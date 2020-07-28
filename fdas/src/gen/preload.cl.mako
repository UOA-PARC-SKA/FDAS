<%!
    from math import gcd, ceil, log2
    from collections import defaultdict
%>\

__attribute__((reqd_work_group_size(${workgroup_sz}, 1, 1)))
kernel void preload_${k}(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
<%
    divisor = gcd(k, group_sz)
    configs = dict()
    for l in range(k // divisor):
        config = tuple([(l * divisor + p) // k for p in range(group_sz)])
        if config not in configs:
            configs[config] = l * divisor

    configs_sorted = list(sorted(configs.keys()))
    n_configs = len(configs_sorted)
    n_buffers = configs_sorted[-1][group_sz - 1] + 1
    buffer_sz = workgroup_sz // k * bundle_sz
    n_elements_per_workitem = 2 ** int(ceil(log2(n_buffers * bundle_sz)))
    n_workitems_per_buffer = buffer_sz // n_elements_per_workitem
    if n_workitems_per_buffer * n_elements_per_workitem < buffer_sz:
        raise RuntimeError("Integer division with remainder")

    first_offset_to_use_last_buffer = 0
    for config, offset in configs.items():
        if config[group_sz - 1] == n_buffers - 1:
            first_offset_to_use_last_buffer = offset
            break

    buffers_for_output = []
    for p in range(group_sz):
        first_buf = configs_sorted[0][p]
        second_buf = -1
        offset = -1
        for c in configs_sorted:
            if c[p] > first_buf:
                second_buf = c[p]
                offset = configs[c]
                break
        if second_buf == -1:
            buffers_for_output += [(first_buf,)]
        else:
            buffers_for_output += [(first_buf, second_buf, offset)]
%>\
% for r in range(n_buffers):
    local   float buffer_${r}[${buffer_sz}];
% endfor
    private float load[${n_elements_per_workitem}];

    uint base_row = get_group_id(1) * ${group_sz} / ${k};
% if n_configs > 1:
    uint base_row_offset = get_group_id(1) * ${group_sz} % ${k};
% endif
    uint base_column = get_group_id(0) * ${buffer_sz};

    uint row = get_local_id(0) / ${n_workitems_per_buffer};
    uint burst = get_local_id(0) % ${n_workitems_per_buffer};

    int filter = base_row + row;

    if (row < ${n_buffers}
% if first_offset_to_use_last_buffer > 0:
        && (row < ${n_buffers - 1} || base_row_offset >= ${first_offset_to_use_last_buffer})
% endif
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < ${n_elements_per_workitem}; ++x)
            load[x] = fop[FOP_IDX(filter, base_column + burst * ${n_elements_per_workitem} + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < ${n_elements_per_workitem}; ++x)
            load[x] = 0.0f;
    }

    switch (row) {
    % for r in range(n_buffers):
        case ${r}:
            #pragma unroll
            for (uint x = 0; x < ${n_elements_per_workitem}; ++x)
                buffer_${r}[burst * ${n_elements_per_workitem} + x] = load[x];
            break;
    % endfor
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

% for q in range(bundle_sz):
    uint channel_${q} = (get_local_id(0) * ${bundle_sz} + ${q}) / ${k};
% endfor

% for r in range(n_buffers):
    float amplitude_${r}[${bundle_sz}] = {${', '.join(f"buffer_{r}[channel_{q}]" for q in range(bundle_sz))}};
% endfor

% for p in range(group_sz):
% for q in range(bundle_sz):
% if len(buffers_for_output[p]) == 1:
    WRITE_CHANNEL(preload_to_detect[${k - 1}][${p}][${q}], amplitude_${buffers_for_output[p][0]}[${q}]);
% else:
    WRITE_CHANNEL(preload_to_detect[${k - 1}][${p}][${q}], base_row_offset < ${buffers_for_output[p][2]} ? amplitude_${buffers_for_output[p][0]}[${q}] : amplitude_${buffers_for_output[p][1]}[${q}]);
% endif
% endfor
% endfor
}
