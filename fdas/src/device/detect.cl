
// Auto-generated file -- see `hsum_codegen.py` and `detect.cl.mako`.
channel float detect_to_detect[7][8] __attribute__((depth(0)));
channel uint  detect_to_store_location[8][8] __attribute__((depth(0)));
channel float detect_to_store_amplitude[8][8] __attribute__((depth(0)));

__attribute__((max_global_work_dim(0)))
kernel void detect_1(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    uint next[8]  = {0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(preload_to_detect[0][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                WRITE_CHANNEL(detect_to_detect[0][p], hsum[p]);

            int filter_0 = batch * 8 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(1, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_1 = batch * 8 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(1, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_2 = batch * 8 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(1, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_3 = batch * 8 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(1, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_4 = batch * 8 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(1, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_5 = batch * 8 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(1, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_6 = batch * 8 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(1, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_7 = batch * 8 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(1, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 6 ? slot + 1 : 0;
            }
        }
    }

    for (uint slot = 0; slot < 6; ++slot) {
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
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_2(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    uint next[8]  = {0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[0][p]) + READ_CHANNEL(preload_to_detect[1][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                WRITE_CHANNEL(detect_to_detect[1][p], hsum[p]);

            int filter_0 = batch * 8 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(2, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_1 = batch * 8 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(2, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_2 = batch * 8 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(2, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_3 = batch * 8 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(2, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_4 = batch * 8 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(2, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_5 = batch * 8 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(2, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_6 = batch * 8 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(2, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_7 = batch * 8 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(2, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 6 ? slot + 1 : 0;
            }
        }
    }

    for (uint slot = 0; slot < 6; ++slot) {
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
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_3(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    uint next[8]  = {0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[1][p]) + READ_CHANNEL(preload_to_detect[2][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                WRITE_CHANNEL(detect_to_detect[2][p], hsum[p]);

            int filter_0 = batch * 8 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(3, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_1 = batch * 8 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(3, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_2 = batch * 8 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(3, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_3 = batch * 8 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(3, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_4 = batch * 8 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(3, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_5 = batch * 8 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(3, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_6 = batch * 8 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(3, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_7 = batch * 8 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(3, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 6 ? slot + 1 : 0;
            }
        }
    }

    for (uint slot = 0; slot < 6; ++slot) {
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
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_4(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    uint next[8]  = {0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[2][p]) + READ_CHANNEL(preload_to_detect[3][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                WRITE_CHANNEL(detect_to_detect[3][p], hsum[p]);

            int filter_0 = batch * 8 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(4, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_1 = batch * 8 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(4, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_2 = batch * 8 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(4, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_3 = batch * 8 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(4, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_4 = batch * 8 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(4, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_5 = batch * 8 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(4, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_6 = batch * 8 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(4, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_7 = batch * 8 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(4, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 6 ? slot + 1 : 0;
            }
        }
    }

    for (uint slot = 0; slot < 6; ++slot) {
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
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_5(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    uint next[8]  = {0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[3][p]) + READ_CHANNEL(preload_to_detect[4][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                WRITE_CHANNEL(detect_to_detect[4][p], hsum[p]);

            int filter_0 = batch * 8 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(5, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_1 = batch * 8 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(5, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_2 = batch * 8 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(5, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_3 = batch * 8 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(5, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_4 = batch * 8 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(5, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_5 = batch * 8 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(5, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_6 = batch * 8 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(5, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_7 = batch * 8 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(5, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 6 ? slot + 1 : 0;
            }
        }
    }

    for (uint slot = 0; slot < 6; ++slot) {
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
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_6(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    uint next[8]  = {0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[4][p]) + READ_CHANNEL(preload_to_detect[5][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                WRITE_CHANNEL(detect_to_detect[5][p], hsum[p]);

            int filter_0 = batch * 8 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(6, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_1 = batch * 8 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(6, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_2 = batch * 8 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(6, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_3 = batch * 8 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(6, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_4 = batch * 8 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(6, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_5 = batch * 8 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(6, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_6 = batch * 8 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(6, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_7 = batch * 8 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(6, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 6 ? slot + 1 : 0;
            }
        }
    }

    for (uint slot = 0; slot < 6; ++slot) {
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
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_7(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    uint next[8]  = {0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[5][p]) + READ_CHANNEL(preload_to_detect[6][p]);

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                WRITE_CHANNEL(detect_to_detect[6][p], hsum[p]);

            int filter_0 = batch * 8 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(7, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_1 = batch * 8 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(7, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_2 = batch * 8 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(7, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_3 = batch * 8 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(7, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_4 = batch * 8 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(7, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_5 = batch * 8 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(7, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_6 = batch * 8 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(7, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_7 = batch * 8 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(7, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 6 ? slot + 1 : 0;
            }
        }
    }

    for (uint slot = 0; slot < 6; ++slot) {
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
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_8(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
    uint location_buffer_0[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_1[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_2[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_3[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_4[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_5[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_6[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    uint location_buffer_7[6] = {HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION, HMS_INVALID_LOCATION};
    float amplitude_buffer_0[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_1[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_2[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_3[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_4[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_5[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_6[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    float amplitude_buffer_7[6] = {-1.0f, -1.0f, -1.0f, -1.0f, -1.0f, -1.0f};
    uint next[8]  = {0, 0, 0, 0, 0, 0, 0, 0};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[8];

            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[6][p]) + READ_CHANNEL(preload_to_detect[7][p]);


            int filter_0 = batch * 8 + 0;
            if (hsum[0] > threshold && filter_0 < n_filters) {
                uint slot = next[0];
                if (negative_filters)
                    filter_0 = -filter_0;
                location_buffer_0[slot] = HMS_ENCODE_LOCATION(8, filter_0, chan);
                amplitude_buffer_0[slot] = hsum[0];
                next[0] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_1 = batch * 8 + 1;
            if (hsum[1] > threshold && filter_1 < n_filters) {
                uint slot = next[1];
                if (negative_filters)
                    filter_1 = -filter_1;
                location_buffer_1[slot] = HMS_ENCODE_LOCATION(8, filter_1, chan);
                amplitude_buffer_1[slot] = hsum[1];
                next[1] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_2 = batch * 8 + 2;
            if (hsum[2] > threshold && filter_2 < n_filters) {
                uint slot = next[2];
                if (negative_filters)
                    filter_2 = -filter_2;
                location_buffer_2[slot] = HMS_ENCODE_LOCATION(8, filter_2, chan);
                amplitude_buffer_2[slot] = hsum[2];
                next[2] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_3 = batch * 8 + 3;
            if (hsum[3] > threshold && filter_3 < n_filters) {
                uint slot = next[3];
                if (negative_filters)
                    filter_3 = -filter_3;
                location_buffer_3[slot] = HMS_ENCODE_LOCATION(8, filter_3, chan);
                amplitude_buffer_3[slot] = hsum[3];
                next[3] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_4 = batch * 8 + 4;
            if (hsum[4] > threshold && filter_4 < n_filters) {
                uint slot = next[4];
                if (negative_filters)
                    filter_4 = -filter_4;
                location_buffer_4[slot] = HMS_ENCODE_LOCATION(8, filter_4, chan);
                amplitude_buffer_4[slot] = hsum[4];
                next[4] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_5 = batch * 8 + 5;
            if (hsum[5] > threshold && filter_5 < n_filters) {
                uint slot = next[5];
                if (negative_filters)
                    filter_5 = -filter_5;
                location_buffer_5[slot] = HMS_ENCODE_LOCATION(8, filter_5, chan);
                amplitude_buffer_5[slot] = hsum[5];
                next[5] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_6 = batch * 8 + 6;
            if (hsum[6] > threshold && filter_6 < n_filters) {
                uint slot = next[6];
                if (negative_filters)
                    filter_6 = -filter_6;
                location_buffer_6[slot] = HMS_ENCODE_LOCATION(8, filter_6, chan);
                amplitude_buffer_6[slot] = hsum[6];
                next[6] = (slot + 1) < 6 ? slot + 1 : 0;
            }
            int filter_7 = batch * 8 + 7;
            if (hsum[7] > threshold && filter_7 < n_filters) {
                uint slot = next[7];
                if (negative_filters)
                    filter_7 = -filter_7;
                location_buffer_7[slot] = HMS_ENCODE_LOCATION(8, filter_7, chan);
                amplitude_buffer_7[slot] = hsum[7];
                next[7] = (slot + 1) < 6 ? slot + 1 : 0;
            }
        }
    }

    for (uint slot = 0; slot < 6; ++slot) {
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
    }
}
