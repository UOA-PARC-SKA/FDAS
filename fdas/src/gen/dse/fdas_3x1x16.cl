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

channel float2x4 ifft_in[3] __attribute__((depth(0)));
channel float2x4 ifft_out[3] __attribute__((depth(0)));

channel float16 preload_to_delay[8][1] __attribute__((depth(0)));
channel float16 delay_to_detect[8][1] __attribute__((depth(0)));

channel float16 detect_to_detect[7][1] __attribute__((depth(0)));
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
                         const uint n_filters)
{
    const float2x4 zeros = {0, 0, 0, 0};

    float2x4 template_buf_0[512];
    float2x4 template_buf_1[512];
    float2x4 template_buf_2[512];

    for (uint pack = 0; pack < 512; ++pack) {
        float2x4 tmpl_0 = 0 < n_filters ? templates[(42 + filter_0) * 512 + pack] : zeros;
        float2x4 tmpl_1 = 1 < n_filters ? templates[(42 + filter_1) * 512 + pack] : zeros;
        float2x4 tmpl_2 = 2 < n_filters ? templates[(42 + filter_2) * 512 + pack] : zeros;
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
        prods[0] = complex_mult4(load, coeffs[0]);
        prods[1] = complex_mult4(load, coeffs[1]);
        prods[2] = complex_mult4(load, coeffs[2]);

        #pragma unroll
        for (uint e = 0; e < 3; ++e) {
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
kernel void preload_1(global float16 * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 load[1];
    float16 out[1];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;

        out[0] = load[0];

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(preload_to_delay[0][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_1(const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 in[1];
    float16 out[1];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 0 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[0][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s1;
                    out[p].s2 = in[p].s2;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s5;
                    out[p].s6 = in[p].s6;
                    out[p].s7 = in[p].s7;
                    out[p].s8 = in[p].s8;
                    out[p].s9 = in[p].s9;
                    out[p].sA = in[p].sA;
                    out[p].sB = in[p].sB;
                    out[p].sC = in[p].sC;
                    out[p].sD = in[p].sD;
                    out[p].sE = in[p].sE;
                    out[p].sF = in[p].sF;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 1; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(delay_to_detect[0][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_2(global float16 * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 load[1];
    float16 out[1];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;

        out[0] = load[0];

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(preload_to_delay[1][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_2(const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 in[1];
    float16 out[1];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 1 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[1][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s1;
                    out[p].s3 = in[p].s1;
                    out[p].s4 = in[p].s2;
                    out[p].s5 = in[p].s2;
                    out[p].s6 = in[p].s3;
                    out[p].s7 = in[p].s3;
                    out[p].s8 = in[p].s4;
                    out[p].s9 = in[p].s4;
                    out[p].sA = in[p].s5;
                    out[p].sB = in[p].s5;
                    out[p].sC = in[p].s6;
                    out[p].sD = in[p].s6;
                    out[p].sE = in[p].s7;
                    out[p].sF = in[p].s7;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s8;
                    out[p].s1 = in[p].s8;
                    out[p].s2 = in[p].s9;
                    out[p].s3 = in[p].s9;
                    out[p].s4 = in[p].sA;
                    out[p].s5 = in[p].sA;
                    out[p].s6 = in[p].sB;
                    out[p].s7 = in[p].sB;
                    out[p].s8 = in[p].sC;
                    out[p].s9 = in[p].sC;
                    out[p].sA = in[p].sD;
                    out[p].sB = in[p].sD;
                    out[p].sC = in[p].sE;
                    out[p].sD = in[p].sE;
                    out[p].sE = in[p].sF;
                    out[p].sF = in[p].sF;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 1; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(delay_to_detect[1][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_3(global float16 * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 load[1];
    float16 out[1];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;

        out[0] = load[0];

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(preload_to_delay[2][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_3(const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 in[1];
    float16 out[1];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 2 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[2][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s1;
                    out[p].s4 = in[p].s1;
                    out[p].s5 = in[p].s1;
                    out[p].s6 = in[p].s2;
                    out[p].s7 = in[p].s2;
                    out[p].s8 = in[p].s2;
                    out[p].s9 = in[p].s3;
                    out[p].sA = in[p].s3;
                    out[p].sB = in[p].s3;
                    out[p].sC = in[p].s4;
                    out[p].sD = in[p].s4;
                    out[p].sE = in[p].s4;
                    out[p].sF = in[p].s5;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s5;
                    out[p].s1 = in[p].s5;
                    out[p].s2 = in[p].s6;
                    out[p].s3 = in[p].s6;
                    out[p].s4 = in[p].s6;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                    out[p].s8 = in[p].s8;
                    out[p].s9 = in[p].s8;
                    out[p].sA = in[p].s8;
                    out[p].sB = in[p].s9;
                    out[p].sC = in[p].s9;
                    out[p].sD = in[p].s9;
                    out[p].sE = in[p].sA;
                    out[p].sF = in[p].sA;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].sA;
                    out[p].s1 = in[p].sB;
                    out[p].s2 = in[p].sB;
                    out[p].s3 = in[p].sB;
                    out[p].s4 = in[p].sC;
                    out[p].s5 = in[p].sC;
                    out[p].s6 = in[p].sC;
                    out[p].s7 = in[p].sD;
                    out[p].s8 = in[p].sD;
                    out[p].s9 = in[p].sD;
                    out[p].sA = in[p].sE;
                    out[p].sB = in[p].sE;
                    out[p].sC = in[p].sE;
                    out[p].sD = in[p].sF;
                    out[p].sE = in[p].sF;
                    out[p].sF = in[p].sF;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 1; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(delay_to_detect[2][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_4(global float16 * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 load[1];
    float16 out[1];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;

        out[0] = load[0];

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(preload_to_delay[3][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_4(const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 in[1];
    float16 out[1];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 3 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[3][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s1;
                    out[p].s5 = in[p].s1;
                    out[p].s6 = in[p].s1;
                    out[p].s7 = in[p].s1;
                    out[p].s8 = in[p].s2;
                    out[p].s9 = in[p].s2;
                    out[p].sA = in[p].s2;
                    out[p].sB = in[p].s2;
                    out[p].sC = in[p].s3;
                    out[p].sD = in[p].s3;
                    out[p].sE = in[p].s3;
                    out[p].sF = in[p].s3;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s4;
                    out[p].s2 = in[p].s4;
                    out[p].s3 = in[p].s4;
                    out[p].s4 = in[p].s5;
                    out[p].s5 = in[p].s5;
                    out[p].s6 = in[p].s5;
                    out[p].s7 = in[p].s5;
                    out[p].s8 = in[p].s6;
                    out[p].s9 = in[p].s6;
                    out[p].sA = in[p].s6;
                    out[p].sB = in[p].s6;
                    out[p].sC = in[p].s7;
                    out[p].sD = in[p].s7;
                    out[p].sE = in[p].s7;
                    out[p].sF = in[p].s7;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s8;
                    out[p].s1 = in[p].s8;
                    out[p].s2 = in[p].s8;
                    out[p].s3 = in[p].s8;
                    out[p].s4 = in[p].s9;
                    out[p].s5 = in[p].s9;
                    out[p].s6 = in[p].s9;
                    out[p].s7 = in[p].s9;
                    out[p].s8 = in[p].sA;
                    out[p].s9 = in[p].sA;
                    out[p].sA = in[p].sA;
                    out[p].sB = in[p].sA;
                    out[p].sC = in[p].sB;
                    out[p].sD = in[p].sB;
                    out[p].sE = in[p].sB;
                    out[p].sF = in[p].sB;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].sC;
                    out[p].s1 = in[p].sC;
                    out[p].s2 = in[p].sC;
                    out[p].s3 = in[p].sC;
                    out[p].s4 = in[p].sD;
                    out[p].s5 = in[p].sD;
                    out[p].s6 = in[p].sD;
                    out[p].s7 = in[p].sD;
                    out[p].s8 = in[p].sE;
                    out[p].s9 = in[p].sE;
                    out[p].sA = in[p].sE;
                    out[p].sB = in[p].sE;
                    out[p].sC = in[p].sF;
                    out[p].sD = in[p].sF;
                    out[p].sE = in[p].sF;
                    out[p].sF = in[p].sF;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 1; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(delay_to_detect[3][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_5(global float16 * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 load[1];
    float16 out[1];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;

        out[0] = load[0];

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(preload_to_delay[4][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_5(const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 in[1];
    float16 out[1];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 4 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[4][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s0;
                    out[p].s5 = in[p].s1;
                    out[p].s6 = in[p].s1;
                    out[p].s7 = in[p].s1;
                    out[p].s8 = in[p].s1;
                    out[p].s9 = in[p].s1;
                    out[p].sA = in[p].s2;
                    out[p].sB = in[p].s2;
                    out[p].sC = in[p].s2;
                    out[p].sD = in[p].s2;
                    out[p].sE = in[p].s2;
                    out[p].sF = in[p].s3;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s3;
                    out[p].s1 = in[p].s3;
                    out[p].s2 = in[p].s3;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s4;
                    out[p].s6 = in[p].s4;
                    out[p].s7 = in[p].s4;
                    out[p].s8 = in[p].s4;
                    out[p].s9 = in[p].s5;
                    out[p].sA = in[p].s5;
                    out[p].sB = in[p].s5;
                    out[p].sC = in[p].s5;
                    out[p].sD = in[p].s5;
                    out[p].sE = in[p].s6;
                    out[p].sF = in[p].s6;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s6;
                    out[p].s1 = in[p].s6;
                    out[p].s2 = in[p].s6;
                    out[p].s3 = in[p].s7;
                    out[p].s4 = in[p].s7;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                    out[p].s8 = in[p].s8;
                    out[p].s9 = in[p].s8;
                    out[p].sA = in[p].s8;
                    out[p].sB = in[p].s8;
                    out[p].sC = in[p].s8;
                    out[p].sD = in[p].s9;
                    out[p].sE = in[p].s9;
                    out[p].sF = in[p].s9;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s9;
                    out[p].s1 = in[p].s9;
                    out[p].s2 = in[p].sA;
                    out[p].s3 = in[p].sA;
                    out[p].s4 = in[p].sA;
                    out[p].s5 = in[p].sA;
                    out[p].s6 = in[p].sA;
                    out[p].s7 = in[p].sB;
                    out[p].s8 = in[p].sB;
                    out[p].s9 = in[p].sB;
                    out[p].sA = in[p].sB;
                    out[p].sB = in[p].sB;
                    out[p].sC = in[p].sC;
                    out[p].sD = in[p].sC;
                    out[p].sE = in[p].sC;
                    out[p].sF = in[p].sC;
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].sC;
                    out[p].s1 = in[p].sD;
                    out[p].s2 = in[p].sD;
                    out[p].s3 = in[p].sD;
                    out[p].s4 = in[p].sD;
                    out[p].s5 = in[p].sD;
                    out[p].s6 = in[p].sE;
                    out[p].s7 = in[p].sE;
                    out[p].s8 = in[p].sE;
                    out[p].s9 = in[p].sE;
                    out[p].sA = in[p].sE;
                    out[p].sB = in[p].sF;
                    out[p].sC = in[p].sF;
                    out[p].sD = in[p].sF;
                    out[p].sE = in[p].sF;
                    out[p].sF = in[p].sF;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 1; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(delay_to_detect[4][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_6(global float16 * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 load[1];
    float16 out[1];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;

        out[0] = load[0];

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(preload_to_delay[5][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_6(const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 in[1];
    float16 out[1];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 5 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[5][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s0;
                    out[p].s5 = in[p].s0;
                    out[p].s6 = in[p].s1;
                    out[p].s7 = in[p].s1;
                    out[p].s8 = in[p].s1;
                    out[p].s9 = in[p].s1;
                    out[p].sA = in[p].s1;
                    out[p].sB = in[p].s1;
                    out[p].sC = in[p].s2;
                    out[p].sD = in[p].s2;
                    out[p].sE = in[p].s2;
                    out[p].sF = in[p].s2;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s2;
                    out[p].s1 = in[p].s2;
                    out[p].s2 = in[p].s3;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s3;
                    out[p].s5 = in[p].s3;
                    out[p].s6 = in[p].s3;
                    out[p].s7 = in[p].s3;
                    out[p].s8 = in[p].s4;
                    out[p].s9 = in[p].s4;
                    out[p].sA = in[p].s4;
                    out[p].sB = in[p].s4;
                    out[p].sC = in[p].s4;
                    out[p].sD = in[p].s4;
                    out[p].sE = in[p].s5;
                    out[p].sF = in[p].s5;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s5;
                    out[p].s1 = in[p].s5;
                    out[p].s2 = in[p].s5;
                    out[p].s3 = in[p].s5;
                    out[p].s4 = in[p].s6;
                    out[p].s5 = in[p].s6;
                    out[p].s6 = in[p].s6;
                    out[p].s7 = in[p].s6;
                    out[p].s8 = in[p].s6;
                    out[p].s9 = in[p].s6;
                    out[p].sA = in[p].s7;
                    out[p].sB = in[p].s7;
                    out[p].sC = in[p].s7;
                    out[p].sD = in[p].s7;
                    out[p].sE = in[p].s7;
                    out[p].sF = in[p].s7;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s8;
                    out[p].s1 = in[p].s8;
                    out[p].s2 = in[p].s8;
                    out[p].s3 = in[p].s8;
                    out[p].s4 = in[p].s8;
                    out[p].s5 = in[p].s8;
                    out[p].s6 = in[p].s9;
                    out[p].s7 = in[p].s9;
                    out[p].s8 = in[p].s9;
                    out[p].s9 = in[p].s9;
                    out[p].sA = in[p].s9;
                    out[p].sB = in[p].s9;
                    out[p].sC = in[p].sA;
                    out[p].sD = in[p].sA;
                    out[p].sE = in[p].sA;
                    out[p].sF = in[p].sA;
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].sA;
                    out[p].s1 = in[p].sA;
                    out[p].s2 = in[p].sB;
                    out[p].s3 = in[p].sB;
                    out[p].s4 = in[p].sB;
                    out[p].s5 = in[p].sB;
                    out[p].s6 = in[p].sB;
                    out[p].s7 = in[p].sB;
                    out[p].s8 = in[p].sC;
                    out[p].s9 = in[p].sC;
                    out[p].sA = in[p].sC;
                    out[p].sB = in[p].sC;
                    out[p].sC = in[p].sC;
                    out[p].sD = in[p].sC;
                    out[p].sE = in[p].sD;
                    out[p].sF = in[p].sD;
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].sD;
                    out[p].s1 = in[p].sD;
                    out[p].s2 = in[p].sD;
                    out[p].s3 = in[p].sD;
                    out[p].s4 = in[p].sE;
                    out[p].s5 = in[p].sE;
                    out[p].s6 = in[p].sE;
                    out[p].s7 = in[p].sE;
                    out[p].s8 = in[p].sE;
                    out[p].s9 = in[p].sE;
                    out[p].sA = in[p].sF;
                    out[p].sB = in[p].sF;
                    out[p].sC = in[p].sF;
                    out[p].sD = in[p].sF;
                    out[p].sE = in[p].sF;
                    out[p].sF = in[p].sF;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 1; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(delay_to_detect[5][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_7(global float16 * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 load[1];
    float16 out[1];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;

        out[0] = load[0];

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(preload_to_delay[6][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_7(const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 in[1];
    float16 out[1];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 6 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[6][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s0;
                    out[p].s5 = in[p].s0;
                    out[p].s6 = in[p].s0;
                    out[p].s7 = in[p].s1;
                    out[p].s8 = in[p].s1;
                    out[p].s9 = in[p].s1;
                    out[p].sA = in[p].s1;
                    out[p].sB = in[p].s1;
                    out[p].sC = in[p].s1;
                    out[p].sD = in[p].s1;
                    out[p].sE = in[p].s2;
                    out[p].sF = in[p].s2;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s2;
                    out[p].s1 = in[p].s2;
                    out[p].s2 = in[p].s2;
                    out[p].s3 = in[p].s2;
                    out[p].s4 = in[p].s2;
                    out[p].s5 = in[p].s3;
                    out[p].s6 = in[p].s3;
                    out[p].s7 = in[p].s3;
                    out[p].s8 = in[p].s3;
                    out[p].s9 = in[p].s3;
                    out[p].sA = in[p].s3;
                    out[p].sB = in[p].s3;
                    out[p].sC = in[p].s4;
                    out[p].sD = in[p].s4;
                    out[p].sE = in[p].s4;
                    out[p].sF = in[p].s4;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s4;
                    out[p].s2 = in[p].s4;
                    out[p].s3 = in[p].s5;
                    out[p].s4 = in[p].s5;
                    out[p].s5 = in[p].s5;
                    out[p].s6 = in[p].s5;
                    out[p].s7 = in[p].s5;
                    out[p].s8 = in[p].s5;
                    out[p].s9 = in[p].s5;
                    out[p].sA = in[p].s6;
                    out[p].sB = in[p].s6;
                    out[p].sC = in[p].s6;
                    out[p].sD = in[p].s6;
                    out[p].sE = in[p].s6;
                    out[p].sF = in[p].s6;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s6;
                    out[p].s1 = in[p].s7;
                    out[p].s2 = in[p].s7;
                    out[p].s3 = in[p].s7;
                    out[p].s4 = in[p].s7;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                    out[p].s8 = in[p].s8;
                    out[p].s9 = in[p].s8;
                    out[p].sA = in[p].s8;
                    out[p].sB = in[p].s8;
                    out[p].sC = in[p].s8;
                    out[p].sD = in[p].s8;
                    out[p].sE = in[p].s8;
                    out[p].sF = in[p].s9;
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s9;
                    out[p].s1 = in[p].s9;
                    out[p].s2 = in[p].s9;
                    out[p].s3 = in[p].s9;
                    out[p].s4 = in[p].s9;
                    out[p].s5 = in[p].s9;
                    out[p].s6 = in[p].sA;
                    out[p].s7 = in[p].sA;
                    out[p].s8 = in[p].sA;
                    out[p].s9 = in[p].sA;
                    out[p].sA = in[p].sA;
                    out[p].sB = in[p].sA;
                    out[p].sC = in[p].sA;
                    out[p].sD = in[p].sB;
                    out[p].sE = in[p].sB;
                    out[p].sF = in[p].sB;
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].sB;
                    out[p].s1 = in[p].sB;
                    out[p].s2 = in[p].sB;
                    out[p].s3 = in[p].sB;
                    out[p].s4 = in[p].sC;
                    out[p].s5 = in[p].sC;
                    out[p].s6 = in[p].sC;
                    out[p].s7 = in[p].sC;
                    out[p].s8 = in[p].sC;
                    out[p].s9 = in[p].sC;
                    out[p].sA = in[p].sC;
                    out[p].sB = in[p].sD;
                    out[p].sC = in[p].sD;
                    out[p].sD = in[p].sD;
                    out[p].sE = in[p].sD;
                    out[p].sF = in[p].sD;
                }
                break;
            case 6:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].sD;
                    out[p].s1 = in[p].sD;
                    out[p].s2 = in[p].sE;
                    out[p].s3 = in[p].sE;
                    out[p].s4 = in[p].sE;
                    out[p].s5 = in[p].sE;
                    out[p].s6 = in[p].sE;
                    out[p].s7 = in[p].sE;
                    out[p].s8 = in[p].sE;
                    out[p].s9 = in[p].sF;
                    out[p].sA = in[p].sF;
                    out[p].sB = in[p].sF;
                    out[p].sC = in[p].sF;
                    out[p].sD = in[p].sF;
                    out[p].sE = in[p].sF;
                    out[p].sF = in[p].sF;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 1; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(delay_to_detect[6][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_8(global float16 * restrict fop,
                      const uint n_rows,
                      const uint base_row_rem,
                      const uint filter_offset_0,
                      const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 load[1];
    float16 out[1];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[filter_offset_0 + bundle] : zeros;

        out[0] = load[0];

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
            WRITE_CHANNEL(preload_to_delay[7][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_8(const uint n_channel_bundles)
{
    const float16 zeros = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    float16 in[1];
    float16 out[1];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 7 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[7][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s0;
                    out[p].s5 = in[p].s0;
                    out[p].s6 = in[p].s0;
                    out[p].s7 = in[p].s0;
                    out[p].s8 = in[p].s1;
                    out[p].s9 = in[p].s1;
                    out[p].sA = in[p].s1;
                    out[p].sB = in[p].s1;
                    out[p].sC = in[p].s1;
                    out[p].sD = in[p].s1;
                    out[p].sE = in[p].s1;
                    out[p].sF = in[p].s1;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s2;
                    out[p].s1 = in[p].s2;
                    out[p].s2 = in[p].s2;
                    out[p].s3 = in[p].s2;
                    out[p].s4 = in[p].s2;
                    out[p].s5 = in[p].s2;
                    out[p].s6 = in[p].s2;
                    out[p].s7 = in[p].s2;
                    out[p].s8 = in[p].s3;
                    out[p].s9 = in[p].s3;
                    out[p].sA = in[p].s3;
                    out[p].sB = in[p].s3;
                    out[p].sC = in[p].s3;
                    out[p].sD = in[p].s3;
                    out[p].sE = in[p].s3;
                    out[p].sF = in[p].s3;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s4;
                    out[p].s2 = in[p].s4;
                    out[p].s3 = in[p].s4;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s4;
                    out[p].s6 = in[p].s4;
                    out[p].s7 = in[p].s4;
                    out[p].s8 = in[p].s5;
                    out[p].s9 = in[p].s5;
                    out[p].sA = in[p].s5;
                    out[p].sB = in[p].s5;
                    out[p].sC = in[p].s5;
                    out[p].sD = in[p].s5;
                    out[p].sE = in[p].s5;
                    out[p].sF = in[p].s5;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s6;
                    out[p].s1 = in[p].s6;
                    out[p].s2 = in[p].s6;
                    out[p].s3 = in[p].s6;
                    out[p].s4 = in[p].s6;
                    out[p].s5 = in[p].s6;
                    out[p].s6 = in[p].s6;
                    out[p].s7 = in[p].s6;
                    out[p].s8 = in[p].s7;
                    out[p].s9 = in[p].s7;
                    out[p].sA = in[p].s7;
                    out[p].sB = in[p].s7;
                    out[p].sC = in[p].s7;
                    out[p].sD = in[p].s7;
                    out[p].sE = in[p].s7;
                    out[p].sF = in[p].s7;
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].s8;
                    out[p].s1 = in[p].s8;
                    out[p].s2 = in[p].s8;
                    out[p].s3 = in[p].s8;
                    out[p].s4 = in[p].s8;
                    out[p].s5 = in[p].s8;
                    out[p].s6 = in[p].s8;
                    out[p].s7 = in[p].s8;
                    out[p].s8 = in[p].s9;
                    out[p].s9 = in[p].s9;
                    out[p].sA = in[p].s9;
                    out[p].sB = in[p].s9;
                    out[p].sC = in[p].s9;
                    out[p].sD = in[p].s9;
                    out[p].sE = in[p].s9;
                    out[p].sF = in[p].s9;
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].sA;
                    out[p].s1 = in[p].sA;
                    out[p].s2 = in[p].sA;
                    out[p].s3 = in[p].sA;
                    out[p].s4 = in[p].sA;
                    out[p].s5 = in[p].sA;
                    out[p].s6 = in[p].sA;
                    out[p].s7 = in[p].sA;
                    out[p].s8 = in[p].sB;
                    out[p].s9 = in[p].sB;
                    out[p].sA = in[p].sB;
                    out[p].sB = in[p].sB;
                    out[p].sC = in[p].sB;
                    out[p].sD = in[p].sB;
                    out[p].sE = in[p].sB;
                    out[p].sF = in[p].sB;
                }
                break;
            case 6:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].sC;
                    out[p].s1 = in[p].sC;
                    out[p].s2 = in[p].sC;
                    out[p].s3 = in[p].sC;
                    out[p].s4 = in[p].sC;
                    out[p].s5 = in[p].sC;
                    out[p].s6 = in[p].sC;
                    out[p].s7 = in[p].sC;
                    out[p].s8 = in[p].sD;
                    out[p].s9 = in[p].sD;
                    out[p].sA = in[p].sD;
                    out[p].sB = in[p].sD;
                    out[p].sC = in[p].sD;
                    out[p].sD = in[p].sD;
                    out[p].sE = in[p].sD;
                    out[p].sF = in[p].sD;
                }
                break;
            case 7:
                #pragma unroll
                for (uint p = 0; p < 1; ++p) {
                    out[p].s0 = in[p].sE;
                    out[p].s1 = in[p].sE;
                    out[p].s2 = in[p].sE;
                    out[p].s3 = in[p].sE;
                    out[p].s4 = in[p].sE;
                    out[p].s5 = in[p].sE;
                    out[p].s6 = in[p].sE;
                    out[p].s7 = in[p].sE;
                    out[p].s8 = in[p].sF;
                    out[p].s9 = in[p].sF;
                    out[p].sA = in[p].sF;
                    out[p].sB = in[p].sF;
                    out[p].sC = in[p].sF;
                    out[p].sD = in[p].sF;
                    out[p].sE = in[p].sF;
                    out[p].sF = in[p].sF;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 1; ++p)
                    out[p] = zeros;
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 1; ++p)
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
        uint group_base = group * 1;
        int filter_num[1];
        bool filter_mask[1];
        #pragma unroll
        for (uint p = 0; p < 1; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 16;
            uint channel_num[16];
            #pragma unroll
            for (uint q = 0; q < 16; ++q)
                channel_num[q] = bundle_base + q;

            float16 hsum[1];

            #pragma unroll
            for (uint p = 0; p < 1; ++p) {
                float16 from_fop = READ_CHANNEL(delay_to_detect[0][p]);
                hsum[p] = from_fop;
            }

            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                WRITE_CHANNEL(detect_to_detect[0][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[0].s8 > threshold) & filter_mask[0];
            cand[9] = (hsum[0].s9 > threshold) & filter_mask[0];
            cand[10] = (hsum[0].sA > threshold) & filter_mask[0];
            cand[11] = (hsum[0].sB > threshold) & filter_mask[0];
            cand[12] = (hsum[0].sC > threshold) & filter_mask[0];
            cand[13] = (hsum[0].sD > threshold) & filter_mask[0];
            cand[14] = (hsum[0].sE > threshold) & filter_mask[0];
            cand[15] = (hsum[0].sF > threshold) & filter_mask[0];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(1, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0].s0 : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(1, filter_num[0], channel_num[1]) : invalid_location;
                amp[1] = cand[1] ? hsum[0].s1 : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(1, filter_num[0], channel_num[2]) : invalid_location;
                amp[2] = cand[2] ? hsum[0].s2 : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(1, filter_num[0], channel_num[3]) : invalid_location;
                amp[3] = cand[3] ? hsum[0].s3 : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(1, filter_num[0], channel_num[4]) : invalid_location;
                amp[4] = cand[4] ? hsum[0].s4 : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(1, filter_num[0], channel_num[5]) : invalid_location;
                amp[5] = cand[5] ? hsum[0].s5 : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(1, filter_num[0], channel_num[6]) : invalid_location;
                amp[6] = cand[6] ? hsum[0].s6 : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(1, filter_num[0], channel_num[7]) : invalid_location;
                amp[7] = cand[7] ? hsum[0].s7 : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(1, filter_num[0], channel_num[8]) : invalid_location;
                amp[8] = cand[8] ? hsum[0].s8 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(1, filter_num[0], channel_num[9]) : invalid_location;
                amp[9] = cand[9] ? hsum[0].s9 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(1, filter_num[0], channel_num[10]) : invalid_location;
                amp[10] = cand[10] ? hsum[0].sA : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(1, filter_num[0], channel_num[11]) : invalid_location;
                amp[11] = cand[11] ? hsum[0].sB : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(1, filter_num[0], channel_num[12]) : invalid_location;
                amp[12] = cand[12] ? hsum[0].sC : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(1, filter_num[0], channel_num[13]) : invalid_location;
                amp[13] = cand[13] ? hsum[0].sD : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(1, filter_num[0], channel_num[14]) : invalid_location;
                amp[14] = cand[14] ? hsum[0].sE : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(1, filter_num[0], channel_num[15]) : invalid_location;
                amp[15] = cand[15] ? hsum[0].sF : invalid_amplitude;

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
        uint group_base = group * 1;
        int filter_num[1];
        bool filter_mask[1];
        #pragma unroll
        for (uint p = 0; p < 1; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 16;
            uint channel_num[16];
            #pragma unroll
            for (uint q = 0; q < 16; ++q)
                channel_num[q] = bundle_base + q;

            float16 hsum[1];

            #pragma unroll
            for (uint p = 0; p < 1; ++p) {
                float16 from_prev_hp = READ_CHANNEL(detect_to_detect[0][p]);
                float16 from_sp = READ_CHANNEL(delay_to_detect[1][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                WRITE_CHANNEL(detect_to_detect[1][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[0].s8 > threshold) & filter_mask[0];
            cand[9] = (hsum[0].s9 > threshold) & filter_mask[0];
            cand[10] = (hsum[0].sA > threshold) & filter_mask[0];
            cand[11] = (hsum[0].sB > threshold) & filter_mask[0];
            cand[12] = (hsum[0].sC > threshold) & filter_mask[0];
            cand[13] = (hsum[0].sD > threshold) & filter_mask[0];
            cand[14] = (hsum[0].sE > threshold) & filter_mask[0];
            cand[15] = (hsum[0].sF > threshold) & filter_mask[0];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(2, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0].s0 : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(2, filter_num[0], channel_num[1]) : invalid_location;
                amp[1] = cand[1] ? hsum[0].s1 : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(2, filter_num[0], channel_num[2]) : invalid_location;
                amp[2] = cand[2] ? hsum[0].s2 : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(2, filter_num[0], channel_num[3]) : invalid_location;
                amp[3] = cand[3] ? hsum[0].s3 : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(2, filter_num[0], channel_num[4]) : invalid_location;
                amp[4] = cand[4] ? hsum[0].s4 : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(2, filter_num[0], channel_num[5]) : invalid_location;
                amp[5] = cand[5] ? hsum[0].s5 : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(2, filter_num[0], channel_num[6]) : invalid_location;
                amp[6] = cand[6] ? hsum[0].s6 : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(2, filter_num[0], channel_num[7]) : invalid_location;
                amp[7] = cand[7] ? hsum[0].s7 : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(2, filter_num[0], channel_num[8]) : invalid_location;
                amp[8] = cand[8] ? hsum[0].s8 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(2, filter_num[0], channel_num[9]) : invalid_location;
                amp[9] = cand[9] ? hsum[0].s9 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(2, filter_num[0], channel_num[10]) : invalid_location;
                amp[10] = cand[10] ? hsum[0].sA : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(2, filter_num[0], channel_num[11]) : invalid_location;
                amp[11] = cand[11] ? hsum[0].sB : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(2, filter_num[0], channel_num[12]) : invalid_location;
                amp[12] = cand[12] ? hsum[0].sC : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(2, filter_num[0], channel_num[13]) : invalid_location;
                amp[13] = cand[13] ? hsum[0].sD : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(2, filter_num[0], channel_num[14]) : invalid_location;
                amp[14] = cand[14] ? hsum[0].sE : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(2, filter_num[0], channel_num[15]) : invalid_location;
                amp[15] = cand[15] ? hsum[0].sF : invalid_amplitude;

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
        uint group_base = group * 1;
        int filter_num[1];
        bool filter_mask[1];
        #pragma unroll
        for (uint p = 0; p < 1; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 16;
            uint channel_num[16];
            #pragma unroll
            for (uint q = 0; q < 16; ++q)
                channel_num[q] = bundle_base + q;

            float16 hsum[1];

            #pragma unroll
            for (uint p = 0; p < 1; ++p) {
                float16 from_prev_hp = READ_CHANNEL(detect_to_detect[1][p]);
                float16 from_sp = READ_CHANNEL(delay_to_detect[2][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                WRITE_CHANNEL(detect_to_detect[2][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[0].s8 > threshold) & filter_mask[0];
            cand[9] = (hsum[0].s9 > threshold) & filter_mask[0];
            cand[10] = (hsum[0].sA > threshold) & filter_mask[0];
            cand[11] = (hsum[0].sB > threshold) & filter_mask[0];
            cand[12] = (hsum[0].sC > threshold) & filter_mask[0];
            cand[13] = (hsum[0].sD > threshold) & filter_mask[0];
            cand[14] = (hsum[0].sE > threshold) & filter_mask[0];
            cand[15] = (hsum[0].sF > threshold) & filter_mask[0];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(3, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0].s0 : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(3, filter_num[0], channel_num[1]) : invalid_location;
                amp[1] = cand[1] ? hsum[0].s1 : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(3, filter_num[0], channel_num[2]) : invalid_location;
                amp[2] = cand[2] ? hsum[0].s2 : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(3, filter_num[0], channel_num[3]) : invalid_location;
                amp[3] = cand[3] ? hsum[0].s3 : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(3, filter_num[0], channel_num[4]) : invalid_location;
                amp[4] = cand[4] ? hsum[0].s4 : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(3, filter_num[0], channel_num[5]) : invalid_location;
                amp[5] = cand[5] ? hsum[0].s5 : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(3, filter_num[0], channel_num[6]) : invalid_location;
                amp[6] = cand[6] ? hsum[0].s6 : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(3, filter_num[0], channel_num[7]) : invalid_location;
                amp[7] = cand[7] ? hsum[0].s7 : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(3, filter_num[0], channel_num[8]) : invalid_location;
                amp[8] = cand[8] ? hsum[0].s8 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(3, filter_num[0], channel_num[9]) : invalid_location;
                amp[9] = cand[9] ? hsum[0].s9 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(3, filter_num[0], channel_num[10]) : invalid_location;
                amp[10] = cand[10] ? hsum[0].sA : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(3, filter_num[0], channel_num[11]) : invalid_location;
                amp[11] = cand[11] ? hsum[0].sB : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(3, filter_num[0], channel_num[12]) : invalid_location;
                amp[12] = cand[12] ? hsum[0].sC : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(3, filter_num[0], channel_num[13]) : invalid_location;
                amp[13] = cand[13] ? hsum[0].sD : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(3, filter_num[0], channel_num[14]) : invalid_location;
                amp[14] = cand[14] ? hsum[0].sE : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(3, filter_num[0], channel_num[15]) : invalid_location;
                amp[15] = cand[15] ? hsum[0].sF : invalid_amplitude;

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
        uint group_base = group * 1;
        int filter_num[1];
        bool filter_mask[1];
        #pragma unroll
        for (uint p = 0; p < 1; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 16;
            uint channel_num[16];
            #pragma unroll
            for (uint q = 0; q < 16; ++q)
                channel_num[q] = bundle_base + q;

            float16 hsum[1];

            #pragma unroll
            for (uint p = 0; p < 1; ++p) {
                float16 from_prev_hp = READ_CHANNEL(detect_to_detect[2][p]);
                float16 from_sp = READ_CHANNEL(delay_to_detect[3][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                WRITE_CHANNEL(detect_to_detect[3][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[0].s8 > threshold) & filter_mask[0];
            cand[9] = (hsum[0].s9 > threshold) & filter_mask[0];
            cand[10] = (hsum[0].sA > threshold) & filter_mask[0];
            cand[11] = (hsum[0].sB > threshold) & filter_mask[0];
            cand[12] = (hsum[0].sC > threshold) & filter_mask[0];
            cand[13] = (hsum[0].sD > threshold) & filter_mask[0];
            cand[14] = (hsum[0].sE > threshold) & filter_mask[0];
            cand[15] = (hsum[0].sF > threshold) & filter_mask[0];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(4, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0].s0 : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(4, filter_num[0], channel_num[1]) : invalid_location;
                amp[1] = cand[1] ? hsum[0].s1 : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(4, filter_num[0], channel_num[2]) : invalid_location;
                amp[2] = cand[2] ? hsum[0].s2 : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(4, filter_num[0], channel_num[3]) : invalid_location;
                amp[3] = cand[3] ? hsum[0].s3 : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(4, filter_num[0], channel_num[4]) : invalid_location;
                amp[4] = cand[4] ? hsum[0].s4 : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(4, filter_num[0], channel_num[5]) : invalid_location;
                amp[5] = cand[5] ? hsum[0].s5 : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(4, filter_num[0], channel_num[6]) : invalid_location;
                amp[6] = cand[6] ? hsum[0].s6 : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(4, filter_num[0], channel_num[7]) : invalid_location;
                amp[7] = cand[7] ? hsum[0].s7 : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(4, filter_num[0], channel_num[8]) : invalid_location;
                amp[8] = cand[8] ? hsum[0].s8 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(4, filter_num[0], channel_num[9]) : invalid_location;
                amp[9] = cand[9] ? hsum[0].s9 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(4, filter_num[0], channel_num[10]) : invalid_location;
                amp[10] = cand[10] ? hsum[0].sA : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(4, filter_num[0], channel_num[11]) : invalid_location;
                amp[11] = cand[11] ? hsum[0].sB : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(4, filter_num[0], channel_num[12]) : invalid_location;
                amp[12] = cand[12] ? hsum[0].sC : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(4, filter_num[0], channel_num[13]) : invalid_location;
                amp[13] = cand[13] ? hsum[0].sD : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(4, filter_num[0], channel_num[14]) : invalid_location;
                amp[14] = cand[14] ? hsum[0].sE : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(4, filter_num[0], channel_num[15]) : invalid_location;
                amp[15] = cand[15] ? hsum[0].sF : invalid_amplitude;

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
        uint group_base = group * 1;
        int filter_num[1];
        bool filter_mask[1];
        #pragma unroll
        for (uint p = 0; p < 1; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 16;
            uint channel_num[16];
            #pragma unroll
            for (uint q = 0; q < 16; ++q)
                channel_num[q] = bundle_base + q;

            float16 hsum[1];

            #pragma unroll
            for (uint p = 0; p < 1; ++p) {
                float16 from_prev_hp = READ_CHANNEL(detect_to_detect[3][p]);
                float16 from_sp = READ_CHANNEL(delay_to_detect[4][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                WRITE_CHANNEL(detect_to_detect[4][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[0].s8 > threshold) & filter_mask[0];
            cand[9] = (hsum[0].s9 > threshold) & filter_mask[0];
            cand[10] = (hsum[0].sA > threshold) & filter_mask[0];
            cand[11] = (hsum[0].sB > threshold) & filter_mask[0];
            cand[12] = (hsum[0].sC > threshold) & filter_mask[0];
            cand[13] = (hsum[0].sD > threshold) & filter_mask[0];
            cand[14] = (hsum[0].sE > threshold) & filter_mask[0];
            cand[15] = (hsum[0].sF > threshold) & filter_mask[0];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(5, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0].s0 : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(5, filter_num[0], channel_num[1]) : invalid_location;
                amp[1] = cand[1] ? hsum[0].s1 : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(5, filter_num[0], channel_num[2]) : invalid_location;
                amp[2] = cand[2] ? hsum[0].s2 : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(5, filter_num[0], channel_num[3]) : invalid_location;
                amp[3] = cand[3] ? hsum[0].s3 : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(5, filter_num[0], channel_num[4]) : invalid_location;
                amp[4] = cand[4] ? hsum[0].s4 : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(5, filter_num[0], channel_num[5]) : invalid_location;
                amp[5] = cand[5] ? hsum[0].s5 : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(5, filter_num[0], channel_num[6]) : invalid_location;
                amp[6] = cand[6] ? hsum[0].s6 : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(5, filter_num[0], channel_num[7]) : invalid_location;
                amp[7] = cand[7] ? hsum[0].s7 : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(5, filter_num[0], channel_num[8]) : invalid_location;
                amp[8] = cand[8] ? hsum[0].s8 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(5, filter_num[0], channel_num[9]) : invalid_location;
                amp[9] = cand[9] ? hsum[0].s9 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(5, filter_num[0], channel_num[10]) : invalid_location;
                amp[10] = cand[10] ? hsum[0].sA : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(5, filter_num[0], channel_num[11]) : invalid_location;
                amp[11] = cand[11] ? hsum[0].sB : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(5, filter_num[0], channel_num[12]) : invalid_location;
                amp[12] = cand[12] ? hsum[0].sC : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(5, filter_num[0], channel_num[13]) : invalid_location;
                amp[13] = cand[13] ? hsum[0].sD : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(5, filter_num[0], channel_num[14]) : invalid_location;
                amp[14] = cand[14] ? hsum[0].sE : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(5, filter_num[0], channel_num[15]) : invalid_location;
                amp[15] = cand[15] ? hsum[0].sF : invalid_amplitude;

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
        uint group_base = group * 1;
        int filter_num[1];
        bool filter_mask[1];
        #pragma unroll
        for (uint p = 0; p < 1; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 16;
            uint channel_num[16];
            #pragma unroll
            for (uint q = 0; q < 16; ++q)
                channel_num[q] = bundle_base + q;

            float16 hsum[1];

            #pragma unroll
            for (uint p = 0; p < 1; ++p) {
                float16 from_prev_hp = READ_CHANNEL(detect_to_detect[4][p]);
                float16 from_sp = READ_CHANNEL(delay_to_detect[5][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                WRITE_CHANNEL(detect_to_detect[5][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[0].s8 > threshold) & filter_mask[0];
            cand[9] = (hsum[0].s9 > threshold) & filter_mask[0];
            cand[10] = (hsum[0].sA > threshold) & filter_mask[0];
            cand[11] = (hsum[0].sB > threshold) & filter_mask[0];
            cand[12] = (hsum[0].sC > threshold) & filter_mask[0];
            cand[13] = (hsum[0].sD > threshold) & filter_mask[0];
            cand[14] = (hsum[0].sE > threshold) & filter_mask[0];
            cand[15] = (hsum[0].sF > threshold) & filter_mask[0];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(6, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0].s0 : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(6, filter_num[0], channel_num[1]) : invalid_location;
                amp[1] = cand[1] ? hsum[0].s1 : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(6, filter_num[0], channel_num[2]) : invalid_location;
                amp[2] = cand[2] ? hsum[0].s2 : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(6, filter_num[0], channel_num[3]) : invalid_location;
                amp[3] = cand[3] ? hsum[0].s3 : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(6, filter_num[0], channel_num[4]) : invalid_location;
                amp[4] = cand[4] ? hsum[0].s4 : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(6, filter_num[0], channel_num[5]) : invalid_location;
                amp[5] = cand[5] ? hsum[0].s5 : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(6, filter_num[0], channel_num[6]) : invalid_location;
                amp[6] = cand[6] ? hsum[0].s6 : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(6, filter_num[0], channel_num[7]) : invalid_location;
                amp[7] = cand[7] ? hsum[0].s7 : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(6, filter_num[0], channel_num[8]) : invalid_location;
                amp[8] = cand[8] ? hsum[0].s8 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(6, filter_num[0], channel_num[9]) : invalid_location;
                amp[9] = cand[9] ? hsum[0].s9 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(6, filter_num[0], channel_num[10]) : invalid_location;
                amp[10] = cand[10] ? hsum[0].sA : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(6, filter_num[0], channel_num[11]) : invalid_location;
                amp[11] = cand[11] ? hsum[0].sB : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(6, filter_num[0], channel_num[12]) : invalid_location;
                amp[12] = cand[12] ? hsum[0].sC : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(6, filter_num[0], channel_num[13]) : invalid_location;
                amp[13] = cand[13] ? hsum[0].sD : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(6, filter_num[0], channel_num[14]) : invalid_location;
                amp[14] = cand[14] ? hsum[0].sE : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(6, filter_num[0], channel_num[15]) : invalid_location;
                amp[15] = cand[15] ? hsum[0].sF : invalid_amplitude;

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
        uint group_base = group * 1;
        int filter_num[1];
        bool filter_mask[1];
        #pragma unroll
        for (uint p = 0; p < 1; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 16;
            uint channel_num[16];
            #pragma unroll
            for (uint q = 0; q < 16; ++q)
                channel_num[q] = bundle_base + q;

            float16 hsum[1];

            #pragma unroll
            for (uint p = 0; p < 1; ++p) {
                float16 from_prev_hp = READ_CHANNEL(detect_to_detect[5][p]);
                float16 from_sp = READ_CHANNEL(delay_to_detect[6][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 1; ++p)
                WRITE_CHANNEL(detect_to_detect[6][p], hsum[p]);

            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[0].s8 > threshold) & filter_mask[0];
            cand[9] = (hsum[0].s9 > threshold) & filter_mask[0];
            cand[10] = (hsum[0].sA > threshold) & filter_mask[0];
            cand[11] = (hsum[0].sB > threshold) & filter_mask[0];
            cand[12] = (hsum[0].sC > threshold) & filter_mask[0];
            cand[13] = (hsum[0].sD > threshold) & filter_mask[0];
            cand[14] = (hsum[0].sE > threshold) & filter_mask[0];
            cand[15] = (hsum[0].sF > threshold) & filter_mask[0];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(7, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0].s0 : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(7, filter_num[0], channel_num[1]) : invalid_location;
                amp[1] = cand[1] ? hsum[0].s1 : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(7, filter_num[0], channel_num[2]) : invalid_location;
                amp[2] = cand[2] ? hsum[0].s2 : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(7, filter_num[0], channel_num[3]) : invalid_location;
                amp[3] = cand[3] ? hsum[0].s3 : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(7, filter_num[0], channel_num[4]) : invalid_location;
                amp[4] = cand[4] ? hsum[0].s4 : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(7, filter_num[0], channel_num[5]) : invalid_location;
                amp[5] = cand[5] ? hsum[0].s5 : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(7, filter_num[0], channel_num[6]) : invalid_location;
                amp[6] = cand[6] ? hsum[0].s6 : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(7, filter_num[0], channel_num[7]) : invalid_location;
                amp[7] = cand[7] ? hsum[0].s7 : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(7, filter_num[0], channel_num[8]) : invalid_location;
                amp[8] = cand[8] ? hsum[0].s8 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(7, filter_num[0], channel_num[9]) : invalid_location;
                amp[9] = cand[9] ? hsum[0].s9 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(7, filter_num[0], channel_num[10]) : invalid_location;
                amp[10] = cand[10] ? hsum[0].sA : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(7, filter_num[0], channel_num[11]) : invalid_location;
                amp[11] = cand[11] ? hsum[0].sB : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(7, filter_num[0], channel_num[12]) : invalid_location;
                amp[12] = cand[12] ? hsum[0].sC : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(7, filter_num[0], channel_num[13]) : invalid_location;
                amp[13] = cand[13] ? hsum[0].sD : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(7, filter_num[0], channel_num[14]) : invalid_location;
                amp[14] = cand[14] ? hsum[0].sE : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(7, filter_num[0], channel_num[15]) : invalid_location;
                amp[15] = cand[15] ? hsum[0].sF : invalid_amplitude;

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
        uint group_base = group * 1;
        int filter_num[1];
        bool filter_mask[1];
        #pragma unroll
        for (uint p = 0; p < 1; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 16;
            uint channel_num[16];
            #pragma unroll
            for (uint q = 0; q < 16; ++q)
                channel_num[q] = bundle_base + q;

            float16 hsum[1];

            #pragma unroll
            for (uint p = 0; p < 1; ++p) {
                float16 from_prev_hp = READ_CHANNEL(detect_to_detect[6][p]);
                float16 from_sp = READ_CHANNEL(delay_to_detect[7][p]);
                hsum[p] = from_prev_hp + from_sp;
            }


            bool cand[16];

            cand[0] = (hsum[0].s0 > threshold) & filter_mask[0];
            cand[1] = (hsum[0].s1 > threshold) & filter_mask[0];
            cand[2] = (hsum[0].s2 > threshold) & filter_mask[0];
            cand[3] = (hsum[0].s3 > threshold) & filter_mask[0];
            cand[4] = (hsum[0].s4 > threshold) & filter_mask[0];
            cand[5] = (hsum[0].s5 > threshold) & filter_mask[0];
            cand[6] = (hsum[0].s6 > threshold) & filter_mask[0];
            cand[7] = (hsum[0].s7 > threshold) & filter_mask[0];
            cand[8] = (hsum[0].s8 > threshold) & filter_mask[0];
            cand[9] = (hsum[0].s9 > threshold) & filter_mask[0];
            cand[10] = (hsum[0].sA > threshold) & filter_mask[0];
            cand[11] = (hsum[0].sB > threshold) & filter_mask[0];
            cand[12] = (hsum[0].sC > threshold) & filter_mask[0];
            cand[13] = (hsum[0].sD > threshold) & filter_mask[0];
            cand[14] = (hsum[0].sE > threshold) & filter_mask[0];
            cand[15] = (hsum[0].sF > threshold) & filter_mask[0];

            bool any_cand = cand[0] | cand[1] | cand[2] | cand[3] | cand[4] | cand[5] | cand[6] | cand[7] | cand[8] | cand[9] | cand[10] | cand[11] | cand[12] | cand[13] | cand[14] | cand[15];
            if (any_cand) {
                uint loc[16];
                float amp[16];

                loc[0] = cand[0] ? encode_location(8, filter_num[0], channel_num[0]) : invalid_location;
                amp[0] = cand[0] ? hsum[0].s0 : invalid_amplitude;
                loc[1] = cand[1] ? encode_location(8, filter_num[0], channel_num[1]) : invalid_location;
                amp[1] = cand[1] ? hsum[0].s1 : invalid_amplitude;
                loc[2] = cand[2] ? encode_location(8, filter_num[0], channel_num[2]) : invalid_location;
                amp[2] = cand[2] ? hsum[0].s2 : invalid_amplitude;
                loc[3] = cand[3] ? encode_location(8, filter_num[0], channel_num[3]) : invalid_location;
                amp[3] = cand[3] ? hsum[0].s3 : invalid_amplitude;
                loc[4] = cand[4] ? encode_location(8, filter_num[0], channel_num[4]) : invalid_location;
                amp[4] = cand[4] ? hsum[0].s4 : invalid_amplitude;
                loc[5] = cand[5] ? encode_location(8, filter_num[0], channel_num[5]) : invalid_location;
                amp[5] = cand[5] ? hsum[0].s5 : invalid_amplitude;
                loc[6] = cand[6] ? encode_location(8, filter_num[0], channel_num[6]) : invalid_location;
                amp[6] = cand[6] ? hsum[0].s6 : invalid_amplitude;
                loc[7] = cand[7] ? encode_location(8, filter_num[0], channel_num[7]) : invalid_location;
                amp[7] = cand[7] ? hsum[0].s7 : invalid_amplitude;
                loc[8] = cand[8] ? encode_location(8, filter_num[0], channel_num[8]) : invalid_location;
                amp[8] = cand[8] ? hsum[0].s8 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(8, filter_num[0], channel_num[9]) : invalid_location;
                amp[9] = cand[9] ? hsum[0].s9 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(8, filter_num[0], channel_num[10]) : invalid_location;
                amp[10] = cand[10] ? hsum[0].sA : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(8, filter_num[0], channel_num[11]) : invalid_location;
                amp[11] = cand[11] ? hsum[0].sB : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(8, filter_num[0], channel_num[12]) : invalid_location;
                amp[12] = cand[12] ? hsum[0].sC : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(8, filter_num[0], channel_num[13]) : invalid_location;
                amp[13] = cand[13] ? hsum[0].sD : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(8, filter_num[0], channel_num[14]) : invalid_location;
                amp[14] = cand[14] ? hsum[0].sE : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(8, filter_num[0], channel_num[15]) : invalid_location;
                amp[15] = cand[15] ? hsum[0].sF : invalid_amplitude;

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
