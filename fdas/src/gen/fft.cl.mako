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
% if both_directions:
kernel void fft_${engine}(const uint n_tiles, const uint is_inverse)
% else:
kernel void fft_${engine}(const uint n_tiles)
% endif
{
    const float2x4 zeros = {${", ".join(["0"] * fft_n_parallel)}};

    float2x4 __attribute__((bank_bits(${fft_n_points_per_terminal_log}))) buf[2][${fft_n_points_per_terminal}];
    float2 fft_delay_elements[${fft_n_points + fft_n_parallel * (fft_n_points_log - 3)}];
    float2x4 data;

    for (uint tile = 0; tile < n_tiles + 2; ++tile) {
        for (uint step = 0; step < ${fft_n_points_per_terminal}; ++step) {
            if (tile >= 1) {
                buf[1 - (tile & 1)][bit_reversed(step, ${fft_n_points_per_terminal_log})] = data;
            }
            if (tile >= 2) {
            % if both_directions:
                if (! is_inverse)
                    write_channel_intel(fft_out, buf[tile & 1][step]);
                else
                    write_channel_intel(ifft_out[${engine}], buf[tile & 1][step]);
            % else:
                write_channel_intel(ifft_out[${engine}], buf[tile & 1][step]);
            % endif
            }

            if (tile < n_tiles) {
            % if both_directions:
                if (! is_inverse)
                    data = read_channel_intel(fft_in);
                else
                    data = read_channel_intel(ifft_in[${engine}]);
            % else:
                data = read_channel_intel(ifft_in[${engine}]);
            % endif
            } else {
                data = zeros;
            }

            data = fft_step(data, step, fft_delay_elements, ${"is_inverse" if both_directions else "1"}, ${fft_n_points_log});
        }
    }
}
