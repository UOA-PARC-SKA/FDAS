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
<%
    from cl_codegen import get_output_mapping, lcm
%>\

#ifndef FDAS_GEN_INFO_H
#define FDAS_GEN_INFO_H

#include <CL/cl.hpp>

namespace GenInfo {
namespace Input {
    static const cl_ulong n_channels                = ${n_channels}L; // TODO: this (and everything derived from it) doesn't need to be statically known
    static const cl_uint  n_filters                 = ${n_filters};
    static const cl_uint  n_taps                    = ${n_taps};
    static const cl_uint  n_filters_per_accel_sign  = ${n_filters_per_accel_sign};
}
namespace FFT {
    static const cl_uint  n_points                  = ${fft_n_points};
    static const cl_uint  n_points_log              = ${fft_n_points_log};
    static const cl_uint  n_parallel                = ${fft_n_parallel};
    static const cl_uint  n_parallel_log            = ${fft_n_parallel_log};
    static const cl_uint  n_points_per_terminal     = ${fft_n_points_per_terminal};
    static const cl_uint  n_points_per_terminal_log = ${fft_n_points_per_terminal_log};
}
namespace FDF {
    static const cl_uint  tile_sz                   = ${fdf_tile_sz};
    static const cl_uint  tile_overlap              = ${fdf_tile_overlap};
    static const cl_uint  tile_payload              = ${fdf_tile_payload};
    static const cl_uint  n_tiles                   = ${fdf_n_tiles};
    static const cl_ulong input_sz                  = ${fdf_input_sz}L;
    static const cl_ulong padded_input_sz           = ${fdf_padded_input_sz}L;
    static const cl_ulong tiled_input_sz            = ${fdf_tiled_input_sz}L;
    static const cl_ulong output_sz                 = ${fdf_output_sz}L;
    static const cl_ulong templates_sz              = ${fdf_templates_sz}L;

    static const cl_uint  group_sz                  = ${fdf_group_sz};
}
namespace FOP {
    static const cl_ulong sz                        = ${fop_sz}L;
}
namespace HMS {
    static const cl_uint  n_planes                  = ${hms_n_planes};
    static const cl_uint  detection_sz              = ${hms_detection_sz};
    static const cl_uint  group_sz                  = ${hms_group_sz};
    static const cl_uint  bundle_sz                 = ${hms_bundle_sz};

    static const     cl_uint lcm = ${lcm(list(range(1, hms_n_planes + 1)))};
<%
    n_buffers_list = []
    first_offset_to_use_last_buffer_list = []

    for k in range(1, hms_n_planes + 1):
        out_map = get_output_mapping(hms_group_sz, k)
        n_buffers = max(out_map[-1].keys()) + 1

        need_base_row_offset = 1 < max(map(lambda x: len(x), out_map))
        first_offset_to_use_last_buffer = k
        for p in range(hms_group_sz):
            if (n_buffers - 1) in out_map[p]:
                first_offset_to_use_last_buffer = min(first_offset_to_use_last_buffer, min(out_map[p][n_buffers - 1]))

        n_buffers_list += [str(n_buffers)]
        first_offset_to_use_last_buffer_list += [str(first_offset_to_use_last_buffer)]
%>\
    static constexpr cl_uint n_buffers[${hms_n_planes}] = {${', '.join(n_buffers_list)}};
    static constexpr cl_uint first_offset_to_use_last_buffer[${hms_n_planes}] = {${', '.join(first_offset_to_use_last_buffer_list)}};

    constexpr cl_uint encode_location(cl_uint k, cl_int f, cl_uint c) {
        return (((k - 1) & 0x7) << 29) | (((f + ${n_filters_per_accel_sign}) & 0x7f) << 22) | (c & 0x3fffff);
    }
    constexpr cl_uint get_harmonic(cl_uint location) { return ((location >> 29) & 0x7) + 1; }
    constexpr cl_uint get_filter(cl_uint location)   { return ((location >> 22) & 0x7f) - ${n_filters_per_accel_sign}; }
    constexpr cl_uint get_channel(cl_uint location)  { return location & 0x3fffff; }

    static constexpr cl_uint invalid_location = encode_location(1, ${n_filters_per_accel_sign} + 1, 0);
}
namespace Output {
    static const cl_uint  n_candidates              = ${n_candidates};
}
}

#endif
