/*
 * The kernels in this file compute several harmonic planes (HP) from differently stretched versions of the
 * filter-output plane (FOP) to amplify periodic signals, then use thresholding to produce a preliminary list of pulsar
 * candidates.
 *
 * The FOP, as computed by the FT convolution kernels in `ft_conv.cl`, is the input:
 *
 *                              &fop[0]
 *                             /
 *  -N_FILTERS_PER_ACCEL_SIGN *───────────────────────────┐
 *             ▲            ┆ │                           │
 *             │           -1 │                           │
 *     template/filter (f)  0 ├───────────────────────────┤FDF_OUTPUT_SZ
 *             │            1 │                           │
 *             ▼            ┆ │                           │
 *   N_FILTERS_PER_ACCEL_SIGN └───────────────────────────┘
 *                             ────────channel (c)───────▶
 *
 * It is important to keep in mind that while indices in the range [0, N_FILTERS) are used to access the FOP in memory,
 * the filter templates are actually numbered -N_FILTERS_PER_ACCEL_SIGN, ..., -1, 0, 1, ..., N_FILTERS_PER_ACCEL_SIGN
 * in the underlying science. It follows that the origin of the FOP (template 0, channel 0) has the memory address
 * `&fop[N_FILTERS_PER_ACCEL_SIGN * FDF_OUTPUT_SZ]`.
 *
 * We compute HMS_N_PLANES harmonic planes HP_k, defined as:
 *   HP_1(f,c) = FOP(f,c)                                             (1)
 *   HP_k(f,c) = HP_k-1(f,c) + SP_k(f,c)   k = 2, ..., HMS_N_PLANES   (2)
 *
 * The SP_k are the stretch planes, which are the result of stretching the FOP by k:
 *   SP_k(f,c) = FOP(f / k, c / k)   k = 2, ..., HMS_N_PLANES         (3)
 *                    ^^^ integer division, rounding towards 0
 *
 * Note that the kernels are _not intended_ to store the HPs explicitly. (This functionality can be enabled for testing
 * by setting HMS_STORE_PLANES to true.) Instead, for a given coordinate (f,c), we iteratively compute the values of the
 * SP_k and HP_k and compare them with with the thresholds:
 *
 *   HP_k(f,c) = Σ_{l=1...k} FOP(f / l, c / l)   >   thresholds(k)    (4)
 *
 * The HPs are associated with different, externally specified thresholds.
 *
 * The output of the harmonic summing module (and in turn, of the FDAS module) is a list of candidates characterised by
 *  - k, the index of the harmonic plane,
 *  - f, the filter number and,
 *  - c, the number of the frequency bin (a.k.a. channel), for which
 *  - HP_k(f,c), an amplitude greater than the appropriate threshold, was detected.
 *
 * Up to N_CANDIDATES are written to the buffers `detection_location` (uint, see HMS_ENCODE_LOCATION(k, f, c) macro) and
 * `detection_amplitude` (float). If fewer candidates are found, invalid slots are marked by HMS_INVALID_LOCATION.
 *
 * The main challenge here is to cope with the irregular memory accesses. Different approaches are implemented below:
 *  - HMS_BASELINE: unoptimised implementation of inequation (4)
 *  - HMS_UNROLL  : Haomiao's approach: Handle more than one channel through loop unrolling
 *  - ... (TODO)
 */
#define HMS_SYSTOLIC

// Computes an index for accessing the FOP buffer
#define FOP_IDX(filt, chan) ((filt + N_FILTERS_PER_ACCEL_SIGN) * FDF_OUTPUT_SZ + chan)

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
                             global float * restrict thresholds,
                             global uint * restrict detection_location,
                             global float * restrict detection_amplitude
                             #if HMS_STORE_PLANES
                             , global float * restrict harmonic_planes
                             #endif
                             )
{
    // Buffers to store the up to N_CANDIDATES detections
    uint location_buf[HMS_N_PLANES][HMS_DETECTION_SZ];
    float amplitude_buf[HMS_N_PLANES][HMS_DETECTION_SZ];

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

    // MAIN LOOP: Iterates over all (f,c) coordinates in the FOP
    #pragma loop_coalesce 2
    for (int f = -N_FILTERS_PER_ACCEL_SIGN; f <= N_FILTERS_PER_ACCEL_SIGN; ++f) {
        for (uint c = 0; c < FDF_OUTPUT_SZ; ++c) {
            float hsum = 0.0f;

            // Iteratively compute HP_1(f,c), HP_2(f,c), ...
            #pragma unroll 1
            for (uint h = 0; h < HMS_N_PLANES; ++h) {
                int k = h + 1;

                // Compute harmonic indices. The OpenCL C division does the right thing here, e.g. -10/3 = -3.
                int f_k = f / k;
                int c_k = c / k;

                // After adding SP_k(f,c), `hsum` represents HP_k(f,c)
                hsum += fop[FOP_IDX(f_k, c_k)];

                // If we have a candidate, store it in the detection buffers and perform bookkeeping
                if (hsum > thresholds[h]) {
                    uint slot = next_slot[h];
                    location_buf[h][slot] = HMS_ENCODE_LOCATION(k, f, c);
                    amplitude_buf[h][slot] = hsum;
                    valid[h] |= 1l << slot;
                    next_slot[h] = (slot == HMS_DETECTION_SZ - 1) ? 0 : slot + 1;
                }

                #if HMS_STORE_PLANES
                if (h > 0) // do not copy the FOP
                    harmonic_planes[(h-1) * FOP_SZ + FOP_IDX(f, c)] = hsum;
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
                detection_amplitude[h * HMS_DETECTION_SZ + d] = amplitude_buf[h][d];
            } else {
                detection_location[h * HMS_DETECTION_SZ + d] = HMS_INVALID_LOCATION;
                detection_amplitude[h * HMS_DETECTION_SZ + d] = 0.0f;
            }
        }
    }
}
#endif

#ifdef HMS_UNROLL
/*
 * `harmonic_summing[HMS_UNROLL]` -- single-work item kernel
 *
 * Parallel implementation of the on-the-fly thresholding approach, handling HMS_X-many channels per iteration. The
 * detection buffers are _logically_ partitioned into HMS_X independent ring-buffers per HP, containing detections from
 * channels congruent to 0 mod HMS_X, 1 mod HMS_X, ..., as illustrated below:
 *
 *    |───────────HMS_N_PLANES─────────────|
 *                                                 ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
 *    HP_1:                    HP_2:   HP_N:          detection,
 *  - ┌──────────────────────┐ ┌───┐   ┌───┐       │  amplitude:       │
 *  │ │ channels % HMS_X = 0 │ │   │   │   │         ┌─┬─┬─┬─┬─┬─┬─┬─┐
 *  H ├──────────────────────┤ ├───┤   ├───┤       │ │r│i│n│g│ │b│u│f│ │
 *  M │ channels % HMS_X = 1 │ │   │   │   │         └─┴─┴▲┴─┴─┴─┴─┴─┘
 *  S ├──────────────────────┤ ├───┤...├───┤       │      └──next_slot │
 *  _ │ channels % HMS_X = 2 │ │   │   │   │          valid:
 *  X ├──────────────────────┤ ├───┤   ├───┤     ─ │ ┌─┬─┬─┬─┬─┬─┬─┬─┐ │
 *  │ │ channels % HMS_X = 3 │ │   │   │   │    │    │1│1│0│0│0│0│0│0│
 *  - └──────────────────────┘ └───┘   └───┘       │ └─┴─┴─┴─┴─┴─┴─┴─┘ │
 *                │                             │    \               /
 *                                                 │  HMS_DETECTION_SZ │
 *                └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘            ÷
 *                                                 │       HMS_X       │
 *                                                  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
 *
 * In consequence, for each HP, we return the last HMS_DETECTION_SZ / HMS_X candidates per congruence class! E.g. if
 * all detections are in channels divisible by HMS_X (congruence class '0'), elements in this ring-buffer would be
 * overwritten even if the other ring-buffers are empty.
 *
 * Convention:
 *   We are using `h` as 0-based index into the arrays, and `k` to represent the 1-based index of the harmonic planes.
 */
__attribute__((max_global_work_dim(0)))
kernel void harmonic_summing(global volatile float * restrict fop,       // `volatile` to disable private caches
                             global float * restrict thresholds,
                             global uint * restrict detection_location,
                             global float * restrict detection_amplitude
                             #if HMS_STORE_PLANES
                             , global float * restrict harmonic_planes
                             #endif
                             )
{
    // The actual layout and banking of the detection and bookkeeping buffers is chosen to allow `aoc` to implement
    // HMS_X-many no-stall parallel accesses in the unrolled region below. The logical layout is as explained above.
    uint __attribute__((numbanks(HMS_X * HMS_N_PLANES))) location_buf[HMS_DETECTION_SZ / HMS_X][HMS_X][HMS_N_PLANES];
    float __attribute__((numbanks(HMS_X * HMS_N_PLANES))) amplitude_buf[HMS_DETECTION_SZ / HMS_X][HMS_X][HMS_N_PLANES];
    ulong valid[HMS_X][HMS_N_PLANES];
    uint next_slot[HMS_X][HMS_N_PLANES];

    // Zero-initialise bookkeeping buffers
    for (uint x = 0; x < HMS_X; ++x) {
        for (uint h = 0; h < HMS_N_PLANES; ++h) {
            next_slot[x][h] = 0;
            valid[x][h] = 0l;
        }
    }

    // MAIN LOOP: Iterates over all (f,c) coordinates in the FOP, handling HMS_X-many channels per iteration of the
    //            inner loop
    for (int f = -N_FILTERS_PER_ACCEL_SIGN; f <= N_FILTERS_PER_ACCEL_SIGN; ++f) {
        HMS_CHANNEL_LOOP_UNROLL
        for (uint c = 0; c < FDF_OUTPUT_SZ; ++c) {
            float hsum = 0.0f;

            // Completely unrolled to perform loading and thresholding for all HPs at once
            #pragma unroll
            for (uint h = 0; h < HMS_N_PLANES; ++h) {
                int k = h + 1;

                // Compute harmonic indices. The OpenCL C division does the right thing here, e.g. -10/3 = -3.
                int f_k = f / k;
                int c_k = c / k;

                // After adding SP_k(f,c), `hsum` represents HP_k(f,c)
                hsum += fop[FOP_IDX(f_k, c_k)];

                // If we have a candidate, store it in the detection buffers and perform bookkeeping
                if (hsum > thresholds[h]) {
                    uint x = c % HMS_X;
                    uint slot = next_slot[x][h];
                    location_buf[slot][x][h] = HMS_ENCODE_LOCATION(k, f, c);
                    amplitude_buf[slot][x][h] = hsum;
                    valid[x][h] |= 1l << slot;
                    next_slot[x][h] = (slot == HMS_DETECTION_SZ / HMS_X - 1) ? 0 : slot + 1;
                }

                #if HMS_STORE_PLANES
                if (h > 0) // do not copy the FOP
                    harmonic_planes[(h-1) * FOP_SZ + FOP_IDX(f, c)] = hsum;
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
                    detection_amplitude[h * HMS_DETECTION_SZ + x * HMS_DETECTION_SZ / HMS_X + d] = amplitude_buf[d][x][h];
                } else {
                    detection_location[h * HMS_DETECTION_SZ + x * HMS_DETECTION_SZ / HMS_X + d] = HMS_INVALID_LOCATION;
                    detection_amplitude[h * HMS_DETECTION_SZ + x * HMS_DETECTION_SZ / HMS_X + d] = 0.0f;
                }
            }
        }
    }
}
#endif

#ifdef HMS_SYSTOLIC
#include "preld.cl"
#include "detect.cl"
#include "store_cands.cl"
#endif

#undef FOP_IDX
