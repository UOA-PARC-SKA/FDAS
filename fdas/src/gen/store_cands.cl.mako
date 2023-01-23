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

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void store_cands(global uint * restrict detection_location,
                        global float * restrict detection_power)
{
    for (uint d = 0; d < ${hms_n_planes * hms_detection_sz}; ++d) {
        #pragma unroll
        for (uint x = 0; x < ${hms_slot_sz}; ++x) {
            uint location = read_channel_intel(detect_location_out[${hms_n_planes - 1}][x]);
            float power = read_channel_intel(detect_power_out[${hms_n_planes - 1}][x]);
            detection_location[d * ${hms_slot_sz} + x] = location;
            detection_power[d * ${hms_slot_sz} + x] = power;
        }
    }
}
