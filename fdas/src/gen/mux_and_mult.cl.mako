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
    n_steps = fft_n_points_per_terminal
    n_steps_per_chunk = fft_n_points_per_terminal // fft_n_parallel
    n_steps_for_overlap = ftc_tile_overlap // fft_n_parallel

    n_packs_per_tile = ftc_tile_sz // ftc_pack_sz
%>\
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void mux_and_mult(global ${ftc_complex_pack_ty} * restrict tiles,
                         global ${ftc_complex_pack_ty} * restrict templates,
                         const uint n_tiles,
                         const uint n_engines_to_use,
                     % for e in range(fft_n_engines - 1):
                         const uint tmpl_offset_${e},
                     % endfor
                         const uint tmpl_offset_${fft_n_engines - 1})
{
    const ${ftc_complex_pack_ty} zeros = {${", ".join(["0"] * fft_n_parallel)}};

% for e in range(fft_n_engines):
    ${ftc_complex_pack_ty} template_buf_${e}[${n_packs_per_tile}];
% endfor

    for (uint pack = 0; pack < ${n_packs_per_tile}; ++pack) {
    % for e in range(fft_n_engines):
        ${ftc_complex_pack_ty} tmpl_${e} = ${e} < n_engines_to_use ? templates[tmpl_offset_${e} + pack] : zeros;
    % endfor
    % for e in range(fft_n_engines):
        template_buf_${e}[pack] = tmpl_${e};
    % endfor
    }

    for (uint pack = 0; pack < n_tiles * ${n_packs_per_tile}; ++pack) {
        ${ftc_complex_pack_ty} coeffs[${fft_n_engines}];
        ${ftc_complex_pack_ty} prods[${fft_n_engines}];

        ${ftc_complex_pack_ty} load = tiles[pack];
    % for e in range(fft_n_engines):
        coeffs[${e}] = template_buf_${e}[pack % ${n_packs_per_tile}];
    % endfor
    % for e in range(fft_n_engines):
        prods[${e}] = complex_mult(load, coeffs[${e}]);
    % endfor

        #pragma unroll
        for (uint e = 0; e < ${fft_n_engines}; ++e) {
            if (e < n_engines_to_use)
                write_channel_intel(ifft_in[e], prods[e]);
        }
    }
}
