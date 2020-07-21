
__attribute__((max_global_work_dim(0)))
kernel void store_cands(global uint * restrict detection_location,
                        global float * restrict detection_amplitude)
{
    #pragma unroll 1
    for (uint harmonic = 1; harmonic <= ${n_planes}; ++harmonic) {
        #pragma unroll 1
        for (uint slot = 0; slot < ${detection_sz // n_parallel}; ++slot) {
            uint locs[${n_parallel}];
            float amps[${n_parallel}];
            switch (harmonic) {
            %for h in range(n_planes):
                case ${h + 1}:
                    #pragma unroll
                    for (uint p = 0; p < ${n_parallel}; ++p) {
                        locs[p] = READ_CHANNEL(locations[${h}][p]);
                        amps[p] = READ_CHANNEL(amplitudes[${h}][p]);
                    }
                    break;
            %endfor
                default:
                    break;
            }

            #pragma unroll
            for (uint p = 0; p < ${n_parallel}; ++p) {
                detection_location[(harmonic - 1) * ${detection_sz} + slot * ${n_parallel} + p] = locs[p];
                detection_amplitude[(harmonic - 1) * ${detection_sz} + slot * ${n_parallel} + p] = amps[p];
            }
        }
    }
}