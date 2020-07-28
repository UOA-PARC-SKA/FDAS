
__attribute__((max_global_work_dim(0)))
kernel void store_cands(global uint * restrict detection_location,
                        global float * restrict detection_amplitude)
{
    #pragma unroll 1
    for (uint h = 0; h < ${n_planes}; ++h) {
        #pragma unroll 1
        for (uint d = 0; d < ${detection_sz // group_sz // bundle_sz}; ++d) {
            uint locs[${group_sz}][${bundle_sz}];
            float amps[${group_sz}][${bundle_sz}];
            switch (h) {
            %for h in range(n_planes):
                case ${h}:
                    #pragma unroll
                    for (uint p = 0; p < ${group_sz}; ++p) {
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
            for (uint p = 0; p < ${group_sz}; ++p) {
                #pragma unroll
                for (uint q = 0; q < ${bundle_sz}; ++q) {
                    detection_location[h * ${detection_sz} + d * ${group_sz * bundle_sz} + p * ${bundle_sz} + q] = locs[p][q];
                    detection_amplitude[h * ${detection_sz} + d * ${group_sz * bundle_sz} + p * ${bundle_sz} + q] = amps[p][q];
                }
            }
        }
    }
}
