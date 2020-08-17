<%
    from hsum_codegen import get_output_mapping

    bundle_idx = lambda i: f".s{i:X}" if bundle_sz > 1 else ""

    out_map = get_output_mapping(group_sz, k)
    n_buffers = max(out_map[-1].keys()) + 1

    need_base_row_offset = 1 < max(map(lambda x: len(x), out_map))
    first_offset_to_use_last_buffer = k
    for p in range(group_sz):
        if (n_buffers - 1) in out_map[p]:
            first_offset_to_use_last_buffer = min(first_offset_to_use_last_buffer, min(out_map[p][n_buffers - 1]))

    buffers_for_output = []
    for p in range(group_sz):
        idxs = sorted(list(out_map[p].keys()))
        if len(idxs) == 1:
            buffers_for_output += [(idxs[0],)]
        else:
            assert len(idxs) == 2
            buffers_for_output += [(idxs[0], idxs[1], min(out_map[p][idxs[1]]))]
%>\

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_${k}(global ${bundle_ty} * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                  % for r in range(n_buffers):
                      const int filter_${r},
                  % endfor
                      const uint n_channel_bundles)
{
    ${bundle_ty} load[${n_buffers}];
    ${bundle_ty} out[${group_sz}];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
    % for r in range(n_buffers):
        load[${r}] = ${r} < n_rows ? fop[fop_idx(filter_${r}, bundle)] : 0.0f;
    % endfor

    % for p in range(group_sz):
    % if len(buffers_for_output[p]) == 1:
        out[${p}] = load[${buffers_for_output[p][0]}];
    % else:
        out[${p}] = base_row_offset < ${buffers_for_output[p][2]} ? load[${buffers_for_output[p][0]}] : load[${buffers_for_output[p][1]}];
    % endif
    % endfor

        #pragma unroll
        for (uint p = 0; p < ${group_sz}; ++p)
            WRITE_CHANNEL(preload_to_delay[${k - 1}][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_${k}(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    ${bundle_ty} in[${group_sz}];
    ${bundle_ty} out[${group_sz}];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < ${k - 1} ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < ${group_sz}; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[${k - 1}][p]);
        }

        switch (m) {
        % for l in range(k):
            case ${l}:
                #pragma unroll
                for (uint p = 0; p < ${group_sz}; ++p) {
            % for q in range(bundle_sz):
                    out[p]${bundle_idx(q)} = in[p]${bundle_idx((l * bundle_sz + q) // k)};
            % endfor
                }
                break;
        % endfor
            default:
                #pragma unroll
                for (uint p = 0; p < ${group_sz}; ++p) {
            % for q in range(bundle_sz):
                    out[p]${bundle_idx(q)} = 0.0f;
            % endfor
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < ${group_sz}; ++p)
            WRITE_CHANNEL(delay_to_detect[${k - 1}][p], out[p]);
    }
}
