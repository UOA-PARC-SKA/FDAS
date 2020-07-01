
#include "fft_4p.cl"
#include "fdas_config.h"

// Enable channels, portable across Altera's and Intel's `aoc` versions
#if defined(INTELFPGA_CL)
#pragma OPENCL EXTENSION cl_intel_channels : enable
#define READ_CHANNEL(ch) read_channel_intel(ch)
#define WRITE_CHANNEL(ch, x) write_channel_intel(ch, x)
#else
#pragma OPENCL EXTENSION cl_altera_channels : enable
#define READ_CHANNEL(ch) read_channel_altera(ch)
#define WRITE_CHANNEL(ch, x) write_channel_altera(ch, x)
#endif

channel float2 fft_in[FFT_N_PARALLEL] __attribute__((depth(0)));
channel float2 fft_out[FFT_N_PARALLEL] __attribute__((depth(0)));

channel float2 ifft_in[N_FILTERS_PARALLEL][FFT_N_PARALLEL] __attribute__((depth(0)));
channel float2 ifft_out[N_FILTERS_PARALLEL][FFT_N_PARALLEL] __attribute__((depth(0)));

/*
 * Helper to perform the FFT-typical bit-reversal.
 */
inline int bit_reversed(int x, int bits)
{
    int y = 0;
    #pragma unroll
    for (int i = 0; i < bits; i++) {
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
    return (a.x * a.x + a.y * a.y) / (FFT_N_POINTS * FFT_N_POINTS);
}

__attribute__((reqd_work_group_size(FFT_N_POINTS_PER_TERMINAL, 1, 1)))
kernel void tile_input(global float2 * restrict input)
{
    local float2 __attribute__((bank_bits(10,9))) buf[FFT_N_PARALLEL][FFT_N_POINTS_PER_TERMINAL];

    int tile = get_group_id(0);
    int step = get_local_id(0);
    int chunk = step / (FFT_N_POINTS_PER_TERMINAL / FFT_N_PARALLEL);
    int chunk_rev = bit_reversed(chunk, FFT_N_PARALLEL_LOG);
    int bundle = step % (FFT_N_POINTS_PER_TERMINAL / FFT_N_PARALLEL);

    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
        buf[chunk_rev][bundle * FFT_N_PARALLEL + p] = input[tile   * FDF_TILE_PAYLOAD +
                                                            chunk  * FFT_N_POINTS_PER_TERMINAL +
                                                            bundle * FFT_N_PARALLEL + p];

    barrier(CLK_LOCAL_MEM_FENCE);

    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
        WRITE_CHANNEL(fft_in[p], buf[p][step]);
}

__attribute__((autorun))
__attribute__((max_global_work_dim(0)))
__attribute__((num_compute_units(1)))
kernel void fft()
{
    // (Double) buffers used for result re-ordering
    float2 __attribute__((bank_bits(11))) buf[2][FFT_N_POINTS_PER_TERMINAL][FFT_N_PARALLEL];

    // Sliding window arrays, used internally by the FFT engine for data reordering
    float2 fft_delay_elements[FFT_N_POINTS + FFT_N_PARALLEL * (FFT_N_POINTS_LOG - 3)];

    // Buffers to hold engine's input/output in each iteration
    float2x4 data;

    // Process FDF_N_TILES tiles and flush the engine's pipeline
    #pragma loop_coalesce
    for (int t = 0; t < FDF_N_TILES + 2; ++t) {
        for (int s = 0; s < FFT_N_POINTS_PER_TERMINAL; ++s) {
            if (t >= 1) {
                #pragma unroll
                for (int p = 0; p < FFT_N_PARALLEL; ++p)
                    buf[1 - (t & 1)][bit_reversed(s, FFT_N_POINTS_PER_TERMINAL_LOG)][p] = data.i[p];
            }
            if (t >= 2) {
                #pragma unroll
                for (int p = 0; p < FFT_N_PARALLEL; ++p)
                    WRITE_CHANNEL(fft_out[p], buf[t & 1][s][p]);
            }

            // Read actual input from the channels, respectively inject zeroes to flush the pipeline
            if (t < FDF_N_TILES) {
                #pragma unroll
                for (int p = 0; p < FFT_N_PARALLEL; ++p)
                    data.i[p] = READ_CHANNEL(fft_in[p]);
            } else {
                data.i0 = data.i1 = data.i2 = data.i3 = 0;
            }

            // Perform one step of the FFT engine
            data = fft_step(data, s, fft_delay_elements, 0 /* = forward FFT */, FFT_N_POINTS_LOG);
        }
    }
}

__attribute__((reqd_work_group_size(FFT_N_POINTS_PER_TERMINAL, 1, 1)))
kernel void store_tiles(global float2 * restrict tiles)
{
    int tile = get_group_id(0);
    int step = get_local_id(0);

    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
       tiles[tile * FDF_TILE_SZ + step * FFT_N_PARALLEL + p] = READ_CHANNEL(fft_out[p]);
}

__attribute__((reqd_work_group_size(FFT_N_POINTS_PER_TERMINAL, 1, 1)))
kernel void mux_and_mult(global float2 * restrict tiles,
                         global float2 * restrict templates)
{
    int batch = get_group_id(1) * N_FILTERS_PARALLEL;
    int tile = get_group_id(0);
    int step = get_local_id(0);

    #pragma unroll
    for (int f = 0; f < N_FILTERS_PARALLEL; ++f) {
        #pragma unroll
        for (int p = 0; p < FFT_N_PARALLEL; ++p) {
            float2 prod = complex_mult(tiles    [tile        * FDF_TILE_SZ + step * FFT_N_PARALLEL + p],
                                       templates[(batch + f) * FDF_TILE_SZ + step * FFT_N_PARALLEL + p]);
            WRITE_CHANNEL(ifft_in[f][p], prod);
        }
    }
}

__attribute__((autorun))
__attribute__((max_global_work_dim(0)))
__attribute__((num_compute_units(N_FILTERS_PARALLEL)))
kernel void ifft()
{
    const int cid = get_compute_id(0);

    // (Double) buffers used for result re-ordering
    float2 __attribute__((bank_bits(11))) buf[2][FFT_N_POINTS_PER_TERMINAL][FFT_N_PARALLEL];

    // Sliding window arrays, used internally by the FFT engine for data reordering
    float2 fft_delay_elements[FFT_N_POINTS + FFT_N_PARALLEL * (FFT_N_POINTS_LOG - 3)];

    // Buffers to hold engine's input/output in each iteration
    float2x4 data;

    // Process N_FILTER_BATCHES * FDF_N_TILES tiles and flush the engine's pipeline
    #pragma loop_coalesce
    for (int t = 0; t < N_FILTER_BATCHES * FDF_N_TILES + 2; ++t) {
        for (int s = 0; s < FFT_N_POINTS_PER_TERMINAL; ++s) {
            if (t >= 1) {
                #pragma unroll
                for (int p = 0; p < FFT_N_PARALLEL; ++p)
                    buf[1 - (t & 1)][bit_reversed(s, FFT_N_POINTS_PER_TERMINAL_LOG)][p] = data.i[p];
            }
            if (t >= 2) {
                #pragma unroll
                for (int p = 0; p < FFT_N_PARALLEL; ++p)
                    WRITE_CHANNEL(ifft_out[cid][p], buf[t & 1][s][p]);
            }

            // Read actual input from the channels, respectively inject zeroes to flush the pipeline
            if (t < N_FILTER_BATCHES * FDF_N_TILES) {
                #pragma unroll
                for (int p = 0; p < FFT_N_PARALLEL; ++p)
                    data.i[p] = READ_CHANNEL(ifft_in[cid][p]);
            } else {
                data.i0 = data.i1 = data.i2 = data.i3 = 0;
            }

            // Perform one step of the FFT engine
            data = fft_step(data, s, fft_delay_elements, 1 /* = inverse FFT */, FFT_N_POINTS_LOG);
        }
    }
}

__attribute__((reqd_work_group_size(FFT_N_POINTS_PER_TERMINAL, 1, 1)))
kernel void square_and_discard(global float * restrict fop)
{
    private float buf[N_FILTERS_PARALLEL][FFT_N_PARALLEL];

    int batch = get_group_id(1) * N_FILTERS_PARALLEL;
    int tile = get_group_id(0);
    int step = get_local_id(0);

    #pragma unroll
    for (int f = 0; f < N_FILTERS_PARALLEL; ++f) {
        #pragma unroll
        for (int p = 0; p < FFT_N_PARALLEL; ++p)
            buf[f][p] = power_norm(READ_CHANNEL(ifft_out[f][p]));
    }

    #pragma unroll
    for (int f = 0; f < N_FILTERS_PARALLEL; ++f) {
        #pragma unroll
        for (int p = 0; p < FFT_N_PARALLEL; ++p) {
            int element = p * FFT_N_POINTS_PER_TERMINAL + step - FDF_TILE_OVERLAP;
            int q = bit_reversed(p, FFT_N_PARALLEL_LOG);
            if (element >= 0)
                fop[(batch + f) * FDF_OUTPUT_SZ + tile * FDF_TILE_PAYLOAD + element] = buf[f][q];
        }
    }
}
