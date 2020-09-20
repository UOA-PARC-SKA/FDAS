/*
 * FDAS -- Fourier Domain Acceleration Search, FPGA-accelerated with OpenCL
 * Copyright (C) 2020  Parallel and Reconfigurable Computing Lab,
 *                     Dept. of Electrical, Computer, and Software Engineering,
 *                     University of Auckland, New Zealand
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * The kernels in this file compute several harmonic planes (HP) from differently stretched versions of the
 * filter-output plane (FOP) to amplify periodic signals, then use thresholding to produce a preliminary list of pulsar
 * candidates.
 *
 * The FOP, as computed by the FT convolution kernels in `ft_conv.cl`, is the input:
 *
 *                              &fop[0]
 *                             /
 *     -N_TMPL_PER_ACCEL_SIGN *───────────────────────────┐
 *             ▲            ┆ │                           │
 *             │           -1 │                           │
 *     template num (tmpl)  0 ├───────────────────────────┤<n_frequency_bins>
 *             │            1 │                           │
 *             ▼            ┆ │                           │
 *      N_TMPL_PER_ACCEL_SIGN └───────────────────────────┘
 *                             ────frequency bin (freq)──▶
 *
 * It is important to remember that while indices in the range [0, N_TEMPLATES) are used to access the FOP in memory,
 * the templates are actually numbered -N_TMPL_PER_ACCEL_SIGN, ..., -1, 0, 1, ..., N_TMPL_PER_ACCEL_SIGN
 * in the underlying science. It follows that the origin of the FOP (template 0, frequency bin 0) has the memory address
 * `&fop[N_TMPL_PER_ACCEL_SIGN * <n_frequency_bins>]`.
 *
 * We compute HMS_N_PLANES harmonic planes HP_k, defined as:
 *   HP_1(t,f) = FOP(t,f)                                             (1)
 *   HP_k(t,f) = HP_k-1(t,f) + SP_k(t,f)   k = 2, ..., HMS_N_PLANES   (2)
 *
 * The SP_k are the stretch planes, which are the result of stretching the FOP by k:
 *   SP_k(t,f) = FOP(t / k, f / k)   k = 2, ..., HMS_N_PLANES         (3)
 *                    ^^^ integer division, rounding towards 0
 *
 * Note that the kernels are _not intended_ to store the HPs explicitly. (This functionality can be enabled for testing
 * by setting HMS_STORE_PLANES to true.) Instead, for a given coordinate (t,f), we iteratively compute the values of the
 * SP_k and HP_k and compare them with with the thresholds:
 *
 *   HP_k(t,f) = Σ_{l=1...k} FOP(t / l, f / l)   >   thresholds(k)    (4)
 *
 * The HPs are associated with different, externally specified thresholds.
 *
 * The output of the harmonic summing module (and in turn, of the FDAS module) is a list of candidates characterised by
 *  - k, the index of the harmonic plane,
 *  - t, the template number and,
 *  - f, the number of the frequency bin, for which
 *  - HP_k(t,f), a power greater than the appropriate threshold, was detected.
 *
 * Up to N_CANDIDATES are written to the buffers `detection_location` (uint, see HMS_ENCODE_LOCATION(harm, tmpl, freq)
 * macro) and `detection_power` (float). If fewer candidates are found, invalid slots are marked by
 * HMS_INVALID_LOCATION.
 *
 * The main challenge here is to cope with the irregular memory accesses. Different approaches are implemented below:
 *  - HMS_BASELINE: unoptimised implementation of inequation (4)
 *  - HMS_UNROLL  : Haomiao's approach: Handle more than one frequency bin at once, through loop unrolling
 *  - ... (TODO)
 */
#define HMS_UNROLL

// Computes an index for accessing the FOP buffer
inline ulong fop_idx(int tmpl, uint freq, uint n_frequency_bins)
{
    return (tmpl + N_TMPL_PER_ACCEL_SIGN) * n_frequency_bins + freq;
}

#ifdef HMS_BASELINE
/*
 * `harmonic_summing[HMS_BASELINE]` -- single-work item kernel
 *
 * Unoptimised implementation of the on-the-fly thresholding approach. Uses per-HP ring-buffers for the detected
 * candidates, i.e. we return the _last_ HMS_DETECTION_SZ candidates for each of the HPs.
 *
 * Convention:
 *   We are using `h` as 0-based index into the arrays, and `k` to represent the 1-based index of the harmonic planes.
 */
__attribute__((max_global_work_dim(0)))
kernel void harmonic_summing(global float * restrict fop,
                             const uint n_frequency_bins,
                             global float * restrict thresholds,
                             global uint * restrict detection_location,
                             global float * restrict detection_power,
                             #if HMS_STORE_PLANES
                             , global float * restrict harmonic_planes
                             #endif
                             )
{
    // Buffers to store the up to N_CANDIDATES detections
    uint location_buf[HMS_N_PLANES][HMS_DETECTION_SZ];
    float power_buf[HMS_N_PLANES][HMS_DETECTION_SZ];

    // One bitfield per HP to indicate which slots hold valid candidates. HMS_DETECTION_SZ must be <= 64!
    ulong valid[HMS_N_PLANES];

    // Per-HP index of the next free (or to be overwritten) slot in the detection buffers
    uint next_slot[HMS_N_PLANES];

    // Zero-initialise bookkeeping buffers
    #pragma unroll
    for (uint h = 0; h < HMS_N_PLANES; ++h) {
        next_slot[h] = 0;
        valid[h] = 0;
    }

    // MAIN LOOP: Iterates over all (t,f) coordinates in the FOP
    #pragma loop_coalesce 2
    for (int tmpl = -N_TMPL_PER_ACCEL_SIGN; tmpl <= N_TMPL_PER_ACCEL_SIGN; ++tmpl) {
        for (uint freq = 0; freq < n_frequency_bins; ++freq) {
            float hsum = 0.0f;

            // Iteratively compute HP_1(t,f), HP_2(t,f), ...
            #pragma unroll 1
            for (uint h = 0; h < HMS_N_PLANES; ++h) {
                int k = h + 1;

                // Compute harmonic indices. The OpenCL C division does the right thing here, e.g. -10/3 = -3.
                int tmpl_k = tmpl / k;
                int freq_k = freq / k;

                // After adding SP_k(t,f), `hsum` represents HP_k(t,f)
                hsum += fop[fop_idx(tmpl_k, freq_k, n_frequency_bins)];

                // If we have a candidate, store it in the detection buffers and perform bookkeeping
                if (hsum > thresholds[h]) {
                    uint slot = next_slot[h];
                    location_buf[h][slot] = HMS_ENCODE_LOCATION(k, tmpl, freq);
                    power_buf[h][slot] = hsum;
                    valid[h] |= 1l << slot;
                    next_slot[h] = (slot == HMS_DETECTION_SZ - 1) ? 0 : slot + 1;
                }

                #if HMS_STORE_PLANES
                if (h > 0) // do not copy the FOP
                    harmonic_planes[(h-1) * (N_TEMPLATES * n_frequency_bins) + fop_idx(tmpl, freq, n_frequency_bins)] = hsum;
                #endif
            }
        }
    }

    // Write detection buffers to global memory (sequentially)
    #pragma loop_coalesce
    for (uint h = 0; h < HMS_N_PLANES; ++h) {
        for (uint d = 0; d < HMS_DETECTION_SZ; ++d) {
            if (valid[h] & (1l << d)) {
                detection_location[h * HMS_DETECTION_SZ + d] = location_buf[h][d];
                detection_power[h * HMS_DETECTION_SZ + d] = power_buf[h][d];
            } else {
                detection_location[h * HMS_DETECTION_SZ + d] = HMS_INVALID_LOCATION;
                detection_power[h * HMS_DETECTION_SZ + d] = 0.0f;
            }
        }
    }
}
#endif

#ifdef HMS_UNROLL
/*
 * `harmonic_summing[HMS_UNROLL]` -- single-work item kernel
 *
 * Parallel implementation of the on-the-fly thresholding approach, handling HMS_X-many frequency bins per iteration.
 * The detection buffers are _logically_ partitioned into HMS_X independent ring-buffers per HP, containing detections
 * from frequency bins congruent to 0 mod HMS_X, 1 mod HMS_X, ..., as illustrated below:
 *
 *    |───────────HMS_N_PLANES─────────────|
 *                                                 ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
 *    HP_1:                    HP_2:   HP_N:          detection,
 *  - ┌──────────────────────┐ ┌───┐   ┌───┐       │  amplitude:       │
 *  │ │  freqs % HMS_X = 0   │ │   │   │   │         ┌─┬─┬─┬─┬─┬─┬─┬─┐
 *  H ├──────────────────────┤ ├───┤   ├───┤       │ │r│i│n│g│ │b│u│f│ │
 *  M │  freqs % HMS_X = 1   │ │   │   │   │         └─┴─┴▲┴─┴─┴─┴─┴─┘
 *  S ├──────────────────────┤ ├───┤...├───┤       │      └──next_slot │
 *  _ │  freqs % HMS_X = 2   │ │   │   │   │          valid:
 *  X ├──────────────────────┤ ├───┤   ├───┤     ─ │ ┌─┬─┬─┬─┬─┬─┬─┬─┐ │
 *  │ │  freqs % HMS_X = 3   │ │   │   │   │    │    │1│1│0│0│0│0│0│0│
 *  - └──────────────────────┘ └───┘   └───┘       │ └─┴─┴─┴─┴─┴─┴─┴─┘ │
 *                │                             │    \               /
 *                                                 │  HMS_DETECTION_SZ │
 *                └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘            ÷
 *                                                 │       HMS_X       │
 *                                                  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
 *
 * In consequence, for each HP, we return the last HMS_DETECTION_SZ / HMS_X candidates per congruence class! E.g. if
 * all detections are in bins divisible by HMS_X (congruence class '0'), elements in this ring-buffer would be
 * overwritten even if the other ring-buffers are empty.
 *
 * Convention:
 *   We are using `h` as 0-based index into the arrays, and `k` to represent the 1-based index of the harmonic planes.
 */
__attribute__((max_global_work_dim(0)))
kernel void harmonic_summing(global volatile float * restrict fop,       // `volatile` to disable private caches
                             const uint n_frequency_bins,
                             global float * restrict thresholds,
                             global uint * restrict detection_location,
                             global float * restrict detection_power
                             #if HMS_STORE_PLANES
                             , global float * restrict harmonic_planes
                             #endif
                             )
{
    // The actual layout and banking of the detection and bookkeeping buffers is chosen to allow `aoc` to implement
    // HMS_X-many no-stall parallel accesses in the unrolled region below. The logical layout is as explained above.
    uint __attribute__((numbanks(HMS_X * HMS_N_PLANES))) location_buf[HMS_DETECTION_SZ / HMS_X][HMS_X][HMS_N_PLANES];
    float __attribute__((numbanks(HMS_X * HMS_N_PLANES))) power_buf[HMS_DETECTION_SZ / HMS_X][HMS_X][HMS_N_PLANES];
    ulong valid[HMS_X][HMS_N_PLANES];
    uint next_slot[HMS_X][HMS_N_PLANES];

    // Zero-initialise bookkeeping buffers
    for (uint x = 0; x < HMS_X; ++x) {
        for (uint h = 0; h < HMS_N_PLANES; ++h) {
            next_slot[x][h] = 0;
            valid[x][h] = 0l;
        }
    }

    // Preload the thresholds
    float thrsh[HMS_N_PLANES];
    #pragma unroll
    for (uint h = 0; h < HMS_N_PLANES; ++h)
        thrsh[h] = thresholds[h];

    // MAIN LOOP: Iterates over all (t,f) coordinates in the FOP, handling HMS_X-many channels per iteration of the
    //            inner loop
    for (int tmpl = -N_TMPL_PER_ACCEL_SIGN; tmpl <= N_TMPL_PER_ACCEL_SIGN; ++tmpl) {
        HMS_CHANNEL_LOOP_UNROLL
        for (uint freq = 0; freq < n_frequency_bins; ++freq) {
            float hsum = 0.0f;

            // Completely unrolled to perform loading and thresholding for all HPs at once
            #pragma unroll
            for (uint h = 0; h < HMS_N_PLANES; ++h) {
                int k = h + 1;

                // Compute harmonic indices. The OpenCL C division does the right thing here, e.g. -10/3 = -3.
                int tmpl_k = tmpl / k;
                int freq_k = freq / k;

                // After adding SP_k(t,f), `hsum` represents HP_k(t,f)
                hsum += fop[fop_idx(tmpl_k, freq_k, n_frequency_bins)];

                // If we have a candidate, store it in the detection buffers and perform bookkeeping
                if (hsum > thrsh[h]) {
                    uint x = freq % HMS_X;
                    uint slot = next_slot[x][h];
                    location_buf[slot][x][h] = HMS_ENCODE_LOCATION(k, tmpl, freq);
                    power_buf[slot][x][h] = hsum;
                    valid[x][h] |= 1l << slot;
                    next_slot[x][h] = (slot == HMS_DETECTION_SZ / HMS_X - 1) ? 0 : slot + 1;
                }

                #if HMS_STORE_PLANES
                if (h > 0) // do not copy the FOP
                    harmonic_planes[(h-1) * (N_TEMPLATES * n_frequency_bins) + fop_idx(tmpl, freq, n_frequency_bins)] = hsum;
                #endif
            }
        }
    }

    // Write detection buffers to global memory without messing up the banking of the buffers
    for (uint h = 0; h < HMS_N_PLANES; ++h) {
        for (uint x = 0; x < HMS_X; ++x) {
            for (uint d = 0; d < HMS_DETECTION_SZ / HMS_X; ++d) {
                if (valid[x][h] & (1l << d)) {
                    detection_location[h * HMS_DETECTION_SZ + x * HMS_DETECTION_SZ / HMS_X + d] = location_buf[d][x][h];
                    detection_power[h * HMS_DETECTION_SZ + x * HMS_DETECTION_SZ / HMS_X + d] = power_buf[d][x][h];
                } else {
                    detection_location[h * HMS_DETECTION_SZ + x * HMS_DETECTION_SZ / HMS_X + d] = HMS_INVALID_LOCATION;
                    detection_power[h * HMS_DETECTION_SZ + x * HMS_DETECTION_SZ / HMS_X + d] = 0.0f;
                }
            }
        }
    }
}
#endif
