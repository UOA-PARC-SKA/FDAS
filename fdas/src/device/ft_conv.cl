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

/*
 * The kernels in this file convolve the contents of global memory `input` with the FIR filter templates in `templates`
 * and write the resulting filter-output plane to `fop`.
 *
 * The overall architecture is shown below. We are using an overlap-save algorithm in the frequency domain,
 * parameterised by the macro definitions in fdas_config.h. See the comments on the individual kernels for a description
 * of their input/output data formats.
 *
 *                                            FFT_N_PARALLEL
 *                                               channels
 *                               ┏━━━━━━━━━━━━━━┓        ┏━━━━━━━━┓        ┏━━━━━━━━━━━━━┓
 *  ╔═══════════════════╗        ┃              ┃───────▶┃        ┃───────▶┃             ┃        ╔══════════════════╗
 *  ║       input       ║═══════▶┃  tile_input  ┃───────▶┃  fft   ┃───────▶┃ store_tiles ┃═══════▶║      tiles       ║
 *  ╚═══════════════════╝        ┃              ┃───────▶┃        ┃───────▶┃             ┃        ╚══════════════════╝
 *   FDF_PADDED_INPUT_SZ         ┃              ┃───────▶┃        ┃───────▶┃             ┃         FDF_TILED_INPUT_SZ
 *         * float2              ┗━━━━━━━━━━━━━━┛        ┗━━━━━━━━┛        ┗━━━━━━━━━━━━━┛              * float2
 *                                NDRange                    Task           NDRange
 *       linear order                                                                               tiled, FFT-order
 *                                  1 workgroup       (FDF_N_TILES + 2)       1 workgroup
 *                                = NPPT items         * NPPT iterations    = NPPT items
 *
 *                                covers 1 tile       incl. bit-reversal    covers 1 tile
 *
 *
 *
 *                                          N_FILTERS_PARALLEL
 *                                           * FFT_N_PARALLEL
 *                                               channels
 *                               ┏━━━━━━━━━━━━━━┓        ┏━━━━━━━━┓        ┏━━━━━━━━━━━━━━┓
 *   ╔══════════════════╗        ┃              ┃───────▶┃        ┃───────▶┃              ┃        ╔═══════════════╗
 *   ║      tiles       ║═══════▶┃              ┃───────▶┃  ifft  ┃───────▶┃              ┃═══════▶║      fop      ║
 *   ╚══════════════════╝        ┃              ┃───────▶┃        ┃───────▶┃              ┃        ╚═══════════════╝
 *    FDF_TILED_INPUT_SZ         ┃              ┃───────▶┃        ┃───────▶┃              ┃         FOP_SZ * float
 *         * float2              ┃              ┃        ┗━━━━━━━━┛        ┃              ┃
 *                               ┃              ┃        ┏━━━━━━━━┓        ┃              ┃          linear order
 *     tiled, FFT-order          ┃              ┃───────▶┃        ┃───────▶┃              ┃         dim 1: filters
 *                               ┃              ┃───────▶┃  ifft  ┃───────▶┃              ┃         dim 2: channels
 *                               ┃              ┃───────▶┃        ┃───────▶┃  square_and  ┃
 *                               ┃ mux_and_mult ┃───────▶┃        ┃───────▶┃   _discard   ┃
 *                               ┃              ┃        ┗━━━━━━━━┛        ┃              ┃
 *                               ┃              ┃   .        .        .    ┃              ┃
 *   ╔══════════════════╗        ┃              ┃   .        .        .    ┃              ┃
 *   ║    templates     ║═══════▶┃              ┃   .        .        .    ┃              ┃
 *   ╚══════════════════╝        ┃              ┃        ┏━━━━━━━━┓        ┃              ┃
 *     FDF_TEMPLATES_SZ          ┃              ┃───────▶┃        ┃───────▶┃              ┃
 *         * float2              ┃              ┃───────▶┃  ifft  ┃───────▶┃              ┃
 *                               ┃              ┃───────▶┃        ┃───────▶┃              ┃
 *     tiled, FFT-order          ┃              ┃───────▶┃        ┃───────▶┃              ┃
 *                               ┗━━━━━━━━━━━━━━┛        ┗━━━━━━━━┛        ┗━━━━━━━━━━━━━━┛
 *                                NDRange (2D)             Task x           NDRange (2D)
 *                                                   N_FILTERS_PARALLEL
 *                                  1 workgroup                               1 workgroup
 *                                = NPPT items        (N_FILTER_BATCHES     = NPPT items
 *                                                     * FDF_N_TILES + 2)
 *                                covers 1 tile,       * NPPT iterations    covers 1 tile,
 *                                1 filter batch                            1 filter batch
 *                                                   incl. bit-reversal
 *
 *
 *
 *  Legend
 *  ▔▔▔▔▔▔
 *    ┏━━━━━━━━┓                                    NPPT = FFT_N_POINTS_PER_TERMINAL
 *    ┃ kernel ┃   ───────▶ channel                      = FFT_N_POINTS / FFT_N_PARALLEL
 *    ┗━━━━━━━━┛
 *    ╔════════╗                                    FFT-order is: (for 2K-tiles, 4-parallel FFT)
 *    ║ global ║   ═══════▶ global memory access        0, 1024,  512, 1536,
 *    ╚════════╝                                        1, 1025,  513, 1537,
 *                                                    ...,  ...,  ...,  ...,
 *                                                    511, 1535, 1023, 2047
 */

// Include a 4-parallel FFT engine
#include "fft_4p.cl"

// Channels from and to the (forward) FFT engine
channel float2 fft_in[FFT_N_PARALLEL] __attribute__((depth(0)));
channel float2 fft_out[FFT_N_PARALLEL] __attribute__((depth(0)));

// Channels from and to the inverse FFT engines
channel float2 ifft_in[N_FILTERS_PARALLEL][FFT_N_PARALLEL] __attribute__((depth(0)));
channel float2 ifft_out[N_FILTERS_PARALLEL][FFT_N_PARALLEL] __attribute__((depth(0)));

// Performs the FFT-typical bit-reversal
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

// Multiplies two complex numbers
inline float2 complex_mult(float2 a, float2 b)
{
    float2 res;
    res.x = a.x * b.x - a.y * b.y;
    res.y = a.y * b.x + a.x * b.y;
    return res;
}

// Multiplies a complex number with its complex conjugate, and normalises the result according to the FFT size
inline float power_norm(float2 a)
{
    return (a.x * a.x + a.y * a.y) / (FFT_N_POINTS * FFT_N_POINTS);
}

/*
 * `tile_input` -- NDRange kernel
 *
 * Each work group loads one tile (which partially overlaps with its neighbours, [Fig. a)]) linearly into a buffer. The
 * buffer is used to split the tile into FFT_N_PARALLEL chunks. Then, each of the FFT_N_POINTS_PER_TERMINAL work items
 * feed one point from each chunk to the FFT engine, obeying the required arrival order (see kernel `fft` for details).
 *
 *  |─────────FDF_PADDED_INPUT_SZ────────|   │                                     │
 *  ┌────────────────────────────────────┐   │   ┌───────────────────────────┐     │  ┌──────┐
 *  │               input                │   │   │           tile            │     │  │buf[0]│─────▶ fft_in[0]
 *  └────────────────────────────────────┘   │   └───────────────────────────┘     │  └──────┘
 *  ┌────────┐    ┌────────┐    ┌────────┐   │       ║      ║      ║      ║        │  ┌──────┐
 *  │  tile  │    │  tile  │    │  tile  │   │       ▼      ▼      ▼      ▼        │  │buf[1]│─────▶ fft_in[1]
 *  └──────┬─┴────┴─┬────┬─┴────┴─┬──────┘   │   ┌──────┬──────┬──────┬──────┐     │  └──────┘
 *         │  tile  │    │  tile  │          │   │buf[0]│buf[2]│buf[1]│buf[3]│     │  ┌──────┐
 *         └────────┘    └────────┘          │   └──────┴──────┴──────┴──────┘     │  │buf[2]│─────▶ fft_in[2]
 *                                           │                                     │  └──────┘
 *  |────────|  FDF_TILE_SZ                  │   |──────| "chunk"                  │  ┌──────┐
 *  |──────|    FDF_TILE_PAYLOAD             │     FFT_N_POINTS_PER_TERMINAL       │  │buf[3]│─────▶ fft_in[3]
 *         |─|  FDF_TILE_OVERLAP             │   = FFT_N_POINTS / FFT_N_PARALLEL   │  └──────┘
 *                                           │                                     │
 *                     a)                    │                 b)                  │            c)
 */
__attribute__((reqd_work_group_size(FFT_N_POINTS_PER_TERMINAL, 1, 1)))
__attribute__((uses_global_work_offset(0)))
kernel void tile_input(global float2 * restrict input)
{
    // Buffer used to reorder the chunks in the current tile. Each chunk resides in its own memory bank.
    local float2 __attribute__((bank_bits(10,9))) buf[FFT_N_PARALLEL][FFT_N_POINTS_PER_TERMINAL];

    // Compute indices used in the following load
    uint tile = get_group_id(0);
    uint step = get_local_id(0);
    uint chunk = step / (FFT_N_POINTS_PER_TERMINAL / FFT_N_PARALLEL);
    uint chunk_rev = bit_reversed(chunk, FFT_N_PARALLEL_LOG);
    uint bundle = step % (FFT_N_POINTS_PER_TERMINAL / FFT_N_PARALLEL);

    // Load a bundle of FFT_N_PARALLEL points from `input`, and store them in the correct chunk buffer [Fig. b)]
    #pragma unroll
    for (uint p = 0; p < FFT_N_PARALLEL; ++p)
        buf[chunk_rev][bundle * FFT_N_PARALLEL + p] = input[tile   * FDF_TILE_PAYLOAD +
                                                            chunk  * FFT_N_POINTS_PER_TERMINAL +
                                                            bundle * FFT_N_PARALLEL + p];

    // Synchronise work items, and ensure coherent view of the local buffer
    barrier(CLK_LOCAL_MEM_FENCE);

    // Feed FFT_N_PARALLEL points to the FFT engine [Fig. c)]
    #pragma unroll
    for (uint p = 0; p < FFT_N_PARALLEL; ++p)
        WRITE_CHANNEL(fft_in[p], buf[p][step]);
}

/*
 * `fft` -- single-work item kernel, autorun
 *
 * The kernel uses a pipelined radix-2^2 feed-forward FFT architecture, as described in:
 *   M. Garrido, J. Grajal, M. A. Sanchez, and O. Gustafsson, ‘Pipelined Radix-2^k Feedforward FFT Architectures’,
 *     IEEE Trans. VLSI Syst., vol. 21, no. 1, 2013, doi: 10.1109/TVLSI.2011.2178275
 *
 * See also 'fft_4p.cl' for more implementation details.
 *
 * The kernel expects that FDF_N_TILES tiles are fed back-to-back to the input channels. The FFT engine requires
 * FFT_N_POINTS_PER_TERMINAL steps to process the tile, but its outputs are in bit-reversed order. Therefore we collect
 * all points in their natural order, and write them to the output channels with an additional delay of
 * FFT_N_POINTS_PER_TERMINAL steps. The kernel automatically flushes the engine with zeros after all tiles have been
 * consumed, and handles the double buffering required for the continuous output reordering.
 *
 * The data flow through the kernel (and the FFT engine in particular, cf. Fig. 3 in the paper) is illustrated below:
 *
 *  N = FFT_N_POINTS, P = FFT_N_PARALLEL, M = FFT_N_POINTS_PER_TERMINAL = N / P
 *              ~~~ shown here for N = 2048, P = 4 and M = 512 ~~~                              x is stored in:   x is written to
 *  ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔                                   output channels
 *  Point x of an N-sized tile arrives                            x leaves engine               buf[][][x mod M]  in step:
 *  in step:                                                      after step:
 *                                                                                              ┌─────────────┐
 *                      x mod M                                      rev<M>(x mod M) + M  ┌────▶│ buf[0|1][0] │   x mod M + 2 M
 *              ◀─────────────────────                             ◀────────────────────  │     ├─────────────┤
 *             ┌────┐ ┌────┬────┬────┐         ┌─────────────┐    ┌────┐ ┌────┬────┬────┐ │┌───▶│ buf[0|1][1] │
 *  and at    ││ 511│…│   2│   1│   0│─────0──▶│             │───▶│ 511│…│ 128│ 256│   0│─┘│    ├─────────────┤ ┌────▶ fft_out[0]
 *  terminal: │└────┘ └────┴────┴────┘  t      │             │    └────┘ └────┴────┴────┘  │┌──▶│ buf[0|1][2] │ │
 *            │┌────┐ ┌────┬────┬────┐  e      │             │    ┌────┐ ┌────┬────┬────┐  ││   ├─────────────┤ │
 *    rev<P>( ││1535│…│1026│1025│1024│──r──1──▶│.___.___.___.│───▶│1535│…│1152│1280│1024│──┘│┌─▶│ buf[0|1][3] │ │┌───▶ fft_out[1]
 *      x / M │└────┘ └────┴────┴────┘  m      │[__ [__   |  │    └────┘ └────┴────┴────┘   ││  ├─────────────┤ ││
 *    )       │┌────┐ ┌────┬────┬────┐  i      │|   |     |  │    ┌────┐ ┌────┬────┬────┐   ││  │ buf[1|0][0] │─┘│
 *            ││1023│…│ 514│ 513│ 512│──n──2──▶│             │───▶│1023│…│ 640│ 768│ 512│───┘│  ├─────────────┤  │┌──▶ fft_out[2]
 *            │└────┘ └────┴────┴────┘  a      │             │    └────┘ └────┴────┴────┘    │  │ buf[1|0][1] │──┘│
 *            │┌────┐ ┌────┬────┬────┐  l      │             │    ┌────┐ ┌────┬────┬────┐    │  ├─────────────┤   │
 *            ▼│2047│…│1538│1537│1536│─────3──▶│             │───▶│2047│…│1664│1792│1536│────┘  │ buf[1|0][2] │───┘┌─▶ fft_out[3]
 *             └────┘ └────┴────┴────┘         └─────────────┘    └────┘ └────┴────┴────┘       ├─────────────┤    │
 *                                                                                              │ buf[1|0][3] │────┘
 *                                                                                              └─────────────┘
 *                                                                                                  (double
 *                                                                                                 buffering)
 */
__attribute__((autorun))
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
__attribute__((num_compute_units(1)))
kernel void fft()
{
    // (Double) buffers used for result re-ordering
    float2 __attribute__((bank_bits(11))) buf[2][FFT_N_POINTS_PER_TERMINAL][FFT_N_PARALLEL];

    // Sliding window arrays, used internally by the FFT engine for data reordering
    float2 fft_delay_elements[FFT_N_POINTS + FFT_N_PARALLEL * (FFT_N_POINTS_LOG - 3)];

    // Buffers to hold engine's input/output in each iteration
    float2x4 data;

    // Process FDF_N_TILES actual tiles, +2 tiles of zeros in order to flush the engine and the output reordering stage
    #pragma loop_coalesce
    for (uint t = 0; t < FDF_N_TILES + 2; ++t) {
        for (uint s = 0; s < FFT_N_POINTS_PER_TERMINAL; ++s) {
            if (t >= 1) {
                // Valid results are available after FFT_N_POINTS_PER_TERMINAL steps, i.e. after 1 tile was consumed
                #pragma unroll
                for (uint p = 0; p < FFT_N_PARALLEL; ++p)
                    buf[1 - (t & 1)][bit_reversed(s, FFT_N_POINTS_PER_TERMINAL_LOG)][p] = data.i[p];
            }
            if (t >= 2) {
                // Valid results in natural order are available after 2 tiles were consumed
                #pragma unroll
                for (uint p = 0; p < FFT_N_PARALLEL; ++p)
                    WRITE_CHANNEL(fft_out[p], buf[t & 1][s][p]);
            }

            // Read actual input from the channels, respectively inject zeros to flush the pipeline
            if (t < FDF_N_TILES) {
                #pragma unroll
                for (uint p = 0; p < FFT_N_PARALLEL; ++p)
                    data.i[p] = READ_CHANNEL(fft_in[p]);
            } else {
                data.i0 = data.i1 = data.i2 = data.i3 = 0;
            }

            // Perform one step of the FFT engine
            data = fft_step(data, s, fft_delay_elements, 0 /* = forward FFT */, FFT_N_POINTS_LOG);
        }
    }
}

/*
 * `store_tiles` -- NDRange kernel
 *
 * Each work group stores one tile to global memory. FFT_N_POINTS_PER_TERMINAL work items capture the output of one step
 * each of the `fft` kernel, and store the FFT_N_PARALLEL values linearly to memory. No reordering is done.
 *
 *                ┌─────────────────────────────┐
 *                │            tile             │
 *                └─────────────────────────────┘
 *                      /     \
 *                     ┌─┬─┬─┬─┐
 *                  ...│ │ │ │ │...
 *                     └─┴─┴─┴─┘
 *                      ▲ ▲ ▲ ▲
 *  fft_out[0] ─────────┘ │ │ │
 *  fft_out[1] ───────────┘ │ │
 *  fft_out[2] ─────────────┘ │
 *  fft_out[3] ───────────────┘
 */
__attribute__((reqd_work_group_size(FFT_N_POINTS_PER_TERMINAL, 1, 1)))
__attribute__((uses_global_work_offset(0)))
kernel void store_tiles(global float2 * restrict tiles)
{
    uint tile = get_group_id(0);
    uint step = get_local_id(0);

    #pragma unroll
    for (uint p = 0; p < FFT_N_PARALLEL; ++p)
       tiles[tile * FDF_TILE_SZ + step * FFT_N_PARALLEL + p] = READ_CHANNEL(fft_out[p]);
}

/*
 * `mux_and_mul` -- NDRange kernel, 2D
 *
 * Multiplies a tile with a batch of filters (i.e. N_FILTERS_PARALLEL-many) in parallel, and feeds the results to the
 * `ifft` kernel instances. This kernel operates on a two-dimensional NDRange: dimension 0 represents the tiles,
 * dimension 1 the filter batches. The work group size is (1 tile = FFT_N_POINTS_PER_TERMINAL work items, 1 batch).
 *
 * Both global memories are expected to be in FFT-order (cf. kernel `fft` and `store_tiles`). This allows us to linearly
 * read FFT_N_PARALLEL values from memory, perform the element-wise complex multiplication, and write the results to the
 * output channels without reordering.
 */
__attribute__((reqd_work_group_size(FFT_N_POINTS_PER_TERMINAL, 1, 1)))
__attribute__((uses_global_work_offset(0)))
kernel void mux_and_mult(global float2 * restrict tiles,
                         global float2 * restrict templates)
{
    uint batch = get_group_id(1) * N_FILTERS_PARALLEL;
    uint tile = get_group_id(0);
    uint step = get_local_id(0);

    #pragma unroll
    for (uint f = 0; f < N_FILTERS_PARALLEL; ++f) {
        #pragma unroll
        for (uint p = 0; p < FFT_N_PARALLEL; ++p) {
            float2 prod = complex_mult(tiles    [tile        * FDF_TILE_SZ + step * FFT_N_PARALLEL + p],
                                       templates[(batch + f) * FDF_TILE_SZ + step * FFT_N_PARALLEL + p]);
            WRITE_CHANNEL(ifft_in[f][p], prod);
        }
    }
}

/*
 * `ifft` -- single-work item kernel, autorun, N_FILTERS_PARALLEL instances
 *
 * This kernel is almost identical to `fft`. Differences:
 *  - hard-wired to perform inverse FFT
 *  - instantiated N_FILTERS_PARALLEL times
 *  - processes (N_FILTER_BATCHES * FDF_N_TILES)-many tiles, as provided by kernel `mux_and_mult`
 *
 * Note: Ideally, we would leave one instance configurable to perform both directions of the FT, and save kernel `fft`
 *       altogether. However it seems difficult to use a particular compute unit in different stages of the pipeline
 *       (main problem: each channel is statically connected to a source and a sink kernel).
 */
__attribute__((autorun))
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
__attribute__((num_compute_units(N_FILTERS_PARALLEL)))
kernel void ifft()
{
    // The compute unit ID is used to connect each instance to the correct set of I/O channels
    uint cid = get_compute_id(0);

    // (Double) buffers used for result re-ordering
    float2 __attribute__((bank_bits(11))) buf[2][FFT_N_POINTS_PER_TERMINAL][FFT_N_PARALLEL];

    // Sliding window arrays, used internally by the FFT engine for data reordering
    float2 fft_delay_elements[FFT_N_POINTS + FFT_N_PARALLEL * (FFT_N_POINTS_LOG - 3)];

    // Buffers to hold engine's input/output in each iteration
    float2x4 data;

    // Process N_FILTER_BATCHES * FDF_N_TILES actual tiles, +2 tiles of zeros in order to flush the engine and the
    // output reordering stage
    #pragma loop_coalesce
    for (uint t = 0; t < N_FILTER_BATCHES * FDF_N_TILES + 2; ++t) {
        for (uint s = 0; s < FFT_N_POINTS_PER_TERMINAL; ++s) {
            if (t >= 1) {
                // Valid results are available after FFT_N_POINTS_PER_TERMINAL steps, i.e. after 1 tile was consumed
                #pragma unroll
                for (uint p = 0; p < FFT_N_PARALLEL; ++p)
                    buf[1 - (t & 1)][bit_reversed(s, FFT_N_POINTS_PER_TERMINAL_LOG)][p] = data.i[p];
            }
            if (t >= 2) {
                // Valid results in natural order are available after 2 tiles were consumed
                #pragma unroll
                for (uint p = 0; p < FFT_N_PARALLEL; ++p)
                    WRITE_CHANNEL(ifft_out[cid][p], buf[t & 1][s][p]);
            }

            // Read actual input from the channels, respectively inject zeros to flush the pipeline
            if (t < N_FILTER_BATCHES * FDF_N_TILES) {
                #pragma unroll
                for (uint p = 0; p < FFT_N_PARALLEL; ++p)
                    data.i[p] = READ_CHANNEL(ifft_in[cid][p]);
            } else {
                data.i0 = data.i1 = data.i2 = data.i3 = 0;
            }

            // Perform one step of the FFT engine
            data = fft_step(data, s, fft_delay_elements, 1 /* = inverse FFT */, FFT_N_POINTS_LOG);
        }
    }
}

/*
 * `square_and_discard` -- NDRange kernel, 2D
 *
 * Demultiplexes the output of the `ifft` instances into the filter-output plane, computing the points' power and
 * discarding invalid elements in the process.
 *
 * This kernel is the counterpart to `mux_and_multiply`, and must use the same NDRange configuration (work group size =
 * (1 tile = FFT_N_POINTS_PER_TERMINAL work items, 1 batch)) in order to correctly associate the incoming data with a
 * tile and filter batch number.
 *
 * The FOP is written as a two-dimensional array `fop[N_FILTERS][FDF_OUTPUT_SZ]` in global memory. A single work item
 * exhibits a column-wise access pattern, and we currently rely on the the memory system's ability to coalesce at least
 * some of these accesses behind the scenes.
 */
__attribute__((reqd_work_group_size(FFT_N_POINTS_PER_TERMINAL, 1, 1)))
__attribute__((uses_global_work_offset(0)))
kernel void square_and_discard(global float * restrict fop)
{
    // Private buffer to collect the output from one step of the `ifft` instances
    float buf[N_FILTERS_PARALLEL][FFT_N_PARALLEL];

    // Establish indices for the current work item
    uint batch = get_group_id(1) * N_FILTERS_PARALLEL;
    uint tile = get_group_id(0);
    uint step = get_local_id(0);

    // Query all incoming channels, and compute the normalised spectral power of each point
    #pragma unroll
    for (uint f = 0; f < N_FILTERS_PARALLEL; ++f) {
        #pragma unroll
        for (uint p = 0; p < FFT_N_PARALLEL; ++p)
            buf[f][p] = power_norm(READ_CHANNEL(ifft_out[f][p]));
    }

    // Discard invalid parts of tiles (cf. overlap-save algorithm) while writing to the FOP
    #pragma unroll
    for (uint f = 0; f < N_FILTERS_PARALLEL; ++f) {
        #pragma unroll
        for (uint p = 0; p < FFT_N_PARALLEL; ++p) {
            // We need to undo the bit-reversal of the chunk indices, as the buffer was populated with FFT-ordered data
            uint q = bit_reversed(p, FFT_N_PARALLEL_LOG);

            // `element` is the index of the current item in its destination tile in the FOP, i.e. shifted by the
            // amount of overlap we need to discard
            int element = p * FFT_N_POINTS_PER_TERMINAL + step - FDF_TILE_OVERLAP;
            if (element >= 0)
                fop[(batch + f) * FDF_OUTPUT_SZ + tile * FDF_TILE_PAYLOAD + element] = buf[f][q];
        }
    }
}
