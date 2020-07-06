
#include <iostream>
#include <stdexcept>
#include <string>

#include "libnpy/npy.hpp"

#include "FDAS.h"

enum FDAS_STATUS {
    SUCCESS = 0,
    LOAD_INPUT_ERROR, INIT_ERROR, FT_CONV_ERROR, SAVE_OUTPUT_ERROR,
    RETR_TILES_ERROR, SAVE_TILES_ERROR, RETR_FOP_ERROR, SAVE_FOP_ERROR
};

int main(int argc, char **argv) {
    if (argc != 6) {
        std::cerr << "usage: fdas <bitstream>.aocx <input>.npy <templates>.npy <tiles.npy> <fop.npy>" << std::endl;
        exit(1);
    }

    std::string bitstream_file_name = argv[1];
    std::string input_file_name = argv[2];
    std::string templates_file_name = argv[3];
    std::string tiles_file_name = argv[4];
    std::string fop_file_name = argv[5];
//    std::string det_loc_file_name = argv[6];
//    std::string det_ampl_file_name = argv[7];

    FDAS::InputType input;
    FDAS::ShapeType input_shape;

    FDAS::TemplatesType templates;
    FDAS::ShapeType templates_shape;

//    FDAS::DetLocType detection_location;
//    FDAS::DetAmplType detection_amplitude;

    try {
        bool fortran_order = false; // library wants this as a reference
        npy::LoadArrayFromNumpy(input_file_name, input_shape, fortran_order, input);
        npy::LoadArrayFromNumpy(templates_file_name, templates_shape, fortran_order, templates);
    } catch (std::runtime_error &e) {
        std::cerr << "Loading input/filter templates failed: " << e.what() << std::endl;
        return LOAD_INPUT_ERROR;
    }

    FDAS pipeline(std::cout);
    pipeline.print_configuration();

    if (!pipeline.initialise_accelerator(bitstream_file_name, FDAS::choose_first_platform, FDAS::choose_accelerator_devices))
        return INIT_ERROR;

    if (!pipeline.perform_ft_convolution(input, input_shape, templates, templates_shape))
        return FT_CONV_ERROR;

    if (!tiles_file_name.empty()) {
        FDAS::ShapeType tiles_shape;
        FDAS::TilesType tiles;

        if (!pipeline.retrieve_tiles(tiles, tiles_shape))
            return RETR_TILES_ERROR;

        try {
            npy::SaveArrayAsNumpy(tiles_file_name, false, tiles_shape.size(), tiles_shape.data(), tiles);
        } catch (std::runtime_error &e) {
            std::cerr << "Saving tiled input data plane failed: " << e.what() << std::endl;
            return SAVE_TILES_ERROR;
        }
    }

    if (!fop_file_name.empty()) {
        FDAS::ShapeType fop_shape;
        FDAS::FOPType fop;

        if (!pipeline.retrieve_FOP(fop, fop_shape))
            return RETR_FOP_ERROR;

        try {
            npy::SaveArrayAsNumpy(fop_file_name, false, fop_shape.size(), fop_shape.data(), fop);
        } catch (std::runtime_error &e) {
            std::cerr << "Saving filter-output plane failed: " << e.what() << std::endl;
            return SAVE_FOP_ERROR;
        }
    }

//    try {
//        // TODO: retrieve detections (because pipeline API changed)
//        FDAS::ShapeType detection_location_shape = {detection_location.size()};
//        FDAS::ShapeType detection_amplitude_shape = {detection_amplitude.size()};
//        npy::SaveArrayAsNumpy(det_loc_file_name, false, detection_location_shape.size(), detection_location_shape.data(), detection_location);
//        npy::SaveArrayAsNumpy(det_ampl_file_name, false, detection_amplitude_shape.size(), detection_amplitude_shape.data(), detection_amplitude);
//    } catch (std::runtime_error &e) {
//        std::cerr << "Saving detection result failed: " << e.what() << std::endl;
//        return SAVE_OUTPUT_ERROR;
//    }

    return 0;
}
