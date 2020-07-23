
__attribute__((max_global_work_dim(0)))
kernel void store_cands(global uint * restrict detection_location,
                        global float * restrict detection_amplitude)
{
    #pragma unroll 1
    for (uint harmonic = 1; harmonic <= ${n_planes}; ++harmonic) {
        #pragma unroll 1
        for (uint slot = 0; slot < ${detection_sz // n_parallel // bundle_sz}; ++slot) {
            uint locs[${n_parallel}][${bundle_sz}];
            float amps[${n_parallel}][${bundle_sz}];
            switch (harmonic) {
            %for h in range(n_planes):
                case ${h + 1}:
                    #pragma unroll
                    for (uint p = 0; p < ${n_parallel}; ++p) {
                        #pragma unroll
                        for (uint q = 0; q < ${bundle_sz}; ++q) {
                            locs[p][q] = READ_CHANNEL(detect_to_store_location[${h}][p][q]);
                            amps[p][q] = READ_CHANNEL(detect_to_store_amplitude[${h}][p][q]);
                        }
                    }
                    break;
            %endfor
                default:
                    break;
            }

            #pragma unroll
            for (uint p = 0; p < ${n_parallel}; ++p) {
                #pragma unroll
                for (uint q = 0; q < ${bundle_sz}; ++q) {
                    detection_location[(harmonic - 1) * ${detection_sz} + slot * ${n_parallel * bundle_sz} + p * ${bundle_sz} + q] = locs[p][q];
                    detection_amplitude[(harmonic - 1) * ${detection_sz} + slot * ${n_parallel * bundle_sz} + p * ${bundle_sz} + q] = amps[p][q];
                }
            }
        }
    }
}
