#include <algorithm>
#include <cmath>
#include <complex>
#include <functional>
#include <iostream>
#include <string>
#include <vector>

#include "libnpy/npy.hpp"
#include "gtest/gtest.h"

#include "FDAS.h"
#include "fdas_config.h"

class FDASTest : public ::testing::TestWithParam<std::string> {
public:
    constexpr static float tolerance = 1e-5f;

    static std::vector<std::string> test_vectors;

    static std::string templates_file;
    static std::string bitstream_file;

protected:
    std::string input_file() { return GetParam() + "/input.npy"; }

    std::string tiles_file(bool ref = false) { return GetParam() + "/input_tiled_p" + std::to_string(FFT_N_PARALLEL) + (ref ? "_ref" : "") + ".npy"; }

    std::string fop_file(bool ref = false) { return GetParam() + "/fop" + (ref ? "_ref" : "") + ".npy"; }

    std::string thrsh_file() { return GetParam() + "/thresholds.npy"; }

    std::string hps_file(bool ref = false) { return GetParam() + "/hps" + (ref ? "_ref" : "") + ".npy"; }

    std::string det_loc_file(bool ref = false) { return GetParam() + "/det_loc" + (ref ? "_ref" : "") + ".npy"; }

    std::string det_amp_file(bool ref = false) { return GetParam() + "/det_amp" + (ref ? "_ref" : "") + ".npy"; }

    FDAS::InputType input;
    FDAS::ShapeType input_shape;

    FDAS::TemplatesType templates;
    FDAS::ShapeType templates_shape;

    FDAS::TilesType tiles, tiles_ref;
    FDAS::ShapeType tiles_shape, tiles_ref_shape;

    FDAS::FOPType fop, fop_ref;
    FDAS::ShapeType fop_shape, fop_ref_shape;

    FDAS::ThreshType thresholds;
    FDAS::ShapeType thresholds_shape;

    FDAS::HPType harmonic_planes, harmonic_planes_ref;
    FDAS::ShapeType harmonic_planes_shape, harmonic_planes_ref_shape;

    FDAS::DetLocType detection_location, detection_location_ref;
    FDAS::ShapeType detection_location_shape, detection_location_ref_shape;

    FDAS::DetAmplType detection_amplitude, detection_amplitude_ref;
    FDAS::ShapeType detection_amplitude_shape, detection_amplitude_ref_shape;

    void SetUp() override {
        bool fortran_order = false; // library wants this as a reference
        npy::LoadArrayFromNumpy(input_file(), input_shape, fortran_order, input);
        npy::LoadArrayFromNumpy(templates_file, templates_shape, fortran_order, templates);
        npy::LoadArrayFromNumpy(tiles_file(true), tiles_ref_shape, fortran_order, tiles_ref);
        npy::LoadArrayFromNumpy(fop_file(true), fop_ref_shape, fortran_order, fop_ref);
        npy::LoadArrayFromNumpy(thrsh_file(), thresholds_shape, fortran_order, thresholds);
        npy::LoadArrayFromNumpy(det_loc_file(true), detection_location_ref_shape, fortran_order, detection_location_ref);
        npy::LoadArrayFromNumpy(det_amp_file(true), detection_amplitude_ref_shape, fortran_order, detection_amplitude_ref);
        if (HMS_STORE_PLANES)
            npy::LoadArrayFromNumpy(hps_file(true), harmonic_planes_ref_shape, fortran_order, harmonic_planes_ref);
    }
};

/*
TEST_P(FDASTest, FT_Convolution) {
    FDAS pipeline(std::cerr);
    ASSERT_TRUE(pipeline.initialise_accelerator(bitstream_file, FDAS::choose_first_platform, FDAS::choose_accelerator_devices));

    ASSERT_TRUE(pipeline.perform_ft_convolution(input, input_shape, templates, templates_shape));

    ASSERT_TRUE(pipeline.retrieve_tiles(tiles, tiles_shape));
    EXPECT_EQ(tiles.size(), tiles_ref.size());
    EXPECT_TRUE(std::equal(tiles.begin(), tiles.end(), tiles_ref.begin(),
                           [](const std::complex<float> a, const std::complex<float> b) {
                               return (fabs(a.real() - b.real()) < tolerance) &&
                                      (fabs(a.imag() - b.imag()) < tolerance);
                           }
    ));
    npy::SaveArrayAsNumpy(tiles_file(), false, tiles_shape.size(), tiles_shape.data(), tiles);

    ASSERT_TRUE(pipeline.retrieve_FOP(fop, fop_shape));
    EXPECT_EQ(fop.size(), fop_ref.size());
    EXPECT_TRUE(std::equal(fop.begin(), fop.end(), fop_ref.begin(),
                           [](const float a, const float b) {
                               return fabs(a - b) < tolerance;
                           }
    ));
    npy::SaveArrayAsNumpy(fop_file(), false, fop_shape.size(), fop_shape.data(), fop);
}
*/

TEST_P(FDASTest, Harmonic_Summing) {
    FDAS pipeline(std::cerr);
    ASSERT_TRUE(pipeline.initialise_accelerator(bitstream_file, FDAS::choose_first_platform, FDAS::choose_accelerator_devices));

    ASSERT_TRUE(pipeline.inject_FOP(fop_ref, fop_ref_shape));

    ASSERT_TRUE(pipeline.perform_harmonic_summing(thresholds, thresholds_shape));
    if (HMS_STORE_PLANES) {
        ASSERT_TRUE(pipeline.retrieve_harmonic_planes(harmonic_planes, harmonic_planes_shape));
        EXPECT_EQ(harmonic_planes.size(), harmonic_planes_ref.size());
        EXPECT_TRUE(std::equal(harmonic_planes.begin(), harmonic_planes.end(), harmonic_planes_ref.begin(),
                               [](const float a, const float b) {
                                   return fabs(a - b) < tolerance;
                               }
        ));
        npy::SaveArrayAsNumpy(hps_file(), false, harmonic_planes_shape.size(), harmonic_planes_shape.data(), harmonic_planes);
    }

    ASSERT_TRUE(pipeline.retrieve_candidates(detection_location, detection_location_shape, detection_amplitude, detection_amplitude_shape));
    // store data as downloaded from the device (i.e. before filtering invalid slots)
    npy::SaveArrayAsNumpy(det_loc_file(), false, detection_location_shape.size(), detection_location_shape.data(), detection_location);
    npy::SaveArrayAsNumpy(det_amp_file(), false, detection_amplitude_shape.size(), detection_amplitude_shape.data(), detection_amplitude);

    auto loc_it = detection_location.begin();
    auto amp_it = detection_amplitude.begin();
    while (loc_it != detection_location.end() && amp_it != detection_amplitude.end()) {
        auto loc = *loc_it;
        if (loc == HMS_INVALID_LOCATION) {
            loc_it = detection_location.erase(loc_it);
            amp_it = detection_amplitude.erase(amp_it);
        } else {
            ++loc_it, ++amp_it;
        }
    }
    EXPECT_LE(detection_location.size(), detection_location_ref.size());
    EXPECT_GE(detection_location.size(), 1);

    int n_non_cands = 0;
    for (loc_it = detection_location.begin(), amp_it = detection_amplitude.begin();
         loc_it != detection_location.end() && amp_it != detection_amplitude.end();
         ++loc_it, ++amp_it) {
        auto loc = *loc_it;
        auto amp = *amp_it;

        auto it = std::find(detection_location_ref.begin(), detection_location_ref.end(), loc);
        if (it == detection_location_ref.end()) {
            ++n_non_cands;
            continue;
        }
        auto dist = std::distance(detection_location_ref.begin(), it);
        auto amp_ref = detection_amplitude_ref[dist];
        EXPECT_TRUE(fabs(amp - amp_ref) < tolerance);
    }
    EXPECT_EQ(n_non_cands, 0);
}

INSTANTIATE_TEST_SUITE_P(TestVectors, FDASTest, ::testing::ValuesIn(FDASTest::test_vectors));

std::vector<std::string> FDASTest::test_vectors;
std::string FDASTest::bitstream_file;
std::string FDASTest::templates_file;

int main(int argc, char **argv) {
    for (int i = 1; i < argc; ++i) {
        std::string arg(argv[i]);
        if (arg.empty() || arg[0] == '-')
            break;
        FDASTest::test_vectors.push_back(arg);
    }

    ::testing::InitGoogleTest(&argc, argv);

    if (TARGET_IS_FPGA) {
        FDASTest::bitstream_file = "bin/fdas.aocx";
        FDASTest::templates_file = "../../fdas/tmpl/fdas_templates_85_350_ft_p4.npy";
    } else {
        FDASTest::bitstream_file = "bin/fdas_emu.aocx";
        FDASTest::templates_file = "../../fdas/tmpl/fdas_templates_21_87.5_ft_p4.npy";
    }

    return RUN_ALL_TESTS();
}
