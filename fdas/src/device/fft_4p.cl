// Copyright (C) 2013-2018 Altera Corporation, San Jose, California, USA. All rights reserved.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to
// whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// This agreement shall be governed in all respects by the laws of the State of California and
// by the laws of the United States of America.

// Complex single-precision floating-point radix-2^2 feedforward FFT / iFFT engine
//
// See Mario Garrido, Jesús Grajal, M. A. Sanchez, Oscar Gustafsson:
// Pipeline Radix-2k Feedforward FFT Architectures.
// IEEE Trans. VLSI Syst. 21(1): 23-32 (2013))
//
// The log(size) of the transform must be a compile-time constant argument.
// This FFT engine processes 4 points for each invocation. The inputs are four
// ordered streams while the outputs are in bit reversed order.
//
// The entry point of the engine is the 'fft_step' function. This function
// passes 4 data points through a fixed sequence of processing blocks
// (butterfly, rotation, swap, reorder, multiplications, etc.) and produces
// 4 output points towards the overall FFT transform.
//
// The engine is designed to be invoked from a loop in a single work-item task.
// When compiling a single work-item task, the compiler leverages pipeline
// parallelism and overlaps the execution of multiple invocations of this
// function. A new instance can start processing every clock cycle

// Note:
//  This implementation was combined and adapted from the Altera examples
//   - 'fft1d'         (-> the overall structure and interface), and
//   - 'fft1d_offchip' (-> twiddle factors suitable for a 4-parallel engine),
//  by Haomiao Wang. The original comments from the authors at Altera are
//  updated to reflect the change to a 4-parallel engine, but left intact
//  otherwise. Additional comments by Julian Oppermann are marked with '[JO]'.

// Includes tabled twiddle factors - storing constants uses fewer resources
// than instantiating 'cos' or 'sin' hardware
#include "twid_radix_2_2.cl"

// Convenience struct representing the 4 data points processed each step
// Each member is a float2 representing a complex number
typedef union {
    struct {
        float2 i0;
        float2 i1;
        float2 i2;
        float2 i3;
    };
    float2 i[4];
} float2x4;

// FFT butterfly building block
float2x4 butterfly(float2x4 data) {
    float2x4 res;
    res.i0 = data.i0 + data.i1;
    res.i1 = data.i0 - data.i1;
    res.i2 = data.i2 + data.i3;
    res.i3 = data.i2 - data.i3;
    return res;
}

// Swap real and imaginary components in preparation for inverse transform
float2x4 swap_complex(float2x4 data) {
    float2x4 res;
    res.i0.x = data.i0.y;
    res.i0.y = data.i0.x;
    res.i1.x = data.i1.y;
    res.i1.y = data.i1.x;
    res.i2.x = data.i2.y;
    res.i2.y = data.i2.x;
    res.i3.x = data.i3.y;
    res.i3.y = data.i3.x;
    return res;
}

// FFT trivial rotation building block
float2x4 trivial_rotate(float2x4 data) {
    float2 tmp = data.i3;
    data.i3.x = tmp.y;
    data.i3.y = -tmp.x;
    return data;
}

// FFT data swap building block associated with trivial rotations
float2x4 trivial_swap(float2x4 data) {
    float2 tmp = data.i1;
    data.i1 = data.i2;
    data.i2 = tmp;
    return data;
}

// FFT data swap building block associated with complex rotations
float2x4 swap(float2x4 data) {
    // [JO] Reduced to 4 parallel points, the complex swap is equivalent to
    //      the trivial one
    float2 tmp = data.i1;
    data.i1 = data.i2;
    data.i2 = tmp;
    return data;
}

// This function "delays" the input by 'depth' steps
// Input 'data' from invocation N would be returned in invocation N + depth
// The 'shift_reg' sliding window is shifted by 1 element at every invocation
float2 delay(float2 data, const int depth, float2 *shift_reg) {
    shift_reg[depth] = data;
    return shift_reg[0];
}

// FFT data reordering building block. Implements the reordering depicted below
// (for depth = 2). The first valid outputs are in invocation 4
// Invocation count: 0123...          01234567...
// data.i0         : GECA...   ---->      DBCA...
// data.i1         : HFDB...   ---->      HFGE...
float2x4 reorder_data(float2x4 data, const int depth, float2 * shift_reg, bool toggle) {
    // Use disconnected segments of length 'depth + 1' elements starting at
    // 'shift_reg' to implement the delay elements. At the end of each FFT step,
    // the contents of the entire buffer is shifted by 1 element
    data.i1 = delay(data.i1, depth, shift_reg);
    data.i3 = delay(data.i3, depth, shift_reg + depth + 1);

    if (toggle) {
        float2 tmp = data.i0;
        data.i0 = data.i1;
        data.i1 = tmp;
        tmp = data.i2;
        data.i2 = data.i3;
        data.i3 = tmp;
    }

    data.i0 = delay(data.i0, depth, shift_reg + 2 * (depth + 1));
    data.i2 = delay(data.i2, depth, shift_reg + 3 * (depth + 1));

    return data;
}

// Implements a complex number multiplication
float2 comp_mult(float2 a, float2 b) {
    float2 res;
    res.x = a.x * b.x - a.y * b.y;
    res.y = a.x * b.y + a.y * b.x;
    return res;
}

// Produces the twiddle factor associated with a processing stream 'stream',
// at a specified 'stage' during a step 'index' of the computation
//
// If there are precomputed twiddle factors for the given FFT size, uses them
// This saves hardware resources, because it avoids evaluating 'cos' and 'sin'
// functions
float2 twiddle(int index, int stage, int size, int stream) {
    float2 twid;
    // Coalesces the twiddle tables for indexed access
    constant float * twiddles_cos[TWID_STAGES][3] = {
        {tc00, tc01, tc02},
        {tc10, tc11, tc12},
        {tc20, tc21, tc22},
        {tc30, tc31, tc32},
        {tc40, tc41, tc42}
    };
    constant float * twiddles_sin[TWID_STAGES][3] = {
        {ts00, ts01, ts02},
        {ts10, ts11, ts12},
        {ts20, ts21, ts22},
        {ts30, ts31, ts32},
        {ts40, ts41, ts42}
    };

    // Use the precomputed twiddle fators, if available - otherwise, compute them
    int twid_stage = stage >> 1;
    if (size <= (1 << (TWID_STAGES * 2 + 2))) {
        twid.x = twiddles_cos[twid_stage][stream]
                                  [index * ((1 << (TWID_STAGES * 2 + 2)) / size)];
        twid.y = twiddles_sin[twid_stage][stream]
                                  [index * ((1 << (TWID_STAGES * 2 + 2)) / size)];
    } else {
        // [JO] The capability to compute the twiddle factors is deliberately
        //      omitted here to save FPGA resources
        twid.x = 0.0f;
        twid.y = 0.0f;
    }
    return twid;
}

// FFT complex rotation building block
float2x4 complex_rotate(float2x4 data, int index, int stage, int size) {
    data.i1 = comp_mult(data.i1, twiddle(index, stage, size, 0));
    data.i2 = comp_mult(data.i2, twiddle(index, stage, size, 1));
    data.i3 = comp_mult(data.i3, twiddle(index, stage, size, 2));
    return data;
}

// Process 4 input points towards and a FFT/iFFT of size N, N >= 4
// (in order input, bit reversed output). Apply all input points in N / 4
// consecutive invocations. Obtain all outputs in N / 4 consecutive invocations
// starting with invocation N / 4 - 1 (outputs are delayed). Multiple back-to-back
// transforms can be executed
//
// 'data' encapsulates 4 complex single-precision floating-point input points
// 'step' specifies the index of the current invocation
// 'fft_delay_elements' is an array representing a sliding window of size
//                      N + 4 * (log(N) - 3)
//   [JO] Modified this to the exact size required by the algorithm.
//        The architecture prescribes data shuffling blocks on stages [1, log(N)-2],
//        whose buffers take up N - 4 elements in total (cf. Eq. (4) in the paper).
//        As this implementation uses 4 extra elements per stage in order to model
//        shift registers (see also the address calculation below), we need
//        4 * (log(N) - 2) additional elements in total.
//
// 'inverse' toggles between the direct and inverse transform
// 'logN' should be a COMPILE TIME constant evaluating log(N) - the constant is
//        propagated throughout the code to achieve efficient hardware
//
float2x4 fft_step(float2x4 data, int step, float2 *fft_delay_elements,
                  bool inverse, const int logN) {
    const int size = 1 << logN;
    // Swap real and imaginary components if doing an inverse transform
    if (inverse) {
       data = swap_complex(data);
    }

    // Stage 0 of feed-forward FFT
    data = butterfly(data);
    data = trivial_rotate(data);
    data = trivial_swap(data);

    // [JO] In the 4-parallel architecture, only the very first stage has no
    //      delay elements (cf. Fig. 5 in Garrido et al.). This means that
    //      stages [1, logN-2] are handled in the loop below.

    // Next logN - 2 stages alternate two computation patterns - represented as
    // a loop to avoid code duplication. Instruct the compiler to fully unroll
    // the loop to increase the  amount of pipeline parallelism and allow feed
    // forward execution

    #pragma unroll
    for (int stage = 1; stage < logN - 1; stage++) {
        bool complex_stage = stage & 1; // stages 3, 5, ...

        // Figure out the index of the element processed at this stage
        // Subtract (add modulo size / 4) the delay incurred as data travels
        // from one stage to the next
        // [JO] Read the (previous stage's) delay as (1 << ((logN - 2) - (stage - 1))).
        //      In stage 1, data_index == step, as stage 0 does not delay the data.
        int data_index = (step + ( 1 << (logN - 1 - stage))) & (size / 4 - 1);

        data = butterfly(data);

        if (complex_stage) {
            data = complex_rotate(data, data_index, stage, size);
        }

        data = swap(data);

        // Compute the delay of this stage
        // [JO] cf. Fig. 5 in Garrido et al. (they use 1-based stage indices, though)
        int delay = 1 << (logN - 2 - stage);

        // Reordering multiplexers must toggle every 'delay' steps
        bool toggle = data_index & delay;

        // Assign unique sections of the buffer for the set of delay elements at
        // each stage
        // [JO] Garrido et al. say that for a given stage s, one needs P buffers
        //      of length N/2^(s+1).
        //      Here, keeping in mind that we use 0-based stage indices, we need
        //      4 * N/2^((stage+1)+1) == 2^(logN - stage) elements.
        //
        //      Each of the 4 shiftregs per stage has an extra element where new
        //      data is inserted (see 'delay' function).
        //
        //      For example, a 2048-point engine would use the following layout:
        //          1024+4 + 512+4 + 256+4 + 128+4 + 64+4 + 32+4 + 16+4 + 8+4 + 4+4
        //        = 2048-4 + 9*4 = 2080 elements
        //
        //      In summary, the base offset for the shiftregs of the current stage
        //      considers the buffer size of the previous stage, i.e.
        //      (1 << (logN - (stage - 1))), and the accumulated extra elements.
        float2 *head_buffer = fft_delay_elements +
                              size - (1 << (logN - stage + 1)) + 4 * (stage - 1);
        data = reorder_data(data, delay, head_buffer, toggle);

        if (!complex_stage) {
            data = trivial_rotate(data);
        }
    }

    // Stage logN - 1
    data = butterfly(data);

    // Shift the contents of the sliding window. The hardware is capable of
    // shifting the entire contents in parallel if the loop is unrolled. More
    // important, when unrolling this loop each transfer maps to a trivial
    // loop-carried dependency
    #pragma unroll
    for (int ii = 0; ii < size + 4 * (logN - 3) - 1; ii++) {
        fft_delay_elements[ii] = fft_delay_elements[ii + 1];
    }

    if (inverse) {
       data = swap_complex(data);
    }

    return data;
}
