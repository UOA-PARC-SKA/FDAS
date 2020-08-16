
// Auto-generated file -- see `hsum_codegen.py` and `detect.cl.mako`.
channel float2 detect_to_detect[7][8] __attribute__((depth(0)));
channel uint  detect_to_store_location[8][16] __attribute__((depth(0)));
channel float detect_to_store_amplitude[8][16] __attribute__((depth(0)));

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_1(global uint * restrict dummy,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 8;
        int filter_num[8];
        bool filter_mask[8];
        #pragma unroll
        for (uint p = 0; p < 8; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 2;
            uint channel_num[2];
            #pragma unroll
            for (uint q = 0; q < 2; ++q)
                channel_num[q] = bundle_base + q;

            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p) {
                float2 from_fop = READ_CHANNEL(delay_to_detect[0][p]);
                hsum[p] = from_fop;
                WRITE_CHANNEL(detect_to_detect[0][p], hsum[p]);
            }

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[3] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[4] = (hsum[2].s0 > threshold) & filter_mask[2];
            cand[5] = (hsum[2].s1 > threshold) & filter_mask[2];
            cand[6] = (hsum[3].s0 > threshold) & filter_mask[3];
            cand[7] = (hsum[3].s1 > threshold) & filter_mask[3];
            cand[8] = (hsum[4].s0 > threshold) & filter_mask[4];
            cand[9] = (hsum[4].s1 > threshold) & filter_mask[4];
            cand[10] = (hsum[5].s0 > threshold) & filter_mask[5];
            cand[11] = (hsum[5].s1 > threshold) & filter_mask[5];
            cand[12] = (hsum[6].s0 > threshold) & filter_mask[6];
            cand[13] = (hsum[6].s1 > threshold) & filter_mask[6];
            cand[14] = (hsum[7].s0 > threshold) & filter_mask[7];
            cand[15] = (hsum[7].s1 > threshold) & filter_mask[7];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(1, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(1, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(1, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[1].s0 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(1, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[1].s1 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(1, filter_num[2], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[2].s0 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(1, filter_num[2], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[2].s1 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(1, filter_num[3], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[3].s0 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(1, filter_num[3], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[3].s1 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(1, filter_num[4], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[4].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(1, filter_num[4], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[4].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(1, filter_num[5], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[5].s0 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(1, filter_num[5], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[5].s1 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(1, filter_num[6], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[6].s0 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(1, filter_num[6], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[6].s1 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(1, filter_num[7], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[7].s0 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(1, filter_num[7], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[7].s1 : -1.0f;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            WRITE_CHANNEL(detect_to_store_location[0][x], is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION);
            WRITE_CHANNEL(detect_to_store_amplitude[0][x], is_valid ? amplitude_buffer[d][x] : -1.0f);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_2(global uint * restrict dummy,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 8;
        int filter_num[8];
        bool filter_mask[8];
        #pragma unroll
        for (uint p = 0; p < 8; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 2;
            uint channel_num[2];
            #pragma unroll
            for (uint q = 0; q < 2; ++q)
                channel_num[q] = bundle_base + q;

            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p) {
                float2 from_sp = READ_CHANNEL(delay_to_detect[1][p]);
                float2 from_prev_hp = READ_CHANNEL(detect_to_detect[0][p]);
                hsum[p] = from_prev_hp + from_sp;
                WRITE_CHANNEL(detect_to_detect[1][p], hsum[p]);
            }

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[3] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[4] = (hsum[2].s0 > threshold) & filter_mask[2];
            cand[5] = (hsum[2].s1 > threshold) & filter_mask[2];
            cand[6] = (hsum[3].s0 > threshold) & filter_mask[3];
            cand[7] = (hsum[3].s1 > threshold) & filter_mask[3];
            cand[8] = (hsum[4].s0 > threshold) & filter_mask[4];
            cand[9] = (hsum[4].s1 > threshold) & filter_mask[4];
            cand[10] = (hsum[5].s0 > threshold) & filter_mask[5];
            cand[11] = (hsum[5].s1 > threshold) & filter_mask[5];
            cand[12] = (hsum[6].s0 > threshold) & filter_mask[6];
            cand[13] = (hsum[6].s1 > threshold) & filter_mask[6];
            cand[14] = (hsum[7].s0 > threshold) & filter_mask[7];
            cand[15] = (hsum[7].s1 > threshold) & filter_mask[7];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(2, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(2, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(2, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[1].s0 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(2, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[1].s1 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(2, filter_num[2], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[2].s0 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(2, filter_num[2], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[2].s1 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(2, filter_num[3], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[3].s0 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(2, filter_num[3], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[3].s1 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(2, filter_num[4], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[4].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(2, filter_num[4], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[4].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(2, filter_num[5], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[5].s0 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(2, filter_num[5], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[5].s1 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(2, filter_num[6], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[6].s0 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(2, filter_num[6], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[6].s1 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(2, filter_num[7], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[7].s0 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(2, filter_num[7], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[7].s1 : -1.0f;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            WRITE_CHANNEL(detect_to_store_location[1][x], is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION);
            WRITE_CHANNEL(detect_to_store_amplitude[1][x], is_valid ? amplitude_buffer[d][x] : -1.0f);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_3(global uint * restrict dummy,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 8;
        int filter_num[8];
        bool filter_mask[8];
        #pragma unroll
        for (uint p = 0; p < 8; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 2;
            uint channel_num[2];
            #pragma unroll
            for (uint q = 0; q < 2; ++q)
                channel_num[q] = bundle_base + q;

            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p) {
                float2 from_sp = READ_CHANNEL(delay_to_detect[2][p]);
                float2 from_prev_hp = READ_CHANNEL(detect_to_detect[1][p]);
                hsum[p] = from_prev_hp + from_sp;
                WRITE_CHANNEL(detect_to_detect[2][p], hsum[p]);
            }

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[3] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[4] = (hsum[2].s0 > threshold) & filter_mask[2];
            cand[5] = (hsum[2].s1 > threshold) & filter_mask[2];
            cand[6] = (hsum[3].s0 > threshold) & filter_mask[3];
            cand[7] = (hsum[3].s1 > threshold) & filter_mask[3];
            cand[8] = (hsum[4].s0 > threshold) & filter_mask[4];
            cand[9] = (hsum[4].s1 > threshold) & filter_mask[4];
            cand[10] = (hsum[5].s0 > threshold) & filter_mask[5];
            cand[11] = (hsum[5].s1 > threshold) & filter_mask[5];
            cand[12] = (hsum[6].s0 > threshold) & filter_mask[6];
            cand[13] = (hsum[6].s1 > threshold) & filter_mask[6];
            cand[14] = (hsum[7].s0 > threshold) & filter_mask[7];
            cand[15] = (hsum[7].s1 > threshold) & filter_mask[7];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(3, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(3, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(3, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[1].s0 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(3, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[1].s1 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(3, filter_num[2], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[2].s0 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(3, filter_num[2], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[2].s1 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(3, filter_num[3], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[3].s0 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(3, filter_num[3], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[3].s1 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(3, filter_num[4], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[4].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(3, filter_num[4], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[4].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(3, filter_num[5], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[5].s0 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(3, filter_num[5], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[5].s1 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(3, filter_num[6], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[6].s0 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(3, filter_num[6], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[6].s1 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(3, filter_num[7], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[7].s0 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(3, filter_num[7], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[7].s1 : -1.0f;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            WRITE_CHANNEL(detect_to_store_location[2][x], is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION);
            WRITE_CHANNEL(detect_to_store_amplitude[2][x], is_valid ? amplitude_buffer[d][x] : -1.0f);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_4(global uint * restrict dummy,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 8;
        int filter_num[8];
        bool filter_mask[8];
        #pragma unroll
        for (uint p = 0; p < 8; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 2;
            uint channel_num[2];
            #pragma unroll
            for (uint q = 0; q < 2; ++q)
                channel_num[q] = bundle_base + q;

            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p) {
                float2 from_sp = READ_CHANNEL(delay_to_detect[3][p]);
                float2 from_prev_hp = READ_CHANNEL(detect_to_detect[2][p]);
                hsum[p] = from_prev_hp + from_sp;
                WRITE_CHANNEL(detect_to_detect[3][p], hsum[p]);
            }

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[3] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[4] = (hsum[2].s0 > threshold) & filter_mask[2];
            cand[5] = (hsum[2].s1 > threshold) & filter_mask[2];
            cand[6] = (hsum[3].s0 > threshold) & filter_mask[3];
            cand[7] = (hsum[3].s1 > threshold) & filter_mask[3];
            cand[8] = (hsum[4].s0 > threshold) & filter_mask[4];
            cand[9] = (hsum[4].s1 > threshold) & filter_mask[4];
            cand[10] = (hsum[5].s0 > threshold) & filter_mask[5];
            cand[11] = (hsum[5].s1 > threshold) & filter_mask[5];
            cand[12] = (hsum[6].s0 > threshold) & filter_mask[6];
            cand[13] = (hsum[6].s1 > threshold) & filter_mask[6];
            cand[14] = (hsum[7].s0 > threshold) & filter_mask[7];
            cand[15] = (hsum[7].s1 > threshold) & filter_mask[7];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(4, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(4, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(4, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[1].s0 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(4, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[1].s1 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(4, filter_num[2], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[2].s0 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(4, filter_num[2], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[2].s1 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(4, filter_num[3], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[3].s0 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(4, filter_num[3], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[3].s1 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(4, filter_num[4], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[4].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(4, filter_num[4], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[4].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(4, filter_num[5], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[5].s0 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(4, filter_num[5], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[5].s1 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(4, filter_num[6], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[6].s0 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(4, filter_num[6], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[6].s1 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(4, filter_num[7], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[7].s0 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(4, filter_num[7], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[7].s1 : -1.0f;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            WRITE_CHANNEL(detect_to_store_location[3][x], is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION);
            WRITE_CHANNEL(detect_to_store_amplitude[3][x], is_valid ? amplitude_buffer[d][x] : -1.0f);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_5(global uint * restrict dummy,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 8;
        int filter_num[8];
        bool filter_mask[8];
        #pragma unroll
        for (uint p = 0; p < 8; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 2;
            uint channel_num[2];
            #pragma unroll
            for (uint q = 0; q < 2; ++q)
                channel_num[q] = bundle_base + q;

            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p) {
                float2 from_sp = READ_CHANNEL(delay_to_detect[4][p]);
                float2 from_prev_hp = READ_CHANNEL(detect_to_detect[3][p]);
                hsum[p] = from_prev_hp + from_sp;
                WRITE_CHANNEL(detect_to_detect[4][p], hsum[p]);
            }

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[3] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[4] = (hsum[2].s0 > threshold) & filter_mask[2];
            cand[5] = (hsum[2].s1 > threshold) & filter_mask[2];
            cand[6] = (hsum[3].s0 > threshold) & filter_mask[3];
            cand[7] = (hsum[3].s1 > threshold) & filter_mask[3];
            cand[8] = (hsum[4].s0 > threshold) & filter_mask[4];
            cand[9] = (hsum[4].s1 > threshold) & filter_mask[4];
            cand[10] = (hsum[5].s0 > threshold) & filter_mask[5];
            cand[11] = (hsum[5].s1 > threshold) & filter_mask[5];
            cand[12] = (hsum[6].s0 > threshold) & filter_mask[6];
            cand[13] = (hsum[6].s1 > threshold) & filter_mask[6];
            cand[14] = (hsum[7].s0 > threshold) & filter_mask[7];
            cand[15] = (hsum[7].s1 > threshold) & filter_mask[7];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(5, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(5, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(5, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[1].s0 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(5, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[1].s1 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(5, filter_num[2], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[2].s0 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(5, filter_num[2], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[2].s1 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(5, filter_num[3], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[3].s0 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(5, filter_num[3], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[3].s1 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(5, filter_num[4], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[4].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(5, filter_num[4], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[4].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(5, filter_num[5], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[5].s0 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(5, filter_num[5], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[5].s1 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(5, filter_num[6], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[6].s0 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(5, filter_num[6], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[6].s1 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(5, filter_num[7], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[7].s0 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(5, filter_num[7], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[7].s1 : -1.0f;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            WRITE_CHANNEL(detect_to_store_location[4][x], is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION);
            WRITE_CHANNEL(detect_to_store_amplitude[4][x], is_valid ? amplitude_buffer[d][x] : -1.0f);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_6(global uint * restrict dummy,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 8;
        int filter_num[8];
        bool filter_mask[8];
        #pragma unroll
        for (uint p = 0; p < 8; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 2;
            uint channel_num[2];
            #pragma unroll
            for (uint q = 0; q < 2; ++q)
                channel_num[q] = bundle_base + q;

            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p) {
                float2 from_sp = READ_CHANNEL(delay_to_detect[5][p]);
                float2 from_prev_hp = READ_CHANNEL(detect_to_detect[4][p]);
                hsum[p] = from_prev_hp + from_sp;
                WRITE_CHANNEL(detect_to_detect[5][p], hsum[p]);
            }

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[3] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[4] = (hsum[2].s0 > threshold) & filter_mask[2];
            cand[5] = (hsum[2].s1 > threshold) & filter_mask[2];
            cand[6] = (hsum[3].s0 > threshold) & filter_mask[3];
            cand[7] = (hsum[3].s1 > threshold) & filter_mask[3];
            cand[8] = (hsum[4].s0 > threshold) & filter_mask[4];
            cand[9] = (hsum[4].s1 > threshold) & filter_mask[4];
            cand[10] = (hsum[5].s0 > threshold) & filter_mask[5];
            cand[11] = (hsum[5].s1 > threshold) & filter_mask[5];
            cand[12] = (hsum[6].s0 > threshold) & filter_mask[6];
            cand[13] = (hsum[6].s1 > threshold) & filter_mask[6];
            cand[14] = (hsum[7].s0 > threshold) & filter_mask[7];
            cand[15] = (hsum[7].s1 > threshold) & filter_mask[7];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(6, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(6, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(6, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[1].s0 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(6, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[1].s1 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(6, filter_num[2], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[2].s0 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(6, filter_num[2], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[2].s1 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(6, filter_num[3], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[3].s0 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(6, filter_num[3], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[3].s1 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(6, filter_num[4], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[4].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(6, filter_num[4], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[4].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(6, filter_num[5], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[5].s0 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(6, filter_num[5], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[5].s1 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(6, filter_num[6], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[6].s0 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(6, filter_num[6], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[6].s1 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(6, filter_num[7], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[7].s0 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(6, filter_num[7], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[7].s1 : -1.0f;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            WRITE_CHANNEL(detect_to_store_location[5][x], is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION);
            WRITE_CHANNEL(detect_to_store_amplitude[5][x], is_valid ? amplitude_buffer[d][x] : -1.0f);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_7(global uint * restrict dummy,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 8;
        int filter_num[8];
        bool filter_mask[8];
        #pragma unroll
        for (uint p = 0; p < 8; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 2;
            uint channel_num[2];
            #pragma unroll
            for (uint q = 0; q < 2; ++q)
                channel_num[q] = bundle_base + q;

            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p) {
                float2 from_sp = READ_CHANNEL(delay_to_detect[6][p]);
                float2 from_prev_hp = READ_CHANNEL(detect_to_detect[5][p]);
                hsum[p] = from_prev_hp + from_sp;
                WRITE_CHANNEL(detect_to_detect[6][p], hsum[p]);
            }

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[3] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[4] = (hsum[2].s0 > threshold) & filter_mask[2];
            cand[5] = (hsum[2].s1 > threshold) & filter_mask[2];
            cand[6] = (hsum[3].s0 > threshold) & filter_mask[3];
            cand[7] = (hsum[3].s1 > threshold) & filter_mask[3];
            cand[8] = (hsum[4].s0 > threshold) & filter_mask[4];
            cand[9] = (hsum[4].s1 > threshold) & filter_mask[4];
            cand[10] = (hsum[5].s0 > threshold) & filter_mask[5];
            cand[11] = (hsum[5].s1 > threshold) & filter_mask[5];
            cand[12] = (hsum[6].s0 > threshold) & filter_mask[6];
            cand[13] = (hsum[6].s1 > threshold) & filter_mask[6];
            cand[14] = (hsum[7].s0 > threshold) & filter_mask[7];
            cand[15] = (hsum[7].s1 > threshold) & filter_mask[7];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(7, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(7, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(7, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[1].s0 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(7, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[1].s1 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(7, filter_num[2], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[2].s0 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(7, filter_num[2], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[2].s1 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(7, filter_num[3], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[3].s0 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(7, filter_num[3], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[3].s1 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(7, filter_num[4], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[4].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(7, filter_num[4], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[4].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(7, filter_num[5], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[5].s0 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(7, filter_num[5], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[5].s1 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(7, filter_num[6], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[6].s0 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(7, filter_num[6], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[6].s1 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(7, filter_num[7], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[7].s0 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(7, filter_num[7], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[7].s1 : -1.0f;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            WRITE_CHANNEL(detect_to_store_location[6][x], is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION);
            WRITE_CHANNEL(detect_to_store_amplitude[6][x], is_valid ? amplitude_buffer[d][x] : -1.0f);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_8(global uint * restrict dummy,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 8;
        int filter_num[8];
        bool filter_mask[8];
        #pragma unroll
        for (uint p = 0; p < 8; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 2;
            uint channel_num[2];
            #pragma unroll
            for (uint q = 0; q < 2; ++q)
                channel_num[q] = bundle_base + q;

            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p) {
                float2 from_sp = READ_CHANNEL(delay_to_detect[7][p]);
                float2 from_prev_hp = READ_CHANNEL(detect_to_detect[6][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[3] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[4] = (hsum[2].s0 > threshold) & filter_mask[2];
            cand[5] = (hsum[2].s1 > threshold) & filter_mask[2];
            cand[6] = (hsum[3].s0 > threshold) & filter_mask[3];
            cand[7] = (hsum[3].s1 > threshold) & filter_mask[3];
            cand[8] = (hsum[4].s0 > threshold) & filter_mask[4];
            cand[9] = (hsum[4].s1 > threshold) & filter_mask[4];
            cand[10] = (hsum[5].s0 > threshold) & filter_mask[5];
            cand[11] = (hsum[5].s1 > threshold) & filter_mask[5];
            cand[12] = (hsum[6].s0 > threshold) & filter_mask[6];
            cand[13] = (hsum[6].s1 > threshold) & filter_mask[6];
            cand[14] = (hsum[7].s0 > threshold) & filter_mask[7];
            cand[15] = (hsum[7].s1 > threshold) & filter_mask[7];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(8, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(8, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(8, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[1].s0 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(8, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[1].s1 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(8, filter_num[2], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[2].s0 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(8, filter_num[2], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[2].s1 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(8, filter_num[3], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[3].s0 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(8, filter_num[3], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[3].s1 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(8, filter_num[4], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[4].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(8, filter_num[4], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[4].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(8, filter_num[5], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[5].s0 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(8, filter_num[5], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[5].s1 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(8, filter_num[6], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[6].s0 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(8, filter_num[6], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[6].s1 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(8, filter_num[7], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[7].s0 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(8, filter_num[7], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[7].s1 : -1.0f;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            WRITE_CHANNEL(detect_to_store_location[7][x], is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION);
            WRITE_CHANNEL(detect_to_store_amplitude[7][x], is_valid ? amplitude_buffer[d][x] : -1.0f);
        }
    }
}
