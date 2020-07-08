
inline int harmonic_index(int z, int k)
{
    // XXX: weird. In the emulator, the division does the right thing here (10/2==5, -10/2==-5)
    return z / k;
}

#define FOP_IDX(filt, chan) ((filt + N_FILTERS_PER_ACCEL_SIGN) * FDF_OUTPUT_SZ + chan)

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
    uint __attribute__((numbanks(HMS_N_PLANES))) location_buf[HMS_DETECTION_SZ][HMS_N_PLANES];
    float __attribute__((numbanks(HMS_N_PLANES))) amplitude_buf[HMS_DETECTION_SZ][HMS_N_PLANES];
    ulong valid[HMS_N_PLANES]; // HMS_DETECTION_SZ must be <= 64!
    uint next_slot[HMS_N_PLANES];

    // using `h` as 0-based index into the arrays, and `k` to represent the 1-based index of the harmonic planes

    #pragma unroll
    for (uint h = 0; h < HMS_N_PLANES; ++h) {
        next_slot[h] = 0;
        valid[h] = 0;
    }

    #pragma loop_coalesce 2
    for (int f = -N_FILTERS_PER_ACCEL_SIGN; f <= N_FILTERS_PER_ACCEL_SIGN; ++f) {
        for (uint c = 0; c < FDF_OUTPUT_SZ; ++c) {
            float hsum = 0.0f;
            #pragma unroll
            for (uint h = 0; h < HMS_N_PLANES; ++h) {
                uint k = h + 1;
                int f_k = harmonic_index(f, k);
                int c_k = harmonic_index(c, k);
                hsum += fop[FOP_IDX(f_k, c_k)];

                if (hsum > thresholds[h]) {
                    uint slot = next_slot[h];
                    location_buf[slot][h] = HMS_ENCODE_LOCATION(k, f, c);
                    amplitude_buf[slot][h] = hsum;
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

    for (uint d = 0; d < HMS_DETECTION_SZ; ++d) {
        #pragma unroll 1
        for (uint h = 0; h < HMS_N_PLANES; ++h) {
            if (valid[h] & (1l << d)) {
                detection_location[h * HMS_DETECTION_SZ + d] = location_buf[d][h];
                detection_amplitude[h * HMS_DETECTION_SZ + d] = amplitude_buf[d][h];
            } else {
                detection_location[h * HMS_DETECTION_SZ + d] = HMS_INVALID_LOCATION;
                detection_amplitude[h * HMS_DETECTION_SZ + d] = 0.0f;
            }
        }
    }
}

#undef FOP_IDX
