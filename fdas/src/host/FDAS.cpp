
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
#define print_config(X) log << setw(27) << #X << setw(12) << X << endl
    print_config(N_CHANNELS);
    print_config(FILTER_GROUP_SZ);
    print_config(N_FILTERS);
    print_config(N_TAPS);
    print_config(FFT_N_POINTS_LOG);
    print_config(FFT_N_POINTS);
    print_config(FFT_N_PARALLEL);
    print_config(FFT_N_STEPS);
    print_config(FFT_LATENCY);
    print_config(FDF_TILE_SZ);
    print_config(FDF_TILE_OVERLAP);
    print_config(FDF_TILE_PAYLOAD);
    print_config(FDF_N_TILES);
    print_config(FDF_INPUT_SZ);
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

bool FDAS::initialise_accelerator(std::string bitstream_file_name,
                                  const std::function<bool(const std::string &, const std::string &)> &platform_selector,
                                  const std::function<bool(int, int, const std::string &)> &device_selector) {
    cl_int status;

    std::vector<cl::Platform> all_platforms;
    status = cl::Platform::get(&all_platforms);
    if (status != CL_SUCCESS || all_platforms.empty()) {
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
    status = platform.getDevices(CL_DEVICE_TYPE_ALL, &all_devices);
    if (status != CL_SUCCESS || all_devices.empty()) {
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

    std::vector<cl_int> binary_status;
    program.reset(new cl::Program(*context, devices, binaries, &binary_status, &status));
    if (status != CL_SUCCESS) {
        log << "[ERROR] Loading program failed with status: " << status << endl;
        return false;
    }

    status = program->build(devices);
    if (status != CL_SUCCESS) {
        log << "[ERROR] Building program failed with status: " << status << endl;
        exit(status);
    }

    log << "[INFO] Program construction from '" << bitstream_file_name << "' (" << bitstream.size() << " bytes) successful" << endl;

    // free our copy of the bitstream
    bitstream.clear();
    bitstream.shrink_to_fit();

    // Kernels
    fetch_kernel.reset(new cl::Kernel(*program, "fetch", &status));
    if (status != CL_SUCCESS) {
        log << "[ERROR] Loading kernel 'fetch' failed with status: " << status << endl;
        return false;
    }
    fdfir_kernel.reset(new cl::Kernel(*program, "fdfir", &status));
    if (status != CL_SUCCESS) {
        log << "[ERROR] Loading kernel 'fdfir' failed with status: " << status << endl;
        return false;
    }
    reversed_kernel.reset(new cl::Kernel(*program, "reversed", &status));
    if (status != CL_SUCCESS) {
        log << "[ERROR] Loading kernel 'reversed failed with status: " << status << endl;
        return false;
    }
    discard_kernel.reset(new cl::Kernel(*program, "discard", &status));
    if (status != CL_SUCCESS) {
        log << "[ERROR] Loading kernel 'discard' failed with status: " << status << endl;
        return false;
    }
    harmonic_kernel.reset(new cl::Kernel(*program, "harmonic_summing", &status));
    if (status != CL_SUCCESS) {
        log << "[ERROR] Loading kernel 'fdfir' failed with status: " << status << endl;
        return false;
    }

    // Buffers
    size_t total_allocated = 0;
    input_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(cl_float2) * FDF_INTERMEDIATE_SZ, nullptr, &status)); // change this to FDF_INPUT_SZ once input FFT is implemented
    if (status != CL_SUCCESS) {
        log << "[ERROR] Allocating buffer 'input' failed with status: " << status << endl;
        return false;
    }
    total_allocated += input_buffer->getInfo<CL_MEM_SIZE>();

    templates_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(cl_float2) * FDF_TEMPLATES_SZ, nullptr, &status));
    if (status != CL_SUCCESS) {
        log << "[ERROR] Allocating buffer 'templates' failed with status: " << status << endl;
        return false;
    }
    total_allocated += templates_buffer->getInfo<CL_MEM_SIZE>();

    for (int i = 0; i < 2; ++i) {
        discard_buffers[i].reset(new cl::Buffer(*context, CL_MEM_READ_WRITE, sizeof(cl_float) * FDF_PRE_DISCARD_SZ, nullptr, &status));
        if (status != CL_SUCCESS) {
            log << "[ERROR] Allocating buffer 'discard_'" << i << " failed with status: " << status << endl;
            return false;
        }
        total_allocated += discard_buffers[i]->getInfo<CL_MEM_SIZE>();
    }

    fop_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_WRITE, sizeof(cl_float) * FOP_SZ, nullptr, &status));
    if (status != CL_SUCCESS) {
        log << "[ERROR] Allocating buffer 'fop' failed with status: " << status << endl;
        return false;
    }
    total_allocated += fop_buffer->getInfo<CL_MEM_SIZE>();

    detection_location_buffer.reset(new cl::Buffer(*context, CL_MEM_WRITE_ONLY, sizeof(cl_uint) * N_CANDIDATES, nullptr, &status));
    if (status != CL_SUCCESS) {
        log << "[ERROR] Allocating buffer 'detection_location' failed with status: " << status << endl;
        return false;
    }
    total_allocated += detection_location_buffer->getInfo<CL_MEM_SIZE>();

    detection_amplitude_buffer.reset(new cl::Buffer(*context, CL_MEM_WRITE_ONLY, sizeof(cl_float) * N_CANDIDATES, nullptr, &status));
    if (status != CL_SUCCESS) {
        log << "[ERROR] Allocating buffer 'detection_amplitude' failed with status: " << status << endl;
        return false;
    }
    total_allocated += detection_amplitude_buffer->getInfo<CL_MEM_SIZE>();

    log << "[INFO] Allocated "
        << fixed << setprecision(2) << (total_allocated / (1.f * (1 << 20)))
        << " MB for buffers in total ("
        << setprecision(2) << (100.f * total_allocated / default_device.getInfo<CL_DEVICE_GLOBAL_MEM_SIZE>())
        << " %)" << endl;

    return true;
}

bool FDAS::check_dimensions(const FDAS::ShapeType &input_shape, const FDAS::ShapeType &templates_shape) {
#define check_dim(cond, msg) do { if (!(cond)) {log << "[ERROR] " #msg << endl; return false; } } while (0)
    check_dim(input_shape.size() == 2, "Expected pre-tiled input");
    check_dim(input_shape[0] == FDF_N_TILES, "Wrong number of tiles in input");
    check_dim(input_shape[1] == FDF_TILE_SZ, "Tile size is wrong");

    check_dim(templates_shape.size() == 2, "Expected filter coefficient matrix");
    check_dim(templates_shape[0] == N_FILTERS, "Wrong number of filters");
    check_dim(templates_shape[1] == FDF_TILE_SZ, "Tile size is wrong");
#undef check_dim

    return true;
}

#define cl_checked(cmd) \
    do { \
        status = cmd; \
        if (status != CL_SUCCESS) { \
            log << "[ERROR] OpenCL command failed with status " << status << ":\n" \
                << "          " #cmd " [" __FILE__ ":" << __LINE__ << "]" << endl; \
            return false; \
        } \
    } while (0)

bool FDAS::run(const FDAS::InputType &input, const FDAS::ShapeType &input_shape,
               const FDAS::TemplatesType &templates, const FDAS::ShapeType &template_shape,
               FDAS::DetLocType &detection_location, FDAS::DetAmplType &detection_amplitude) {
    // Fail early if dimensions do not match the hardware architecture
    if (!check_dimensions(input_shape, template_shape)) {
        return false;
    }

    cl_int status;

    // Instantiate command queues, one per kernel, plus one for I/O operations. Multi-device support is NYI
    cl::CommandQueue buffer_q(*context, default_device);
    cl::CommandQueue fetch_q(*context, default_device);
    cl::CommandQueue fdfir_q(*context, default_device);
    cl::CommandQueue reversed_q(*context, default_device);
    cl::CommandQueue discard_q(*context, default_device);

    // NDRange configuration
    cl::NDRange local(NDR_WORK_GROUP_SZ);
    cl::NDRange global(NDR_NDRANGE_SZ);

    // Set static kernel arguments
    cl_checked(fetch_kernel->setArg<cl::Buffer>(0, *input_buffer));
    cl_checked(fetch_kernel->setArg<cl::Buffer>(1, *templates_buffer));

    cl_checked(fdfir_kernel->setArg<cl_int>(0, /* inverse FFT */ 1));

    cl_checked(reversed_kernel->setArg<cl::Buffer>(0, *discard_buffers[0]));
    cl_checked(reversed_kernel->setArg<cl::Buffer>(1, *discard_buffers[1]));

    cl_checked(discard_kernel->setArg<cl::Buffer>(0, *discard_buffers[0]));
    cl_checked(discard_kernel->setArg<cl::Buffer>(1, *discard_buffers[1]));
    cl_checked(discard_kernel->setArg<cl::Buffer>(2, *fop_buffer));

    // Copy input to device
    cl_checked(buffer_q.enqueueWriteBuffer(*input_buffer, true, 0, sizeof(cl_float2) * FDF_INTERMEDIATE_SZ, input.data())); // change this to FDF_INPUT_SZ once input FFT is implemented
    cl_checked(buffer_q.enqueueWriteBuffer(*templates_buffer, true, 0, sizeof(cl_float2) * (FDF_TEMPLATES_SZ - FDF_TILE_SZ), templates.data()));
    cl_checked(buffer_q.finish());

    // Enqueue *all* FDFIR kernels at once; the channels will ensure that the data dependencies are respected
    cl::Event fetch_evs[FILTER_GROUP_SZ + 1];
    cl::Event fdfir_evs[FILTER_GROUP_SZ + 1];
    cl::Event reversed_evs[FILTER_GROUP_SZ + 1];
    for (int i = 0; i < FILTER_GROUP_SZ + 1; ++i) {
        int tmpl_idx_0 = i;
        int tmpl_idx_1 = i + FILTER_GROUP_SZ + 1;
        cl_checked(fetch_kernel->setArg<cl_int>(2, tmpl_idx_0));
        cl_checked(fetch_kernel->setArg<cl_int>(3, tmpl_idx_1));
        cl_checked(fetch_q.enqueueNDRangeKernel(*fetch_kernel, cl::NullRange, global, local, nullptr, &fetch_evs[i]));

        cl_checked(fdfir_q.enqueueTask(*fdfir_kernel, nullptr, &fdfir_evs[i]));

        cl_checked(reversed_kernel->setArg<cl_int>(2, i));
        cl_checked(reversed_kernel->setArg<cl_int>(3, i)); // not a typo, the two streams are written to two separate buffers (using the same offsets)
        cl_checked(reversed_q.enqueueNDRangeKernel(*reversed_kernel, cl::NullRange, global, local, nullptr, &reversed_evs[i]));
    }

    // Wait for the FDFIR part of the pipeline to finish
    cl_checked(fetch_q.finish());
    cl_checked(fdfir_q.finish());
    cl_checked(reversed_q.finish());

    unsigned long fdfir_duration_ms = (reversed_evs[FILTER_GROUP_SZ].getProfilingInfo<CL_PROFILING_COMMAND_END>()
                                       - fetch_evs[0].getProfilingInfo<CL_PROFILING_COMMAND_START>()) / 1000 / 1000;
    log << "[INFO] FDFIR took " << fdfir_duration_ms << " ms" << endl;

    cl::Event discard_ev;
    cl_checked(discard_q.enqueueTask(*discard_kernel, nullptr, &discard_ev));
    cl_checked(discard_q.finish());

    unsigned long discard_duration_ms = (discard_ev.getProfilingInfo<CL_PROFILING_COMMAND_END>()
                                         - discard_ev.getProfilingInfo<CL_PROFILING_COMMAND_START>()) / 1000 / 1000;
    log << "[INFO] Discard took " << discard_duration_ms << " ms" << endl;

    log << "[INFO] Harmonic summing NYI" << endl;

    return true;
}

bool FDAS::retrieveFOP(FDAS::FOPType &fop, FDAS::ShapeType &fop_shape) {
    cl_int status;

    fop.reserve(FOP_SZ);
    cl::CommandQueue buffer_q(*context, default_device);
    cl_checked(buffer_q.enqueueReadBuffer(*fop_buffer, true, 0, sizeof(cl_float) * FOP_SZ, fop.data()));
    cl_checked(buffer_q.finish());
    fop_shape.push_back(N_FILTERS);
    fop_shape.push_back(FDF_OUTPUT_SZ);

    return true;
}

#undef cl_checked
