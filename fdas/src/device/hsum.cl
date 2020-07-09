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
 *  - ... (TODO)
 */
#define HMS_BASELINE

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

    // One bitfield per HP to indiciate which slots hold valid candidate. HMS_DETECTION_SZ must be <= 64!
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

#undef FOP_IDX
