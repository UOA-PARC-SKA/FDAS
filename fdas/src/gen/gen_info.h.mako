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
    static const cl_uint  n_templates               = ${n_templates};
    static const cl_uint  max_template_len          = ${max_template_len};
    static const cl_int   n_tmpl_per_accel_sign     = ${n_tmpl_per_accel_sign}; // intentionally signed
}
namespace FFT {
    static const cl_uint  n_points                  = ${fft_n_points};
    static const cl_uint  n_points_log              = ${fft_n_points_log};
    static const cl_uint  n_parallel                = ${fft_n_parallel};
    static const cl_uint  n_parallel_log            = ${fft_n_parallel_log};
    static const cl_uint  n_points_per_terminal     = ${fft_n_points_per_terminal};
    static const cl_uint  n_points_per_terminal_log = ${fft_n_points_per_terminal_log};
    static const cl_uint  n_engines                 = ${fft_n_engines};
}
namespace FTC {
    static const cl_uint  tile_sz                   = ${ftc_tile_sz};
    static const cl_uint  tile_overlap              = ${ftc_tile_overlap};
    static const cl_uint  tile_payload              = ${ftc_tile_payload};
    static const cl_uint  pack_sz                   = ${ftc_pack_sz};
}
namespace HMS {
    static const cl_uint  n_planes                  = ${hms_n_planes};
    static const cl_uint  detection_sz              = ${hms_detection_sz};
    static const cl_uint  group_sz                  = ${hms_group_sz};
    static const cl_uint  bundle_sz                 = ${hms_bundle_sz};
    static const cl_uint  slot_sz                   = ${hms_slot_sz};

    static const     cl_uint lcm = ${lcm(list(range(1, hms_n_planes + 1)))};
<%
    n_buffers_list = []
    first_cc_to_use_last_buffer_list = []

    for k in range(1, hms_n_planes + 1):
        out_map = get_output_mapping(hms_group_sz, k)
        n_buffers = max(out_map[-1].keys()) + 1

        first_cc_to_use_last_buffer = k
        for p in range(hms_group_sz):
            if (n_buffers - 1) in out_map[p]:
                first_cc_to_use_last_buffer = min(first_cc_to_use_last_buffer, min(out_map[p][n_buffers - 1]))

        n_buffers_list += [str(n_buffers)]
        first_cc_to_use_last_buffer_list += [str(first_cc_to_use_last_buffer)]
%>\
    static constexpr cl_uint n_buffers[${hms_n_planes}] = {${', '.join(n_buffers_list)}};
    static constexpr cl_uint first_cc_to_use_last_buffer[${hms_n_planes}] = {${', '.join(first_cc_to_use_last_buffer_list)}};

    constexpr cl_uint encode_location(cl_uint harm, cl_int tmpl, cl_uint freq) {
        return (((harm - 1) & 0x7) << 29) | (((tmpl + ${n_tmpl_per_accel_sign}) & 0x7f) << 22) | (freq & 0x3fffff);
    }
    constexpr cl_uint get_harmonic(cl_uint location)      { return ((location >> 29) & 0x7) + 1; }
    constexpr cl_int  get_template_num(cl_uint location)  { return ((location >> 22) & 0x7f) - ${n_tmpl_per_accel_sign}; }
    constexpr cl_uint get_frequency_bin(cl_uint location) { return location & 0x3fffff; }

    static constexpr cl_uint invalid_location = encode_location(1, ${n_tmpl_per_accel_sign} + 1, 0);
}
namespace Output {
    static const cl_uint  n_candidates              = ${n_candidates};
}
}

#endif
