
#include <cerrno>
#include <fstream>
#include <iomanip>

#include "FDAS.h"

#include "fdas_config.h"

using std::endl;
using std::setw;
using std::setprecision;
using std::fixed;

void FDAS::print_configuration() {
#define print_config(X) log << setw(29) << #X << setw(12) << X << endl
    print_config(N_CHANNELS);
    print_config(FILTER_GROUP_SZ);
    print_config(N_FILTERS);
    print_config(N_TAPS);
    print_config(FFT_N_POINTS_LOG);
    print_config(FFT_N_POINTS);
    print_config(FFT_N_PARALLEL_LOG);
    print_config(FFT_N_PARALLEL);
    print_config(FFT_N_POINTS_PER_TERMINAL_LOG);
    print_config(FFT_N_POINTS_PER_TERMINAL);
    print_config(FFT_N_STEPS);
    print_config(FFT_LATENCY);
    print_config(FDF_TILE_SZ);
    print_config(FDF_TILE_OVERLAP);
    print_config(FDF_TILE_PAYLOAD);
    print_config(FDF_N_TILES);
    print_config(FDF_INPUT_SZ);
    print_config(FDF_PADDED_INPUT_SZ);
    print_config(FDF_INTERMEDIATE_SZ);
    print_config(FDF_OUTPUT_SZ);
    print_config(FDF_TEMPLATES_SZ);
    print_config(FDF_PRE_DISCARD_SZ);
    print_config(NDR_N_TILES_PER_WORK_GROUP);
    print_config(NDR_N_POINTS_PER_WORK_GROUP);
    print_config(NDR_N_POINTS_PER_WORK_ITEM);
    print_config(NDR_N_WORK_ITEMS_PER_TILE);
    print_config(NDR_WORK_GROUP_SZ);
    print_config(NDR_NDRANGE_SZ);
    print_config(FOP_SZ);
    print_config(HMS_N_PLANES);
    print_config(HMS_DETECTION_SZ);
    print_config(N_CANDIDATES);
#undef print_config
}

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
                                  const std::function<bool(int, int, const std::string &)> &device_selector) {
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
    cl_chkref(fwd_fetch_kernel.reset(new cl::Kernel(*program, "fwd_fetch", &status)));
    cl_chkref(fwd_fft_kernel.reset(new cl::Kernel(*program, "fwd_fft", &status)));
    cl_chkref(fwd_reversed_kernel.reset(new cl::Kernel(*program, "fwd_reversed", &status)));
    cl_chkref(fetch_kernel.reset(new cl::Kernel(*program, "fetch", &status)));
    cl_chkref(fdfir_kernel.reset(new cl::Kernel(*program, "fdfir", &status)));
    cl_chkref(reversed_kernel.reset(new cl::Kernel(*program, "reversed", &status)));
    cl_chkref(discard_kernel.reset(new cl::Kernel(*program, "discard", &status)));
    cl_chkref(harmonic_kernel.reset(new cl::Kernel(*program, "harmonic_summing", &status)));

    // Buffers
    size_t total_allocated = 0;

    cl_chkref(input_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(cl_float2) * FDF_PADDED_INPUT_SZ, nullptr, &status)));
    total_allocated += input_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(tiles_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_WRITE, sizeof(cl_float2) * FDF_INTERMEDIATE_SZ, nullptr, &status)));
    total_allocated += tiles_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(templates_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(cl_float2) * FDF_TEMPLATES_SZ, nullptr, &status)));
    total_allocated += templates_buffer->getInfo<CL_MEM_SIZE>();

    for (int i = 0; i < 2; ++i) {
        cl_chkref(discard_buffers[i].reset(new cl::Buffer(*context, CL_MEM_READ_WRITE, sizeof(cl_float) * FDF_PRE_DISCARD_SZ, nullptr, &status)));
        total_allocated += discard_buffers[i]->getInfo<CL_MEM_SIZE>();
    }

    cl_chkref(fop_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_WRITE, sizeof(cl_float) * FOP_SZ, nullptr, &status)));
    total_allocated += fop_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(detection_location_buffer.reset(new cl::Buffer(*context, CL_MEM_WRITE_ONLY, sizeof(cl_uint) * N_CANDIDATES, nullptr, &status)));
    total_allocated += detection_location_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(detection_amplitude_buffer.reset(new cl::Buffer(*context, CL_MEM_WRITE_ONLY, sizeof(cl_float) * N_CANDIDATES, nullptr, &status)));
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

    if (input_shape[0] < FDF_INPUT_SZ) {
        log << "[ERROR] Not enough input points" << endl;
        return false;
    }

    if (templates_shape.size() != 2 || templates_shape[0] != N_FILTERS || templates_shape[1] != FDF_TILE_SZ) {
        log << "[ERROR] Malformed filter templates" << endl;
        return false;
    }

    return true;
}

bool FDAS::run(const FDAS::InputType &input, const FDAS::ShapeType &input_shape,
               const FDAS::TemplatesType &templates, const FDAS::ShapeType &template_shape,
               FDAS::DetLocType &detection_location, FDAS::DetAmplType &detection_amplitude) {
    cl_int status;

    // Fail early if dimensions do not match the hardware architecture
    if (!check_dimensions(input_shape, template_shape)) {
        return false;
    }

    // Instantiate command queues, one per kernel, plus one for I/O operations. Multi-device support is NYI
    cl::CommandQueue buffer_q(*context, default_device);
    cl::CommandQueue fwd_fetch_q(*context, default_device);
    cl::CommandQueue fwd_fft_q(*context, default_device);
    cl::CommandQueue fwd_reversed_q(*context, default_device);
    cl::CommandQueue fetch_q(*context, default_device);
    cl::CommandQueue fdfir_q(*context, default_device);
    cl::CommandQueue reversed_q(*context, default_device);
    cl::CommandQueue discard_q(*context, default_device);

    // NDRange configuration
    cl::NDRange fwd_local(FFT_N_POINTS_PER_TERMINAL);
    cl::NDRange fwd_global(FFT_N_POINTS_PER_TERMINAL * FDF_N_TILES);
    cl::NDRange local(NDR_WORK_GROUP_SZ);
    cl::NDRange global(NDR_NDRANGE_SZ);

    // Set static kernel arguments
    cl_chk(fwd_fetch_kernel->setArg<cl::Buffer>(0, *input_buffer));
    cl_chk(fwd_reversed_kernel->setArg<cl::Buffer>(0, *tiles_buffer));

    cl_chk(fetch_kernel->setArg<cl::Buffer>(0, *tiles_buffer));
    cl_chk(fetch_kernel->setArg<cl::Buffer>(1, *templates_buffer));

    cl_chk(fdfir_kernel->setArg<cl_int>(0, /* inverse FFT */ 1));

    cl_chk(reversed_kernel->setArg<cl::Buffer>(0, *discard_buffers[0]));
    cl_chk(reversed_kernel->setArg<cl::Buffer>(1, *discard_buffers[1]));

    cl_chk(discard_kernel->setArg<cl::Buffer>(0, *discard_buffers[0]));
    cl_chk(discard_kernel->setArg<cl::Buffer>(1, *discard_buffers[1]));
    cl_chk(discard_kernel->setArg<cl::Buffer>(2, *fop_buffer));

    // Copy input to device
    cl_float2 zeros[FDF_TILE_OVERLAP];
    memset(zeros, 0x0, sizeof(cl_float2) * FDF_TILE_OVERLAP);
    cl_chk(buffer_q.enqueueWriteBuffer(*input_buffer, true, 0, sizeof(cl_float2) * FDF_TILE_OVERLAP, zeros));
    cl_chk(buffer_q.enqueueWriteBuffer(*input_buffer, true, sizeof(cl_float2) * FDF_TILE_OVERLAP, sizeof(cl_float2) * FDF_INPUT_SZ, input.data()));
    cl_chk(buffer_q.enqueueWriteBuffer(*templates_buffer, true, 0, sizeof(cl_float2) * (FDF_TEMPLATES_SZ - FDF_TILE_SZ), templates.data()));
    cl_chk(buffer_q.finish());

    // Perform forward FT
    cl::Event fwd_fetch_ev, fwd_fft_ev, fwd_reversed_ev;
    cl_chk(fwd_fetch_q.enqueueNDRangeKernel(*fwd_fetch_kernel, cl::NullRange, fwd_global, fwd_local, nullptr, &fwd_fetch_ev));
    cl_chk(fwd_fft_q.enqueueTask(*fwd_fft_kernel, nullptr, &fwd_fft_ev));
    cl_chk(fwd_reversed_q.enqueueNDRangeKernel(*fwd_reversed_kernel, cl::NullRange, fwd_global, fwd_local, nullptr, &fwd_reversed_ev));

    cl_chk(fwd_fetch_q.finish());
    cl_chk(fwd_fft_q.finish());
    cl_chk(fwd_reversed_q.finish());

    unsigned long fwd_duraration_Ms = (fwd_reversed_ev.getProfilingInfo<CL_PROFILING_COMMAND_END>()
                                       - fwd_fetch_ev.getProfilingInfo<CL_PROFILING_COMMAND_START>()) / 1000 / 1000;
    log << "[INFO] Forward FFT took " << fwd_duraration_Ms << " ms" << endl;

    // Enqueue *all* FDFIR kernels at once; the channels will ensure that the data dependencies are respected
    cl::Event fetch_evs[FILTER_GROUP_SZ + 1];
    cl::Event fdfir_evs[FILTER_GROUP_SZ + 1];
    cl::Event reversed_evs[FILTER_GROUP_SZ + 1];
    for (int i = 0; i < FILTER_GROUP_SZ + 1; ++i) {
        int tmpl_idx_0 = i;
        int tmpl_idx_1 = i + FILTER_GROUP_SZ + 1;
        cl_chk(fetch_kernel->setArg<cl_int>(2, tmpl_idx_0));
        cl_chk(fetch_kernel->setArg<cl_int>(3, tmpl_idx_1));
        cl_chk(fetch_q.enqueueNDRangeKernel(*fetch_kernel, cl::NullRange, global, local, nullptr, &fetch_evs[i]));

        cl_chk(fdfir_q.enqueueTask(*fdfir_kernel, nullptr, &fdfir_evs[i]));

        cl_chk(reversed_kernel->setArg<cl_int>(2, i));
        cl_chk(reversed_kernel->setArg<cl_int>(3, i)); // not a typo, the two streams are written to two separate buffers (using the same offsets)
        cl_chk(reversed_q.enqueueNDRangeKernel(*reversed_kernel, cl::NullRange, global, local, nullptr, &reversed_evs[i]));
    }

    // Wait for the FDFIR part of the pipeline to finish
    cl_chk(fetch_q.finish());
    cl_chk(fdfir_q.finish());
    cl_chk(reversed_q.finish());

    unsigned long fdfir_duration_ms = (reversed_evs[FILTER_GROUP_SZ].getProfilingInfo<CL_PROFILING_COMMAND_END>()
                                       - fetch_evs[0].getProfilingInfo<CL_PROFILING_COMMAND_START>()) / 1000 / 1000;
    log << "[INFO] FDFIR took " << fdfir_duration_ms << " ms" << endl;

    cl::Event discard_ev;
    cl_chk(discard_q.enqueueTask(*discard_kernel, nullptr, &discard_ev));
    cl_chk(discard_q.finish());

    unsigned long discard_duration_ms = (discard_ev.getProfilingInfo<CL_PROFILING_COMMAND_END>()
                                         - discard_ev.getProfilingInfo<CL_PROFILING_COMMAND_START>()) / 1000 / 1000;
    log << "[INFO] Discard took " << discard_duration_ms << " ms" << endl;

    log << "[INFO] Harmonic summing NYI" << endl;

    return true;
}

bool FDAS::retrieve_tiles(FDAS::TilesType &tiles, FDAS::ShapeType &tiles_shape) {
    cl_int status;

    tiles.reserve(FDF_INTERMEDIATE_SZ);
    cl::CommandQueue buffer_q(*context, default_device);
    cl_chk(buffer_q.enqueueReadBuffer(*tiles_buffer, true, 0, sizeof(cl_float2) * FDF_INTERMEDIATE_SZ, tiles.data()));
    cl_chk(buffer_q.finish());
    tiles_shape.push_back(FDF_N_TILES);
    tiles_shape.push_back(FDF_TILE_SZ);

    return true;
}

bool FDAS::retrieveFOP(FDAS::FOPType &fop, FDAS::ShapeType &fop_shape) {
    cl_int status;

    fop.reserve(FOP_SZ);
    cl::CommandQueue buffer_q(*context, default_device);
    cl_chk(buffer_q.enqueueReadBuffer(*fop_buffer, true, 0, sizeof(cl_float) * FOP_SZ, fop.data()));
    cl_chk(buffer_q.finish());
    fop_shape.push_back(N_FILTERS);
    fop_shape.push_back(FDF_OUTPUT_SZ);

    return true;
}

#undef cl_chk
#undef cl_chkref
