
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void harmonic_summing(global volatile float * restrict fop,       // `volatile` to disable private caches
                             const int first_template,
                             const int last_template,
                             const uint n_frequency_bins,
                             global float * restrict thresholds,
                             global uint * restrict detection_location,
                             global float * restrict detection_power)
{
    const uint invalid_location = encode_location(1, ${n_tmpl_per_accel_sign + 1}, 0);
    const float invalid_power = -1.0f;

    // The actual layout and banking of the detection and bookkeeping buffers is chosen to allow `aoc` to implement
    // hms_unroll_x-many no-stall parallel accesses in the unrolled region below. The logical layout is as explained above.
    uint __attribute__((numbanks(${hms_unroll_x * hms_n_planes}))) location_buf[${hms_detection_sz // hms_unroll_x}][${hms_unroll_x}][${hms_n_planes}];
    float __attribute__((numbanks(${hms_unroll_x * hms_n_planes}))) power_buf[${hms_detection_sz // hms_unroll_x}][${hms_unroll_x}][${hms_n_planes}];
    ulong valid[${hms_unroll_x}][${hms_n_planes}];
    ushort next_slot[${hms_unroll_x}][${hms_n_planes}];

    // Zero-initialise bookkeeping buffers
    for (uint x = 0; x < ${hms_unroll_x}; ++x) {
        for (uint h = 0; h < ${hms_n_planes}; ++h) {
            next_slot[x][h] = 0;
            valid[x][h] = 0l;
        }
    }

    // Preload the thresholds
    float thrsh[${hms_n_planes}];
    #pragma unroll
    for (uint h = 0; h < ${hms_n_planes}; ++h)
        thrsh[h] = thresholds[h];

    // MAIN LOOP: Iterates over all (t,f) coordinates in the FOP, handling hms_unroll_x-many channels per iteration of the
    //            inner loop
    for (int tmpl = first_template; tmpl <= last_template; ++tmpl) {
        #pragma unroll ${hms_unroll_x}
        for (uint freq = 0; freq < n_frequency_bins; ++freq) {
            float hsum = 0.0f;

            // Completely unrolled to perform loading and thresholding for all HPs at once
            #pragma unroll
            for (uint h = 0; h < ${hms_n_planes}; ++h) {
                int k = h + 1;

                // Compute harmonic indices. The OpenCL C division does the right thing here, e.g. -10/3 = -3.
                int tmpl_k = tmpl / k;
                int freq_k = freq / k;

                // After adding SP_k(t,f), `hsum` represents HP_k(t,f)
                hsum += fop[(tmpl_k + ${n_tmpl_per_accel_sign}) * n_frequency_bins + freq_k];

                // If we have a candidate, store it in the detection buffers and perform bookkeeping
                if (hsum > thrsh[h]) {
                    uint x = freq % ${hms_unroll_x};
                    ushort slot = next_slot[x][h];
                    location_buf[slot][x][h] = encode_location(k, tmpl, freq);
                    power_buf[slot][x][h] = hsum;
                    valid[x][h] |= 1l << slot;
                    next_slot[x][h] = (slot == ${hms_detection_sz // hms_unroll_x - 1}) ? 0 : slot + 1;
                }
            }
        }
    }

    // Write detection buffers to global memory without messing up the banking of the buffers
    for (uint h = 0; h < ${hms_n_planes}; ++h) {
        for (uint x = 0; x < ${hms_unroll_x}; ++x) {
            for (uint d = 0; d < ${hms_detection_sz // hms_unroll_x}; ++d) {
                if (valid[x][h] & (1l << d)) {
                    detection_location[h * ${hms_detection_sz} + x * ${hms_detection_sz // hms_unroll_x} + d] = location_buf[d][x][h];
                    detection_power[h * ${hms_detection_sz} + x * ${hms_detection_sz // hms_unroll_x} + d] = power_buf[d][x][h];
                } else {
                    detection_location[h * ${hms_detection_sz} + x * ${hms_detection_sz // hms_unroll_x} + d] = invalid_location;
                    detection_power[h * ${hms_detection_sz} + x * ${hms_detection_sz // hms_unroll_x} + d] = invalid_power;
                }
            }
        }
    }
}
