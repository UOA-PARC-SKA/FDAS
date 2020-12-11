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

#pragma OPENCL EXTENSION cl_intel_channels : enable

<% depth_attr = "__attribute__((depth(0)))" %>\
channel float2x4 load_to_tile ${depth_attr};

channel float2x4 fft_in ${depth_attr};
channel float2x4 fft_out ${depth_attr};

channel float2x4 ifft_in[${fft_n_engines}] ${depth_attr};
channel float2x4 ifft_out[${fft_n_engines}] ${depth_attr};

% if not hms_baseline:
channel ${hms_bundle_ty} preload_to_delay[${hms_n_planes}][${hms_group_sz}] ${depth_attr};
channel ${hms_bundle_ty} delay_to_detect[${hms_n_planes}][${hms_group_sz}] ${depth_attr};

channel ${hms_bundle_ty} detect_to_detect[${hms_n_planes - 1}][${hms_group_sz}] ${depth_attr};
channel uint  detect_location_out[${hms_n_planes}][${hms_slot_sz}] ${depth_attr};
channel float detect_power_out[${hms_n_planes}][${hms_slot_sz}] ${depth_attr};
% endif
