
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
                        locs[p] = READ_CHANNEL(locations[0][p]);
                        amps[p] = READ_CHANNEL(amplitudes[0][p]);
                    }
                    break;
                case 2:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(locations[1][p]);
                        amps[p] = READ_CHANNEL(amplitudes[1][p]);
                    }
                    break;
                case 3:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(locations[2][p]);
                        amps[p] = READ_CHANNEL(amplitudes[2][p]);
                    }
                    break;
                case 4:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(locations[3][p]);
                        amps[p] = READ_CHANNEL(amplitudes[3][p]);
                    }
                    break;
                case 5:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(locations[4][p]);
                        amps[p] = READ_CHANNEL(amplitudes[4][p]);
                    }
                    break;
                case 6:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(locations[5][p]);
                        amps[p] = READ_CHANNEL(amplitudes[5][p]);
                    }
                    break;
                case 7:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(locations[6][p]);
                        amps[p] = READ_CHANNEL(amplitudes[6][p]);
                    }
                    break;
                case 8:
                    #pragma unroll
                    for (uint p = 0; p < 16; ++p) {
                        locs[p] = READ_CHANNEL(locations[7][p]);
                        amps[p] = READ_CHANNEL(amplitudes[7][p]);
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
