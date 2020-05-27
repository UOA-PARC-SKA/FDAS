
#include "fft_4p.cl"

#define TRUE 0
#define LOGN 11
#define FFT  0
#define IFFT 1
//#define SIGNAL_LENGTH 4096
#define SIGNAL_LENGTH 2095576
#define T_N  85     // Number of templates
#define DS   40      // maximum detection size
#define SP_N 8      // Number of stretched planes
#define P_F 8
#define HM_PF 2

#pragma OPENCL EXTENSION cl_altera_channels : enable

channel float chan0 __attribute__((depth(0)));
channel float chan1 __attribute__((depth(0)));
channel float chan2 __attribute__((depth(0)));
channel float chan3 __attribute__((depth(0)));
channel float chan4 __attribute__((depth(0)));
channel float chan5 __attribute__((depth(0)));
channel float chan6 __attribute__((depth(0)));
channel float chan7 __attribute__((depth(0)));

channel float2 chanin0 __attribute__((depth(0)));
channel float2 chanin1 __attribute__((depth(0)));
channel float2 chanin2 __attribute__((depth(0)));
channel float2 chanin3 __attribute__((depth(0)));
channel float2 chanin4 __attribute__((depth(0)));
channel float2 chanin5 __attribute__((depth(0)));
channel float2 chanin6 __attribute__((depth(0)));
channel float2 chanin7 __attribute__((depth(0)));

int bit_reversed(int x, int bits);

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
__attribute__((reqd_work_group_size((1 << LOGN), 1, 1)))
kernel void fetch(global float *restrict src,
                  global float *restrict coef_0,
                  int const filter_index) {
    const int N = (1 << LOGN);

    // One buffer per filter template, sized to hold the work group's multiplication result
    local float2 buf_0[4 * N];
    local float2 buf_1[4 * N];

    // Work item's base index in 'src' is its global id scaled by 4 (because each WI handles 4 values)
    unsigned where_global = get_global_id(0) << 2;

    // Work item's base index in the local buffers is the global base index modulo 8192
    unsigned where_local = where_global & ((1 << (LOGN + 2)) - 1);

    // The base indices in 'coef_0': 'filter_index' (resp. 'filter_index'+43) selects a particular filter template.
    // Then, the work item's local id, modulo 512, is scaled by 4 to refer to a 4-pack of coefficients.
    // Note: The device buffer behind 'coef_0' holds 86 templates. The bogus 86th filter output is discarded later
    unsigned i_local = get_local_id(0);
    unsigned ifilter_0 = filter_index * N + 4 * (i_local & (N / 4 - 1));
    unsigned ifilter_1 = (filter_index + 43) * N + 4 * (i_local & (N / 4 - 1)); //43 = ceil(85/2)

    // Complex multiplications. The base indices compute above are scaled again by 2 in order to address the individual,
    // i.e. real and imaginary, floating point values in 'src' and 'coef_0'
    buf_0[where_local + 0].x = src[2 * (where_global + 0)    ] * coef_0[2 * (ifilter_0 + 0)] - src[2 * (where_global + 0) + 1] * coef_0[2 * (ifilter_0 + 0) + 1];
    buf_0[where_local + 0].y = src[2 * (where_global + 0) + 1] * coef_0[2 * (ifilter_0 + 0)] + src[2 * (where_global + 0)    ] * coef_0[2 * (ifilter_0 + 0) + 1];
    buf_0[where_local + 1].x = src[2 * (where_global + 1)    ] * coef_0[2 * (ifilter_0 + 1)] - src[2 * (where_global + 1) + 1] * coef_0[2 * (ifilter_0 + 1) + 1];
    buf_0[where_local + 1].y = src[2 * (where_global + 1) + 1] * coef_0[2 * (ifilter_0 + 1)] + src[2 * (where_global + 1)    ] * coef_0[2 * (ifilter_0 + 1) + 1];
    buf_0[where_local + 2].x = src[2 * (where_global + 2)    ] * coef_0[2 * (ifilter_0 + 2)] - src[2 * (where_global + 2) + 1] * coef_0[2 * (ifilter_0 + 2) + 1];
    buf_0[where_local + 2].y = src[2 * (where_global + 2) + 1] * coef_0[2 * (ifilter_0 + 2)] + src[2 * (where_global + 2)    ] * coef_0[2 * (ifilter_0 + 2) + 1];
    buf_0[where_local + 3].x = src[2 * (where_global + 3)    ] * coef_0[2 * (ifilter_0 + 3)] - src[2 * (where_global + 3) + 1] * coef_0[2 * (ifilter_0 + 3) + 1];
    buf_0[where_local + 3].y = src[2 * (where_global + 3) + 1] * coef_0[2 * (ifilter_0 + 3)] + src[2 * (where_global + 3)    ] * coef_0[2 * (ifilter_0 + 3) + 1];

    buf_1[where_local + 0].x = src[2 * (where_global + 0)    ] * coef_0[2 * (ifilter_1 + 0)] - src[2 * (where_global + 0) + 1] * coef_0[2 * (ifilter_1 + 0) + 1];
    buf_1[where_local + 0].y = src[2 * (where_global + 0) + 1] * coef_0[2 * (ifilter_1 + 0)] + src[2 * (where_global + 0)    ] * coef_0[2 * (ifilter_1 + 0) + 1];
    buf_1[where_local + 1].x = src[2 * (where_global + 1)    ] * coef_0[2 * (ifilter_1 + 1)] - src[2 * (where_global + 1) + 1] * coef_0[2 * (ifilter_1 + 1) + 1];
    buf_1[where_local + 1].y = src[2 * (where_global + 1) + 1] * coef_0[2 * (ifilter_1 + 1)] + src[2 * (where_global + 1)    ] * coef_0[2 * (ifilter_1 + 1) + 1];
    buf_1[where_local + 2].x = src[2 * (where_global + 2)    ] * coef_0[2 * (ifilter_1 + 2)] - src[2 * (where_global + 2) + 1] * coef_0[2 * (ifilter_1 + 2) + 1];
    buf_1[where_local + 2].y = src[2 * (where_global + 2) + 1] * coef_0[2 * (ifilter_1 + 2)] + src[2 * (where_global + 2)    ] * coef_0[2 * (ifilter_1 + 2) + 1];
    buf_1[where_local + 3].x = src[2 * (where_global + 3)    ] * coef_0[2 * (ifilter_1 + 3)] - src[2 * (where_global + 3) + 1] * coef_0[2 * (ifilter_1 + 3) + 1];
    buf_1[where_local + 3].y = src[2 * (where_global + 3) + 1] * coef_0[2 * (ifilter_1 + 3)] + src[2 * (where_global + 3)    ] * coef_0[2 * (ifilter_1 + 3) + 1];

    // Synchronise work items, and ensure coherent view of the local buffers
    barrier(CLK_LOCAL_MEM_FENCE);

    // 'base' refers to one of the 4 tiles handled by this work group
    int base = get_local_id(0) >> (LOGN - 2);
    // 'offset' is the work item's local id modulo 512
    int offset = get_local_id(0) & (N / 4 - 1);

    // Write multiplication result to channels. The particular order of elements is mandated by the FFT engine, see
    // also kernel 'fdfir'
    write_channel_altera(chanin0, buf_0[base * N + 0 * N / 4 + offset]);
    write_channel_altera(chanin1, buf_0[base * N + 2 * N / 4 + offset]);
    write_channel_altera(chanin2, buf_0[base * N + 1 * N / 4 + offset]);
    write_channel_altera(chanin3, buf_0[base * N + 3 * N / 4 + offset]);

    write_channel_altera(chanin4, buf_1[base * N + 0 * N / 4 + offset]);
    write_channel_altera(chanin5, buf_1[base * N + 2 * N / 4 + offset]);
    write_channel_altera(chanin6, buf_1[base * N + 1 * N / 4 + offset]);
    write_channel_altera(chanin7, buf_1[base * N + 3 * N / 4 + offset]);
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
kernel void fdfir(int const count,
                  int const inverse) {
    const int N = (1 << LOGN);

    // Sliding window arrays, used internally by the FFT engine for data reordering
    float2 fft_delay_elements_0[N + 4 * (LOGN - 3)];
    float2 fft_delay_elements_1[N + 4 * (LOGN - 3)];

    // Process 'count' tiles and flush the engine's pipeline
    for (unsigned i = 0; i < count * (N / 4) + N / 4 - 1; i++) {
        // Buffers to hold engine's input/output in each iteration
        float2x4 data_0;
        float2x4 data_1;

        // Buffers to store the spectral power of the iFFT outputs (4 real values)
        float power_0[4];
        float power_1[4];

        // Read actual input from the channels, respectively inject zeroes to flush the pipeline
        if (i < count * (N / 4)) {
            data_0.i0 = read_channel_altera(chanin0);
            data_0.i1 = read_channel_altera(chanin1);
            data_0.i2 = read_channel_altera(chanin2);
            data_0.i3 = read_channel_altera(chanin3);

            data_1.i0 = read_channel_altera(chanin4);
            data_1.i1 = read_channel_altera(chanin5);
            data_1.i2 = read_channel_altera(chanin6);
            data_1.i3 = read_channel_altera(chanin7);
        } else {
            data_0.i0 = data_0.i1 = data_0.i2 = data_0.i3 = 0;
            data_1.i0 = data_1.i1 = data_1.i2 = data_1.i3 = 0;
        }

        // Perform one step of the FFT engines
        data_0 = fft_step(data_0, i % (N / 4), fft_delay_elements_0, inverse, LOGN);
        data_1 = fft_step(data_1, i % (N / 4), fft_delay_elements_1, inverse, LOGN);

        // Compute spectral power
        power_0[0] = data_0.i0.x * data_0.i0.x + data_0.i0.y * data_0.i0.y;
        power_0[1] = data_0.i1.x * data_0.i1.x + data_0.i1.y * data_0.i1.y;
        power_0[2] = data_0.i2.x * data_0.i2.x + data_0.i2.y * data_0.i2.y;
        power_0[3] = data_0.i3.x * data_0.i3.x + data_0.i3.y * data_0.i3.y;

        power_1[0] = data_1.i0.x * data_1.i0.x + data_1.i0.y * data_1.i0.y;
        power_1[1] = data_1.i1.x * data_1.i1.x + data_1.i1.y * data_1.i1.y;
        power_1[2] = data_1.i2.x * data_1.i2.x + data_1.i2.y * data_1.i2.y;
        power_1[3] = data_1.i3.x * data_1.i3.x + data_1.i3.y * data_1.i3.y;

        // Pass output to the 'reversed' kernel. Recall that FFT engine outputs are delayed by N / 4 - 1 steps, hence
        // gate channel writes accordingly.
        if (i >= N / 4 - 1) {
            write_channel_altera(chan0, power_0[0]);
            write_channel_altera(chan1, power_0[1]);
            write_channel_altera(chan2, power_0[2]);
            write_channel_altera(chan3, power_0[3]);

            write_channel_altera(chan4, power_1[0]);
            write_channel_altera(chan5, power_1[1]);
            write_channel_altera(chan6, power_1[2]);
            write_channel_altera(chan7, power_1[3]);
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
__attribute__((reqd_work_group_size((1 << LOGN), 1, 1)))
kernel void reversed(global float *restrict dest_0,
                     global float *restrict dest_1,
                     int const filter_index,
                     int const padded_length) { // = GROUP_N * TILE_SIZE
    const int N = (1 << LOGN);
    const int N_T = 2637824; // ??? (unused, anyway)

    // Reordering buffers, sized to hold the 8192 real values covered by the current work group
    local float buf_0[4 * N];
    local float buf_1[4 * N];

    // Fill buffers linearly from the channels. The base index is the work item's local id, scaled by 4 as each WI
    // handles 4 values
    buf_0[4 * get_local_id(0) + 0] = read_channel_altera(chan0);
    buf_0[4 * get_local_id(0) + 1] = read_channel_altera(chan1);
    buf_0[4 * get_local_id(0) + 2] = read_channel_altera(chan2);
    buf_0[4 * get_local_id(0) + 3] = read_channel_altera(chan3);

    buf_1[4 * get_local_id(0) + 0] = read_channel_altera(chan4);
    buf_1[4 * get_local_id(0) + 1] = read_channel_altera(chan5);
    buf_1[4 * get_local_id(0) + 2] = read_channel_altera(chan6);
    buf_1[4 * get_local_id(0) + 3] = read_channel_altera(chan7);

    // Synchronise work items, and ensure coherent view of the local buffers
    barrier(CLK_LOCAL_MEM_FENCE);

    // Address calculation to map the work group's local buffers to the right place (indexed by work group id and
    // filter id) in a preliminary FOP-like structure (e.g. float[43][1288*2048]) in memory.
    int colt = get_local_id(0);
    int group = get_group_id(0);
    int revcolt = bit_reversed(colt, LOGN);
    int i = get_global_id(0) >> LOGN; // unused
    int where = colt + (group << (LOGN + 2)) + filter_index * padded_length;

    // Assign (work item id)'th element in each of the 4 tiles handled by the current work group, and handle
    // peculiarities of this particular FFT engine:
    //   - results are still in bit-reversed order -> use bit-reversed index when accessing local buffers.
    //   - results are not normalised with the usual 1/N factor -> divide the previously squared values by N^2.
    // TODO: Make sure that the synthesis tool does not instantiate actual dividers here
    dest_0[0 * N + where] = buf_0[0 * N + revcolt] / 4194304;
    dest_0[1 * N + where] = buf_0[1 * N + revcolt] / 4194304;
    dest_0[2 * N + where] = buf_0[2 * N + revcolt] / 4194304;
    dest_0[3 * N + where] = buf_0[3 * N + revcolt] / 4194304;

    dest_1[0 * N + where] = buf_1[0 * N + revcolt] / 4194304;
    dest_1[1 * N + where] = buf_1[1 * N + revcolt] / 4194304;
    dest_1[2 * N + where] = buf_1[2 * N + revcolt] / 4194304;
    dest_1[3 * N + where] = buf_1[3 * N + revcolt] / 4194304;
}

/*
 * Helper to perform the FFT-typical bit-reversal.
 */
int bit_reversed(int x, int bits) {
    int y = 0;
    #pragma unroll
    for (int i = 0; i < bits; i++) {
        y <<= 1;
        y |= x & 1;
        x >>= 1;
    }
    return y;
}

/*
 * Single work item kernel 'discard':
 *   Concatenates the valid parts from two buffer (one per filter group) into the final filter output plane (FOP).
 *
 * The first #taps-1 elements in each tile of the intermediate result need to be discarded (cf. overlap-save algorithm).
 *
 * TODO: There might be an off-by-one error here -- the code discards #taps elements.
 */
__attribute__((task))
kernel void discard(global float *restrict dataPtr_0,  //2048 x GROUP_N x ceil(FILTER_N / 2)
                    global float *restrict dataPtr_1,  //2048 x GROUP_N x ceil(FILTER_N / 2)
                    global float *restrict outputPtr,  //1627 x GROUP_N x FILTER_N
                    const unsigned int totalGroup) {   //GROUP_N x ceil(FILTER_N/2)
    // Copy values in bursts of 8 values to the first half of the FOP (filters 0...42)
    for (unsigned iload = 0; iload < totalGroup; iload++) {
        #pragma unroll 8
        for (unsigned i = 0; i < 1627; i++) {
            outputPtr[iload * 1627 + i] = dataPtr_0[iload * 2048 + 421 + i];
        }
    }
    // Copy values to the second half of the FOP (filters 43...85). As the 86th filter template was introduced for the
    // sole purpose of balancing the pipeline, discard its results here: iterating for totalGroup-1288 iterations
    // practically means that we handle only 42 filters in this loop
    for (unsigned iload = 0; iload < totalGroup - 1288; iload++) {
        #pragma unroll 8
        for (unsigned i = 0; i < 1627; i++) {
            outputPtr[iload * 1627 + i + 43 * SIGNAL_LENGTH] = dataPtr_1[iload * 2048 + 421 + i];
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
                             const unsigned int singleLength,           //            GROUP_N * (TILE_SIZE - FILTER_SIZE) / 2 - 1
                             const unsigned int totalLength,            // FILTER_N * GROUP_N * (TILE_SIZE - FILTER_SIZE) / 2;
                             global float *restrict resultPtr) {        // same as dataPtr
    // Buffers to store HP_k(i,j) and HP_k(i, j+1) for all k
    float local_result_0[SP_N];
    float local_result_1[SP_N];

    // Buffers to build the candidate lists, in the format outlined above. We allocate 40 slots per harmonic plane in
    // total, split up into a buffer for the even and the odd channels
    float local_detection_0[SP_N][DS / 2];
    float local_detection_1[SP_N][DS / 2];
    unsigned int detection_location_0[SP_N][DS / 2];
    unsigned int detection_location_1[SP_N][DS / 2];

    // Fill buffers with zeros
    #pragma unroll
    for (int ilen = 0; ilen < SP_N; ilen++) {
        local_result_0[ilen] = 0.0f;
        local_result_1[ilen] = 0.0f;
    }

    for (int ilen_1 = 0; ilen_1 < DS / 2; ilen_1++) {
        #pragma unroll
        for (int ilen_2 = 0; ilen_2 < P_F; ilen_2++) {
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
    char i_count_0[8];
    char i_count_1[8];

    // Reset all counters to zero
    #pragma unroll
    for (int i = 0; i < SP_N; i++) {
        i_count_0[i] = 0;
        i_count_1[i] = 0;
    }

    // Iterate over all points the FOP. Semantically, this is a two-dimensional loop:
    //   for m_y = 1:85 { ...
    //     for m_x = 1:2^20 { ...
    for (int ilen = 0; ilen < totalLength; ilen++) {
        // Each iteration handles two adjacent channels 'm_x*HM_PF+0' and 'm_x*HM_PF+1'
        int m_x = freq_bin;
        int m_y = i_template;

        // Buffers to store indices for k-stretched views of the FOP
        int s_x_0[SP_N];
        int s_x_1[SP_N];
        int s_y[SP_N];

        // Compute indices
        // TODO: This is potentially expensive due to modulo/div operations -- results could be reused (at least the
        //       s_y computation which is loop-invariant for 2^20 iterations)
        #pragma unroll
        for (char ilen_0 = 0; ilen_0 < SP_N; ilen_0++) {
            // Compute channel indices into k'th SP (k==ilen_0+1)
            s_x_0[ilen_0] = (m_x * HM_PF + 0) / (ilen_0 + 1);
            s_x_1[ilen_0] = (m_x * HM_PF + 1) / (ilen_0 + 1);

            // Compute template indices. This is floor(m_y/k), but considering the origin of the FOP, as explained above
            s_y[ilen_0] = (m_y - 42) % (ilen_0 + 1) == 0 ?
                (m_y - 42) / (ilen_0 + 1) + 42 : (m_y - 42) <= 0 ?
                    (m_y - 42) / (ilen_0 + 1) + 41 : (m_y - 42) / (ilen_0 + 1) + 43;
        }

        // Buffers to hold values retrieved from the k-stretched views of the FOP
        float __attribute__((register)) load_0[SP_N];
        float __attribute__((register)) load_1[SP_N];

        // Gather values from memory
        #pragma unroll
        for (char ilen_0 = 0; ilen_0 < SP_N; ilen_0++) {
            load_0[ilen_0] = dataPtr[s_x_0[ilen_0] + (s_y[ilen_0] * SIGNAL_LENGTH)];
            load_1[ilen_0] = dataPtr[s_x_1[ilen_0] + (s_y[ilen_0] * SIGNAL_LENGTH)];
        }

        // Sum-up values to determine the amplitudes at coordinates (m_y, m_x*2) (resp. (m_y, m_x*2+1)) for all HP_k
        local_result_0[0] = load_0[0];
        local_result_1[0] = load_1[0];
        #pragma unroll
        for (char ilen_0 = 1; ilen_0 < SP_N; ilen_0++) {
            local_result_0[ilen_0] = local_result_0[ilen_0 - 1] + load_0[ilen_0];
            local_result_1[ilen_0] = local_result_1[ilen_0 - 1] + load_1[ilen_0];
        }

        // Write back the amplitudes in HP_8 at the current coordinates (validation only)
        resultPtr[(i_template * SIGNAL_LENGTH) + freq_bin * HM_PF + 0] = local_result_0[7];
        resultPtr[(i_template * SIGNAL_LENGTH) + freq_bin * HM_PF + 1] = local_result_1[7];

        // Now, compare the amplitudes in each HP with the corresponding threshold
        #pragma unroll
        for (int k = 0; k < SP_N; k++) {
            if (local_result_0[k] > threshold[(i_template << 3) + k]) {
                //  ┌───────┬───┬──────────────────────┐
                //  │i_tem..│ k │ freq_bin * HM_PF + 0 │
                //  └───────┴───┴──────────────────────┘
                // 31      24  21                      0
                detection_location_0[k][i_count_0[k]] = ((i_template & 0x7F) << 25) + ((k & 0x7) << 22) + freq_bin * HM_PF + 0;

                // The amplitude is a single-precision FP value
                local_detection_0[k][i_count_0[k]] = local_result_0[k];

                 // Increment the counter (-> next insertion position). Saturate at last index instead of overflowing
                 // TODO: Shouldn't we rather stop collecting candidates instead of overwriting the last one?
                i_count_0[k] = (i_count_0[k] == (DS / HM_PF - 1)) ? (DS / HM_PF - 1) : (i_count_0[k] + 1);
            }
            if (local_result_1[k] > threshold[(i_template << 3) + k]) {
                detection_location_1[k][i_count_1[k]] = ((i_template & 0x7F) << 25) + ((k & 0x7) << 22) + freq_bin * HM_PF + 1;
                local_detection_1[k][i_count_1[k]] = local_result_1[k];
                i_count_1[k] = (i_count_1[k] == (DS / HM_PF - 1)) ? (DS / HM_PF - 1) : i_count_1[k] + 1;
            }
        }

        // Increment 2D loop counters
        if (freq_bin == singleLength) {
            i_template++;
        }
        if (freq_bin == singleLength) {
            freq_bin = 0;
        } else {
            freq_bin++;
        }
    }

    // Write candidate list to output buffer
    // TODO: Why is this not unrolled to allow a burst write?
    // TODO: Couldn't we just write back the candidates on-the-fly, in the main loop?
    for (int ilen = 0; ilen < DS / HM_PF; ilen++) {
        for (int k = 0; k < SP_N; k++) {
            detection_l[ilen * SP_N + k] = detection_location_0[k][ilen];
            detection[ilen * SP_N + k] = local_detection_0[k][ilen];
            detection_l[(ilen + DS / HM_PF) * SP_N + k] = detection_location_1[k][ilen];
            detection[(ilen + DS / HM_PF) * SP_N + k] = local_detection_1[k][ilen];
        }
    }
}
