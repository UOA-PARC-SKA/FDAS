
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
public:
    using InputType = std::vector<std::complex<float>>;
    using TilesType = std::vector<std::complex<float>>;
    using TemplatesType = std::vector<std::complex<float>>;
    using FOPType = std::vector<float>;
//    using DetLocType = std::vector<uint32_t>;
//    using DetAmplType = std::vector<float>;

    using ShapeType = std::vector<unsigned long>;

public:
    FDAS(std::ostream &log) : log(log) {}

    void print_configuration();

    bool initialise_accelerator(std::string bitstream_file_name, const std::function<bool(const std::string &, const std::string &)> &platform_selector, const std::function<bool(int, int, const std::string &)> &device_selector);

    bool perform_ft_convolution(const InputType &input, const ShapeType &input_shape,
                                const TemplatesType &templates, const ShapeType &template_shape);

    bool retrieve_tiles(TilesType &tiles, ShapeType &tiles_shape);

    bool retrieve_FOP(FOPType &fop, ShapeType &fop_shape);

    static bool chooseFirstPlatform(const std::string &platform_name, const std::string &platform_version) { return true; }

    static bool chooseAcceleratorDevices(int device_num, int device_type, const std::string &device_name) { return device_type == CL_DEVICE_TYPE_ACCELERATOR; }

private:
    cl::Platform platform;
    cl::Device default_device;
    std::vector<cl::Device> devices;

    std::unique_ptr<cl::Context> context;
    std::unique_ptr<cl::Program> program;

    std::unique_ptr<cl::Kernel> fwd_fetch_kernel;
    std::unique_ptr<cl::Kernel> fwd_fft_kernel;
    std::unique_ptr<cl::Kernel> fwd_reversed_kernel;
    std::unique_ptr<cl::Kernel> fetch_kernel;
    std::unique_ptr<cl::Kernel> fdfir_kernel;
    std::unique_ptr<cl::Kernel> reversed_kernel;
    std::unique_ptr<cl::Kernel> discard_kernel;
//    std::unique_ptr<cl::Kernel> harmonic_kernel;

    std::unique_ptr<cl::Buffer> input_buffer;
    std::unique_ptr<cl::Buffer> tiles_buffer;
    std::unique_ptr<cl::Buffer> templates_buffer;
    std::unique_ptr<cl::Buffer> discard_buffers[2];
    std::unique_ptr<cl::Buffer> fop_buffer;
//    std::unique_ptr<cl::Buffer> detection_location_buffer;
//    std::unique_ptr<cl::Buffer> detection_amplitude_buffer;

    std::ostream &log;

private:
    bool check_dimensions(const ShapeType &input_shape, const ShapeType &templates_shape);

};

#endif //SKAPINT_FDAS_H
