///////////////////////////////////////////////////////////////////////////////////
// This OpenCL application executs a 1D FFT transform on an Altera FPGA.
// The kernel is defined in a device/fdfir.cl file.  The Altera
// Offline Compiler tool ('aoc') compiles the kernel source into a 'fdfir.aocx'
// file containing a hardware programming image for the FPGA.  The host program
// provides the contents of the .aocx file to the clCreateProgramWithBinary OpenCL
// API for runtime programming of the FPGA.
//
// When compiling this application, ensure that the Altera SDK for OpenCL
// is properly installed.
///////////////////////////////////////////////////////////////////////////////////
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#define _USE_MATH_DEFINES

#include <math.h>
#include <cstring>
#include <algorithm>
#include "CL/opencl.h"
#include "AOCL_Utils.h"
#include "fdas.h"
//#include "fft_config.h"

//env CL_CONTEXT_EMULATOR_DEVICE_ALTERA=1 <host_program>
#define LOGN 11
#define EPS .00000011921
#define POINTS 4
#define ITERATION 1
// the above header defines log of the FFT size hardcoded in the kernel
// compute N as 2^LOGN
#define N (1 << LOGN)
#define FILTER_SIZE 421
#define INPUT_SIZE 2095576
#define TILE_SIZE 2048
#define FILTER_N 85// The total number of Filters is 3 * FILTER_N
#define GROUP_N 1288// actually 1289, to make it times of 8 
// The length of OLS algorithm set is 2048, the valid of output size is 2048-422+1 = 1627
// The input is divided into [2097152/1627]= 1289 groups [4194468]

#define DS   40      // maximum detection size
#define SP_N 8       // Number of SP planes
using namespace aocl_utils;

#define STRING_BUFFER_LEN 1024

// ACL runtime configuration
static cl_platform_id platform = NULL;
static cl_device_id device = NULL;
static cl_context context = NULL;
static cl_command_queue queue_1 = NULL, queue_2 = NULL, queue_3 = NULL;
static cl_command_queue queue_4 = NULL, queue_5 = NULL;
static cl_command_queue queue_6 = NULL;//, queue_7 = NULL;
static cl_kernel kernel_fetch = NULL, kernel_fdfir = NULL, kernel_reversed = NULL;
static cl_kernel kernel_discard = NULL; //kernel_transpose = NULL;
static cl_kernel kernel_harmonic = NULL;//kernel_candidate = NULL;
static cl_program program = NULL;
static cl_int status = 0;
cl_mem dev_datainput_0;
cl_mem dev_datainput_1;
cl_mem dev_filterconst;
cl_mem dev_discard_0;
cl_mem dev_discard_1;
//cl_mem dev_reorder;
cl_mem dev_result_0;
cl_mem dev_result_a0;
cl_mem dev_result_b0;
cl_mem dev_result_1;
cl_mem dev_result_a1;
cl_mem dev_result_b1;
cl_mem dev_detLocation_0, dev_detection_0;
cl_mem dev_detLocation_1, dev_detection_1;
cl_mem dev_threshold;
cl_event myEvent;

// Function prototypes
void cleanup();

void Print_Candidate(struct fdFirVariables *fdFirVars);


int main(int argc, char **argv) {

    struct fdFirVariables fdFirVars;
    fdFirVars.arguments = 1;
    fdFirVars.dataSet = 1;

    if (!init()) {
        return false;
    }
    double startTime, stopTime;
    fdFirSetup(&fdFirVars);

    startTime = getCurrentTimestamp();

    int iterations = GROUP_N;

    test_fft(&fdFirVars, iterations);
    stopTime = getCurrentTimestamp();
    float overall_latency = stopTime - startTime;
    printf("  Overall latency is  %0.3f ms\n", overall_latency * 1E3);
    fdFirComplete(&fdFirVars);
//    harmonicCompare(&fdFirVars);
//    Print_Candidate(&fdFirVars);
    return 0;
}

void fdFirSetup(struct fdFirVariables *fdFirVars) {
    int inputLength, filterLength, resultLength;
    char dataSetString[100];
    char filterSetString[100];
//  char discardSetString[100];

    sprintf(dataSetString, "./real_data/padded_input_p_1_234_2584group.dat");
    sprintf(filterSetString, "./real_data/template_fft_85x2048.dat");
//  sprintf(discardSetString,"./real_data/tv_p1_234_fop_t_sw.dat");

    readFromFile(float, dataSetString, fdFirVars->input);
    readFromFile(float, filterSetString, fdFirVars->filter);
//  readFromFile(float, discardSetString, fdFirVars->discard);  

    pca_create_carray_1d(float, fdFirVars->time, 1, PCA_REAL);

    fdFirVars->time.data[0] = 0.0f;
    fdFirVars->time.data[1] = 0.0f;
    fdFirVars->time.data[2] = 0.0f;

    pca_create_carray_1d(float, fdFirVars->detection, DS * SP_N, PCA_REAL);
    zeroData<float>(fdFirVars->detection.data, DS * SP_N, 1);
    pca_create_carray_1d(int, fdFirVars->detLocation, DS * SP_N, PCA_REAL);
    zeroData<int>(fdFirVars->detLocation.data, DS * SP_N, 1);
    pca_create_carray_1d(float, fdFirVars->result, FILTER_N * INPUT_SIZE, PCA_REAL);
    zeroData<float>(fdFirVars->result.data, FILTER_N * INPUT_SIZE, 1);
    //pca_create_carray_1d(float, fdFirVars->threshold, FILTER_N*SP_N, PCA_REAL);
    //zeroData<float>(fdFirVars->threshold.data, FILTER_N*SP_N, 1);

}

void test_fft(struct fdFirVariables *fdFirVars, int iterations) {

    printf("Launching...\n");
    int err;
    double startTime, stopTime;

    float *inputPtr = fdFirVars->input.data;
    float *filterPtr = fdFirVars->filter.data;
    float *resultPtr = fdFirVars->result.data;
    float *discardPtr = fdFirVars->discard.data;
    float *thresholdPtr = fdFirVars->threshold.data;
    float *detectionPtr = fdFirVars->detection.data;
    int *detLocationPtr = fdFirVars->detLocation.data;

    int filterLength = fdFirVars->filterLength;
    int inputLength = INPUT_SIZE; //fdFirVars->inputLength;
    int resultLength = (TILE_SIZE - FILTER_SIZE) * GROUP_N * FILTER_N;

//    float * paddedInputPtr 	= 0;
//    float * paddedResultPtr = 0;
//    float * paddedcoef 		= 0;
//    float * inputPtr_reorder= 0;  
//    float * paddeddetection = 0;
//    int   * paddeddetLocation = 0;
//    float * reorderPtr = fdFirVars->result.data; 

    int totalDataInputLength_H = FILTER_N * GROUP_N * (TILE_SIZE - FILTER_SIZE);
    int totalDataInputLength_L = FILTER_N * INPUT_SIZE;
    int totalResultLength = DS * SP_N;
    int totalthresLength = SP_N * FILTER_N;
    int totalDataInputLength = 2 * TILE_SIZE * GROUP_N;
    int paddedNumResultLength = TILE_SIZE * GROUP_N * FILTER_N * 1;
    int paddedcoefLength = TILE_SIZE * FILTER_N;

    startTime = getCurrentTimestamp();
    // this assumes that the inputLength is the same for each filter
/////////////////////////////For Device A////////////////////////////////////////
    dev_datainput_0 = clCreateBuffer(context, CL_MEM_READ_ONLY,
                                     sizeof(float) * totalDataInputLength, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_datainput_1 = clCreateBuffer(context, CL_MEM_READ_ONLY,
                                     sizeof(float) * totalDataInputLength, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_filterconst = clCreateBuffer(context, CL_MEM_READ_ONLY,//| CL_MEM_BANK_2_ALTERA, 
                                     sizeof(float) * 2 * TILE_SIZE * (FILTER_N + 1), NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_result_0 = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_BANK_2_ALTERA,
                                  sizeof(float) * totalDataInputLength_L, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_result_a0 = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_BANK_2_ALTERA,
                                   sizeof(float) * GROUP_N * TILE_SIZE * 43, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_result_b0 = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_BANK_2_ALTERA,
                                   sizeof(float) * GROUP_N * TILE_SIZE * 43, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_result_1 = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_BANK_2_ALTERA,
                                  sizeof(float) * totalDataInputLength_L, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_result_a1 = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_BANK_2_ALTERA,
                                   sizeof(float) * GROUP_N * TILE_SIZE * 43, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_result_b1 = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_BANK_2_ALTERA,
                                   sizeof(float) * GROUP_N * TILE_SIZE * 43, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_discard_0 = clCreateBuffer(context, CL_MEM_READ_WRITE,
                                   sizeof(float) * totalDataInputLength_L, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_discard_1 = clCreateBuffer(context, CL_MEM_READ_WRITE,
                                   sizeof(float) * totalDataInputLength_L, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
//    dev_reorder = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_BANK_2_ALTERA, 
//                        sizeof(float)*totalDataInputLength_L, NULL, &err);
//    checkError(err, "Failed to allocate device memory!");
    dev_threshold = clCreateBuffer(context, CL_MEM_READ_ONLY,//| CL_MEM_BANK_2_ALTERA, 
                                   sizeof(float) * totalthresLength, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_detLocation_0 = clCreateBuffer(context, CL_MEM_WRITE_ONLY,
                                       sizeof(int) * totalResultLength, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_detection_0 = clCreateBuffer(context, CL_MEM_WRITE_ONLY,
                                     sizeof(float) * totalResultLength, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_detLocation_1 = clCreateBuffer(context, CL_MEM_WRITE_ONLY,
                                       sizeof(int) * totalResultLength, NULL, &err);
    checkError(err, "Failed to allocate device memory!");
    dev_detection_1 = clCreateBuffer(context, CL_MEM_WRITE_ONLY,
                                     sizeof(float) * totalResultLength, NULL, &err);
    checkError(err, "Failed to allocate device memory!");

    thresholdPtr = (float *) alignedMalloc(sizeof(float) * totalthresLength);
    memset(thresholdPtr, '\0', sizeof(int) * totalthresLength);

    for (int i = 0; i < FILTER_N; i++) {
        thresholdPtr[(i << 3) + 0] = 0.007f;
        thresholdPtr[(i << 3) + 1] = 0.008f;
        thresholdPtr[(i << 3) + 2] = 0.009f;
        thresholdPtr[(i << 3) + 3] = 0.01f;
        thresholdPtr[(i << 3) + 4] = 0.011f;
        thresholdPtr[(i << 3) + 5] = 0.012f;
        thresholdPtr[(i << 3) + 6] = 0.014f;
        thresholdPtr[(i << 3) + 7] = 0.015f;
    }

/////////////////////////////////////////////////////////////////////////////////
////////////////////////////Enqueue Write Buffer/////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

    err = clEnqueueWriteBuffer(queue_1, dev_datainput_0, CL_FALSE, 0,
                               sizeof(float) * totalDataInputLength,
                               inputPtr, 0, NULL, &myEvent);
    checkError(err, "Failed to write input buffer!");
    err = clEnqueueWriteBuffer(queue_1, dev_datainput_1, CL_FALSE, 0,
                               sizeof(float) * totalDataInputLength,
                               inputPtr, 0, NULL, &myEvent);
    checkError(err, "Failed to write input buffer!");
    err = clEnqueueWriteBuffer(queue_1, dev_filterconst, CL_FALSE, 0,
                               sizeof(float) * 2 * paddedcoefLength,
                               filterPtr, 0, NULL, &myEvent);
    checkError(err, "Failed to write filterconst!");
    err = clEnqueueWriteBuffer(queue_1, dev_threshold, CL_FALSE, 0,
                               sizeof(float) * totalthresLength,
                               thresholdPtr, 0, NULL, &myEvent);
    checkError(err, "Failed to write thresholdPtr!");

//    err = clEnqueueWriteBuffer(queue_1, dev_discard, CL_FALSE, 0, 
//                     sizeof(float) * totalDataInputLength_L,
//                     discardPtr, 0, NULL, &myEvent);
//    checkError(err, "Failed to write thresholdPtr!");

    status = clFinish(queue_1);
    checkError(status, "Failed to finish queue_a1");

    stopTime = getCurrentTimestamp();
    fdFirVars->time.data[1] += (float) (stopTime - startTime);

    startTime = getCurrentTimestamp();
    int inverse_int = true;
    int filter_index = 0;
    size_t lws_fetch[] = {N};
    size_t gws_fetch[] = {iterations * N / POINTS};
    size_t lws_transpose[] = {N};
    size_t gws_transpose[] = {iterations * N / POINTS};
    printf("FT-Convolution Start\n");

//********************************kernel_fetch*************************************	
    // Set the kernel arguments for kernel_fetch
    status = clSetKernelArg(kernel_fetch, 0, sizeof(cl_mem), (void *) &dev_datainput_0);
    checkError(status, "Failed to set kernel arg 0");
    status = clSetKernelArg(kernel_fetch, 1, sizeof(cl_mem), (void *) &dev_filterconst);
    checkError(status, "Failed to set kernel arg 1");
    status = clSetKernelArg(kernel_fetch, 2, sizeof(cl_int), (void *) &filter_index);
    checkError(status, "Failed to set kernel arg 2");
//********************************kernel_fdfir*************************************	  
    // Set the kernel arguments for kernel_fdfir
    status = clSetKernelArg(kernel_fdfir, 0, sizeof(cl_int), (void *) &iterations);
    checkError(status, "Failed to set kernel arg 0 iterations_1");
    status = clSetKernelArg(kernel_fdfir, 1, sizeof(cl_int), (void *) &inverse_int);
    checkError(status, "Failed to set kernel arg 1");

//********************************kernel_reversed*************************************
    int padded_length_l = GROUP_N * TILE_SIZE;//(TILE_SIZE-FILTER_SIZE);
    status = clSetKernelArg(kernel_reversed, 0, sizeof(cl_mem), (void *) &dev_result_a0);
    checkError(status, "Failed to set kernel_reversed arg 0");
    status = clSetKernelArg(kernel_reversed, 1, sizeof(cl_mem), (void *) &dev_result_b0);
    checkError(status, "Failed to set kernel_reversed arg 0");
    status = clSetKernelArg(kernel_reversed, 2, sizeof(cl_int), (void *) &filter_index);
    checkError(status, "Failed to set kernel arg 1");
    status = clSetKernelArg(kernel_reversed, 3, sizeof(cl_int), (void *) &padded_length_l);
    checkError(status, "Failed to set kernel arg 1");

    for (int ilen_f = 0; ilen_f < 43; ilen_f++) {
//			printf("FIR %d Starts\n", ilen_f);
        status = clSetKernelArg(kernel_fetch, 2, sizeof(cl_int), (void *) &ilen_f);
        checkError(status, "Failed to set kernel arg 2");

        status = clSetKernelArg(kernel_reversed, 2, sizeof(cl_int), (void *) &ilen_f);
        checkError(status, "Failed to set kernel arg 1");

        status = clEnqueueNDRangeKernel(queue_1, kernel_fetch, 1, 0, gws_fetch, lws_fetch, 0, NULL, NULL);
        checkError(status, "Failed to launch kernel");
        status = clEnqueueTask(queue_2, kernel_fdfir, 0, NULL, NULL);
        checkError(status, "Failed to launch kernel_fdfir");
        status = clEnqueueNDRangeKernel(queue_3, kernel_reversed, 1, 0, gws_transpose, lws_transpose, 0, NULL, NULL);
        checkError(status, "Failed to launch kernel");

        // Wait for command queue to complete pending events
        status = clFinish(queue_1);
        checkError(status, "Failed to finish queue");
        status = clFinish(queue_2);
        checkError(status, "Failed to finish queue2");
        status = clFinish(queue_3);
        checkError(status, "Failed to finish queue3");
    }

//********************************kernel_discard*************************************
    printf("Discard Start\n");
    int it_discard = 43 * GROUP_N;
    status = clSetKernelArg(kernel_discard, 0, sizeof(cl_mem), (void *) &dev_result_a0);
    checkError(status, "Failed to set kernel_discard arg 0");
    status = clSetKernelArg(kernel_discard, 1, sizeof(cl_mem), (void *) &dev_result_b0);
    checkError(status, "Failed to set kernel_discard arg 0");
    status = clSetKernelArg(kernel_discard, 2, sizeof(cl_mem), (void *) &dev_discard_0);
    checkError(status, "Failed to set kernel_discard arg 1");
    status = clSetKernelArg(kernel_discard, 3, sizeof(cl_int), (void *) &it_discard);
    checkError(status, "Failed to set kernel_discard arg 2");
    status = clEnqueueTask(queue_4, kernel_discard, 0, NULL, NULL);
    checkError(status, "Failed to launch kernel_discard");
    status = clFinish(queue_4);
    checkError(status, "Failed to finish queue_4");


    for (int iloop = 1; iloop < 4; iloop++) {
        if ((iloop % 2) == 1) {
//********************************kernel_fetch*************************************	
            // Set the kernel arguments for kernel_fetch
            status = clSetKernelArg(kernel_fetch, 0, sizeof(cl_mem), (void *) &dev_datainput_1);
            checkError(status, "Failed to set kernel arg 0");
            status = clSetKernelArg(kernel_fetch, 1, sizeof(cl_mem), (void *) &dev_filterconst);
            checkError(status, "Failed to set kernel arg 1");
            status = clSetKernelArg(kernel_fetch, 2, sizeof(cl_int), (void *) &filter_index);
            checkError(status, "Failed to set kernel arg 2");
//********************************kernel_fdfir*************************************	  
            // Set the kernel arguments for kernel_fdfir
            status = clSetKernelArg(kernel_fdfir, 0, sizeof(cl_int), (void *) &iterations);
            checkError(status, "Failed to set kernel arg 0 iterations_1");
            status = clSetKernelArg(kernel_fdfir, 1, sizeof(cl_int), (void *) &inverse_int);
            checkError(status, "Failed to set kernel arg 1");

//********************************kernel_reversed*************************************
            int padded_length_l = GROUP_N * TILE_SIZE;//(TILE_SIZE-FILTER_SIZE);
            status = clSetKernelArg(kernel_reversed, 0, sizeof(cl_mem), (void *) &dev_result_a1);
            checkError(status, "Failed to set kernel_reversed arg 0");
            status = clSetKernelArg(kernel_reversed, 1, sizeof(cl_mem), (void *) &dev_result_b1);
            checkError(status, "Failed to set kernel_reversed arg 0");
            status = clSetKernelArg(kernel_reversed, 2, sizeof(cl_int), (void *) &filter_index);
            checkError(status, "Failed to set kernel arg 1");
            status = clSetKernelArg(kernel_reversed, 3, sizeof(cl_int), (void *) &padded_length_l);
            checkError(status, "Failed to set kernel arg 1");
//********************************kernel_discard*************************************
            int it_discard = 43 * GROUP_N;
            status = clSetKernelArg(kernel_discard, 0, sizeof(cl_mem), (void *) &dev_result_a1);
            checkError(status, "Failed to set kernel_discard arg 0");
            status = clSetKernelArg(kernel_discard, 1, sizeof(cl_mem), (void *) &dev_result_b1);
            checkError(status, "Failed to set kernel_discard arg 0");
            status = clSetKernelArg(kernel_discard, 2, sizeof(cl_mem), (void *) &dev_discard_1);
            checkError(status, "Failed to set kernel_discard arg 1");
            status = clSetKernelArg(kernel_discard, 3, sizeof(cl_int), (void *) &it_discard);
            checkError(status, "Failed to set kernel_discard arg 2");
//********************************kernel_harmonic*************************************

            size_t totalDataInputLength_1 = GROUP_N * (TILE_SIZE - FILTER_SIZE) / 2 - 1;//(FILTER_N-1);
            unsigned int totalDataInputLength_2 = FILTER_N * GROUP_N * (TILE_SIZE - FILTER_SIZE) / 2;
            // Set the kernel arguments for kernel
            status = clSetKernelArg(kernel_harmonic, 0, sizeof(cl_mem), (void *) &dev_discard_0);
            checkError(status, "Failed to set kernel_harmonic arg 0");
            status = clSetKernelArg(kernel_harmonic, 1, sizeof(cl_mem), (void *) &dev_detection_0);
            checkError(status, "Failed to set kernel_harmonic arg 1");
            status = clSetKernelArg(kernel_harmonic, 2, sizeof(cl_mem), (void *) &dev_threshold);
            checkError(status, "Failed to set kernel_harmonic arg 2");
            status = clSetKernelArg(kernel_harmonic, 3, sizeof(cl_mem), (void *) &dev_detLocation_0);
            checkError(status, "Failed to set kernel_harmonic arg 3");
            status = clSetKernelArg(kernel_harmonic, 4, sizeof(cl_int), (void *) &totalDataInputLength_1);
            checkError(status, "Failed to set kernel_harmonic arg 4");
            status = clSetKernelArg(kernel_harmonic, 5, sizeof(cl_int), (void *) &totalDataInputLength_2);
            checkError(status, "Failed to set kernel_harmonic arg 5");
            status = clSetKernelArg(kernel_harmonic, 6, sizeof(cl_mem), (void *) &dev_result_0);
            checkError(status, "Failed to set kernel_harmonic arg 6");


            status = clEnqueueTask(queue_6, kernel_harmonic, 0, NULL, NULL);
            checkError(status, "Failed to launch kernel_harmonic");

            for (int ilen_f = 0; ilen_f < 43; ilen_f++) {
                status = clSetKernelArg(kernel_fetch, 2, sizeof(cl_int), (void *) &ilen_f);
                checkError(status, "Failed to set kernel arg 2");

                status = clSetKernelArg(kernel_reversed, 2, sizeof(cl_int), (void *) &ilen_f);
                checkError(status, "Failed to set kernel arg 1");

                status = clEnqueueNDRangeKernel(queue_1, kernel_fetch, 1, 0, gws_fetch, lws_fetch, 0, NULL, NULL);
                checkError(status, "Failed to launch kernel");
                status = clEnqueueTask(queue_2, kernel_fdfir, 0, NULL, NULL);
                checkError(status, "Failed to launch kernel_fdfir");
                status = clEnqueueNDRangeKernel(queue_3, kernel_reversed, 1, 0, gws_transpose, lws_transpose, 0, NULL, NULL);
                checkError(status, "Failed to launch kernel");

                // Wait for command queue to complete pending events
                status = clFinish(queue_1);
                checkError(status, "Failed to finish queue");
                status = clFinish(queue_2);
                checkError(status, "Failed to finish queue2");
                status = clFinish(queue_3);
                checkError(status, "Failed to finish queue3");
            }
            status = clEnqueueTask(queue_4, kernel_discard, 0, NULL, NULL);
            checkError(status, "Failed to launch kernel_discard");
            status = clFinish(queue_4);
            checkError(status, "Failed to finish queue_4");
            status = clFinish(queue_6);
            checkError(status, "Failed to finish queue_6");
        }
        if ((iloop % 2) == 0) {
//********************************kernel_fetch*************************************	
            // Set the kernel arguments for kernel_fetch
            status = clSetKernelArg(kernel_fetch, 0, sizeof(cl_mem), (void *) &dev_datainput_0);
            checkError(status, "Failed to set kernel arg 0");
            status = clSetKernelArg(kernel_fetch, 1, sizeof(cl_mem), (void *) &dev_filterconst);
            checkError(status, "Failed to set kernel arg 1");
            status = clSetKernelArg(kernel_fetch, 2, sizeof(cl_int), (void *) &filter_index);
            checkError(status, "Failed to set kernel arg 2");
//********************************kernel_fdfir*************************************	  
            // Set the kernel arguments for kernel_fdfir
            status = clSetKernelArg(kernel_fdfir, 0, sizeof(cl_int), (void *) &iterations);
            checkError(status, "Failed to set kernel arg 0 iterations_1");
            status = clSetKernelArg(kernel_fdfir, 1, sizeof(cl_int), (void *) &inverse_int);
            checkError(status, "Failed to set kernel arg 1");

//********************************kernel_reversed*************************************
            int padded_length_l = GROUP_N * TILE_SIZE;//(TILE_SIZE-FILTER_SIZE);
            status = clSetKernelArg(kernel_reversed, 0, sizeof(cl_mem), (void *) &dev_result_a0);
            checkError(status, "Failed to set kernel_reversed arg 0");
            status = clSetKernelArg(kernel_reversed, 1, sizeof(cl_mem), (void *) &dev_result_b0);
            checkError(status, "Failed to set kernel_reversed arg 0");
            status = clSetKernelArg(kernel_reversed, 2, sizeof(cl_int), (void *) &filter_index);
            checkError(status, "Failed to set kernel arg 1");
            status = clSetKernelArg(kernel_reversed, 3, sizeof(cl_int), (void *) &padded_length_l);
            checkError(status, "Failed to set kernel arg 1");
//********************************kernel_discard*************************************
            int it_discard = 43 * GROUP_N;
            status = clSetKernelArg(kernel_discard, 0, sizeof(cl_mem), (void *) &dev_result_a0);
            checkError(status, "Failed to set kernel_discard arg 0");
            status = clSetKernelArg(kernel_discard, 1, sizeof(cl_mem), (void *) &dev_result_b0);
            checkError(status, "Failed to set kernel_discard arg 0");
            status = clSetKernelArg(kernel_discard, 2, sizeof(cl_mem), (void *) &dev_discard_0);
            checkError(status, "Failed to set kernel_discard arg 1");
            status = clSetKernelArg(kernel_discard, 3, sizeof(cl_int), (void *) &it_discard);
            checkError(status, "Failed to set kernel_discard arg 2");
//********************************kernel_harmonic*************************************

            size_t totalDataInputLength_1 = GROUP_N * (TILE_SIZE - FILTER_SIZE) / 2 - 1;//(FILTER_N-1);
            unsigned int totalDataInputLength_2 = FILTER_N * GROUP_N * (TILE_SIZE - FILTER_SIZE) / 2;
            // Set the kernel arguments for kernel
            status = clSetKernelArg(kernel_harmonic, 0, sizeof(cl_mem), (void *) &dev_discard_1);
            checkError(status, "Failed to set kernel_harmonic arg 0");
            status = clSetKernelArg(kernel_harmonic, 1, sizeof(cl_mem), (void *) &dev_detection_1);
            checkError(status, "Failed to set kernel_harmonic arg 1");
            status = clSetKernelArg(kernel_harmonic, 2, sizeof(cl_mem), (void *) &dev_threshold);
            checkError(status, "Failed to set kernel_harmonic arg 2");
            status = clSetKernelArg(kernel_harmonic, 3, sizeof(cl_mem), (void *) &dev_detLocation_1);
            checkError(status, "Failed to set kernel_harmonic arg 3");
            status = clSetKernelArg(kernel_harmonic, 4, sizeof(cl_int), (void *) &totalDataInputLength_1);
            checkError(status, "Failed to set kernel_harmonic arg 4");
            status = clSetKernelArg(kernel_harmonic, 5, sizeof(cl_int), (void *) &totalDataInputLength_2);
            checkError(status, "Failed to set kernel_harmonic arg 5");
            status = clSetKernelArg(kernel_harmonic, 6, sizeof(cl_mem), (void *) &dev_result_1);
            checkError(status, "Failed to set kernel_harmonic arg 6");


            status = clEnqueueTask(queue_6, kernel_harmonic, 0, NULL, NULL);
            checkError(status, "Failed to launch kernel_harmonic");

            for (int ilen_f = 0; ilen_f < 43; ilen_f++) {
                status = clSetKernelArg(kernel_fetch, 2, sizeof(cl_int), (void *) &ilen_f);
                checkError(status, "Failed to set kernel arg 2");

                status = clSetKernelArg(kernel_reversed, 2, sizeof(cl_int), (void *) &ilen_f);
                checkError(status, "Failed to set kernel arg 1");

                status = clEnqueueNDRangeKernel(queue_1, kernel_fetch, 1, 0, gws_fetch, lws_fetch, 0, NULL, NULL);
                checkError(status, "Failed to launch kernel");
                status = clEnqueueTask(queue_2, kernel_fdfir, 0, NULL, NULL);
                checkError(status, "Failed to launch kernel_fdfir");
                status = clEnqueueNDRangeKernel(queue_3, kernel_reversed, 1, 0, gws_transpose, lws_transpose, 0, NULL, NULL);
                checkError(status, "Failed to launch kernel");

                // Wait for command queue to complete pending events
                status = clFinish(queue_1);
                checkError(status, "Failed to finish queue");
                status = clFinish(queue_2);
                checkError(status, "Failed to finish queue2");
                status = clFinish(queue_3);
                checkError(status, "Failed to finish queue3");
            }
            status = clEnqueueTask(queue_4, kernel_discard, 0, NULL, NULL);
            checkError(status, "Failed to launch kernel_discard");
            status = clFinish(queue_4);
            checkError(status, "Failed to finish queue_4");
            status = clFinish(queue_6);
            checkError(status, "Failed to finish queue_6");
        }
    }
    printf("--------------\n");
    printf("Harmonic-summing Done\n");
    stopTime = getCurrentTimestamp();
    float hs_kernel = (float) (stopTime - startTime);

    printf(" Start loading candidates and HM8. \n");
    startTime = getCurrentTimestamp();

    err = clEnqueueReadBuffer(queue_1, dev_detection_0, CL_FALSE, 0,
                              sizeof(float) * totalResultLength, detectionPtr, 0, NULL, NULL);
    checkError(err, "Failed to read result array!");
    err = clEnqueueReadBuffer(queue_1, dev_detLocation_0, CL_FALSE, 0,
                              sizeof(int) * totalResultLength, detLocationPtr, 0, NULL, NULL);
    checkError(err, "Failed to read result array!");
    err = clEnqueueReadBuffer(queue_1, dev_result_0, CL_FALSE, 0,
                              sizeof(float) * totalDataInputLength_L, resultPtr, 0, NULL, &myEvent);
    checkError(err, "Failed to read result array!");
    err = clFinish(queue_1);
    checkError(err, "Failed to finish queue");
    // Copy the result into the original result array, by starting 
//    memcpy(detectionPtr, paddeddetection, sizeof(float) * totalResultLength);
//    memcpy(detLocationPtr, paddeddetLocation, sizeof(int) * totalResultLength); 

    stopTime = getCurrentTimestamp();
    fdFirVars->time.data[0] = (float) (stopTime - startTime);

    printf("Done.\n ");
}

bool init() {
    cl_int status;

    if (!setCwdToExeDir()) {
        return false;
    }

    // Get the OpenCL platform.
    platform = findPlatform("Altera");
    if (platform == NULL) {
        printf("ERROR: Unable to find Altera OpenCL platform\n");
        return false;
    }
    {
        char char_buffer[STRING_BUFFER_LEN];
        printf("Querying platform for info:\n");
        printf("==========================\n");
        clGetPlatformInfo(platform, CL_PLATFORM_NAME, STRING_BUFFER_LEN, char_buffer, NULL);
        printf("%-40s = %s\n", "CL_PLATFORM_NAME", char_buffer);
        clGetPlatformInfo(platform, CL_PLATFORM_VENDOR, STRING_BUFFER_LEN, char_buffer, NULL);
        printf("%-40s = %s\n", "CL_PLATFORM_VENDOR ", char_buffer);
        clGetPlatformInfo(platform, CL_PLATFORM_VERSION, STRING_BUFFER_LEN, char_buffer, NULL);
        printf("%-40s = %s\n\n", "CL_PLATFORM_VERSION ", char_buffer);
    }
    // Query the available OpenCL devices.
    scoped_array<cl_device_id> devices;
    cl_uint num_devices;

    devices.reset(getDevices(platform, CL_DEVICE_TYPE_ALL, &num_devices));
    printf("There are total %d device(s)\n", num_devices);
    // We'll just use the first device.
    device = devices[0];
    // Create the context.
    context = clCreateContext(NULL, 1, &device, NULL, NULL, &status);
    checkError(status, "Failed to create context");

    // Create the program.
    std::string binary_file = getBoardBinaryFile("fdas_fft2_op2_ll", device);
    printf("Using AOCX: %s\n\n", binary_file.c_str());
    program = createProgramFromBinary(context, binary_file.c_str(), &device, 1);

    // Build the program that was just created.
    status = clBuildProgram(program, 0, NULL, "", NULL, NULL);
    checkError(status, "Failed to build program");

    // Create the command queue.
    queue_1 = clCreateCommandQueue(context, device, CL_QUEUE_PROFILING_ENABLE, &status);
    checkError(status, "Failed to create command queue_1");
    queue_2 = clCreateCommandQueue(context, device, CL_QUEUE_PROFILING_ENABLE, &status);
    checkError(status, "Failed to create command queue_2");
    queue_3 = clCreateCommandQueue(context, device, CL_QUEUE_PROFILING_ENABLE, &status);
    checkError(status, "Failed to create command queue_3");
    queue_4 = clCreateCommandQueue(context, device, CL_QUEUE_PROFILING_ENABLE, &status);
    checkError(status, "Failed to create command queue_4");
    queue_5 = clCreateCommandQueue(context, device, CL_QUEUE_PROFILING_ENABLE, &status);
    checkError(status, "Failed to create command queue_5");
    queue_6 = clCreateCommandQueue(context, device, CL_QUEUE_PROFILING_ENABLE, &status);
    checkError(status, "Failed to create command queue_6");

    kernel_fetch = clCreateKernel(program, "fetch", &status);
    checkError(status, "Failed to create kernel fetch");
    kernel_fdfir = clCreateKernel(program, "fdfir", &status);
    checkError(status, "Failed to create kernel fdfir");
    kernel_reversed = clCreateKernel(program, "reversed", &status);
    checkError(status, "Failed to create kernel reversed");
    kernel_discard = clCreateKernel(program, "discard", &status);
    checkError(status, "Failed to create kernel discard");
//	kernel_transpose = clCreateKernel(program, "transpose", &status);
//    checkError(status, "Failed to create kernel transpose");
    kernel_harmonic = clCreateKernel(program, "harmonic_summing", &status);
    checkError(status, "Failed to create kernel harmonic_summing");

    return true;
}

// Free the resources allocated during initialization
void cleanup() {
    if (kernel_fetch)
        clReleaseKernel(kernel_fetch);
    if (kernel_fdfir)
        clReleaseKernel(kernel_fdfir);
    if (kernel_reversed)
        clReleaseKernel(kernel_reversed);
    if (kernel_discard)
        clReleaseKernel(kernel_discard);
//    if(kernel_transpose)
//        clReleaseKernel(kernel_transpose);  		
    if (kernel_harmonic)
        clReleaseKernel(kernel_harmonic);
    if (program)
        clReleaseProgram(program);
    if (queue_1)
        clReleaseCommandQueue(queue_1);
    if (queue_2)
        clReleaseCommandQueue(queue_2);
    if (queue_3)
        clReleaseCommandQueue(queue_3);
    if (queue_4)
        clReleaseCommandQueue(queue_4);
    if (queue_5)
        clReleaseCommandQueue(queue_5);
    if (queue_6)
        clReleaseCommandQueue(queue_6);
    if (context)
        clReleaseContext(context);
}

void fdFirComplete(struct fdFirVariables *fdFirVars) {
    char timeString[100];
    char detectionString[100];
    char detLocationString[100];
    char temp_result[100];

    sprintf(timeString, "./%d-fdFir-time.dat", fdFirVars->dataSet);
    sprintf(detectionString, "./test_result/%d-detection.dat", fdFirVars->dataSet);
    sprintf(detLocationString, "./test_result/%d-detLocation.dat", fdFirVars->dataSet);
    sprintf(temp_result, "./real_data/tv_p1_234_hm8.dat");
    printf("Writing the candidate to *.dat file.\n ");
    writeToFile(float, timeString, fdFirVars->time);
    writeToFile(float, detectionString, fdFirVars->detection);
    writeToFile(float, detLocationString, fdFirVars->detLocation);
    writeToFile(float, temp_result, fdFirVars->result);

//  clean_mem(float, fdFirVars->input);
//  clean_mem(float, fdFirVars->filter);
//  clean_mem(float, fdFirVars->result);
//  clean_mem(float, fdFirVars->threshold);
    clean_mem(float, fdFirVars->detection);
    clean_mem(float, fdFirVars->detLocation);
    clean_mem(float, fdFirVars->time);
    cleanup();
}

template<typename T>
void zeroData(T *dataPtr, int length, int filters) {
    int index, filter;

    for (filter = 0; filter < filters; filter++) {
        for (index = 0; index < length; index++) {
            *dataPtr = 0;
            dataPtr++;
        }
    }
}

int bit_reversed(int x, int bits) {
    int y = 0;
//  #pragma unroll 
    for (int i = 0; i < bits; i++) {
        y <<= 1;
        y |= x & 1;
        x >>= 1;
    }
    return y;
}

void sorting_descending(float *dataPtr, int length) {
    int i, j, n;
    float a;
    for (i = 0; i < length; ++i) {
        for (j = i + 1; j < length; ++j) {
            if (dataPtr[i] > dataPtr[j]) {
                a = dataPtr[i];
                dataPtr[i] = dataPtr[j];
                dataPtr[j] = a;
            }
        }
    }
}

void Print_Candidate(struct fdFirVariables *fdFirVars) {
    char detectionString[100];
    char detLocationString[100];
    sprintf(detectionString, "./test_result/%d-detection.dat", fdFirVars->dataSet);
    sprintf(detLocationString, "./test_result/%d-detLocation.dat", fdFirVars->dataSet);
    readFromFile(float, detectionString, fdFirVars->detection);
    readFromFile(int, detLocationString, fdFirVars->detLocation);
    float *detection_value = fdFirVars->detection.data;
    int *detection_locatation = fdFirVars->detLocation.data;
    int candidate_template[200];
    int candidate_freq[200];
    for (int i = 0; i < 200; i++) {
        candidate_freq[i] = (detection_locatation[i] & 0x3FFFFF);
        candidate_template[i] = (detection_locatation[i] & 0xFE000000) >> 25;
    }


//  std::sort(detection_value, detection_value+200);
//  std::sort(detection_locatation, detection_locatation+200);
    for (int i = 0; i < 200; i++) {
        if (1) {
            printf("Cand--freq = %d || temp = %d || HM=%d|| value = %.10f \n",
                   candidate_freq[i], candidate_template[i], i % 8 + 1, detection_value[i]);
        }
    }


}

void harmonicCompare(struct fdFirVariables *fdFirVars) {

    char hm_8_String[100];
    char hm_8_sw_String[100];
    sprintf(hm_8_String, "./real_data/tv_p1_234_hm8_matlab.dat");
    sprintf(hm_8_sw_String, "./real_data/tv_p1_234_hm8_sw.dat");

    readFromFile(float, hm_8_String, fdFirVars->input);
    readFromFile(float, hm_8_sw_String, fdFirVars->result);

    float *hm_8_value = fdFirVars->input.data;
    float *hm_8_sw_value = fdFirVars->result.data;
    int icount_x = 0;
/**/


    for (int i = 0; i < (FILTER_N * INPUT_SIZE); i++) {

        if (fabs(hm_8_sw_value[i] - hm_8_value[i]) > 1E-9 && (i % FILTER_N < 85)) {
//				printf("Error at Index [%2d, %3d], relative error is %.3f% \n",
//				i%FILTER_N, i/FILTER_N, fabs(hm_8_sw_value[i]-hm_8_value[i])/hm_8_value[i]*100);	
            printf("Error at Index [%2d, %3d], matlab: %.8f and FPGA:%.8f. \n",
                   i % FILTER_N, i / FILTER_N, hm_8_value[i], hm_8_sw_value[i]);
            icount_x++;
        }

    }
    if (icount_x == 0) {
        printf("--------------\n");
        printf("All differences are less then 1 x 10^-9 \n");
        printf("All Pass! \n");
        printf("--------------\n");
    } else {
        printf("Number of mismatch points: %d. \n", icount_x);
    }

    clean_mem(float, fdFirVars->result);
    clean_mem(float, fdFirVars->input);


}
