
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
#define PRINT_CONFIG(X) log << setw(27) << #X << setw(12) << X << endl
    PRINT_CONFIG(N_CHANNELS);
    PRINT_CONFIG(FILTER_GROUP_SZ);
    PRINT_CONFIG(N_FILTERS);
    PRINT_CONFIG(N_TAPS);
    PRINT_CONFIG(FFT_N_POINTS_LOG);
    PRINT_CONFIG(FFT_N_POINTS);
    PRINT_CONFIG(FFT_N_PARALLEL);
    PRINT_CONFIG(FFT_N_STEPS);
    PRINT_CONFIG(FFT_LATENCY);
    PRINT_CONFIG(FDF_TILE_SZ);
    PRINT_CONFIG(FDF_TILE_OVERLAP);
    PRINT_CONFIG(FDF_TILE_PAYLOAD);
    PRINT_CONFIG(FDF_N_TILES);
    PRINT_CONFIG(FDF_INPUT_SZ);
    PRINT_CONFIG(FDF_INTERMEDIATE_SZ);
    PRINT_CONFIG(FDF_OUTPUT_SZ);
    PRINT_CONFIG(NDR_N_TILES_PER_WORK_GROUP);
    PRINT_CONFIG(NDR_N_POINTS_PER_WORK_GROUP);
    PRINT_CONFIG(NDR_N_POINTS_PER_WORK_ITEM);
    PRINT_CONFIG(NDR_N_WORK_ITEMS_PER_TILE);
    PRINT_CONFIG(NDR_WORK_GROUP_SZ);
    PRINT_CONFIG(FOP_PRE_DISCARD_SZ);
    PRINT_CONFIG(FOP_SZ);
    PRINT_CONFIG(HMS_N_PLANES);
    PRINT_CONFIG(HMS_DETECTION_SZ);
    PRINT_CONFIG(N_CANDIDATES);
#undef PRINT_CONFIG
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
    // XXX: Find out how to use exceptions here (and still get a usable error message)
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
    input_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_ONLY, sizeof(cl_float2) * FDF_INPUT_SZ, nullptr, &status));
    if (status != CL_SUCCESS) {
        log << "[ERROR] Allocating buffer 'input' failed with status: " << status << endl;
        return false;
    }
    total_allocated += input_buffer->getInfo<CL_MEM_SIZE>();

    discard_buffer.reset(new cl::Buffer(*context, CL_MEM_READ_WRITE, sizeof(cl_float) * FOP_PRE_DISCARD_SZ, nullptr, &status));
    if (status != CL_SUCCESS) {
        log << "[ERROR] Allocating buffer 'fop' failed with status: " << status << endl;
        return false;
    }
    total_allocated += discard_buffer->getInfo<CL_MEM_SIZE>();

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

    // Queues
    input_queue.reset(new cl::CommandQueue(*context, default_device));
    fft_queue.reset(new cl::CommandQueue(*context, default_device));
    fop_queue.reset(new cl::CommandQueue(*context, default_device));
    detection_queue.reset(new cl::CommandQueue(*context, default_device));
}

void FDAS::run(const FDAS::FreqDomainType &input, FDAS::DetectionType &detection, FDAS::FOPType *fop) {

}
