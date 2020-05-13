
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

__attribute__((reqd_work_group_size((1 << LOGN), 1, 1)))
kernel void fetch(global float *restrict src,
                  global float *restrict coef_0,
                  int const filter_index
) {
    const int N = (1 << LOGN);

    local
    float2 buf_0[4 * N];
    local
    float2 buf_1[4 * N];
    unsigned where_global = get_global_id(0) << 2;
    unsigned i_local = get_local_id(0);
    unsigned where_local = where_global & ((1 << (LOGN + 2)) - 1);
//  unsigned ifilter = 8 * (i_local%(N/8));
    unsigned ifilter_0 = filter_index * N + 4 * (i_local & (N / 4 - 1));
    unsigned ifilter_1 = (filter_index + 43) * N + 4 * (i_local & (N / 4 - 1)); //43 = ceil(85/2)


    buf_0[where_local + 0].x = src[2 * (where_global + 0)] * coef_0[2 * ifilter_0] - src[2 * where_global + 1] * coef_0[2 * ifilter_0 + 1];
    buf_0[where_local + 0].y = src[2 * (where_global + 0) + 1] * coef_0[2 * ifilter_0] + src[2 * where_global] * coef_0[2 * ifilter_0 + 1];
    buf_0[where_local + 1].x = src[2 * (where_global + 1)] * coef_0[2 * (ifilter_0 + 1)] - src[2 * (where_global + 1) + 1] * coef_0[2 * (ifilter_0 + 1) + 1];
    buf_0[where_local + 1].y = src[2 * (where_global + 1) + 1] * coef_0[2 * (ifilter_0 + 1)] + src[2 * (where_global + 1)] * coef_0[2 * (ifilter_0 + 1) + 1];
    buf_0[where_local + 2].x = src[2 * (where_global + 2)] * coef_0[2 * (ifilter_0 + 2)] - src[2 * (where_global + 2) + 1] * coef_0[2 * (ifilter_0 + 2) + 1];
    buf_0[where_local + 2].y = src[2 * (where_global + 2) + 1] * coef_0[2 * (ifilter_0 + 2)] + src[2 * (where_global + 2)] * coef_0[2 * (ifilter_0 + 2) + 1];
    buf_0[where_local + 3].x = src[2 * (where_global + 3)] * coef_0[2 * (ifilter_0 + 3)] - src[2 * (where_global + 3) + 1] * coef_0[2 * (ifilter_0 + 3) + 1];
    buf_0[where_local + 3].y = src[2 * (where_global + 3) + 1] * coef_0[2 * (ifilter_0 + 3)] + src[2 * (where_global + 3)] * coef_0[2 * (ifilter_0 + 3) + 1];

    buf_1[where_local + 0].x = src[2 * (where_global + 0)] * coef_0[2 * ifilter_1] - src[2 * where_global + 1] * coef_0[2 * ifilter_1 + 1];
    buf_1[where_local + 0].y = src[2 * (where_global + 0) + 1] * coef_0[2 * ifilter_1] + src[2 * where_global] * coef_0[2 * ifilter_1 + 1];
    buf_1[where_local + 1].x = src[2 * (where_global + 1)] * coef_0[2 * (ifilter_1 + 1)] - src[2 * (where_global + 1) + 1] * coef_0[2 * (ifilter_1 + 1) + 1];
    buf_1[where_local + 1].y = src[2 * (where_global + 1) + 1] * coef_0[2 * (ifilter_1 + 1)] + src[2 * (where_global + 1)] * coef_0[2 * (ifilter_1 + 1) + 1];
    buf_1[where_local + 2].x = src[2 * (where_global + 2)] * coef_0[2 * (ifilter_1 + 2)] - src[2 * (where_global + 2) + 1] * coef_0[2 * (ifilter_1 + 2) + 1];
    buf_1[where_local + 2].y = src[2 * (where_global + 2) + 1] * coef_0[2 * (ifilter_1 + 2)] + src[2 * (where_global + 2)] * coef_0[2 * (ifilter_1 + 2) + 1];
    buf_1[where_local + 3].x = src[2 * (where_global + 3)] * coef_0[2 * (ifilter_1 + 3)] - src[2 * (where_global + 3) + 1] * coef_0[2 * (ifilter_1 + 3) + 1];
    buf_1[where_local + 3].y = src[2 * (where_global + 3) + 1] * coef_0[2 * (ifilter_1 + 3)] + src[2 * (where_global + 3)] * coef_0[2 * (ifilter_1 + 3) + 1];

    barrier(CLK_LOCAL_MEM_FENCE);

    int base = get_local_id(0) >> (LOGN - 2);
    int offset = get_local_id(0) & (N / 4 - 1);

    write_channel_altera(chanin0, buf_0[base * N + offset]);
    write_channel_altera(chanin1, buf_0[base * N + 2 * N / 4 + offset]);
    write_channel_altera(chanin2, buf_0[base * N + 1 * N / 4 + offset]);
    write_channel_altera(chanin3, buf_0[base * N + 3 * N / 4 + offset]);

    write_channel_altera(chanin4, buf_1[base * N + offset]);
    write_channel_altera(chanin5, buf_1[base * N + 2 * N / 4 + offset]);
    write_channel_altera(chanin6, buf_1[base * N + 1 * N / 4 + offset]);
    write_channel_altera(chanin7, buf_1[base * N + 3 * N / 4 + offset]);
}

__attribute((task))
kernel void fdfir(
        int const count,
        int const inverse
) {

    const int N = (1 << LOGN);
    float2 fft_delay_elements_0[N + 4 * (LOGN - 2)];
    float2 fft_delay_elements_1[N + 4 * (LOGN - 2)];

    for (unsigned i = 0; i < count * (N / 4) + N / 4 - 1; i++) {

        float2x4 data_0;
        float2x4 data_1;
        float power_0[4];
        float power_1[4];

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
        // Perform one step of the FFT engine
        data_0 = fft_step(data_0, i % (N / 4), fft_delay_elements_0, inverse, LOGN);
        data_1 = fft_step(data_1, i % (N / 4), fft_delay_elements_1, inverse, LOGN);


        power_0[0] = data_0.i0.x * data_0.i0.x + data_0.i0.y * data_0.i0.y;
        power_0[1] = data_0.i1.x * data_0.i1.x + data_0.i1.y * data_0.i1.y;
        power_0[2] = data_0.i2.x * data_0.i2.x + data_0.i2.y * data_0.i2.y;
        power_0[3] = data_0.i3.x * data_0.i3.x + data_0.i3.y * data_0.i3.y;

        power_1[0] = data_1.i0.x * data_1.i0.x + data_1.i0.y * data_1.i0.y;
        power_1[1] = data_1.i1.x * data_1.i1.x + data_1.i1.y * data_1.i1.y;
        power_1[2] = data_1.i2.x * data_1.i2.x + data_1.i2.y * data_1.i2.y;
        power_1[3] = data_1.i3.x * data_1.i3.x + data_1.i3.y * data_1.i3.y;
        /* Store data back to memory. FFT engine outputs are delayed by
         * N / 8 - 1 steps, hence gate writes accordingly
         */
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

__attribute__((reqd_work_group_size((1 << LOGN), 1, 1)))
kernel void reversed(global float *restrict dest_0,
                     global float *restrict dest_1,
                     int const filter_index,
                     int const padded_length) {
//					 int const N_T) { //, global float * restrict coef
    const int N = (1 << LOGN);
    const int N_T = 2637824;
    local float buf_0[4 * N];
    local float buf_1[4 * N];

    buf_0[4 * get_local_id(0) + 0] = read_channel_altera(chan0);
    buf_0[4 * get_local_id(0) + 1] = read_channel_altera(chan1);
    buf_0[4 * get_local_id(0) + 2] = read_channel_altera(chan2);
    buf_0[4 * get_local_id(0) + 3] = read_channel_altera(chan3);

    buf_1[4 * get_local_id(0) + 0] = read_channel_altera(chan4);
    buf_1[4 * get_local_id(0) + 1] = read_channel_altera(chan5);
    buf_1[4 * get_local_id(0) + 2] = read_channel_altera(chan6);
    buf_1[4 * get_local_id(0) + 3] = read_channel_altera(chan7);

    barrier(CLK_LOCAL_MEM_FENCE);

    int colt = get_local_id(0);
    int group = get_group_id(0);
    int revcolt = bit_reversed(colt, LOGN);
    int i = get_global_id(0) >> LOGN;
    int where = colt + (group << (LOGN + 2)) + filter_index * padded_length;

    dest_0[where] = buf_0[revcolt] / 4194304;
    dest_0[N + where] = buf_0[N + revcolt] / 4194304;
    dest_0[2 * N + where] = buf_0[2 * N + revcolt] / 4194304;
    dest_0[3 * N + where] = buf_0[3 * N + revcolt] / 4194304;

    dest_1[where] = buf_1[revcolt] / 4194304;
    dest_1[N + where] = buf_1[N + revcolt] / 4194304;
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
__kernel void discard(
        __global float *restrict dataPtr_0,   //2048 x GROUP_N x FILTER_N / 2
        __global float *restrict dataPtr_1,   //2048 x GROUP_N x FILTER_N / 2
        __global float *restrict outputPtr,   //1627 x GROUP_N x FILTER_N
//         const unsigned int tile_size,       //TILE_SIZE
//         const unsigned int filter_size      //FILTER_SIZE
        const unsigned int totalGroup     //GROUP_N*FILTER_N/2
) {
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
__kernel
void harmonic_summing(
        __global volatile float *restrict dataPtr,   //2^LOGN
        __global float *restrict detection,
        __constant float *restrict threshold, //SP_N
        __global unsigned int *restrict detection_l,
        const unsigned int singleLength,       //2^LOGN/HM_PF - 1
        const unsigned int totalLength,     //2^LOGN x T_N / HM_PF
        __global float *restrict resultPtr //2^LOGN x T_N
) {
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

