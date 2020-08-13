
// Auto-generated file -- see `hsum_codegen.py` and `store_cands.cl.mako`.

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void store_cands(global uint * restrict detection_location,
                        global float * restrict detection_amplitude)
{
    #pragma unroll 1
    for (uint h = 0; h < 8; ++h) {
        #pragma unroll 1
        for (uint d = 0; d < 64; ++d) {
            uint loc[8];
            float amp[8];
            switch (h) {
                case 0:
                    #pragma unroll
                    for (uint x = 0; x < 8; ++x) {
                        loc[x] = READ_CHANNEL(detect_to_store_location[0][x]);
                        amp[x] = READ_CHANNEL(detect_to_store_amplitude[0][x]);
                    }
                    break;
                case 1:
                    #pragma unroll
                    for (uint x = 0; x < 8; ++x) {
                        loc[x] = READ_CHANNEL(detect_to_store_location[1][x]);
                        amp[x] = READ_CHANNEL(detect_to_store_amplitude[1][x]);
                    }
                    break;
                case 2:
                    #pragma unroll
                    for (uint x = 0; x < 8; ++x) {
                        loc[x] = READ_CHANNEL(detect_to_store_location[2][x]);
                        amp[x] = READ_CHANNEL(detect_to_store_amplitude[2][x]);
                    }
                    break;
                case 3:
                    #pragma unroll
                    for (uint x = 0; x < 8; ++x) {
                        loc[x] = READ_CHANNEL(detect_to_store_location[3][x]);
                        amp[x] = READ_CHANNEL(detect_to_store_amplitude[3][x]);
                    }
                    break;
                case 4:
                    #pragma unroll
                    for (uint x = 0; x < 8; ++x) {
                        loc[x] = READ_CHANNEL(detect_to_store_location[4][x]);
                        amp[x] = READ_CHANNEL(detect_to_store_amplitude[4][x]);
                    }
                    break;
                case 5:
                    #pragma unroll
                    for (uint x = 0; x < 8; ++x) {
                        loc[x] = READ_CHANNEL(detect_to_store_location[5][x]);
                        amp[x] = READ_CHANNEL(detect_to_store_amplitude[5][x]);
                    }
                    break;
                case 6:
                    #pragma unroll
                    for (uint x = 0; x < 8; ++x) {
                        loc[x] = READ_CHANNEL(detect_to_store_location[6][x]);
                        amp[x] = READ_CHANNEL(detect_to_store_amplitude[6][x]);
                    }
                    break;
                case 7:
                    #pragma unroll
                    for (uint x = 0; x < 8; ++x) {
                        loc[x] = READ_CHANNEL(detect_to_store_location[7][x]);
                        amp[x] = READ_CHANNEL(detect_to_store_amplitude[7][x]);
                    }
                    break;
                default:
                    break;
            }

            #pragma unroll
            for (uint x = 0; x < 8; ++x) {
                detection_location[h * 512 + d * 8 + x] = loc[x];
                detection_amplitude[h * 512 + d * 8 + x] = amp[x];
            }
        }
    }
}
