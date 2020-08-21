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

// Auto-generated file -- see `hsum_codegen.py` and `gen_info.h.mako`.

namespace GenInfo {
    static const cl_uint n_planes = 8;
    static const cl_uint detection_sz = 1024;
    static const cl_uint group_sz = 2;
    static const cl_uint bundle_sz = 8;

    static const cl_uint lcm = 840;

    static constexpr cl_uint n_buffers[8] = {2, 1, 2, 1, 2, 1, 2, 1};
    static constexpr cl_uint first_offset_to_use_last_buffer[8] = {0, 0, 2, 0, 4, 0, 6, 0};
}
