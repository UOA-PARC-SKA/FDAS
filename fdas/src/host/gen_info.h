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
    static const cl_ulong n_channels                = 62176L; // TODO: this (and everything derived from it) doesn't need to be statically known
    static const cl_uint  n_filters                 = 21;
    static const cl_uint  n_taps                    = 106;
    static const cl_uint  n_filters_per_accel_sign  = 10;
}
namespace FFT {
    static const cl_uint  n_points                  = 2048;
    static const cl_uint  n_points_log              = 11;
    static const cl_uint  n_parallel                = 4;
    static const cl_uint  n_parallel_log            = 2;
    static const cl_uint  n_points_per_terminal     = 512;
    static const cl_uint  n_points_per_terminal_log = 9;
}
namespace FDF {
    static const cl_uint  tile_sz                   = 2048;
    static const cl_uint  tile_overlap              = 105;
    static const cl_uint  tile_payload              = 1943;
    static const cl_uint  n_tiles                   = 32;
    static const cl_ulong input_sz                  = 62176L;
    static const cl_ulong padded_input_sz           = 64119L;
    static const cl_ulong tiled_input_sz            = 65536L;
    static const cl_ulong output_sz                 = 62176L;
    static const cl_ulong templates_sz              = 43008L;

    static const cl_uint  group_sz                  = 3;
}
namespace FOP {
    static const cl_ulong sz                        = 1305696L;
}
namespace HMS {
    static const cl_uint  n_planes                  = 8;
    static const cl_uint  detection_sz              = 64;
    static const cl_uint  group_sz                  = 2;
    static const cl_uint  bundle_sz                 = 8;

    static const     cl_uint lcm = 840;
    static constexpr cl_uint n_buffers[8] = {2, 1, 2, 1, 2, 1, 2, 1};
    static constexpr cl_uint first_offset_to_use_last_buffer[8] = {0, 0, 2, 0, 4, 0, 6, 0};

    constexpr cl_uint encode_location(cl_uint k, cl_int f, cl_uint c) {
        return (((k - 1) & 0x7) << 29) | (((f + 10) & 0x7f) << 22) | (c & 0x3fffff);
    }
    constexpr cl_uint get_harmonic(cl_uint location) { return ((location >> 29) & 0x7) + 1; }
    constexpr cl_uint get_filter(cl_uint location)   { return ((location >> 22) & 0x7f) - 10; }
    constexpr cl_uint get_channel(cl_uint location)  { return location & 0x3fffff; }

    static constexpr cl_uint invalid_location = encode_location(1, 10 + 1, 0);
}
namespace Output {
    static const cl_uint  n_candidates              = 8192;
}
}

#endif
