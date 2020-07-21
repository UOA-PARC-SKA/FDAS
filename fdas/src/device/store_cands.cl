
// Auto-generated file -- see `hsum_codegen.py` and `store_cands.cl.mako`.

__attribute__((max_global_work_dim(0)))
kernel void store_cands(global uint * restrict detection_location,
                        global float * restrict detection_amplitude)
{
    #pragma unroll 1
    for (uint harmonic = 1; harmonic <= 8; ++harmonic) {
        #pragma unroll 1
        for (uint slot = 0; slot < 4; ++slot) {
            uint locs[16];
            float amps[16];
            switch (harmonic) {
                case 1:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(detect_to_store_location[0][p]);
                        amps[p] = READ_CHANNEL(detect_to_store_amplitude[0][p]);
                    }
                    break;
                case 2:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(detect_to_store_location[1][p]);
                        amps[p] = READ_CHANNEL(detect_to_store_amplitude[1][p]);
                    }
                    break;
                case 3:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(detect_to_store_location[2][p]);
                        amps[p] = READ_CHANNEL(detect_to_store_amplitude[2][p]);
                    }
                    break;
                case 4:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(detect_to_store_location[3][p]);
                        amps[p] = READ_CHANNEL(detect_to_store_amplitude[3][p]);
                    }
                    break;
                case 5:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(detect_to_store_location[4][p]);
                        amps[p] = READ_CHANNEL(detect_to_store_amplitude[4][p]);
                    }
                    break;
                case 6:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(detect_to_store_location[5][p]);
                        amps[p] = READ_CHANNEL(detect_to_store_amplitude[5][p]);
                    }
                    break;
                case 7:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(detect_to_store_location[6][p]);
                        amps[p] = READ_CHANNEL(detect_to_store_amplitude[6][p]);
                    }
                    break;
                case 8:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(detect_to_store_location[7][p]);
                        amps[p] = READ_CHANNEL(detect_to_store_amplitude[7][p]);
                    }
                    break;
                default:
                    break;
            }

            #pragma unroll
            for (uint p = 0; p < 16; ++p) {
                detection_location[(harmonic - 1) * 64 + slot * 16 + p] = locs[p];
                detection_amplitude[(harmonic - 1) * 64 + slot * 16 + p] = amps[p];
            }
        }
    }
}
