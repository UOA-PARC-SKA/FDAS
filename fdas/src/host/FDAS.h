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

#include <cmath>
#include <functional>
#include <iostream>
#include <memory>
#include <string>

#include <CL/cl.hpp>

class FDAS {
public:
    enum FOPPart {NegativeAccelerations, PositiveAccelerations, AllAccelerations};

    FDAS(std::ostream &log) : log(log) {}

    bool initialise_accelerator(std::string bitstream_file_name,
                                const std::function<bool(const std::string &, const std::string &)> &platform_selector,
                                const std::function<bool(cl_uint, cl_uint, const std::string &)> &device_selector,
                                cl_uint input_sz);

    bool upload_templates(const cl_float2 *templates);

    bool perform_input_tiling(const cl_float2 *input);

    bool perform_ft_convolution(FOPPart which);

    bool perform_harmonic_summing(const cl_float *thresholds, FOPPart which);

    bool retrieve_tiles(cl_float2 *tiles);

    bool retrieve_FOP(cl_float *fop);

    bool inject_FOP(const cl_float *fop);

    bool retrieve_candidates(cl_uint *detection_location, cl_float *detection_power);

    cl_uint get_input_sz() const;

    cl_uint get_tiles_sz() const;

    cl_uint get_templates_sz() const;

    cl_uint get_thresholds_sz() const;

    cl_uint get_fop_sz() const;

    cl_uint get_candidate_list_sz() const;

    static bool choose_first_platform(const std::string &platform_name, const std::string &platform_version) { return true; }

    static bool choose_accelerator_devices(cl_uint device_num, cl_uint device_type, const std::string &device_name) { return device_type == CL_DEVICE_TYPE_ACCELERATOR; }

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

    std::vector<std::unique_ptr<cl::Kernel>> fft_kernels;
    std::unique_ptr<cl::Kernel> load_input_kernel;
    std::unique_ptr<cl::Kernel> tile_kernel;
    std::unique_ptr<cl::Kernel> store_tiles_kernel;
    std::unique_ptr<cl::Kernel> mux_and_mult_kernel;
    std::vector<std::unique_ptr<cl::Kernel>> square_and_discard_kernels;

    std::vector<std::unique_ptr<cl::Kernel>> preload_kernels;
    std::vector<std::unique_ptr<cl::Kernel>> delay_kernels;
    std::vector<std::unique_ptr<cl::Kernel>> detect_kernels;
    std::unique_ptr<cl::Kernel> store_cands_kernel;

    std::unique_ptr<cl::Buffer> input_buffer;
    std::unique_ptr<cl::Buffer> tiles_buffer;
    std::unique_ptr<cl::Buffer> templates_buffer;
    std::unique_ptr<cl::Buffer> fop_buffer_A, fop_buffer_B;
    std::unique_ptr<cl::Buffer> detection_location_buffer;
    std::unique_ptr<cl::Buffer> detection_power_buffer;

    std::ostream &log;

    void print_duration(const std::string &phase, const cl::Event &from, const cl::Event &to);

};

#endif // FDAS_FDAS_H
