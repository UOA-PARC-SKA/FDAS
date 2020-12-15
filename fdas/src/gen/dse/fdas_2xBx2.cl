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

channel float2x4 ifft_in[2] __attribute__((depth(0)));
channel float2x4 ifft_out[2] __attribute__((depth(0)));


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
                         const uint tmpl_offset_1)
{
    const float2x4 zeros = {0, 0, 0, 0};

    float2x4 template_buf_0[512];
    float2x4 template_buf_1[512];

    for (uint pack = 0; pack < 512; ++pack) {
        float2x4 tmpl_0 = 0 < n_engines_to_use ? templates[tmpl_offset_0 + pack] : zeros;
        float2x4 tmpl_1 = 1 < n_engines_to_use ? templates[tmpl_offset_1 + pack] : zeros;
        template_buf_0[pack] = tmpl_0;
        template_buf_1[pack] = tmpl_1;
    }

    for (uint pack = 0; pack < n_tiles * 512; ++pack) {
        float2x4 coeffs[2];
        float2x4 prods[2];

        float2x4 load = tiles[pack];
        coeffs[0] = template_buf_0[pack % 512];
        coeffs[1] = template_buf_1[pack % 512];
        prods[0] = complex_mult(load, coeffs[0]);
        prods[1] = complex_mult(load, coeffs[1]);

        #pragma unroll
        for (uint e = 0; e < 2; ++e) {
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
kernel void harmonic_summing(global volatile float * restrict fop,       // `volatile` to disable private caches
                             const int first_template,
                             const int last_template,
                             const uint n_frequency_bins,
                             global float * restrict thresholds,
                             global uint * restrict detection_location,
                             global float * restrict detection_power)
{
    const uint invalid_location = encode_location(1, 43, 0);
    const float invalid_power = -1.0f;

    // The actual layout and banking of the detection and bookkeeping buffers is chosen to allow `aoc` to implement
    // hms_unroll_x-many no-stall parallel accesses in the unrolled region below. The logical layout is as explained above.
    uint __attribute__((numbanks(16))) location_buf[32][2][8];
    float __attribute__((numbanks(16))) power_buf[32][2][8];
    ulong valid[2][8];
    uint next_slot[2][8];

    // Zero-initialise bookkeeping buffers
    for (uint x = 0; x < 2; ++x) {
        for (uint h = 0; h < 8; ++h) {
            next_slot[x][h] = 0;
            valid[x][h] = 0l;
        }
    }

    // Preload the thresholds
    float thrsh[8];
    #pragma unroll
    for (uint h = 0; h < 8; ++h)
        thrsh[h] = thresholds[h];

    // MAIN LOOP: Iterates over all (t,f) coordinates in the FOP, handling hms_unroll_x-many channels per iteration of the
    //            inner loop
    for (int tmpl = first_template; tmpl <= last_template; ++tmpl) {
        #pragma unroll 2
        #pragma ii 1
        for (uint freq = 0; freq < n_frequency_bins; ++freq) {
            float hsum = 0.0f;

            // Completely unrolled to perform loading and thresholding for all HPs at once
            #pragma unroll
            for (uint h = 0; h < 8; ++h) {
                int k = h + 1;

                // Compute harmonic indices. The OpenCL C division does the right thing here, e.g. -10/3 = -3.
                int tmpl_k = tmpl / k;
                int freq_k = freq / k;

                // After adding SP_k(t,f), `hsum` represents HP_k(t,f)
                hsum += fop[(tmpl_k + 42) * n_frequency_bins + freq_k];

                // If we have a candidate, store it in the detection buffers and perform bookkeeping
                if (hsum > thrsh[h]) {
                    uint x = freq % 2;
                    uint slot = next_slot[x][h];
                    location_buf[slot][x][h] = encode_location(k, tmpl, freq);
                    power_buf[slot][x][h] = hsum;
                    valid[x][h] |= 1l << slot;
                    next_slot[x][h] = (slot == 31) ? 0 : slot + 1;
                }
            }
        }
    }

    // Write detection buffers to global memory without messing up the banking of the buffers
    for (uint h = 0; h < 8; ++h) {
        for (uint x = 0; x < 2; ++x) {
            for (uint d = 0; d < 32; ++d) {
                if (valid[x][h] & (1l << d)) {
                    detection_location[h * 64 + x * 32 + d] = location_buf[d][x][h];
                    detection_power[h * 64 + x * 32 + d] = power_buf[d][x][h];
                } else {
                    detection_location[h * 64 + x * 32 + d] = invalid_location;
                    detection_power[h * 64 + x * 32 + d] = invalid_power;
                }
            }
        }
    }
}
