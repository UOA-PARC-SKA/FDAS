
#ifndef SKAPINT_FDAS_H
#define SKAPINT_FDAS_H

#include <complex>
#include <functional>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include <CL/cl.hpp>

class FDAS {
private:
    cl::Platform platform;
    cl::Device default_device;
    std::vector<cl::Device> devices;

    std::unique_ptr<cl::Context> context;
    std::unique_ptr<cl::Program> program;

    std::unique_ptr<cl::Kernel> fetch_kernel;
    std::unique_ptr<cl::Kernel> fdfir_kernel;
    std::unique_ptr<cl::Kernel> reversed_kernel;
    std::unique_ptr<cl::Kernel> discard_kernel;
    std::unique_ptr<cl::Kernel> harmonic_kernel;

    std::unique_ptr<cl::Buffer> input_buffer;
    std::unique_ptr<cl::Buffer> discard_buffer;
    std::unique_ptr<cl::Buffer> fop_buffer;
    std::unique_ptr<cl::Buffer> detection_location_buffer;
    std::unique_ptr<cl::Buffer> detection_amplitude_buffer;

    std::unique_ptr<cl::CommandQueue> input_queue;
    std::unique_ptr<cl::CommandQueue> fft_queue;
    std::unique_ptr<cl::CommandQueue> fop_queue;
    std::unique_ptr<cl::CommandQueue> detection_queue;

    std::ostream &log;

public:
    using FreqDomainType = std::vector<std::complex<float>>;
    using FOPType = std::vector<float>;
    using DetectionType = std::vector<std::pair<uint32_t, float>>;

    FDAS(std::ostream &log) : log(log) {}

    void print_configuration();

    bool initialise_accelerator(std::string bitstream_file_name, const std::function<bool(const std::string &, const std::string &)> &platform_selector, const std::function<bool(int, int, const std::string &)> &device_selector);

    void release_accelerator();

    void run(const FreqDomainType &input, DetectionType &detection, FOPType *fop = nullptr);

    static bool chooseFirstPlatform(const std::string &platform_name, const std::string &platform_version) { return true; }

    static bool chooseAcceleratorDevices(int device_num, int device_type, const std::string &device_name) { return device_type == CL_DEVICE_TYPE_ACCELERATOR; }
};

#endif //SKAPINT_FDAS_H
