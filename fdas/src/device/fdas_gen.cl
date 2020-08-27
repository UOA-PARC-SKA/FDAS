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

#if defined(INTELFPGA_CL)
#pragma OPENCL EXTENSION cl_intel_channels : enable
#define READ_CHANNEL(ch) read_channel_intel(ch)
#define WRITE_CHANNEL(ch, x) write_channel_intel(ch, x)
#else
#pragma OPENCL EXTENSION cl_altera_channels : enable
#define READ_CHANNEL(ch) read_channel_altera(ch)
#define WRITE_CHANNEL(ch, x) write_channel_altera(ch, x)
#endif

channel float2 fft_in[4] __attribute__((depth(0)));
channel float2 fft_out[4] __attribute__((depth(0)));

channel float2 ifft_in[3][4] __attribute__((depth(0)));
channel float2 ifft_out[3][4] __attribute__((depth(0)));

channel float8 preload_to_delay[8][2] __attribute__((depth(0)));
channel float8 delay_to_detect[8][2] __attribute__((depth(0)));

channel float8 detect_to_detect[7][2] __attribute__((depth(0)));
channel uint  detect_to_store_location[8][16] __attribute__((depth(0)));
channel float detect_to_store_amplitude[8][16] __attribute__((depth(0)));

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

inline float2 complex_mult(float2 a, float2 b)
{
    float2 res;
    res.x = a.x * b.x - a.y * b.y;
    res.y = a.y * b.x + a.x * b.y;
    return res;
}

inline float power_norm(float2 a)
{
    return (a.x * a.x + a.y * a.y) / 4194304;
}

inline ulong fop_idx(int filter, uint bundle) {
    return (filter + 10) * 7772 + bundle;
}

inline uint encode_location(uint k, int f, uint c) {
    return (((k - 1) & 0x7) << 29) | (((f + 10) & 0x7f) << 22) | (c & 0x3fffff);
}

#include "fft_4p.cl"

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void fft_0(const uint n_tiles, const uint is_inverse)
{
    float2 __attribute__((bank_bits(11))) buf[2][512][4];
    float2 fft_delay_elements[2080];
    float2x4 data;

    #pragma loop_coalesce
    for (uint t = 0; t < n_tiles + 2; ++t) {
        for (uint s = 0; s < 512; ++s) {
            if (t >= 1) {
                #pragma unroll
                for (uint p = 0; p < 4; ++p) {
                    buf[1 - (t & 1)][bit_reversed(s, 9)][p] = data.i[p];
                }
            }
            if (t >= 2) {
                #pragma unroll
                for (uint p = 0; p < 4; ++p) {
                    if (! is_inverse)
                        WRITE_CHANNEL(fft_out[p], buf[t & 1][s][p]);
                    else
                        WRITE_CHANNEL(ifft_out[0][p], buf[t & 1][s][p]);
                }
            }

            if (t < n_tiles) {
                #pragma unroll
                for (uint p = 0; p < 4; ++p) {
                    if (! is_inverse)
                        data.i[p] = READ_CHANNEL(fft_in[p]);
                    else
                        data.i[p] = READ_CHANNEL(ifft_in[0][p]);
                }
            } else {
                data.i0 = data.i1 = data.i2 = data.i3 = 0.0f;
            }

            data = fft_step(data, s, fft_delay_elements, is_inverse, 11);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void fft_1(const uint n_tiles)
{
    float2 __attribute__((bank_bits(11))) buf[2][512][4];
    float2 fft_delay_elements[2080];
    float2x4 data;

    #pragma loop_coalesce
    for (uint t = 0; t < n_tiles + 2; ++t) {
        for (uint s = 0; s < 512; ++s) {
            if (t >= 1) {
                #pragma unroll
                for (uint p = 0; p < 4; ++p) {
                    buf[1 - (t & 1)][bit_reversed(s, 9)][p] = data.i[p];
                }
            }
            if (t >= 2) {
                #pragma unroll
                for (uint p = 0; p < 4; ++p) {
                    WRITE_CHANNEL(ifft_out[1][p], buf[t & 1][s][p]);
                }
            }

            if (t < n_tiles) {
                #pragma unroll
                for (uint p = 0; p < 4; ++p) {
                    data.i[p] = READ_CHANNEL(ifft_in[1][p]);
                }
            } else {
                data.i0 = data.i1 = data.i2 = data.i3 = 0.0f;
            }

            data = fft_step(data, s, fft_delay_elements, 1, 11);
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void fft_2(const uint n_tiles)
{
    float2 __attribute__((bank_bits(11))) buf[2][512][4];
    float2 fft_delay_elements[2080];
    float2x4 data;

    #pragma loop_coalesce
    for (uint t = 0; t < n_tiles + 2; ++t) {
        for (uint s = 0; s < 512; ++s) {
            if (t >= 1) {
                #pragma unroll
                for (uint p = 0; p < 4; ++p) {
                    buf[1 - (t & 1)][bit_reversed(s, 9)][p] = data.i[p];
                }
            }
            if (t >= 2) {
                #pragma unroll
                for (uint p = 0; p < 4; ++p) {
                    WRITE_CHANNEL(ifft_out[2][p], buf[t & 1][s][p]);
                }
            }

            if (t < n_tiles) {
                #pragma unroll
                for (uint p = 0; p < 4; ++p) {
                    data.i[p] = READ_CHANNEL(ifft_in[2][p]);
                }
            } else {
                data.i0 = data.i1 = data.i2 = data.i3 = 0.0f;
            }

            data = fft_step(data, s, fft_delay_elements, 1, 11);
        }
    }
}

__attribute__((reqd_work_group_size(512, 1, 1)))
__attribute__((uses_global_work_offset(0)))
kernel void tile_input(global float2 * restrict input)
{
    local float2 __attribute__((bank_bits(10,9))) buf[4][512];

    uint tile = get_group_id(0);
    uint step = get_local_id(0);
    uint chunk = step / 128;
    uint chunk_rev = bit_reversed(chunk, 2);
    uint bundle = step % 128;

    #pragma unroll
    for (uint p = 0; p < 4; ++p)
        buf[chunk_rev][bundle * 4 + p] = input[tile * 1943 + chunk * 512 + bundle * 4 + p];

    barrier(CLK_LOCAL_MEM_FENCE);

    #pragma unroll
    for (uint p = 0; p < 4; ++p)
        WRITE_CHANNEL(fft_in[p], buf[p][step]);
}

__attribute__((reqd_work_group_size(512, 1, 1)))
__attribute__((uses_global_work_offset(0)))
kernel void store_tiles(global float2 * restrict tiles)
{
    uint tile = get_group_id(0);
    uint step = get_local_id(0);

    #pragma unroll
    for (uint p = 0; p < 4; ++p)
       tiles[tile * 2048 + step * 4 + p] = READ_CHANNEL(fft_out[p]);
}

__attribute__((reqd_work_group_size(512, 1, 1)))
__attribute__((uses_global_work_offset(0)))
kernel void mux_and_mult(global float2 * restrict tiles,
                         global float2 * restrict templates)
{
    uint batch = get_group_id(1) * 3;
    uint tile = get_group_id(0);
    uint step = get_local_id(0);

    #pragma unroll
    for (uint f = 0; f < 3; ++f) {
        #pragma unroll
        for (uint p = 0; p < 4; ++p) {
            float2 value = tiles[tile * 2048 + step * 4 + p];
            float2 coeff = templates[(batch + f) * 2048 + step * 4 + p];
            float2 prod = complex_mult(value, coeff);
            WRITE_CHANNEL(ifft_in[f][p], prod);
        }
    }
}

__attribute__((reqd_work_group_size(512, 1, 1)))
__attribute__((uses_global_work_offset(0)))
kernel void square_and_discard(global float * restrict fop)
{
    float buf[3][4];

    uint batch = get_group_id(1) * 3;
    uint tile = get_group_id(0);
    uint step = get_local_id(0);

    #pragma unroll
    for (uint f = 0; f < 3; ++f) {
        #pragma unroll
        for (uint p = 0; p < 4; ++p)
            buf[f][p] = power_norm(READ_CHANNEL(ifft_out[f][p]));
    }

    #pragma unroll
    for (uint f = 0; f < 3; ++f) {
        #pragma unroll
        for (uint p = 0; p < 4; ++p) {
            uint q = bit_reversed(p, 2);

            int element = p * 512 + step - 105;
            if (element >= 0)
                fop[(batch + f) * 62176 + tile * 1943 + element] = buf[f][q];
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_1(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const uint n_channel_bundles)
{
    float8 load[2];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[1];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[0][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_1(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 0 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[0][p]);
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
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[0][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_2(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const uint n_channel_bundles)
{
    float8 load[1];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[0];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[1][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_2(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 1 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[1][p]);
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
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[1][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_3(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const uint n_channel_bundles)
{
    float8 load[2];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = base_row_offset < 2 ? load[0] : load[1];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[2][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_3(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 2 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[2][p]);
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
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[2][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_4(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const uint n_channel_bundles)
{
    float8 load[1];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[0];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[3][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_4(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 3 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[3][p]);
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
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[3][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_5(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const uint n_channel_bundles)
{
    float8 load[2];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = base_row_offset < 4 ? load[0] : load[1];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[4][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_5(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 4 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[4][p]);
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
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[4][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_6(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const uint n_channel_bundles)
{
    float8 load[1];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[0];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[5][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_6(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 5 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[5][p]);
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
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[5][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_7(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const uint n_channel_bundles)
{
    float8 load[2];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = base_row_offset < 6 ? load[0] : load[1];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[6][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_7(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 6 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[6][p]);
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
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[6][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_8(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const uint n_channel_bundles)
{
    float8 load[1];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[0];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[7][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_8(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 7 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[7][p]);
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
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[7][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_1(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 11, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_fop = READ_CHANNEL(delay_to_detect[0][p]);
                hsum[p] = from_fop;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
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
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

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
                loc[8] = cand[8] ? encode_location(1, filter_num[1], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[1].s0 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(1, filter_num[1], channel_num[1]) : invalid_location;
                amp[9] = cand[9] ? hsum[1].s1 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(1, filter_num[1], channel_num[2]) : invalid_location;
                amp[10] = cand[10] ? hsum[1].s2 : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(1, filter_num[1], channel_num[3]) : invalid_location;
                amp[11] = cand[11] ? hsum[1].s3 : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(1, filter_num[1], channel_num[4]) : invalid_location;
                amp[12] = cand[12] ? hsum[1].s4 : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(1, filter_num[1], channel_num[5]) : invalid_location;
                amp[13] = cand[13] ? hsum[1].s5 : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(1, filter_num[1], channel_num[6]) : invalid_location;
                amp[14] = cand[14] ? hsum[1].s6 : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(1, filter_num[1], channel_num[7]) : invalid_location;
                amp[15] = cand[15] ? hsum[1].s7 : invalid_amplitude;

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

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            detection_location[0 + d * 16 + x] = is_valid ? location_buffer[d][x] : invalid_location;
            detection_amplitude[0 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : invalid_amplitude;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_2(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 11, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[0][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[1][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
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
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

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
                loc[8] = cand[8] ? encode_location(2, filter_num[1], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[1].s0 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(2, filter_num[1], channel_num[1]) : invalid_location;
                amp[9] = cand[9] ? hsum[1].s1 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(2, filter_num[1], channel_num[2]) : invalid_location;
                amp[10] = cand[10] ? hsum[1].s2 : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(2, filter_num[1], channel_num[3]) : invalid_location;
                amp[11] = cand[11] ? hsum[1].s3 : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(2, filter_num[1], channel_num[4]) : invalid_location;
                amp[12] = cand[12] ? hsum[1].s4 : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(2, filter_num[1], channel_num[5]) : invalid_location;
                amp[13] = cand[13] ? hsum[1].s5 : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(2, filter_num[1], channel_num[6]) : invalid_location;
                amp[14] = cand[14] ? hsum[1].s6 : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(2, filter_num[1], channel_num[7]) : invalid_location;
                amp[15] = cand[15] ? hsum[1].s7 : invalid_amplitude;

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

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            detection_location[1024 + d * 16 + x] = is_valid ? location_buffer[d][x] : invalid_location;
            detection_amplitude[1024 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : invalid_amplitude;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_3(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 11, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[1][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[2][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
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
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

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
                loc[8] = cand[8] ? encode_location(3, filter_num[1], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[1].s0 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(3, filter_num[1], channel_num[1]) : invalid_location;
                amp[9] = cand[9] ? hsum[1].s1 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(3, filter_num[1], channel_num[2]) : invalid_location;
                amp[10] = cand[10] ? hsum[1].s2 : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(3, filter_num[1], channel_num[3]) : invalid_location;
                amp[11] = cand[11] ? hsum[1].s3 : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(3, filter_num[1], channel_num[4]) : invalid_location;
                amp[12] = cand[12] ? hsum[1].s4 : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(3, filter_num[1], channel_num[5]) : invalid_location;
                amp[13] = cand[13] ? hsum[1].s5 : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(3, filter_num[1], channel_num[6]) : invalid_location;
                amp[14] = cand[14] ? hsum[1].s6 : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(3, filter_num[1], channel_num[7]) : invalid_location;
                amp[15] = cand[15] ? hsum[1].s7 : invalid_amplitude;

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

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            detection_location[2048 + d * 16 + x] = is_valid ? location_buffer[d][x] : invalid_location;
            detection_amplitude[2048 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : invalid_amplitude;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_4(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 11, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[2][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[3][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
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
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

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
                loc[8] = cand[8] ? encode_location(4, filter_num[1], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[1].s0 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(4, filter_num[1], channel_num[1]) : invalid_location;
                amp[9] = cand[9] ? hsum[1].s1 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(4, filter_num[1], channel_num[2]) : invalid_location;
                amp[10] = cand[10] ? hsum[1].s2 : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(4, filter_num[1], channel_num[3]) : invalid_location;
                amp[11] = cand[11] ? hsum[1].s3 : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(4, filter_num[1], channel_num[4]) : invalid_location;
                amp[12] = cand[12] ? hsum[1].s4 : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(4, filter_num[1], channel_num[5]) : invalid_location;
                amp[13] = cand[13] ? hsum[1].s5 : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(4, filter_num[1], channel_num[6]) : invalid_location;
                amp[14] = cand[14] ? hsum[1].s6 : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(4, filter_num[1], channel_num[7]) : invalid_location;
                amp[15] = cand[15] ? hsum[1].s7 : invalid_amplitude;

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

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            detection_location[3072 + d * 16 + x] = is_valid ? location_buffer[d][x] : invalid_location;
            detection_amplitude[3072 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : invalid_amplitude;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_5(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 11, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[3][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[4][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
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
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

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
                loc[8] = cand[8] ? encode_location(5, filter_num[1], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[1].s0 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(5, filter_num[1], channel_num[1]) : invalid_location;
                amp[9] = cand[9] ? hsum[1].s1 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(5, filter_num[1], channel_num[2]) : invalid_location;
                amp[10] = cand[10] ? hsum[1].s2 : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(5, filter_num[1], channel_num[3]) : invalid_location;
                amp[11] = cand[11] ? hsum[1].s3 : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(5, filter_num[1], channel_num[4]) : invalid_location;
                amp[12] = cand[12] ? hsum[1].s4 : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(5, filter_num[1], channel_num[5]) : invalid_location;
                amp[13] = cand[13] ? hsum[1].s5 : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(5, filter_num[1], channel_num[6]) : invalid_location;
                amp[14] = cand[14] ? hsum[1].s6 : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(5, filter_num[1], channel_num[7]) : invalid_location;
                amp[15] = cand[15] ? hsum[1].s7 : invalid_amplitude;

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

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            detection_location[4096 + d * 16 + x] = is_valid ? location_buffer[d][x] : invalid_location;
            detection_amplitude[4096 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : invalid_amplitude;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_6(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 11, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[4][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[5][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
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
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

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
                loc[8] = cand[8] ? encode_location(6, filter_num[1], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[1].s0 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(6, filter_num[1], channel_num[1]) : invalid_location;
                amp[9] = cand[9] ? hsum[1].s1 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(6, filter_num[1], channel_num[2]) : invalid_location;
                amp[10] = cand[10] ? hsum[1].s2 : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(6, filter_num[1], channel_num[3]) : invalid_location;
                amp[11] = cand[11] ? hsum[1].s3 : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(6, filter_num[1], channel_num[4]) : invalid_location;
                amp[12] = cand[12] ? hsum[1].s4 : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(6, filter_num[1], channel_num[5]) : invalid_location;
                amp[13] = cand[13] ? hsum[1].s5 : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(6, filter_num[1], channel_num[6]) : invalid_location;
                amp[14] = cand[14] ? hsum[1].s6 : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(6, filter_num[1], channel_num[7]) : invalid_location;
                amp[15] = cand[15] ? hsum[1].s7 : invalid_amplitude;

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

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            detection_location[5120 + d * 16 + x] = is_valid ? location_buffer[d][x] : invalid_location;
            detection_amplitude[5120 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : invalid_amplitude;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_7(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 11, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[5][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[6][p]);
                hsum[p] = from_prev_hp + from_sp;
            }

            #pragma unroll
            for (uint p = 0; p < 2; ++p)
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
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

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
                loc[8] = cand[8] ? encode_location(7, filter_num[1], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[1].s0 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(7, filter_num[1], channel_num[1]) : invalid_location;
                amp[9] = cand[9] ? hsum[1].s1 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(7, filter_num[1], channel_num[2]) : invalid_location;
                amp[10] = cand[10] ? hsum[1].s2 : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(7, filter_num[1], channel_num[3]) : invalid_location;
                amp[11] = cand[11] ? hsum[1].s3 : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(7, filter_num[1], channel_num[4]) : invalid_location;
                amp[12] = cand[12] ? hsum[1].s4 : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(7, filter_num[1], channel_num[5]) : invalid_location;
                amp[13] = cand[13] ? hsum[1].s5 : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(7, filter_num[1], channel_num[6]) : invalid_location;
                amp[14] = cand[14] ? hsum[1].s6 : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(7, filter_num[1], channel_num[7]) : invalid_location;
                amp[15] = cand[15] ? hsum[1].s7 : invalid_amplitude;

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

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            detection_location[6144 + d * 16 + x] = is_valid ? location_buffer[d][x] : invalid_location;
            detection_amplitude[6144 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : invalid_amplitude;
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void detect_8(global uint * restrict detection_location,
                     global float * restrict detection_amplitude,
                     float threshold,
                     uint n_filters,
                     uint negative_filters,
                     uint n_filter_groups,
                     uint n_channel_bundles)
{
    uint location_buffer[64][16];
    float amplitude_buffer[64][16];

    ulong valid = 0l;
    uint next = 0;

    const uint invalid_location = encode_location(1, 11, 0);
    const float invalid_amplitude = -1.0f;

    for (uint group = 0; group < n_filter_groups; ++group) {
        uint group_base = group * 2;
        int filter_num[2];
        bool filter_mask[2];
        #pragma unroll
        for (uint p = 0; p < 2; ++p) {
            filter_num[p] = negative_filters ? - group_base - p : group_base + p;
            filter_mask[p] = group_base + p < n_filters;
        }

        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            uint bundle_base = bundle * 8;
            uint channel_num[8];
            #pragma unroll
            for (uint q = 0; q < 8; ++q)
                channel_num[q] = bundle_base + q;

            float8 hsum[2];

            #pragma unroll
            for (uint p = 0; p < 2; ++p) {
                float8 from_prev_hp = READ_CHANNEL(detect_to_detect[6][p]);
                float8 from_sp = READ_CHANNEL(delay_to_detect[7][p]);
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
            cand[8] = (hsum[1].s0 > threshold) & filter_mask[1];
            cand[9] = (hsum[1].s1 > threshold) & filter_mask[1];
            cand[10] = (hsum[1].s2 > threshold) & filter_mask[1];
            cand[11] = (hsum[1].s3 > threshold) & filter_mask[1];
            cand[12] = (hsum[1].s4 > threshold) & filter_mask[1];
            cand[13] = (hsum[1].s5 > threshold) & filter_mask[1];
            cand[14] = (hsum[1].s6 > threshold) & filter_mask[1];
            cand[15] = (hsum[1].s7 > threshold) & filter_mask[1];

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
                loc[8] = cand[8] ? encode_location(8, filter_num[1], channel_num[0]) : invalid_location;
                amp[8] = cand[8] ? hsum[1].s0 : invalid_amplitude;
                loc[9] = cand[9] ? encode_location(8, filter_num[1], channel_num[1]) : invalid_location;
                amp[9] = cand[9] ? hsum[1].s1 : invalid_amplitude;
                loc[10] = cand[10] ? encode_location(8, filter_num[1], channel_num[2]) : invalid_location;
                amp[10] = cand[10] ? hsum[1].s2 : invalid_amplitude;
                loc[11] = cand[11] ? encode_location(8, filter_num[1], channel_num[3]) : invalid_location;
                amp[11] = cand[11] ? hsum[1].s3 : invalid_amplitude;
                loc[12] = cand[12] ? encode_location(8, filter_num[1], channel_num[4]) : invalid_location;
                amp[12] = cand[12] ? hsum[1].s4 : invalid_amplitude;
                loc[13] = cand[13] ? encode_location(8, filter_num[1], channel_num[5]) : invalid_location;
                amp[13] = cand[13] ? hsum[1].s5 : invalid_amplitude;
                loc[14] = cand[14] ? encode_location(8, filter_num[1], channel_num[6]) : invalid_location;
                amp[14] = cand[14] ? hsum[1].s6 : invalid_amplitude;
                loc[15] = cand[15] ? encode_location(8, filter_num[1], channel_num[7]) : invalid_location;
                amp[15] = cand[15] ? hsum[1].s7 : invalid_amplitude;

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

    for (uint d = 0; d < 64; ++d) {
        bool is_valid = (valid & (1l << d)) > 0;
        #pragma unroll
        for (uint x = 0; x < 16; ++x) {
            detection_location[7168 + d * 16 + x] = is_valid ? location_buffer[d][x] : invalid_location;
            detection_amplitude[7168 + d * 16 + x] = is_valid ? amplitude_buffer[d][x] : invalid_amplitude;
        }
    }
}
