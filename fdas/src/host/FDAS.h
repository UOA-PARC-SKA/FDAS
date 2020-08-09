
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
    using ThreshType = std::vector<float>;
    using DetLocType = std::vector<uint32_t>;
    using DetAmplType = std::vector<float>;
    using HPType = std::vector<float>;

    using ShapeType = std::vector<unsigned long>;

public:
    FDAS(std::ostream &log) : log(log) {}

    bool initialise_accelerator(std::string bitstream_file_name, const std::function<bool(const std::string &, const std::string &)> &platform_selector, const std::function<bool(int, int, const std::string &)> &device_selector);

    bool perform_ft_convolution(const InputType &input, const ShapeType &input_shape,
                                const TemplatesType &templates, const ShapeType &templates_shape);

    bool perform_harmonic_summing(const ThreshType &thresholds, const ShapeType &thresholds_shape);

    bool retrieve_tiles(TilesType &tiles, ShapeType &tiles_shape);

    bool retrieve_FOP(FOPType &fop, ShapeType &fop_shape);

    bool inject_FOP(FOPType &fop, ShapeType &fop_shape);

    bool retrieve_harmonic_planes(HPType &harmonic_planes, ShapeType &harmonic_planes_shape);

    bool retrieve_candidates(DetLocType &detection_location, ShapeType &detection_location_shape,
                             DetAmplType &detection_amplitude, ShapeType &detection_amplitude_shape);

    static bool choose_first_platform(const std::string &platform_name, const std::string &platform_version) { return true; }

    static bool choose_accelerator_devices(int device_num, int device_type, const std::string &device_name) { return device_type == CL_DEVICE_TYPE_ACCELERATOR; }

    static bool acl1_on_x240(int device_num, int device_type, const std::string &device_name) { return device_num == 1 && device_type == CL_DEVICE_TYPE_ACCELERATOR; }

private:
    cl::Platform platform;
    cl::Device default_device;
    std::vector<cl::Device> devices;

    std::unique_ptr<cl::Context> context;
    std::unique_ptr<cl::Program> program;

    std::unique_ptr<cl::Kernel> tile_input_kernel;
    std::unique_ptr<cl::Kernel> store_tiles_kernel;
    std::unique_ptr<cl::Kernel> mux_and_mult_kernel;
    std::unique_ptr<cl::Kernel> square_and_discard_kernel;

    std::vector<std::unique_ptr<cl::Kernel>> preload_kernels;
    std::vector<std::unique_ptr<cl::Kernel>> delay_kernels;
    std::vector<std::unique_ptr<cl::Kernel>> detect_kernels;
    std::unique_ptr<cl::Kernel> store_cands_kernel;

    std::unique_ptr<cl::Buffer> input_buffer;
    std::unique_ptr<cl::Buffer> tiles_buffer;
    std::unique_ptr<cl::Buffer> templates_buffer;
    std::unique_ptr<cl::Buffer> fop_buffer;
    std::unique_ptr<cl::Buffer> harmonic_planes_buffer;
    std::unique_ptr<cl::Buffer> detection_location_buffer;
    std::unique_ptr<cl::Buffer> detection_amplitude_buffer;

    std::ostream &log;

private:
    bool check_dimensions(const ShapeType &input_shape, const ShapeType &templates_shape);

    void print_duration(const std::string &phase, const cl::Event &from, const cl::Event &to);

};

#endif //SKAPINT_FDAS_H
