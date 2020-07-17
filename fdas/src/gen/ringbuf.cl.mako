
__attribute__((max_global_work_dim(0)))
kernel void ringbuf_${harmonic}(global uint * restrict detection_location,
                      global float * restrict detection_amplitude)
{
    uint  __attribute__((numbanks(${n_parallel}))) location_buf[${detection_sz // n_parallel}][${n_parallel}];
    float __attribute__((numbanks(${n_parallel}))) amplitude_buf[${detection_sz // n_parallel}][${n_parallel}];

    uint valid[${n_parallel}] = {${', '.join(["0"] * n_parallel)}};
    uint next[${n_parallel}]  = {${', '.join(["0"] * n_parallel)}};

    for (uint F = 0; F < ${n_filters}; F += ${n_parallel}) {
        for (uint c = 0; c < ${n_channels}; ++c) {
            uint  loc[${n_parallel}];
            float amp[${n_parallel}];
            #pragma unroll
            for (uint f = 0; f < ${n_parallel}; ++f) {
                loc[f] = READ_CHANNEL(locations[${harmonic - 1}][f]);
                amp[f] = READ_CHANNEL(amplitudes[${harmonic - 1}][f]);
            }

            #pragma unroll
            for (uint f = 0; f < ${n_parallel}; ++f) {
                if (loc[f] != HMS_INVALID_LOCATION) {
                    uint slot = next[f];
                    location_buf[slot][f] = loc[f];
                    amplitude_buf[slot][f] = amp[f];
                    valid[f] |= 1 << slot;
                    next[f] = (slot + 1) % ${detection_sz // n_parallel};
                }
            }
        }
    }

    #pragma loop_coalesce
    #pragma unroll 1
    for (uint f = 0; f < ${n_parallel}; ++f) {
        #pragma unroll 1
        for (uint d = 0; d < ${detection_sz // n_parallel}; ++d) {
            if (valid[f] & (1 << d)) {
                detection_location[${harmonic - 1} * ${detection_sz} + f * ${detection_sz // n_parallel} + d] = location_buf[d][f];
                detection_amplitude[${harmonic - 1} * ${detection_sz} + f * ${detection_sz // n_parallel} + d] = amplitude_buf[d][f];
            } else {
                detection_location[${harmonic - 1} * ${detection_sz} + f * ${detection_sz // n_parallel} + d] = HMS_INVALID_LOCATION;
                detection_amplitude[${harmonic - 1} * ${detection_sz} + f * ${detection_sz // n_parallel} + d] = 0.0f;
            }
        }
    }
}
