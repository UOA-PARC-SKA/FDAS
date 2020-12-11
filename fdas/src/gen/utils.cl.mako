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

inline uint bit_reversed(uint x, uint bits)
{
    uint y = 0;
    #pragma unroll
    for (uint i = 0; i < bits; i++) {
        y <<= 1;
        y |= x & 1;
        x >>= 1;
    }
    return y;
}

inline ${ftc_complex_pack_ty} complex_mult(${ftc_complex_pack_ty} a, ${ftc_complex_pack_ty} b)
{
    ${ftc_complex_pack_ty} res;
%for z in range(ftc_pack_sz):
    res.i${z}.x = a.i${z}.x * b.i${z}.x - a.i${z}.y * b.i${z}.y;
    res.i${z}.y = a.i${z}.y * b.i${z}.x + a.i${z}.x * b.i${z}.y;
%endfor
    return res;
}

inline ${ftc_real_pack_ty} power_norm(${ftc_complex_pack_ty} a)
{
    ${ftc_real_pack_ty} res;
%for z in range(ftc_pack_sz):
    res.s${z} = (a.i${z}.x * a.i${z}.x + a.i${z}.y * a.i${z}.y) / ${fft_n_points ** 2};
%endfor
    return res;
}

inline uint encode_location(uint harm, int tmpl, uint freq) {
    return (((harm - 1) & 0x7) << 29) | (((tmpl + ${n_tmpl_per_accel_sign}) & 0x7f) << 22) | (freq & 0x3fffff);
}
