<%
    from hsum_codegen import get_output_mapping, lcm
%>\

namespace GenInfo {
    static const cl_uint n_planes = ${n_planes};
## FIXME: make use of "detection size" consistent
    static const cl_uint detection_sz = ${detection_sz * group_sz * bundle_sz};
    static const cl_uint group_sz = ${group_sz};
    static const cl_uint bundle_sz = ${bundle_sz};

    static const cl_uint lcm = ${lcm(list(range(1, n_planes + 1)))};
<%
    n_buffers_list = []
    first_offset_to_use_last_buffer_list = []

    for k in range(1, n_planes + 1):
        out_map = get_output_mapping(group_sz, k)
        n_buffers = max(out_map[-1].keys()) + 1

        need_base_row_offset = 1 < max(map(lambda x: len(x), out_map))
        first_offset_to_use_last_buffer = k
        for p in range(group_sz):
            if (n_buffers - 1) in out_map[p]:
                first_offset_to_use_last_buffer = min(first_offset_to_use_last_buffer, min(out_map[p][n_buffers - 1]))

        n_buffers_list += [str(n_buffers)]
        first_offset_to_use_last_buffer_list += [str(first_offset_to_use_last_buffer)]
%>\

    static constexpr cl_uint n_buffers[${n_planes}] = {${', '.join(n_buffers_list)}};
    static constexpr cl_uint first_offset_to_use_last_buffer[${n_planes}] = {${', '.join(first_offset_to_use_last_buffer_list)}};
}
