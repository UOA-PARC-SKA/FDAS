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

#include <CL/cl_ext_intelfpga.h>

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
                                  const cl_uint n_input_points) {
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
    cl_chkref(load_input_kernel.reset(new cl::Kernel(*program, "load_input", &status)));
    cl_chkref(tile_kernel.reset(new cl::Kernel(*program, "tile", &status)));
    cl_chkref(store_tiles_kernel.reset(new cl::Kernel(*program, "store_tiles", &status)));
    cl_chkref(mux_and_mult_kernel.reset(new cl::Kernel(*program, "mux_and_mult", &status)));

    fft_kernels.resize(FFT::n_engines);
    square_and_discard_kernels.resize(FFT::n_engines);
    for (int e = 0; e < FFT::n_engines; ++e) {
        auto name = "fft_" + std::to_string(e);
        cl_chkref(fft_kernels[e].reset(new cl::Kernel(*program, name.c_str(), &status)));
        name = "square_and_discard_" + std::to_string(e);
        cl_chkref(square_and_discard_kernels[e].reset(new cl::Kernel(*program, name.c_str(), &status)));
    }

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
    cl_chkref(store_cands_kernel.reset(new cl::Kernel(*program, "store_cands", &status)));

    // Buffers
    n_frequency_bins = n_input_points;
    n_tiles = n_frequency_bins / FTC::tile_payload + 1;
    padding_last_tile = FTC::tile_payload - n_frequency_bins % FTC::tile_payload;
    if (padding_last_tile == FTC::tile_payload) {
        --n_tiles;
        padding_last_tile = 0;
    }
    padded_input_sz = FTC::tile_overlap + n_frequency_bins + padding_last_tile; // NB: == (n_tiles - 1) * FDF::tile_payload + FDF::tile_sz;
    tiled_input_sz = n_tiles * FTC::tile_sz;
    templates_sz = Input::n_templates * FTC::tile_sz;
    fop_sz = Input::n_templates * n_frequency_bins;

    size_t total_allocated = 0;

    cl_chkref(input_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(cl_float2) * padded_input_sz, nullptr, &status)));
    total_allocated += input_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(tiles_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_WRITE, sizeof(cl_float2) * tiled_input_sz, nullptr, &status)));
    total_allocated += tiles_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(templates_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(cl_float2) * templates_sz, nullptr, &status)));
    total_allocated += templates_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(fop_buffer_A.reset(new cl::Buffer(*context, CL_MEM_READ_WRITE | CL_CHANNEL_2_INTELFPGA, sizeof(cl_float) * fop_sz, nullptr, &status)));
    total_allocated += fop_buffer_A->getInfo<CL_MEM_SIZE>();
    cl_chkref(fop_buffer_B.reset(new cl::Buffer(*context, CL_MEM_READ_WRITE | CL_CHANNEL_1_INTELFPGA, sizeof(cl_float) * fop_sz, nullptr, &status)));
    total_allocated += fop_buffer_B->getInfo<CL_MEM_SIZE>();

    cl_chkref(detection_location_buffer.reset(new cl::Buffer(*context, CL_MEM_WRITE_ONLY, sizeof(cl_uint) * Output::n_candidates, nullptr, &status)));
    total_allocated += detection_location_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(detection_power_buffer.reset(new cl::Buffer(*context, CL_MEM_WRITE_ONLY, sizeof(cl_float) * Output::n_candidates, nullptr, &status)));
    total_allocated += detection_power_buffer->getInfo<CL_MEM_SIZE>();

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

    if (input_shape[0] < n_frequency_bins) {
        log << "[ERROR] Not enough input points" << endl;
        return false;
    }

    if (templates_shape.size() != 2 || templates_shape[0] != Input::n_templates || templates_shape[1] != FTC::tile_sz) {
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

    cl::CommandQueue load_input_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl::CommandQueue tile_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl::CommandQueue store_tiles_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl::CommandQueue mux_and_mult_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);

    std::vector<cl::CommandQueue> fft_queues, square_and_discard_queues;
    for (int e = 0; e < FFT::n_engines; ++e) {
        cl::CommandQueue fft_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
        fft_queues.emplace_back(fft_q);
        cl::CommandQueue square_and_discard_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
        square_and_discard_queues.emplace_back(square_and_discard_q);
    }

    // Copy input to device
    cl_chk(buffer_q.enqueueWriteBuffer(*input_buffer, true, 0, sizeof(cl_float2) * n_frequency_bins, input.data())); // FIXME after merge
    cl_chk(buffer_q.enqueueWriteBuffer(*templates_buffer, true, 0, sizeof(cl_float2) * templates_sz, templates.data()));
    cl_chk(buffer_q.finish());

    cl::Event prep_start, prep_end, conv_start, conv_end;

    cl_chk(load_input_kernel->setArg<cl::Buffer>(0, *input_buffer));
    cl_chk(load_input_kernel->setArg<cl_uint>(1, n_frequency_bins / FFT::n_parallel)); // FIXME after merge

    cl_chk(tile_kernel->setArg<cl_uint>(0, n_tiles));

    cl_chk(fft_kernels[0]->setArg<cl_uint>(0, n_tiles));
    cl_chk(fft_kernels[0]->setArg<cl_uint>(1, false));

    cl_chk(store_tiles_kernel->setArg<cl::Buffer>(0, *tiles_buffer));
    cl_chk(store_tiles_kernel->setArg<cl_uint>(1, n_tiles));

    cl_chk(load_input_q.enqueueTask(*load_input_kernel, nullptr, &prep_start));
    cl_chk(tile_q.enqueueTask(*tile_kernel, nullptr, nullptr));
    cl_chk(fft_queues[0].enqueueTask(*fft_kernels[0], nullptr, nullptr));
    cl_chk(store_tiles_q.enqueueTask(*store_tiles_kernel, nullptr, &prep_end));

    load_input_q.finish();
    tile_q.finish();
    fft_queues[0].finish();
    store_tiles_q.finish();
    print_duration("Preparation", prep_start, prep_end);

    cl_chk(mux_and_mult_kernel->setArg<cl::Buffer>(0, *tiles_buffer));
    cl_chk(mux_and_mult_kernel->setArg<cl::Buffer>(1, *templates_buffer));
    cl_chk(mux_and_mult_kernel->setArg<cl_uint>(2, n_tiles));

    for (int e = 0; e < FFT::n_engines; ++e) {
        cl_chk(fft_kernels[e]->setArg<cl_uint>(0, n_tiles));
        if (e == 0)
            cl_chk(fft_kernels[e]->setArg<cl_uint>(1, true));

        cl_chk(square_and_discard_kernels[e]->setArg<cl::Buffer>(0, *fop_buffer_A));
        if (HMS::dual_channnel) {
            cl_chk(square_and_discard_kernels[e]->setArg<cl::Buffer>(3, *fop_buffer_B));
            cl_chk(square_and_discard_kernels[e]->setArg<cl_uint>(4, false));
        }
        cl_chk(square_and_discard_kernels[e]->setArg<cl_uint>(2, n_tiles));
    }

    const int first_filter = 0; // use -Input::n_filters_per_accel_sign for full FOP
    const int last_filter = Input::n_tmpl_per_accel_sign;
    for (int f = first_filter; f <= last_filter; f += FFT::n_engines) {
        int n_filters = std::min(last_filter - f + 1, (int) FFT::n_engines);
        cl_chk(mux_and_mult_kernel->setArg<cl_uint>(3 + FFT::n_engines, n_filters));
        for (int e = 0; e < FFT::n_engines; ++e) {
            cl_chk(mux_and_mult_kernel->setArg<cl_uint>(3 + e, f + e));

            cl_uint fop_offset = (f + e + Input::n_tmpl_per_accel_sign) * n_frequency_bins / FFT::n_parallel;
            cl_chk(square_and_discard_kernels[e]->setArg<cl_uint>(1, fop_offset));
        }

        cl_chk(mux_and_mult_q.enqueueTask(*mux_and_mult_kernel, nullptr, (f == first_filter ? &conv_start : nullptr)));
        for (int e = 0; e < n_filters; ++e) {
            cl_chk(fft_queues[e].enqueueTask(*fft_kernels[e], nullptr, nullptr));
            cl_chk(square_and_discard_queues[e].enqueueTask(*square_and_discard_kernels[e], nullptr, (f + e == last_filter ? &conv_end : nullptr)));
        }
    }

    mux_and_mult_q.finish();
    for (int e = 0; e < FFT::n_engines; ++e) {
        fft_queues[e].finish();
        square_and_discard_queues[e].finish();
    }

    print_duration("FT convolution and IFFT (1/2 FOP)", conv_start, conv_end);

    return true;
}

bool FDAS::perform_harmonic_summing(const FDAS::ThreshType &thresholds, const FDAS::ShapeType &thresholds_shape) {
    if (thresholds_shape.size() != 1 && thresholds_shape[0] < HMS::n_planes) {
        log << "[ERROR] Not enough threshold values given" << endl;
        return false;
    }

    const int n_planes = HMS::n_planes;
    const int n_filters = Input::n_tmpl_per_accel_sign + 1;
    const int n_filter_groups = (int) ceil(1.0 * n_filters / HMS::group_sz);
    const int n_channels = n_frequency_bins / HMS::bundle_sz / HMS::lcm * HMS::bundle_sz * HMS::lcm; // FIXME after merge
    const int n_channel_bundles = n_channels / HMS::bundle_sz;
    const bool negative_filters = false;

    log << "[INFO] HSUM: Considering " << n_channels << " channels per filter" << endl;

    cl::Event hsum_start, hsum_end;

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
            int n_rows = HMS::first_cc_to_use_last_buffer[h] > 0 ?
                    HMS::n_buffers[h] - (base_row_rem < HMS::first_cc_to_use_last_buffer[h]) :
                    n_rows = HMS::n_buffers[h];
            if (base_row + n_rows >= n_filters)
                n_rows = n_filters - base_row;

            if (HMS::dual_channnel && k == 1)
                cl_chk(preload_k.setArg<cl::Buffer>(0, *fop_buffer_B));
            else
                cl_chk(preload_k.setArg<cl::Buffer>(0, *fop_buffer_A));
            cl_chk(preload_k.setArg<cl_uint>(1, n_rows));
            cl_chk(preload_k.setArg<cl_uint>(2, base_row_rem));
            for (int r = 0; r < HMS::n_buffers[h]; ++r) {
                cl_int filter = negative_filters ? -base_row - r : base_row + r;
                cl_uint filter_offset = (filter + Input::n_tmpl_per_accel_sign) * n_frequency_bins / HMS::bundle_sz;
                cl_chk(preload_k.setArg<cl_uint>(3 + r, filter_offset));
            }
            cl_chk(preload_k.setArg<cl_uint>(3 + HMS::n_buffers[h], n_channel_bundles / k)); // important: n_channel_bundles must be divisible by all k
            cl_chk(preload_q.enqueueTask(preload_k, nullptr, (k == 1 && g == 0 ? &hsum_start : nullptr)));

            cl_chk(delay_k.setArg<cl_uint>(0, n_channel_bundles));
            cl_chk(delay_q.enqueueTask(delay_k, nullptr, nullptr));
        }

        auto &detect_k = *detect_kernels[h];
        cl_chk(detect_k.setArg<cl_float>(0, thresholds[h]));
        cl_chk(detect_k.setArg<cl_uint>(1, n_filters));
        cl_chk(detect_k.setArg<cl_uint>(2, negative_filters));
        cl_chk(detect_k.setArg<cl_uint>(3, n_filter_groups));
        cl_chk(detect_k.setArg<cl_uint>(4, n_channel_bundles));

        cl::CommandQueue detect_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
        detect_queues.emplace_back(detect_q);
        cl_chk(detect_q.enqueueTask(detect_k, nullptr, nullptr));
    }

    cl::CommandQueue store_cands_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl_chk(store_cands_kernel->setArg<cl::Buffer>(0, *detection_location_buffer));
    cl_chk(store_cands_kernel->setArg<cl::Buffer>(1, *detection_power_buffer));
    cl_chk(store_cands_q.enqueueTask(*store_cands_kernel, nullptr, &hsum_end));

    for (auto &q : preload_queues)
        cl_chk(q.finish());

    for (auto &q : delay_queues)
        cl_chk(q.finish());

    for (auto &q : detect_queues)
        cl_chk(q.finish());

    cl_chk(store_cands_q.finish());

    print_duration("Harmonic summing (1/2 FOP)", hsum_start, hsum_end);

    return true;
}

bool FDAS::retrieve_tiles(FDAS::TilesType &tiles, FDAS::ShapeType &tiles_shape) {
    tiles.resize(tiled_input_sz);

    cl::CommandQueue buffer_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl_chk(buffer_q.enqueueReadBuffer(*tiles_buffer, true, 0, sizeof(cl_float2) * tiled_input_sz, tiles.data()));
    cl_chk(buffer_q.finish());

    tiles_shape.push_back(n_tiles);
    tiles_shape.push_back(FTC::tile_sz);

    return true;
}

bool FDAS::retrieve_FOP(FDAS::FOPType &fop, FDAS::ShapeType &fop_shape) {
    fop.resize(fop_sz);

    cl::CommandQueue buffer_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl_chk(buffer_q.enqueueReadBuffer(*fop_buffer_A, true, 0, sizeof(cl_float) * fop_sz, fop.data()));
    cl_chk(buffer_q.finish());

    fop_shape.push_back(Input::n_templates);
    fop_shape.push_back(n_frequency_bins);

    return true;
}

bool FDAS::retrieve_candidates(FDAS::DetLocType &detection_location, FDAS::ShapeType &detection_location_shape,
                               FDAS::DetPwrType &detection_power, FDAS::ShapeType &detection_power_shape) {
    detection_location.resize(Output::n_candidates);
    detection_power.resize(Output::n_candidates);

    cl::CommandQueue buffer_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl_chk(buffer_q.enqueueReadBuffer(*detection_location_buffer, true, 0, sizeof(cl_uint) * Output::n_candidates, detection_location.data()));
    cl_chk(buffer_q.enqueueReadBuffer(*detection_power_buffer, true, 0, sizeof(cl_float) * Output::n_candidates, detection_power.data()));
    cl_chk(buffer_q.finish());

    detection_location_shape.push_back(Output::n_candidates);
    detection_power_shape.push_back(Output::n_candidates);

    return true;
}

bool FDAS::inject_FOP(FDAS::FOPType &fop, FDAS::ShapeType &fop_shape) {
    cl::CommandQueue buffer_q(*context, default_device, CL_QUEUE_PROFILING_ENABLE);
    cl_chk(buffer_q.enqueueWriteBuffer(*fop_buffer_A, true, 0, sizeof(cl_float) * fop_sz, fop.data()));
    if (HMS::dual_channnel)
        cl_chk(buffer_q.enqueueWriteBuffer(*fop_buffer_B, true, 0, sizeof(cl_float) * fop_sz, fop.data()));
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
