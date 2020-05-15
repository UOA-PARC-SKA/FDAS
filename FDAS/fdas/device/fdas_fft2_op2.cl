
#include "fft_4_1.cl"

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
 * for 511 additional steps, in order to flush out the last valid results.
 *
 * The dataflow through the engine is as follows (cf. Fig. 3 in the paper):
 *
 *                  Point i arrives:                                   Result i arrives:
 *
 *                     in time step:                                      in time step:
 *                ◀────i mod 2^(N/P)────                             ◀────  (i >> P)   ───
 *               ┌────┐ ┌────┬────┬────┐         ┌─────────────┐    ┌────┐ ┌────┬────┬────┐
 *              ││ 511│…│   2│   1│   0│─────0──▶│.___.___.___.│───▶│2044│…│   8│   4│   0││
 *              │└────┘ └────┴────┴────┘  t      │[__ [__   |  │    └────┘ └────┴────┴────┘│
 *              │┌────┐ ┌────┬────┬────┐  e      │|   |     |  │    ┌────┐ ┌────┬────┬────┐│
 *  at terminal:││1535│…│1026│1025│1024│──r──1──▶│             │───▶│2045│…│   9│   5│   1││at terminal:
 *  bit-reverse(│└────┘ └────┴────┴────┘  m      │ N    = 2048 │    └────┘ └────┴────┴────┘│  i mod P
 *   i >> (N-P) │┌────┐ ┌────┬────┬────┐  i      │ P    =    4 │    ┌────┐ ┌────┬────┬────┐│
 *  )           ││1023│…│ 514│ 513│ 512│──n──2──▶│             │───▶│2046│…│  10│   6│   2││
 *              │└────┘ └────┴────┴────┘  a      │ lat. =  N/P │    └────┘ └────┴────┴────┘│
 *              │┌────┐ ┌────┬────┬────┐  l      │ II   =    1 │    ┌────┐ ┌────┬────┬────┐│
 *              ▼│2047│…│1538│1537│1536│─────3──▶│             │───▶│2047│…│  11│   7│   3│▼
 *               └────┘ └────┴────┴────┘         └─────────────┘    └────┘ └────┴────┴────┘
 *
 * TODO: fft_4_1.cl contains a mix of code from Altera's 'fft1d' and 'fft1d_offchip' examples -- best guess is that
 *       'fft1d' was stripped down to 4 points. However, functional changes were made in the 'fft_step' function
 *       (step 1 moved to loop, computation of variable 'data_index' simplified).
 * TODO: The documentation in the original sources says the engine's output is in bit-reversed order, in contrast to
 *       Garrido et al. and the illustration above! I do not see a bit-reversal step in the example's driver code.
 *
 * The kernel uses two FFT engines to process the two independent data channels supplied by the 'fetch' kernel in
 * parallel.
 */
__attribute__((task))
kernel void fdfir(int const count,
                  int const inverse) {
    const int N = (1 << LOGN);

    // Sliding window arrays, used internally by the FFT engine for data reordering
    float2 fft_delay_elements_0[N + 4 * (LOGN - 2)];
    float2 fft_delay_elements_1[N + 4 * (LOGN - 2)];

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
    // Indices into local buffers are bit-reversed first
    // TODO: cf. comments on 'fdfir' kernel: Shouldn't the output of the FFT engine be already in the correct order?
    int colt = get_local_id(0);
    int group = get_group_id(0);
    int revcolt = bit_reversed(colt, LOGN);
    int i = get_global_id(0) >> LOGN; // unused
    int where = colt + (group << (LOGN + 2)) + filter_index * padded_length;

    // Assign (work item id)'th element in each of the 4 tiles handled by the current work group
    // TODO: Still unclear why this access pattern was chosen (maybe to save the three bit-reversal operations?)
    // TODO: In case the bit-reversal is actually unnecessary here the destination buffers could be written linearly
    // TODO: check whether the synthesis tool understands that it does not need dividers here
    dest_0[0 * N + where] = buf_0[0 * N + revcolt] / 4194304; // divide by 2^22 -- why?
    dest_0[1 * N + where] = buf_0[1 * N + revcolt] / 4194304;
    dest_0[2 * N + where] = buf_0[2 * N + revcolt] / 4194304;
    dest_0[3 * N + where] = buf_0[3 * N + revcolt] / 4194304;

    dest_1[0 * N + where] = buf_1[0 * N + revcolt] / 4194304;
    dest_1[1 * N + where] = buf_1[1 * N + revcolt] / 4194304;
    dest_1[2 * N + where] = buf_1[2 * N + revcolt] / 4194304;
    dest_1[3 * N + where] = buf_1[3 * N + revcolt] / 4194304;
}

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


__attribute__((task))
kernel void discard(global float *restrict dataPtr_0,   //2048 x GROUP_N x FILTER_N / 2
                    global float *restrict dataPtr_1,   //2048 x GROUP_N x FILTER_N / 2
                    global float *restrict outputPtr,   //1627 x GROUP_N x FILTER_N
//         const unsigned int tile_size,       //TILE_SIZE
//         const unsigned int filter_size      //FILTER_SIZE
                    const unsigned int totalGroup) {     //GROUP_N*FILTER_N/2
    for (unsigned iload = 0; iload < totalGroup; iload++) {
#pragma unroll 8
        for (unsigned i = 0; i < 1627; i++) {
            outputPtr[iload * 1627 + i] = dataPtr_0[iload * 2048 + 421 + i];
        }
    }
//Because we don't need the 86th output array, the iterate is totalGroup-1288 instead of totalGroup 
    for (unsigned iload = 0; iload < totalGroup - 1288; iload++) {
#pragma unroll 8
        for (unsigned i = 0; i < 1627; i++) {
            outputPtr[iload * 1627 + i + 43 * SIGNAL_LENGTH] = dataPtr_1[iload * 2048 + 421 + i];
        }
    }
}

__attribute__((task))
kernel void harmonic_summing(global volatile float *restrict dataPtr,   //2^LOGN
                             global float *restrict detection,
                             constant float *restrict threshold, //SP_N
                             global unsigned int *restrict detection_l,
                             const unsigned int singleLength,       //2^LOGN/HM_PF - 1
                             const unsigned int totalLength,     //2^LOGN x T_N / HM_PF
                             global float *restrict resultPtr) { //2^LOGN x T_N
    float local_result_0[SP_N];
    float local_result_1[SP_N];
//  float __attribute__((numbanks(16),bankwidth(64))) local_detection[SP_N][DS];     
//  unsigned int __attribute__((numbanks(16),bankwidth(64))) detection_location[SP_N][DS];
    float local_detection_0[SP_N][DS / 2];
    float local_detection_1[SP_N][DS / 2];
    unsigned int detection_location_0[SP_N][DS / 2];
    unsigned int detection_location_1[SP_N][DS / 2];


// initialize intermediate result array
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

    int freq_bin = 0;
    int i_template = 0;
    char i_count_0[8];
    char i_count_1[8];

#pragma unroll
    for (int i = 0; i < SP_N; i++) {
        i_count_0[i] = 0;
        i_count_1[i] = 0;
    }
//  #pragma unroll 2
    for (int ilen = 0; ilen < totalLength; ilen++) {

        int m_x = freq_bin; // has to times HM_PF
        int m_y = i_template;
        int s_x_0[SP_N];
        int s_x_1[SP_N];
        int s_y[SP_N];// = (m_y >> logharmonic);
#pragma unroll
        for (char ilen_0 = 0; ilen_0 < SP_N; ilen_0++) {
            s_x_0[ilen_0] = (m_x * HM_PF + 0) / (ilen_0 + 1);
            s_x_1[ilen_0] = (m_x * HM_PF + 1) / (ilen_0 + 1);

            s_y[ilen_0] = (m_y - 42) % (ilen_0 + 1) == 0 ? (m_y - 42) / (ilen_0 + 1) + 42 :
                          (m_y - 42) <= 0 ? (m_y - 42) / (ilen_0 + 1) + 41 : (m_y - 42) / (ilen_0 + 1) + 43;
        }
        float __attribute__((register)) load_0[SP_N];
        float __attribute__((register)) load_1[SP_N];

#pragma unroll
        for (char ilen_0 = 0; ilen_0 < SP_N; ilen_0++) {
            load_0[ilen_0] = dataPtr[s_x_0[ilen_0] + (s_y[ilen_0] * SIGNAL_LENGTH)];
            load_1[ilen_0] = dataPtr[s_x_1[ilen_0] + (s_y[ilen_0] * SIGNAL_LENGTH)];
        }
        local_result_0[0] = load_0[0];
        local_result_1[0] = load_1[0];

#pragma unroll
        for (char ilen_0 = 1; ilen_0 < SP_N; ilen_0++) {
            local_result_0[ilen_0] = local_result_0[ilen_0 - 1] + load_0[ilen_0];
            local_result_1[ilen_0] = local_result_1[ilen_0 - 1] + load_1[ilen_0];
        }

        resultPtr[(i_template * SIGNAL_LENGTH) + freq_bin * HM_PF + 0] = local_result_0[7];
        resultPtr[(i_template * SIGNAL_LENGTH) + freq_bin * HM_PF + 1] = local_result_1[7];

        // Serach the generated f-fdot plane

#pragma unroll
        for (int k = 0; k < SP_N; k++) {
            if (local_result_0[k] > threshold[(i_template << 3) + k]) {
                detection_location_0[k][i_count_0[k]] = ((i_template & 0x7F) << 25) + ((k & 0x7) << 22) + freq_bin * HM_PF + 0;
                local_detection_0[k][i_count_0[k]] = local_result_0[k];
                i_count_0[k] = (i_count_0[k] == (DS / HM_PF - 1)) ? (DS / HM_PF - 1) : (i_count_0[k] + 1);
            }
            if (local_result_1[k] > threshold[(i_template << 3) + k]) {
                detection_location_1[k][i_count_1[k]] = ((i_template & 0x7F) << 25) + ((k & 0x7) << 22) + freq_bin * HM_PF + 1;
                local_detection_1[k][i_count_1[k]] = local_result_1[k];
                i_count_1[k] = (i_count_1[k] == (DS / HM_PF - 1)) ? (DS / HM_PF - 1) : i_count_1[k] + 1;
            }
        }
/**/
        if (freq_bin == singleLength) {
            i_template++;
        }
        if (freq_bin == singleLength) {
            freq_bin = 0;
        } else {
            freq_bin++;
        }
    }

    for (int ilen = 0; ilen < DS / HM_PF; ilen++) {
//      #pragma unroll  
        for (int k = 0; k < SP_N; k++) {
            detection_l[ilen * SP_N + k] = detection_location_0[k][ilen];
            detection[ilen * SP_N + k] = local_detection_0[k][ilen];
            detection_l[(ilen + DS / HM_PF) * SP_N + k] = detection_location_1[k][ilen];
            detection[(ilen + DS / HM_PF) * SP_N + k] = local_detection_1[k][ilen];
        }
    }
} 
