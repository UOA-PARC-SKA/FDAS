
// Auto-generated file -- see `hsum_codegen.py` and `ringbuf.cl.mako`.

__attribute__((max_global_work_dim(0)))
kernel void ringbuf_1(global uint * restrict detection_location,
                      global float * restrict detection_amplitude)
{
    uint  __attribute__((numbanks(4))) location_buf[8][4];
    float __attribute__((numbanks(4))) amplitude_buf[8][4];

    uint valid[4] = {0, 0, 0, 0};
    uint next[4]  = {0, 0, 0, 0};

    for (uint F = 0; F < 40; F += 4) {
        for (uint c = 0; c < 4193280; ++c) {
            uint  loc[4];
            float amp[4];
            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                loc[f] = READ_CHANNEL(locations[0][f]);
                amp[f] = READ_CHANNEL(amplitudes[0][f]);
            }

            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                if (loc[f] != HMS_INVALID_LOCATION) {
                    uint slot = next[f];
                    location_buf[slot][f] = loc[f];
                    amplitude_buf[slot][f] = amp[f];
                    valid[f] |= 1 << slot;
                    next[f] = (slot + 1) % 8;
                }
            }
        }
    }

    #pragma loop_coalesce
    #pragma unroll 1
    for (uint f = 0; f < 4; ++f) {
        #pragma unroll 1
        for (uint d = 0; d < 8; ++d) {
            if (valid[f] & (1 << d)) {
                detection_location[0 * 32 + f * 8 + d] = location_buf[d][f];
                detection_amplitude[0 * 32 + f * 8 + d] = amplitude_buf[d][f];
            } else {
                detection_location[0 * 32 + f * 8 + d] = HMS_INVALID_LOCATION;
                detection_amplitude[0 * 32 + f * 8 + d] = 0.0f;
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void ringbuf_2(global uint * restrict detection_location,
                      global float * restrict detection_amplitude)
{
    uint  __attribute__((numbanks(4))) location_buf[8][4];
    float __attribute__((numbanks(4))) amplitude_buf[8][4];

    uint valid[4] = {0, 0, 0, 0};
    uint next[4]  = {0, 0, 0, 0};

    for (uint F = 0; F < 40; F += 4) {
        for (uint c = 0; c < 4193280; ++c) {
            uint  loc[4];
            float amp[4];
            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                loc[f] = READ_CHANNEL(locations[1][f]);
                amp[f] = READ_CHANNEL(amplitudes[1][f]);
            }

            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                if (loc[f] != HMS_INVALID_LOCATION) {
                    uint slot = next[f];
                    location_buf[slot][f] = loc[f];
                    amplitude_buf[slot][f] = amp[f];
                    valid[f] |= 1 << slot;
                    next[f] = (slot + 1) % 8;
                }
            }
        }
    }

    #pragma loop_coalesce
    #pragma unroll 1
    for (uint f = 0; f < 4; ++f) {
        #pragma unroll 1
        for (uint d = 0; d < 8; ++d) {
            if (valid[f] & (1 << d)) {
                detection_location[1 * 32 + f * 8 + d] = location_buf[d][f];
                detection_amplitude[1 * 32 + f * 8 + d] = amplitude_buf[d][f];
            } else {
                detection_location[1 * 32 + f * 8 + d] = HMS_INVALID_LOCATION;
                detection_amplitude[1 * 32 + f * 8 + d] = 0.0f;
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void ringbuf_3(global uint * restrict detection_location,
                      global float * restrict detection_amplitude)
{
    uint  __attribute__((numbanks(4))) location_buf[8][4];
    float __attribute__((numbanks(4))) amplitude_buf[8][4];

    uint valid[4] = {0, 0, 0, 0};
    uint next[4]  = {0, 0, 0, 0};

    for (uint F = 0; F < 40; F += 4) {
        for (uint c = 0; c < 4193280; ++c) {
            uint  loc[4];
            float amp[4];
            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                loc[f] = READ_CHANNEL(locations[2][f]);
                amp[f] = READ_CHANNEL(amplitudes[2][f]);
            }

            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                if (loc[f] != HMS_INVALID_LOCATION) {
                    uint slot = next[f];
                    location_buf[slot][f] = loc[f];
                    amplitude_buf[slot][f] = amp[f];
                    valid[f] |= 1 << slot;
                    next[f] = (slot + 1) % 8;
                }
            }
        }
    }

    #pragma loop_coalesce
    #pragma unroll 1
    for (uint f = 0; f < 4; ++f) {
        #pragma unroll 1
        for (uint d = 0; d < 8; ++d) {
            if (valid[f] & (1 << d)) {
                detection_location[2 * 32 + f * 8 + d] = location_buf[d][f];
                detection_amplitude[2 * 32 + f * 8 + d] = amplitude_buf[d][f];
            } else {
                detection_location[2 * 32 + f * 8 + d] = HMS_INVALID_LOCATION;
                detection_amplitude[2 * 32 + f * 8 + d] = 0.0f;
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void ringbuf_4(global uint * restrict detection_location,
                      global float * restrict detection_amplitude)
{
    uint  __attribute__((numbanks(4))) location_buf[8][4];
    float __attribute__((numbanks(4))) amplitude_buf[8][4];

    uint valid[4] = {0, 0, 0, 0};
    uint next[4]  = {0, 0, 0, 0};

    for (uint F = 0; F < 40; F += 4) {
        for (uint c = 0; c < 4193280; ++c) {
            uint  loc[4];
            float amp[4];
            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                loc[f] = READ_CHANNEL(locations[3][f]);
                amp[f] = READ_CHANNEL(amplitudes[3][f]);
            }

            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                if (loc[f] != HMS_INVALID_LOCATION) {
                    uint slot = next[f];
                    location_buf[slot][f] = loc[f];
                    amplitude_buf[slot][f] = amp[f];
                    valid[f] |= 1 << slot;
                    next[f] = (slot + 1) % 8;
                }
            }
        }
    }

    #pragma loop_coalesce
    #pragma unroll 1
    for (uint f = 0; f < 4; ++f) {
        #pragma unroll 1
        for (uint d = 0; d < 8; ++d) {
            if (valid[f] & (1 << d)) {
                detection_location[3 * 32 + f * 8 + d] = location_buf[d][f];
                detection_amplitude[3 * 32 + f * 8 + d] = amplitude_buf[d][f];
            } else {
                detection_location[3 * 32 + f * 8 + d] = HMS_INVALID_LOCATION;
                detection_amplitude[3 * 32 + f * 8 + d] = 0.0f;
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void ringbuf_5(global uint * restrict detection_location,
                      global float * restrict detection_amplitude)
{
    uint  __attribute__((numbanks(4))) location_buf[8][4];
    float __attribute__((numbanks(4))) amplitude_buf[8][4];

    uint valid[4] = {0, 0, 0, 0};
    uint next[4]  = {0, 0, 0, 0};

    for (uint F = 0; F < 40; F += 4) {
        for (uint c = 0; c < 4193280; ++c) {
            uint  loc[4];
            float amp[4];
            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                loc[f] = READ_CHANNEL(locations[4][f]);
                amp[f] = READ_CHANNEL(amplitudes[4][f]);
            }

            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                if (loc[f] != HMS_INVALID_LOCATION) {
                    uint slot = next[f];
                    location_buf[slot][f] = loc[f];
                    amplitude_buf[slot][f] = amp[f];
                    valid[f] |= 1 << slot;
                    next[f] = (slot + 1) % 8;
                }
            }
        }
    }

    #pragma loop_coalesce
    #pragma unroll 1
    for (uint f = 0; f < 4; ++f) {
        #pragma unroll 1
        for (uint d = 0; d < 8; ++d) {
            if (valid[f] & (1 << d)) {
                detection_location[4 * 32 + f * 8 + d] = location_buf[d][f];
                detection_amplitude[4 * 32 + f * 8 + d] = amplitude_buf[d][f];
            } else {
                detection_location[4 * 32 + f * 8 + d] = HMS_INVALID_LOCATION;
                detection_amplitude[4 * 32 + f * 8 + d] = 0.0f;
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void ringbuf_6(global uint * restrict detection_location,
                      global float * restrict detection_amplitude)
{
    uint  __attribute__((numbanks(4))) location_buf[8][4];
    float __attribute__((numbanks(4))) amplitude_buf[8][4];

    uint valid[4] = {0, 0, 0, 0};
    uint next[4]  = {0, 0, 0, 0};

    for (uint F = 0; F < 40; F += 4) {
        for (uint c = 0; c < 4193280; ++c) {
            uint  loc[4];
            float amp[4];
            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                loc[f] = READ_CHANNEL(locations[5][f]);
                amp[f] = READ_CHANNEL(amplitudes[5][f]);
            }

            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                if (loc[f] != HMS_INVALID_LOCATION) {
                    uint slot = next[f];
                    location_buf[slot][f] = loc[f];
                    amplitude_buf[slot][f] = amp[f];
                    valid[f] |= 1 << slot;
                    next[f] = (slot + 1) % 8;
                }
            }
        }
    }

    #pragma loop_coalesce
    #pragma unroll 1
    for (uint f = 0; f < 4; ++f) {
        #pragma unroll 1
        for (uint d = 0; d < 8; ++d) {
            if (valid[f] & (1 << d)) {
                detection_location[5 * 32 + f * 8 + d] = location_buf[d][f];
                detection_amplitude[5 * 32 + f * 8 + d] = amplitude_buf[d][f];
            } else {
                detection_location[5 * 32 + f * 8 + d] = HMS_INVALID_LOCATION;
                detection_amplitude[5 * 32 + f * 8 + d] = 0.0f;
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void ringbuf_7(global uint * restrict detection_location,
                      global float * restrict detection_amplitude)
{
    uint  __attribute__((numbanks(4))) location_buf[8][4];
    float __attribute__((numbanks(4))) amplitude_buf[8][4];

    uint valid[4] = {0, 0, 0, 0};
    uint next[4]  = {0, 0, 0, 0};

    for (uint F = 0; F < 40; F += 4) {
        for (uint c = 0; c < 4193280; ++c) {
            uint  loc[4];
            float amp[4];
            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                loc[f] = READ_CHANNEL(locations[6][f]);
                amp[f] = READ_CHANNEL(amplitudes[6][f]);
            }

            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                if (loc[f] != HMS_INVALID_LOCATION) {
                    uint slot = next[f];
                    location_buf[slot][f] = loc[f];
                    amplitude_buf[slot][f] = amp[f];
                    valid[f] |= 1 << slot;
                    next[f] = (slot + 1) % 8;
                }
            }
        }
    }

    #pragma loop_coalesce
    #pragma unroll 1
    for (uint f = 0; f < 4; ++f) {
        #pragma unroll 1
        for (uint d = 0; d < 8; ++d) {
            if (valid[f] & (1 << d)) {
                detection_location[6 * 32 + f * 8 + d] = location_buf[d][f];
                detection_amplitude[6 * 32 + f * 8 + d] = amplitude_buf[d][f];
            } else {
                detection_location[6 * 32 + f * 8 + d] = HMS_INVALID_LOCATION;
                detection_amplitude[6 * 32 + f * 8 + d] = 0.0f;
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void ringbuf_8(global uint * restrict detection_location,
                      global float * restrict detection_amplitude)
{
    uint  __attribute__((numbanks(4))) location_buf[8][4];
    float __attribute__((numbanks(4))) amplitude_buf[8][4];

    uint valid[4] = {0, 0, 0, 0};
    uint next[4]  = {0, 0, 0, 0};

    for (uint F = 0; F < 40; F += 4) {
        for (uint c = 0; c < 4193280; ++c) {
            uint  loc[4];
            float amp[4];
            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                loc[f] = READ_CHANNEL(locations[7][f]);
                amp[f] = READ_CHANNEL(amplitudes[7][f]);
            }

            #pragma unroll
            for (uint f = 0; f < 4; ++f) {
                if (loc[f] != HMS_INVALID_LOCATION) {
                    uint slot = next[f];
                    location_buf[slot][f] = loc[f];
                    amplitude_buf[slot][f] = amp[f];
                    valid[f] |= 1 << slot;
                    next[f] = (slot + 1) % 8;
                }
            }
        }
    }

    #pragma loop_coalesce
    #pragma unroll 1
    for (uint f = 0; f < 4; ++f) {
        #pragma unroll 1
        for (uint d = 0; d < 8; ++d) {
            if (valid[f] & (1 << d)) {
                detection_location[7 * 32 + f * 8 + d] = location_buf[d][f];
                detection_amplitude[7 * 32 + f * 8 + d] = amplitude_buf[d][f];
            } else {
                detection_location[7 * 32 + f * 8 + d] = HMS_INVALID_LOCATION;
                detection_amplitude[7 * 32 + f * 8 + d] = 0.0f;
            }
        }
    }
}
