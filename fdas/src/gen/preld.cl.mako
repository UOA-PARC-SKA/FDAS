<%!
    from collections import defaultdict

    def get_buffer(outp, harm, roff):
        return (outp + roff) // harm

    def get_buffers_by_offset(outp, harm):
        d = defaultdict(list)
        for roff in range(harm):
            d[get_buffer(outp, harm, roff)] += [roff]
        return list(d.items())
%>\

__attribute__((reqd_work_group_size(${burst_len}, 1, 1)))
kernel void preloader_${harmonic}(global float * restrict fop,
                        const uint negative_filters)
{
<%
    offset_logic_req = n_parallel % harmonic > 0
    if offset_logic_req:
        n_buffers = get_buffer(n_parallel - 1, harmonic, harmonic - 1) + 1
        first_offset_to_use_last_buffer = 0
        for roff in range(harmonic):
            if get_buffer(n_parallel - 1, harmonic, roff) == n_buffers - 1:
                first_offset_to_use_last_buffer = roff
                break
    else:
        n_buffers = n_parallel // harmonic
%>\
% for i in range(n_buffers):
    local   float buf_${i}[${burst_len}];
% endfor
    private float ld[${burst_len}];

    int  filter_base  = get_group_id(0) * ${n_parallel} / ${harmonic};
    uint channel_base = get_group_id(1) * ${burst_len};
% if offset_logic_req:
    uint row_offset   = filter_base % ${harmonic};
% endif

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < ${n_buffers}) {
    % if offset_logic_req and first_offset_to_use_last_buffer > 0:
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

    c = get_local_id(0);

% for i in range(n_buffers):
    float b_${i} = buf_${i}[c];
% endfor

    for (uint z = 0; z < ${harmonic}; ++z) {
    % for j in range(n_parallel):
    % if offset_logic_req:
<% bboff = get_buffers_by_offset(j, harmonic) %>\
    % if len(bboff) == 1:
        WRITE_CHANNEL(preloaders_out[${harmonic - 1}][${j}], b_${bboff[0][0]});
    % elif len(bboff) == 2:
        WRITE_CHANNEL(preloaders_out[${harmonic - 1}][${j}], row_offset <= ${bboff[0][1][-1]} ? b_${bboff[0][0]} : b_${bboff[1][0]});
    % else:
        // ERROR!
    % endif
    % else:
        WRITE_CHANNEL(preloaders_out[${harmonic - 1}][${j}], b_${j // harmonic});
    % endif
    % endfor
    }
}
