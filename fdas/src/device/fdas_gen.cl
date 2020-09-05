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

#if defined(INTELFPGA_CL)
#pragma OPENCL EXTENSION cl_intel_channels : enable
#define READ_CHANNEL(ch) read_channel_intel(ch)
#define WRITE_CHANNEL(ch, x) write_channel_intel(ch, x)
#else
#pragma OPENCL EXTENSION cl_altera_channels : enable
#define READ_CHANNEL(ch) read_channel_altera(ch)
#define WRITE_CHANNEL(ch, x) write_channel_altera(ch, x)
#endif

channel float2x4 load_to_tile __attribute__((depth(0)));

channel float2x4 fft_in __attribute__((depth(0)));
channel float2x4 fft_out __attribute__((depth(0)));

channel float2x4 ifft_in[4] __attribute__((depth(0)));
channel float2x4 ifft_out[4] __attribute__((depth(0)));

channel float preload_to_delay[8][16] __attribute__((depth(0)));
channel float delay_to_detect[8][16] __attribute__((depth(0)));

channel float detect_to_detect[7][16] __attribute__((depth(0)));
channel uint  detect_location_out[8][16] __attribute__((depth(0)));
channel float detect_amplitude_out[8][16] __attribute__((depth(0)));

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

inline float2x4 complex_mult4(float2x4 a, float2x4 b)
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

inline float4 power_norm4(float2x4 a)
{
    float4 res;
    res.s0 = (a.i0.x * a.i0.x + a.i0.y * a.i0.y) / 4194304;
    res.s1 = (a.i1.x * a.i1.x + a.i1.y * a.i1.y) / 4194304;
    res.s2 = (a.i2.x * a.i2.x + a.i2.y * a.i2.y) / 4194304;
    res.s3 = (a.i3.x * a.i3.x + a.i3.y * a.i3.y) / 4194304;
    return res;
}

inline uint encode_location(uint k, int f, uint c) {
    return (((k - 1) & 0x7) << 29) | (((f + 42) & 0x7f) << 22) | (c & 0x3fffff);
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
                    WRITE_CHANNEL(fft_out, buf[tile & 1][step]);
                else
                    WRITE_CHANNEL(ifft_out[0], buf[tile & 1][step]);
            }

            if (tile < n_tiles) {
                if (! is_inverse)
                    data = READ_CHANNEL(fft_in);
                else
                    data = READ_CHANNEL(ifft_in[0]);
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
                WRITE_CHANNEL(ifft_out[1], buf[tile & 1][step]);
            }

            if (tile < n_tiles) {
                data = READ_CHANNEL(ifft_in[1]);
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
                WRITE_CHANNEL(ifft_out[2], buf[tile & 1][step]);
            }

            if (tile < n_tiles) {
                data = READ_CHANNEL(ifft_in[2]);
            } else {
                data = zeros;
            }

            data = fft_step(data, step, fft_delay_elements, 1, 11);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void fft_3(const uint n_tiles)
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
                WRITE_CHANNEL(ifft_out[3], buf[tile & 1][step]);
            }

            if (tile < n_tiles) {
                data = READ_CHANNEL(ifft_in[3]);
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
                       const uint n_packs)
{
    for (uint pack = 0; pack < n_packs; ++pack) {
        float2x4 load = input[pack];
        WRITE_CHANNEL(load_to_tile, load);
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
                WRITE_CHANNEL(fft_in, output);
            }

            float2x4 input = zeros;
            if (tile < n_tiles) {
                if (step < 105) {
                    if (tile >= 1)
                        input = overlap_sr[0];
                }
                else {
                    input = READ_CHANNEL(load_to_tile);
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
            float2x4 read = READ_CHANNEL(fft_out);
            tiles[tile * 512 + step] = read;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void mux_and_mult(global float2x4 * restrict tiles,
                         global float2x4 * restrict templates,
                         const uint n_tiles,
                         const int filter_0,
                         const int filter_1,
                         const int filter_2,
                         const int filter_3,
                         const uint n_filters)
{
    const float2x4 zeros = {0, 0, 0, 0};

    float2x4 template_buf_0[512];
    float2x4 template_buf_1[512];
    float2x4 template_buf_2[512];
    float2x4 template_buf_3[512];

    for (uint pack = 0; pack < 512; ++pack) {
        float2x4 tmpl_0 = 0 < n_filters ? templates[(42 + filter_0) * 512 + pack] : zeros;
        float2x4 tmpl_1 = 1 < n_filters ? templates[(42 + filter_1) * 512 + pack] : zeros;
        float2x4 tmpl_2 = 2 < n_filters ? templates[(42 + filter_2) * 512 + pack] : zeros;
        float2x4 tmpl_3 = 3 < n_filters ? templates[(42 + filter_3) * 512 + pack] : zeros;
        template_buf_0[pack] = tmpl_0;
        template_buf_1[pack] = tmpl_1;
        template_buf_2[pack] = tmpl_2;
        template_buf_3[pack] = tmpl_3;
    }

    for (uint pack = 0; pack < n_tiles * 512; ++pack) {
        float2x4 coeffs[4];
        float2x4 prods[4];

        float2x4 load = tiles[pack];
        coeffs[0] = template_buf_0[pack % 512];
        coeffs[1] = template_buf_1[pack % 512];
        coeffs[2] = template_buf_2[pack % 512];
        coeffs[3] = template_buf_3[pack % 512];
        prods[0] = complex_mult4(load, coeffs[0]);
        prods[1] = complex_mult4(load, coeffs[1]);
        prods[2] = complex_mult4(load, coeffs[2]);
        prods[3] = complex_mult4(load, coeffs[3]);

        #pragma unroll
        for (uint e = 0; e < 4; ++e) {
            if (e < n_filters)
                WRITE_CHANNEL(ifft_in[e], prods[e]);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void square_and_discard_0(global float4 * restrict fop_A,
                                 const uint fop_offset,
                                 const uint n_tiles)
{
    const float4 zeros = {0, 0, 0, 0};

    float __attribute__((bank_bits(9))) chunk_buf_0[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_1[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_2[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_3[2][512];

    uint fop_idx = 0;
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

                fop_A[fop_offset + fop_idx] = store;
                ++fop_idx;
            }

            if (tile < n_tiles) {
                float2x4 read = READ_CHANNEL(ifft_out[0]);
                float4 norm = power_norm4(read);
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
kernel void square_and_discard_1(global float4 * restrict fop_A,
                                 const uint fop_offset,
                                 const uint n_tiles)
{
    const float4 zeros = {0, 0, 0, 0};

    float __attribute__((bank_bits(9))) chunk_buf_0[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_1[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_2[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_3[2][512];

    uint fop_idx = 0;
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

                fop_A[fop_offset + fop_idx] = store;
                ++fop_idx;
            }

            if (tile < n_tiles) {
                float2x4 read = READ_CHANNEL(ifft_out[1]);
                float4 norm = power_norm4(read);
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
kernel void square_and_discard_2(global float4 * restrict fop_A,
                                 const uint fop_offset,
                                 const uint n_tiles)
{
    const float4 zeros = {0, 0, 0, 0};

    float __attribute__((bank_bits(9))) chunk_buf_0[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_1[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_2[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_3[2][512];

    uint fop_idx = 0;
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

                fop_A[fop_offset + fop_idx] = store;
                ++fop_idx;
            }

            if (tile < n_tiles) {
                float2x4 read = READ_CHANNEL(ifft_out[2]);
                float4 norm = power_norm4(read);
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
kernel void square_and_discard_3(global float4 * restrict fop_A,
                                 const uint fop_offset,
                                 const uint n_tiles)
{
    const float4 zeros = {0, 0, 0, 0};

    float __attribute__((bank_bits(9))) chunk_buf_0[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_1[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_2[2][512];
    float __attribute__((bank_bits(9))) chunk_buf_3[2][512];

    uint fop_idx = 0;
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

                fop_A[fop_offset + fop_idx] = store;
                ++fop_idx;
            }

            if (tile < n_tiles) {
                float2x4 read = READ_CHANNEL(ifft_out[3]);
                float4 norm = power_norm4(read);
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
kernel void preload_1(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint filter_offset_1,
                      const uint filter_offset_2,
                      const uint filter_offset_3,
                      const uint filter_offset_4,
                      const uint filter_offset_5,
                      const uint filter_offset_6,
                      const uint filter_offset_7,
                      const uint filter_offset_8,
                      const uint filter_offset_9,
                      const uint filter_offset_10,
                      const uint filter_offset_11,
                      const uint filter_offset_12,
                      const uint filter_offset_13,
                      const uint filter_offset_14,
                      const uint filter_offset_15,
                      const uint n_channel_bundles)
{
    const float zeros = {0};
    float load[16];
    float out[16];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;
        load[1] = 1 < n_rows ? fop[filter_offset_1 + bundle] : zeros;
        load[2] = 2 < n_rows ? fop[filter_offset_2 + bundle] : zeros;
        load[3] = 3 < n_rows ? fop[filter_offset_3 + bundle] : zeros;
        load[4] = 4 < n_rows ? fop[filter_offset_4 + bundle] : zeros;
        load[5] = 5 < n_rows ? fop[filter_offset_5 + bundle] : zeros;
        load[6] = 6 < n_rows ? fop[filter_offset_6 + bundle] : zeros;
        load[7] = 7 < n_rows ? fop[filter_offset_7 + bundle] : zeros;
        load[8] = 8 < n_rows ? fop[filter_offset_8 + bundle] : zeros;
        load[9] = 9 < n_rows ? fop[filter_offset_9 + bundle] : zeros;
        load[10] = 10 < n_rows ? fop[filter_offset_10 + bundle] : zeros;
        load[11] = 11 < n_rows ? fop[filter_offset_11 + bundle] : zeros;
        load[12] = 12 < n_rows ? fop[filter_offset_12 + bundle] : zeros;
        load[13] = 13 < n_rows ? fop[filter_offset_13 + bundle] : zeros;
        load[14] = 14 < n_rows ? fop[filter_offset_14 + bundle] : zeros;
        load[15] = 15 < n_rows ? fop[filter_offset_15 + bundle] : zeros;

        out[0] = load[0];
        out[1] = load[1];
        out[2] = load[2];
        out[3] = load[3];
        out[4] = load[4];
        out[5] = load[5];
        out[6] = load[6];
        out[7] = load[7];
        out[8] = load[8];
        out[9] = load[9];
        out[10] = load[10];
        out[11] = load[11];
        out[12] = load[12];
        out[13] = load[13];
        out[14] = load[14];
        out[15] = load[15];

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(preload_to_delay[0][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_1(const uint n_channel_bundles)
{
    const float zeros = {0};
    float in[16];
    float out[16];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 0 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[0][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 16; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(delay_to_detect[0][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_2(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint filter_offset_1,
                      const uint filter_offset_2,
                      const uint filter_offset_3,
                      const uint filter_offset_4,
                      const uint filter_offset_5,
                      const uint filter_offset_6,
                      const uint filter_offset_7,
                      const uint n_channel_bundles)
{
    const float zeros = {0};
    float load[8];
    float out[16];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;
        load[1] = 1 < n_rows ? fop[filter_offset_1 + bundle] : zeros;
        load[2] = 2 < n_rows ? fop[filter_offset_2 + bundle] : zeros;
        load[3] = 3 < n_rows ? fop[filter_offset_3 + bundle] : zeros;
        load[4] = 4 < n_rows ? fop[filter_offset_4 + bundle] : zeros;
        load[5] = 5 < n_rows ? fop[filter_offset_5 + bundle] : zeros;
        load[6] = 6 < n_rows ? fop[filter_offset_6 + bundle] : zeros;
        load[7] = 7 < n_rows ? fop[filter_offset_7 + bundle] : zeros;

        out[0] = load[0];
        out[1] = load[0];
        out[2] = load[1];
        out[3] = load[1];
        out[4] = load[2];
        out[5] = load[2];
        out[6] = load[3];
        out[7] = load[3];
        out[8] = load[4];
        out[9] = load[4];
        out[10] = load[5];
        out[11] = load[5];
        out[12] = load[6];
        out[13] = load[6];
        out[14] = load[7];
        out[15] = load[7];

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(preload_to_delay[1][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_2(const uint n_channel_bundles)
{
    const float zeros = {0};
    float in[16];
    float out[16];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 1 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[1][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 16; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(delay_to_detect[1][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_3(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint filter_offset_1,
                      const uint filter_offset_2,
                      const uint filter_offset_3,
                      const uint filter_offset_4,
                      const uint filter_offset_5,
                      const uint n_channel_bundles)
{
    const float zeros = {0};
    float load[6];
    float out[16];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;
        load[1] = 1 < n_rows ? fop[filter_offset_1 + bundle] : zeros;
        load[2] = 2 < n_rows ? fop[filter_offset_2 + bundle] : zeros;
        load[3] = 3 < n_rows ? fop[filter_offset_3 + bundle] : zeros;
        load[4] = 4 < n_rows ? fop[filter_offset_4 + bundle] : zeros;
        load[5] = 5 < n_rows ? fop[filter_offset_5 + bundle] : zeros;

        out[0] = load[0];
        out[1] = base_row_rem < 2 ? load[0] : load[1];
        out[2] = base_row_rem < 1 ? load[0] : load[1];
        out[3] = load[1];
        out[4] = base_row_rem < 2 ? load[1] : load[2];
        out[5] = base_row_rem < 1 ? load[1] : load[2];
        out[6] = load[2];
        out[7] = base_row_rem < 2 ? load[2] : load[3];
        out[8] = base_row_rem < 1 ? load[2] : load[3];
        out[9] = load[3];
        out[10] = base_row_rem < 2 ? load[3] : load[4];
        out[11] = base_row_rem < 1 ? load[3] : load[4];
        out[12] = load[4];
        out[13] = base_row_rem < 2 ? load[4] : load[5];
        out[14] = base_row_rem < 1 ? load[4] : load[5];
        out[15] = load[5];

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(preload_to_delay[2][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_3(const uint n_channel_bundles)
{
    const float zeros = {0};
    float in[16];
    float out[16];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 2 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[2][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 16; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(delay_to_detect[2][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_4(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint filter_offset_1,
                      const uint filter_offset_2,
                      const uint filter_offset_3,
                      const uint n_channel_bundles)
{
    const float zeros = {0};
    float load[4];
    float out[16];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;
        load[1] = 1 < n_rows ? fop[filter_offset_1 + bundle] : zeros;
        load[2] = 2 < n_rows ? fop[filter_offset_2 + bundle] : zeros;
        load[3] = 3 < n_rows ? fop[filter_offset_3 + bundle] : zeros;

        out[0] = load[0];
        out[1] = load[0];
        out[2] = load[0];
        out[3] = load[0];
        out[4] = load[1];
        out[5] = load[1];
        out[6] = load[1];
        out[7] = load[1];
        out[8] = load[2];
        out[9] = load[2];
        out[10] = load[2];
        out[11] = load[2];
        out[12] = load[3];
        out[13] = load[3];
        out[14] = load[3];
        out[15] = load[3];

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(preload_to_delay[3][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_4(const uint n_channel_bundles)
{
    const float zeros = {0};
    float in[16];
    float out[16];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 3 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[3][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 16; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(delay_to_detect[3][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_5(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint filter_offset_1,
                      const uint filter_offset_2,
                      const uint filter_offset_3,
                      const uint n_channel_bundles)
{
    const float zeros = {0};
    float load[4];
    float out[16];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;
        load[1] = 1 < n_rows ? fop[filter_offset_1 + bundle] : zeros;
        load[2] = 2 < n_rows ? fop[filter_offset_2 + bundle] : zeros;
        load[3] = 3 < n_rows ? fop[filter_offset_3 + bundle] : zeros;

        out[0] = load[0];
        out[1] = base_row_rem < 4 ? load[0] : load[1];
        out[2] = base_row_rem < 3 ? load[0] : load[1];
        out[3] = base_row_rem < 2 ? load[0] : load[1];
        out[4] = base_row_rem < 1 ? load[0] : load[1];
        out[5] = load[1];
        out[6] = base_row_rem < 4 ? load[1] : load[2];
        out[7] = base_row_rem < 3 ? load[1] : load[2];
        out[8] = base_row_rem < 2 ? load[1] : load[2];
        out[9] = base_row_rem < 1 ? load[1] : load[2];
        out[10] = load[2];
        out[11] = base_row_rem < 4 ? load[2] : load[3];
        out[12] = base_row_rem < 3 ? load[2] : load[3];
        out[13] = base_row_rem < 2 ? load[2] : load[3];
        out[14] = base_row_rem < 1 ? load[2] : load[3];
        out[15] = load[3];

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(preload_to_delay[4][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_5(const uint n_channel_bundles)
{
    const float zeros = {0};
    float in[16];
    float out[16];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 4 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[4][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 16; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(delay_to_detect[4][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_6(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint filter_offset_1,
                      const uint filter_offset_2,
                      const uint filter_offset_3,
                      const uint n_channel_bundles)
{
    const float zeros = {0};
    float load[4];
    float out[16];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;
        load[1] = 1 < n_rows ? fop[filter_offset_1 + bundle] : zeros;
        load[2] = 2 < n_rows ? fop[filter_offset_2 + bundle] : zeros;
        load[3] = 3 < n_rows ? fop[filter_offset_3 + bundle] : zeros;

        out[0] = load[0];
        out[1] = load[0];
        out[2] = base_row_rem < 4 ? load[0] : load[1];
        out[3] = base_row_rem < 4 ? load[0] : load[1];
        out[4] = base_row_rem < 2 ? load[0] : load[1];
        out[5] = base_row_rem < 2 ? load[0] : load[1];
        out[6] = load[1];
        out[7] = load[1];
        out[8] = base_row_rem < 4 ? load[1] : load[2];
        out[9] = base_row_rem < 4 ? load[1] : load[2];
        out[10] = base_row_rem < 2 ? load[1] : load[2];
        out[11] = base_row_rem < 2 ? load[1] : load[2];
        out[12] = load[2];
        out[13] = load[2];
        out[14] = base_row_rem < 4 ? load[2] : load[3];
        out[15] = base_row_rem < 4 ? load[2] : load[3];

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(preload_to_delay[5][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_6(const uint n_channel_bundles)
{
    const float zeros = {0};
    float in[16];
    float out[16];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 5 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[5][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 16; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(delay_to_detect[5][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_7(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint filter_offset_1,
                      const uint filter_offset_2,
                      const uint filter_offset_3,
                      const uint n_channel_bundles)
{
    const float zeros = {0};
    float load[4];
    float out[16];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;
        load[1] = 1 < n_rows ? fop[filter_offset_1 + bundle] : zeros;
        load[2] = 2 < n_rows ? fop[filter_offset_2 + bundle] : zeros;
        load[3] = 3 < n_rows ? fop[filter_offset_3 + bundle] : zeros;

        out[0] = load[0];
        out[1] = base_row_rem < 6 ? load[0] : load[1];
        out[2] = base_row_rem < 5 ? load[0] : load[1];
        out[3] = base_row_rem < 4 ? load[0] : load[1];
        out[4] = base_row_rem < 3 ? load[0] : load[1];
        out[5] = base_row_rem < 2 ? load[0] : load[1];
        out[6] = base_row_rem < 1 ? load[0] : load[1];
        out[7] = load[1];
        out[8] = base_row_rem < 6 ? load[1] : load[2];
        out[9] = base_row_rem < 5 ? load[1] : load[2];
        out[10] = base_row_rem < 4 ? load[1] : load[2];
        out[11] = base_row_rem < 3 ? load[1] : load[2];
        out[12] = base_row_rem < 2 ? load[1] : load[2];
        out[13] = base_row_rem < 1 ? load[1] : load[2];
        out[14] = load[2];
        out[15] = base_row_rem < 6 ? load[2] : load[3];

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(preload_to_delay[6][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_7(const uint n_channel_bundles)
{
    const float zeros = {0};
    float in[16];
    float out[16];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 6 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[6][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 6:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 16; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(delay_to_detect[6][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_8(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint filter_offset_1,
                      const uint n_channel_bundles)
{
    const float zeros = {0};
    float load[2];
    float out[16];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;
        load[1] = 1 < n_rows ? fop[filter_offset_1 + bundle] : zeros;

        out[0] = load[0];
        out[1] = load[0];
        out[2] = load[0];
        out[3] = load[0];
        out[4] = load[0];
        out[5] = load[0];
        out[6] = load[0];
        out[7] = load[0];
        out[8] = load[1];
        out[9] = load[1];
        out[10] = load[1];
        out[11] = load[1];
        out[12] = load[1];
        out[13] = load[1];
        out[14] = load[1];
        out[15] = load[1];

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(preload_to_delay[7][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_8(const uint n_channel_bundles)
{
    const float zeros = {0};
    float in[16];
    float out[16];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 7 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[7][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 6:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            case 7:
                #pragma unroll
                for (uint p = 0; p < 16; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 16; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 16; ++p)
            WRITE_CHANNEL(delay_to_detect[7][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_1(float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 16;
        int filter_num[16];
        bool filter_mask[16];
        #pragma unroll
        for (uint p = 0; p < 16; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 1;
            uint channel_num[1];
            #pragma unroll
            for (uint q = 0; q < 1; ++q)
                channel_num[q] = bundle_base + q;

            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p) {
                float from_fop = READ_CHANNEL(delay_to_detect[0][p]);
                hsum[p] = from_fop;
            }

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[0][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0] > threshold) & filter_mask[0];
            cand[1] = (hsum[1] > threshold) & filter_mask[1];
            cand[2] = (hsum[2] > threshold) & filter_mask[2];
            cand[3] = (hsum[3] > threshold) & filter_mask[3];
            cand[4] = (hsum[4] > threshold) & filter_mask[4];
            cand[5] = (hsum[5] > threshold) & filter_mask[5];
            cand[6] = (hsum[6] > threshold) & filter_mask[6];
            cand[7] = (hsum[7] > threshold) & filter_mask[7];
            cand[8] = (hsum[8] > threshold) & filter_mask[8];
            cand[9] = (hsum[9] > threshold) & filter_mask[9];
            cand[10] = (hsum[10] > threshold) & filter_mask[10];
            cand[11] = (hsum[11] > threshold) & filter_mask[11];
            cand[12] = (hsum[12] > threshold) & filter_mask[12];
            cand[13] = (hsum[13] > threshold) & filter_mask[13];
            cand[14] = (hsum[14] > threshold) & filter_mask[14];
            cand[15] = (hsum[15] > threshold) & filter_mask[15];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(1, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0] : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(1, filter_num[1], channel_num[0]) : invalid_location;
                amp[1] = cand[1] ? hsum[1] : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(1, filter_num[2], channel_num[0]) : invalid_location;
                amp[2] = cand[2] ? hsum[2] : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(1, filter_num[3], channel_num[0]) : invalid_location;
                amp[3] = cand[3] ? hsum[3] : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(1, filter_num[4], channel_num[0]) : invalid_location;
                amp[4] = cand[4] ? hsum[4] : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(1, filter_num[5], channel_num[0]) : invalid_location;
                amp[5] = cand[5] ? hsum[5] : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(1, filter_num[6], channel_num[0]) : invalid_location;
                amp[6] = cand[6] ? hsum[6] : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(1, filter_num[7], channel_num[0]) : invalid_location;
                amp[7] = cand[7] ? hsum[7] : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(1, filter_num[8], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[8] : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(1, filter_num[9], channel_num[0]) : invalid_location;
                amp[9] = cand[9] ? hsum[9] : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(1, filter_num[10], channel_num[0]) : invalid_location;
                amp[10] = cand[10] ? hsum[10] : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(1, filter_num[11], channel_num[0]) : invalid_location;
                amp[11] = cand[11] ? hsum[11] : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(1, filter_num[12], channel_num[0]) : invalid_location;
                amp[12] = cand[12] ? hsum[12] : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(1, filter_num[13], channel_num[0]) : invalid_location;
                amp[13] = cand[13] ? hsum[13] : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(1, filter_num[14], channel_num[0]) : invalid_location;
                amp[14] = cand[14] ? hsum[14] : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(1, filter_num[15], channel_num[0]) : invalid_location;
                amp[15] = cand[15] ? hsum[15] : invalid_amplitude;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
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
                float amplitude = is_valid ? amplitude_buffer[d][x] : invalid_amplitude;
                WRITE_CHANNEL(detect_location_out[0][x], location);
                WRITE_CHANNEL(detect_amplitude_out[0][x], amplitude);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_2(float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 16;
        int filter_num[16];
        bool filter_mask[16];
        #pragma unroll
        for (uint p = 0; p < 16; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 1;
            uint channel_num[1];
            #pragma unroll
            for (uint q = 0; q < 1; ++q)
                channel_num[q] = bundle_base + q;

            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p) {
                float from_prev_hp = READ_CHANNEL(detect_to_detect[0][p]);
                float from_sp = READ_CHANNEL(delay_to_detect[1][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[1][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0] > threshold) & filter_mask[0];
            cand[1] = (hsum[1] > threshold) & filter_mask[1];
            cand[2] = (hsum[2] > threshold) & filter_mask[2];
            cand[3] = (hsum[3] > threshold) & filter_mask[3];
            cand[4] = (hsum[4] > threshold) & filter_mask[4];
            cand[5] = (hsum[5] > threshold) & filter_mask[5];
            cand[6] = (hsum[6] > threshold) & filter_mask[6];
            cand[7] = (hsum[7] > threshold) & filter_mask[7];
            cand[8] = (hsum[8] > threshold) & filter_mask[8];
            cand[9] = (hsum[9] > threshold) & filter_mask[9];
            cand[10] = (hsum[10] > threshold) & filter_mask[10];
            cand[11] = (hsum[11] > threshold) & filter_mask[11];
            cand[12] = (hsum[12] > threshold) & filter_mask[12];
            cand[13] = (hsum[13] > threshold) & filter_mask[13];
            cand[14] = (hsum[14] > threshold) & filter_mask[14];
            cand[15] = (hsum[15] > threshold) & filter_mask[15];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(2, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0] : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(2, filter_num[1], channel_num[0]) : invalid_location;
                amp[1] = cand[1] ? hsum[1] : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(2, filter_num[2], channel_num[0]) : invalid_location;
                amp[2] = cand[2] ? hsum[2] : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(2, filter_num[3], channel_num[0]) : invalid_location;
                amp[3] = cand[3] ? hsum[3] : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(2, filter_num[4], channel_num[0]) : invalid_location;
                amp[4] = cand[4] ? hsum[4] : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(2, filter_num[5], channel_num[0]) : invalid_location;
                amp[5] = cand[5] ? hsum[5] : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(2, filter_num[6], channel_num[0]) : invalid_location;
                amp[6] = cand[6] ? hsum[6] : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(2, filter_num[7], channel_num[0]) : invalid_location;
                amp[7] = cand[7] ? hsum[7] : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(2, filter_num[8], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[8] : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(2, filter_num[9], channel_num[0]) : invalid_location;
                amp[9] = cand[9] ? hsum[9] : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(2, filter_num[10], channel_num[0]) : invalid_location;
                amp[10] = cand[10] ? hsum[10] : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(2, filter_num[11], channel_num[0]) : invalid_location;
                amp[11] = cand[11] ? hsum[11] : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(2, filter_num[12], channel_num[0]) : invalid_location;
                amp[12] = cand[12] ? hsum[12] : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(2, filter_num[13], channel_num[0]) : invalid_location;
                amp[13] = cand[13] ? hsum[13] : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(2, filter_num[14], channel_num[0]) : invalid_location;
                amp[14] = cand[14] ? hsum[14] : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(2, filter_num[15], channel_num[0]) : invalid_location;
                amp[15] = cand[15] ? hsum[15] : invalid_amplitude;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
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
                float amplitude = invalid_amplitude;
                if (h < 1) {
                    location = READ_CHANNEL(detect_location_out[0][x]);
                    amplitude = READ_CHANNEL(detect_amplitude_out[0][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    amplitude = amplitude_buffer[d][x];
                }
                WRITE_CHANNEL(detect_location_out[1][x], location);
                WRITE_CHANNEL(detect_amplitude_out[1][x], amplitude);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_3(float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 16;
        int filter_num[16];
        bool filter_mask[16];
        #pragma unroll
        for (uint p = 0; p < 16; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 1;
            uint channel_num[1];
            #pragma unroll
            for (uint q = 0; q < 1; ++q)
                channel_num[q] = bundle_base + q;

            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p) {
                float from_prev_hp = READ_CHANNEL(detect_to_detect[1][p]);
                float from_sp = READ_CHANNEL(delay_to_detect[2][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[2][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0] > threshold) & filter_mask[0];
            cand[1] = (hsum[1] > threshold) & filter_mask[1];
            cand[2] = (hsum[2] > threshold) & filter_mask[2];
            cand[3] = (hsum[3] > threshold) & filter_mask[3];
            cand[4] = (hsum[4] > threshold) & filter_mask[4];
            cand[5] = (hsum[5] > threshold) & filter_mask[5];
            cand[6] = (hsum[6] > threshold) & filter_mask[6];
            cand[7] = (hsum[7] > threshold) & filter_mask[7];
            cand[8] = (hsum[8] > threshold) & filter_mask[8];
            cand[9] = (hsum[9] > threshold) & filter_mask[9];
            cand[10] = (hsum[10] > threshold) & filter_mask[10];
            cand[11] = (hsum[11] > threshold) & filter_mask[11];
            cand[12] = (hsum[12] > threshold) & filter_mask[12];
            cand[13] = (hsum[13] > threshold) & filter_mask[13];
            cand[14] = (hsum[14] > threshold) & filter_mask[14];
            cand[15] = (hsum[15] > threshold) & filter_mask[15];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(3, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0] : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(3, filter_num[1], channel_num[0]) : invalid_location;
                amp[1] = cand[1] ? hsum[1] : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(3, filter_num[2], channel_num[0]) : invalid_location;
                amp[2] = cand[2] ? hsum[2] : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(3, filter_num[3], channel_num[0]) : invalid_location;
                amp[3] = cand[3] ? hsum[3] : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(3, filter_num[4], channel_num[0]) : invalid_location;
                amp[4] = cand[4] ? hsum[4] : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(3, filter_num[5], channel_num[0]) : invalid_location;
                amp[5] = cand[5] ? hsum[5] : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(3, filter_num[6], channel_num[0]) : invalid_location;
                amp[6] = cand[6] ? hsum[6] : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(3, filter_num[7], channel_num[0]) : invalid_location;
                amp[7] = cand[7] ? hsum[7] : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(3, filter_num[8], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[8] : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(3, filter_num[9], channel_num[0]) : invalid_location;
                amp[9] = cand[9] ? hsum[9] : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(3, filter_num[10], channel_num[0]) : invalid_location;
                amp[10] = cand[10] ? hsum[10] : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(3, filter_num[11], channel_num[0]) : invalid_location;
                amp[11] = cand[11] ? hsum[11] : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(3, filter_num[12], channel_num[0]) : invalid_location;
                amp[12] = cand[12] ? hsum[12] : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(3, filter_num[13], channel_num[0]) : invalid_location;
                amp[13] = cand[13] ? hsum[13] : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(3, filter_num[14], channel_num[0]) : invalid_location;
                amp[14] = cand[14] ? hsum[14] : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(3, filter_num[15], channel_num[0]) : invalid_location;
                amp[15] = cand[15] ? hsum[15] : invalid_amplitude;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
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
                float amplitude = invalid_amplitude;
                if (h < 2) {
                    location = READ_CHANNEL(detect_location_out[1][x]);
                    amplitude = READ_CHANNEL(detect_amplitude_out[1][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    amplitude = amplitude_buffer[d][x];
                }
                WRITE_CHANNEL(detect_location_out[2][x], location);
                WRITE_CHANNEL(detect_amplitude_out[2][x], amplitude);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_4(float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 16;
        int filter_num[16];
        bool filter_mask[16];
        #pragma unroll
        for (uint p = 0; p < 16; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 1;
            uint channel_num[1];
            #pragma unroll
            for (uint q = 0; q < 1; ++q)
                channel_num[q] = bundle_base + q;

            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p) {
                float from_prev_hp = READ_CHANNEL(detect_to_detect[2][p]);
                float from_sp = READ_CHANNEL(delay_to_detect[3][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[3][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0] > threshold) & filter_mask[0];
            cand[1] = (hsum[1] > threshold) & filter_mask[1];
            cand[2] = (hsum[2] > threshold) & filter_mask[2];
            cand[3] = (hsum[3] > threshold) & filter_mask[3];
            cand[4] = (hsum[4] > threshold) & filter_mask[4];
            cand[5] = (hsum[5] > threshold) & filter_mask[5];
            cand[6] = (hsum[6] > threshold) & filter_mask[6];
            cand[7] = (hsum[7] > threshold) & filter_mask[7];
            cand[8] = (hsum[8] > threshold) & filter_mask[8];
            cand[9] = (hsum[9] > threshold) & filter_mask[9];
            cand[10] = (hsum[10] > threshold) & filter_mask[10];
            cand[11] = (hsum[11] > threshold) & filter_mask[11];
            cand[12] = (hsum[12] > threshold) & filter_mask[12];
            cand[13] = (hsum[13] > threshold) & filter_mask[13];
            cand[14] = (hsum[14] > threshold) & filter_mask[14];
            cand[15] = (hsum[15] > threshold) & filter_mask[15];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(4, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0] : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(4, filter_num[1], channel_num[0]) : invalid_location;
                amp[1] = cand[1] ? hsum[1] : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(4, filter_num[2], channel_num[0]) : invalid_location;
                amp[2] = cand[2] ? hsum[2] : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(4, filter_num[3], channel_num[0]) : invalid_location;
                amp[3] = cand[3] ? hsum[3] : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(4, filter_num[4], channel_num[0]) : invalid_location;
                amp[4] = cand[4] ? hsum[4] : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(4, filter_num[5], channel_num[0]) : invalid_location;
                amp[5] = cand[5] ? hsum[5] : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(4, filter_num[6], channel_num[0]) : invalid_location;
                amp[6] = cand[6] ? hsum[6] : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(4, filter_num[7], channel_num[0]) : invalid_location;
                amp[7] = cand[7] ? hsum[7] : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(4, filter_num[8], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[8] : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(4, filter_num[9], channel_num[0]) : invalid_location;
                amp[9] = cand[9] ? hsum[9] : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(4, filter_num[10], channel_num[0]) : invalid_location;
                amp[10] = cand[10] ? hsum[10] : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(4, filter_num[11], channel_num[0]) : invalid_location;
                amp[11] = cand[11] ? hsum[11] : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(4, filter_num[12], channel_num[0]) : invalid_location;
                amp[12] = cand[12] ? hsum[12] : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(4, filter_num[13], channel_num[0]) : invalid_location;
                amp[13] = cand[13] ? hsum[13] : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(4, filter_num[14], channel_num[0]) : invalid_location;
                amp[14] = cand[14] ? hsum[14] : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(4, filter_num[15], channel_num[0]) : invalid_location;
                amp[15] = cand[15] ? hsum[15] : invalid_amplitude;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
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
                float amplitude = invalid_amplitude;
                if (h < 3) {
                    location = READ_CHANNEL(detect_location_out[2][x]);
                    amplitude = READ_CHANNEL(detect_amplitude_out[2][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    amplitude = amplitude_buffer[d][x];
                }
                WRITE_CHANNEL(detect_location_out[3][x], location);
                WRITE_CHANNEL(detect_amplitude_out[3][x], amplitude);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_5(float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 16;
        int filter_num[16];
        bool filter_mask[16];
        #pragma unroll
        for (uint p = 0; p < 16; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 1;
            uint channel_num[1];
            #pragma unroll
            for (uint q = 0; q < 1; ++q)
                channel_num[q] = bundle_base + q;

            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p) {
                float from_prev_hp = READ_CHANNEL(detect_to_detect[3][p]);
                float from_sp = READ_CHANNEL(delay_to_detect[4][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[4][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0] > threshold) & filter_mask[0];
            cand[1] = (hsum[1] > threshold) & filter_mask[1];
            cand[2] = (hsum[2] > threshold) & filter_mask[2];
            cand[3] = (hsum[3] > threshold) & filter_mask[3];
            cand[4] = (hsum[4] > threshold) & filter_mask[4];
            cand[5] = (hsum[5] > threshold) & filter_mask[5];
            cand[6] = (hsum[6] > threshold) & filter_mask[6];
            cand[7] = (hsum[7] > threshold) & filter_mask[7];
            cand[8] = (hsum[8] > threshold) & filter_mask[8];
            cand[9] = (hsum[9] > threshold) & filter_mask[9];
            cand[10] = (hsum[10] > threshold) & filter_mask[10];
            cand[11] = (hsum[11] > threshold) & filter_mask[11];
            cand[12] = (hsum[12] > threshold) & filter_mask[12];
            cand[13] = (hsum[13] > threshold) & filter_mask[13];
            cand[14] = (hsum[14] > threshold) & filter_mask[14];
            cand[15] = (hsum[15] > threshold) & filter_mask[15];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(5, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0] : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(5, filter_num[1], channel_num[0]) : invalid_location;
                amp[1] = cand[1] ? hsum[1] : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(5, filter_num[2], channel_num[0]) : invalid_location;
                amp[2] = cand[2] ? hsum[2] : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(5, filter_num[3], channel_num[0]) : invalid_location;
                amp[3] = cand[3] ? hsum[3] : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(5, filter_num[4], channel_num[0]) : invalid_location;
                amp[4] = cand[4] ? hsum[4] : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(5, filter_num[5], channel_num[0]) : invalid_location;
                amp[5] = cand[5] ? hsum[5] : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(5, filter_num[6], channel_num[0]) : invalid_location;
                amp[6] = cand[6] ? hsum[6] : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(5, filter_num[7], channel_num[0]) : invalid_location;
                amp[7] = cand[7] ? hsum[7] : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(5, filter_num[8], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[8] : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(5, filter_num[9], channel_num[0]) : invalid_location;
                amp[9] = cand[9] ? hsum[9] : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(5, filter_num[10], channel_num[0]) : invalid_location;
                amp[10] = cand[10] ? hsum[10] : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(5, filter_num[11], channel_num[0]) : invalid_location;
                amp[11] = cand[11] ? hsum[11] : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(5, filter_num[12], channel_num[0]) : invalid_location;
                amp[12] = cand[12] ? hsum[12] : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(5, filter_num[13], channel_num[0]) : invalid_location;
                amp[13] = cand[13] ? hsum[13] : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(5, filter_num[14], channel_num[0]) : invalid_location;
                amp[14] = cand[14] ? hsum[14] : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(5, filter_num[15], channel_num[0]) : invalid_location;
                amp[15] = cand[15] ? hsum[15] : invalid_amplitude;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
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
                float amplitude = invalid_amplitude;
                if (h < 4) {
                    location = READ_CHANNEL(detect_location_out[3][x]);
                    amplitude = READ_CHANNEL(detect_amplitude_out[3][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    amplitude = amplitude_buffer[d][x];
                }
                WRITE_CHANNEL(detect_location_out[4][x], location);
                WRITE_CHANNEL(detect_amplitude_out[4][x], amplitude);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_6(float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 16;
        int filter_num[16];
        bool filter_mask[16];
        #pragma unroll
        for (uint p = 0; p < 16; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 1;
            uint channel_num[1];
            #pragma unroll
            for (uint q = 0; q < 1; ++q)
                channel_num[q] = bundle_base + q;

            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p) {
                float from_prev_hp = READ_CHANNEL(detect_to_detect[4][p]);
                float from_sp = READ_CHANNEL(delay_to_detect[5][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[5][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0] > threshold) & filter_mask[0];
            cand[1] = (hsum[1] > threshold) & filter_mask[1];
            cand[2] = (hsum[2] > threshold) & filter_mask[2];
            cand[3] = (hsum[3] > threshold) & filter_mask[3];
            cand[4] = (hsum[4] > threshold) & filter_mask[4];
            cand[5] = (hsum[5] > threshold) & filter_mask[5];
            cand[6] = (hsum[6] > threshold) & filter_mask[6];
            cand[7] = (hsum[7] > threshold) & filter_mask[7];
            cand[8] = (hsum[8] > threshold) & filter_mask[8];
            cand[9] = (hsum[9] > threshold) & filter_mask[9];
            cand[10] = (hsum[10] > threshold) & filter_mask[10];
            cand[11] = (hsum[11] > threshold) & filter_mask[11];
            cand[12] = (hsum[12] > threshold) & filter_mask[12];
            cand[13] = (hsum[13] > threshold) & filter_mask[13];
            cand[14] = (hsum[14] > threshold) & filter_mask[14];
            cand[15] = (hsum[15] > threshold) & filter_mask[15];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(6, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0] : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(6, filter_num[1], channel_num[0]) : invalid_location;
                amp[1] = cand[1] ? hsum[1] : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(6, filter_num[2], channel_num[0]) : invalid_location;
                amp[2] = cand[2] ? hsum[2] : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(6, filter_num[3], channel_num[0]) : invalid_location;
                amp[3] = cand[3] ? hsum[3] : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(6, filter_num[4], channel_num[0]) : invalid_location;
                amp[4] = cand[4] ? hsum[4] : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(6, filter_num[5], channel_num[0]) : invalid_location;
                amp[5] = cand[5] ? hsum[5] : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(6, filter_num[6], channel_num[0]) : invalid_location;
                amp[6] = cand[6] ? hsum[6] : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(6, filter_num[7], channel_num[0]) : invalid_location;
                amp[7] = cand[7] ? hsum[7] : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(6, filter_num[8], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[8] : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(6, filter_num[9], channel_num[0]) : invalid_location;
                amp[9] = cand[9] ? hsum[9] : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(6, filter_num[10], channel_num[0]) : invalid_location;
                amp[10] = cand[10] ? hsum[10] : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(6, filter_num[11], channel_num[0]) : invalid_location;
                amp[11] = cand[11] ? hsum[11] : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(6, filter_num[12], channel_num[0]) : invalid_location;
                amp[12] = cand[12] ? hsum[12] : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(6, filter_num[13], channel_num[0]) : invalid_location;
                amp[13] = cand[13] ? hsum[13] : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(6, filter_num[14], channel_num[0]) : invalid_location;
                amp[14] = cand[14] ? hsum[14] : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(6, filter_num[15], channel_num[0]) : invalid_location;
                amp[15] = cand[15] ? hsum[15] : invalid_amplitude;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
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
                float amplitude = invalid_amplitude;
                if (h < 5) {
                    location = READ_CHANNEL(detect_location_out[4][x]);
                    amplitude = READ_CHANNEL(detect_amplitude_out[4][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    amplitude = amplitude_buffer[d][x];
                }
                WRITE_CHANNEL(detect_location_out[5][x], location);
                WRITE_CHANNEL(detect_amplitude_out[5][x], amplitude);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_7(float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 16;
        int filter_num[16];
        bool filter_mask[16];
        #pragma unroll
        for (uint p = 0; p < 16; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 1;
            uint channel_num[1];
            #pragma unroll
            for (uint q = 0; q < 1; ++q)
                channel_num[q] = bundle_base + q;

            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p) {
                float from_prev_hp = READ_CHANNEL(detect_to_detect[5][p]);
                float from_sp = READ_CHANNEL(delay_to_detect[6][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 16; ++p)
                WRITE_CHANNEL(detect_to_detect[6][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0] > threshold) & filter_mask[0];
            cand[1] = (hsum[1] > threshold) & filter_mask[1];
            cand[2] = (hsum[2] > threshold) & filter_mask[2];
            cand[3] = (hsum[3] > threshold) & filter_mask[3];
            cand[4] = (hsum[4] > threshold) & filter_mask[4];
            cand[5] = (hsum[5] > threshold) & filter_mask[5];
            cand[6] = (hsum[6] > threshold) & filter_mask[6];
            cand[7] = (hsum[7] > threshold) & filter_mask[7];
            cand[8] = (hsum[8] > threshold) & filter_mask[8];
            cand[9] = (hsum[9] > threshold) & filter_mask[9];
            cand[10] = (hsum[10] > threshold) & filter_mask[10];
            cand[11] = (hsum[11] > threshold) & filter_mask[11];
            cand[12] = (hsum[12] > threshold) & filter_mask[12];
            cand[13] = (hsum[13] > threshold) & filter_mask[13];
            cand[14] = (hsum[14] > threshold) & filter_mask[14];
            cand[15] = (hsum[15] > threshold) & filter_mask[15];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(7, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0] : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(7, filter_num[1], channel_num[0]) : invalid_location;
                amp[1] = cand[1] ? hsum[1] : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(7, filter_num[2], channel_num[0]) : invalid_location;
                amp[2] = cand[2] ? hsum[2] : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(7, filter_num[3], channel_num[0]) : invalid_location;
                amp[3] = cand[3] ? hsum[3] : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(7, filter_num[4], channel_num[0]) : invalid_location;
                amp[4] = cand[4] ? hsum[4] : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(7, filter_num[5], channel_num[0]) : invalid_location;
                amp[5] = cand[5] ? hsum[5] : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(7, filter_num[6], channel_num[0]) : invalid_location;
                amp[6] = cand[6] ? hsum[6] : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(7, filter_num[7], channel_num[0]) : invalid_location;
                amp[7] = cand[7] ? hsum[7] : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(7, filter_num[8], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[8] : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(7, filter_num[9], channel_num[0]) : invalid_location;
                amp[9] = cand[9] ? hsum[9] : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(7, filter_num[10], channel_num[0]) : invalid_location;
                amp[10] = cand[10] ? hsum[10] : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(7, filter_num[11], channel_num[0]) : invalid_location;
                amp[11] = cand[11] ? hsum[11] : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(7, filter_num[12], channel_num[0]) : invalid_location;
                amp[12] = cand[12] ? hsum[12] : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(7, filter_num[13], channel_num[0]) : invalid_location;
                amp[13] = cand[13] ? hsum[13] : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(7, filter_num[14], channel_num[0]) : invalid_location;
                amp[14] = cand[14] ? hsum[14] : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(7, filter_num[15], channel_num[0]) : invalid_location;
                amp[15] = cand[15] ? hsum[15] : invalid_amplitude;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
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
                float amplitude = invalid_amplitude;
                if (h < 6) {
                    location = READ_CHANNEL(detect_location_out[5][x]);
                    amplitude = READ_CHANNEL(detect_amplitude_out[5][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    amplitude = amplitude_buffer[d][x];
                }
                WRITE_CHANNEL(detect_location_out[6][x], location);
                WRITE_CHANNEL(detect_amplitude_out[6][x], amplitude);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_8(float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 16;
        int filter_num[16];
        bool filter_mask[16];
        #pragma unroll
        for (uint p = 0; p < 16; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 1;
            uint channel_num[1];
            #pragma unroll
            for (uint q = 0; q < 1; ++q)
                channel_num[q] = bundle_base + q;

            float hsum[16];

            #pragma unroll
            for (uint p = 0; p < 16; ++p) {
                float from_prev_hp = READ_CHANNEL(detect_to_detect[6][p]);
                float from_sp = READ_CHANNEL(delay_to_detect[7][p]);
                hsum[p] = from_prev_hp + from_sp;
            }


            bool cand[16];

            cand[0] = (hsum[0] > threshold) & filter_mask[0];
            cand[1] = (hsum[1] > threshold) & filter_mask[1];
            cand[2] = (hsum[2] > threshold) & filter_mask[2];
            cand[3] = (hsum[3] > threshold) & filter_mask[3];
            cand[4] = (hsum[4] > threshold) & filter_mask[4];
            cand[5] = (hsum[5] > threshold) & filter_mask[5];
            cand[6] = (hsum[6] > threshold) & filter_mask[6];
            cand[7] = (hsum[7] > threshold) & filter_mask[7];
            cand[8] = (hsum[8] > threshold) & filter_mask[8];
            cand[9] = (hsum[9] > threshold) & filter_mask[9];
            cand[10] = (hsum[10] > threshold) & filter_mask[10];
            cand[11] = (hsum[11] > threshold) & filter_mask[11];
            cand[12] = (hsum[12] > threshold) & filter_mask[12];
            cand[13] = (hsum[13] > threshold) & filter_mask[13];
            cand[14] = (hsum[14] > threshold) & filter_mask[14];
            cand[15] = (hsum[15] > threshold) & filter_mask[15];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(8, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0] : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(8, filter_num[1], channel_num[0]) : invalid_location;
                amp[1] = cand[1] ? hsum[1] : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(8, filter_num[2], channel_num[0]) : invalid_location;
                amp[2] = cand[2] ? hsum[2] : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(8, filter_num[3], channel_num[0]) : invalid_location;
                amp[3] = cand[3] ? hsum[3] : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(8, filter_num[4], channel_num[0]) : invalid_location;
                amp[4] = cand[4] ? hsum[4] : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(8, filter_num[5], channel_num[0]) : invalid_location;
                amp[5] = cand[5] ? hsum[5] : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(8, filter_num[6], channel_num[0]) : invalid_location;
                amp[6] = cand[6] ? hsum[6] : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(8, filter_num[7], channel_num[0]) : invalid_location;
                amp[7] = cand[7] ? hsum[7] : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(8, filter_num[8], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[8] : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(8, filter_num[9], channel_num[0]) : invalid_location;
                amp[9] = cand[9] ? hsum[9] : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(8, filter_num[10], channel_num[0]) : invalid_location;
                amp[10] = cand[10] ? hsum[10] : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(8, filter_num[11], channel_num[0]) : invalid_location;
                amp[11] = cand[11] ? hsum[11] : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(8, filter_num[12], channel_num[0]) : invalid_location;
                amp[12] = cand[12] ? hsum[12] : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(8, filter_num[13], channel_num[0]) : invalid_location;
                amp[13] = cand[13] ? hsum[13] : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(8, filter_num[14], channel_num[0]) : invalid_location;
                amp[14] = cand[14] ? hsum[14] : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(8, filter_num[15], channel_num[0]) : invalid_location;
                amp[15] = cand[15] ? hsum[15] : invalid_amplitude;

                uint slot = next;
                next = (next + 1) & 63;

                #pragma unroll
                for (uint x = 0; x < 16; ++x) {
                    location_buffer[slot][x] = loc[x];
                    amplitude_buffer[slot][x] = amp[x];
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
                float amplitude = invalid_amplitude;
                if (h < 7) {
                    location = READ_CHANNEL(detect_location_out[6][x]);
                    amplitude = READ_CHANNEL(detect_amplitude_out[6][x]);
                } else if (is_valid) {
                    location = location_buffer[d][x];
                    amplitude = amplitude_buffer[d][x];
                }
                WRITE_CHANNEL(detect_location_out[7][x], location);
                WRITE_CHANNEL(detect_amplitude_out[7][x], amplitude);
            }
        }
    }
}
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void store_cands(global uint * restrict detection_location,
                        global float * restrict detection_amplitude)
{
    for (uint d = 0; d < 512; ++d) {
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            uint location = READ_CHANNEL(detect_location_out[7][x]);
            float amplitude = READ_CHANNEL(detect_amplitude_out[7][x]);
            detection_location[d * 16 + x] = location;
            detection_amplitude[d * 16 + x] = amplitude;
        }
    }
}
