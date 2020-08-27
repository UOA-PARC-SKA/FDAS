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

#include <cerrno>
#include <fstream>
#include <iomanip>

#include "FDAS.h"
#include "gen_info.h"

using std::endl;
using std::setprecision;
using std::fixed;

using namespace GenInfo;

#define cl_chk(cmd) \
    do { \
        cl_int status = cmd; \
        if (status != CL_SUCCESS) { \
            log << "[ERROR] OpenCL command failed with status " << status << ":\n" \
                << "          " #cmd " [" __FILE__ ":" << __LINE__ << "]" << endl; \
            return false; \
        } \
    } while (0)

#define cl_chkref(cmd) \
    do { \
        cmd; \
        if (status != CL_SUCCESS) { \
            log << "[ERROR] OpenCL command failed with status " << status << ":\n" \
                << "          " #cmd " [" __FILE__ ":" << __LINE__ << "]" << endl; \
            return false; \
        } \
    } while (0)

bool FDAS::initialise_accelerator(std::string bitstream_file_name,
                                  const std::function<bool(const std::string &, const std::string &)> &platform_selector,
                                  const std::function<bool(int, int, const std::string &)> &device_selector,
                                  const cl_uint n_input_channels) {
    cl_int status;

    std::vector<cl::Platform> all_platforms;
    cl_chk(cl::Platform::get(&all_platforms));
    if (all_platforms.empty()) {
        log << "[ERROR] No OpenCL platforms found" << endl;
        return false;
    }

    bool platform_found = false;
    for (auto p : all_platforms) {
        auto pn = p.getInfo<CL_PLATFORM_NAME>();
        auto pv = p.getInfo<CL_PLATFORM_VERSION>();
        if (platform_selector(pn, pv)) {
            platform = p;
            platform_found = true;
            log << "[INFO] Platform: " << pn << endl;
            log << "[INFO] Version : " << pv << endl;
            break;
        }
    }
    if (!platform_found) {
        log << "[ERROR] No suitable OpenCL platform found" << endl;
        return false;
    }

    std::vector<cl::Device> all_devices;
    cl_chk(platform.getDevices(CL_DEVICE_TYPE_ALL, &all_devices));
    if (all_devices.empty()) {
        log << "[ERROR] No OpenCL devices found" << endl;
        return false;
    }

    devices.clear();
    for (int i = 0; i < all_devices.size(); ++i) {
        auto d = all_devices[i];
        auto dt = d.getInfo<CL_DEVICE_TYPE>();
        auto dn = d.getInfo<CL_DEVICE_NAME>();
        if (device_selector(i, dt, dn)) {
            if (devices.empty())
                default_device = d;
            log << "[INFO] Device[" << i << "]: " << dn << (devices.empty() ? " (default)" : "") << endl;
            devices.push_back(d);
        }
    }
    if (devices.empty()) {
        log << "[ERROR] No suitable OpenCL device found" << endl;
        return false;
    }
    if (devices.size() > 1) {
        log << "[WARN] Multi-device support not yet implemented, truncating device list to contain only the default device" << endl;
        devices.resize(1);
    }

    std::vector<char> bitstream;
    std::ifstream bitstream_file(bitstream_file_name, std::ios::ate | std::ios::binary);
    if (bitstream_file.good()) {
        bitstream.reserve(bitstream_file.tellg());
        bitstream_file.seekg(0);
        bitstream.assign(std::istreambuf_iterator<char>(bitstream_file), std::istreambuf_iterator<char>());
        bitstream_file.close();
    } else {
        log << "[ERROR] Could not read bitstream file '" << bitstream_file_name << "': " << strerror(errno) << endl;
        return false;
    }

    context.reset(new cl::Context(devices));

    cl::Program::Binaries binaries;
    for (int i = 0; i < devices.size(); ++i)
        binaries.push_back(std::make_pair(bitstream.data(), bitstream.size()));

    cl_chkref(program.reset(new cl::Program(*context, devices, binaries, nullptr, &status)));
    cl_chk(program->build(devices));

    log << "[INFO] Program construction from '" << bitstream_file_name << "' (" << bitstream.size() << " bytes) successful" << endl;

    // free our copy of the bitstream
    bitstream.clear();
    bitstream.shrink_to_fit();

    // Kernels
    fft_kernels.resize(FDF::group_sz);
    for (int i = 0; i < FDF::group_sz; ++i) {
        auto name = "fft_" + std::to_string(i);
        cl_chkref(fft_kernels[i].reset(new cl::Kernel(*program, name.c_str(), &status)));
    }
    cl_chkref(load_input_kernel.reset(new cl::Kernel(*program, "load_input", &status)));
    cl_chkref(tile_kernel.reset(new cl::Kernel(*program, "tile", &status)));
    cl_chkref(store_tiles_kernel.reset(new cl::Kernel(*program, "store_tiles", &status)));
    cl_chkref(mux_and_mult_kernel.reset(new cl::Kernel(*program, "mux_and_mult", &status)));
    cl_chkref(square_and_discard_kernel.reset(new cl::Kernel(*program, "square_and_discard", &status)));

    preload_kernels.resize(HMS::n_planes);
    delay_kernels.resize(HMS::n_planes);
    detect_kernels.resize(HMS::n_planes);
    for (int h = 0; h < HMS::n_planes; ++h) {
        auto name = "preload_" + std::to_string(h + 1);
        cl_chkref(preload_kernels[h].reset(new cl::Kernel(*program, name.c_str(), &status)));
        name = "delay_" + std::to_string(h + 1);
        cl_chkref(delay_kernels[h].reset(new cl::Kernel(*program, name.c_str(), &status)));
        name = "detect_" + std::to_string(h + 1);
        cl_chkref(detect_kernels[h].reset(new cl::Kernel(*program, name.c_str(), &status)));
    }

    // Buffers
    n_tiles = n_input_channels / FDF::tile_payload;
    input_sz = n_tiles * FDF::tile_payload;
    tiled_input_sz = n_tiles * FDF::tile_sz;
    templates_sz = Input::n_filters * FDF::tile_sz;
    fop_row_sz = input_sz;
    fop_sz = Input::n_filters * fop_row_sz;

    size_t total_allocated = 0;

    cl_chkref(input_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(cl_float2) * input_sz, nullptr, &status)));
    total_allocated += input_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(tiles_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_WRITE, sizeof(cl_float2) * tiled_input_sz, nullptr, &status)));
    total_allocated += tiles_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(templates_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(cl_float2) * templates_sz, nullptr, &status)));
    total_allocated += templates_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(fop_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_WRITE, sizeof(cl_float) * fop_sz, nullptr, &status)));
    total_allocated += fop_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(detection_location_buffer.reset(new cl::Buffer(*context, CL_MEM_WRITE_ONLY, sizeof(cl_uint) * Output::n_candidates, nullptr, &status)));
    total_allocated += detection_location_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(detection_amplitude_buffer.reset(new cl::Buffer(*context, CL_MEM_WRITE_ONLY, sizeof(cl_float) * Output::n_candidates, nullptr, &status)));
    total_allocated += detection_amplitude_buffer->getInfo<CL_MEM_SIZE>();

    log << "[INFO] Allocated "
        << fixed << setprecision(2) << (total_allocated / (1.f * (1 << 20)))
        << " MB for buffers in total ("
        << setprecision(2) << (100.f * total_allocated / default_device.getInfo<CL_DEVICE_GLOBAL_MEM_SIZE>())
        << " %)" << endl;

    return true;
}

bool FDAS::check_dimensions(const FDAS::ShapeType &input_shape, const FDAS::ShapeType &templates_shape) {
    if (input_shape.size() != 1) {
        log << "[ERROR] Malformed input" << endl;
        return false;
    }

    if (input_shape[0] < input_sz) {
        log << "[ERROR] Not enough input points" << endl;
        return false;
    }

    if (templates_shape.size() != 2 || templates_shape[0] != Input::n_filters || templates_shape[1] != FDF::tile_sz) {
        log << "[ERROR] Malformed filter templates" << endl;
        return false;
    }

    return true;
}

bool FDAS::perform_ft_convolution(const FDAS::InputType &input, const FDAS::ShapeType &input_shape,
                                  const FDAS::TemplatesType &templates, const FDAS::ShapeType &templates_shape) {
    // Fail early if dimensions do not match the hardware architecture
    if (!check_dimensions(input_shape, templates_shape)) {
        return false;
    }

    // Instantiate command queues, one per kernel, plus one for I/O operations. Multi-device support is NYI
    cl::CommandQueue buffer_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);

    std::vector<cl::CommandQueue> fft_queues;
    for (int i = 0; i < FDF::group_sz; ++i) {
        cl::CommandQueue fft_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
        fft_queues.emplace_back(fft_q);
    }

    cl::CommandQueue load_input_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl::CommandQueue tile_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl::CommandQueue store_tiles_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl::CommandQueue mux_and_mult_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl::CommandQueue square_and_discard_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);

    // NDRange configuration
    cl::NDRange prep_local(FFT::n_points_per_terminal);
    cl::NDRange prep_global(FFT::n_points_per_terminal * n_tiles);

    cl::NDRange conv_local(FFT::n_points_per_terminal, 1);
    cl::NDRange conv_global(FFT::n_points_per_terminal * n_tiles, Input::n_filters / FDF::group_sz);

    // Set static kernel arguments
    cl_chk(load_input_kernel->setArg<cl::Buffer>(0, *input_buffer));
    cl_chk(load_input_kernel->setArg<cl_uint>(1, input_sz));
    cl_chk(tile_kernel->setArg<cl_uint>(0, n_tiles));
    cl_chk(store_tiles_kernel->setArg<cl::Buffer>(0, *tiles_buffer));
    cl_chk(mux_and_mult_kernel->setArg<cl::Buffer>(0, *tiles_buffer));
    cl_chk(mux_and_mult_kernel->setArg<cl::Buffer>(1, *templates_buffer));
    cl_chk(square_and_discard_kernel->setArg<cl::Buffer>(0, *fop_buffer));
    cl_chk(square_and_discard_kernel->setArg<cl_uint>(1, fop_row_sz));


    // Copy input to device
    cl_chk(buffer_q.enqueueWriteBuffer(*input_buffer, true, 0, sizeof(cl_float2) * input_sz, input.data()));
    cl_chk(buffer_q.enqueueWriteBuffer(*templates_buffer, true, 0, sizeof(cl_float2) * templates_sz, templates.data()));
    cl_chk(buffer_q.finish());

    cl::Event load_input_ev, tile_ev, store_tiles_ev, mux_and_mult_ev, square_and_discard_ev;
    cl::Event fft_evs[FDF::group_sz];

    cl_chk(load_input_q.enqueueTask(*load_input_kernel, nullptr, &load_input_ev));
    cl_chk(tile_q.enqueueTask(*tile_kernel, nullptr, &tile_ev));

    auto& fwd_fft_k = *fft_kernels[0];
    auto& fwd_fft_q = fft_queues[0];
    cl_chk(fwd_fft_k.setArg<cl_uint>(0, n_tiles));
    cl_chk(fwd_fft_k.setArg<cl_uint>(1, false));
    cl_chk(fwd_fft_q.enqueueTask(fwd_fft_k, nullptr, &fft_evs[0]));

    cl_chk(store_tiles_q.enqueueNDRangeKernel(*store_tiles_kernel, cl::NullRange, prep_global, prep_local, nullptr, &store_tiles_ev));

    load_input_q.finish();
    tile_q.finish();
    fwd_fft_q.finish();
    store_tiles_q.finish();
    print_duration("Preparation", load_input_ev, store_tiles_ev);

    cl_chk(mux_and_mult_q.enqueueNDRangeKernel(*mux_and_mult_kernel, cl::NullRange, conv_global, conv_local, nullptr, &mux_and_mult_ev));

    fwd_fft_k.setArg<cl_uint>(1, true);
    for (int i = 0; i < FDF::group_sz; ++i) {
        cl_chk(fft_kernels[i]->setArg<cl_uint>(0, Input::n_filters / FDF::group_sz * n_tiles));
        fft_queues[i].enqueueTask(*fft_kernels[i], nullptr, &fft_evs[i]);
    }

    cl_chk(square_and_discard_q.enqueueNDRangeKernel(*square_and_discard_kernel, cl::NullRange, conv_global, conv_local, nullptr, &square_and_discard_ev));

    mux_and_mult_q.finish();
    for (int i = 0; i < FDF::group_sz; ++i)
        fft_queues[i].finish();
    square_and_discard_q.finish();

    print_duration("FT convolution and IFFT", mux_and_mult_ev, square_and_discard_ev);

    return true;
}

bool FDAS::perform_harmonic_summing(const FDAS::ThreshType &thresholds, const FDAS::ShapeType &thresholds_shape) {
    if (thresholds_shape.size() != 1 && thresholds_shape[0] < HMS::n_planes) {
        log << "[ERROR] Not enough threshold values given" << endl;
        return false;
    }

    const int n_planes = HMS::n_planes;
    const int n_filters = Input::n_filters_per_accel_sign + 1;
    const int n_filter_groups = (int) ceil(1.0 * n_filters / HMS::group_sz);
    const int n_channels = fop_row_sz / HMS::bundle_sz / HMS::lcm * HMS::bundle_sz * HMS::lcm;
    const int n_channel_bundles = n_channels / HMS::bundle_sz;
    const bool negative_filters = false;

    log << "[INFO] HSUM: Considering " << n_channels << " channels per filter" << endl;

    cl::Event preload_evs[n_planes][n_filter_groups];
    cl::Event delay_evs[n_planes][n_filter_groups];
    cl::Event detect_evs[n_planes];

    std::vector<cl::CommandQueue> preload_queues, delay_queues, detect_queues;

    for (int h = 0; h < n_planes; ++h) {
        auto k = h + 1;

        cl::CommandQueue preload_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
        cl::CommandQueue delay_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
        preload_queues.emplace_back(preload_q);
        delay_queues.emplace_back(delay_q);

        auto &preload_k = *preload_kernels[h];
        auto &delay_k = *delay_kernels[h];

        for (int g = 0; g < n_filter_groups; ++g) {
            int base_row = g * HMS::group_sz / k;
            int base_row_rem = g * HMS::group_sz % k;
            int n_rows = HMS::first_offset_to_use_last_buffer[h] > 0 ?
                    HMS::n_buffers[h] - (base_row_rem < HMS::first_offset_to_use_last_buffer[h]) :
                    n_rows = HMS::n_buffers[h];
            if (base_row + n_rows >= n_filters)
                n_rows = n_filters - base_row;

            cl_chk(preload_k.setArg<cl::Buffer>(0, *fop_buffer));
            cl_chk(preload_k.setArg<cl_uint>(1, n_rows));
            cl_chk(preload_k.setArg<cl_uint>(2, base_row_rem));
            for (int r = 0; r < HMS::n_buffers[h]; ++r) {
                cl_int filter = negative_filters ? -base_row - r : base_row + r;
                cl_uint filter_offset = (filter + Input::n_filters_per_accel_sign) * fop_row_sz / HMS::bundle_sz;
                cl_chk(preload_k.setArg<cl_uint>(3 + r, filter_offset));
            }
            cl_chk(preload_k.setArg<cl_uint>(3 + HMS::n_buffers[h], n_channel_bundles / k)); // important: n_channel_bundles must be divisible by all k
            cl_chk(preload_q.enqueueTask(preload_k, nullptr, &preload_evs[h][g]));

            cl_chk(delay_k.setArg<cl_uint>(0, n_channel_bundles));
            cl_chk(delay_q.enqueueTask(delay_k, nullptr, &delay_evs[h][g]));
        }

        auto &detect_k = *detect_kernels[h];
        cl_chk(detect_k.setArg<cl::Buffer>(0, *detection_location_buffer));
        cl_chk(detect_k.setArg<cl::Buffer>(1, *detection_amplitude_buffer));
        cl_chk(detect_k.setArg<cl_float>(2, thresholds[h]));
        cl_chk(detect_k.setArg<cl_uint>(3, n_filters));
        cl_chk(detect_k.setArg<cl_uint>(4, negative_filters));
        cl_chk(detect_k.setArg<cl_uint>(5, n_filter_groups));
        cl_chk(detect_k.setArg<cl_uint>(6, n_channel_bundles));

        cl::CommandQueue detect_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
        detect_queues.emplace_back(detect_q);
        cl_chk(detect_q.enqueueTask(detect_k, nullptr, &detect_evs[h]));
    }

    for (auto &q : preload_queues)
        cl_chk(q.finish());

    for (auto &q : delay_queues)
        cl_chk(q.finish());

    for (auto &q : detect_queues)
        cl_chk(q.finish());

    print_duration("Harmonic summing (1/2 FOP)", preload_evs[0][0], detect_evs[n_planes - 1]);

    return true;
}

bool FDAS::retrieve_tiles(FDAS::TilesType &tiles, FDAS::ShapeType &tiles_shape) {
    tiles.resize(tiled_input_sz);
    cl::CommandQueue buffer_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl_chk(buffer_q.enqueueReadBuffer(*tiles_buffer, true, 0, sizeof(cl_float2) * tiled_input_sz, tiles.data()));
    cl_chk(buffer_q.finish());
    tiles_shape.push_back(n_tiles);
    tiles_shape.push_back(FDF::tile_sz);

    return true;
}

bool FDAS::retrieve_FOP(FDAS::FOPType &fop, FDAS::ShapeType &fop_shape) {
    fop.resize(fop_sz);
    cl::CommandQueue buffer_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl_chk(buffer_q.enqueueReadBuffer(*fop_buffer, true, 0, sizeof(cl_float) * fop_sz, fop.data()));
    cl_chk(buffer_q.finish());
    fop_shape.push_back(Input::n_filters);
    fop_shape.push_back(fop_row_sz);

    return true;
}

bool FDAS::retrieve_candidates(FDAS::DetLocType &detection_location, FDAS::ShapeType &detection_location_shape,
                               FDAS::DetAmplType &detection_amplitude, FDAS::ShapeType &detection_amplitude_shape) {
    detection_location.resize(Output::n_candidates);
    detection_amplitude.resize(Output::n_candidates);

    cl::CommandQueue buffer_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl_chk(buffer_q.enqueueReadBuffer(*detection_location_buffer, true, 0, sizeof(cl_uint) * Output::n_candidates, detection_location.data()));
    cl_chk(buffer_q.enqueueReadBuffer(*detection_amplitude_buffer, true, 0, sizeof(cl_float) * Output::n_candidates, detection_amplitude.data()));
    cl_chk(buffer_q.finish());

    detection_location_shape.push_back(Output::n_candidates);
    detection_amplitude_shape.push_back(Output::n_candidates);

    return true;
}

bool FDAS::inject_FOP(FDAS::FOPType &fop, FDAS::ShapeType &fop_shape) {
    cl::CommandQueue buffer_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl_chk(buffer_q.enqueueWriteBuffer(*fop_buffer, true, 0, sizeof(cl_float) * fop_sz, fop.data()));
    cl_chk(buffer_q.finish());

    return true;
}

void FDAS::print_duration(const std::string &phase, const cl::Event &from, const cl::Event &to) {
    unsigned long duration = (to.getProfilingInfo<CL_PROFILING_COMMAND_END>()
                              - from.getProfilingInfo<CL_PROFILING_COMMAND_START>()) / 1000 / 1000;
    log << "[INFO] " << phase << " duration: " << duration << " ms" << endl;
}

#undef cl_chk
#undef cl_chkref
