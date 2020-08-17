
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_${k}(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
<%
    bundle_idx = lambda i: f".s{i}" if bundle_sz > 1 else ""
    assert detection_sz <= 64 and bin(detection_sz).count('1') == 1  # power of 2
%>\
    uint location_buffer[${detection_sz}][${group_sz * bundle_sz}];
    float amplitude_buffer[${detection_sz}][${group_sz * bundle_sz}];

    ulong valid = 0l;
    uint next = 0;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * ${group_sz};
        int filter_num[${group_sz}];
        bool filter_mask[${group_sz}];
        #pragma unroll
        for (uint p = 0; p < ${group_sz}; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * ${bundle_sz};
            uint channel_num[${bundle_sz}];
            #pragma unroll
            for (uint q = 0; q < ${bundle_sz}; ++q)
                channel_num[q] = bundle_base + q;

            ${bundle_ty} hsum[${group_sz}];

        % if k == 1:
            #pragma unroll
            for (uint p = 0; p < ${group_sz}; ++p) {
                ${bundle_ty} from_fop = READ_CHANNEL(delay_to_detect[${k - 1}][p]);
                hsum[p] = from_fop;
            }
        %else:
            #pragma unroll
            for (uint p = 0; p < ${group_sz}; ++p) {
                ${bundle_ty} from_prev_hp = READ_CHANNEL(detect_to_detect[${k - 2}][p]);
                ${bundle_ty} from_sp = READ_CHANNEL(delay_to_detect[${k - 1}][p]);
                hsum[p] = from_prev_hp + from_sp;
            }
        % endif

        %if k < n_planes:
            #pragma unroll
            for (uint p = 0; p < ${group_sz}; ++p)
                WRITE_CHANNEL(detect_to_detect[${k - 1}][p], hsum[p]);
        %endif

            bool cand[${group_sz * bundle_sz}];

        %for p in range(group_sz):
        %for q in range(bundle_sz):
            cand[${p * bundle_sz + q}] = (hsum[${p}]${bundle_idx(q)} > threshold) & filter_mask[${p}];
        %endfor
        %endfor

            bool any_cand = ${' | '.join(f"cand[{x}]" for x in range(group_sz * bundle_sz))};
            if (any_cand) {
                uint loc[${group_sz * bundle_sz}];
                float amp[${group_sz * bundle_sz}];

            % for p in range(group_sz):
            % for q in range(bundle_sz):
<% x = p * bundle_sz + q %>\
                loc[${x}] = cand[${x}] ? HMS_ENCODE_LOCATION(${k}, filter_num[${p}], channel_num[${q}]) : HMS_INVALID_LOCATION;
                amp[${x}] = cand[${x}] ? hsum[${p}]${bundle_idx(q)} : -1.0f;
            % endfor
            % endfor

                uint slot = next;
                next = (next + 1) & ${detection_sz - 1};

                #pragma unroll
                for (uint x = 0; x < ${group_sz * bundle_sz}; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint d = 0; d < ${detection_sz}; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < ${group_sz * bundle_sz}; ++x) {
            detection_location[${(k-1) * detection_sz * group_sz * bundle_sz} + d * ${group_sz * bundle_sz} + x] = is_valid ? location_buffer[d][x] : HMS_INVALID_LOCATION;
            detection_amplitude[${(k-1) * detection_sz * group_sz * bundle_sz} + d * ${group_sz * bundle_sz} + x] = is_valid ? amplitude_buffer[d][x] : -1.0f;
        }
    }
}
