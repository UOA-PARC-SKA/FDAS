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
    constexpr static float tiles_tolerance = 1e-5f;
    constexpr static float fop_tolerance = 1e-5f;

    static std::vector<std::string> test_vectors;

    static std::string templates_file;
    static std::string bitstream_file;

protected:
    std::string input_file() { return GetParam() + "/input.npy"; }
    std::string tiles_file() { return GetParam() + "/input_tiled_p" + std::to_string(FFT_N_PARALLEL) + ".npy"; }
    std::string fop_file()   { return GetParam() + "/fop.npy"; }

    FDAS::InputType input;
    FDAS::ShapeType input_shape;

    FDAS::TemplatesType templates;
    FDAS::ShapeType templates_shape;

    FDAS::TilesType tiles, tiles_ref;
    FDAS::ShapeType tiles_shape, tiles_shape_ref;

    FDAS::FOPType fop, fop_ref;
    FDAS::ShapeType fop_shape, fop_shape_ref;

    void SetUp() override {
        bool fortran_order = false; // library wants this as a reference
        std::cerr << tiles_file() << std::endl;
        npy::LoadArrayFromNumpy(input_file(), input_shape, fortran_order, input);
        npy::LoadArrayFromNumpy(templates_file, templates_shape, fortran_order, templates);
        npy::LoadArrayFromNumpy(tiles_file(), tiles_shape_ref, fortran_order, tiles_ref);
        npy::LoadArrayFromNumpy(fop_file(), fop_shape_ref, fortran_order, fop_ref);
    }
};

TEST_P(FDASTest, FT_Convolution) {
    FDAS pipeline(std::cerr);
    ASSERT_TRUE(pipeline.initialise_accelerator(bitstream_file, FDAS::choose_first_platform, FDAS::choose_accelerator_devices));
    ASSERT_TRUE(pipeline.perform_ft_convolution(input, input_shape, templates, templates_shape));
    ASSERT_TRUE(pipeline.retrieve_tiles(tiles, tiles_shape));
    ASSERT_TRUE(pipeline.retrieve_FOP(fop, fop_shape));

    EXPECT_EQ(tiles.size(), tiles_ref.size());
    EXPECT_TRUE(std::equal(tiles.begin(), tiles.end(), tiles_ref.begin(),
                           [](const std::complex<float> a, const std::complex<float> b) {
                               return (fabs(a.real() - b.real()) < tiles_tolerance) &&
                                      (fabs(a.imag() - b.imag()) < tiles_tolerance);
                           }
    ));

    EXPECT_EQ(fop.size(), fop_ref.size());
    EXPECT_TRUE(std::equal(fop.begin(), fop.end(), fop_ref.begin(),
                           [](const float a, const float b) {
                               return fabs(a - b) < fop_tolerance;
                           }
    ));
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

#if defined(FDAS_EMU)
    FDASTest::bitstream_file = "bin/fdas_emu.aocx";
    FDASTest::templates_file = "../../fdas/tmpl/fdas_templates_21_87.5_ft_p4.npy";
#else
    FDASTest::bitstreamFile = "bin/fdas.aocx";
    FDASTest::templatesFile = "../../fdas/tmpl/fdas_templates_85_350_ft_p4.npy"
#endif

    return RUN_ALL_TESTS();
}
