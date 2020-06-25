
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

    int input_base = get_group_id(0) * FDF_TILE_PAYLOAD;
    int lid = get_local_id(0);

    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
        buf[p][lid] = input[input_base + bit_reversed(p, FFT_N_PARALLEL_LOG) * FFT_N_POINTS_PER_TERMINAL + lid];

    barrier(CLK_LOCAL_MEM_FENCE);

    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
        WRITE_CHANNEL(fwd_fft_input[p], buf[p][lid]);
}

__attribute__((task))
kernel void fwd_fft() {
    // Sliding window arrays, used internally by the FFT engine for data reordering
    float2 fft_delay_elements[FFT_N_POINTS + FFT_N_PARALLEL * (FFT_N_POINTS_LOG - 3)];

    // Process 'count' tiles and flush the engine's pipeline
    for (int s = 0; s < FDF_N_TILES * FFT_N_STEPS + FFT_LATENCY; ++s) {
        // Buffers to hold engine's input/output in each iteration
        float2x4 data;

        // Read actual input from the channels, respectively inject zeroes to flush the pipeline
        if (s < FDF_N_TILES * FFT_N_STEPS) {
            #pragma unroll
            for (int p = 0; p < FFT_N_PARALLEL; ++p)
                data.i[p] = READ_CHANNEL(fwd_fft_input[p]);
        } else {
            data.i0 = data.i1 = data.i2 = data.i3 = 0;
        }

        // Perform one step of the FFT engine
        data = fft_step(data, s % FFT_N_STEPS, fft_delay_elements, 0, FFT_N_POINTS_LOG);

        // Pass output to the 'reversed' kernel. Recall that FFT engine outputs are delayed by N / 4 - 1 steps, hence
        // gate channel writes accordingly.
        if (s >= FFT_LATENCY) {
            #pragma unroll
            for (int p = 0; p < FFT_N_PARALLEL; ++p)
                WRITE_CHANNEL(fwd_fft_output[p], data.i[p]);
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

    int tiles_base = get_group_id(0) * FDF_TILE_SZ;
    int rev_lid = bit_reversed(lid, FFT_N_POINTS_PER_TERMINAL_LOG);

    #pragma unroll
    for (int p = 0; p < FFT_N_PARALLEL; ++p)
       tiles[tiles_base + bit_reversed(p, FFT_N_PARALLEL_LOG) * FFT_N_POINTS_PER_TERMINAL + rev_lid] = buf[p][lid];
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

/*
 * Single work item kernel 'harmonic_summing':
 *   Computes several harmonic planes (HP) from differently stretched versions of the FOP to amplify periodic signals,
 *   then uses thresholding to produce a preliminary list of pulsar candidates.
 *
 * The FOP, as computed by the FT convolution kernels above, is the input:
 *
 *                &dataPtr[0]
 *               /
 *          -42 *───────────────────────────┐
 *        ▲   ┆ │                           │
 *        │  -1 │                           │
 *  template  0 ├───────────────────────────┤2^21
 *      i │   1 │                           │
 *        ▼   ┆ │                           │
 *           42 └───────────────────────────┘
 *               ─────────channel j────────▶
 *
 * It is important to keep in mind that while indices in the range [0, 84] are used to access the FOP in memory, the
 * filter templates are actually numbered -42,...,-1,0,1,...,42 in the underlying science. It follows that the origin
 * of the FOP (template 0, channel 0) has the memory address '&dataPtr[42 * 2^21]'.
 *
 * This kernel computes 8 harmonic planes HP_k, defined as:
 *   HP_1(i,j) = FOP(i,j)
 *   HP_k(i,j) = HP_k-1(i,j) + SP_k(i,j)   k = 2,...,8
 *
 * The SP_k are the stretch planes, which are the result of stretching the FOP by k:
 *   SP_k(i,j) = FOP(floor(i/k), floor(j/k))   k = 2,...,8
 *                    (^^ the floor-operation needs to handle the negative filter number correctly!)
 *
 * Note that this kernel does not store the HPs explicitly (only HP_8 is written to resultPtr to enable verification).
 * Instead, for a given coordinate (i,j), we iteratively compute the values of the SP_k and HP_k and compare them with
 * with the thresholds:
 *
 *   HP_k(i,j) = Σ_{l=1...k} FOP(floor(i/l), floor(j/l))   >   threshold(i, k)
 *
 * The HPs are associated with different thresholds. This implementation supports externally specified,
 * constant thresholds per filter and per HP number.
 * TODO: In the Matlab reference implementation, the threshold is a function of the noise level in the respective HP.
 *
 * The output of the harmonic summing module (and in turn, of the FDAS module) is a list of candidates characterised by
 *  - i, the filter number,
 *  - k, the index of the harmonic plane, and
 *  - j, the number of the frequency bin (a.k.a. channel), for which
 *  - HP_k(i,j), an amplitude greater than the appropriate threshold, was detected.
 *
 * For each HP, the kernel writes 40 candidates (or zeros, if fewer candidates exist) in the following format to the
 * buffers 'detection' and 'detection_l' (which therefore need to hold at least 320*4 bytes each):
 *
 *                 ┌──────────────────────────────────┐
 *  detection:     │            HP_k(i,j)             │
 *                 └──────────────────────────────────┘
 *                31                                  0
 *
 *                 ┌───────┬───┬──────────────────────┐
 *  detection_l:   │ i+42  │ k │          j           │
 *                 └───────┴───┴──────────────────────┘
 *                31      24  21                      0
 *
 * This implementation processes two adjacent channels concurrently.
 */
__attribute__((task))
kernel void harmonic_summing(global volatile float *restrict dataPtr,   // FILTER_N * INPUT_LENGTH // TODO: Why volatile?
                             global float *restrict detection,          // SP_N * DS
                             constant float *restrict threshold,        // SP_N * FILTER_N
                             global unsigned int *restrict detection_l, // SP_N * DS
                             global float *restrict resultPtr) {        // same as dataPtr
    // Buffers to store HP_k(i,j) and HP_k(i, j+1) for all k
    float local_result_0[HMS_N_PLANES];
    float local_result_1[HMS_N_PLANES];

    // Buffers to build the candidate lists, in the format outlined above. We allocate 40 slots per harmonic plane in
    // total, split up into a buffer for the even and the odd channels
    float local_detection_0[HMS_N_PLANES][HMS_DETECTION_SZ / 2];
    float local_detection_1[HMS_N_PLANES][HMS_DETECTION_SZ / 2];
    unsigned int detection_location_0[HMS_N_PLANES][HMS_DETECTION_SZ / 2];
    unsigned int detection_location_1[HMS_N_PLANES][HMS_DETECTION_SZ / 2];

    // Fill buffers with zeros
    #pragma unroll
    for (int ilen = 0; ilen < HMS_N_PLANES; ilen++) {
        local_result_0[ilen] = 0.0f;
        local_result_1[ilen] = 0.0f;
    }

    for (int ilen_1 = 0; ilen_1 < HMS_DETECTION_SZ / 2; ilen_1++) {
        #pragma unroll
        for (int ilen_2 = 0; ilen_2 < HMS_N_PLANES; ilen_2++) {
            detection_location_0[ilen_2][ilen_1] = 0;
            detection_location_1[ilen_2][ilen_1] = 0;
            local_detection_0[ilen_2][ilen_1] = 0.0f;
            local_detection_1[ilen_2][ilen_1] = 0.0f;
        }
    }

    // 'freq_bin' and 'i_template' denote the current coordinates in the loop below. As two channels are handled per
    // iteration, 'freq_bin' will be iterated from 0...#channels/2. 'i_template' is in the range [0, 84].
    int freq_bin = 0;
    int i_template = 0;

    // Counters for the number of elements already stored in the result buffers ('local_detection_*' and
    // 'detection_location_*'). The literal 8 corresponds to the number of HPs.
    char i_count_0[HMS_N_PLANES];
    char i_count_1[HMS_N_PLANES];

    // Reset all counters to zero
    #pragma unroll
    for (int i = 0; i < HMS_N_PLANES; i++) {
        i_count_0[i] = 0;
        i_count_1[i] = 0;
    }

    // Iterate over all points the FOP. Semantically, this is a two-dimensional loop:
    //   for m_y = 1:85 { ...
    //     for m_x = 1:2^20 { ...
    for (int ilen = 0; ilen < FOP_SZ / 2; ilen++) {
        // Each iteration handles two adjacent channels 'm_x*HM_PF+0' and 'm_x*HM_PF+1'
        int m_x = freq_bin;
        int m_y = i_template;

        // Buffers to store indices for k-stretched views of the FOP
        int s_x_0[HMS_N_PLANES];
        int s_x_1[HMS_N_PLANES];
        int s_y[HMS_N_PLANES];

        // Compute indices
        // TODO: This is potentially expensive due to modulo/div operations -- results could be reused (at least the
        //       s_y computation which is loop-invariant for 2^20 iterations)
        #pragma unroll
        for (char ilen_0 = 0; ilen_0 < HMS_N_PLANES; ilen_0++) {
            // Compute channel indices into k'th SP (k==ilen_0+1)
            s_x_0[ilen_0] = (m_x * 2 + 0) / (ilen_0 + 1);
            s_x_1[ilen_0] = (m_x * 2 + 1) / (ilen_0 + 1);

            // Compute template indices. This is floor(m_y/k), but considering the origin of the FOP, as explained above
            s_y[ilen_0] = (m_y - 42) % (ilen_0 + 1) == 0 ?
                (m_y - 42) / (ilen_0 + 1) + 42 : (m_y - 42) <= 0 ?
                    (m_y - 42) / (ilen_0 + 1) + 41 : (m_y - 42) / (ilen_0 + 1) + 43;
        }

        // Buffers to hold values retrieved from the k-stretched views of the FOP
        float __attribute__((register)) load_0[HMS_N_PLANES];
        float __attribute__((register)) load_1[HMS_N_PLANES];

        // Gather values from memory
        #pragma unroll
        for (char ilen_0 = 0; ilen_0 < HMS_N_PLANES; ilen_0++) {
            load_0[ilen_0] = dataPtr[s_x_0[ilen_0] + (s_y[ilen_0] * FDF_OUTPUT_SZ)];
            load_1[ilen_0] = dataPtr[s_x_1[ilen_0] + (s_y[ilen_0] * FDF_OUTPUT_SZ)];
        }

        // Sum-up values to determine the amplitudes at coordinates (m_y, m_x*2) (resp. (m_y, m_x*2+1)) for all HP_k
        local_result_0[0] = load_0[0];
        local_result_1[0] = load_1[0];
        #pragma unroll
        for (char ilen_0 = 1; ilen_0 < HMS_N_PLANES; ilen_0++) {
            local_result_0[ilen_0] = local_result_0[ilen_0 - 1] + load_0[ilen_0];
            local_result_1[ilen_0] = local_result_1[ilen_0 - 1] + load_1[ilen_0];
        }

        // Write back the amplitudes in HP_8 at the current coordinates (validation only)
        resultPtr[(i_template * FDF_OUTPUT_SZ) + freq_bin * 2 + 0] = local_result_0[7];
        resultPtr[(i_template * FDF_OUTPUT_SZ) + freq_bin * 2 + 1] = local_result_1[7];

        // Now, compare the amplitudes in each HP with the corresponding threshold
        #pragma unroll
        for (int k = 0; k < HMS_N_PLANES; k++) {
            if (local_result_0[k] > threshold[(i_template << 3) + k]) {
                //  ┌───────┬───┬──────────────────────┐
                //  │i_tem..│ k │ freq_bin * HM_PF + 0 │
                //  └───────┴───┴──────────────────────┘
                // 31      24  21                      0
                detection_location_0[k][i_count_0[k]] = ((i_template & 0x7F) << 25) + ((k & 0x7) << 22) + freq_bin * 2 + 0;

                // The amplitude is a single-precision FP value
                local_detection_0[k][i_count_0[k]] = local_result_0[k];

                 // Increment the counter (-> next insertion position). Saturate at last index instead of overflowing
                 // TODO: Shouldn't we rather stop collecting candidates instead of overwriting the last one?
                i_count_0[k] = (i_count_0[k] == (HMS_DETECTION_SZ / 2 - 1)) ? (HMS_DETECTION_SZ / 2 - 1) : (i_count_0[k] + 1);
            }
            if (local_result_1[k] > threshold[(i_template << 3) + k]) {
                detection_location_1[k][i_count_1[k]] = ((i_template & 0x7F) << 25) + ((k & 0x7) << 22) + freq_bin * 2 + 1;
                local_detection_1[k][i_count_1[k]] = local_result_1[k];
                i_count_1[k] = (i_count_1[k] == (HMS_DETECTION_SZ / 2 - 1)) ? (HMS_DETECTION_SZ / 2 - 1) : i_count_1[k] + 1;
            }
        }

        // Increment 2D loop counters
        if (freq_bin == FDF_OUTPUT_SZ / 2 - 1) {
            i_template++;
        }
        if (freq_bin == FDF_OUTPUT_SZ / 2 - 1) {
            freq_bin = 0;
        } else {
            freq_bin++;
        }
    }

    // Write candidate list to output buffer
    // TODO: Why is this not unrolled to allow a burst write?
    // TODO: Couldn't we just write back the candidates on-the-fly, in the main loop?
    for (int ilen = 0; ilen < HMS_DETECTION_SZ / 2; ilen++) {
        for (int k = 0; k < HMS_N_PLANES; k++) {
            detection_l[ilen * HMS_N_PLANES + k] = detection_location_0[k][ilen];
            detection[ilen * HMS_N_PLANES + k] = local_detection_0[k][ilen];
            detection_l[(ilen + HMS_DETECTION_SZ / 2) * HMS_N_PLANES + k] = detection_location_1[k][ilen];
            detection[(ilen + HMS_DETECTION_SZ / 2) * HMS_N_PLANES + k] = local_detection_1[k][ilen];
        }
    }
}
