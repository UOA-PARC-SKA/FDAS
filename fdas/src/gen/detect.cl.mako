## FDAS -- Fourier Domain Acceleration Search, FPGA-accelerated with OpenCL
## Copyright (C) 2020  Parallel and Reconfigurable Computing Lab,
##                     Dept. of Electrical, Computer, and Software Engineering,
##                     University of Auckland, New Zealand
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_${k}(
##                      global uint * restrict detection_location,
##                      global float * restrict detection_amplitude,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
<%
    bundle_idx = lambda i: f".s{i:X}" if hms_bundle_sz > 1 else ""
    assert hms_detection_sz <= 64 and bin(hms_detection_sz).count('1') == 1  # power of 2
%>\
    uint location_buffer[${hms_detection_sz}][${hms_group_sz * hms_bundle_sz}];
    float amplitude_buffer[${hms_detection_sz}][${hms_group_sz * hms_bundle_sz}];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, ${n_filters_per_accel_sign + 1}, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * ${hms_group_sz};
        int filter_num[${hms_group_sz}];
        bool filter_mask[${hms_group_sz}];
        #pragma unroll
        for (uint p = 0; p < ${hms_group_sz}; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * ${hms_bundle_sz};
            uint channel_num[${hms_bundle_sz}];
            #pragma unroll
            for (uint q = 0; q < ${hms_bundle_sz}; ++q)
                channel_num[q] = bundle_base + q;

            ${hms_bundle_ty} hsum[${hms_group_sz}];

        % if k == 1:
            #pragma unroll
            for (uint p = 0; p < ${hms_group_sz}; ++p) {
                ${hms_bundle_ty} from_fop = READ_CHANNEL(delay_to_detect[${k - 1}][p]);
                hsum[p] = from_fop;
            }
        %else:
            #pragma unroll
            for (uint p = 0; p < ${hms_group_sz}; ++p) {
                ${hms_bundle_ty} from_prev_hp = READ_CHANNEL(detect_to_detect[${k - 2}][p]);
                ${hms_bundle_ty} from_sp = READ_CHANNEL(delay_to_detect[${k - 1}][p]);
                hsum[p] = from_prev_hp + from_sp;
            }
        % endif

        %if k < hms_n_planes:
            #pragma unroll
            for (uint p = 0; p < ${hms_group_sz}; ++p)
                WRITE_CHANNEL(detect_to_detect[${k - 1}][p], hsum[p]);
        %endif

            bool cand[${hms_group_sz * hms_bundle_sz}];

        %for p in range(hms_group_sz):
        %for q in range(hms_bundle_sz):
            cand[${p * hms_bundle_sz + q}] = (hsum[${p}]${bundle_idx(q)} > threshold) & filter_mask[${p}];
        %endfor
        %endfor

            bool any_cand = ${' | '.join(f"cand[{x}]" for x in range(hms_group_sz * hms_bundle_sz))};
            if (any_cand) {
                uint loc[${hms_group_sz * hms_bundle_sz}];
                float amp[${hms_group_sz * hms_bundle_sz}];

            % for p in range(hms_group_sz):
            % for q in range(hms_bundle_sz):
<% x = p * hms_bundle_sz + q %>\
                loc[${x}] = cand[${x}] ? encode_location(${k}, filter_num[${p}], channel_num[${q}]) : invalid_location;
                amp[${x}] = cand[${x}] ? hsum[${p}]${bundle_idx(q)} : invalid_amplitude;
            % endfor
            % endfor

                uint slot = next;
                next = (next + 1) & ${hms_detection_sz - 1};

                #pragma unroll
                for (uint x = 0; x < ${hms_group_sz * hms_bundle_sz}; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint d = 0; d < ${hms_detection_sz}; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < ${hms_group_sz * hms_bundle_sz}; ++x) {
##             detection_location[${(k-1) * hms_detection_sz * hms_group_sz * hms_bundle_sz} + d * ${hms_group_sz * hms_bundle_sz} + x] = is_valid ? location_buffer[d][x] : invalid_location;
##             detection_amplitude[${(k-1) * hms_detection_sz * hms_group_sz * hms_bundle_sz} + d * ${hms_group_sz * hms_bundle_sz} + x] = is_valid ? amplitude_buffer[d][x] : invalid_amplitude;
            WRITE_CHANNEL(detect_to_store_location[${k-1}][x], is_valid ? location_buffer[d][x] : invalid_location);
            WRITE_CHANNEL(detect_to_store_amplitude[${k-1}][x], is_valid ? amplitude_buffer[d][x] : invalid_amplitude);
        }
    }
}
