
// Auto-generated file -- see `hsum_codegen.py` and `detect.cl.mako`.
channel float2 detect_to_detect[7][8] __attribute__((depth(0)));
channel uint  detect_to_store_location[8][8][2] __attribute__((depth(0)));
channel float detect_to_store_amplitude[8][8][2] __attribute__((depth(0)));

__attribute__((max_global_work_dim(0)))
kernel void detect_1(const float threshold,
                     const uint n_filters,
                     const uint negative_filters,
                     const uint n_filter_groups,
                     const uint n_channel_bundles)
{
    uint location_buffer_0_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_0_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_0_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};

    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint group = 0; group < n_filter_groups; ++group) {
        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(delay_to_detect[0][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                    WRITE_CHANNEL(detect_to_detect[0][p], hsum[p]);

            int filter_0 = group * 8 + 0;
            if (filter_0 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[0].s0 > threshold) {
                    uint slot = next[0];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_0[slot] = HMS_ENCODE_LOCATION(1, filter_0, channel_0);
                    amplitude_buffer_0_0[slot] = hsum[0].s0;
                    next[0] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[0].s1 > threshold) {
                    uint slot = next[1];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_1[slot] = HMS_ENCODE_LOCATION(1, filter_0, channel_1);
                    amplitude_buffer_0_1[slot] = hsum[0].s1;
                    next[1] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_1 = group * 8 + 1;
            if (filter_1 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[1].s0 > threshold) {
                    uint slot = next[2];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_0[slot] = HMS_ENCODE_LOCATION(1, filter_1, channel_0);
                    amplitude_buffer_1_0[slot] = hsum[1].s0;
                    next[2] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[1].s1 > threshold) {
                    uint slot = next[3];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_1[slot] = HMS_ENCODE_LOCATION(1, filter_1, channel_1);
                    amplitude_buffer_1_1[slot] = hsum[1].s1;
                    next[3] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_2 = group * 8 + 2;
            if (filter_2 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[2].s0 > threshold) {
                    uint slot = next[4];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_0[slot] = HMS_ENCODE_LOCATION(1, filter_2, channel_0);
                    amplitude_buffer_2_0[slot] = hsum[2].s0;
                    next[4] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[2].s1 > threshold) {
                    uint slot = next[5];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_1[slot] = HMS_ENCODE_LOCATION(1, filter_2, channel_1);
                    amplitude_buffer_2_1[slot] = hsum[2].s1;
                    next[5] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_3 = group * 8 + 3;
            if (filter_3 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[3].s0 > threshold) {
                    uint slot = next[6];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_0[slot] = HMS_ENCODE_LOCATION(1, filter_3, channel_0);
                    amplitude_buffer_3_0[slot] = hsum[3].s0;
                    next[6] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[3].s1 > threshold) {
                    uint slot = next[7];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_1[slot] = HMS_ENCODE_LOCATION(1, filter_3, channel_1);
                    amplitude_buffer_3_1[slot] = hsum[3].s1;
                    next[7] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_4 = group * 8 + 4;
            if (filter_4 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[4].s0 > threshold) {
                    uint slot = next[8];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_0[slot] = HMS_ENCODE_LOCATION(1, filter_4, channel_0);
                    amplitude_buffer_4_0[slot] = hsum[4].s0;
                    next[8] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[4].s1 > threshold) {
                    uint slot = next[9];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_1[slot] = HMS_ENCODE_LOCATION(1, filter_4, channel_1);
                    amplitude_buffer_4_1[slot] = hsum[4].s1;
                    next[9] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_5 = group * 8 + 5;
            if (filter_5 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[5].s0 > threshold) {
                    uint slot = next[10];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_0[slot] = HMS_ENCODE_LOCATION(1, filter_5, channel_0);
                    amplitude_buffer_5_0[slot] = hsum[5].s0;
                    next[10] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[5].s1 > threshold) {
                    uint slot = next[11];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_1[slot] = HMS_ENCODE_LOCATION(1, filter_5, channel_1);
                    amplitude_buffer_5_1[slot] = hsum[5].s1;
                    next[11] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_6 = group * 8 + 6;
            if (filter_6 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[6].s0 > threshold) {
                    uint slot = next[12];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_0[slot] = HMS_ENCODE_LOCATION(1, filter_6, channel_0);
                    amplitude_buffer_6_0[slot] = hsum[6].s0;
                    next[12] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[6].s1 > threshold) {
                    uint slot = next[13];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_1[slot] = HMS_ENCODE_LOCATION(1, filter_6, channel_1);
                    amplitude_buffer_6_1[slot] = hsum[6].s1;
                    next[13] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_7 = group * 8 + 7;
            if (filter_7 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[7].s0 > threshold) {
                    uint slot = next[14];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_0[slot] = HMS_ENCODE_LOCATION(1, filter_7, channel_0);
                    amplitude_buffer_7_0[slot] = hsum[7].s0;
                    next[14] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[7].s1 > threshold) {
                    uint slot = next[15];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_1[slot] = HMS_ENCODE_LOCATION(1, filter_7, channel_1);
                    amplitude_buffer_7_1[slot] = hsum[7].s1;
                    next[15] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
        }
    }

    for (uint d = 0; d < 4; ++d) {
        WRITE_CHANNEL(detect_to_store_location[0][0][0], location_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][0][0], amplitude_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_location[0][0][1], location_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][0][1], amplitude_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_location[0][1][0], location_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][1][0], amplitude_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_location[0][1][1], location_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][1][1], amplitude_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_location[0][2][0], location_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][2][0], amplitude_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_location[0][2][1], location_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][2][1], amplitude_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_location[0][3][0], location_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][3][0], amplitude_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_location[0][3][1], location_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][3][1], amplitude_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_location[0][4][0], location_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][4][0], amplitude_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_location[0][4][1], location_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][4][1], amplitude_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_location[0][5][0], location_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][5][0], amplitude_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_location[0][5][1], location_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][5][1], amplitude_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_location[0][6][0], location_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][6][0], amplitude_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_location[0][6][1], location_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][6][1], amplitude_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_location[0][7][0], location_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][7][0], amplitude_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_location[0][7][1], location_buffer_7_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][7][1], amplitude_buffer_7_1[d]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_2(const float threshold,
                     const uint n_filters,
                     const uint negative_filters,
                     const uint n_filter_groups,
                     const uint n_channel_bundles)
{
    uint location_buffer_0_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_0_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_0_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};

    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint group = 0; group < n_filter_groups; ++group) {
        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[0][p]) + READ_CHANNEL(delay_to_detect[1][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                    WRITE_CHANNEL(detect_to_detect[1][p], hsum[p]);

            int filter_0 = group * 8 + 0;
            if (filter_0 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[0].s0 > threshold) {
                    uint slot = next[0];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_0[slot] = HMS_ENCODE_LOCATION(2, filter_0, channel_0);
                    amplitude_buffer_0_0[slot] = hsum[0].s0;
                    next[0] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[0].s1 > threshold) {
                    uint slot = next[1];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_1[slot] = HMS_ENCODE_LOCATION(2, filter_0, channel_1);
                    amplitude_buffer_0_1[slot] = hsum[0].s1;
                    next[1] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_1 = group * 8 + 1;
            if (filter_1 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[1].s0 > threshold) {
                    uint slot = next[2];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_0[slot] = HMS_ENCODE_LOCATION(2, filter_1, channel_0);
                    amplitude_buffer_1_0[slot] = hsum[1].s0;
                    next[2] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[1].s1 > threshold) {
                    uint slot = next[3];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_1[slot] = HMS_ENCODE_LOCATION(2, filter_1, channel_1);
                    amplitude_buffer_1_1[slot] = hsum[1].s1;
                    next[3] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_2 = group * 8 + 2;
            if (filter_2 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[2].s0 > threshold) {
                    uint slot = next[4];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_0[slot] = HMS_ENCODE_LOCATION(2, filter_2, channel_0);
                    amplitude_buffer_2_0[slot] = hsum[2].s0;
                    next[4] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[2].s1 > threshold) {
                    uint slot = next[5];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_1[slot] = HMS_ENCODE_LOCATION(2, filter_2, channel_1);
                    amplitude_buffer_2_1[slot] = hsum[2].s1;
                    next[5] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_3 = group * 8 + 3;
            if (filter_3 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[3].s0 > threshold) {
                    uint slot = next[6];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_0[slot] = HMS_ENCODE_LOCATION(2, filter_3, channel_0);
                    amplitude_buffer_3_0[slot] = hsum[3].s0;
                    next[6] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[3].s1 > threshold) {
                    uint slot = next[7];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_1[slot] = HMS_ENCODE_LOCATION(2, filter_3, channel_1);
                    amplitude_buffer_3_1[slot] = hsum[3].s1;
                    next[7] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_4 = group * 8 + 4;
            if (filter_4 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[4].s0 > threshold) {
                    uint slot = next[8];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_0[slot] = HMS_ENCODE_LOCATION(2, filter_4, channel_0);
                    amplitude_buffer_4_0[slot] = hsum[4].s0;
                    next[8] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[4].s1 > threshold) {
                    uint slot = next[9];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_1[slot] = HMS_ENCODE_LOCATION(2, filter_4, channel_1);
                    amplitude_buffer_4_1[slot] = hsum[4].s1;
                    next[9] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_5 = group * 8 + 5;
            if (filter_5 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[5].s0 > threshold) {
                    uint slot = next[10];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_0[slot] = HMS_ENCODE_LOCATION(2, filter_5, channel_0);
                    amplitude_buffer_5_0[slot] = hsum[5].s0;
                    next[10] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[5].s1 > threshold) {
                    uint slot = next[11];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_1[slot] = HMS_ENCODE_LOCATION(2, filter_5, channel_1);
                    amplitude_buffer_5_1[slot] = hsum[5].s1;
                    next[11] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_6 = group * 8 + 6;
            if (filter_6 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[6].s0 > threshold) {
                    uint slot = next[12];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_0[slot] = HMS_ENCODE_LOCATION(2, filter_6, channel_0);
                    amplitude_buffer_6_0[slot] = hsum[6].s0;
                    next[12] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[6].s1 > threshold) {
                    uint slot = next[13];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_1[slot] = HMS_ENCODE_LOCATION(2, filter_6, channel_1);
                    amplitude_buffer_6_1[slot] = hsum[6].s1;
                    next[13] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_7 = group * 8 + 7;
            if (filter_7 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[7].s0 > threshold) {
                    uint slot = next[14];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_0[slot] = HMS_ENCODE_LOCATION(2, filter_7, channel_0);
                    amplitude_buffer_7_0[slot] = hsum[7].s0;
                    next[14] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[7].s1 > threshold) {
                    uint slot = next[15];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_1[slot] = HMS_ENCODE_LOCATION(2, filter_7, channel_1);
                    amplitude_buffer_7_1[slot] = hsum[7].s1;
                    next[15] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
        }
    }

    for (uint d = 0; d < 4; ++d) {
        WRITE_CHANNEL(detect_to_store_location[1][0][0], location_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][0][0], amplitude_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_location[1][0][1], location_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][0][1], amplitude_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_location[1][1][0], location_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][1][0], amplitude_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_location[1][1][1], location_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][1][1], amplitude_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_location[1][2][0], location_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][2][0], amplitude_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_location[1][2][1], location_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][2][1], amplitude_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_location[1][3][0], location_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][3][0], amplitude_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_location[1][3][1], location_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][3][1], amplitude_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_location[1][4][0], location_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][4][0], amplitude_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_location[1][4][1], location_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][4][1], amplitude_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_location[1][5][0], location_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][5][0], amplitude_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_location[1][5][1], location_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][5][1], amplitude_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_location[1][6][0], location_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][6][0], amplitude_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_location[1][6][1], location_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][6][1], amplitude_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_location[1][7][0], location_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][7][0], amplitude_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_location[1][7][1], location_buffer_7_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][7][1], amplitude_buffer_7_1[d]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_3(const float threshold,
                     const uint n_filters,
                     const uint negative_filters,
                     const uint n_filter_groups,
                     const uint n_channel_bundles)
{
    uint location_buffer_0_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_0_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_0_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};

    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint group = 0; group < n_filter_groups; ++group) {
        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[1][p]) + READ_CHANNEL(delay_to_detect[2][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                    WRITE_CHANNEL(detect_to_detect[2][p], hsum[p]);

            int filter_0 = group * 8 + 0;
            if (filter_0 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[0].s0 > threshold) {
                    uint slot = next[0];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_0[slot] = HMS_ENCODE_LOCATION(3, filter_0, channel_0);
                    amplitude_buffer_0_0[slot] = hsum[0].s0;
                    next[0] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[0].s1 > threshold) {
                    uint slot = next[1];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_1[slot] = HMS_ENCODE_LOCATION(3, filter_0, channel_1);
                    amplitude_buffer_0_1[slot] = hsum[0].s1;
                    next[1] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_1 = group * 8 + 1;
            if (filter_1 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[1].s0 > threshold) {
                    uint slot = next[2];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_0[slot] = HMS_ENCODE_LOCATION(3, filter_1, channel_0);
                    amplitude_buffer_1_0[slot] = hsum[1].s0;
                    next[2] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[1].s1 > threshold) {
                    uint slot = next[3];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_1[slot] = HMS_ENCODE_LOCATION(3, filter_1, channel_1);
                    amplitude_buffer_1_1[slot] = hsum[1].s1;
                    next[3] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_2 = group * 8 + 2;
            if (filter_2 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[2].s0 > threshold) {
                    uint slot = next[4];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_0[slot] = HMS_ENCODE_LOCATION(3, filter_2, channel_0);
                    amplitude_buffer_2_0[slot] = hsum[2].s0;
                    next[4] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[2].s1 > threshold) {
                    uint slot = next[5];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_1[slot] = HMS_ENCODE_LOCATION(3, filter_2, channel_1);
                    amplitude_buffer_2_1[slot] = hsum[2].s1;
                    next[5] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_3 = group * 8 + 3;
            if (filter_3 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[3].s0 > threshold) {
                    uint slot = next[6];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_0[slot] = HMS_ENCODE_LOCATION(3, filter_3, channel_0);
                    amplitude_buffer_3_0[slot] = hsum[3].s0;
                    next[6] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[3].s1 > threshold) {
                    uint slot = next[7];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_1[slot] = HMS_ENCODE_LOCATION(3, filter_3, channel_1);
                    amplitude_buffer_3_1[slot] = hsum[3].s1;
                    next[7] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_4 = group * 8 + 4;
            if (filter_4 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[4].s0 > threshold) {
                    uint slot = next[8];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_0[slot] = HMS_ENCODE_LOCATION(3, filter_4, channel_0);
                    amplitude_buffer_4_0[slot] = hsum[4].s0;
                    next[8] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[4].s1 > threshold) {
                    uint slot = next[9];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_1[slot] = HMS_ENCODE_LOCATION(3, filter_4, channel_1);
                    amplitude_buffer_4_1[slot] = hsum[4].s1;
                    next[9] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_5 = group * 8 + 5;
            if (filter_5 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[5].s0 > threshold) {
                    uint slot = next[10];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_0[slot] = HMS_ENCODE_LOCATION(3, filter_5, channel_0);
                    amplitude_buffer_5_0[slot] = hsum[5].s0;
                    next[10] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[5].s1 > threshold) {
                    uint slot = next[11];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_1[slot] = HMS_ENCODE_LOCATION(3, filter_5, channel_1);
                    amplitude_buffer_5_1[slot] = hsum[5].s1;
                    next[11] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_6 = group * 8 + 6;
            if (filter_6 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[6].s0 > threshold) {
                    uint slot = next[12];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_0[slot] = HMS_ENCODE_LOCATION(3, filter_6, channel_0);
                    amplitude_buffer_6_0[slot] = hsum[6].s0;
                    next[12] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[6].s1 > threshold) {
                    uint slot = next[13];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_1[slot] = HMS_ENCODE_LOCATION(3, filter_6, channel_1);
                    amplitude_buffer_6_1[slot] = hsum[6].s1;
                    next[13] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_7 = group * 8 + 7;
            if (filter_7 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[7].s0 > threshold) {
                    uint slot = next[14];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_0[slot] = HMS_ENCODE_LOCATION(3, filter_7, channel_0);
                    amplitude_buffer_7_0[slot] = hsum[7].s0;
                    next[14] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[7].s1 > threshold) {
                    uint slot = next[15];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_1[slot] = HMS_ENCODE_LOCATION(3, filter_7, channel_1);
                    amplitude_buffer_7_1[slot] = hsum[7].s1;
                    next[15] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
        }
    }

    for (uint d = 0; d < 4; ++d) {
        WRITE_CHANNEL(detect_to_store_location[2][0][0], location_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][0][0], amplitude_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_location[2][0][1], location_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][0][1], amplitude_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_location[2][1][0], location_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][1][0], amplitude_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_location[2][1][1], location_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][1][1], amplitude_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_location[2][2][0], location_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][2][0], amplitude_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_location[2][2][1], location_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][2][1], amplitude_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_location[2][3][0], location_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][3][0], amplitude_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_location[2][3][1], location_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][3][1], amplitude_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_location[2][4][0], location_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][4][0], amplitude_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_location[2][4][1], location_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][4][1], amplitude_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_location[2][5][0], location_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][5][0], amplitude_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_location[2][5][1], location_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][5][1], amplitude_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_location[2][6][0], location_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][6][0], amplitude_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_location[2][6][1], location_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][6][1], amplitude_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_location[2][7][0], location_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][7][0], amplitude_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_location[2][7][1], location_buffer_7_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][7][1], amplitude_buffer_7_1[d]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_4(const float threshold,
                     const uint n_filters,
                     const uint negative_filters,
                     const uint n_filter_groups,
                     const uint n_channel_bundles)
{
    uint location_buffer_0_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_0_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_0_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};

    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint group = 0; group < n_filter_groups; ++group) {
        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[2][p]) + READ_CHANNEL(delay_to_detect[3][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                    WRITE_CHANNEL(detect_to_detect[3][p], hsum[p]);

            int filter_0 = group * 8 + 0;
            if (filter_0 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[0].s0 > threshold) {
                    uint slot = next[0];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_0[slot] = HMS_ENCODE_LOCATION(4, filter_0, channel_0);
                    amplitude_buffer_0_0[slot] = hsum[0].s0;
                    next[0] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[0].s1 > threshold) {
                    uint slot = next[1];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_1[slot] = HMS_ENCODE_LOCATION(4, filter_0, channel_1);
                    amplitude_buffer_0_1[slot] = hsum[0].s1;
                    next[1] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_1 = group * 8 + 1;
            if (filter_1 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[1].s0 > threshold) {
                    uint slot = next[2];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_0[slot] = HMS_ENCODE_LOCATION(4, filter_1, channel_0);
                    amplitude_buffer_1_0[slot] = hsum[1].s0;
                    next[2] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[1].s1 > threshold) {
                    uint slot = next[3];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_1[slot] = HMS_ENCODE_LOCATION(4, filter_1, channel_1);
                    amplitude_buffer_1_1[slot] = hsum[1].s1;
                    next[3] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_2 = group * 8 + 2;
            if (filter_2 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[2].s0 > threshold) {
                    uint slot = next[4];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_0[slot] = HMS_ENCODE_LOCATION(4, filter_2, channel_0);
                    amplitude_buffer_2_0[slot] = hsum[2].s0;
                    next[4] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[2].s1 > threshold) {
                    uint slot = next[5];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_1[slot] = HMS_ENCODE_LOCATION(4, filter_2, channel_1);
                    amplitude_buffer_2_1[slot] = hsum[2].s1;
                    next[5] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_3 = group * 8 + 3;
            if (filter_3 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[3].s0 > threshold) {
                    uint slot = next[6];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_0[slot] = HMS_ENCODE_LOCATION(4, filter_3, channel_0);
                    amplitude_buffer_3_0[slot] = hsum[3].s0;
                    next[6] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[3].s1 > threshold) {
                    uint slot = next[7];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_1[slot] = HMS_ENCODE_LOCATION(4, filter_3, channel_1);
                    amplitude_buffer_3_1[slot] = hsum[3].s1;
                    next[7] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_4 = group * 8 + 4;
            if (filter_4 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[4].s0 > threshold) {
                    uint slot = next[8];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_0[slot] = HMS_ENCODE_LOCATION(4, filter_4, channel_0);
                    amplitude_buffer_4_0[slot] = hsum[4].s0;
                    next[8] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[4].s1 > threshold) {
                    uint slot = next[9];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_1[slot] = HMS_ENCODE_LOCATION(4, filter_4, channel_1);
                    amplitude_buffer_4_1[slot] = hsum[4].s1;
                    next[9] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_5 = group * 8 + 5;
            if (filter_5 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[5].s0 > threshold) {
                    uint slot = next[10];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_0[slot] = HMS_ENCODE_LOCATION(4, filter_5, channel_0);
                    amplitude_buffer_5_0[slot] = hsum[5].s0;
                    next[10] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[5].s1 > threshold) {
                    uint slot = next[11];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_1[slot] = HMS_ENCODE_LOCATION(4, filter_5, channel_1);
                    amplitude_buffer_5_1[slot] = hsum[5].s1;
                    next[11] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_6 = group * 8 + 6;
            if (filter_6 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[6].s0 > threshold) {
                    uint slot = next[12];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_0[slot] = HMS_ENCODE_LOCATION(4, filter_6, channel_0);
                    amplitude_buffer_6_0[slot] = hsum[6].s0;
                    next[12] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[6].s1 > threshold) {
                    uint slot = next[13];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_1[slot] = HMS_ENCODE_LOCATION(4, filter_6, channel_1);
                    amplitude_buffer_6_1[slot] = hsum[6].s1;
                    next[13] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_7 = group * 8 + 7;
            if (filter_7 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[7].s0 > threshold) {
                    uint slot = next[14];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_0[slot] = HMS_ENCODE_LOCATION(4, filter_7, channel_0);
                    amplitude_buffer_7_0[slot] = hsum[7].s0;
                    next[14] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[7].s1 > threshold) {
                    uint slot = next[15];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_1[slot] = HMS_ENCODE_LOCATION(4, filter_7, channel_1);
                    amplitude_buffer_7_1[slot] = hsum[7].s1;
                    next[15] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
        }
    }

    for (uint d = 0; d < 4; ++d) {
        WRITE_CHANNEL(detect_to_store_location[3][0][0], location_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][0][0], amplitude_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_location[3][0][1], location_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][0][1], amplitude_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_location[3][1][0], location_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][1][0], amplitude_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_location[3][1][1], location_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][1][1], amplitude_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_location[3][2][0], location_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][2][0], amplitude_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_location[3][2][1], location_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][2][1], amplitude_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_location[3][3][0], location_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][3][0], amplitude_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_location[3][3][1], location_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][3][1], amplitude_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_location[3][4][0], location_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][4][0], amplitude_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_location[3][4][1], location_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][4][1], amplitude_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_location[3][5][0], location_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][5][0], amplitude_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_location[3][5][1], location_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][5][1], amplitude_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_location[3][6][0], location_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][6][0], amplitude_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_location[3][6][1], location_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][6][1], amplitude_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_location[3][7][0], location_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][7][0], amplitude_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_location[3][7][1], location_buffer_7_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][7][1], amplitude_buffer_7_1[d]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_5(const float threshold,
                     const uint n_filters,
                     const uint negative_filters,
                     const uint n_filter_groups,
                     const uint n_channel_bundles)
{
    uint location_buffer_0_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_0_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_0_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};

    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint group = 0; group < n_filter_groups; ++group) {
        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[3][p]) + READ_CHANNEL(delay_to_detect[4][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                    WRITE_CHANNEL(detect_to_detect[4][p], hsum[p]);

            int filter_0 = group * 8 + 0;
            if (filter_0 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[0].s0 > threshold) {
                    uint slot = next[0];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_0[slot] = HMS_ENCODE_LOCATION(5, filter_0, channel_0);
                    amplitude_buffer_0_0[slot] = hsum[0].s0;
                    next[0] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[0].s1 > threshold) {
                    uint slot = next[1];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_1[slot] = HMS_ENCODE_LOCATION(5, filter_0, channel_1);
                    amplitude_buffer_0_1[slot] = hsum[0].s1;
                    next[1] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_1 = group * 8 + 1;
            if (filter_1 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[1].s0 > threshold) {
                    uint slot = next[2];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_0[slot] = HMS_ENCODE_LOCATION(5, filter_1, channel_0);
                    amplitude_buffer_1_0[slot] = hsum[1].s0;
                    next[2] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[1].s1 > threshold) {
                    uint slot = next[3];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_1[slot] = HMS_ENCODE_LOCATION(5, filter_1, channel_1);
                    amplitude_buffer_1_1[slot] = hsum[1].s1;
                    next[3] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_2 = group * 8 + 2;
            if (filter_2 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[2].s0 > threshold) {
                    uint slot = next[4];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_0[slot] = HMS_ENCODE_LOCATION(5, filter_2, channel_0);
                    amplitude_buffer_2_0[slot] = hsum[2].s0;
                    next[4] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[2].s1 > threshold) {
                    uint slot = next[5];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_1[slot] = HMS_ENCODE_LOCATION(5, filter_2, channel_1);
                    amplitude_buffer_2_1[slot] = hsum[2].s1;
                    next[5] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_3 = group * 8 + 3;
            if (filter_3 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[3].s0 > threshold) {
                    uint slot = next[6];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_0[slot] = HMS_ENCODE_LOCATION(5, filter_3, channel_0);
                    amplitude_buffer_3_0[slot] = hsum[3].s0;
                    next[6] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[3].s1 > threshold) {
                    uint slot = next[7];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_1[slot] = HMS_ENCODE_LOCATION(5, filter_3, channel_1);
                    amplitude_buffer_3_1[slot] = hsum[3].s1;
                    next[7] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_4 = group * 8 + 4;
            if (filter_4 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[4].s0 > threshold) {
                    uint slot = next[8];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_0[slot] = HMS_ENCODE_LOCATION(5, filter_4, channel_0);
                    amplitude_buffer_4_0[slot] = hsum[4].s0;
                    next[8] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[4].s1 > threshold) {
                    uint slot = next[9];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_1[slot] = HMS_ENCODE_LOCATION(5, filter_4, channel_1);
                    amplitude_buffer_4_1[slot] = hsum[4].s1;
                    next[9] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_5 = group * 8 + 5;
            if (filter_5 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[5].s0 > threshold) {
                    uint slot = next[10];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_0[slot] = HMS_ENCODE_LOCATION(5, filter_5, channel_0);
                    amplitude_buffer_5_0[slot] = hsum[5].s0;
                    next[10] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[5].s1 > threshold) {
                    uint slot = next[11];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_1[slot] = HMS_ENCODE_LOCATION(5, filter_5, channel_1);
                    amplitude_buffer_5_1[slot] = hsum[5].s1;
                    next[11] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_6 = group * 8 + 6;
            if (filter_6 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[6].s0 > threshold) {
                    uint slot = next[12];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_0[slot] = HMS_ENCODE_LOCATION(5, filter_6, channel_0);
                    amplitude_buffer_6_0[slot] = hsum[6].s0;
                    next[12] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[6].s1 > threshold) {
                    uint slot = next[13];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_1[slot] = HMS_ENCODE_LOCATION(5, filter_6, channel_1);
                    amplitude_buffer_6_1[slot] = hsum[6].s1;
                    next[13] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_7 = group * 8 + 7;
            if (filter_7 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[7].s0 > threshold) {
                    uint slot = next[14];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_0[slot] = HMS_ENCODE_LOCATION(5, filter_7, channel_0);
                    amplitude_buffer_7_0[slot] = hsum[7].s0;
                    next[14] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[7].s1 > threshold) {
                    uint slot = next[15];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_1[slot] = HMS_ENCODE_LOCATION(5, filter_7, channel_1);
                    amplitude_buffer_7_1[slot] = hsum[7].s1;
                    next[15] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
        }
    }

    for (uint d = 0; d < 4; ++d) {
        WRITE_CHANNEL(detect_to_store_location[4][0][0], location_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][0][0], amplitude_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_location[4][0][1], location_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][0][1], amplitude_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_location[4][1][0], location_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][1][0], amplitude_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_location[4][1][1], location_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][1][1], amplitude_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_location[4][2][0], location_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][2][0], amplitude_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_location[4][2][1], location_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][2][1], amplitude_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_location[4][3][0], location_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][3][0], amplitude_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_location[4][3][1], location_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][3][1], amplitude_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_location[4][4][0], location_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][4][0], amplitude_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_location[4][4][1], location_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][4][1], amplitude_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_location[4][5][0], location_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][5][0], amplitude_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_location[4][5][1], location_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][5][1], amplitude_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_location[4][6][0], location_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][6][0], amplitude_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_location[4][6][1], location_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][6][1], amplitude_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_location[4][7][0], location_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][7][0], amplitude_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_location[4][7][1], location_buffer_7_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][7][1], amplitude_buffer_7_1[d]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_6(const float threshold,
                     const uint n_filters,
                     const uint negative_filters,
                     const uint n_filter_groups,
                     const uint n_channel_bundles)
{
    uint location_buffer_0_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_0_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_0_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};

    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint group = 0; group < n_filter_groups; ++group) {
        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[4][p]) + READ_CHANNEL(delay_to_detect[5][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                    WRITE_CHANNEL(detect_to_detect[5][p], hsum[p]);

            int filter_0 = group * 8 + 0;
            if (filter_0 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[0].s0 > threshold) {
                    uint slot = next[0];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_0[slot] = HMS_ENCODE_LOCATION(6, filter_0, channel_0);
                    amplitude_buffer_0_0[slot] = hsum[0].s0;
                    next[0] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[0].s1 > threshold) {
                    uint slot = next[1];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_1[slot] = HMS_ENCODE_LOCATION(6, filter_0, channel_1);
                    amplitude_buffer_0_1[slot] = hsum[0].s1;
                    next[1] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_1 = group * 8 + 1;
            if (filter_1 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[1].s0 > threshold) {
                    uint slot = next[2];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_0[slot] = HMS_ENCODE_LOCATION(6, filter_1, channel_0);
                    amplitude_buffer_1_0[slot] = hsum[1].s0;
                    next[2] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[1].s1 > threshold) {
                    uint slot = next[3];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_1[slot] = HMS_ENCODE_LOCATION(6, filter_1, channel_1);
                    amplitude_buffer_1_1[slot] = hsum[1].s1;
                    next[3] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_2 = group * 8 + 2;
            if (filter_2 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[2].s0 > threshold) {
                    uint slot = next[4];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_0[slot] = HMS_ENCODE_LOCATION(6, filter_2, channel_0);
                    amplitude_buffer_2_0[slot] = hsum[2].s0;
                    next[4] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[2].s1 > threshold) {
                    uint slot = next[5];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_1[slot] = HMS_ENCODE_LOCATION(6, filter_2, channel_1);
                    amplitude_buffer_2_1[slot] = hsum[2].s1;
                    next[5] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_3 = group * 8 + 3;
            if (filter_3 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[3].s0 > threshold) {
                    uint slot = next[6];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_0[slot] = HMS_ENCODE_LOCATION(6, filter_3, channel_0);
                    amplitude_buffer_3_0[slot] = hsum[3].s0;
                    next[6] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[3].s1 > threshold) {
                    uint slot = next[7];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_1[slot] = HMS_ENCODE_LOCATION(6, filter_3, channel_1);
                    amplitude_buffer_3_1[slot] = hsum[3].s1;
                    next[7] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_4 = group * 8 + 4;
            if (filter_4 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[4].s0 > threshold) {
                    uint slot = next[8];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_0[slot] = HMS_ENCODE_LOCATION(6, filter_4, channel_0);
                    amplitude_buffer_4_0[slot] = hsum[4].s0;
                    next[8] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[4].s1 > threshold) {
                    uint slot = next[9];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_1[slot] = HMS_ENCODE_LOCATION(6, filter_4, channel_1);
                    amplitude_buffer_4_1[slot] = hsum[4].s1;
                    next[9] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_5 = group * 8 + 5;
            if (filter_5 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[5].s0 > threshold) {
                    uint slot = next[10];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_0[slot] = HMS_ENCODE_LOCATION(6, filter_5, channel_0);
                    amplitude_buffer_5_0[slot] = hsum[5].s0;
                    next[10] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[5].s1 > threshold) {
                    uint slot = next[11];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_1[slot] = HMS_ENCODE_LOCATION(6, filter_5, channel_1);
                    amplitude_buffer_5_1[slot] = hsum[5].s1;
                    next[11] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_6 = group * 8 + 6;
            if (filter_6 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[6].s0 > threshold) {
                    uint slot = next[12];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_0[slot] = HMS_ENCODE_LOCATION(6, filter_6, channel_0);
                    amplitude_buffer_6_0[slot] = hsum[6].s0;
                    next[12] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[6].s1 > threshold) {
                    uint slot = next[13];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_1[slot] = HMS_ENCODE_LOCATION(6, filter_6, channel_1);
                    amplitude_buffer_6_1[slot] = hsum[6].s1;
                    next[13] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_7 = group * 8 + 7;
            if (filter_7 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[7].s0 > threshold) {
                    uint slot = next[14];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_0[slot] = HMS_ENCODE_LOCATION(6, filter_7, channel_0);
                    amplitude_buffer_7_0[slot] = hsum[7].s0;
                    next[14] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[7].s1 > threshold) {
                    uint slot = next[15];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_1[slot] = HMS_ENCODE_LOCATION(6, filter_7, channel_1);
                    amplitude_buffer_7_1[slot] = hsum[7].s1;
                    next[15] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
        }
    }

    for (uint d = 0; d < 4; ++d) {
        WRITE_CHANNEL(detect_to_store_location[5][0][0], location_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][0][0], amplitude_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_location[5][0][1], location_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][0][1], amplitude_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_location[5][1][0], location_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][1][0], amplitude_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_location[5][1][1], location_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][1][1], amplitude_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_location[5][2][0], location_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][2][0], amplitude_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_location[5][2][1], location_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][2][1], amplitude_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_location[5][3][0], location_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][3][0], amplitude_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_location[5][3][1], location_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][3][1], amplitude_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_location[5][4][0], location_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][4][0], amplitude_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_location[5][4][1], location_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][4][1], amplitude_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_location[5][5][0], location_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][5][0], amplitude_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_location[5][5][1], location_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][5][1], amplitude_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_location[5][6][0], location_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][6][0], amplitude_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_location[5][6][1], location_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][6][1], amplitude_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_location[5][7][0], location_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][7][0], amplitude_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_location[5][7][1], location_buffer_7_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][7][1], amplitude_buffer_7_1[d]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_7(const float threshold,
                     const uint n_filters,
                     const uint negative_filters,
                     const uint n_filter_groups,
                     const uint n_channel_bundles)
{
    uint location_buffer_0_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_0_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_0_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};

    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint group = 0; group < n_filter_groups; ++group) {
        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[5][p]) + READ_CHANNEL(delay_to_detect[6][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                    WRITE_CHANNEL(detect_to_detect[6][p], hsum[p]);

            int filter_0 = group * 8 + 0;
            if (filter_0 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[0].s0 > threshold) {
                    uint slot = next[0];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_0[slot] = HMS_ENCODE_LOCATION(7, filter_0, channel_0);
                    amplitude_buffer_0_0[slot] = hsum[0].s0;
                    next[0] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[0].s1 > threshold) {
                    uint slot = next[1];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_1[slot] = HMS_ENCODE_LOCATION(7, filter_0, channel_1);
                    amplitude_buffer_0_1[slot] = hsum[0].s1;
                    next[1] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_1 = group * 8 + 1;
            if (filter_1 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[1].s0 > threshold) {
                    uint slot = next[2];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_0[slot] = HMS_ENCODE_LOCATION(7, filter_1, channel_0);
                    amplitude_buffer_1_0[slot] = hsum[1].s0;
                    next[2] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[1].s1 > threshold) {
                    uint slot = next[3];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_1[slot] = HMS_ENCODE_LOCATION(7, filter_1, channel_1);
                    amplitude_buffer_1_1[slot] = hsum[1].s1;
                    next[3] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_2 = group * 8 + 2;
            if (filter_2 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[2].s0 > threshold) {
                    uint slot = next[4];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_0[slot] = HMS_ENCODE_LOCATION(7, filter_2, channel_0);
                    amplitude_buffer_2_0[slot] = hsum[2].s0;
                    next[4] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[2].s1 > threshold) {
                    uint slot = next[5];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_1[slot] = HMS_ENCODE_LOCATION(7, filter_2, channel_1);
                    amplitude_buffer_2_1[slot] = hsum[2].s1;
                    next[5] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_3 = group * 8 + 3;
            if (filter_3 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[3].s0 > threshold) {
                    uint slot = next[6];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_0[slot] = HMS_ENCODE_LOCATION(7, filter_3, channel_0);
                    amplitude_buffer_3_0[slot] = hsum[3].s0;
                    next[6] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[3].s1 > threshold) {
                    uint slot = next[7];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_1[slot] = HMS_ENCODE_LOCATION(7, filter_3, channel_1);
                    amplitude_buffer_3_1[slot] = hsum[3].s1;
                    next[7] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_4 = group * 8 + 4;
            if (filter_4 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[4].s0 > threshold) {
                    uint slot = next[8];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_0[slot] = HMS_ENCODE_LOCATION(7, filter_4, channel_0);
                    amplitude_buffer_4_0[slot] = hsum[4].s0;
                    next[8] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[4].s1 > threshold) {
                    uint slot = next[9];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_1[slot] = HMS_ENCODE_LOCATION(7, filter_4, channel_1);
                    amplitude_buffer_4_1[slot] = hsum[4].s1;
                    next[9] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_5 = group * 8 + 5;
            if (filter_5 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[5].s0 > threshold) {
                    uint slot = next[10];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_0[slot] = HMS_ENCODE_LOCATION(7, filter_5, channel_0);
                    amplitude_buffer_5_0[slot] = hsum[5].s0;
                    next[10] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[5].s1 > threshold) {
                    uint slot = next[11];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_1[slot] = HMS_ENCODE_LOCATION(7, filter_5, channel_1);
                    amplitude_buffer_5_1[slot] = hsum[5].s1;
                    next[11] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_6 = group * 8 + 6;
            if (filter_6 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[6].s0 > threshold) {
                    uint slot = next[12];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_0[slot] = HMS_ENCODE_LOCATION(7, filter_6, channel_0);
                    amplitude_buffer_6_0[slot] = hsum[6].s0;
                    next[12] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[6].s1 > threshold) {
                    uint slot = next[13];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_1[slot] = HMS_ENCODE_LOCATION(7, filter_6, channel_1);
                    amplitude_buffer_6_1[slot] = hsum[6].s1;
                    next[13] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_7 = group * 8 + 7;
            if (filter_7 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[7].s0 > threshold) {
                    uint slot = next[14];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_0[slot] = HMS_ENCODE_LOCATION(7, filter_7, channel_0);
                    amplitude_buffer_7_0[slot] = hsum[7].s0;
                    next[14] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[7].s1 > threshold) {
                    uint slot = next[15];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_1[slot] = HMS_ENCODE_LOCATION(7, filter_7, channel_1);
                    amplitude_buffer_7_1[slot] = hsum[7].s1;
                    next[15] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
        }
    }

    for (uint d = 0; d < 4; ++d) {
        WRITE_CHANNEL(detect_to_store_location[6][0][0], location_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][0][0], amplitude_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_location[6][0][1], location_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][0][1], amplitude_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_location[6][1][0], location_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][1][0], amplitude_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_location[6][1][1], location_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][1][1], amplitude_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_location[6][2][0], location_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][2][0], amplitude_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_location[6][2][1], location_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][2][1], amplitude_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_location[6][3][0], location_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][3][0], amplitude_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_location[6][3][1], location_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][3][1], amplitude_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_location[6][4][0], location_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][4][0], amplitude_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_location[6][4][1], location_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][4][1], amplitude_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_location[6][5][0], location_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][5][0], amplitude_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_location[6][5][1], location_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][5][1], amplitude_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_location[6][6][0], location_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][6][0], amplitude_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_location[6][6][1], location_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][6][1], amplitude_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_location[6][7][0], location_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][7][0], amplitude_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_location[6][7][1], location_buffer_7_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][7][1], amplitude_buffer_7_1[d]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_8(const float threshold,
                     const uint n_filters,
                     const uint negative_filters,
                     const uint n_filter_groups,
                     const uint n_channel_bundles)
{
    uint location_buffer_0_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_0_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_0_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};

    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint group = 0; group < n_filter_groups; ++group) {
        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            float2 hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[6][p]) + READ_CHANNEL(delay_to_detect[7][p]);


            int filter_0 = group * 8 + 0;
            if (filter_0 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[0].s0 > threshold) {
                    uint slot = next[0];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_0[slot] = HMS_ENCODE_LOCATION(8, filter_0, channel_0);
                    amplitude_buffer_0_0[slot] = hsum[0].s0;
                    next[0] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[0].s1 > threshold) {
                    uint slot = next[1];
                    if (negative_filters)
                        filter_0 = -filter_0;
                    location_buffer_0_1[slot] = HMS_ENCODE_LOCATION(8, filter_0, channel_1);
                    amplitude_buffer_0_1[slot] = hsum[0].s1;
                    next[1] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_1 = group * 8 + 1;
            if (filter_1 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[1].s0 > threshold) {
                    uint slot = next[2];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_0[slot] = HMS_ENCODE_LOCATION(8, filter_1, channel_0);
                    amplitude_buffer_1_0[slot] = hsum[1].s0;
                    next[2] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[1].s1 > threshold) {
                    uint slot = next[3];
                    if (negative_filters)
                        filter_1 = -filter_1;
                    location_buffer_1_1[slot] = HMS_ENCODE_LOCATION(8, filter_1, channel_1);
                    amplitude_buffer_1_1[slot] = hsum[1].s1;
                    next[3] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_2 = group * 8 + 2;
            if (filter_2 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[2].s0 > threshold) {
                    uint slot = next[4];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_0[slot] = HMS_ENCODE_LOCATION(8, filter_2, channel_0);
                    amplitude_buffer_2_0[slot] = hsum[2].s0;
                    next[4] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[2].s1 > threshold) {
                    uint slot = next[5];
                    if (negative_filters)
                        filter_2 = -filter_2;
                    location_buffer_2_1[slot] = HMS_ENCODE_LOCATION(8, filter_2, channel_1);
                    amplitude_buffer_2_1[slot] = hsum[2].s1;
                    next[5] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_3 = group * 8 + 3;
            if (filter_3 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[3].s0 > threshold) {
                    uint slot = next[6];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_0[slot] = HMS_ENCODE_LOCATION(8, filter_3, channel_0);
                    amplitude_buffer_3_0[slot] = hsum[3].s0;
                    next[6] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[3].s1 > threshold) {
                    uint slot = next[7];
                    if (negative_filters)
                        filter_3 = -filter_3;
                    location_buffer_3_1[slot] = HMS_ENCODE_LOCATION(8, filter_3, channel_1);
                    amplitude_buffer_3_1[slot] = hsum[3].s1;
                    next[7] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_4 = group * 8 + 4;
            if (filter_4 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[4].s0 > threshold) {
                    uint slot = next[8];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_0[slot] = HMS_ENCODE_LOCATION(8, filter_4, channel_0);
                    amplitude_buffer_4_0[slot] = hsum[4].s0;
                    next[8] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[4].s1 > threshold) {
                    uint slot = next[9];
                    if (negative_filters)
                        filter_4 = -filter_4;
                    location_buffer_4_1[slot] = HMS_ENCODE_LOCATION(8, filter_4, channel_1);
                    amplitude_buffer_4_1[slot] = hsum[4].s1;
                    next[9] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_5 = group * 8 + 5;
            if (filter_5 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[5].s0 > threshold) {
                    uint slot = next[10];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_0[slot] = HMS_ENCODE_LOCATION(8, filter_5, channel_0);
                    amplitude_buffer_5_0[slot] = hsum[5].s0;
                    next[10] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[5].s1 > threshold) {
                    uint slot = next[11];
                    if (negative_filters)
                        filter_5 = -filter_5;
                    location_buffer_5_1[slot] = HMS_ENCODE_LOCATION(8, filter_5, channel_1);
                    amplitude_buffer_5_1[slot] = hsum[5].s1;
                    next[11] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_6 = group * 8 + 6;
            if (filter_6 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[6].s0 > threshold) {
                    uint slot = next[12];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_0[slot] = HMS_ENCODE_LOCATION(8, filter_6, channel_0);
                    amplitude_buffer_6_0[slot] = hsum[6].s0;
                    next[12] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[6].s1 > threshold) {
                    uint slot = next[13];
                    if (negative_filters)
                        filter_6 = -filter_6;
                    location_buffer_6_1[slot] = HMS_ENCODE_LOCATION(8, filter_6, channel_1);
                    amplitude_buffer_6_1[slot] = hsum[6].s1;
                    next[13] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
            int filter_7 = group * 8 + 7;
            if (filter_7 < n_filters) {
                uint channel_0 = bundle * 2 + 0;
                if (hsum[7].s0 > threshold) {
                    uint slot = next[14];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_0[slot] = HMS_ENCODE_LOCATION(8, filter_7, channel_0);
                    amplitude_buffer_7_0[slot] = hsum[7].s0;
                    next[14] = (slot + 1) < 4 ? slot + 1 : 0;
                }
                uint channel_1 = bundle * 2 + 1;
                if (hsum[7].s1 > threshold) {
                    uint slot = next[15];
                    if (negative_filters)
                        filter_7 = -filter_7;
                    location_buffer_7_1[slot] = HMS_ENCODE_LOCATION(8, filter_7, channel_1);
                    amplitude_buffer_7_1[slot] = hsum[7].s1;
                    next[15] = (slot + 1) < 4 ? slot + 1 : 0;
                }
            }
        }
    }

    for (uint d = 0; d < 4; ++d) {
        WRITE_CHANNEL(detect_to_store_location[7][0][0], location_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][0][0], amplitude_buffer_0_0[d]);
        WRITE_CHANNEL(detect_to_store_location[7][0][1], location_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][0][1], amplitude_buffer_0_1[d]);
        WRITE_CHANNEL(detect_to_store_location[7][1][0], location_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][1][0], amplitude_buffer_1_0[d]);
        WRITE_CHANNEL(detect_to_store_location[7][1][1], location_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][1][1], amplitude_buffer_1_1[d]);
        WRITE_CHANNEL(detect_to_store_location[7][2][0], location_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][2][0], amplitude_buffer_2_0[d]);
        WRITE_CHANNEL(detect_to_store_location[7][2][1], location_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][2][1], amplitude_buffer_2_1[d]);
        WRITE_CHANNEL(detect_to_store_location[7][3][0], location_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][3][0], amplitude_buffer_3_0[d]);
        WRITE_CHANNEL(detect_to_store_location[7][3][1], location_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][3][1], amplitude_buffer_3_1[d]);
        WRITE_CHANNEL(detect_to_store_location[7][4][0], location_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][4][0], amplitude_buffer_4_0[d]);
        WRITE_CHANNEL(detect_to_store_location[7][4][1], location_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][4][1], amplitude_buffer_4_1[d]);
        WRITE_CHANNEL(detect_to_store_location[7][5][0], location_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][5][0], amplitude_buffer_5_0[d]);
        WRITE_CHANNEL(detect_to_store_location[7][5][1], location_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][5][1], amplitude_buffer_5_1[d]);
        WRITE_CHANNEL(detect_to_store_location[7][6][0], location_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][6][0], amplitude_buffer_6_0[d]);
        WRITE_CHANNEL(detect_to_store_location[7][6][1], location_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][6][1], amplitude_buffer_6_1[d]);
        WRITE_CHANNEL(detect_to_store_location[7][7][0], location_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][7][0], amplitude_buffer_7_0[d]);
        WRITE_CHANNEL(detect_to_store_location[7][7][1], location_buffer_7_1[d]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][7][1], amplitude_buffer_7_1[d]);
    }
}
