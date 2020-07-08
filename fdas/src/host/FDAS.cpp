
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
    print_config(N_FILTERS_PER_ACCEL_SIGN);
    print_config(N_FILTERS);
    print_config(N_TAPS);
    print_config(N_FILTERS_PARALLEL);
    print_config(N_FILTER_BATCHES);
    print_config(FFT_N_POINTS_LOG);
    print_config(FFT_N_POINTS);
    print_config(FFT_N_PARALLEL_LOG);
    print_config(FFT_N_PARALLEL);
    print_config(FFT_N_POINTS_PER_TERMINAL_LOG);
    print_config(FFT_N_POINTS_PER_TERMINAL);
    print_config(FDF_TILE_SZ);
    print_config(FDF_TILE_OVERLAP);
    print_config(FDF_TILE_PAYLOAD);
    print_config(FDF_N_TILES);
    print_config(FDF_INPUT_SZ);
    print_config(FDF_PADDED_INPUT_SZ);
    print_config(FDF_TILED_INPUT_SZ);
    print_config(FDF_OUTPUT_SZ);
    print_config(FDF_TEMPLATES_SZ);
    print_config(FOP_SZ);
    print_config(HMS_N_PLANES);
    print_config(HMS_DETECTION_SZ);
    print_config(HMS_STORE_PLANES);
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
    cl_chkref(tile_input_kernel.reset(new cl::Kernel(*program, "tile_input", &status)));
    cl_chkref(store_tiles_kernel.reset(new cl::Kernel(*program, "store_tiles", &status)));
    cl_chkref(mux_and_mult_kernel.reset(new cl::Kernel(*program, "mux_and_mult", &status)));
    cl_chkref(square_and_discard_kernel.reset(new cl::Kernel(*program, "square_and_discard", &status)));
    cl_chkref(harmonic_summing_kernel.reset(new cl::Kernel(*program, "harmonic_summing", &status)));

    // Buffers
    size_t total_allocated = 0;

    cl_chkref(input_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(cl_float2) * FDF_PADDED_INPUT_SZ, nullptr, &status)));
    total_allocated += input_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(tiles_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_WRITE, sizeof(cl_float2) * FDF_TILED_INPUT_SZ, nullptr, &status)));
    total_allocated += tiles_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(templates_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(cl_float2) * FDF_TEMPLATES_SZ, nullptr, &status)));
    total_allocated += templates_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(fop_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_WRITE, sizeof(cl_float) * FOP_SZ, nullptr, &status)));
    total_allocated += fop_buffer->getInfo<CL_MEM_SIZE>();

    cl_chkref(thresholds_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(cl_float) * HMS_N_PLANES, nullptr, &status)));
    total_allocated += thresholds_buffer->getInfo<CL_MEM_SIZE>();

    if (HMS_STORE_PLANES) {
        cl_chkref(harmonic_planes_buffer.reset(new cl::Buffer(*context, CL_MEM_WRITE_ONLY, sizeof(cl_float) * HMS_PLANES_SZ, nullptr, &status)));
        total_allocated += harmonic_planes_buffer->getInfo<CL_MEM_SIZE>();
    }

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

bool FDAS::perform_ft_convolution(const FDAS::InputType &input, const FDAS::ShapeType &input_shape,
                                  const FDAS::TemplatesType &templates, const FDAS::ShapeType &templates_shape) {
    // Fail early if dimensions do not match the hardware architecture
    if (!check_dimensions(input_shape, templates_shape)) {
        return false;
    }

    // Instantiate command queues, one per kernel, plus one for I/O operations. Multi-device support is NYI
    cl::CommandQueue buffer_q(*context, default_device);

    cl::CommandQueue tile_input_q(*context, default_device);
    cl::CommandQueue store_tiles_q(*context, default_device);
    cl::CommandQueue mux_and_mult_q(*context, default_device);
    cl::CommandQueue square_and_discard_q(*context, default_device);

    // NDRange configuration
    cl::NDRange prep_local(FFT_N_POINTS_PER_TERMINAL);
    cl::NDRange prep_global(FFT_N_POINTS_PER_TERMINAL * FDF_N_TILES);

    cl::NDRange conv_local(FFT_N_POINTS_PER_TERMINAL, 1);
    cl::NDRange conv_global(FFT_N_POINTS_PER_TERMINAL * FDF_N_TILES, N_FILTER_BATCHES);

    // Set static kernel arguments
    cl_chk(tile_input_kernel->setArg<cl::Buffer>(0, *input_buffer));
    cl_chk(store_tiles_kernel->setArg<cl::Buffer>(0, *tiles_buffer));

    cl_chk(mux_and_mult_kernel->setArg<cl::Buffer>(0, *tiles_buffer));
    cl_chk(mux_and_mult_kernel->setArg<cl::Buffer>(1, *templates_buffer));

    cl_chk(square_and_discard_kernel->setArg<cl::Buffer>(0, *fop_buffer));

    // Copy input to device
    cl_float2 zeros[FDF_TILE_OVERLAP];
    memset(zeros, 0x0, sizeof(cl_float2) * FDF_TILE_OVERLAP);
    cl_chk(buffer_q.enqueueWriteBuffer(*input_buffer, true, 0, sizeof(cl_float2) * FDF_TILE_OVERLAP, zeros));
    cl_chk(buffer_q.enqueueWriteBuffer(*input_buffer, true, sizeof(cl_float2) * FDF_TILE_OVERLAP, sizeof(cl_float2) * FDF_INPUT_SZ, input.data()));
    cl_chk(buffer_q.enqueueWriteBuffer(*templates_buffer, true, 0, sizeof(cl_float2) * FDF_TEMPLATES_SZ, templates.data()));
    cl_chk(buffer_q.finish());

    cl::Event tile_input_ev, store_tiles_ev, mux_and_mult_ev, square_and_discard_ev;
    cl_chk(tile_input_q.enqueueNDRangeKernel(*tile_input_kernel, cl::NullRange, prep_global, prep_local, nullptr, &tile_input_ev));
    cl_chk(store_tiles_q.enqueueNDRangeKernel(*store_tiles_kernel, cl::NullRange, prep_global, prep_local, nullptr, &store_tiles_ev));
    tile_input_q.finish();
    store_tiles_q.finish();
    print_duration("Preparation", tile_input_ev, store_tiles_ev);

    cl_chk(mux_and_mult_q.enqueueNDRangeKernel(*mux_and_mult_kernel, cl::NullRange, conv_global, conv_local, nullptr, &mux_and_mult_ev));
    cl_chk(square_and_discard_q.enqueueNDRangeKernel(*square_and_discard_kernel, cl::NullRange, conv_global, conv_local, nullptr, &square_and_discard_ev));
    mux_and_mult_q.finish();
    square_and_discard_q.finish();

    print_duration("FT convolution and IFFT", mux_and_mult_ev, square_and_discard_ev);

    return true;
}

bool FDAS::perform_harmonic_summing(const FDAS::ThreshType &thresholds, const FDAS::ShapeType &thresholds_shape) {
    if (thresholds_shape.size() != 1 && thresholds_shape[0] < HMS_N_PLANES) {
        log << "[ERROR] Not enough threshold values given" << endl;
        return false;
    }

    cl::CommandQueue buffer_q(*context, default_device);
    cl::CommandQueue harmonic_summing_q(*context, default_device);

    cl_chk(harmonic_summing_kernel->setArg<cl::Buffer>(0, *fop_buffer));
    cl_chk(harmonic_summing_kernel->setArg<cl::Buffer>(1, *thresholds_buffer));
    cl_chk(harmonic_summing_kernel->setArg<cl::Buffer>(2, *detection_location_buffer));
    cl_chk(harmonic_summing_kernel->setArg<cl::Buffer>(3, *detection_amplitude_buffer));
    if (HMS_STORE_PLANES)
        cl_chk(harmonic_summing_kernel->setArg<cl::Buffer>(4, *harmonic_planes_buffer));

    cl_chk(buffer_q.enqueueWriteBuffer(*thresholds_buffer, true, 0, sizeof(cl_float) * HMS_N_PLANES, thresholds.data()));
    cl_chk(buffer_q.finish());

    cl::Event harmonic_summing_ev;
    cl_chk(harmonic_summing_q.enqueueTask(*harmonic_summing_kernel, nullptr, &harmonic_summing_ev));
    cl_chk(harmonic_summing_q.finish());

    print_duration("Harmonic summing", harmonic_summing_ev, harmonic_summing_ev);

    return true;
}

bool FDAS::retrieve_tiles(FDAS::TilesType &tiles, FDAS::ShapeType &tiles_shape) {
    tiles.resize(FDF_TILED_INPUT_SZ);
    cl::CommandQueue buffer_q(*context, default_device);
    cl_chk(buffer_q.enqueueReadBuffer(*tiles_buffer, true, 0, sizeof(cl_float2) * FDF_TILED_INPUT_SZ, tiles.data()));
    cl_chk(buffer_q.finish());
    tiles_shape.push_back(FDF_N_TILES);
    tiles_shape.push_back(FDF_TILE_SZ);

    return true;
}

bool FDAS::retrieve_FOP(FDAS::FOPType &fop, FDAS::ShapeType &fop_shape) {
    fop.resize(FOP_SZ);
    cl::CommandQueue buffer_q(*context, default_device);
    cl_chk(buffer_q.enqueueReadBuffer(*fop_buffer, true, 0, sizeof(cl_float) * FOP_SZ, fop.data()));
    cl_chk(buffer_q.finish());
    fop_shape.push_back(N_FILTERS);
    fop_shape.push_back(FDF_OUTPUT_SZ);

    return true;
}

bool FDAS::retrieve_harmonic_planes(FDAS::HPType &harmonic_planes, FDAS::ShapeType &harmonic_planes_shape) {
    if (!HMS_STORE_PLANES)
        return false;

    harmonic_planes.resize(HMS_PLANES_SZ);
    cl::CommandQueue buffer_q(*context, default_device);
    cl_chk(buffer_q.enqueueReadBuffer(*harmonic_planes_buffer, true, 0, sizeof(cl_float) * HMS_PLANES_SZ, harmonic_planes.data()));
    cl_chk(buffer_q.finish());
    harmonic_planes_shape.push_back(HMS_N_PLANES - 1);
    harmonic_planes_shape.push_back(N_FILTERS);
    harmonic_planes_shape.push_back(FDF_OUTPUT_SZ);

    return true;
}

bool FDAS::retrieve_candidates(FDAS::DetLocType &detection_location, FDAS::ShapeType &detection_location_shape,
                               FDAS::DetAmplType &detection_amplitude, FDAS::ShapeType &detection_amplitude_shape) {
    detection_location.resize(N_CANDIDATES);
    detection_amplitude.resize(N_CANDIDATES);

    cl::CommandQueue buffer_q(*context, default_device);
    cl_chk(buffer_q.enqueueReadBuffer(*detection_location_buffer, true, 0, sizeof(cl_uint) * N_CANDIDATES, detection_location.data()));
    cl_chk(buffer_q.enqueueReadBuffer(*detection_amplitude_buffer, true, 0, sizeof(cl_float) * N_CANDIDATES, detection_amplitude.data()));
    cl_chk(buffer_q.finish());

    detection_location_shape.push_back(N_CANDIDATES);
    detection_amplitude_shape.push_back(N_CANDIDATES);

    return true;
}

void FDAS::print_duration(const std::string &phase, const cl::Event &from, const cl::Event &to) {
    unsigned long duration = (to.getProfilingInfo<CL_PROFILING_COMMAND_END>()
                              - from.getProfilingInfo<CL_PROFILING_COMMAND_START>()) / 1000 / 1000;
    log << "[INFO] " << phase << " duration: " << duration << " ms" << endl;
}

#undef cl_chk
#undef cl_chkref
