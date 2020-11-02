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

public:
    FDAS(std::ostream &log) : log(log) {}

    bool initialise_accelerator(std::string bitstream_file_name,
                                const std::function<bool(const std::string &, const std::string &)> &platform_selector,
                                const std::function<bool(cl_uint, cl_uint, const std::string &)> &device_selector,
                                cl_uint input_sz);

    bool upload_templates(const cl_float2 *templates, BufferSet ab = A);

    bool perform_input_tiling(const cl_float2 *input, BufferSet ab = A);

    bool perform_ft_convolution(FOPPart which, BufferSet ab = A);

    bool perform_harmonic_summing(const cl_float *thresholds, FOPPart which, BufferSet ab = A);

    bool launch(const cl_float2 *input, const cl_float *thresholds, FOPPart which, BufferSet ab = A);

    bool retrieve_tiles(cl_float2 *tiles, BufferSet ab = A);

    bool retrieve_FOP(cl_float *fop, BufferSet ab = A);

    bool inject_FOP(const cl_float *fop, BufferSet ab = A);

    bool retrieve_candidates(cl_uint *detection_location, cl_float *detection_power, BufferSet ab = A);

    void print_stats(BufferSet ab = A, bool reset = false);

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

    bool enqueue_harmonic_summing(const cl_float *thresholds, FOPPart which, BufferSet);

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
    std::array<std::unique_ptr<cl::Kernel>, HMS::n_planes> preload_kernels;
    std::array<std::unique_ptr<cl::Kernel>, HMS::n_planes> delay_kernels;
    std::array<std::unique_ptr<cl::Kernel>, HMS::n_planes> detect_kernels;
    std::unique_ptr<cl::Kernel> store_cands_kernel;

    // Buffers
    std::array<std::unique_ptr<cl::Buffer>, 2> input_buffers;
    std::array<std::unique_ptr<cl::Buffer>, 2> tiles_buffers;
    std::array<std::unique_ptr<cl::Buffer>, 2> templates_buffers;
    std::array<std::unique_ptr<cl::Buffer>, 2> fop_buffers;
    std::array<std::unique_ptr<cl::Buffer>, 2> detection_location_buffers;
    std::array<std::unique_ptr<cl::Buffer>, 2> detection_power_buffers;

    // Queues for kernels
    std::array<std::unique_ptr<cl::CommandQueue>, FFT::n_engines> fft_queues;
    std::unique_ptr<cl::CommandQueue> load_input_queue;
    std::unique_ptr<cl::CommandQueue> tile_queue;
    std::unique_ptr<cl::CommandQueue> store_tiles_queue;
    std::unique_ptr<cl::CommandQueue> mux_and_mult_queue;
    std::array<std::unique_ptr<cl::CommandQueue>, FFT::n_engines> square_and_discard_queues;

    std::array<std::unique_ptr<cl::CommandQueue>, HMS::n_planes> preload_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, HMS::n_planes> delay_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, HMS::n_planes> detect_queues;
    std::unique_ptr<cl::CommandQueue> store_cands_queue;

    // Queues for buffer operations
    std::array<std::unique_ptr<cl::CommandQueue>, 2> input_buffer_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, 2> tiles_buffer_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, 2> templates_buffer_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, 2> fop_buffer_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, 2> detection_location_buffer_queues;
    std::array<std::unique_ptr<cl::CommandQueue>, 2> detection_power_buffer_queues;

    // Events
    std::array<std::unique_ptr<cl::Event>, 2> xfer_input_events;
    std::array<std::unique_ptr<cl::Event>, 2> load_input_events;
    std::array<std::unique_ptr<cl::Event>, 2> store_tiles_events;
    std::array<std::unique_ptr<cl::Event>, 2> mux_and_mult_events;
    std::array<std::unique_ptr<cl::Event>, 2> last_square_and_discard_events;
    std::array<std::unique_ptr<cl::Event>, 2> first_preload_events;
    std::array<std::unique_ptr<cl::Event>, 2> store_cands_events;
    std::array<std::unique_ptr<cl::Event>, 2> xfer_det_locs_events;
    std::array<std::unique_ptr<cl::Event>, 2> xfer_det_pwrs_events;

    std::ostream &log;

    void print_duration(const std::string &phase, const cl::Event &from, const cl::Event &to);

};

#endif // FDAS_FDAS_H
