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
#include <chrono>

#include "FDAS.h"

#include <CL/cl_ext_intelfpga.h>

using std::endl;
using std::setprecision;
using std::fixed;

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
                                  const std::function<bool(cl_uint, cl_uint, const std::string &)> &device_selector,
                                  cl_uint input_sz, BufferMode mode, bool sync_pipeline) {
    cl_int status;

    // emit timestamp to be able to sync between wall-clock time and the "steady" time later
    auto system_now = std::chrono::system_clock::now();
    auto steady_now = std::chrono::steady_clock::now();
    log << "^^^," << system_now.time_since_epoch().count() << ',' << steady_now.time_since_epoch().count() << endl;

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
    for (auto i = 0; i < all_devices.size(); ++i) {
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
    for (auto i = 0; i < devices.size(); ++i)
        binaries.push_back(std::make_pair(bitstream.data(), bitstream.size()));

    cl_chkref(program.reset(new cl::Program(*context, devices, binaries, nullptr, &status)));
    cl_chk(program->build(devices));

    log << "[INFO] Program construction from '" << bitstream_file_name << "' (" << bitstream.size() << " bytes) successful" << endl;

    // free our copy of the bitstream
    bitstream.clear();
    bitstream.shrink_to_fit();

    // Kernels
    for (cl_uint e = 0; e < FFT::n_engines; ++e) {
        auto name = "fft_" + std::to_string(e);
        cl_chkref(fft_kernels[e].reset(new cl::Kernel(*program, name.c_str(), &status)));
    }
    cl_chkref(load_input_kernel.reset(new cl::Kernel(*program, "load_input", &status)));
    cl_chkref(tile_kernel.reset(new cl::Kernel(*program, "tile", &status)));
    cl_chkref(store_tiles_kernel.reset(new cl::Kernel(*program, "store_tiles", &status)));
    cl_chkref(mux_and_mult_kernel.reset(new cl::Kernel(*program, "mux_and_mult", &status)));
    for (cl_uint e = 0; e < FFT::n_engines; ++e) {
        auto name = "square_and_discard_" + std::to_string(e);
        cl_chkref(square_and_discard_kernels[e].reset(new cl::Kernel(*program, name.c_str(), &status)));
    }

    if (HMS::baseline) {
        harmonic_summing_kernel.reset(new cl::Kernel(*program, "harmonic_summing", &status));
    } else {
        for (cl_uint h = 0; h < HMS::n_planes; ++h) {
            auto name = "preload_" + std::to_string(h + 1);
            cl_chkref(preload_kernels[h].reset(new cl::Kernel(*program, name.c_str(), &status)));
        }
        for (cl_uint h = 0; h < HMS::n_planes; ++h) {
            auto name = "delay_" + std::to_string(h + 1);
            cl_chkref(delay_kernels[h].reset(new cl::Kernel(*program, name.c_str(), &status)));
        }
        for (cl_uint h = 0; h < HMS::n_planes; ++h) {
            auto name = "detect_" + std::to_string(h + 1);
            cl_chkref(detect_kernels[h].reset(new cl::Kernel(*program, name.c_str(), &status)));
        }
        cl_chkref(store_cands_kernel.reset(new cl::Kernel(*program, "store_cands", &status)));
    }

    // Buffers
    n_frequency_bins = input_sz;
    n_tiles = n_frequency_bins / FTC::tile_payload + 1;
    padding_last_tile = FTC::tile_payload - n_frequency_bins % FTC::tile_payload;
    if (padding_last_tile == FTC::tile_payload) {
        --n_tiles;
        padding_last_tile = 0;
    }
    tiles_sz = n_tiles * FTC::tile_sz;
    templates_sz = Input::n_templates * FTC::tile_sz;
    fop_sz = Input::n_templates * n_frequency_bins;

    cl_uint bank_stage1[2], bank_stage2[2];
    switch (mode) {
        case PerSet:
            bank_stage1[A] = CL_CHANNEL_1_INTELFPGA;
            bank_stage2[A] = CL_CHANNEL_1_INTELFPGA;
            bank_stage1[B] = CL_CHANNEL_2_INTELFPGA;
            bank_stage2[B] = CL_CHANNEL_2_INTELFPGA;
            break;
        case PerStage:
            bank_stage1[A] = CL_CHANNEL_1_INTELFPGA;
            bank_stage2[A] = CL_CHANNEL_2_INTELFPGA;
            bank_stage1[B] = CL_CHANNEL_1_INTELFPGA;
            bank_stage2[B] = CL_CHANNEL_2_INTELFPGA;
            break;
        case Crossed:
            bank_stage1[A] = CL_CHANNEL_1_INTELFPGA;
            bank_stage2[A] = CL_CHANNEL_2_INTELFPGA;
            bank_stage1[B] = CL_CHANNEL_2_INTELFPGA;
            bank_stage2[B] = CL_CHANNEL_1_INTELFPGA;
            break;
    }

    for (auto ab : {A, B}) {
        cl_chkref(input_buffers[ab].reset(new cl::Buffer(*context, CL_MEM_READ_ONLY | bank_stage1[ab], sizeof(cl_float2) * n_frequency_bins, nullptr, &status)));
        cl_chkref(tiles_buffers[ab].reset(new cl::Buffer(*context, CL_MEM_READ_WRITE | bank_stage1[ab], sizeof(cl_float2) * tiles_sz, nullptr, &status)));
        cl_chkref(templates_buffers[ab].reset(new cl::Buffer(*context, CL_MEM_READ_ONLY | bank_stage1[ab], sizeof(cl_float2) * templates_sz, nullptr, &status)));
        cl_chkref(fop_buffers[ab].reset(new cl::Buffer(*context, CL_MEM_READ_WRITE | bank_stage2[ab], sizeof(cl_float) * fop_sz, nullptr, &status)));
        if (HMS::baseline)
            cl_chkref(thresholds_buffers[ab].reset(new cl::Buffer(*context, CL_MEM_READ_ONLY | bank_stage2[ab], sizeof(cl_float) * HMS::n_planes, nullptr, &status)));
        cl_chkref(detection_location_buffers[ab].reset(new cl::Buffer(*context, CL_MEM_WRITE_ONLY | bank_stage2[ab], sizeof(cl_uint) * Output::n_candidates, nullptr, &status)));
        cl_chkref(detection_power_buffers[ab].reset(new cl::Buffer(*context, CL_MEM_WRITE_ONLY | bank_stage2[ab], sizeof(cl_float) * Output::n_candidates, nullptr, &status)));
    }

    // Queues
    for (auto &q : fft_queues)
        cl_chkref(q.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
    cl_chkref(load_input_queue.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
    cl_chkref(tile_queue.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
    cl_chkref(store_tiles_queue.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
    cl_chkref(mux_and_mult_queue.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
    for (auto &q : square_and_discard_queues)
        cl_chkref(q.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));

    if (HMS::baseline) {
        cl_chkref(harmonic_summing_queue.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
    } else {
        for (auto &q : preload_queues)
            cl_chkref(q.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
        for (auto &q : delay_queues)
            cl_chkref(q.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
        for (auto &q : detect_queues)
            cl_chkref(q.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
        cl_chkref(store_cands_queue.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
    }

    for (auto &q : input_buffer_queues)
        cl_chkref(q.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
    for (auto &q : tiles_buffer_queues)
        cl_chkref(q.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
    for (auto &q : templates_buffer_queues)
        cl_chkref(q.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
    for (auto &q : fop_buffer_queues)
        cl_chkref(q.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
    if (HMS::baseline) {
        for (auto &q : thresholds_buffer_queues)
            cl_chkref(q.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));
    }
    for (auto &q : detection_buffer_queues)
        cl_chkref(q.reset(new cl::CommandQueue(*context, default_device, CL_QUEUE_PROFILING_ENABLE, &status)));

    this->sync_pipeline = sync_pipeline;

    return true;
}

bool FDAS::upload_templates(const cl_float2 *templates, BufferSet ab) {
    cl_chk(templates_buffer_queues[ab]->enqueueWriteBuffer(*templates_buffers[ab], true /* blocking */, 0, sizeof(cl_float2) * templates_sz, templates));

    log << "[INFO] Uploaded template coefficients" << endl;

    return true;
}

bool FDAS::upload_thresholds(const cl_float *thresholds, BufferSet ab) {
    if (! HMS::baseline)
        return true;

    cl_chk(thresholds_buffer_queues[ab]->enqueueWriteBuffer(*thresholds_buffers[ab], true /* blocking */, 0, sizeof(cl_float) * HMS::n_planes, thresholds));

    log << "[INFO] Uploaded thresholds" << endl;

    return true;
}

bool FDAS::enqueue_input_tiling(const cl_float2 *input, BufferSet ab) {
    std::vector<cl::Event> deps;

    // Copy input to device
    xfer_input_events[ab].reset(new cl::Event);
    if (sync_pipeline && last_square_and_discard_events[1 - ab])
        deps.push_back(*last_square_and_discard_events[1 - ab]);
    cl_chk(input_buffer_queues[ab]->enqueueWriteBuffer(*input_buffers[ab], false, 0, sizeof(cl_float2) * n_frequency_bins, input, &deps, &*xfer_input_events[ab]));

    // Launch pipeline
    cl_chk(load_input_kernel->setArg<cl::Buffer>(0, *input_buffers[ab]));
    cl_chk(load_input_kernel->setArg<cl_uint>(1, n_frequency_bins / FTC::pack_sz));
    cl_chk(load_input_kernel->setArg<cl_uint>(2, padding_last_tile / FTC::pack_sz)); // TODO: should assert that padding amount is divisible by pack_sz

    deps.clear();
    deps.push_back(*xfer_input_events[ab]);
    load_input_events[ab].reset(new cl::Event);
    cl_chk(load_input_queue->enqueueTask(*load_input_kernel, &deps, &*load_input_events[ab]));

    cl_chk(tile_kernel->setArg<cl_uint>(0, n_tiles));

    cl_chk(tile_queue->enqueueTask(*tile_kernel, &deps));

    cl_chk(fft_kernels[0]->setArg<cl_uint>(0, n_tiles));
    cl_chk(fft_kernels[0]->setArg<cl_uint>(1, false));

    cl_chk(fft_queues[0]->enqueueTask(*fft_kernels[0], &deps));

    cl_chk(store_tiles_kernel->setArg<cl::Buffer>(0, *tiles_buffers[ab]));
    cl_chk(store_tiles_kernel->setArg<cl_uint>(1, n_tiles));

    store_tiles_events[ab].reset(new cl::Event);
    cl_chk(store_tiles_queue->enqueueTask(*store_tiles_kernel, &deps, &*store_tiles_events[ab]));

    return true;
}

bool FDAS::perform_input_tiling(const cl_float2 *input, BufferSet ab) {
    if (! enqueue_input_tiling(input, ab))
        return false;

    cl_chk(store_tiles_events[ab]->wait());

    print_duration("Preparation", *load_input_events[ab], *store_tiles_events[ab]);

    return true;
}

bool FDAS::enqueue_ft_convolution(FOPPart which, BufferSet ab) {
    // Determine scope
    cl_int first_template, last_template;
    switch (which) {
        case NegativeAccelerations:
            first_template = -Input::n_tmpl_per_accel_sign;
            last_template = 0;
            break;
        case PositiveAccelerations:
            first_template = 0;
            last_template = Input::n_tmpl_per_accel_sign;
            break;
        case AllAccelerations:
            first_template = -Input::n_tmpl_per_accel_sign;
            last_template = Input::n_tmpl_per_accel_sign;
            break;
    }

    std::vector<cl::Event> deps = {*store_tiles_events[ab]};

    // Distribute batches of templates to the available FFT engines
    for (cl_int t = first_template; t <= last_template; t += FFT::n_engines) {
        cl_uint n_engines_to_use = std::min(last_template - t + 1, (cl_int) FFT::n_engines);
        cl_chk(mux_and_mult_kernel->setArg<cl::Buffer>(0, *tiles_buffers[ab]));
        cl_chk(mux_and_mult_kernel->setArg<cl::Buffer>(1, *templates_buffers[ab]));
        cl_chk(mux_and_mult_kernel->setArg<cl_uint>(2, n_tiles));
        cl_chk(mux_and_mult_kernel->setArg<cl_uint>(3, n_engines_to_use));

        for (cl_uint e = 0; e < FFT::n_engines; ++e) {
            cl_uint templates_offset = (t + e + Input::n_tmpl_per_accel_sign) * FTC::tile_sz / FTC::pack_sz;
            cl_chk(mux_and_mult_kernel->setArg<cl_uint>(4 + e, templates_offset));

            cl_chk(fft_kernels[e]->setArg<cl_uint>(0, n_tiles));
            if (e == 0)
                cl_chk(fft_kernels[e]->setArg<cl_uint>(1, true)); // `fft_0` can do both directions - request iFFT here

            cl_uint fop_offset = (t + e + Input::n_tmpl_per_accel_sign) * n_frequency_bins / FTC::pack_sz;
            cl_chk(square_and_discard_kernels[e]->setArg<cl::Buffer>(0, *fop_buffers[ab]));
            cl_chk(square_and_discard_kernels[e]->setArg<cl_uint>(1, n_tiles));
            cl_chk(square_and_discard_kernels[e]->setArg<cl_uint>(2, n_frequency_bins / FTC::pack_sz));
            cl_chk(square_and_discard_kernels[e]->setArg<cl_uint>(3, fop_offset));
        }

        if (t == first_template) {
            mux_and_mult_events[ab].reset(new cl::Event);
            cl_chk(mux_and_mult_queue->enqueueTask(*mux_and_mult_kernel, &deps, &*mux_and_mult_events[ab]));
        } else {
            cl_chk(mux_and_mult_queue->enqueueTask(*mux_and_mult_kernel));
        }

        for (cl_uint e = 0; e < n_engines_to_use; ++e) {
            cl_chk(fft_queues[e]->enqueueTask(*fft_kernels[e], nullptr, nullptr));
            if (t == first_template) {
                cl_chk(square_and_discard_queues[e]->enqueueTask(*square_and_discard_kernels[e], &deps));
            } else if (t + e == last_template) {
                last_square_and_discard_events[ab].reset(new cl::Event);
                cl_chk(square_and_discard_queues[e]->enqueueTask(*square_and_discard_kernels[e], nullptr, &*last_square_and_discard_events[ab]));
            } else {
                cl_chk(square_and_discard_queues[e]->enqueueTask(*square_and_discard_kernels[e]));
            }
        }
    }

    return true;
}

bool FDAS::perform_ft_convolution(FOPPart which, BufferSet ab) {
    if (! enqueue_ft_convolution(which, ab))
        return false;

    cl_chk(last_square_and_discard_events[ab]->wait());

    print_duration("FT convolution and IFFT", *mux_and_mult_events[ab], *last_square_and_discard_events[ab]);

    return true;
}

bool FDAS::enqueue_harmonic_summing(const cl_float *thresholds, FOPPart which, BufferSet ab) {
    if (HMS::baseline)
        return enqueue_harmonic_summing_baseline(which, ab);
    else
        return enqueue_harmonic_summing_systolic(thresholds, which, ab);
}

bool FDAS::enqueue_harmonic_summing_baseline(FOPPart which, BufferSet ab) {
    cl_int first_template, last_template;
    switch (which) {
        case NegativeAccelerations:
            first_template = -Input::n_tmpl_per_accel_sign;
            last_template = 0;
            break;
        case PositiveAccelerations:
            first_template = 0;
            last_template = Input::n_tmpl_per_accel_sign;
            break;
        case AllAccelerations:
            first_template = -Input::n_tmpl_per_accel_sign;
            last_template = Input::n_tmpl_per_accel_sign;
            break;
    }

    cl_chk(harmonic_summing_kernel->setArg<cl::Buffer>(0, *fop_buffers[ab]));
    cl_chk(harmonic_summing_kernel->setArg<cl_int>(1, first_template));
    cl_chk(harmonic_summing_kernel->setArg<cl_int>(2, last_template));
    cl_chk(harmonic_summing_kernel->setArg<cl_uint>(3, n_frequency_bins));
    cl_chk(harmonic_summing_kernel->setArg<cl::Buffer>(4, *thresholds_buffers[ab]));
    cl_chk(harmonic_summing_kernel->setArg<cl::Buffer>(5, *detection_location_buffers[ab]));
    cl_chk(harmonic_summing_kernel->setArg<cl::Buffer>(6, *detection_power_buffers[ab]));

    std::vector<cl::Event> deps = {*last_square_and_discard_events[ab]};
    harmonic_summing_events[ab].reset(new cl::Event);
    cl_chk(harmonic_summing_queue->enqueueTask(*harmonic_summing_kernel, &deps, &*harmonic_summing_events[ab]));

    return true;
}

bool FDAS::enqueue_harmonic_summing_systolic(const cl_float *thresholds, FOPPart which, BufferSet ab) {
    if (which == AllAccelerations) {
        log << "[ERROR] Candidate detection on the entire FOP is not supported" << endl;
        return false;
    }

    // Derive runtime parameters
    const cl_uint n_planes = HMS::n_planes;
    const cl_uint n_templates = Input::n_tmpl_per_accel_sign + 1;
    const cl_uint n_groups = (cl_uint) ceil(1.0 * n_templates / HMS::group_sz);
    const cl_uint n_bundles = (cl_uint) ceil(1.0 * n_frequency_bins / HMS::bundle_sz);
    const bool negative_tmpls = which == NegativeAccelerations;

    std::vector<cl::Event> deps = {*last_square_and_discard_events[ab]};

    if (sync_pipeline) {
        sync_events[ab].reset(new cl::UserEvent(*context));
        deps.push_back(*sync_events[ab]);
    }

    // Orchestrate systolic array
    cl_chk(store_cands_kernel->setArg<cl::Buffer>(0, *detection_location_buffers[ab]));
    cl_chk(store_cands_kernel->setArg<cl::Buffer>(1, *detection_power_buffers[ab]));

    store_cands_events[ab].reset(new cl::Event);
    cl_chk(store_cands_queue->enqueueTask(*store_cands_kernel, &deps, &*store_cands_events[ab]));

    for (cl_uint h = 0; h < n_planes; ++h) {
        cl_uint k = h + 1;

        auto &detect_k = *detect_kernels[h];
        cl_chk(detect_k.setArg<cl_float>(0, thresholds[h]));
        cl_chk(detect_k.setArg<cl_uint>(1, n_templates));
        cl_chk(detect_k.setArg<cl_uint>(2, negative_tmpls));
        cl_chk(detect_k.setArg<cl_uint>(3, n_groups));
        cl_chk(detect_k.setArg<cl_uint>(4, n_bundles));

        cl_chk(detect_queues[h]->enqueueTask(detect_k, &deps));
    }

    for (cl_uint g = 0; g < n_groups; ++g) {
        for (cl_uint h = 0; h < n_planes; ++h) {
            cl_uint k = h + 1;

            auto &preload_k = *preload_kernels[h];
            auto &delay_k = *delay_kernels[h];

            cl_uint group_base = g * HMS::group_sz / k;
            cl_uint cc_of_group_base = g * HMS::group_sz % k;

            // determine how many buffer to use, i.e., how many rows to load from the FOP
            cl_uint n_buffers_to_use = HMS::n_buffers[h];
            if (HMS::first_cc_to_use_last_buffer[h] > 0 && cc_of_group_base < HMS::first_cc_to_use_last_buffer[h])
                --n_buffers_to_use;
            if (group_base + n_buffers_to_use >= n_templates)
                n_buffers_to_use = n_templates - group_base;

            cl_chk(preload_k.setArg<cl::Buffer>(0, *fop_buffers[ab]));
            cl_chk(preload_k.setArg<cl_uint>(1, (cl_uint) ceil(1.0 * n_bundles / k)));
            cl_chk(preload_k.setArg<cl_uint>(2, n_buffers_to_use));
            cl_chk(preload_k.setArg<cl_uint>(3, cc_of_group_base));
            for (cl_uint r = 0; r < HMS::n_buffers[h]; ++r) {
                cl_int tmpl = negative_tmpls ? -group_base - r : group_base + r;
                cl_uint fop_offset = (tmpl + Input::n_tmpl_per_accel_sign) * n_frequency_bins / HMS::bundle_sz;
                cl_chk(preload_k.setArg<cl_uint>(4 + r, fop_offset));
            }

            cl_chk(delay_k.setArg<cl_uint>(0, n_bundles));

            if (g == 0) {
                if (k == 1) {
                    first_preload_events[ab].reset(new cl::Event);
                    cl_chk(preload_queues[h]->enqueueTask(preload_k, &deps, &*first_preload_events[ab]));
                } else {
                    cl_chk(preload_queues[h]->enqueueTask(preload_k, &deps));
                }
                cl_chk(delay_queues[h]->enqueueTask(delay_k, &deps));
            } else {
                cl_chk(preload_queues[h]->enqueueTask(preload_k));
                cl_chk(delay_queues[h]->enqueueTask(delay_k));
            }
        }
    }

    return true;
}

bool FDAS::perform_harmonic_summing(const cl_float *thresholds, FOPPart which, BufferSet ab) {
    if (! enqueue_harmonic_summing(thresholds, which, ab))
        return false;

    if (HMS::baseline) {
        cl_chk(harmonic_summing_events[ab]->wait());
        print_duration("Harmonic summing (1/2 FOP)", *harmonic_summing_events[ab], *harmonic_summing_events[ab]);
    } else {
        cl_chk(store_cands_events[ab]->wait());
        print_duration("Harmonic summing (1/2 FOP)", *first_preload_events[ab], *store_cands_events[ab]);
    }

    return true;
}

bool FDAS::launch(const cl_float2 *input, const cl_float *thresholds, cl_uint *detection_location, cl_float *detection_power, FDAS::FOPPart which, FDAS::BufferSet ab) {
    if (sync_pipeline && sync_events[1-ab])
        sync_events[1-ab]->setStatus(CL_COMPLETE);

    std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();
    if (enqueue_input_tiling(input, ab)) {
        std::chrono::steady_clock::time_point s1 = std::chrono::steady_clock::now();
        if (enqueue_ft_convolution(which, ab)) {
            std::chrono::steady_clock::time_point s2 = std::chrono::steady_clock::now();
            if (enqueue_harmonic_summing(thresholds, which, ab)) {
                std::chrono::steady_clock::time_point s3 = std::chrono::steady_clock::now();
                if (enqueue_candidate_retrieval(detection_location, detection_power, ab)) {
                    std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();
                    log << "[INFO] Enqueueing: " << (ab == A ? 'A' : 'B') << "\n"
                        << "       " << std::chrono::duration_cast<std::chrono::milliseconds>(end - begin).count() << "ms\n"
                        << "       " << std::chrono::duration_cast<std::chrono::milliseconds>(s1 - begin).count() << "ms\n"
                        << "       " << std::chrono::duration_cast<std::chrono::milliseconds>(s2 - s1).count() << "ms\n"
                        << "       " << std::chrono::duration_cast<std::chrono::milliseconds>(s3 - s2).count() << "ms\n"
                        << "       " << std::chrono::duration_cast<std::chrono::milliseconds>(end - s3).count() << "ms"
                        << endl;
                    log << "%%%,"
                        << (ab == A ? 'A' : 'B') << ','
                        << begin.time_since_epoch().count() << ','
                        << s1.time_since_epoch().count() << ','
                        << s2.time_since_epoch().count() << ','
                        << s3.time_since_epoch().count() << ','
                        << end.time_since_epoch().count() << ','
                        << endl;

                    return true;
                }
            }
        }
    }
    return false;
}

bool FDAS::wait(BufferSet ab) {
    cl_chk(xfer_cands_events[ab]->wait());
    return true;
}

bool FDAS::end_pipeline(BufferSet ab) {
    if (sync_events[1 - ab])
        cl_chk(sync_events[1 - ab]->setStatus(CL_COMPLETE));
    return true;
}

bool FDAS::retrieve_tiles(cl_float2 *tiles, BufferSet ab) {
    cl_chk(tiles_buffer_queues[ab]->enqueueReadBuffer(*tiles_buffers[ab], true /* blocking */, 0, sizeof(cl_float2) * tiles_sz, tiles));
    return true;
}

bool FDAS::retrieve_FOP(cl_float *fop, BufferSet ab) {
    cl_chk(fop_buffer_queues[ab]->enqueueReadBuffer(*fop_buffers[ab], true /* blocking */, 0, sizeof(cl_float) * fop_sz, fop));
    return true;
}

bool FDAS::enqueue_candidate_retrieval(cl_uint *detection_location, cl_float *detection_power, BufferSet ab) {
    std::vector<cl::Event> deps;
    if (HMS::baseline)
        deps.push_back(*harmonic_summing_events[ab]);
    else
        deps.push_back(*store_cands_events[ab]);
    xfer_cands_events[ab].reset(new cl::Event);
    cl_chk(detection_buffer_queues[ab]->enqueueReadBuffer(*detection_location_buffers[ab], false, 0, sizeof(cl_uint) * Output::n_candidates, detection_location, &deps, nullptr));
    cl_chk(detection_buffer_queues[ab]->enqueueReadBuffer(*detection_power_buffers[ab], false, 0, sizeof(cl_float) * Output::n_candidates, detection_power, nullptr, &*xfer_cands_events[ab]));

    return true;
}

bool FDAS::retrieve_candidates(cl_uint *detection_location, cl_float *detection_power, BufferSet ab) {
    if (! enqueue_candidate_retrieval(detection_location, detection_power, ab))
        return false;

    cl_chk(xfer_cands_events[ab]->wait());

    return true;
}

bool FDAS::inject_FOP(const cl_float *fop, BufferSet ab) {
    last_square_and_discard_events[ab].reset(new cl::Event);
    cl_chk(fop_buffer_queues[ab]->enqueueWriteBuffer(*fop_buffers[ab], false, 0, sizeof(cl_float) * fop_sz, fop, nullptr, &*last_square_and_discard_events[ab]));
    return true;
}

void FDAS::print_duration(const std::string &phase, const cl::Event &from, const cl::Event &to) {
    unsigned long duration = (to.getProfilingInfo<CL_PROFILING_COMMAND_END>()
                              - from.getProfilingInfo<CL_PROFILING_COMMAND_START>()) / 1000 / 1000;
    log << "[INFO] " << phase << " duration: " << duration << " ms" << endl;
}

static long long pipeline_start, pipeline_accum;
static unsigned pipeline_launches;

void FDAS::print_stats(BufferSet ab, bool reset) {
    if (reset) {
        pipeline_start = xfer_input_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_START>();
        pipeline_accum = 0L;
        pipeline_launches = 1;
    } else {
        ++pipeline_launches;
    }

    long long acc = xfer_cands_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_END>() - pipeline_start;

    log << "[INFO] Launch  #" << pipeline_launches << (ab == A ? 'A' : 'B')
        << " complete @ " << (acc / 1000 / 1000) << " ms"
        << " II ~ " << ((acc - pipeline_accum) / 1000 / 1000) << " ms" << endl;
    print_duration("  Preparation", *load_input_events[ab], *store_tiles_events[ab]);
    print_duration("  FT convolution and IFFT (1/2 FOP)", *mux_and_mult_events[ab], *last_square_and_discard_events[ab]);
    if (HMS::baseline)
        print_duration("  Harmonic summing (1/2 FOP)", *harmonic_summing_events[ab], *harmonic_summing_events[ab]);
    else
        print_duration("  Harmonic summing (1/2 FOP)", *first_preload_events[ab], *store_cands_events[ab]);
    print_duration("  Total", *xfer_input_events[ab], *xfer_cands_events[ab]);

    pipeline_accum = acc;
}

void FDAS::print_events(BufferSet ab) {
    log << "@@@,"
        << (ab == A ? 'A' : 'B') << ','
        << xfer_input_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_START>() << ','
        << xfer_input_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_END>() << ','
        << load_input_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_START>() << ','
        << store_tiles_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_END>() << ','
        << mux_and_mult_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_START>() << ','
        << last_square_and_discard_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_END>() << ',';
    if (HMS::baseline) {
        log << harmonic_summing_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_START>() << ','
            << harmonic_summing_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_END>() << ',';
    } else {
        log << first_preload_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_START>() << ','
            << store_cands_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_END>() << ',';
    }
    log << xfer_cands_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_START>() << ','
        << xfer_cands_events[ab]->getProfilingInfo<CL_PROFILING_COMMAND_END>() << endl;
}

cl_uint FDAS::get_input_sz() const {
    return n_frequency_bins;
}

cl_uint FDAS::get_tiles_sz() const {
    return tiles_sz;
}

cl_uint FDAS::get_templates_sz() const {
    return templates_sz;
}

cl_uint FDAS::get_thresholds_sz() const {
    return HMS::n_planes;
}

cl_uint FDAS::get_fop_sz() const {
    return fop_sz;
}

cl_uint FDAS::get_candidate_list_sz() const {
    return Output::n_candidates;
}

#undef cl_chk
#undef cl_chkref
