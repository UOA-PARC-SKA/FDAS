/*
 * FDAS -- Fourier Domain Acceleration Search, FPGA-accelerated with OpenCL
 * Copyright (C) 2020  Parallel and Reconfigurable Computing Lab,
 *                     Dept. of Electrical, Computer, and Software Engineering,
 *                     University of Auckland, New Zealand
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

// Auto-generated file -- see `hsum_codegen.py` and `detect.cl.mako`.

channel float8 detect_to_detect[7][2] __attribute__((depth(0)));
channel uint  detect_to_store_location[8][16] __attribute__((depth(0)));
channel float detect_to_store_amplitude[8][16] __attribute__((depth(0)));

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_1(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
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
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_fop = READ_CHANNEL(delay_to_detect[0][p]);
                hsum[p] = from_fop;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                WRITE_CHANNEL(detect_to_detect[0][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(1, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(1, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(1, filter_num[0], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[0].s2 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(1, filter_num[0], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[0].s3 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(1, filter_num[0], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[0].s4 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(1, filter_num[0], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[0].s5 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(1, filter_num[0], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[0].s6 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(1, filter_num[0], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[0].s7 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(1, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[1].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(1, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[1].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(1, filter_num[1], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[1].s2 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(1, filter_num[1], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[1].s3 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(1, filter_num[1], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[1].s4 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(1, filter_num[1], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[1].s5 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(1, filter_num[1], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[1].s6 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(1, filter_num[1], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[1].s7 : -1.0f;

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
            detection_location[0 + d * 16 + x] = is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION;
            detection_amplitude[0 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : -1.0f;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_2(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
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
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[0][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[1][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                WRITE_CHANNEL(detect_to_detect[1][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(2, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(2, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(2, filter_num[0], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[0].s2 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(2, filter_num[0], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[0].s3 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(2, filter_num[0], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[0].s4 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(2, filter_num[0], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[0].s5 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(2, filter_num[0], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[0].s6 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(2, filter_num[0], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[0].s7 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(2, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[1].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(2, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[1].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(2, filter_num[1], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[1].s2 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(2, filter_num[1], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[1].s3 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(2, filter_num[1], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[1].s4 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(2, filter_num[1], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[1].s5 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(2, filter_num[1], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[1].s6 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(2, filter_num[1], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[1].s7 : -1.0f;

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
            detection_location[1024 + d * 16 + x] = is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION;
            detection_amplitude[1024 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : -1.0f;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_3(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
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
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[1][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[2][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                WRITE_CHANNEL(detect_to_detect[2][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(3, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(3, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(3, filter_num[0], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[0].s2 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(3, filter_num[0], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[0].s3 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(3, filter_num[0], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[0].s4 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(3, filter_num[0], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[0].s5 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(3, filter_num[0], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[0].s6 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(3, filter_num[0], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[0].s7 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(3, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[1].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(3, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[1].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(3, filter_num[1], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[1].s2 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(3, filter_num[1], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[1].s3 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(3, filter_num[1], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[1].s4 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(3, filter_num[1], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[1].s5 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(3, filter_num[1], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[1].s6 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(3, filter_num[1], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[1].s7 : -1.0f;

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
            detection_location[2048 + d * 16 + x] = is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION;
            detection_amplitude[2048 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : -1.0f;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_4(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
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
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[2][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[3][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                WRITE_CHANNEL(detect_to_detect[3][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(4, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(4, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(4, filter_num[0], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[0].s2 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(4, filter_num[0], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[0].s3 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(4, filter_num[0], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[0].s4 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(4, filter_num[0], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[0].s5 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(4, filter_num[0], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[0].s6 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(4, filter_num[0], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[0].s7 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(4, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[1].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(4, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[1].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(4, filter_num[1], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[1].s2 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(4, filter_num[1], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[1].s3 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(4, filter_num[1], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[1].s4 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(4, filter_num[1], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[1].s5 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(4, filter_num[1], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[1].s6 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(4, filter_num[1], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[1].s7 : -1.0f;

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
            detection_location[3072 + d * 16 + x] = is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION;
            detection_amplitude[3072 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : -1.0f;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_5(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
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
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[3][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[4][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                WRITE_CHANNEL(detect_to_detect[4][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(5, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(5, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(5, filter_num[0], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[0].s2 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(5, filter_num[0], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[0].s3 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(5, filter_num[0], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[0].s4 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(5, filter_num[0], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[0].s5 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(5, filter_num[0], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[0].s6 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(5, filter_num[0], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[0].s7 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(5, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[1].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(5, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[1].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(5, filter_num[1], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[1].s2 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(5, filter_num[1], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[1].s3 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(5, filter_num[1], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[1].s4 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(5, filter_num[1], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[1].s5 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(5, filter_num[1], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[1].s6 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(5, filter_num[1], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[1].s7 : -1.0f;

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
            detection_location[4096 + d * 16 + x] = is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION;
            detection_amplitude[4096 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : -1.0f;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_6(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
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
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[4][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[5][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                WRITE_CHANNEL(detect_to_detect[5][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(6, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(6, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(6, filter_num[0], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[0].s2 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(6, filter_num[0], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[0].s3 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(6, filter_num[0], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[0].s4 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(6, filter_num[0], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[0].s5 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(6, filter_num[0], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[0].s6 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(6, filter_num[0], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[0].s7 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(6, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[1].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(6, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[1].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(6, filter_num[1], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[1].s2 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(6, filter_num[1], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[1].s3 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(6, filter_num[1], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[1].s4 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(6, filter_num[1], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[1].s5 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(6, filter_num[1], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[1].s6 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(6, filter_num[1], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[1].s7 : -1.0f;

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
            detection_location[5120 + d * 16 + x] = is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION;
            detection_amplitude[5120 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : -1.0f;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_7(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
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
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[5][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[6][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                WRITE_CHANNEL(detect_to_detect[6][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(7, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(7, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(7, filter_num[0], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[0].s2 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(7, filter_num[0], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[0].s3 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(7, filter_num[0], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[0].s4 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(7, filter_num[0], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[0].s5 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(7, filter_num[0], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[0].s6 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(7, filter_num[0], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[0].s7 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(7, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[1].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(7, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[1].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(7, filter_num[1], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[1].s2 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(7, filter_num[1], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[1].s3 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(7, filter_num[1], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[1].s4 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(7, filter_num[1], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[1].s5 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(7, filter_num[1], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[1].s6 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(7, filter_num[1], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[1].s7 : -1.0f;

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
            detection_location[6144 + d * 16 + x] = is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION;
            detection_amplitude[6144 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : -1.0f;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_8(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
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
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[6][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[7][p]);
                hsum[p] = from_prev_hp + from_sp;
            }


            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? HMS_ENCODE_LOCATION(8, filter_num[0], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[0] = cand[0] ? hsum[0].s0 : -1.0f;
                loc[1] = cand[1] ? HMS_ENCODE_LOCATION(8, filter_num[0], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[1] = cand[1] ? hsum[0].s1 : -1.0f;
                loc[2] = cand[2] ? HMS_ENCODE_LOCATION(8, filter_num[0], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[2] = cand[2] ? hsum[0].s2 : -1.0f;
                loc[3] = cand[3] ? HMS_ENCODE_LOCATION(8, filter_num[0], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[3] = cand[3] ? hsum[0].s3 : -1.0f;
                loc[4] = cand[4] ? HMS_ENCODE_LOCATION(8, filter_num[0], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[4] = cand[4] ? hsum[0].s4 : -1.0f;
                loc[5] = cand[5] ? HMS_ENCODE_LOCATION(8, filter_num[0], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[5] = cand[5] ? hsum[0].s5 : -1.0f;
                loc[6] = cand[6] ? HMS_ENCODE_LOCATION(8, filter_num[0], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[6] = cand[6] ? hsum[0].s6 : -1.0f;
                loc[7] = cand[7] ? HMS_ENCODE_LOCATION(8, filter_num[0], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[7] = cand[7] ? hsum[0].s7 : -1.0f;
                loc[8] = cand[8] ? HMS_ENCODE_LOCATION(8, filter_num[1], channel_num[0]) : HMS_INVALID_LOCATION;
                amp[8] = cand[8] ? hsum[1].s0 : -1.0f;
                loc[9] = cand[9] ? HMS_ENCODE_LOCATION(8, filter_num[1], channel_num[1]) : HMS_INVALID_LOCATION;
                amp[9] = cand[9] ? hsum[1].s1 : -1.0f;
                loc[10] = cand[10] ? HMS_ENCODE_LOCATION(8, filter_num[1], channel_num[2]) : HMS_INVALID_LOCATION;
                amp[10] = cand[10] ? hsum[1].s2 : -1.0f;
                loc[11] = cand[11] ? HMS_ENCODE_LOCATION(8, filter_num[1], channel_num[3]) : HMS_INVALID_LOCATION;
                amp[11] = cand[11] ? hsum[1].s3 : -1.0f;
                loc[12] = cand[12] ? HMS_ENCODE_LOCATION(8, filter_num[1], channel_num[4]) : HMS_INVALID_LOCATION;
                amp[12] = cand[12] ? hsum[1].s4 : -1.0f;
                loc[13] = cand[13] ? HMS_ENCODE_LOCATION(8, filter_num[1], channel_num[5]) : HMS_INVALID_LOCATION;
                amp[13] = cand[13] ? hsum[1].s5 : -1.0f;
                loc[14] = cand[14] ? HMS_ENCODE_LOCATION(8, filter_num[1], channel_num[6]) : HMS_INVALID_LOCATION;
                amp[14] = cand[14] ? hsum[1].s6 : -1.0f;
                loc[15] = cand[15] ? HMS_ENCODE_LOCATION(8, filter_num[1], channel_num[7]) : HMS_INVALID_LOCATION;
                amp[15] = cand[15] ? hsum[1].s7 : -1.0f;

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
            detection_location[7168 + d * 16 + x] = is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION;
            detection_amplitude[7168 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : -1.0f;
        }
    }
}
