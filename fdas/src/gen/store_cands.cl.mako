__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void store_cands(global uint * restrict detection_location,
                        global float * restrict detection_power)
{
    for (uint d = 0; d < ${hms_n_planes * hms_detection_sz}; ++d) {
        #pragma unroll
        for (uint x = 0; x < ${hms_slot_sz}; ++x) {
            uint location = read_channel_intel(detect_location_out[${hms_n_planes - 1}][x]);
            float power = read_channel_intel(detect_power_out[${hms_n_planes - 1}][x]);
            detection_location[d * ${hms_slot_sz} + x] = location;
            detection_power[d * ${hms_slot_sz} + x] = power;
        }
    }
}
