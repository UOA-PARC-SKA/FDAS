
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
