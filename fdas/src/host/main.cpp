
#include <iostream>
#include <stdexcept>
#include <string>

#include "libnpy/npy.hpp"

#include "FDAS.h"

int main(int argc, char **argv) {
    if (argc < 6 || argc > 7) {
        std::cerr << "usage: fdas <bitstream>.aocx <input>.npy <templates>.npy <det_loc>.npy <det_ampl>.npy [<fop>.npy]" << std::endl;
        exit(1);
    }

    std::string bitstream_file_name = argv[1];
    std::string input_file_name = argv[2];
    std::string templates_file_name = argv[3];
    std::string det_loc_file_name = argv[4];
    std::string det_ampl_file_name = argv[5];
    std::string fop_file_name = argc == 7 ? argv[6] : "";

    FDAS::InputType input;
    FDAS::ShapeType input_shape;

    FDAS::TemplatesType templates;
    FDAS::ShapeType templates_shape;

    FDAS::DetLocType detection_location;
    FDAS::DetAmplType detection_amplitude;

    try {
        bool fortran_order = false; // library wants this as a reference
        npy::LoadArrayFromNumpy(input_file_name, input_shape, fortran_order, input);
        npy::LoadArrayFromNumpy(templates_file_name, templates_shape, fortran_order, templates);
    } catch (std::runtime_error &e) {
        std::cerr << "Loading input/filter templates failed: " << e.what() << std::endl;
        return 1;
    }

    FDAS pipeline(std::cout);
    pipeline.print_configuration();

    if (!pipeline.initialise_accelerator(bitstream_file_name, FDAS::chooseFirstPlatform, FDAS::chooseAcceleratorDevices))
        return 1;

    if (!pipeline.run(input, input_shape, templates, templates_shape, detection_location, detection_amplitude))
        return 1;

    try {
        FDAS::ShapeType detection_location_shape = {detection_location.size()};
        FDAS::ShapeType detection_amplitude_shape = {detection_amplitude.size()};
        npy::SaveArrayAsNumpy(det_loc_file_name, false, 1, detection_location_shape.data(), detection_location);
        npy::SaveArrayAsNumpy(det_ampl_file_name, false, 1, detection_amplitude_shape.data(), detection_amplitude);
    } catch (std::runtime_error &e) {
        std::cerr << "Saving detection result failed: " << e.what() << std::endl;
        return 1;
    }

    if (!fop_file_name.empty()) {
        FDAS::ShapeType fop_shape;
        FDAS::FOPType fop;

        if (!pipeline.retrieveFOP(fop, fop_shape))
            return 1;

        try {
            npy::SaveArrayAsNumpy(fop_file_name, false, fop_shape.size(), fop_shape.data(), fop);
        } catch (std::runtime_error &e) {
            std::cerr << "Saving filter-output plane failed: " << e.what() << std::endl;
            return 1;
        }
    }

    return 0;
}
