<%!
    from math import gcd
    from collections import defaultdict
%>\

__attribute__((reqd_work_group_size(${burst_len * harmonic}, 1, 1)))
kernel void preloader_${harmonic}(global float * restrict fop,
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

    first_offset_to_use_last_buffer = 0
    for config, roff in configs.items():
        if config[n_parallel - 1] == n_buffers - 1:
            first_offset_to_use_last_buffer = roff
            break

    buffers_for_output = []
    for j in range(n_parallel):
        first_buf = configs_sorted[0][j]
        second_buf = -1
        roff = -1
        for c in configs_sorted:
            if c[j] > first_buf:
                second_buf = c[j]
                roff = configs[c]
                break
        if second_buf == -1:
            buffers_for_output += [(first_buf,)]
        else:
            buffers_for_output += [(first_buf, second_buf, roff)]
%>\
% for i in range(n_buffers):
    local   float buf_${i}[${burst_len}];
% endfor
    private float ld[${burst_len}];

    int  filter_base  = get_group_id(1) * ${n_parallel} / ${harmonic};
    uint channel_base = get_group_id(0) * ${burst_len};
% if n_configs > 0:
    uint row_offset   = get_group_id(1) * ${n_parallel} % ${harmonic};
% endif

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < ${n_buffers}) {
    % if first_offset_to_use_last_buffer > 0:
        if (get_local_id(0) < ${n_buffers - 1} || row_offset >= ${first_offset_to_use_last_buffer}) {
            #pragma unroll
            for (c = 0; c < ${burst_len}; ++c)
                ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
        } else {
            #pragma unroll
            for (c = 0; c < ${burst_len}; ++c)
                ld[c] = 0.0f;
        }
    %else:
        #pragma unroll
        for (c = 0; c < ${burst_len}; ++c)
            ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
    % endif
    }

    switch (get_local_id(0)) {
    % for i in range(n_buffers):
        case ${i}:
            #pragma unroll
            for (c = 0; c < ${burst_len}; ++c)
                buf_${i}[c] = ld[c];
            break;
    % endfor
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0) / ${harmonic};

% for i in range(n_buffers):
    float b_${i} = buf_${i}[c];
% endfor

% for j in range(n_parallel):
% if len(buffers_for_output[j]) == 1:
    WRITE_CHANNEL(preloaders_out[${harmonic - 1}][${j}], b_${buffers_for_output[j][0]});
% else:
    WRITE_CHANNEL(preloaders_out[${harmonic - 1}][${j}], row_offset < ${buffers_for_output[j][2]} ? b_${buffers_for_output[j][0]} : b_${buffers_for_output[j][1]});
% endif
% endfor
}
