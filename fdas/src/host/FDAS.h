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

#ifndef FDAS_FDAS_H
#define FDAS_FDAS_H

#include <array>
#include <cmath>
#include <functional>
#include <iostream>
#include <memory>
#include <string>

#include <CL/cl.hpp>

#include "gen_info.h"
using namespace GenInfo;

class FDAS {
public:
    enum FOPPart {NegativeAccelerations, PositiveAccelerations, AllAccelerations};
    enum BufferSet {A=0, B=1};
    enum BufferMode {PerSet, PerStage, Crossed};

public:
    FDAS(std::ostream &log) : log(log) {}

    bool initialise_accelerator(std::string bitstream_file_name,
                                const std::function<bool(const std::string &, const std::string &)> &platform_selector,
                                const std::function<bool(cl_uint, cl_uint, const std::string &)> &device_selector,
                                cl_uint input_sz, BufferMode mode = PerSet, bool sync_pipeline = false);

    bool upload_templates(const cl_float2 *templates, BufferSet ab);

    bool upload_thresholds(const cl_float *thresholds, BufferSet ab);

    bool perform_input_tiling(const cl_float2 *input, BufferSet ab);

    bool perform_ft_convolution(FOPPart which, BufferSet ab);

    bool perform_harmonic_summing(const cl_float *thresholds, FOPPart which, BufferSet ab);

    bool launch(const cl_float2 *input, const cl_float *thresholds, cl_uint *detection_location, cl_float *detection_power, FOPPart which, BufferSet ab);

    bool wait(BufferSet ab);

    bool end_pipeline(BufferSet ab);

    bool retrieve_tiles(cl_float2 *tiles, BufferSet ab);

    bool retrieve_FOP(cl_float *fop, BufferSet ab);

    bool inject_FOP(const cl_float *fop, BufferSet ab);

    bool retrieve_candidates(cl_uint *detection_location, cl_float *detection_power, BufferSet ab);

    void print_stats(BufferSet ab, bool reset = false);

    void print_events(BufferSet ab);

    cl_uint get_input_sz() const;

    cl_uint get_tiles_sz() const;

    cl_uint get_templates_sz() const;

    cl_uint get_thresholds_sz() const;

    cl_uint get_fop_sz() const;

    cl_uint get_candidate_list_sz() const;

    static bool choose_first_platform(const std::string &platform_name, const std::string &platform_version) { return true; }

    static bool choose_accelerator_devices(cl_uint device_num, cl_uint device_type, const std::string &device_name) { return device_type == CL_DEVICE_TYPE_ACCELERATOR; }

private:
    bool enqueue_input_tiling(const cl_float2 *input, BufferSet ab);

    bool enqueue_ft_convolution(FOPPart which, BufferSet ab);

    bool enqueue_harmonic_summing(const cl_float *thresholds, FOPPart which, BufferSet ab);

    bool enqueue_harmonic_summing_baseline(FOPPart which, BufferSet ab);

    bool enqueue_harmonic_summing_systolic(const cl_float *thresholds, FOPPart which, BufferSet ab);

    bool enqueue_candidate_retrieval(cl_uint *detection_location, cl_float *detection_power, BufferSet ab);

private:
    cl_uint n_frequency_bins;
    cl_uint n_tiles;
    cl_uint padding_last_tile;
    cl_uint tiles_sz;
    cl_uint templates_sz;
    cl_uint fop_sz;

    cl::Platform platform;
    cl::Device default_device;
    std::vector<cl::Device> devices;

    std::unique_ptr<cl::Context> context;
    std::unique_ptr<cl::Program> program;

    // FTC kernels
    std::array<std::unique_ptr<cl::Kernel>, FFT::n_engines> fft_kernels;
    std::unique_ptr<cl::Kernel> load_input_kernel;
    std::unique_ptr<cl::Kernel> tile_kernel;
    std::unique_ptr<cl::Kernel> store_tiles_kernel;
    std::unique_ptr<cl::Kernel> mux_and_mult_kernel;
    std::array<std::unique_ptr<cl::Kernel>, FFT::n_engines> square_and_discard_kernels;

    // Harmonic summing kernels
    std::unique_ptr<cl::Kernel> harmonic_summing_kernel;
    std::array<std::unique_ptr<cl::Kernel>, HMS::n_planes> preload_kernels;
    std::array<std::unique_ptr<cl::Kernel>, HMS::n_planes> delay_kernels;
    std::array<std::unique_ptr<cl::Kernel>, HMS::n_planes> detect_kernels;
    std::unique_ptr<cl::Kernel> store_cands_kernel;

    // Buffers
    std::array<std::unique_ptr<cl::Buffer>, 2> input_buffers;
    std::array<std::unique_ptr<cl::Buffer>, 2> tiles_buffers;
    std::array<std::unique_ptr<cl::Buffer>, 2> templates_buffers;
    std::array<std::unique_ptr<cl::Buffer>, 2> fop_buffers;
    std::array<std::unique_ptr<cl::Buffer>, 2> thresholds_buffers;
    std::array<std::unique_ptr<cl::Buffer>, 2> detection_location_buffers;
    std::array<std::unique_ptr<cl::Buffer>, 2> detection_power_buffers;

    // Queues for kernels
    std::array<std::unique_ptr<cl::CommandQueue>, FFT::n_engines> fft_queues;
    std::unique_ptr<cl::CommandQueue> load_input_queue;
    std::unique_ptr<cl::CommandQueue> tile_queue;
    std::unique_ptr<cl::CommandQueue> store_tiles_queue;
    std::unique_ptr<cl::CommandQueue> mux_and_mult_queue;
    std::array<std::unique_ptr<cl::CommandQueue>, FFT::n_engines> square_and_discard_queues;

    std::unique_ptr<cl::CommandQueue> harmonic_summing_queue;
    std::array<std::unique_ptr<cl::CommandQueue>, HMS::n_planes> preload_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, HMS::n_planes> delay_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, HMS::n_planes> detect_queues;
    std::unique_ptr<cl::CommandQueue> store_cands_queue;

    // Queues for buffer operations
    std::array<std::unique_ptr<cl::CommandQueue>, 2> input_buffer_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, 2> tiles_buffer_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, 2> templates_buffer_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, 2> fop_buffer_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, 2> thresholds_buffer_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, 2> detection_buffer_queues;

    // Events
    std::array<std::unique_ptr<cl::Event>, 2> xfer_input_events;
    std::array<std::unique_ptr<cl::Event>, 2> load_input_events;
    std::array<std::unique_ptr<cl::Event>, 2> store_tiles_events;
    std::array<std::unique_ptr<cl::Event>, 2> mux_and_mult_events;
    std::array<std::unique_ptr<cl::Event>, 2> last_square_and_discard_events;
    std::array<std::unique_ptr<cl::Event>, 2> harmonic_summing_events;
    std::array<std::unique_ptr<cl::Event>, 2> first_preload_events;
    std::array<std::unique_ptr<cl::Event>, 2> store_cands_events;
    std::array<std::unique_ptr<cl::Event>, 2> xfer_cands_events;

    // Synchronisation of pipeline stages
    bool sync_pipeline;
    std::array<std::unique_ptr<cl::UserEvent>, 2> sync_events;

    std::ostream &log;

    void print_duration(const std::string &phase, const cl::Event &from, const cl::Event &to);

};

#endif // FDAS_FDAS_H
