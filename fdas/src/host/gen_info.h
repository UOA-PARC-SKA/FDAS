
// Auto-generated file -- see `hsum_codegen.py` and `gen_info.h.mako`.

namespace GenInfo {
    static const cl_uint n_planes = 8;
    static const cl_uint detection_sz = 64;
    static const cl_uint group_sz = 4;
    static const cl_uint bundle_sz = 4;

    static const cl_uint lcm = 840;

    static constexpr cl_uint n_buffers[8] = {4, 2, 2, 1, 2, 2, 2, 1};
    static constexpr cl_uint first_offset_to_use_last_buffer[8] = {0, 0, 0, 0, 2, 4, 4, 0};
}
