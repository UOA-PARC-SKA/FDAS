<%!
    from math import gcd, ceil
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
    n_i_per_buf = int(ceil(workgroup_sz // harmonic / bundle_sz))
    buffer_sz = n_i_per_buf * bundle_sz

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
    private float bundle_load[${bundle_sz}];

    int  filter_base  = get_group_id(1) * ${n_parallel} / ${harmonic};
% if n_configs > 1:
    uint row_offset   = get_group_id(1) * ${n_parallel} % ${harmonic};
% endif
    uint channel_base = get_group_id(0) * ${workgroup_sz // harmonic};

    uint buffer = get_local_id(0) / ${n_i_per_buf};
    uint bundle = get_local_id(0) % ${n_i_per_buf};

    int  filter = filter_base + buffer;

    if (   buffer < ${n_buffers}
% if first_offset_to_use_last_buffer > 0:
        && (buffer < ${n_buffers - 1} || row_offset >= ${first_offset_to_use_last_buffer})
% endif
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < ${bundle_sz}; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * ${bundle_sz} + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < ${bundle_sz}; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
    % for b in range(n_buffers):
        case ${b}:
            #pragma unroll
            for (uint x = 0; x < ${bundle_sz}; ++x)
                buffer_${b}[bundle * ${bundle_sz} + x] = bundle_load[x];
            break;
    % endfor
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / ${harmonic};

% for b in range(n_buffers):
    float v_${b} = buffer_${b}[chan];
% endfor

% for p in range(n_parallel):
% if len(buffers_for_output[p]) == 1:
    WRITE_CHANNEL(preload_to_detect[${harmonic - 1}][${p}], v_${buffers_for_output[p][0]});
% else:
    WRITE_CHANNEL(preload_to_detect[${harmonic - 1}][${p}], row_offset < ${buffers_for_output[p][2]} ? v_${buffers_for_output[p][0]} : v_${buffers_for_output[p][1]});
% endif
% endfor
}
