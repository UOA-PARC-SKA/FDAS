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
#include "fft_4p.cl"

#pragma OPENCL EXTENSION cl_intel_channels : enable

channel float2x4 load_to_tile __attribute__((depth(0)));

channel float2x4 fft_in __attribute__((depth(0)));
channel float2x4 fft_out __attribute__((depth(0)));

channel float2x4 ifft_in[3] __attribute__((depth(0)));
channel float2x4 ifft_out[3] __attribute__((depth(0)));

channel float8 preload_to_delay[8][2] __attribute__((depth(0)));
channel float8 delay_to_detect[8][2] __attribute__((depth(0)));

channel float8 detect_to_detect[7][2] __attribute__((depth(0)));
channel uint  detect_location_out[8][16] __attribute__((depth(0)));
channel float detect_power_out[8][16] __attribute__((depth(0)));

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

inline float2x4 complex_mult(float2x4 a, float2x4 b)
{
    float2x4 res;
    res.i0.x = a.i0.x * b.i0.x - a.i0.y * b.i0.y;
    res.i0.y = a.i0.y * b.i0.x + a.i0.x * b.i0.y;
    res.i1.x = a.i1.x * b.i1.x - a.i1.y * b.i1.y;
    res.i1.y = a.i1.y * b.i1.x + a.i1.x * b.i1.y;
    res.i2.x = a.i2.x * b.i2.x - a.i2.y * b.i2.y;
    res.i2.y = a.i2.y * b.i2.x + a.i2.x * b.i2.y;
    res.i3.x = a.i3.x * b.i3.x - a.i3.y * b.i3.y;
    res.i3.y = a.i3.y * b.i3.x + a.i3.x * b.i3.y;
    return res;
}

inline float4 power_norm(float2x4 a)
{
    float4 res;
    res.s0 = (a.i0.x * a.i0.x + a.i0.y * a.i0.y) / 4194304;
    res.s1 = (a.i1.x * a.i1.x + a.i1.y * a.i1.y) / 4194304;
    res.s2 = (a.i2.x * a.i2.x + a.i2.y * a.i2.y) / 4194304;
    res.s3 = (a.i3.x * a.i3.x + a.i3.y * a.i3.y) / 4194304;
    return res;
}

inline uint encode_location(uint harm, int tmpl, uint freq) {
    return (((harm - 1) & 0x7) << 29) | (((tmpl + 42) & 0x7f) << 22) | (freq & 0x3fffff);
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void fft_0(const uint n_tiles, const uint is_inverse)
{
    const float2x4 zeros = {0, 0, 0, 0};

    float2x4 __attribute__((bank_bits(9))) buf[2][512];
    float2 fft_delay_elements[2080];
    float2x4 data;

    for (uint tile = 0; tile < n_tiles + 2; ++tile) {
        for (uint step = 0; step < 512; ++step) {
            if (tile >= 1) {
                buf[1 - (tile & 1)][bit_reversed(step, 9)] = data;
            }
            if (tile >= 2) {
                if (! is_inverse)
                    write_channel_intel(fft_out, buf[tile & 1][step]);
                else
                    write_channel_intel(ifft_out[0], buf[tile & 1][step]);
            }

            if (tile < n_tiles) {
                if (! is_inverse)
                    data = read_channel_intel(fft_in);
                else
                    data = read_channel_intel(ifft_in[0]);
            } else {
                data = zeros;
            }

            data = fft_step(data, step, fft_delay_elements, is_inverse, 11);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void fft_1(const uint n_tiles)
{
    const float2x4 zeros = {0, 0, 0, 0};

    float2x4 __attribute__((bank_bits(9))) buf[2][512];
    float2 fft_delay_elements[2080];
    float2x4 data;

    for (uint tile = 0; tile < n_tiles + 2; ++tile) {
        for (uint step = 0; step < 512; ++step) {
            if (tile >= 1) {
                buf[1 - (tile & 1)][bit_reversed(step, 9)] = data;
            }
            if (tile >= 2) {
                write_channel_intel(ifft_out[1], buf[tile & 1][step]);
            }

            if (tile < n_tiles) {
                data = read_channel_intel(ifft_in[1]);
            } else {
                data = zeros;
            }

            data = fft_step(data, step, fft_delay_elements, 1, 11);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void fft_2(const uint n_tiles)
{
    const float2x4 zeros = {0, 0, 0, 0};

    float2x4 __attribute__((bank_bits(9))) buf[2][512];
    float2 fft_delay_elements[2080];
    float2x4 data;

    for (uint tile = 0; tile < n_tiles + 2; ++tile) {
        for (uint step = 0; step < 512; ++step) {
            if (tile >= 1) {
                buf[1 - (tile & 1)][bit_reversed(step, 9)] = data;
            }
            if (tile >= 2) {
                write_channel_intel(ifft_out[2], buf[tile & 1][step]);
            }

            if (tile < n_tiles) {
                data = read_channel_intel(ifft_in[2]);
            } else {
                data = zeros;
            }

            data = fft_step(data, step, fft_delay_elements, 1, 11);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void load_input(global float2x4 * restrict input,
                       const uint n_packs,
                       const uint n_packs_padding)
{
    const float2x4 zeros = {0, 0, 0, 0};

    for (uint pack = 0; pack < n_packs + n_packs_padding; ++pack) {
        float2x4 load = pack < n_packs ? input[pack] : zeros;
        write_channel_intel(load_to_tile, load);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void tile(const uint n_tiles)
{
    const float2x4 zeros = {0, 0, 0, 0};

    float2x4 overlap_sr[106];
    float2 __attribute__((bank_bits(9))) chunk_buf_0[2][512];
    float2 __attribute__((bank_bits(9))) chunk_buf_1[2][512];
    float2 __attribute__((bank_bits(9))) chunk_buf_2[2][512];
    float2 __attribute__((bank_bits(9))) chunk_buf_3[2][512];

    for (uint tile = 0; tile < n_tiles + 1; ++tile) {
        for (uint step = 0; step < 512; ++step) {
            if (tile >= 1) {
                float2x4 output;
                output.i[0] = chunk_buf_0[1 - (tile & 1)][step];
                output.i[2] = chunk_buf_1[1 - (tile & 1)][step];
                output.i[1] = chunk_buf_2[1 - (tile & 1)][step];
                output.i[3] = chunk_buf_3[1 - (tile & 1)][step];
                write_channel_intel(fft_in, output);
            }

            float2x4 input = zeros;
            if (tile < n_tiles) {
                if (step < 105) {
                    if (tile >= 1)
                        input = overlap_sr[0];
                }
                else {
                    input = read_channel_intel(load_to_tile);
                }

                uint chunk = step / 128;
                uint pack = step % 128;

                switch (chunk) {
                    case 0:
                        #pragma unroll
                        for (uint p = 0; p < 4; ++p)
                            chunk_buf_0[tile & 1][pack * 4 + p] = input.i[p];
                        break;
                    case 1:
                        #pragma unroll
                        for (uint p = 0; p < 4; ++p)
                            chunk_buf_1[tile & 1][pack * 4 + p] = input.i[p];
                        break;
                    case 2:
                        #pragma unroll
                        for (uint p = 0; p < 4; ++p)
                            chunk_buf_2[tile & 1][pack * 4 + p] = input.i[p];
                        break;
                    case 3:
                        #pragma unroll
                        for (uint p = 0; p < 4; ++p)
                            chunk_buf_3[tile & 1][pack * 4 + p] = input.i[p];
                        break;
                    default:
                        break;
                }
            }

            overlap_sr[105] = input;

            #pragma unroll
            for (uint x = 0; x < 105; ++x)
                overlap_sr[x] = overlap_sr[x + 1];
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void store_tiles(global float2x4 * restrict tiles,
                        const uint n_tiles)
{
    for (uint tile = 0; tile < n_tiles; ++tile) {
        for (uint step = 0; step < 512; ++step) {
            float2x4 read = read_channel_intel(fft_out);
            tiles[tile * 512 + step] = read;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void mux_and_mult(global float2x4 * restrict tiles,
                         global float2x4 * restrict templates,
                         const uint n_tiles,
                         const uint n_engines_to_use,
                         const uint tmpl_offset_0,
                         const uint tmpl_offset_1,
                         const uint tmpl_offset_2)
{
    const float2x4 zeros = {0, 0, 0, 0};

    float2x4 template_buf_0[512];
    float2x4 template_buf_1[512];
    float2x4 template_buf_2[512];

    for (uint pack = 0; pack < 512; ++pack) {
        float2x4 tmpl_0 = 0 < n_engines_to_use ? templates[tmpl_offset_0 + pack] : zeros;
        float2x4 tmpl_1 = 1 < n_engines_to_use ? templates[tmpl_offset_1 + pack] : zeros;
        float2x4 tmpl_2 = 2 < n_engines_to_use ? templates[tmpl_offset_2 + pack] : zeros;
        template_buf_0[pack] = tmpl_0;
        template_buf_1[pack] = tmpl_1;
        template_buf_2[pack] = tmpl_2;
    }

    for (uint pack = 0; pack < n_tiles * 512; ++pack) {
        float2x4 coeffs[3];
        float2x4 prods[3];

        float2x4 load = tiles[pack];
        coeffs[0] = template_buf_0[pack % 512];
        coeffs[1] = template_buf_1[pack % 512];
        coeffs[2] = template_buf_2[pack % 512];
        prods[0] = complex_mult(load, coeffs[0]);
        prods[1] = complex_mult(load, coeffs[1]);
        prods[2] = complex_mult(load, coeffs[2]);

        #pragma unroll
        for (uint e = 0; e < 3; ++e) {
            if (e < n_engines_to_use)
                write_channel_intel(ifft_in[e], prods[e]);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void square_and_discard_0(global float4 * restrict fop,
                                 const uint n_tiles,
                                 const uint n_packs,
                                 const uint fop_offset)
{
    const float4 zeros = {0, 0, 0, 0};

    float __attribute__((bank_bits(9))) chunk_buf_0[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_1[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_2[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_3[2][512];

    uint fop_pack = 0;
    for (uint tile = 0; tile < n_tiles + 1; ++tile) {
        for (uint step = 0; step < 512; ++step) {
            if (tile >= 1 && step >= 105) {
                uint chunk = step / 128;
                uint pack = step % 128;

                float4 store = zeros;
                switch (chunk) {
                    case 0:
                        store.s0 = chunk_buf_0[1 - (tile & 1)][pack * 4 + 0];
                        store.s1 = chunk_buf_0[1 - (tile & 1)][pack * 4 + 1];
                        store.s2 = chunk_buf_0[1 - (tile & 1)][pack * 4 + 2];
                        store.s3 = chunk_buf_0[1 - (tile & 1)][pack * 4 + 3];
                        break;
                    case 1:
                        store.s0 = chunk_buf_1[1 - (tile & 1)][pack * 4 + 0];
                        store.s1 = chunk_buf_1[1 - (tile & 1)][pack * 4 + 1];
                        store.s2 = chunk_buf_1[1 - (tile & 1)][pack * 4 + 2];
                        store.s3 = chunk_buf_1[1 - (tile & 1)][pack * 4 + 3];
                        break;
                    case 2:
                        store.s0 = chunk_buf_2[1 - (tile & 1)][pack * 4 + 0];
                        store.s1 = chunk_buf_2[1 - (tile & 1)][pack * 4 + 1];
                        store.s2 = chunk_buf_2[1 - (tile & 1)][pack * 4 + 2];
                        store.s3 = chunk_buf_2[1 - (tile & 1)][pack * 4 + 3];
                        break;
                    case 3:
                        store.s0 = chunk_buf_3[1 - (tile & 1)][pack * 4 + 0];
                        store.s1 = chunk_buf_3[1 - (tile & 1)][pack * 4 + 1];
                        store.s2 = chunk_buf_3[1 - (tile & 1)][pack * 4 + 2];
                        store.s3 = chunk_buf_3[1 - (tile & 1)][pack * 4 + 3];
                        break;
                    default:
                        break;
                }

                // Quick hack: Just run idle at the end of the last tile, to discard the zero padding there.
                //   This may actually be a good solution (tm), because complicating the control flow would likely
                //   introduce fmax bottlnecks -- need to test this!
                if (fop_pack < n_packs)
                    fop[fop_offset + fop_pack] = store;
                ++fop_pack;
            }

            if (tile < n_tiles) {
                float2x4 read = read_channel_intel(ifft_out[0]);
                float4 norm = power_norm(read);
                chunk_buf_0[tile & 1][step] = norm.s0;
                chunk_buf_1[tile & 1][step] = norm.s2;
                chunk_buf_2[tile & 1][step] = norm.s1;
                chunk_buf_3[tile & 1][step] = norm.s3;
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void square_and_discard_1(global float4 * restrict fop,
                                 const uint n_tiles,
                                 const uint n_packs,
                                 const uint fop_offset)
{
    const float4 zeros = {0, 0, 0, 0};

    float __attribute__((bank_bits(9))) chunk_buf_0[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_1[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_2[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_3[2][512];

    uint fop_pack = 0;
    for (uint tile = 0; tile < n_tiles + 1; ++tile) {
        for (uint step = 0; step < 512; ++step) {
            if (tile >= 1 && step >= 105) {
                uint chunk = step / 128;
                uint pack = step % 128;

                float4 store = zeros;
                switch (chunk) {
                    case 0:
                        store.s0 = chunk_buf_0[1 - (tile & 1)][pack * 4 + 0];
                        store.s1 = chunk_buf_0[1 - (tile & 1)][pack * 4 + 1];
                        store.s2 = chunk_buf_0[1 - (tile & 1)][pack * 4 + 2];
                        store.s3 = chunk_buf_0[1 - (tile & 1)][pack * 4 + 3];
                        break;
                    case 1:
                        store.s0 = chunk_buf_1[1 - (tile & 1)][pack * 4 + 0];
                        store.s1 = chunk_buf_1[1 - (tile & 1)][pack * 4 + 1];
                        store.s2 = chunk_buf_1[1 - (tile & 1)][pack * 4 + 2];
                        store.s3 = chunk_buf_1[1 - (tile & 1)][pack * 4 + 3];
                        break;
                    case 2:
                        store.s0 = chunk_buf_2[1 - (tile & 1)][pack * 4 + 0];
                        store.s1 = chunk_buf_2[1 - (tile & 1)][pack * 4 + 1];
                        store.s2 = chunk_buf_2[1 - (tile & 1)][pack * 4 + 2];
                        store.s3 = chunk_buf_2[1 - (tile & 1)][pack * 4 + 3];
                        break;
                    case 3:
                        store.s0 = chunk_buf_3[1 - (tile & 1)][pack * 4 + 0];
                        store.s1 = chunk_buf_3[1 - (tile & 1)][pack * 4 + 1];
                        store.s2 = chunk_buf_3[1 - (tile & 1)][pack * 4 + 2];
                        store.s3 = chunk_buf_3[1 - (tile & 1)][pack * 4 + 3];
                        break;
                    default:
                        break;
                }

                // Quick hack: Just run idle at the end of the last tile, to discard the zero padding there.
                //   This may actually be a good solution (tm), because complicating the control flow would likely
                //   introduce fmax bottlnecks -- need to test this!
                if (fop_pack < n_packs)
                    fop[fop_offset + fop_pack] = store;
                ++fop_pack;
            }

            if (tile < n_tiles) {
                float2x4 read = read_channel_intel(ifft_out[1]);
                float4 norm = power_norm(read);
                chunk_buf_0[tile & 1][step] = norm.s0;
                chunk_buf_1[tile & 1][step] = norm.s2;
                chunk_buf_2[tile & 1][step] = norm.s1;
                chunk_buf_3[tile & 1][step] = norm.s3;
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void square_and_discard_2(global float4 * restrict fop,
                                 const uint n_tiles,
                                 const uint n_packs,
                                 const uint fop_offset)
{
    const float4 zeros = {0, 0, 0, 0};

    float __attribute__((bank_bits(9))) chunk_buf_0[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_1[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_2[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_3[2][512];

    uint fop_pack = 0;
    for (uint tile = 0; tile < n_tiles + 1; ++tile) {
        for (uint step = 0; step < 512; ++step) {
            if (tile >= 1 && step >= 105) {
                uint chunk = step / 128;
                uint pack = step % 128;

                float4 store = zeros;
                switch (chunk) {
                    case 0:
                        store.s0 = chunk_buf_0[1 - (tile & 1)][pack * 4 + 0];
                        store.s1 = chunk_buf_0[1 - (tile & 1)][pack * 4 + 1];
                        store.s2 = chunk_buf_0[1 - (tile & 1)][pack * 4 + 2];
                        store.s3 = chunk_buf_0[1 - (tile & 1)][pack * 4 + 3];
                        break;
                    case 1:
                        store.s0 = chunk_buf_1[1 - (tile & 1)][pack * 4 + 0];
                        store.s1 = chunk_buf_1[1 - (tile & 1)][pack * 4 + 1];
                        store.s2 = chunk_buf_1[1 - (tile & 1)][pack * 4 + 2];
                        store.s3 = chunk_buf_1[1 - (tile & 1)][pack * 4 + 3];
                        break;
                    case 2:
                        store.s0 = chunk_buf_2[1 - (tile & 1)][pack * 4 + 0];
                        store.s1 = chunk_buf_2[1 - (tile & 1)][pack * 4 + 1];
                        store.s2 = chunk_buf_2[1 - (tile & 1)][pack * 4 + 2];
                        store.s3 = chunk_buf_2[1 - (tile & 1)][pack * 4 + 3];
                        break;
                    case 3:
                        store.s0 = chunk_buf_3[1 - (tile & 1)][pack * 4 + 0];
                        store.s1 = chunk_buf_3[1 - (tile & 1)][pack * 4 + 1];
                        store.s2 = chunk_buf_3[1 - (tile & 1)][pack * 4 + 2];
                        store.s3 = chunk_buf_3[1 - (tile & 1)][pack * 4 + 3];
                        break;
                    default:
                        break;
                }

                // Quick hack: Just run idle at the end of the last tile, to discard the zero padding there.
                //   This may actually be a good solution (tm), because complicating the control flow would likely
                //   introduce fmax bottlnecks -- need to test this!
                if (fop_pack < n_packs)
                    fop[fop_offset + fop_pack] = store;
                ++fop_pack;
            }

            if (tile < n_tiles) {
                float2x4 read = read_channel_intel(ifft_out[2]);
                float4 norm = power_norm(read);
                chunk_buf_0[tile & 1][step] = norm.s0;
                chunk_buf_1[tile & 1][step] = norm.s2;
                chunk_buf_2[tile & 1][step] = norm.s1;
                chunk_buf_3[tile & 1][step] = norm.s3;
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_1(global float8 * restrict fop,
                      const uint n_bundles,
                      const uint n_buffers_to_use,
                      const uint cc_of_group_base,
                      const uint fop_offset_0,
                      const uint fop_offset_1
                      )
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 load[2];
    float8 out[2];

    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        load[0] = 0 < n_buffers_to_use ? fop[fop_offset_0 + bundle] : zeros;
        load[1] = 1 < n_buffers_to_use ? fop[fop_offset_1 + bundle] : zeros;

        out[0] = load[0];
        out[1] = load[1];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(preload_to_delay[0][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_1(const uint n_bundles)
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        uint m = M;
        M = M < 0 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = read_channel_intel(preload_to_delay[0][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s1;
                    out[p].s2 = in[p].s2;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s5;
                    out[p].s6 = in[p].s6;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(delay_to_detect[0][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_2(global float8 * restrict fop,
                      const uint n_bundles,
                      const uint n_buffers_to_use,
                      const uint cc_of_group_base,
                      const uint fop_offset_0
                      )
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 load[1];
    float8 out[2];

    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        load[0] = 0 < n_buffers_to_use ? fop[fop_offset_0 + bundle] : zeros;

        out[0] = load[0];
        out[1] = load[0];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(preload_to_delay[1][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_2(const uint n_bundles)
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        uint m = M;
        M = M < 1 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = read_channel_intel(preload_to_delay[1][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s1;
                    out[p].s3 = in[p].s1;
                    out[p].s4 = in[p].s2;
                    out[p].s5 = in[p].s2;
                    out[p].s6 = in[p].s3;
                    out[p].s7 = in[p].s3;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s4;
                    out[p].s2 = in[p].s5;
                    out[p].s3 = in[p].s5;
                    out[p].s4 = in[p].s6;
                    out[p].s5 = in[p].s6;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(delay_to_detect[1][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_3(global float8 * restrict fop,
                      const uint n_bundles,
                      const uint n_buffers_to_use,
                      const uint cc_of_group_base,
                      const uint fop_offset_0,
                      const uint fop_offset_1
                      )
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 load[2];
    float8 out[2];

    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        load[0] = 0 < n_buffers_to_use ? fop[fop_offset_0 + bundle] : zeros;
        load[1] = 1 < n_buffers_to_use ? fop[fop_offset_1 + bundle] : zeros;

        out[0] = load[0];
        out[1] = cc_of_group_base < 2 ? load[0] : load[1];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(preload_to_delay[2][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_3(const uint n_bundles)
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        uint m = M;
        M = M < 2 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = read_channel_intel(preload_to_delay[2][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s1;
                    out[p].s4 = in[p].s1;
                    out[p].s5 = in[p].s1;
                    out[p].s6 = in[p].s2;
                    out[p].s7 = in[p].s2;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s2;
                    out[p].s1 = in[p].s3;
                    out[p].s2 = in[p].s3;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s4;
                    out[p].s6 = in[p].s4;
                    out[p].s7 = in[p].s5;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s5;
                    out[p].s1 = in[p].s5;
                    out[p].s2 = in[p].s6;
                    out[p].s3 = in[p].s6;
                    out[p].s4 = in[p].s6;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(delay_to_detect[2][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_4(global float8 * restrict fop,
                      const uint n_bundles,
                      const uint n_buffers_to_use,
                      const uint cc_of_group_base,
                      const uint fop_offset_0
                      )
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 load[1];
    float8 out[2];

    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        load[0] = 0 < n_buffers_to_use ? fop[fop_offset_0 + bundle] : zeros;

        out[0] = load[0];
        out[1] = load[0];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(preload_to_delay[3][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_4(const uint n_bundles)
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        uint m = M;
        M = M < 3 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = read_channel_intel(preload_to_delay[3][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s1;
                    out[p].s5 = in[p].s1;
                    out[p].s6 = in[p].s1;
                    out[p].s7 = in[p].s1;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s2;
                    out[p].s1 = in[p].s2;
                    out[p].s2 = in[p].s2;
                    out[p].s3 = in[p].s2;
                    out[p].s4 = in[p].s3;
                    out[p].s5 = in[p].s3;
                    out[p].s6 = in[p].s3;
                    out[p].s7 = in[p].s3;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s4;
                    out[p].s2 = in[p].s4;
                    out[p].s3 = in[p].s4;
                    out[p].s4 = in[p].s5;
                    out[p].s5 = in[p].s5;
                    out[p].s6 = in[p].s5;
                    out[p].s7 = in[p].s5;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s6;
                    out[p].s1 = in[p].s6;
                    out[p].s2 = in[p].s6;
                    out[p].s3 = in[p].s6;
                    out[p].s4 = in[p].s7;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(delay_to_detect[3][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_5(global float8 * restrict fop,
                      const uint n_bundles,
                      const uint n_buffers_to_use,
                      const uint cc_of_group_base,
                      const uint fop_offset_0,
                      const uint fop_offset_1
                      )
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 load[2];
    float8 out[2];

    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        load[0] = 0 < n_buffers_to_use ? fop[fop_offset_0 + bundle] : zeros;
        load[1] = 1 < n_buffers_to_use ? fop[fop_offset_1 + bundle] : zeros;

        out[0] = load[0];
        out[1] = cc_of_group_base < 4 ? load[0] : load[1];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(preload_to_delay[4][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_5(const uint n_bundles)
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        uint m = M;
        M = M < 4 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = read_channel_intel(preload_to_delay[4][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s0;
                    out[p].s5 = in[p].s1;
                    out[p].s6 = in[p].s1;
                    out[p].s7 = in[p].s1;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s1;
                    out[p].s1 = in[p].s1;
                    out[p].s2 = in[p].s2;
                    out[p].s3 = in[p].s2;
                    out[p].s4 = in[p].s2;
                    out[p].s5 = in[p].s2;
                    out[p].s6 = in[p].s2;
                    out[p].s7 = in[p].s3;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s3;
                    out[p].s1 = in[p].s3;
                    out[p].s2 = in[p].s3;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s4;
                    out[p].s6 = in[p].s4;
                    out[p].s7 = in[p].s4;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s5;
                    out[p].s2 = in[p].s5;
                    out[p].s3 = in[p].s5;
                    out[p].s4 = in[p].s5;
                    out[p].s5 = in[p].s5;
                    out[p].s6 = in[p].s6;
                    out[p].s7 = in[p].s6;
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s6;
                    out[p].s1 = in[p].s6;
                    out[p].s2 = in[p].s6;
                    out[p].s3 = in[p].s7;
                    out[p].s4 = in[p].s7;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(delay_to_detect[4][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_6(global float8 * restrict fop,
                      const uint n_bundles,
                      const uint n_buffers_to_use,
                      const uint cc_of_group_base,
                      const uint fop_offset_0
                      )
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 load[1];
    float8 out[2];

    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        load[0] = 0 < n_buffers_to_use ? fop[fop_offset_0 + bundle] : zeros;

        out[0] = load[0];
        out[1] = load[0];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(preload_to_delay[5][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_6(const uint n_bundles)
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        uint m = M;
        M = M < 5 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = read_channel_intel(preload_to_delay[5][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s0;
                    out[p].s5 = in[p].s0;
                    out[p].s6 = in[p].s1;
                    out[p].s7 = in[p].s1;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s1;
                    out[p].s1 = in[p].s1;
                    out[p].s2 = in[p].s1;
                    out[p].s3 = in[p].s1;
                    out[p].s4 = in[p].s2;
                    out[p].s5 = in[p].s2;
                    out[p].s6 = in[p].s2;
                    out[p].s7 = in[p].s2;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s2;
                    out[p].s1 = in[p].s2;
                    out[p].s2 = in[p].s3;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s3;
                    out[p].s5 = in[p].s3;
                    out[p].s6 = in[p].s3;
                    out[p].s7 = in[p].s3;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s4;
                    out[p].s2 = in[p].s4;
                    out[p].s3 = in[p].s4;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s4;
                    out[p].s6 = in[p].s5;
                    out[p].s7 = in[p].s5;
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s5;
                    out[p].s1 = in[p].s5;
                    out[p].s2 = in[p].s5;
                    out[p].s3 = in[p].s5;
                    out[p].s4 = in[p].s6;
                    out[p].s5 = in[p].s6;
                    out[p].s6 = in[p].s6;
                    out[p].s7 = in[p].s6;
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s6;
                    out[p].s1 = in[p].s6;
                    out[p].s2 = in[p].s7;
                    out[p].s3 = in[p].s7;
                    out[p].s4 = in[p].s7;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(delay_to_detect[5][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_7(global float8 * restrict fop,
                      const uint n_bundles,
                      const uint n_buffers_to_use,
                      const uint cc_of_group_base,
                      const uint fop_offset_0,
                      const uint fop_offset_1
                      )
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 load[2];
    float8 out[2];

    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        load[0] = 0 < n_buffers_to_use ? fop[fop_offset_0 + bundle] : zeros;
        load[1] = 1 < n_buffers_to_use ? fop[fop_offset_1 + bundle] : zeros;

        out[0] = load[0];
        out[1] = cc_of_group_base < 6 ? load[0] : load[1];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(preload_to_delay[6][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_7(const uint n_bundles)
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        uint m = M;
        M = M < 6 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = read_channel_intel(preload_to_delay[6][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s0;
                    out[p].s5 = in[p].s0;
                    out[p].s6 = in[p].s0;
                    out[p].s7 = in[p].s1;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s1;
                    out[p].s1 = in[p].s1;
                    out[p].s2 = in[p].s1;
                    out[p].s3 = in[p].s1;
                    out[p].s4 = in[p].s1;
                    out[p].s5 = in[p].s1;
                    out[p].s6 = in[p].s2;
                    out[p].s7 = in[p].s2;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s2;
                    out[p].s1 = in[p].s2;
                    out[p].s2 = in[p].s2;
                    out[p].s3 = in[p].s2;
                    out[p].s4 = in[p].s2;
                    out[p].s5 = in[p].s3;
                    out[p].s6 = in[p].s3;
                    out[p].s7 = in[p].s3;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s3;
                    out[p].s1 = in[p].s3;
                    out[p].s2 = in[p].s3;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s4;
                    out[p].s6 = in[p].s4;
                    out[p].s7 = in[p].s4;
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s4;
                    out[p].s2 = in[p].s4;
                    out[p].s3 = in[p].s5;
                    out[p].s4 = in[p].s5;
                    out[p].s5 = in[p].s5;
                    out[p].s6 = in[p].s5;
                    out[p].s7 = in[p].s5;
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s5;
                    out[p].s1 = in[p].s5;
                    out[p].s2 = in[p].s6;
                    out[p].s3 = in[p].s6;
                    out[p].s4 = in[p].s6;
                    out[p].s5 = in[p].s6;
                    out[p].s6 = in[p].s6;
                    out[p].s7 = in[p].s6;
                }
                break;
            case 6:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s6;
                    out[p].s1 = in[p].s7;
                    out[p].s2 = in[p].s7;
                    out[p].s3 = in[p].s7;
                    out[p].s4 = in[p].s7;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(delay_to_detect[6][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_8(global float8 * restrict fop,
                      const uint n_bundles,
                      const uint n_buffers_to_use,
                      const uint cc_of_group_base,
                      const uint fop_offset_0
                      )
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 load[1];
    float8 out[2];

    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        load[0] = 0 < n_buffers_to_use ? fop[fop_offset_0 + bundle] : zeros;

        out[0] = load[0];
        out[1] = load[0];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(preload_to_delay[7][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_8(const uint n_bundles)
{
    const float8 zeros = {0, 0, 0, 0, 0, 0, 0, 0};
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_bundles; ++bundle) {
        uint m = M;
        M = M < 7 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = read_channel_intel(preload_to_delay[7][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s0;
                    out[p].s5 = in[p].s0;
                    out[p].s6 = in[p].s0;
                    out[p].s7 = in[p].s0;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s1;
                    out[p].s1 = in[p].s1;
                    out[p].s2 = in[p].s1;
                    out[p].s3 = in[p].s1;
                    out[p].s4 = in[p].s1;
                    out[p].s5 = in[p].s1;
                    out[p].s6 = in[p].s1;
                    out[p].s7 = in[p].s1;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s2;
                    out[p].s1 = in[p].s2;
                    out[p].s2 = in[p].s2;
                    out[p].s3 = in[p].s2;
                    out[p].s4 = in[p].s2;
                    out[p].s5 = in[p].s2;
                    out[p].s6 = in[p].s2;
                    out[p].s7 = in[p].s2;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s3;
                    out[p].s1 = in[p].s3;
                    out[p].s2 = in[p].s3;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s3;
                    out[p].s5 = in[p].s3;
                    out[p].s6 = in[p].s3;
                    out[p].s7 = in[p].s3;
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s4;
                    out[p].s2 = in[p].s4;
                    out[p].s3 = in[p].s4;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s4;
                    out[p].s6 = in[p].s4;
                    out[p].s7 = in[p].s4;
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s5;
                    out[p].s1 = in[p].s5;
                    out[p].s2 = in[p].s5;
                    out[p].s3 = in[p].s5;
                    out[p].s4 = in[p].s5;
                    out[p].s5 = in[p].s5;
                    out[p].s6 = in[p].s5;
                    out[p].s7 = in[p].s5;
                }
                break;
            case 6:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s6;
                    out[p].s1 = in[p].s6;
                    out[p].s2 = in[p].s6;
                    out[p].s3 = in[p].s6;
                    out[p].s4 = in[p].s6;
                    out[p].s5 = in[p].s6;
                    out[p].s6 = in[p].s6;
                    out[p].s7 = in[p].s6;
                }
                break;
            case 7:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s7;
                    out[p].s1 = in[p].s7;
                    out[p].s2 = in[p].s7;
                    out[p].s3 = in[p].s7;
                    out[p].s4 = in[p].s7;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            write_channel_intel(delay_to_detect[7][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_1(float threshold,
                     uint n_templates,
                     uint negative_tmpls,
                     uint n_groups,
                     uint n_bundles)
{
    uint location_buffer[64][16];
    float power_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_power = -1.0f;

    for (uint group = 0; group < n_groups; ++group) {
        uint group_base = group * 2;
        int tmpl[2];
        bool tmpl_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            tmpl[p] = negative_tmpls ? - group_base - p : group_base + p;
            tmpl_mask[p] = group_base + p < n_templates;
        }

        for (uint bundle = 0; bundle < n_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint freq[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                freq[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_fop = read_channel_intel(delay_to_detect[0][p]);
                hsum[p] = from_fop;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                write_channel_intel(detect_to_detect[0][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & tmpl_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & tmpl_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & tmpl_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & tmpl_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & tmpl_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & tmpl_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & tmpl_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & tmpl_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & tmpl_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & tmpl_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & tmpl_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & tmpl_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & tmpl_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & tmpl_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & tmpl_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & tmpl_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float pwr[16];

                loc[0] = cand[0] ? encode_location(1, tmpl[0], freq[0]) : invalid_location;
                pwr[0] = cand[0] ? hsum[0].s0 : invalid_power;
                loc[1] = cand[1] ? encode_location(1, tmpl[0], freq[1]) : invalid_location;
                pwr[1] = cand[1] ? hsum[0].s1 : invalid_power;
                loc[2] = cand[2] ? encode_location(1, tmpl[0], freq[2]) : invalid_location;
                pwr[2] = cand[2] ? hsum[0].s2 : invalid_power;
                loc[3] = cand[3] ? encode_location(1, tmpl[0], freq[3]) : invalid_location;
                pwr[3] = cand[3] ? hsum[0].s3 : invalid_power;
                loc[4] = cand[4] ? encode_location(1, tmpl[0], freq[4]) : invalid_location;
                pwr[4] = cand[4] ? hsum[0].s4 : invalid_power;
                loc[5] = cand[5] ? encode_location(1, tmpl[0], freq[5]) : invalid_location;
                pwr[5] = cand[5] ? hsum[0].s5 : invalid_power;
                loc[6] = cand[6] ? encode_location(1, tmpl[0], freq[6]) : invalid_location;
                pwr[6] = cand[6] ? hsum[0].s6 : invalid_power;
                loc[7] = cand[7] ? encode_location(1, tmpl[0], freq[7]) : invalid_location;
                pwr[7] = cand[7] ? hsum[0].s7 : invalid_power;
                loc[8] = cand[8] ? encode_location(1, tmpl[1], freq[0]) : invalid_location;
                pwr[8] = cand[8] ? hsum[1].s0 : invalid_power;
                loc[9] = cand[9] ? encode_location(1, tmpl[1], freq[1]) : invalid_location;
                pwr[9] = cand[9] ? hsum[1].s1 : invalid_power;
                loc[10] = cand[10] ? encode_location(1, tmpl[1], freq[2]) : invalid_location;
                pwr[10] = cand[10] ? hsum[1].s2 : invalid_power;
                loc[11] = cand[11] ? encode_location(1, tmpl[1], freq[3]) : invalid_location;
                pwr[11] = cand[11] ? hsum[1].s3 : invalid_power;
                loc[12] = cand[12] ? encode_location(1, tmpl[1], freq[4]) : invalid_location;
                pwr[12] = cand[12] ? hsum[1].s4 : invalid_power;
                loc[13] = cand[13] ? encode_location(1, tmpl[1], freq[5]) : invalid_location;
                pwr[13] = cand[13] ? hsum[1].s5 : invalid_power;
                loc[14] = cand[14] ? encode_location(1, tmpl[1], freq[6]) : invalid_location;
                pwr[14] = cand[14] ? hsum[1].s6 : invalid_power;
                loc[15] = cand[15] ? encode_location(1, tmpl[1], freq[7]) : invalid_location;
                pwr[15] = cand[15] ? hsum[1].s7 : invalid_power;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    power_buffer[slot][x] = pwr[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint h = 0; h < 1; ++h) {
        for (uint d = 0; d < 64; ++d) {
            bool is_valid = (valid & (1l << d)) > 0;
            #pragma unroll
            for (uint x = 0; x < 16; ++x) {
                uint location = is_valid ? location_buffer[d][x] : invalid_location;
                float power = is_valid ? power_buffer[d][x] : invalid_power;
                write_channel_intel(detect_location_out[0][x], location);
                write_channel_intel(detect_power_out[0][x], power);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_2(float threshold,
                     uint n_templates,
                     uint negative_tmpls,
                     uint n_groups,
                     uint n_bundles)
{
    uint location_buffer[64][16];
    float power_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_power = -1.0f;

    for (uint group = 0; group < n_groups; ++group) {
        uint group_base = group * 2;
        int tmpl[2];
        bool tmpl_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            tmpl[p] = negative_tmpls ? - group_base - p : group_base + p;
            tmpl_mask[p] = group_base + p < n_templates;
        }

        for (uint bundle = 0; bundle < n_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint freq[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                freq[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = read_channel_intel(detect_to_detect[0][p]);
                float8 from_sp = read_channel_intel(delay_to_detect[1][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                write_channel_intel(detect_to_detect[1][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & tmpl_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & tmpl_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & tmpl_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & tmpl_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & tmpl_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & tmpl_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & tmpl_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & tmpl_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & tmpl_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & tmpl_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & tmpl_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & tmpl_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & tmpl_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & tmpl_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & tmpl_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & tmpl_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float pwr[16];

                loc[0] = cand[0] ? encode_location(2, tmpl[0], freq[0]) : invalid_location;
                pwr[0] = cand[0] ? hsum[0].s0 : invalid_power;
                loc[1] = cand[1] ? encode_location(2, tmpl[0], freq[1]) : invalid_location;
                pwr[1] = cand[1] ? hsum[0].s1 : invalid_power;
                loc[2] = cand[2] ? encode_location(2, tmpl[0], freq[2]) : invalid_location;
                pwr[2] = cand[2] ? hsum[0].s2 : invalid_power;
                loc[3] = cand[3] ? encode_location(2, tmpl[0], freq[3]) : invalid_location;
                pwr[3] = cand[3] ? hsum[0].s3 : invalid_power;
                loc[4] = cand[4] ? encode_location(2, tmpl[0], freq[4]) : invalid_location;
                pwr[4] = cand[4] ? hsum[0].s4 : invalid_power;
                loc[5] = cand[5] ? encode_location(2, tmpl[0], freq[5]) : invalid_location;
                pwr[5] = cand[5] ? hsum[0].s5 : invalid_power;
                loc[6] = cand[6] ? encode_location(2, tmpl[0], freq[6]) : invalid_location;
                pwr[6] = cand[6] ? hsum[0].s6 : invalid_power;
                loc[7] = cand[7] ? encode_location(2, tmpl[0], freq[7]) : invalid_location;
                pwr[7] = cand[7] ? hsum[0].s7 : invalid_power;
                loc[8] = cand[8] ? encode_location(2, tmpl[1], freq[0]) : invalid_location;
                pwr[8] = cand[8] ? hsum[1].s0 : invalid_power;
                loc[9] = cand[9] ? encode_location(2, tmpl[1], freq[1]) : invalid_location;
                pwr[9] = cand[9] ? hsum[1].s1 : invalid_power;
                loc[10] = cand[10] ? encode_location(2, tmpl[1], freq[2]) : invalid_location;
                pwr[10] = cand[10] ? hsum[1].s2 : invalid_power;
                loc[11] = cand[11] ? encode_location(2, tmpl[1], freq[3]) : invalid_location;
                pwr[11] = cand[11] ? hsum[1].s3 : invalid_power;
                loc[12] = cand[12] ? encode_location(2, tmpl[1], freq[4]) : invalid_location;
                pwr[12] = cand[12] ? hsum[1].s4 : invalid_power;
                loc[13] = cand[13] ? encode_location(2, tmpl[1], freq[5]) : invalid_location;
                pwr[13] = cand[13] ? hsum[1].s5 : invalid_power;
                loc[14] = cand[14] ? encode_location(2, tmpl[1], freq[6]) : invalid_location;
                pwr[14] = cand[14] ? hsum[1].s6 : invalid_power;
                loc[15] = cand[15] ? encode_location(2, tmpl[1], freq[7]) : invalid_location;
                pwr[15] = cand[15] ? hsum[1].s7 : invalid_power;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    power_buffer[slot][x] = pwr[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint h = 0; h < 2; ++h) {
        for (uint d = 0; d < 64; ++d) {
            bool is_valid = (valid & (1l << d)) > 0;
            #pragma unroll
            for (uint x = 0; x < 16; ++x) {
                uint location = invalid_location;
                float power = invalid_power;
                if (h < 1) {
                    location = read_channel_intel(detect_location_out[0][x]);
                    power = read_channel_intel(detect_power_out[0][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    power = power_buffer[d][x];
                }
                write_channel_intel(detect_location_out[1][x], location);
                write_channel_intel(detect_power_out[1][x], power);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_3(float threshold,
                     uint n_templates,
                     uint negative_tmpls,
                     uint n_groups,
                     uint n_bundles)
{
    uint location_buffer[64][16];
    float power_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_power = -1.0f;

    for (uint group = 0; group < n_groups; ++group) {
        uint group_base = group * 2;
        int tmpl[2];
        bool tmpl_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            tmpl[p] = negative_tmpls ? - group_base - p : group_base + p;
            tmpl_mask[p] = group_base + p < n_templates;
        }

        for (uint bundle = 0; bundle < n_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint freq[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                freq[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = read_channel_intel(detect_to_detect[1][p]);
                float8 from_sp = read_channel_intel(delay_to_detect[2][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                write_channel_intel(detect_to_detect[2][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & tmpl_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & tmpl_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & tmpl_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & tmpl_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & tmpl_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & tmpl_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & tmpl_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & tmpl_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & tmpl_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & tmpl_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & tmpl_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & tmpl_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & tmpl_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & tmpl_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & tmpl_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & tmpl_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float pwr[16];

                loc[0] = cand[0] ? encode_location(3, tmpl[0], freq[0]) : invalid_location;
                pwr[0] = cand[0] ? hsum[0].s0 : invalid_power;
                loc[1] = cand[1] ? encode_location(3, tmpl[0], freq[1]) : invalid_location;
                pwr[1] = cand[1] ? hsum[0].s1 : invalid_power;
                loc[2] = cand[2] ? encode_location(3, tmpl[0], freq[2]) : invalid_location;
                pwr[2] = cand[2] ? hsum[0].s2 : invalid_power;
                loc[3] = cand[3] ? encode_location(3, tmpl[0], freq[3]) : invalid_location;
                pwr[3] = cand[3] ? hsum[0].s3 : invalid_power;
                loc[4] = cand[4] ? encode_location(3, tmpl[0], freq[4]) : invalid_location;
                pwr[4] = cand[4] ? hsum[0].s4 : invalid_power;
                loc[5] = cand[5] ? encode_location(3, tmpl[0], freq[5]) : invalid_location;
                pwr[5] = cand[5] ? hsum[0].s5 : invalid_power;
                loc[6] = cand[6] ? encode_location(3, tmpl[0], freq[6]) : invalid_location;
                pwr[6] = cand[6] ? hsum[0].s6 : invalid_power;
                loc[7] = cand[7] ? encode_location(3, tmpl[0], freq[7]) : invalid_location;
                pwr[7] = cand[7] ? hsum[0].s7 : invalid_power;
                loc[8] = cand[8] ? encode_location(3, tmpl[1], freq[0]) : invalid_location;
                pwr[8] = cand[8] ? hsum[1].s0 : invalid_power;
                loc[9] = cand[9] ? encode_location(3, tmpl[1], freq[1]) : invalid_location;
                pwr[9] = cand[9] ? hsum[1].s1 : invalid_power;
                loc[10] = cand[10] ? encode_location(3, tmpl[1], freq[2]) : invalid_location;
                pwr[10] = cand[10] ? hsum[1].s2 : invalid_power;
                loc[11] = cand[11] ? encode_location(3, tmpl[1], freq[3]) : invalid_location;
                pwr[11] = cand[11] ? hsum[1].s3 : invalid_power;
                loc[12] = cand[12] ? encode_location(3, tmpl[1], freq[4]) : invalid_location;
                pwr[12] = cand[12] ? hsum[1].s4 : invalid_power;
                loc[13] = cand[13] ? encode_location(3, tmpl[1], freq[5]) : invalid_location;
                pwr[13] = cand[13] ? hsum[1].s5 : invalid_power;
                loc[14] = cand[14] ? encode_location(3, tmpl[1], freq[6]) : invalid_location;
                pwr[14] = cand[14] ? hsum[1].s6 : invalid_power;
                loc[15] = cand[15] ? encode_location(3, tmpl[1], freq[7]) : invalid_location;
                pwr[15] = cand[15] ? hsum[1].s7 : invalid_power;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    power_buffer[slot][x] = pwr[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint h = 0; h < 3; ++h) {
        for (uint d = 0; d < 64; ++d) {
            bool is_valid = (valid & (1l << d)) > 0;
            #pragma unroll
            for (uint x = 0; x < 16; ++x) {
                uint location = invalid_location;
                float power = invalid_power;
                if (h < 2) {
                    location = read_channel_intel(detect_location_out[1][x]);
                    power = read_channel_intel(detect_power_out[1][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    power = power_buffer[d][x];
                }
                write_channel_intel(detect_location_out[2][x], location);
                write_channel_intel(detect_power_out[2][x], power);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_4(float threshold,
                     uint n_templates,
                     uint negative_tmpls,
                     uint n_groups,
                     uint n_bundles)
{
    uint location_buffer[64][16];
    float power_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_power = -1.0f;

    for (uint group = 0; group < n_groups; ++group) {
        uint group_base = group * 2;
        int tmpl[2];
        bool tmpl_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            tmpl[p] = negative_tmpls ? - group_base - p : group_base + p;
            tmpl_mask[p] = group_base + p < n_templates;
        }

        for (uint bundle = 0; bundle < n_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint freq[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                freq[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = read_channel_intel(detect_to_detect[2][p]);
                float8 from_sp = read_channel_intel(delay_to_detect[3][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                write_channel_intel(detect_to_detect[3][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & tmpl_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & tmpl_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & tmpl_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & tmpl_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & tmpl_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & tmpl_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & tmpl_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & tmpl_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & tmpl_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & tmpl_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & tmpl_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & tmpl_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & tmpl_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & tmpl_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & tmpl_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & tmpl_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float pwr[16];

                loc[0] = cand[0] ? encode_location(4, tmpl[0], freq[0]) : invalid_location;
                pwr[0] = cand[0] ? hsum[0].s0 : invalid_power;
                loc[1] = cand[1] ? encode_location(4, tmpl[0], freq[1]) : invalid_location;
                pwr[1] = cand[1] ? hsum[0].s1 : invalid_power;
                loc[2] = cand[2] ? encode_location(4, tmpl[0], freq[2]) : invalid_location;
                pwr[2] = cand[2] ? hsum[0].s2 : invalid_power;
                loc[3] = cand[3] ? encode_location(4, tmpl[0], freq[3]) : invalid_location;
                pwr[3] = cand[3] ? hsum[0].s3 : invalid_power;
                loc[4] = cand[4] ? encode_location(4, tmpl[0], freq[4]) : invalid_location;
                pwr[4] = cand[4] ? hsum[0].s4 : invalid_power;
                loc[5] = cand[5] ? encode_location(4, tmpl[0], freq[5]) : invalid_location;
                pwr[5] = cand[5] ? hsum[0].s5 : invalid_power;
                loc[6] = cand[6] ? encode_location(4, tmpl[0], freq[6]) : invalid_location;
                pwr[6] = cand[6] ? hsum[0].s6 : invalid_power;
                loc[7] = cand[7] ? encode_location(4, tmpl[0], freq[7]) : invalid_location;
                pwr[7] = cand[7] ? hsum[0].s7 : invalid_power;
                loc[8] = cand[8] ? encode_location(4, tmpl[1], freq[0]) : invalid_location;
                pwr[8] = cand[8] ? hsum[1].s0 : invalid_power;
                loc[9] = cand[9] ? encode_location(4, tmpl[1], freq[1]) : invalid_location;
                pwr[9] = cand[9] ? hsum[1].s1 : invalid_power;
                loc[10] = cand[10] ? encode_location(4, tmpl[1], freq[2]) : invalid_location;
                pwr[10] = cand[10] ? hsum[1].s2 : invalid_power;
                loc[11] = cand[11] ? encode_location(4, tmpl[1], freq[3]) : invalid_location;
                pwr[11] = cand[11] ? hsum[1].s3 : invalid_power;
                loc[12] = cand[12] ? encode_location(4, tmpl[1], freq[4]) : invalid_location;
                pwr[12] = cand[12] ? hsum[1].s4 : invalid_power;
                loc[13] = cand[13] ? encode_location(4, tmpl[1], freq[5]) : invalid_location;
                pwr[13] = cand[13] ? hsum[1].s5 : invalid_power;
                loc[14] = cand[14] ? encode_location(4, tmpl[1], freq[6]) : invalid_location;
                pwr[14] = cand[14] ? hsum[1].s6 : invalid_power;
                loc[15] = cand[15] ? encode_location(4, tmpl[1], freq[7]) : invalid_location;
                pwr[15] = cand[15] ? hsum[1].s7 : invalid_power;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    power_buffer[slot][x] = pwr[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint h = 0; h < 4; ++h) {
        for (uint d = 0; d < 64; ++d) {
            bool is_valid = (valid & (1l << d)) > 0;
            #pragma unroll
            for (uint x = 0; x < 16; ++x) {
                uint location = invalid_location;
                float power = invalid_power;
                if (h < 3) {
                    location = read_channel_intel(detect_location_out[2][x]);
                    power = read_channel_intel(detect_power_out[2][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    power = power_buffer[d][x];
                }
                write_channel_intel(detect_location_out[3][x], location);
                write_channel_intel(detect_power_out[3][x], power);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_5(float threshold,
                     uint n_templates,
                     uint negative_tmpls,
                     uint n_groups,
                     uint n_bundles)
{
    uint location_buffer[64][16];
    float power_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_power = -1.0f;

    for (uint group = 0; group < n_groups; ++group) {
        uint group_base = group * 2;
        int tmpl[2];
        bool tmpl_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            tmpl[p] = negative_tmpls ? - group_base - p : group_base + p;
            tmpl_mask[p] = group_base + p < n_templates;
        }

        for (uint bundle = 0; bundle < n_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint freq[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                freq[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = read_channel_intel(detect_to_detect[3][p]);
                float8 from_sp = read_channel_intel(delay_to_detect[4][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                write_channel_intel(detect_to_detect[4][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & tmpl_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & tmpl_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & tmpl_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & tmpl_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & tmpl_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & tmpl_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & tmpl_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & tmpl_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & tmpl_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & tmpl_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & tmpl_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & tmpl_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & tmpl_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & tmpl_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & tmpl_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & tmpl_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float pwr[16];

                loc[0] = cand[0] ? encode_location(5, tmpl[0], freq[0]) : invalid_location;
                pwr[0] = cand[0] ? hsum[0].s0 : invalid_power;
                loc[1] = cand[1] ? encode_location(5, tmpl[0], freq[1]) : invalid_location;
                pwr[1] = cand[1] ? hsum[0].s1 : invalid_power;
                loc[2] = cand[2] ? encode_location(5, tmpl[0], freq[2]) : invalid_location;
                pwr[2] = cand[2] ? hsum[0].s2 : invalid_power;
                loc[3] = cand[3] ? encode_location(5, tmpl[0], freq[3]) : invalid_location;
                pwr[3] = cand[3] ? hsum[0].s3 : invalid_power;
                loc[4] = cand[4] ? encode_location(5, tmpl[0], freq[4]) : invalid_location;
                pwr[4] = cand[4] ? hsum[0].s4 : invalid_power;
                loc[5] = cand[5] ? encode_location(5, tmpl[0], freq[5]) : invalid_location;
                pwr[5] = cand[5] ? hsum[0].s5 : invalid_power;
                loc[6] = cand[6] ? encode_location(5, tmpl[0], freq[6]) : invalid_location;
                pwr[6] = cand[6] ? hsum[0].s6 : invalid_power;
                loc[7] = cand[7] ? encode_location(5, tmpl[0], freq[7]) : invalid_location;
                pwr[7] = cand[7] ? hsum[0].s7 : invalid_power;
                loc[8] = cand[8] ? encode_location(5, tmpl[1], freq[0]) : invalid_location;
                pwr[8] = cand[8] ? hsum[1].s0 : invalid_power;
                loc[9] = cand[9] ? encode_location(5, tmpl[1], freq[1]) : invalid_location;
                pwr[9] = cand[9] ? hsum[1].s1 : invalid_power;
                loc[10] = cand[10] ? encode_location(5, tmpl[1], freq[2]) : invalid_location;
                pwr[10] = cand[10] ? hsum[1].s2 : invalid_power;
                loc[11] = cand[11] ? encode_location(5, tmpl[1], freq[3]) : invalid_location;
                pwr[11] = cand[11] ? hsum[1].s3 : invalid_power;
                loc[12] = cand[12] ? encode_location(5, tmpl[1], freq[4]) : invalid_location;
                pwr[12] = cand[12] ? hsum[1].s4 : invalid_power;
                loc[13] = cand[13] ? encode_location(5, tmpl[1], freq[5]) : invalid_location;
                pwr[13] = cand[13] ? hsum[1].s5 : invalid_power;
                loc[14] = cand[14] ? encode_location(5, tmpl[1], freq[6]) : invalid_location;
                pwr[14] = cand[14] ? hsum[1].s6 : invalid_power;
                loc[15] = cand[15] ? encode_location(5, tmpl[1], freq[7]) : invalid_location;
                pwr[15] = cand[15] ? hsum[1].s7 : invalid_power;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    power_buffer[slot][x] = pwr[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint h = 0; h < 5; ++h) {
        for (uint d = 0; d < 64; ++d) {
            bool is_valid = (valid & (1l << d)) > 0;
            #pragma unroll
            for (uint x = 0; x < 16; ++x) {
                uint location = invalid_location;
                float power = invalid_power;
                if (h < 4) {
                    location = read_channel_intel(detect_location_out[3][x]);
                    power = read_channel_intel(detect_power_out[3][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    power = power_buffer[d][x];
                }
                write_channel_intel(detect_location_out[4][x], location);
                write_channel_intel(detect_power_out[4][x], power);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_6(float threshold,
                     uint n_templates,
                     uint negative_tmpls,
                     uint n_groups,
                     uint n_bundles)
{
    uint location_buffer[64][16];
    float power_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_power = -1.0f;

    for (uint group = 0; group < n_groups; ++group) {
        uint group_base = group * 2;
        int tmpl[2];
        bool tmpl_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            tmpl[p] = negative_tmpls ? - group_base - p : group_base + p;
            tmpl_mask[p] = group_base + p < n_templates;
        }

        for (uint bundle = 0; bundle < n_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint freq[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                freq[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = read_channel_intel(detect_to_detect[4][p]);
                float8 from_sp = read_channel_intel(delay_to_detect[5][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                write_channel_intel(detect_to_detect[5][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & tmpl_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & tmpl_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & tmpl_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & tmpl_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & tmpl_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & tmpl_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & tmpl_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & tmpl_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & tmpl_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & tmpl_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & tmpl_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & tmpl_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & tmpl_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & tmpl_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & tmpl_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & tmpl_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float pwr[16];

                loc[0] = cand[0] ? encode_location(6, tmpl[0], freq[0]) : invalid_location;
                pwr[0] = cand[0] ? hsum[0].s0 : invalid_power;
                loc[1] = cand[1] ? encode_location(6, tmpl[0], freq[1]) : invalid_location;
                pwr[1] = cand[1] ? hsum[0].s1 : invalid_power;
                loc[2] = cand[2] ? encode_location(6, tmpl[0], freq[2]) : invalid_location;
                pwr[2] = cand[2] ? hsum[0].s2 : invalid_power;
                loc[3] = cand[3] ? encode_location(6, tmpl[0], freq[3]) : invalid_location;
                pwr[3] = cand[3] ? hsum[0].s3 : invalid_power;
                loc[4] = cand[4] ? encode_location(6, tmpl[0], freq[4]) : invalid_location;
                pwr[4] = cand[4] ? hsum[0].s4 : invalid_power;
                loc[5] = cand[5] ? encode_location(6, tmpl[0], freq[5]) : invalid_location;
                pwr[5] = cand[5] ? hsum[0].s5 : invalid_power;
                loc[6] = cand[6] ? encode_location(6, tmpl[0], freq[6]) : invalid_location;
                pwr[6] = cand[6] ? hsum[0].s6 : invalid_power;
                loc[7] = cand[7] ? encode_location(6, tmpl[0], freq[7]) : invalid_location;
                pwr[7] = cand[7] ? hsum[0].s7 : invalid_power;
                loc[8] = cand[8] ? encode_location(6, tmpl[1], freq[0]) : invalid_location;
                pwr[8] = cand[8] ? hsum[1].s0 : invalid_power;
                loc[9] = cand[9] ? encode_location(6, tmpl[1], freq[1]) : invalid_location;
                pwr[9] = cand[9] ? hsum[1].s1 : invalid_power;
                loc[10] = cand[10] ? encode_location(6, tmpl[1], freq[2]) : invalid_location;
                pwr[10] = cand[10] ? hsum[1].s2 : invalid_power;
                loc[11] = cand[11] ? encode_location(6, tmpl[1], freq[3]) : invalid_location;
                pwr[11] = cand[11] ? hsum[1].s3 : invalid_power;
                loc[12] = cand[12] ? encode_location(6, tmpl[1], freq[4]) : invalid_location;
                pwr[12] = cand[12] ? hsum[1].s4 : invalid_power;
                loc[13] = cand[13] ? encode_location(6, tmpl[1], freq[5]) : invalid_location;
                pwr[13] = cand[13] ? hsum[1].s5 : invalid_power;
                loc[14] = cand[14] ? encode_location(6, tmpl[1], freq[6]) : invalid_location;
                pwr[14] = cand[14] ? hsum[1].s6 : invalid_power;
                loc[15] = cand[15] ? encode_location(6, tmpl[1], freq[7]) : invalid_location;
                pwr[15] = cand[15] ? hsum[1].s7 : invalid_power;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    power_buffer[slot][x] = pwr[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint h = 0; h < 6; ++h) {
        for (uint d = 0; d < 64; ++d) {
            bool is_valid = (valid & (1l << d)) > 0;
            #pragma unroll
            for (uint x = 0; x < 16; ++x) {
                uint location = invalid_location;
                float power = invalid_power;
                if (h < 5) {
                    location = read_channel_intel(detect_location_out[4][x]);
                    power = read_channel_intel(detect_power_out[4][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    power = power_buffer[d][x];
                }
                write_channel_intel(detect_location_out[5][x], location);
                write_channel_intel(detect_power_out[5][x], power);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_7(float threshold,
                     uint n_templates,
                     uint negative_tmpls,
                     uint n_groups,
                     uint n_bundles)
{
    uint location_buffer[64][16];
    float power_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_power = -1.0f;

    for (uint group = 0; group < n_groups; ++group) {
        uint group_base = group * 2;
        int tmpl[2];
        bool tmpl_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            tmpl[p] = negative_tmpls ? - group_base - p : group_base + p;
            tmpl_mask[p] = group_base + p < n_templates;
        }

        for (uint bundle = 0; bundle < n_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint freq[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                freq[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = read_channel_intel(detect_to_detect[5][p]);
                float8 from_sp = read_channel_intel(delay_to_detect[6][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                write_channel_intel(detect_to_detect[6][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & tmpl_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & tmpl_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & tmpl_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & tmpl_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & tmpl_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & tmpl_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & tmpl_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & tmpl_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & tmpl_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & tmpl_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & tmpl_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & tmpl_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & tmpl_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & tmpl_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & tmpl_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & tmpl_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float pwr[16];

                loc[0] = cand[0] ? encode_location(7, tmpl[0], freq[0]) : invalid_location;
                pwr[0] = cand[0] ? hsum[0].s0 : invalid_power;
                loc[1] = cand[1] ? encode_location(7, tmpl[0], freq[1]) : invalid_location;
                pwr[1] = cand[1] ? hsum[0].s1 : invalid_power;
                loc[2] = cand[2] ? encode_location(7, tmpl[0], freq[2]) : invalid_location;
                pwr[2] = cand[2] ? hsum[0].s2 : invalid_power;
                loc[3] = cand[3] ? encode_location(7, tmpl[0], freq[3]) : invalid_location;
                pwr[3] = cand[3] ? hsum[0].s3 : invalid_power;
                loc[4] = cand[4] ? encode_location(7, tmpl[0], freq[4]) : invalid_location;
                pwr[4] = cand[4] ? hsum[0].s4 : invalid_power;
                loc[5] = cand[5] ? encode_location(7, tmpl[0], freq[5]) : invalid_location;
                pwr[5] = cand[5] ? hsum[0].s5 : invalid_power;
                loc[6] = cand[6] ? encode_location(7, tmpl[0], freq[6]) : invalid_location;
                pwr[6] = cand[6] ? hsum[0].s6 : invalid_power;
                loc[7] = cand[7] ? encode_location(7, tmpl[0], freq[7]) : invalid_location;
                pwr[7] = cand[7] ? hsum[0].s7 : invalid_power;
                loc[8] = cand[8] ? encode_location(7, tmpl[1], freq[0]) : invalid_location;
                pwr[8] = cand[8] ? hsum[1].s0 : invalid_power;
                loc[9] = cand[9] ? encode_location(7, tmpl[1], freq[1]) : invalid_location;
                pwr[9] = cand[9] ? hsum[1].s1 : invalid_power;
                loc[10] = cand[10] ? encode_location(7, tmpl[1], freq[2]) : invalid_location;
                pwr[10] = cand[10] ? hsum[1].s2 : invalid_power;
                loc[11] = cand[11] ? encode_location(7, tmpl[1], freq[3]) : invalid_location;
                pwr[11] = cand[11] ? hsum[1].s3 : invalid_power;
                loc[12] = cand[12] ? encode_location(7, tmpl[1], freq[4]) : invalid_location;
                pwr[12] = cand[12] ? hsum[1].s4 : invalid_power;
                loc[13] = cand[13] ? encode_location(7, tmpl[1], freq[5]) : invalid_location;
                pwr[13] = cand[13] ? hsum[1].s5 : invalid_power;
                loc[14] = cand[14] ? encode_location(7, tmpl[1], freq[6]) : invalid_location;
                pwr[14] = cand[14] ? hsum[1].s6 : invalid_power;
                loc[15] = cand[15] ? encode_location(7, tmpl[1], freq[7]) : invalid_location;
                pwr[15] = cand[15] ? hsum[1].s7 : invalid_power;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    power_buffer[slot][x] = pwr[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint h = 0; h < 7; ++h) {
        for (uint d = 0; d < 64; ++d) {
            bool is_valid = (valid & (1l << d)) > 0;
            #pragma unroll
            for (uint x = 0; x < 16; ++x) {
                uint location = invalid_location;
                float power = invalid_power;
                if (h < 6) {
                    location = read_channel_intel(detect_location_out[5][x]);
                    power = read_channel_intel(detect_power_out[5][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    power = power_buffer[d][x];
                }
                write_channel_intel(detect_location_out[6][x], location);
                write_channel_intel(detect_power_out[6][x], power);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_8(float threshold,
                     uint n_templates,
                     uint negative_tmpls,
                     uint n_groups,
                     uint n_bundles)
{
    uint location_buffer[64][16];
    float power_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_power = -1.0f;

    for (uint group = 0; group < n_groups; ++group) {
        uint group_base = group * 2;
        int tmpl[2];
        bool tmpl_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            tmpl[p] = negative_tmpls ? - group_base - p : group_base + p;
            tmpl_mask[p] = group_base + p < n_templates;
        }

        for (uint bundle = 0; bundle < n_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint freq[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                freq[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = read_channel_intel(detect_to_detect[6][p]);
                float8 from_sp = read_channel_intel(delay_to_detect[7][p]);
                hsum[p] = from_prev_hp + from_sp;
            }


            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & tmpl_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & tmpl_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & tmpl_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & tmpl_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & tmpl_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & tmpl_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & tmpl_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & tmpl_mask[0];
            cand[8] = (hsum[1].s0 > threshold) & tmpl_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & tmpl_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & tmpl_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & tmpl_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & tmpl_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & tmpl_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & tmpl_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & tmpl_mask[1];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float pwr[16];

                loc[0] = cand[0] ? encode_location(8, tmpl[0], freq[0]) : invalid_location;
                pwr[0] = cand[0] ? hsum[0].s0 : invalid_power;
                loc[1] = cand[1] ? encode_location(8, tmpl[0], freq[1]) : invalid_location;
                pwr[1] = cand[1] ? hsum[0].s1 : invalid_power;
                loc[2] = cand[2] ? encode_location(8, tmpl[0], freq[2]) : invalid_location;
                pwr[2] = cand[2] ? hsum[0].s2 : invalid_power;
                loc[3] = cand[3] ? encode_location(8, tmpl[0], freq[3]) : invalid_location;
                pwr[3] = cand[3] ? hsum[0].s3 : invalid_power;
                loc[4] = cand[4] ? encode_location(8, tmpl[0], freq[4]) : invalid_location;
                pwr[4] = cand[4] ? hsum[0].s4 : invalid_power;
                loc[5] = cand[5] ? encode_location(8, tmpl[0], freq[5]) : invalid_location;
                pwr[5] = cand[5] ? hsum[0].s5 : invalid_power;
                loc[6] = cand[6] ? encode_location(8, tmpl[0], freq[6]) : invalid_location;
                pwr[6] = cand[6] ? hsum[0].s6 : invalid_power;
                loc[7] = cand[7] ? encode_location(8, tmpl[0], freq[7]) : invalid_location;
                pwr[7] = cand[7] ? hsum[0].s7 : invalid_power;
                loc[8] = cand[8] ? encode_location(8, tmpl[1], freq[0]) : invalid_location;
                pwr[8] = cand[8] ? hsum[1].s0 : invalid_power;
                loc[9] = cand[9] ? encode_location(8, tmpl[1], freq[1]) : invalid_location;
                pwr[9] = cand[9] ? hsum[1].s1 : invalid_power;
                loc[10] = cand[10] ? encode_location(8, tmpl[1], freq[2]) : invalid_location;
                pwr[10] = cand[10] ? hsum[1].s2 : invalid_power;
                loc[11] = cand[11] ? encode_location(8, tmpl[1], freq[3]) : invalid_location;
                pwr[11] = cand[11] ? hsum[1].s3 : invalid_power;
                loc[12] = cand[12] ? encode_location(8, tmpl[1], freq[4]) : invalid_location;
                pwr[12] = cand[12] ? hsum[1].s4 : invalid_power;
                loc[13] = cand[13] ? encode_location(8, tmpl[1], freq[5]) : invalid_location;
                pwr[13] = cand[13] ? hsum[1].s5 : invalid_power;
                loc[14] = cand[14] ? encode_location(8, tmpl[1], freq[6]) : invalid_location;
                pwr[14] = cand[14] ? hsum[1].s6 : invalid_power;
                loc[15] = cand[15] ? encode_location(8, tmpl[1], freq[7]) : invalid_location;
                pwr[15] = cand[15] ? hsum[1].s7 : invalid_power;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    power_buffer[slot][x] = pwr[x];
                }

                valid |= 1l << slot;
            }
        }
    }

    for (uint h = 0; h < 8; ++h) {
        for (uint d = 0; d < 64; ++d) {
            bool is_valid = (valid & (1l << d)) > 0;
            #pragma unroll
            for (uint x = 0; x < 16; ++x) {
                uint location = invalid_location;
                float power = invalid_power;
                if (h < 7) {
                    location = read_channel_intel(detect_location_out[6][x]);
                    power = read_channel_intel(detect_power_out[6][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    power = power_buffer[d][x];
                }
                write_channel_intel(detect_location_out[7][x], location);
                write_channel_intel(detect_power_out[7][x], power);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void store_cands(global uint * restrict detection_location,
                        global float * restrict detection_power)
{
    for (uint d = 0; d < 512; ++d) {
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            uint location = read_channel_intel(detect_location_out[7][x]);
            float power = read_channel_intel(detect_power_out[7][x]);
            detection_location[d * 16 + x] = location;
            detection_power[d * 16 + x] = power;
        }
    }
}
