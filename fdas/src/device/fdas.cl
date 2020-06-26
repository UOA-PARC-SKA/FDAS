
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

/*
 * Channels to and from the FFT engine(s). Currently, this implementation instantiates two FFT engines, and therefore
 * supports two independent streams (_0 and _1) of data through the kernels.
 */
channel float2 fwd_fft_input[FFT_N_PARALLEL] __attribute__((depth(0)));
channel float2 fwd_fft_output[FFT_N_PARALLEL] __attribute__((depth(0)));

channel float2 fft_input_0[FFT_N_PARALLEL] __attribute__((depth(0)));
channel float2 fft_input_1[FFT_N_PARALLEL] __attribute__((depth(0)));

channel float fft_output_0[FFT_N_PARALLEL] __attribute__((depth(0)));
channel float fft_output_1[FFT_N_PARALLEL] __attribute__((depth(0)));

/*
 * Helper to perform the FFT-typical bit-reversal.
 */
inline int bit_reversed(int x, int bits) {
    int y = 0;
    #pragma unroll
    for (int i = 0; i < bits; i++) {
        y <<= 1;
        y |= x & 1;
        x >>= 1;
    }
    return y;
}

__attribute__((reqd_work_group_size(FFT_N_POINTS_PER_TERMINAL, 1, 1)))
kernel void fwd_fetch(global float2 *input) {
    local float2 __attribute__((bank_bits(10,9))) buf[FFT_N_PARALLEL][FFT_N_POINTS_PER_TERMINAL];

    int lid = get_local_id(0);

    int chunk_off = lid % (FFT_N_POINTS_PER_TERMINAL / FFT_N_PARALLEL);
    int chunk_idx = lid / (FFT_N_POINTS_PER_TERMINAL / FFT_N_PARALLEL);
    int chunk_rev = bit_reversed(chunk_idx, FFT_N_PARALLEL_LOG);
    int input_base = get_group_id(0) * FDF_TILE_PAYLOAD + chunk_idx * FFT_N_POINTS_PER_TERMINAL + chunk_off * FFT_N_PARALLEL;

    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
        buf[chunk_rev][chunk_off * FFT_N_PARALLEL + p] = input[input_base + p];

    barrier(CLK_LOCAL_MEM_FENCE);

    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
        WRITE_CHANNEL(fwd_fft_input[p], buf[p][lid]);
}

__attribute__((task))
kernel void fwd_fft() {
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
                    WRITE_CHANNEL(fwd_fft_output[p], buf[t & 1][s][p]);
            }

            // Read actual input from the channels, respectively inject zeroes to flush the pipeline
            if (t < FDF_N_TILES) {
                #pragma unroll
                for (int p = 0; p < FFT_N_PARALLEL; ++p)
                    data.i[p] = READ_CHANNEL(fwd_fft_input[p]);
            } else {
                data.i0 = data.i1 = data.i2 = data.i3 = 0;
            }

            // Perform one step of the FFT engine
            data = fft_step(data, s, fft_delay_elements, 0, FFT_N_POINTS_LOG);
        }
    }
}

__attribute__((reqd_work_group_size(FFT_N_POINTS_PER_TERMINAL, 1, 1)))
kernel void fwd_reversed(global float2 *tiles) {
    local float2 __attribute__((bank_bits(10,9))) buf[FFT_N_PARALLEL][FFT_N_POINTS_PER_TERMINAL];

    int lid = get_local_id(0);

    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
        buf[p][lid] = READ_CHANNEL(fwd_fft_output[p]);

    barrier(CLK_LOCAL_MEM_FENCE);

    int chunk_off = lid % (FFT_N_POINTS_PER_TERMINAL / FFT_N_PARALLEL);
    int chunk_idx = lid / (FFT_N_POINTS_PER_TERMINAL / FFT_N_PARALLEL);
    int chunk_rev = bit_reversed(chunk_idx, FFT_N_PARALLEL_LOG);
    int tiles_base = get_group_id(0) * FDF_TILE_SZ + chunk_idx * FFT_N_POINTS_PER_TERMINAL + chunk_off * FFT_N_PARALLEL;

    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
       tiles[tiles_base + p] = buf[chunk_rev][chunk_off * FFT_N_PARALLEL + p];
}

/*
 * NDRange kernel 'fetch':
 *   Multiplies tiles of 2048 complex input values with 2048-element wide filter templates. The result is reordered and
 *   passed to the 'fdfir' kernel via channels.
 *
 * The kernel handles two filter templates (indices 'i' and 'i+43', i.e. one from both filter groups) in parallel.
 *
 * A work group consists of 2048 work items. Each work item handles 4 input values at once. Therefore, a work group
 * covers 8192 complex input values, and cycles 4 times through the filter coefficients.
 *
 *     ◀───────── work group = 2048 work items ──────────▶
 *    ┌────────────┬────────────┬────────────┬────────────┐
 * ...│2048 inputs │2048 inputs │2048 inputs │2048 inputs │...
 *    └────────────┴────────────┴────────────┴────────────┘
 *          x            x            x            x
 *    ┌────────────┬────────────┬────────────┬────────────┐
 *    │filter[i]   │filter[i]   │filter[i]   │filter[i]   │
 *    ├────────────┼────────────┼────────────┼────────────┤
 *    │filter[i+43]│filter[i+43]│filter[i+43]│filter[i+43]│
 *    └────────────┴────────────┴────────────┴────────────┘
 *     ◀──512 WI──▶ ◀──512 WI──▶ ◀──512 WI──▶ ◀──512 WI──▶
 */
__attribute__((reqd_work_group_size(NDR_WORK_GROUP_SZ, 1, 1)))
kernel void fetch(global float2 *restrict src,
                  global float2 *restrict tmpl,
                  const int tmpl_idx_0,
                  const int tmpl_idx_1) {

    // One buffer per filter template, sized to hold the work group's multiplication result
    local float2 buf_0[NDR_N_POINTS_PER_WORK_GROUP];
    local float2 buf_1[NDR_N_POINTS_PER_WORK_GROUP];

    // Work item's base index in 'src' is its global id scaled by 4 (because each WI handles 4 values)
    int src_base = get_global_id(0) * NDR_N_POINTS_PER_WORK_ITEM;

    // Work item's base index in the local buffers its local id scaled by 4 (because each WI handles 4 values)
    int item_base = get_local_id(0) * NDR_N_POINTS_PER_WORK_ITEM;

    // The base indices in 'coef_0': 'filter_index' (resp. 'filter_index'+43) selects a particular filter template.
    // Then, the work item's local id, modulo 512, is scaled by 4 to refer to a 4-pack of coefficients.
    // Note: The device buffer behind 'coef_0' holds 86 templates. The bogus 86th filter output is discarded later
    int tmpl_base_0 = tmpl_idx_0 * FDF_TILE_SZ + NDR_N_POINTS_PER_WORK_ITEM * (get_local_id(0) % NDR_N_WORK_ITEMS_PER_TILE);
    int tmpl_base_1 = tmpl_idx_1 * FDF_TILE_SZ + NDR_N_POINTS_PER_WORK_ITEM * (get_local_id(0) % NDR_N_WORK_ITEMS_PER_TILE);

    // Complex multiplications. The base indices compute above are scaled again by 2 in order to address the individual,
    // i.e. real and imaginary, floating point values in 'src' and 'coef_0'
    #pragma unroll
    for (int p = 0; p < NDR_N_POINTS_PER_WORK_ITEM; ++p) {
        buf_0[item_base + p].x = src[src_base + p].x * tmpl[tmpl_base_0 + p].x - src[src_base + p].y * tmpl[tmpl_base_0 + p].y;
        buf_0[item_base + p].y = src[src_base + p].y * tmpl[tmpl_base_0 + p].x + src[src_base + p].x * tmpl[tmpl_base_0 + p].y;
    }

    #pragma unroll
    for (int p = 0; p < NDR_N_POINTS_PER_WORK_ITEM; ++p) {
        buf_1[item_base + p].x = src[src_base + p].x * tmpl[tmpl_base_1 + p].x - src[src_base + p].y * tmpl[tmpl_base_1 + p].y;
        buf_1[item_base + p].y = src[src_base + p].y * tmpl[tmpl_base_1 + p].x + src[src_base + p].x * tmpl[tmpl_base_1 + p].y;
    }

    // Synchronise work items, and ensure coherent view of the local buffers
    barrier(CLK_LOCAL_MEM_FENCE);

    // 'base' refers to one of the 4 tiles handled by this work group
    int tile_base = get_local_id(0) / NDR_N_WORK_ITEMS_PER_TILE * FDF_TILE_SZ;
    // 'offset' is the work item's local id modulo 512
    int offset = get_local_id(0) % NDR_N_WORK_ITEMS_PER_TILE;

    // Write multiplication result to channels. The particular order of elements is mandated by the FFT engine, see
    // also kernel 'fdfir'
    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
        WRITE_CHANNEL(fft_input_0[p], buf_0[tile_base + bit_reversed(p, FFT_N_PARALLEL_LOG) * (FFT_N_POINTS / FFT_N_PARALLEL) + offset]);

    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
        WRITE_CHANNEL(fft_input_1[p], buf_1[tile_base + bit_reversed(p, FFT_N_PARALLEL_LOG) * (FFT_N_POINTS / FFT_N_PARALLEL) + offset]);
}

/*
 * Single work item kernel 'fdfir':
 *   Performs a tile-wise inverse FFT on the 'fetch'ed data, computes the spectral power of the result, and passes it
 *   on to the 'reversed' kernel.
 *
 * The kernel uses a pipelined radix-2^2 feed-forward FFT architecture, as described in:
 *   M. Garrido, J. Grajal, M. A. Sanchez, and O. Gustafsson, ‘Pipelined Radix-2^k Feedforward FFT Architectures’,
 *     IEEE Trans. VLSI Syst., vol. 21, no. 1, 2013, doi: 10.1109/TVLSI.2011.2178275
 *
 * The particular configuration used here accepts 4 input points in each step, and requires 512 steps to process a
 * 2048-element tile of data. Multiple tiles can be fed back-to-back to the engine. At the end, zeroes are inserted
 * for 511 additional steps, in order to flush out the last valid results. See 'fft_4p.cl' for more details.
 *
 * The dataflow through the engine is as follows (cf. Fig. 3 in the paper):
 *
 *                    Point i arrives in step:                          Result i arrives in step:
 *
 *                                                                              bit-reverse(
 *                                                                               i mod (N/P)
 *                      ◀─────i mod (N/P)─────                             ◀─── ) >> logP    ───
 *                     ┌────┐ ┌────┬────┬────┐         ┌─────────────┐    ┌────┐ ┌────┬────┬────┐
 *                    ││ 511│…│   2│   1│   0│─────0──▶│.___.___.___.│───▶│ 511│…│ 128│ 256│   0│
 *                    │└────┘ └────┴────┴────┘  t      │[__ [__   |  │    └────┘ └────┴────┴────┘
 *  Terminal:         │┌────┐ ┌────┬────┬────┐  e      │|   |     |  │    ┌────┐ ┌────┬────┬────┐
 *                    ││1535│…│1026│1025│1024│──r──1──▶│             │───▶│1535│…│1152│1280│1024│
 *   bit-reverse(     │└────┘ └────┴────┴────┘  m      │ N    = 2048 │    └────┘ └────┴────┴────┘
 *    i >> (logN-logP)│┌────┐ ┌────┬────┬────┐  i      │ P    =    4 │    ┌────┐ ┌────┬────┬────┐
 *   )                ││1023│…│ 514│ 513│ 512│──n──2──▶│             │───▶│1023│…│ 640│ 768│ 512│
 *                    │└────┘ └────┴────┴────┘  a      │ lat. =  N/P │    └────┘ └────┴────┴────┘
 *                    │┌────┐ ┌────┬────┬────┐  l      │ II   =    1 │    ┌────┐ ┌────┬────┬────┐
 *                    ▼│2047│…│1538│1537│1536│─────3──▶│             │───▶│2047│…│1664│1792│1536│
 *                     └────┘ └────┴────┴────┘         └─────────────┘    └────┘ └────┴────┴────┘
 *
 * The kernel uses two FFT engines to process the two independent data channels supplied by the 'fetch' kernel in
 * parallel.
 */
__attribute__((task))
kernel void fdfir(int const inverse) {

    // Sliding window arrays, used internally by the FFT engine for data reordering
    float2 fft_delay_elements_0[FFT_N_POINTS + FFT_N_PARALLEL * (FFT_N_POINTS_LOG - 3)];
    float2 fft_delay_elements_1[FFT_N_POINTS + FFT_N_PARALLEL * (FFT_N_POINTS_LOG - 3)];

    // Process 'count' tiles and flush the engine's pipeline
    for (int s = 0; s < FDF_N_TILES * FFT_N_STEPS + FFT_LATENCY; ++s) {
        // Buffers to hold engine's input/output in each iteration
        float2x4 data_0;
        float2x4 data_1;

        // Buffers to store the spectral power of the iFFT outputs (4 real values)
        float power_0[FFT_N_PARALLEL];
        float power_1[FFT_N_PARALLEL];

        // Read actual input from the channels, respectively inject zeroes to flush the pipeline
        if (s < FDF_N_TILES * FFT_N_STEPS) {
            #pragma unroll
            for (int p = 0; p < FFT_N_PARALLEL; ++p)
                data_0.i[p] = READ_CHANNEL(fft_input_0[p]);

            #pragma unroll
            for (int p = 0; p < FFT_N_PARALLEL; ++p)
                data_1.i[p] = READ_CHANNEL(fft_input_1[p]);
        } else {
            data_0.i0 = data_0.i1 = data_0.i2 = data_0.i3 = 0;
            data_1.i0 = data_1.i1 = data_1.i2 = data_1.i3 = 0;
        }

        // Perform one step of the FFT engines
        data_0 = fft_step(data_0, s % FFT_N_STEPS, fft_delay_elements_0, inverse, FFT_N_POINTS_LOG);
        data_1 = fft_step(data_1, s % FFT_N_STEPS, fft_delay_elements_1, inverse, FFT_N_POINTS_LOG);

        // Compute spectral power
        #pragma unroll
        for (int p = 0; p < FFT_N_PARALLEL; ++p)
            power_0[p] = data_0.i[p].x * data_0.i[p].x + data_0.i[p].y * data_0.i[p].y;

        #pragma unroll
        for (int p = 0; p < FFT_N_PARALLEL; ++p)
            power_1[p] = data_1.i[p].x * data_1.i[p].x + data_1.i[p].y * data_1.i[p].y;

        // Pass output to the 'reversed' kernel. Recall that FFT engine outputs are delayed by N / 4 - 1 steps, hence
        // gate channel writes accordingly.
        if (s >= FFT_LATENCY) {
            #pragma unroll
            for (int p = 0; p < FFT_N_PARALLEL; ++p)
                WRITE_CHANNEL(fft_output_0[p], power_0[p]);

            #pragma unroll
            for (int p = 0; p < FFT_N_PARALLEL; ++p)
                WRITE_CHANNEL(fft_output_1[p], power_1[p]);
        }
    }
}

/*
 * NDRange kernel 'reversed':
 *   Takes in the output from the 'fdfir' kernel, and writes it back to memory in the layout of the FOP.
 *
 * Two data streams, corresponding to one filter template each, are processed concurrently.  The work group layout is
 * similar to the 'fetch' kernel: a work group consists of 2048 work items that handle 2x4 values each.
 */
__attribute__((reqd_work_group_size(NDR_WORK_GROUP_SZ, 1, 1)))
kernel void reversed(global float *restrict dest_0,
                     global float *restrict dest_1,
                     int const tmpl_idx_0,
                     int const tmpl_idx_1) {

    // Reordering buffers, sized to hold the 8192 real values covered by the current work group
    local float buf_0[NDR_N_POINTS_PER_WORK_GROUP];
    local float buf_1[NDR_N_POINTS_PER_WORK_GROUP];

    // Fill buffers linearly from the channels. The base index is the work item's local id, scaled by 4 as each WI
    // handles 4 values
    int item_base = get_local_id(0) * NDR_N_POINTS_PER_WORK_ITEM;

    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
        buf_0[item_base + p] = READ_CHANNEL(fft_output_0[p]);

    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
        buf_1[item_base + p] = READ_CHANNEL(fft_output_1[p]);

    // Synchronise work items, and ensure coherent view of the local buffers
    barrier(CLK_LOCAL_MEM_FENCE);

    // Address calculation to map the work group's local buffers to the right place (indexed by work group id and
    // filter id) in a preliminary FOP-like structure (e.g. float[43][1288*2048]) in memory.
    int dest_0_base = tmpl_idx_0 * FDF_INTERMEDIATE_SZ + get_group_id(0) * NDR_N_POINTS_PER_WORK_GROUP;
    int dest_1_base = tmpl_idx_1 * FDF_INTERMEDIATE_SZ + get_group_id(0) * NDR_N_POINTS_PER_WORK_GROUP;

    int lid = get_local_id(0);
    int rev_lid = bit_reversed(lid, FFT_N_POINTS_LOG);

    // Assign (work item id)'th element in each of the 4 tiles handled by the current work group, and handle
    // peculiarities of this particular FFT engine:
    //   - results are still in bit-reversed order -> use bit-reversed index when accessing local buffers.
    //   - results are not normalised with the usual 1/N factor -> divide the previously squared values by N^2.
    const int NN = FFT_N_POINTS * FFT_N_POINTS;

    #pragma unroll
    for (int p = 0; p < NDR_N_POINTS_PER_WORK_ITEM; ++p)
        dest_0[dest_0_base + p * FDF_TILE_SZ + lid] = buf_0[p * FFT_N_POINTS + rev_lid] / NN;

    #pragma unroll
    for (int p = 0; p < NDR_N_POINTS_PER_WORK_ITEM; ++p)
        dest_1[dest_1_base + p * FDF_TILE_SZ + lid] = buf_1[p * FFT_N_POINTS + rev_lid] / NN;
}

/*
 * Single work item kernel 'discard':
 *   Concatenates the valid parts from two buffer (one per filter group) into the final filter output plane (FOP).
 *
 * The first #taps-1 elements in each tile of the intermediate result need to be discarded (cf. overlap-save algorithm).
 */
__attribute__((task))
kernel void discard(global float *restrict pre_discard_0,
                    global float *restrict pre_discard_1,
                    global float *restrict fop) {
    // Copy values in bursts of 8 values to the first half of the FOP (filters 0...42)
    for (int t = 0; t < (FILTER_GROUP_SZ + 1) * FDF_N_TILES; ++t) {
        int fop_base = t * FDF_TILE_PAYLOAD;
        int pre_discard_base = t * FDF_TILE_SZ + FDF_TILE_OVERLAP;

        #pragma unroll 8
        for (unsigned i = 0; i < FDF_TILE_PAYLOAD; ++i) {
            fop[fop_base + i] = pre_discard_0[pre_discard_base + i];
        }
    }

    // Copy values to the second half of the FOP (filters 43...85). As the 86th filter template was introduced for the
    // sole purpose of balancing the pipeline, discard its results here: iterating for totalGroup-1288 iterations
    // practically means that we handle only 42 filters in this loop
    for (int t = 0; t < FILTER_GROUP_SZ * FDF_N_TILES; ++t) {
        int fop_base = (FILTER_GROUP_SZ + 1) * FDF_OUTPUT_SZ + t * FDF_TILE_PAYLOAD;
        int pre_discard_base = t * FDF_TILE_SZ + FDF_TILE_OVERLAP;

        #pragma unroll 8
        for (unsigned i = 0; i < FDF_TILE_PAYLOAD; i++) {
            fop[fop_base + i] = pre_discard_1[pre_discard_base + i];
        }
    }
}

//#include "hsum.cl"
