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
 * The kernels in this file convolve the contents of global memory `input` with the templates in `templates` and write
 * the result to `fop`, the so-called filter-output plane. (From n DSP viewpoint, the convolution is equivalent to
 * applying an FIR _filter_ to the input signal.)
 *
 * The overall architecture is shown below. We are using an overlap-save algorithm on the Fourier-transformed input and
 * template coefficients, parameterised by the macro definitions in fdas_config.h. See the comments on the individual
 * kernels for a description of their input/output data formats.
 *
 *                                            FFT_N_PARALLEL
 *                                               channels
 *                               ┏━━━━━━━━━━━━━━┓        ┏━━━━━━━━┓        ┏━━━━━━━━━━━━━┓
 *  ╔═══════════════════╗        ┃              ┃───────▶┃        ┃───────▶┃             ┃        ╔══════════════════╗
 *  ║       input       ║═══════▶┃  tile_input  ┃───────▶┃  fft   ┃───────▶┃ store_tiles ┃═══════▶║      tiles       ║
 *  ╚═══════════════════╝        ┃              ┃───────▶┃        ┃───────▶┃             ┃        ╚══════════════════╝
 *    <padded_input_sz>          ┃              ┃───────▶┃        ┃───────▶┃             ┃          <tiled_input_sz>
 *         * float2              ┗━━━━━━━━━━━━━━┛        ┗━━━━━━━━┛        ┗━━━━━━━━━━━━━┛              * float2
 *                                NDRange                    Task           NDRange
 *       linear order                                                                               tiled, FFT-order
 *                                  1 workgroup        (<n_tiles> + 2)        1 workgroup
 *                                = NPPT items         * NPPT iterations    = NPPT items
 *
 *                                covers 1 tile       incl. bit-reversal    covers 1 tile
 *
 *
 *
 *                                             FTC_GROUP_SZ
 *                                           * FFT_N_PARALLEL
 *                                               channels
 *                               ┏━━━━━━━━━━━━━━┓        ┏━━━━━━━━┓        ┏━━━━━━━━━━━━━━┓
 *   ╔══════════════════╗        ┃              ┃───────▶┃        ┃───────▶┃              ┃        ╔═══════════════╗
 *   ║      tiles       ║═══════▶┃              ┃───────▶┃ ifft_0 ┃───────▶┃              ┃═══════▶║      fop      ║
 *   ╚══════════════════╝        ┃              ┃───────▶┃        ┃───────▶┃              ┃        ╚═══════════════╝
 *     <tiled_input_sz>          ┃              ┃───────▶┃        ┃───────▶┃              ┃         <fop_sz> * float
 *         * float2              ┃              ┃        ┗━━━━━━━━┛        ┃              ┃
 *                               ┃              ┃        ┏━━━━━━━━┓        ┃              ┃           linear order
 *     tiled, FFT-order          ┃              ┃───────▶┃        ┃───────▶┃              ┃         dim 1: templates
 *                               ┃              ┃───────▶┃ ifft_1 ┃───────▶┃              ┃       dim 2: frequency bins
 *                               ┃              ┃───────▶┃        ┃───────▶┃  square_and  ┃
 *                               ┃ mux_and_mult ┃───────▶┃        ┃───────▶┃   _discard   ┃
 *                               ┃              ┃        ┗━━━━━━━━┛        ┃              ┃
 *                               ┃              ┃   .        .        .    ┃              ┃
 *   ╔══════════════════╗        ┃              ┃   .        .        .    ┃              ┃
 *   ║    templates     ║═══════▶┃              ┃   .        .        .    ┃              ┃
 *   ╚══════════════════╝        ┃              ┃        ┏━━━━━━━━┓        ┃              ┃
 *      <templates_sz>           ┃              ┃───────▶┃        ┃───────▶┃              ┃
 *         * float2              ┃              ┃───────▶┃ ifft_N ┃───────▶┃              ┃
 *                               ┃              ┃───────▶┃        ┃───────▶┃              ┃
 *     tiled, FFT-order          ┃              ┃───────▶┃        ┃───────▶┃              ┃
 *                               ┗━━━━━━━━━━━━━━┛        ┗━━━━━━━━┛        ┗━━━━━━━━━━━━━━┛
 *                                NDRange (2D)          FTC_GROUP_SZ        NDRange (2D)
 *                                                          tasks
 *                                  1 workgroup                               1 workgroup
 *                                = NPPT items           <n_groups>         = NPPT items
 *                                                    * (<n_tiles> + 2)
 *                                covers 1 tile,      * NPPT iterations     covers 1 tile,
 *                                1 group of                                1 group of
 *                                templates          incl. bit-reversal     templates
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
 *                 <xyz_sz> runtime parameter         ...,  ...,  ...,  ...,
 *                          computed by host          511, 1535, 1023, 2047
 */

// Include a 4-parallel FFT engine
#include "fft_4p.cl"

// Enable channels
#pragma OPENCL EXTENSION cl_intel_channels : enable

// Channels from and to the FFT engines. Indices 0..FTC_GROUP_SZ-1 are
// connected to the iFFT engines; index FTC_GROUP_SZ is used by to the
// (forward) FFT engine
channel float2 fft_in[FTC_GROUP_SZ + 1][FFT_N_PARALLEL] __attribute__((depth(0)));
channel float2 fft_out[FTC_GROUP_SZ + 1][FFT_N_PARALLEL] __attribute__((depth(0)));

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
 * feed one point from each chunk to the FFT engine, obeying the required arrival order (see `do_fft` for details).
 *
 *  |───────── <padded_input_sz> ────────|   │                                     │
 *  ┌────────────────────────────────────┐   │   ┌───────────────────────────┐     │  ┌──────┐
 *  │               input                │   │   │           tile            │     │  │buf[0]│─────▶ fft_in[0]
 *  └────────────────────────────────────┘   │   └───────────────────────────┘     │  └──────┘
 *  ┌────────┐    ┌────────┐    ┌────────┐   │       ║      ║      ║      ║        │  ┌──────┐
 *  │  tile  │    │  tile  │    │  tile  │   │       ▼      ▼      ▼      ▼        │  │buf[1]│─────▶ fft_in[1]
 *  └──────┬─┴────┴─┬────┬─┴────┴─┬──────┘   │   ┌──────┬──────┬──────┬──────┐     │  └──────┘
 *         │  tile  │    │  tile  │          │   │buf[0]│buf[2]│buf[1]│buf[3]│     │  ┌──────┐
 *         └────────┘    └────────┘          │   └──────┴──────┴──────┴──────┘     │  │buf[2]│─────▶ fft_in[2]
 *                                           │                                     │  └──────┘
 *  |────────|  FTC_TILE_SZ                  │   |──────| "chunk"                  │  ┌──────┐
 *  |──────|    FTC_TILE_PAYLOAD             │     FFT_N_POINTS_PER_TERMINAL       │  │buf[3]│─────▶ fft_in[3]
 *         |─|  FTC_TILE_OVERLAP             │   = FFT_N_POINTS / FFT_N_PARALLEL   │  └──────┘
 *                                           │                                     │
 *                     a)                    │                 b)                  │            c)
 */
__attribute__((reqd_work_group_size(FFT_N_POINTS_PER_TERMINAL, 1, 1)))
kernel void tile_input(global volatile float2 * restrict input)
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
        buf[chunk_rev][bundle * FFT_N_PARALLEL + p] = input[tile   * FTC_TILE_PAYLOAD +
                                                            chunk  * FFT_N_POINTS_PER_TERMINAL +
                                                            bundle * FFT_N_PARALLEL + p];

    // Synchronise work items, and ensure coherent view of the local buffer
    barrier(CLK_LOCAL_MEM_FENCE);

    // Feed FFT_N_PARALLEL points to the FFT engine [Fig. c)]
    #pragma unroll
    for (uint p = 0; p < FFT_N_PARALLEL; ++p)
        write_channel_intel(fft_in[FTC_GROUP_SZ][p], buf[p][step]);
}

/*
 * We use a pipelined radix-2^2 feed-forward FFT architecture, as described in:
 *   M. Garrido, J. Grajal, M. A. Sanchez, and O. Gustafsson, ‘Pipelined Radix-2^k Feedforward FFT Architectures’,
 *     IEEE Trans. VLSI Syst., vol. 21, no. 1, 2013, doi: 10.1109/TVLSI.2011.2178275
 *
 * See also 'fft_4p.cl' for more implementation details.
 *
 * This implementation expects that `n_tiles` tiles are fed back-to-back to the input channels. The FFT engine requires
 * FFT_N_POINTS_PER_TERMINAL steps to process the tile, but its outputs are in bit-reversed order. Therefore we collect
 * all points in their natural order, and write them to the output channels with an additional delay of
 * FFT_N_POINTS_PER_TERMINAL steps. This function automatically flushes the engine with zeros after all tiles have been
 * consumed, and handles the double buffering required for the continuous output reordering.
 *
 * The data flow through the FFT engine (cf. Fig. 3 in the paper) is illustrated below:
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
inline void do_fft(const uint n_tiles,
                   const uint is_inverse,
                   const uint channel_num)
{
    // (Double) buffers used for result re-ordering
    float2 __attribute__((bank_bits(11))) buf[2][FFT_N_POINTS_PER_TERMINAL][FFT_N_PARALLEL];

    // Sliding window arrays, used internally by the FFT engine for data reordering
    float2 fft_delay_elements[FFT_N_POINTS + FFT_N_PARALLEL * (FFT_N_POINTS_LOG - 3)];

    // Buffers to hold engine's input/output in each iteration
    float2x4 data;

    // Process `n_tiles` actual tiles, +2 tiles of zeros in order to flush the engine and the output reordering stage
    #pragma loop_coalesce
    for (uint tile = 0; tile < n_tiles + 2; ++tile) {
        for (uint step = 0; step < FFT_N_POINTS_PER_TERMINAL; ++step) {
            if (tile >= 1) {
                // Valid results are available after FFT_N_POINTS_PER_TERMINAL steps, i.e. after 1 tile was consumed
                #pragma unroll
                for (uint p = 0; p < FFT_N_PARALLEL; ++p)
                    buf[1 - (tile & 1)][bit_reversed(step, FFT_N_POINTS_PER_TERMINAL_LOG)][p] = data.i[p];
            }
            if (tile >= 2) {
                // Valid results in natural order are available after 2 tiles were consumed
                #pragma unroll
                for (uint p = 0; p < FFT_N_PARALLEL; ++p)
                    write_channel_intel(fft_out[channel_num][p], buf[tile & 1][step][p]);
            }

            // Read actual input from the channels, respectively inject zeros to flush the pipeline
            if (tile < n_tiles) {
                #pragma unroll
                for (uint p = 0; p < FFT_N_PARALLEL; ++p)
                    data.i[p] = read_channel_intel(fft_in[channel_num][p]);
            } else {
                data.i0 = data.i1 = data.i2 = data.i3 = 0;
            }

            // Perform one step of the FFT engine
            data = fft_step(data, step, fft_delay_elements, is_inverse, FFT_N_POINTS_LOG);
        }
    }
}

// Macro to instantiate FFT engine as a kernel
#define FFT_KERNEL(name, is_inverse, channel_num) \
__attribute__((max_global_work_dim(0)))           \
kernel void name (const uint n_tiles)             \
{                                                 \
    do_fft(n_tiles, is_inverse, channel_num);     \
}

/*
 * `fft` -- single-work item kernel
 */
FFT_KERNEL(fft, 0, FTC_GROUP_SZ)

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
kernel void store_tiles(global float2 * restrict tiles)
{
    uint tile = get_group_id(0);
    uint step = get_local_id(0);

    #pragma unroll
    for (uint p = 0; p < FFT_N_PARALLEL; ++p)
       tiles[tile * FTC_TILE_SZ + step * FFT_N_PARALLEL + p] = read_channel_intel(fft_out[FTC_GROUP_SZ][p]);
}

/*
 * `mux_and_mul` -- NDRange kernel, 2D
 *
 * Multiplies a tile with a group of templates (i.e. FTC_GROUP_SZ-many) in parallel, and feeds the results to the
 * `ifft_<n>` kernel instances. This kernel operates on a two-dimensional NDRange: dimension 0 represents the tiles,
 * dimension 1 the template groups. The work group size is:
 *   (1 tile = FFT_N_POINTS_PER_TERMINAL work items, 1 group of templates)
 *
 * Both global memories are expected to be in FFT-order (cf. kernel `fft` and `store_tiles`). This allows us to linearly
 * read FFT_N_PARALLEL values from memory, perform the element-wise complex multiplication, and write the results to the
 * output channels without reordering.
 */
__attribute__((reqd_work_group_size(FFT_N_POINTS_PER_TERMINAL, 1, 1)))
kernel void mux_and_mult(global volatile float2 * restrict tiles,
                         global volatile float2 * restrict templates)
{
    // Establish indices
    uint group = get_group_id(1) * FTC_GROUP_SZ;
    uint tile = get_group_id(0);
    uint step = get_local_id(0);

    // Load one bundle from the input tile
    float2 tile_load[FFT_N_PARALLEL];
    #pragma unroll
    for (uint p = 0; p < FFT_N_PARALLEL; ++p)
        tile_load[p] = tiles[tile * FTC_TILE_SZ + step * FFT_N_PARALLEL + p];

    // Load bundles of template coefficients, multiply, and emit to the iFFT engines' input channels
    #pragma unroll
    for (uint i = 0; i < FTC_GROUP_SZ; ++i) {
        uint tmpl = group + i;
        if (tmpl < N_TEMPLATES) {
            float2 tmpl_load[FFT_N_PARALLEL];
            #pragma unroll
            for (uint p = 0; p < FFT_N_PARALLEL; ++p)
                tmpl_load[p] = templates[tmpl * FTC_TILE_SZ + step * FFT_N_PARALLEL + p];

            #pragma unroll
            for (uint p = 0; p < FFT_N_PARALLEL; ++p) {
                float2 prod = complex_mult(tile_load[p], tmpl_load[p]);
                write_channel_intel(fft_in[i][p], prod);
            }
        }
    }
}

/*
 * `ifft_<n>` -- single-work item kernels
 */
FFT_KERNEL(ifft_0, 1, 0)
#if FTC_GROUP_SZ > 1
FFT_KERNEL(ifft_1, 1, 1)
#if FTC_GROUP_SZ > 2
FFT_KERNEL(ifft_2, 1, 2)
#if FTC_GROUP_SZ > 3
FFT_KERNEL(ifft_3, 1, 3)
#if FTC_GROUP_SZ > 4
FFT_KERNEL(ifft_4, 1, 4)
#if FTC_GROUP_SZ > 5
FFT_KERNEL(ifft_5, 1, 5)
#if FTC_GROUP_SZ > 6
FFT_KERNEL(ifft_6, 1, 6)
#if FTC_GROUP_SZ > 7
#error "Instantiate more iFFT kernels"
#endif
#endif
#endif
#endif
#endif
#endif
#endif

/*
 * `square_and_discard` -- NDRange kernel, 2D
 *
 * Demultiplexes the output of the `ifft_<n>` instances into the filter-output plane, computing the points' power and
 * discarding invalid elements in the process.
 *
 * This kernel is the counterpart to `mux_and_multiply`, and must use the same NDRange configuration (work group size =
 * (1 tile = FFT_N_POINTS_PER_TERMINAL work items, 1 group of templates)) in order to correctly associate the incoming
 * data with a tile and template group number.
 *
 * The FOP is written as a two-dimensional array `fop[N_TEMPLATES][<n_frequency_bins>]` in global memory. A single work
 * item exhibits a column-wise access pattern, and we currently rely on the the memory system's ability to coalesce at
 * least some of these accesses behind the scenes.
 */
__attribute__((reqd_work_group_size(FFT_N_POINTS_PER_TERMINAL, 1, 1)))
kernel void square_and_discard(global float * restrict fop,
                               const uint n_frequency_bins)
{
    // Private buffer to collect the output from one step of the `ifft` instances
    float buf[FTC_GROUP_SZ][FFT_N_PARALLEL];

    // Establish indices for the current work item
    uint group = get_group_id(1) * FTC_GROUP_SZ;
    uint tile = get_group_id(0);
    uint step = get_local_id(0);

    // Query all incoming channels, and compute the normalised spectral power of each point
    #pragma unroll
    for (uint i = 0; i < FTC_GROUP_SZ; ++i) {
        uint tmpl = group + i;
        if (tmpl < N_TEMPLATES) {
            #pragma unroll
            for (uint p = 0; p < FFT_N_PARALLEL; ++p)
                buf[i][p] = power_norm(read_channel_intel(fft_out[i][p]));
        } else {
            #pragma unroll
            for (uint p = 0; p < FFT_N_PARALLEL; ++p)
                buf[i][p] = 0.0f;
        }
    }

    // Discard invalid parts of tiles (cf. overlap-save algorithm) while writing to the FOP
    #pragma unroll
    for (uint i = 0; i < FTC_GROUP_SZ; ++i) {
        uint tmpl = group + i;
        if (tmpl < N_TEMPLATES) {
            #pragma unroll
            for (uint p = 0; p < FFT_N_PARALLEL; ++p) {
                // We need to undo the bit-reversal of the chunk indices, as the buffer was populated with FFT-ordered data
                uint q = bit_reversed(p, FFT_N_PARALLEL_LOG);

                // `element` is the index of the current item in its destination tile in the FOP, i.e. shifted by the
                // amount of overlap we need to discard
                int element = p * FFT_N_POINTS_PER_TERMINAL + step - FTC_TILE_OVERLAP;
                if (element >= 0 && tile * FTC_TILE_PAYLOAD + element < n_frequency_bins)
                    fop[tmpl * n_frequency_bins + tile * FTC_TILE_PAYLOAD + element] = buf[i][q];
            }
        }
    }
}
