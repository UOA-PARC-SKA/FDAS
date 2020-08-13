
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void store_cands(global uint * restrict detection_location,
                        global float * restrict detection_amplitude)
{
    #pragma unroll 1
    for (uint h = 0; h < ${n_planes}; ++h) {
        #pragma unroll 1
        for (uint d = 0; d < ${detection_sz}; ++d) {
            uint loc[${group_sz * bundle_sz}];
            float amp[${group_sz * bundle_sz}];
            switch (h) {
            %for h in range(n_planes):
                case ${h}:
                    #pragma unroll
                    for (uint x = 0; x < ${group_sz * bundle_sz}; ++x) {
                        loc[x] = READ_CHANNEL(detect_to_store_location[${h}][x]);
                        amp[x] = READ_CHANNEL(detect_to_store_amplitude[${h}][x]);
                    }
                    break;
            %endfor
                default:
                    break;
            }

            #pragma unroll
            for (uint x = 0; x < ${group_sz * bundle_sz}; ++x) {
                detection_location[h * ${detection_sz * group_sz * bundle_sz} + d * ${group_sz * bundle_sz} + x] = loc[x];
                detection_amplitude[h * ${detection_sz * group_sz * bundle_sz} + d * ${group_sz * bundle_sz} + x] = amp[x];
            }
        }
    }
}
