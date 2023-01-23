/*
 * FDAS -- Fourier Domain Acceleration Search, FPGA-accelerated with OpenCL
 * Copyright (C) 2020  Parallel and Reconfigurable Computing Lab,
 *                     Dept. of Electrical, Computer, and Software Engineering,
 *                     University of Auckland, New Zealand
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#ifndef FDAS_GEN_INFO_H
#define FDAS_GEN_INFO_H

#include <CL/cl.hpp>

namespace GenInfo {
namespace Input {
    static const cl_uint  n_templates               = 85;
    static const cl_uint  max_template_len          = 421;
    static const cl_int   n_tmpl_per_accel_sign     = 42; // intentionally signed
}
namespace FFT {
    static const cl_uint  n_points                  = 2048;
    static const cl_uint  n_points_log              = 11;
    static const cl_uint  n_parallel                = 4;
    static const cl_uint  n_parallel_log            = 2;
    static const cl_uint  n_points_per_terminal     = 512;
    static const cl_uint  n_points_per_terminal_log = 9;
    static const cl_uint  n_engines                 = 5;
}
namespace FTC {
    static const cl_uint  tile_sz                   = 2048;
    static const cl_uint  tile_overlap              = 420;
    static const cl_uint  tile_payload              = 1628;
    static const cl_uint  pack_sz                   = 4;
}
namespace HMS {
    static const cl_uint  baseline                  = false;

    static const cl_uint  n_planes                  = 8;
    static const cl_uint  detection_sz              = 64;
    static const cl_uint  group_sz                  = 3;
    static const cl_uint  bundle_sz                 = 4;
    static const cl_uint  slot_sz                   = 16;

    static const cl_uint  unroll_x                  = 1;

    static const     cl_uint lcm = 840;
    static constexpr cl_uint n_buffers[8] = {3, 2, 1, 2, 2, 1, 2, 2};
    static constexpr cl_uint first_cc_to_use_last_buffer[8] = {0, 0, 0, 2, 3, 0, 5, 6};

    constexpr cl_uint encode_location(cl_uint harm, cl_int tmpl, cl_uint freq) {
        return (((harm - 1) & 0x7) << 29) | (((tmpl + 42) & 0x7f) << 22) | (freq & 0x3fffff);
    }
    constexpr cl_uint get_harmonic(cl_uint location)      { return ((location >> 29) & 0x7) + 1; }
    constexpr cl_int  get_template_num(cl_uint location)  { return ((location >> 22) & 0x7f) - 42; }
    constexpr cl_uint get_frequency_bin(cl_uint location) { return location & 0x3fffff; }

    static constexpr cl_uint invalid_location = encode_location(1, 42 + 1, 0);
}
namespace Output {
    static const cl_uint  n_candidates              = 8192;
}
}

#endif
