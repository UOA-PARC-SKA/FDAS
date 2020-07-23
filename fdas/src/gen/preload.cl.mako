<%!
    from math import gcd, ceil, log2
    from collections import defaultdict
%>\

__attribute__((reqd_work_group_size(${workgroup_sz}, 1, 1)))
kernel void preload_${harmonic}(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
<%
    gcd_kp = gcd(harmonic, n_parallel)
    configs = dict()
    for l in range(harmonic // gcd_kp):
        config = tuple([(gcd_kp * l + j) // harmonic for j in range(n_parallel)])
        if config not in configs:
            configs[config] = gcd_kp * l

    configs_sorted = list(sorted(configs.keys()))
    n_configs = len(configs_sorted)
    n_buffers = configs_sorted[-1][n_parallel - 1] + 1
    buffer_sz = workgroup_sz // harmonic * bundle_sz
    n_elements_per_workitem = 2 ** int(ceil(log2(n_buffers * bundle_sz)))
    n_workitems_per_buffer = buffer_sz // n_elements_per_workitem
    if n_workitems_per_buffer * n_elements_per_workitem < buffer_sz:
        raise RuntimeError("Integer division with remainder")

    first_offset_to_use_last_buffer = 0
    for config, roff in configs.items():
        if config[n_parallel - 1] == n_buffers - 1:
            first_offset_to_use_last_buffer = roff
            break

    buffers_for_output = []
    for p in range(n_parallel):
        first_buf = configs_sorted[0][p]
        second_buf = -1
        roff = -1
        for c in configs_sorted:
            if c[p] > first_buf:
                second_buf = c[p]
                roff = configs[c]
                break
        if second_buf == -1:
            buffers_for_output += [(first_buf,)]
        else:
            buffers_for_output += [(first_buf, second_buf, roff)]
%>\
% for b in range(n_buffers):
    local   float buffer_${b}[${buffer_sz}];
% endfor
    private float load[${n_elements_per_workitem}];

    uint group_row = get_group_id(1) * ${n_parallel} / ${harmonic};
% if n_configs > 1:
    uint group_row_offset = get_group_id(1) * ${n_parallel} % ${harmonic};
% endif
    uint group_col = get_group_id(0) * ${buffer_sz};

    uint item_row = get_local_id(0) / ${n_workitems_per_buffer};
    uint item_col = get_local_id(0) % ${n_workitems_per_buffer} * ${n_elements_per_workitem};

    int filter = group_row + item_row;

    if (item_row < ${n_buffers}
% if first_offset_to_use_last_buffer > 0:
        && (item_row < ${n_buffers - 1} || group_row_offset >= ${first_offset_to_use_last_buffer})
% endif
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < ${n_elements_per_workitem}; ++x)
            load[x] = fop[FOP_IDX(filter, group_col + item_col + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < ${n_elements_per_workitem}; ++x)
            load[x] = 0.0f;
    }

    switch (item_row) {
    % for b in range(n_buffers):
        case ${b}:
            #pragma unroll
            for (uint x = 0; x < ${n_elements_per_workitem}; ++x)
                buffer_${b}[item_col + x] = load[x];
            break;
    % endfor
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

% for q in range(bundle_sz):
    uint channel_${q} = (get_local_id(0) * ${bundle_sz} + ${q}) / ${harmonic};
% endfor

% for b in range(n_buffers):
    float v_${b}[${bundle_sz}] = {${', '.join(f"buffer_{b}[channel_{q}]" for q in range(bundle_sz))}};
% endfor

% for p in range(n_parallel):
% for q in range(bundle_sz):
% if len(buffers_for_output[p]) == 1:
    WRITE_CHANNEL(preload_to_detect[${harmonic - 1}][${p}][${q}], v_${buffers_for_output[p][0]}[${q}]);
% else:
    WRITE_CHANNEL(preload_to_detect[${harmonic - 1}][${p}][${q}], group_row_offset < ${buffers_for_output[p][2]} ? v_${buffers_for_output[p][0]}[${q}] : v_${buffers_for_output[p][1]}[${q}]);
% endif
% endfor
% endfor
}
