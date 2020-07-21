
// Auto-generated file -- see `hsum_codegen.py` and `detect.cl.mako`.
channel float detect_to_detect[7][16] __attribute__((depth(0)));
channel uint  detect_to_store_location[8][16] __attribute__((depth(0)));
channel float detect_to_store_amplitude[8][16] __attribute__((depth(0)));

__attribute__((max_global_work_dim(0)))
kernel void detect_1(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_8[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_9[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_10[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_11[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_12[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_13[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_14[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_15[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_8[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_9[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_10[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_11[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_12[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_13[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_14[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_15[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                hsum[p] = READ_CHANNEL(preload_to_detect[0][p]);

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[0][p], hsum[p]);

            int filter_0 = batch * 16 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(1, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_1 = batch * 16 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(1, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_2 = batch * 16 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(1, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_3 = batch * 16 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(1, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_4 = batch * 16 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(1, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_5 = batch * 16 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(1, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_6 = batch * 16 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(1, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_7 = batch * 16 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(1, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_8 = batch * 16 + 8;
            if (hsum[8] > threshold && filter_8 < n_filters) {
                uint slot = next[8];
                if (negative_filters)
                    filter_8 = -filter_8;
                location_buffer_8[slot] = HMS_ENCODE_LOCATION(1, filter_8, chan);
                amplitude_buffer_8[slot] = hsum[8];
                next[8] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_9 = batch * 16 + 9;
            if (hsum[9] > threshold && filter_9 < n_filters) {
                uint slot = next[9];
                if (negative_filters)
                    filter_9 = -filter_9;
                location_buffer_9[slot] = HMS_ENCODE_LOCATION(1, filter_9, chan);
                amplitude_buffer_9[slot] = hsum[9];
                next[9] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_10 = batch * 16 + 10;
            if (hsum[10] > threshold && filter_10 < n_filters) {
                uint slot = next[10];
                if (negative_filters)
                    filter_10 = -filter_10;
                location_buffer_10[slot] = HMS_ENCODE_LOCATION(1, filter_10, chan);
                amplitude_buffer_10[slot] = hsum[10];
                next[10] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_11 = batch * 16 + 11;
            if (hsum[11] > threshold && filter_11 < n_filters) {
                uint slot = next[11];
                if (negative_filters)
                    filter_11 = -filter_11;
                location_buffer_11[slot] = HMS_ENCODE_LOCATION(1, filter_11, chan);
                amplitude_buffer_11[slot] = hsum[11];
                next[11] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_12 = batch * 16 + 12;
            if (hsum[12] > threshold && filter_12 < n_filters) {
                uint slot = next[12];
                if (negative_filters)
                    filter_12 = -filter_12;
                location_buffer_12[slot] = HMS_ENCODE_LOCATION(1, filter_12, chan);
                amplitude_buffer_12[slot] = hsum[12];
                next[12] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_13 = batch * 16 + 13;
            if (hsum[13] > threshold && filter_13 < n_filters) {
                uint slot = next[13];
                if (negative_filters)
                    filter_13 = -filter_13;
                location_buffer_13[slot] = HMS_ENCODE_LOCATION(1, filter_13, chan);
                amplitude_buffer_13[slot] = hsum[13];
                next[13] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_14 = batch * 16 + 14;
            if (hsum[14] > threshold && filter_14 < n_filters) {
                uint slot = next[14];
                if (negative_filters)
                    filter_14 = -filter_14;
                location_buffer_14[slot] = HMS_ENCODE_LOCATION(1, filter_14, chan);
                amplitude_buffer_14[slot] = hsum[14];
                next[14] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_15 = batch * 16 + 15;
            if (hsum[15] > threshold && filter_15 < n_filters) {
                uint slot = next[15];
                if (negative_filters)
                    filter_15 = -filter_15;
                location_buffer_15[slot] = HMS_ENCODE_LOCATION(1, filter_15, chan);
                amplitude_buffer_15[slot] = hsum[15];
                next[15] = (slot + 1) < 4 ? slot + 1 : 0;
            }
        }
    }

    #pragma unroll 1
    for (uint slot = 0; slot < 4; ++slot) {
        WRITE_CHANNEL(detect_to_store_location[0][0], location_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][0], amplitude_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][1], location_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][1], amplitude_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][2], location_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][2], amplitude_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][3], location_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][3], amplitude_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][4], location_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][4], amplitude_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][5], location_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][5], amplitude_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][6], location_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][6], amplitude_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][7], location_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][7], amplitude_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][8], location_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][8], amplitude_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][9], location_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][9], amplitude_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][10], location_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][10], amplitude_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][11], location_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][11], amplitude_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][12], location_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][12], amplitude_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][13], location_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][13], amplitude_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][14], location_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][14], amplitude_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_location[0][15], location_buffer_15[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[0][15], amplitude_buffer_15[slot]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_2(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_8[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_9[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_10[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_11[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_12[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_13[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_14[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_15[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_8[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_9[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_10[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_11[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_12[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_13[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_14[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_15[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[0][p]) + READ_CHANNEL(preload_to_detect[1][p]);

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[1][p], hsum[p]);

            int filter_0 = batch * 16 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(2, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_1 = batch * 16 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(2, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_2 = batch * 16 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(2, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_3 = batch * 16 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(2, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_4 = batch * 16 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(2, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_5 = batch * 16 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(2, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_6 = batch * 16 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(2, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_7 = batch * 16 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(2, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_8 = batch * 16 + 8;
            if (hsum[8] > threshold && filter_8 < n_filters) {
                uint slot = next[8];
                if (negative_filters)
                    filter_8 = -filter_8;
                location_buffer_8[slot] = HMS_ENCODE_LOCATION(2, filter_8, chan);
                amplitude_buffer_8[slot] = hsum[8];
                next[8] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_9 = batch * 16 + 9;
            if (hsum[9] > threshold && filter_9 < n_filters) {
                uint slot = next[9];
                if (negative_filters)
                    filter_9 = -filter_9;
                location_buffer_9[slot] = HMS_ENCODE_LOCATION(2, filter_9, chan);
                amplitude_buffer_9[slot] = hsum[9];
                next[9] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_10 = batch * 16 + 10;
            if (hsum[10] > threshold && filter_10 < n_filters) {
                uint slot = next[10];
                if (negative_filters)
                    filter_10 = -filter_10;
                location_buffer_10[slot] = HMS_ENCODE_LOCATION(2, filter_10, chan);
                amplitude_buffer_10[slot] = hsum[10];
                next[10] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_11 = batch * 16 + 11;
            if (hsum[11] > threshold && filter_11 < n_filters) {
                uint slot = next[11];
                if (negative_filters)
                    filter_11 = -filter_11;
                location_buffer_11[slot] = HMS_ENCODE_LOCATION(2, filter_11, chan);
                amplitude_buffer_11[slot] = hsum[11];
                next[11] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_12 = batch * 16 + 12;
            if (hsum[12] > threshold && filter_12 < n_filters) {
                uint slot = next[12];
                if (negative_filters)
                    filter_12 = -filter_12;
                location_buffer_12[slot] = HMS_ENCODE_LOCATION(2, filter_12, chan);
                amplitude_buffer_12[slot] = hsum[12];
                next[12] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_13 = batch * 16 + 13;
            if (hsum[13] > threshold && filter_13 < n_filters) {
                uint slot = next[13];
                if (negative_filters)
                    filter_13 = -filter_13;
                location_buffer_13[slot] = HMS_ENCODE_LOCATION(2, filter_13, chan);
                amplitude_buffer_13[slot] = hsum[13];
                next[13] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_14 = batch * 16 + 14;
            if (hsum[14] > threshold && filter_14 < n_filters) {
                uint slot = next[14];
                if (negative_filters)
                    filter_14 = -filter_14;
                location_buffer_14[slot] = HMS_ENCODE_LOCATION(2, filter_14, chan);
                amplitude_buffer_14[slot] = hsum[14];
                next[14] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_15 = batch * 16 + 15;
            if (hsum[15] > threshold && filter_15 < n_filters) {
                uint slot = next[15];
                if (negative_filters)
                    filter_15 = -filter_15;
                location_buffer_15[slot] = HMS_ENCODE_LOCATION(2, filter_15, chan);
                amplitude_buffer_15[slot] = hsum[15];
                next[15] = (slot + 1) < 4 ? slot + 1 : 0;
            }
        }
    }

    #pragma unroll 1
    for (uint slot = 0; slot < 4; ++slot) {
        WRITE_CHANNEL(detect_to_store_location[1][0], location_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][0], amplitude_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][1], location_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][1], amplitude_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][2], location_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][2], amplitude_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][3], location_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][3], amplitude_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][4], location_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][4], amplitude_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][5], location_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][5], amplitude_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][6], location_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][6], amplitude_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][7], location_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][7], amplitude_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][8], location_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][8], amplitude_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][9], location_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][9], amplitude_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][10], location_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][10], amplitude_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][11], location_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][11], amplitude_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][12], location_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][12], amplitude_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][13], location_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][13], amplitude_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][14], location_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][14], amplitude_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_location[1][15], location_buffer_15[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[1][15], amplitude_buffer_15[slot]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_3(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_8[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_9[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_10[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_11[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_12[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_13[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_14[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_15[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_8[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_9[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_10[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_11[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_12[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_13[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_14[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_15[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[1][p]) + READ_CHANNEL(preload_to_detect[2][p]);

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[2][p], hsum[p]);

            int filter_0 = batch * 16 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(3, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_1 = batch * 16 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(3, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_2 = batch * 16 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(3, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_3 = batch * 16 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(3, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_4 = batch * 16 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(3, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_5 = batch * 16 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(3, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_6 = batch * 16 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(3, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_7 = batch * 16 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(3, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_8 = batch * 16 + 8;
            if (hsum[8] > threshold && filter_8 < n_filters) {
                uint slot = next[8];
                if (negative_filters)
                    filter_8 = -filter_8;
                location_buffer_8[slot] = HMS_ENCODE_LOCATION(3, filter_8, chan);
                amplitude_buffer_8[slot] = hsum[8];
                next[8] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_9 = batch * 16 + 9;
            if (hsum[9] > threshold && filter_9 < n_filters) {
                uint slot = next[9];
                if (negative_filters)
                    filter_9 = -filter_9;
                location_buffer_9[slot] = HMS_ENCODE_LOCATION(3, filter_9, chan);
                amplitude_buffer_9[slot] = hsum[9];
                next[9] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_10 = batch * 16 + 10;
            if (hsum[10] > threshold && filter_10 < n_filters) {
                uint slot = next[10];
                if (negative_filters)
                    filter_10 = -filter_10;
                location_buffer_10[slot] = HMS_ENCODE_LOCATION(3, filter_10, chan);
                amplitude_buffer_10[slot] = hsum[10];
                next[10] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_11 = batch * 16 + 11;
            if (hsum[11] > threshold && filter_11 < n_filters) {
                uint slot = next[11];
                if (negative_filters)
                    filter_11 = -filter_11;
                location_buffer_11[slot] = HMS_ENCODE_LOCATION(3, filter_11, chan);
                amplitude_buffer_11[slot] = hsum[11];
                next[11] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_12 = batch * 16 + 12;
            if (hsum[12] > threshold && filter_12 < n_filters) {
                uint slot = next[12];
                if (negative_filters)
                    filter_12 = -filter_12;
                location_buffer_12[slot] = HMS_ENCODE_LOCATION(3, filter_12, chan);
                amplitude_buffer_12[slot] = hsum[12];
                next[12] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_13 = batch * 16 + 13;
            if (hsum[13] > threshold && filter_13 < n_filters) {
                uint slot = next[13];
                if (negative_filters)
                    filter_13 = -filter_13;
                location_buffer_13[slot] = HMS_ENCODE_LOCATION(3, filter_13, chan);
                amplitude_buffer_13[slot] = hsum[13];
                next[13] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_14 = batch * 16 + 14;
            if (hsum[14] > threshold && filter_14 < n_filters) {
                uint slot = next[14];
                if (negative_filters)
                    filter_14 = -filter_14;
                location_buffer_14[slot] = HMS_ENCODE_LOCATION(3, filter_14, chan);
                amplitude_buffer_14[slot] = hsum[14];
                next[14] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_15 = batch * 16 + 15;
            if (hsum[15] > threshold && filter_15 < n_filters) {
                uint slot = next[15];
                if (negative_filters)
                    filter_15 = -filter_15;
                location_buffer_15[slot] = HMS_ENCODE_LOCATION(3, filter_15, chan);
                amplitude_buffer_15[slot] = hsum[15];
                next[15] = (slot + 1) < 4 ? slot + 1 : 0;
            }
        }
    }

    #pragma unroll 1
    for (uint slot = 0; slot < 4; ++slot) {
        WRITE_CHANNEL(detect_to_store_location[2][0], location_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][0], amplitude_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][1], location_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][1], amplitude_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][2], location_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][2], amplitude_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][3], location_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][3], amplitude_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][4], location_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][4], amplitude_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][5], location_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][5], amplitude_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][6], location_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][6], amplitude_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][7], location_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][7], amplitude_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][8], location_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][8], amplitude_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][9], location_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][9], amplitude_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][10], location_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][10], amplitude_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][11], location_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][11], amplitude_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][12], location_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][12], amplitude_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][13], location_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][13], amplitude_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][14], location_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][14], amplitude_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_location[2][15], location_buffer_15[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[2][15], amplitude_buffer_15[slot]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_4(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_8[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_9[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_10[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_11[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_12[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_13[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_14[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_15[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_8[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_9[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_10[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_11[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_12[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_13[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_14[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_15[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[2][p]) + READ_CHANNEL(preload_to_detect[3][p]);

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[3][p], hsum[p]);

            int filter_0 = batch * 16 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(4, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_1 = batch * 16 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(4, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_2 = batch * 16 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(4, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_3 = batch * 16 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(4, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_4 = batch * 16 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(4, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_5 = batch * 16 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(4, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_6 = batch * 16 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(4, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_7 = batch * 16 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(4, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_8 = batch * 16 + 8;
            if (hsum[8] > threshold && filter_8 < n_filters) {
                uint slot = next[8];
                if (negative_filters)
                    filter_8 = -filter_8;
                location_buffer_8[slot] = HMS_ENCODE_LOCATION(4, filter_8, chan);
                amplitude_buffer_8[slot] = hsum[8];
                next[8] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_9 = batch * 16 + 9;
            if (hsum[9] > threshold && filter_9 < n_filters) {
                uint slot = next[9];
                if (negative_filters)
                    filter_9 = -filter_9;
                location_buffer_9[slot] = HMS_ENCODE_LOCATION(4, filter_9, chan);
                amplitude_buffer_9[slot] = hsum[9];
                next[9] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_10 = batch * 16 + 10;
            if (hsum[10] > threshold && filter_10 < n_filters) {
                uint slot = next[10];
                if (negative_filters)
                    filter_10 = -filter_10;
                location_buffer_10[slot] = HMS_ENCODE_LOCATION(4, filter_10, chan);
                amplitude_buffer_10[slot] = hsum[10];
                next[10] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_11 = batch * 16 + 11;
            if (hsum[11] > threshold && filter_11 < n_filters) {
                uint slot = next[11];
                if (negative_filters)
                    filter_11 = -filter_11;
                location_buffer_11[slot] = HMS_ENCODE_LOCATION(4, filter_11, chan);
                amplitude_buffer_11[slot] = hsum[11];
                next[11] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_12 = batch * 16 + 12;
            if (hsum[12] > threshold && filter_12 < n_filters) {
                uint slot = next[12];
                if (negative_filters)
                    filter_12 = -filter_12;
                location_buffer_12[slot] = HMS_ENCODE_LOCATION(4, filter_12, chan);
                amplitude_buffer_12[slot] = hsum[12];
                next[12] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_13 = batch * 16 + 13;
            if (hsum[13] > threshold && filter_13 < n_filters) {
                uint slot = next[13];
                if (negative_filters)
                    filter_13 = -filter_13;
                location_buffer_13[slot] = HMS_ENCODE_LOCATION(4, filter_13, chan);
                amplitude_buffer_13[slot] = hsum[13];
                next[13] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_14 = batch * 16 + 14;
            if (hsum[14] > threshold && filter_14 < n_filters) {
                uint slot = next[14];
                if (negative_filters)
                    filter_14 = -filter_14;
                location_buffer_14[slot] = HMS_ENCODE_LOCATION(4, filter_14, chan);
                amplitude_buffer_14[slot] = hsum[14];
                next[14] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_15 = batch * 16 + 15;
            if (hsum[15] > threshold && filter_15 < n_filters) {
                uint slot = next[15];
                if (negative_filters)
                    filter_15 = -filter_15;
                location_buffer_15[slot] = HMS_ENCODE_LOCATION(4, filter_15, chan);
                amplitude_buffer_15[slot] = hsum[15];
                next[15] = (slot + 1) < 4 ? slot + 1 : 0;
            }
        }
    }

    #pragma unroll 1
    for (uint slot = 0; slot < 4; ++slot) {
        WRITE_CHANNEL(detect_to_store_location[3][0], location_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][0], amplitude_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][1], location_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][1], amplitude_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][2], location_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][2], amplitude_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][3], location_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][3], amplitude_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][4], location_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][4], amplitude_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][5], location_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][5], amplitude_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][6], location_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][6], amplitude_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][7], location_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][7], amplitude_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][8], location_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][8], amplitude_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][9], location_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][9], amplitude_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][10], location_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][10], amplitude_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][11], location_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][11], amplitude_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][12], location_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][12], amplitude_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][13], location_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][13], amplitude_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][14], location_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][14], amplitude_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_location[3][15], location_buffer_15[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[3][15], amplitude_buffer_15[slot]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_5(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_8[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_9[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_10[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_11[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_12[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_13[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_14[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_15[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_8[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_9[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_10[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_11[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_12[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_13[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_14[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_15[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[3][p]) + READ_CHANNEL(preload_to_detect[4][p]);

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[4][p], hsum[p]);

            int filter_0 = batch * 16 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(5, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_1 = batch * 16 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(5, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_2 = batch * 16 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(5, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_3 = batch * 16 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(5, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_4 = batch * 16 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(5, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_5 = batch * 16 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(5, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_6 = batch * 16 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(5, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_7 = batch * 16 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(5, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_8 = batch * 16 + 8;
            if (hsum[8] > threshold && filter_8 < n_filters) {
                uint slot = next[8];
                if (negative_filters)
                    filter_8 = -filter_8;
                location_buffer_8[slot] = HMS_ENCODE_LOCATION(5, filter_8, chan);
                amplitude_buffer_8[slot] = hsum[8];
                next[8] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_9 = batch * 16 + 9;
            if (hsum[9] > threshold && filter_9 < n_filters) {
                uint slot = next[9];
                if (negative_filters)
                    filter_9 = -filter_9;
                location_buffer_9[slot] = HMS_ENCODE_LOCATION(5, filter_9, chan);
                amplitude_buffer_9[slot] = hsum[9];
                next[9] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_10 = batch * 16 + 10;
            if (hsum[10] > threshold && filter_10 < n_filters) {
                uint slot = next[10];
                if (negative_filters)
                    filter_10 = -filter_10;
                location_buffer_10[slot] = HMS_ENCODE_LOCATION(5, filter_10, chan);
                amplitude_buffer_10[slot] = hsum[10];
                next[10] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_11 = batch * 16 + 11;
            if (hsum[11] > threshold && filter_11 < n_filters) {
                uint slot = next[11];
                if (negative_filters)
                    filter_11 = -filter_11;
                location_buffer_11[slot] = HMS_ENCODE_LOCATION(5, filter_11, chan);
                amplitude_buffer_11[slot] = hsum[11];
                next[11] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_12 = batch * 16 + 12;
            if (hsum[12] > threshold && filter_12 < n_filters) {
                uint slot = next[12];
                if (negative_filters)
                    filter_12 = -filter_12;
                location_buffer_12[slot] = HMS_ENCODE_LOCATION(5, filter_12, chan);
                amplitude_buffer_12[slot] = hsum[12];
                next[12] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_13 = batch * 16 + 13;
            if (hsum[13] > threshold && filter_13 < n_filters) {
                uint slot = next[13];
                if (negative_filters)
                    filter_13 = -filter_13;
                location_buffer_13[slot] = HMS_ENCODE_LOCATION(5, filter_13, chan);
                amplitude_buffer_13[slot] = hsum[13];
                next[13] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_14 = batch * 16 + 14;
            if (hsum[14] > threshold && filter_14 < n_filters) {
                uint slot = next[14];
                if (negative_filters)
                    filter_14 = -filter_14;
                location_buffer_14[slot] = HMS_ENCODE_LOCATION(5, filter_14, chan);
                amplitude_buffer_14[slot] = hsum[14];
                next[14] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_15 = batch * 16 + 15;
            if (hsum[15] > threshold && filter_15 < n_filters) {
                uint slot = next[15];
                if (negative_filters)
                    filter_15 = -filter_15;
                location_buffer_15[slot] = HMS_ENCODE_LOCATION(5, filter_15, chan);
                amplitude_buffer_15[slot] = hsum[15];
                next[15] = (slot + 1) < 4 ? slot + 1 : 0;
            }
        }
    }

    #pragma unroll 1
    for (uint slot = 0; slot < 4; ++slot) {
        WRITE_CHANNEL(detect_to_store_location[4][0], location_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][0], amplitude_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][1], location_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][1], amplitude_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][2], location_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][2], amplitude_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][3], location_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][3], amplitude_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][4], location_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][4], amplitude_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][5], location_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][5], amplitude_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][6], location_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][6], amplitude_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][7], location_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][7], amplitude_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][8], location_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][8], amplitude_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][9], location_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][9], amplitude_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][10], location_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][10], amplitude_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][11], location_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][11], amplitude_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][12], location_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][12], amplitude_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][13], location_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][13], amplitude_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][14], location_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][14], amplitude_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_location[4][15], location_buffer_15[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[4][15], amplitude_buffer_15[slot]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_6(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_8[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_9[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_10[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_11[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_12[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_13[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_14[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_15[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_8[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_9[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_10[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_11[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_12[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_13[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_14[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_15[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[4][p]) + READ_CHANNEL(preload_to_detect[5][p]);

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[5][p], hsum[p]);

            int filter_0 = batch * 16 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(6, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_1 = batch * 16 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(6, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_2 = batch * 16 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(6, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_3 = batch * 16 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(6, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_4 = batch * 16 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(6, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_5 = batch * 16 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(6, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_6 = batch * 16 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(6, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_7 = batch * 16 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(6, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_8 = batch * 16 + 8;
            if (hsum[8] > threshold && filter_8 < n_filters) {
                uint slot = next[8];
                if (negative_filters)
                    filter_8 = -filter_8;
                location_buffer_8[slot] = HMS_ENCODE_LOCATION(6, filter_8, chan);
                amplitude_buffer_8[slot] = hsum[8];
                next[8] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_9 = batch * 16 + 9;
            if (hsum[9] > threshold && filter_9 < n_filters) {
                uint slot = next[9];
                if (negative_filters)
                    filter_9 = -filter_9;
                location_buffer_9[slot] = HMS_ENCODE_LOCATION(6, filter_9, chan);
                amplitude_buffer_9[slot] = hsum[9];
                next[9] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_10 = batch * 16 + 10;
            if (hsum[10] > threshold && filter_10 < n_filters) {
                uint slot = next[10];
                if (negative_filters)
                    filter_10 = -filter_10;
                location_buffer_10[slot] = HMS_ENCODE_LOCATION(6, filter_10, chan);
                amplitude_buffer_10[slot] = hsum[10];
                next[10] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_11 = batch * 16 + 11;
            if (hsum[11] > threshold && filter_11 < n_filters) {
                uint slot = next[11];
                if (negative_filters)
                    filter_11 = -filter_11;
                location_buffer_11[slot] = HMS_ENCODE_LOCATION(6, filter_11, chan);
                amplitude_buffer_11[slot] = hsum[11];
                next[11] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_12 = batch * 16 + 12;
            if (hsum[12] > threshold && filter_12 < n_filters) {
                uint slot = next[12];
                if (negative_filters)
                    filter_12 = -filter_12;
                location_buffer_12[slot] = HMS_ENCODE_LOCATION(6, filter_12, chan);
                amplitude_buffer_12[slot] = hsum[12];
                next[12] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_13 = batch * 16 + 13;
            if (hsum[13] > threshold && filter_13 < n_filters) {
                uint slot = next[13];
                if (negative_filters)
                    filter_13 = -filter_13;
                location_buffer_13[slot] = HMS_ENCODE_LOCATION(6, filter_13, chan);
                amplitude_buffer_13[slot] = hsum[13];
                next[13] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_14 = batch * 16 + 14;
            if (hsum[14] > threshold && filter_14 < n_filters) {
                uint slot = next[14];
                if (negative_filters)
                    filter_14 = -filter_14;
                location_buffer_14[slot] = HMS_ENCODE_LOCATION(6, filter_14, chan);
                amplitude_buffer_14[slot] = hsum[14];
                next[14] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_15 = batch * 16 + 15;
            if (hsum[15] > threshold && filter_15 < n_filters) {
                uint slot = next[15];
                if (negative_filters)
                    filter_15 = -filter_15;
                location_buffer_15[slot] = HMS_ENCODE_LOCATION(6, filter_15, chan);
                amplitude_buffer_15[slot] = hsum[15];
                next[15] = (slot + 1) < 4 ? slot + 1 : 0;
            }
        }
    }

    #pragma unroll 1
    for (uint slot = 0; slot < 4; ++slot) {
        WRITE_CHANNEL(detect_to_store_location[5][0], location_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][0], amplitude_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][1], location_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][1], amplitude_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][2], location_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][2], amplitude_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][3], location_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][3], amplitude_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][4], location_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][4], amplitude_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][5], location_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][5], amplitude_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][6], location_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][6], amplitude_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][7], location_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][7], amplitude_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][8], location_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][8], amplitude_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][9], location_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][9], amplitude_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][10], location_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][10], amplitude_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][11], location_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][11], amplitude_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][12], location_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][12], amplitude_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][13], location_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][13], amplitude_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][14], location_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][14], amplitude_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_location[5][15], location_buffer_15[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[5][15], amplitude_buffer_15[slot]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_7(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_8[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_9[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_10[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_11[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_12[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_13[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_14[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_15[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_8[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_9[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_10[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_11[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_12[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_13[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_14[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_15[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[5][p]) + READ_CHANNEL(preload_to_detect[6][p]);

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[6][p], hsum[p]);

            int filter_0 = batch * 16 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(7, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_1 = batch * 16 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(7, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_2 = batch * 16 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(7, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_3 = batch * 16 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(7, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_4 = batch * 16 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(7, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_5 = batch * 16 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(7, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_6 = batch * 16 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(7, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_7 = batch * 16 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(7, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_8 = batch * 16 + 8;
            if (hsum[8] > threshold && filter_8 < n_filters) {
                uint slot = next[8];
                if (negative_filters)
                    filter_8 = -filter_8;
                location_buffer_8[slot] = HMS_ENCODE_LOCATION(7, filter_8, chan);
                amplitude_buffer_8[slot] = hsum[8];
                next[8] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_9 = batch * 16 + 9;
            if (hsum[9] > threshold && filter_9 < n_filters) {
                uint slot = next[9];
                if (negative_filters)
                    filter_9 = -filter_9;
                location_buffer_9[slot] = HMS_ENCODE_LOCATION(7, filter_9, chan);
                amplitude_buffer_9[slot] = hsum[9];
                next[9] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_10 = batch * 16 + 10;
            if (hsum[10] > threshold && filter_10 < n_filters) {
                uint slot = next[10];
                if (negative_filters)
                    filter_10 = -filter_10;
                location_buffer_10[slot] = HMS_ENCODE_LOCATION(7, filter_10, chan);
                amplitude_buffer_10[slot] = hsum[10];
                next[10] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_11 = batch * 16 + 11;
            if (hsum[11] > threshold && filter_11 < n_filters) {
                uint slot = next[11];
                if (negative_filters)
                    filter_11 = -filter_11;
                location_buffer_11[slot] = HMS_ENCODE_LOCATION(7, filter_11, chan);
                amplitude_buffer_11[slot] = hsum[11];
                next[11] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_12 = batch * 16 + 12;
            if (hsum[12] > threshold && filter_12 < n_filters) {
                uint slot = next[12];
                if (negative_filters)
                    filter_12 = -filter_12;
                location_buffer_12[slot] = HMS_ENCODE_LOCATION(7, filter_12, chan);
                amplitude_buffer_12[slot] = hsum[12];
                next[12] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_13 = batch * 16 + 13;
            if (hsum[13] > threshold && filter_13 < n_filters) {
                uint slot = next[13];
                if (negative_filters)
                    filter_13 = -filter_13;
                location_buffer_13[slot] = HMS_ENCODE_LOCATION(7, filter_13, chan);
                amplitude_buffer_13[slot] = hsum[13];
                next[13] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_14 = batch * 16 + 14;
            if (hsum[14] > threshold && filter_14 < n_filters) {
                uint slot = next[14];
                if (negative_filters)
                    filter_14 = -filter_14;
                location_buffer_14[slot] = HMS_ENCODE_LOCATION(7, filter_14, chan);
                amplitude_buffer_14[slot] = hsum[14];
                next[14] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_15 = batch * 16 + 15;
            if (hsum[15] > threshold && filter_15 < n_filters) {
                uint slot = next[15];
                if (negative_filters)
                    filter_15 = -filter_15;
                location_buffer_15[slot] = HMS_ENCODE_LOCATION(7, filter_15, chan);
                amplitude_buffer_15[slot] = hsum[15];
                next[15] = (slot + 1) < 4 ? slot + 1 : 0;
            }
        }
    }

    #pragma unroll 1
    for (uint slot = 0; slot < 4; ++slot) {
        WRITE_CHANNEL(detect_to_store_location[6][0], location_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][0], amplitude_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][1], location_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][1], amplitude_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][2], location_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][2], amplitude_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][3], location_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][3], amplitude_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][4], location_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][4], amplitude_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][5], location_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][5], amplitude_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][6], location_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][6], amplitude_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][7], location_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][7], amplitude_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][8], location_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][8], amplitude_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][9], location_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][9], amplitude_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][10], location_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][10], amplitude_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][11], location_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][11], amplitude_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][12], location_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][12], amplitude_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][13], location_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][13], amplitude_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][14], location_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][14], amplitude_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_location[6][15], location_buffer_15[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[6][15], amplitude_buffer_15[slot]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_8(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_8[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_9[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_10[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_11[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_12[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_13[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_14[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_15[4] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_8[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_9[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_10[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_11[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_12[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_13[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_14[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_15[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    uint next[16]  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[6][p]) + READ_CHANNEL(preload_to_detect[7][p]);


            int filter_0 = batch * 16 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(8, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_1 = batch * 16 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(8, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_2 = batch * 16 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(8, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_3 = batch * 16 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(8, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_4 = batch * 16 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(8, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_5 = batch * 16 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(8, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_6 = batch * 16 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(8, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_7 = batch * 16 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(8, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_8 = batch * 16 + 8;
            if (hsum[8] > threshold && filter_8 < n_filters) {
                uint slot = next[8];
                if (negative_filters)
                    filter_8 = -filter_8;
                location_buffer_8[slot] = HMS_ENCODE_LOCATION(8, filter_8, chan);
                amplitude_buffer_8[slot] = hsum[8];
                next[8] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_9 = batch * 16 + 9;
            if (hsum[9] > threshold && filter_9 < n_filters) {
                uint slot = next[9];
                if (negative_filters)
                    filter_9 = -filter_9;
                location_buffer_9[slot] = HMS_ENCODE_LOCATION(8, filter_9, chan);
                amplitude_buffer_9[slot] = hsum[9];
                next[9] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_10 = batch * 16 + 10;
            if (hsum[10] > threshold && filter_10 < n_filters) {
                uint slot = next[10];
                if (negative_filters)
                    filter_10 = -filter_10;
                location_buffer_10[slot] = HMS_ENCODE_LOCATION(8, filter_10, chan);
                amplitude_buffer_10[slot] = hsum[10];
                next[10] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_11 = batch * 16 + 11;
            if (hsum[11] > threshold && filter_11 < n_filters) {
                uint slot = next[11];
                if (negative_filters)
                    filter_11 = -filter_11;
                location_buffer_11[slot] = HMS_ENCODE_LOCATION(8, filter_11, chan);
                amplitude_buffer_11[slot] = hsum[11];
                next[11] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_12 = batch * 16 + 12;
            if (hsum[12] > threshold && filter_12 < n_filters) {
                uint slot = next[12];
                if (negative_filters)
                    filter_12 = -filter_12;
                location_buffer_12[slot] = HMS_ENCODE_LOCATION(8, filter_12, chan);
                amplitude_buffer_12[slot] = hsum[12];
                next[12] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_13 = batch * 16 + 13;
            if (hsum[13] > threshold && filter_13 < n_filters) {
                uint slot = next[13];
                if (negative_filters)
                    filter_13 = -filter_13;
                location_buffer_13[slot] = HMS_ENCODE_LOCATION(8, filter_13, chan);
                amplitude_buffer_13[slot] = hsum[13];
                next[13] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_14 = batch * 16 + 14;
            if (hsum[14] > threshold && filter_14 < n_filters) {
                uint slot = next[14];
                if (negative_filters)
                    filter_14 = -filter_14;
                location_buffer_14[slot] = HMS_ENCODE_LOCATION(8, filter_14, chan);
                amplitude_buffer_14[slot] = hsum[14];
                next[14] = (slot + 1) < 4 ? slot + 1 : 0;
            }
            int filter_15 = batch * 16 + 15;
            if (hsum[15] > threshold && filter_15 < n_filters) {
                uint slot = next[15];
                if (negative_filters)
                    filter_15 = -filter_15;
                location_buffer_15[slot] = HMS_ENCODE_LOCATION(8, filter_15, chan);
                amplitude_buffer_15[slot] = hsum[15];
                next[15] = (slot + 1) < 4 ? slot + 1 : 0;
            }
        }
    }

    #pragma unroll 1
    for (uint slot = 0; slot < 4; ++slot) {
        WRITE_CHANNEL(detect_to_store_location[7][0], location_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][0], amplitude_buffer_0[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][1], location_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][1], amplitude_buffer_1[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][2], location_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][2], amplitude_buffer_2[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][3], location_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][3], amplitude_buffer_3[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][4], location_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][4], amplitude_buffer_4[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][5], location_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][5], amplitude_buffer_5[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][6], location_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][6], amplitude_buffer_6[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][7], location_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][7], amplitude_buffer_7[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][8], location_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][8], amplitude_buffer_8[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][9], location_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][9], amplitude_buffer_9[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][10], location_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][10], amplitude_buffer_10[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][11], location_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][11], amplitude_buffer_11[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][12], location_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][12], amplitude_buffer_12[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][13], location_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][13], amplitude_buffer_13[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][14], location_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][14], amplitude_buffer_14[slot]);
        WRITE_CHANNEL(detect_to_store_location[7][15], location_buffer_15[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[7][15], amplitude_buffer_15[slot]);
    }
}
