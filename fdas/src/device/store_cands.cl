
// Auto-generated file -- see `hsum_codegen.py` and `store_cands.cl.mako`.

__attribute__((max_global_work_dim(0)))
kernel void store_cands(global uint * restrict detection_location,
                        global float * restrict detection_amplitude)
{
    #pragma unroll 1
    for (uint h = 0; h < 8; ++h) {
        #pragma unroll 1
        for (uint d = 0; d < 4; ++d) {
            uint locs[8][2];
            float amps[8][2];
            switch (h) {
                case 0:
                    #pragma unroll
                    for (uint p = 0; p < 8; ++p) {
                        #pragma unroll
                        for (uint q = 0; q < 2; ++q) {
                            locs[p][q] = READ_CHANNEL(detect_to_store_location[0][p][q]);
                            amps[p][q] = READ_CHANNEL(detect_to_store_amplitude[0][p][q]);
                        }
                    }
                    break;
                case 1:
                    #pragma unroll
                    for (uint p = 0; p < 8; ++p) {
                        #pragma unroll
                        for (uint q = 0; q < 2; ++q) {
                            locs[p][q] = READ_CHANNEL(detect_to_store_location[1][p][q]);
                            amps[p][q] = READ_CHANNEL(detect_to_store_amplitude[1][p][q]);
                        }
                    }
                    break;
                case 2:
                    #pragma unroll
                    for (uint p = 0; p < 8; ++p) {
                        #pragma unroll
                        for (uint q = 0; q < 2; ++q) {
                            locs[p][q] = READ_CHANNEL(detect_to_store_location[2][p][q]);
                            amps[p][q] = READ_CHANNEL(detect_to_store_amplitude[2][p][q]);
                        }
                    }
                    break;
                case 3:
                    #pragma unroll
                    for (uint p = 0; p < 8; ++p) {
                        #pragma unroll
                        for (uint q = 0; q < 2; ++q) {
                            locs[p][q] = READ_CHANNEL(detect_to_store_location[3][p][q]);
                            amps[p][q] = READ_CHANNEL(detect_to_store_amplitude[3][p][q]);
                        }
                    }
                    break;
                case 4:
                    #pragma unroll
                    for (uint p = 0; p < 8; ++p) {
                        #pragma unroll
                        for (uint q = 0; q < 2; ++q) {
                            locs[p][q] = READ_CHANNEL(detect_to_store_location[4][p][q]);
                            amps[p][q] = READ_CHANNEL(detect_to_store_amplitude[4][p][q]);
                        }
                    }
                    break;
                case 5:
                    #pragma unroll
                    for (uint p = 0; p < 8; ++p) {
                        #pragma unroll
                        for (uint q = 0; q < 2; ++q) {
                            locs[p][q] = READ_CHANNEL(detect_to_store_location[5][p][q]);
                            amps[p][q] = READ_CHANNEL(detect_to_store_amplitude[5][p][q]);
                        }
                    }
                    break;
                case 6:
                    #pragma unroll
                    for (uint p = 0; p < 8; ++p) {
                        #pragma unroll
                        for (uint q = 0; q < 2; ++q) {
                            locs[p][q] = READ_CHANNEL(detect_to_store_location[6][p][q]);
                            amps[p][q] = READ_CHANNEL(detect_to_store_amplitude[6][p][q]);
                        }
                    }
                    break;
                case 7:
                    #pragma unroll
                    for (uint p = 0; p < 8; ++p) {
                        #pragma unroll
                        for (uint q = 0; q < 2; ++q) {
                            locs[p][q] = READ_CHANNEL(detect_to_store_location[7][p][q]);
                            amps[p][q] = READ_CHANNEL(detect_to_store_amplitude[7][p][q]);
                        }
                    }
                    break;
                default:
                    break;
            }

            #pragma unroll
            for (uint p = 0; p < 8; ++p) {
                #pragma unroll
                for (uint q = 0; q < 2; ++q) {
                    detection_location[h * 64 + d * 16 + p * 2 + q] = locs[p][q];
                    detection_amplitude[h * 64 + d * 16 + p * 2 + q] = amps[p][q];
                }
            }
        }
    }
}
