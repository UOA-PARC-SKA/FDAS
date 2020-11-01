/*
 * FDAS -- Fourier Domain Acceleration Search, FPGA-accelerated with OpenCL
 * Copyright (C) 2020  Parallel and Reconfigurable Computing Lab,
 *                     Dept. of Electrical, Computer, and Software Engineering,
 *                     University of Auckland, New Zealand
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <algorithm>
#include <cmath>
#include <complex>
#include <functional>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "libnpy/npy.hpp"
#include "gtest/gtest.h"

#include "FDAS.h"
#include "AlignedBuffer.h"

class FDASTest : public ::testing::TestWithParam<std::string> {
public:
    using InputType = std::vector<std::complex<float>>;
    using TilesType = std::vector<std::complex<float>>;
    using TemplatesType = std::vector<std::complex<float>>;
    using FOPType = std::vector<float>;
    using ThreshType = std::vector<float>;
    using DetLocType = std::vector<uint32_t>;
    using DetPwrType = std::vector<float>;
    using ShapeType = std::vector<unsigned long>;

    constexpr static float tolerance = 1e-5f;

    static std::vector<std::string> test_vectors;

    static std::string templates_file;
    static std::string bitstream_file;

protected:
    std::string input_file() { return GetParam() + "/input.npy"; }

    std::string tiles_file(bool ref = false) { return GetParam() + "/input_tiled_p" + std::to_string(FFT::n_parallel) + (ref ? "_ref" : "") + ".npy"; }

    std::string fop_file(bool ref = false) { return GetParam() + "/fop" + (ref ? "_ref" : "") + ".npy"; }

    std::string thrsh_file() { return GetParam() + "/thresholds.npy"; }

    std::string det_loc_file(bool ref = false) { return GetParam() + "/det_loc" + (ref ? "_ref" : "") + ".npy"; }

    std::string det_pwr_file(bool ref = false) { return GetParam() + "/det_pwr" + (ref ? "_ref" : "") + ".npy"; }

    static cl_float2 complex_to_float2(std::complex<float> c) {
        return {c.real(), c.imag()};
    }

    static std::complex<float> float2_to_complex(cl_float2 c) {
        return std::complex<float>(c.s[0], c.s[1]);
    }

    InputType input;
    ShapeType input_shape;
    AlignedBuffer<cl_float2, 64> input_host;

    TilesType tiles, tiles_ref;
    ShapeType tiles_ref_shape;
    AlignedBuffer<cl_float2, 64> tiles_host;

    TemplatesType templates;
    ShapeType templates_shape;
    AlignedBuffer<cl_float2, 64> templates_host;

    ThreshType thresholds;
    ShapeType thresholds_shape;

    FOPType fop, fop_ref;
    ShapeType fop_ref_shape;
    AlignedBuffer<cl_float, 64> fop_host;

    DetLocType detection_location, detection_location_ref;
    ShapeType detection_location_ref_shape;
    AlignedBuffer<cl_uint, 64> detection_location_host;

    DetPwrType detection_power, detection_power_ref;
    ShapeType detection_power_ref_shape;
    AlignedBuffer<cl_float, 64> detection_power_host;

    void SetUp() override {
        bool fortran_order = false; // library wants this as a reference
        npy::LoadArrayFromNumpy(input_file(), input_shape, fortran_order, input);
        npy::LoadArrayFromNumpy(tiles_file(true), tiles_ref_shape, fortran_order, tiles_ref);
        npy::LoadArrayFromNumpy(templates_file, templates_shape, fortran_order, templates);
        npy::LoadArrayFromNumpy(thrsh_file(), thresholds_shape, fortran_order, thresholds);
        npy::LoadArrayFromNumpy(fop_file(true), fop_ref_shape, fortran_order, fop_ref);
        npy::LoadArrayFromNumpy(det_loc_file(true), detection_location_ref_shape, fortran_order, detection_location_ref);
        npy::LoadArrayFromNumpy(det_pwr_file(true), detection_power_ref_shape, fortran_order, detection_power_ref);
    }

    void validateInputDimensions(const FDAS &pipeline) {
        ASSERT_EQ(input.size(), pipeline.get_input_sz());
        ASSERT_EQ(templates.size(), pipeline.get_templates_sz());
        ASSERT_EQ(templates_shape.size(), 2);
        ASSERT_EQ(templates_shape[0], Input::n_templates);
        ASSERT_EQ(templates_shape[1], FTC::tile_sz);
        ASSERT_EQ(thresholds.size(), pipeline.get_thresholds_sz());
        ASSERT_EQ(fop_ref.size(), pipeline.get_fop_sz()); // we inject the reference FOP for HSum-only testing
    }

    void allocateAlignedBuffers(const FDAS &pipeline) {
        input_host.allocate(pipeline.get_input_sz());
        tiles_host.allocate(pipeline.get_tiles_sz());
        templates_host.allocate(pipeline.get_templates_sz());
        fop_host.allocate(pipeline.get_fop_sz());
        detection_location_host.allocate(pipeline.get_candidate_list_sz());
        detection_power_host.allocate(pipeline.get_candidate_list_sz());
    }

    void validateInputTiling() {
        ASSERT_EQ(tiles.size(), tiles_ref.size());
        ASSERT_TRUE(std::equal(tiles.begin(), tiles.end(), tiles_ref.begin(),
                               [](const std::complex<float> a, const std::complex<float> b) {
                                   return (fabs(a.real() - b.real()) < tolerance) &&
                                          (fabs(a.imag() - b.imag()) < tolerance);
                               }
        ));
    }

    void validateFTConvolution() {
        ASSERT_EQ(fop.size(), fop_ref.size());
        ASSERT_TRUE(std::equal(fop.begin(), fop.end(), fop_ref.begin(),
                               [](const float a, const float b) {
                                   return fabs(a - b) < tolerance;
                               }
        ));
    }

    void validateHarmonicSumming() {
        auto loc_it = detection_location.begin();
        auto pwr_it = detection_power.begin();
        while (loc_it != detection_location.end() && pwr_it != detection_power.end()) {
            auto loc = *loc_it;
            if (loc == HMS::invalid_location) {
                loc_it = detection_location.erase(loc_it);
                pwr_it = detection_power.erase(pwr_it);
            } else {
                ++loc_it, ++pwr_it;
            }
        }
        ASSERT_LE(detection_location.size(), detection_location_ref.size());
        ASSERT_GE(detection_location.size(), 1);

        auto n_non_cands = 0;
        for (loc_it = detection_location.begin(), pwr_it = detection_power.begin();
             loc_it != detection_location.end() && pwr_it != detection_power.end();
             ++loc_it, ++pwr_it) {
            auto loc = *loc_it;
            auto pwr = *pwr_it;

            auto it = std::find(detection_location_ref.begin(), detection_location_ref.end(), loc);
            if (it == detection_location_ref.end()) {
                std::cerr << "INVALID[" << n_non_cands << "]:"
                          << " harmonic=" << HMS::get_harmonic(loc)
                          << " template=" << HMS::get_template_num(loc)
                          << " freq.bin=" << HMS::get_harmonic(loc)
                          << " power=" << pwr << std::endl;
                ++n_non_cands;
                continue;
            }
            auto pwr_ref = detection_power_ref[std::distance(detection_location_ref.begin(), it)];
            EXPECT_TRUE(fabs(pwr - pwr_ref) < tolerance);
        }
        ASSERT_EQ(n_non_cands, 0);
    }
};

TEST_P(FDASTest, FT_Convolution) {
    FDAS pipeline(std::cerr);
    ASSERT_TRUE(pipeline.initialise_accelerator(bitstream_file,
                                                FDAS::choose_first_platform, FDAS::choose_accelerator_devices,
                                                input.size()));
    validateInputDimensions(pipeline);
    allocateAlignedBuffers(pipeline);

    std::transform(templates.begin(), templates.end(), templates_host(), complex_to_float2);
    ASSERT_TRUE(pipeline.upload_templates(templates_host()));
    std::transform(input.begin(), input.end(), input_host(), complex_to_float2);
    ASSERT_TRUE(pipeline.perform_input_tiling(input_host()));
    ASSERT_TRUE(pipeline.perform_ft_convolution(FDAS::AllAccelerations));

    ASSERT_TRUE(pipeline.retrieve_tiles(tiles_host()));
    tiles.resize(pipeline.get_tiles_sz());
    std::transform(tiles_host(), tiles_host() + pipeline.get_tiles_sz(), tiles.begin(), float2_to_complex);
    validateInputTiling();

    ASSERT_TRUE(pipeline.retrieve_FOP(fop_host()));
    fop.resize(pipeline.get_fop_sz());
    std::copy(fop_host(), fop_host() + pipeline.get_fop_sz(), fop.begin());
    validateFTConvolution();
}

TEST_P(FDASTest, Harmonic_Summing) {
    FDAS pipeline(std::cerr);
    ASSERT_TRUE(pipeline.initialise_accelerator(bitstream_file,
                                                FDAS::choose_first_platform, FDAS::choose_accelerator_devices,
                                                input.size()));
    validateInputDimensions(pipeline);
    allocateAlignedBuffers(pipeline);

    std::copy(fop_ref.begin(), fop_ref.end(), fop_host());
    ASSERT_TRUE(pipeline.inject_FOP(fop_host()));
    ASSERT_TRUE(pipeline.perform_harmonic_summing(thresholds.data(), FDAS::NegativeAccelerations));

    ASSERT_TRUE(pipeline.retrieve_candidates(detection_location_host(), detection_power_host()));
    detection_location.resize(pipeline.get_candidate_list_sz());
    detection_power.resize(pipeline.get_candidate_list_sz());
    std::copy(detection_location_host(), detection_location_host() + pipeline.get_candidate_list_sz(), detection_location.begin());
    std::copy(detection_power_host(), detection_power_host() + pipeline.get_candidate_list_sz(), detection_power.begin());
    validateHarmonicSumming();
}

TEST_P(FDASTest, FDAS) {
    FDAS pipeline(std::cerr);
    ASSERT_TRUE(pipeline.initialise_accelerator(bitstream_file,
                                                FDAS::choose_first_platform, FDAS::choose_accelerator_devices,
                                                input.size()));
    validateInputDimensions(pipeline);
    allocateAlignedBuffers(pipeline);

    std::transform(templates.begin(), templates.end(), templates_host(), complex_to_float2);
    ASSERT_TRUE(pipeline.upload_templates(templates_host()));
    std::transform(input.begin(), input.end(), input_host(), complex_to_float2);
    ASSERT_TRUE(pipeline.perform_input_tiling(input_host()));
    ASSERT_TRUE(pipeline.perform_ft_convolution(FDAS::PositiveAccelerations));
    ASSERT_TRUE(pipeline.perform_harmonic_summing(thresholds.data(), FDAS::PositiveAccelerations));

    ASSERT_TRUE(pipeline.retrieve_candidates(detection_location_host(), detection_power_host()));
    detection_location.resize(pipeline.get_candidate_list_sz());
    detection_power.resize(pipeline.get_candidate_list_sz());
    std::copy(detection_location_host(), detection_location_host() + pipeline.get_candidate_list_sz(), detection_location.begin());
    std::copy(detection_power_host(), detection_power_host() + pipeline.get_candidate_list_sz(), detection_power.begin());
    validateHarmonicSumming();
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

    FDASTest::bitstream_file = "bin/fdas.aocx";
    FDASTest::templates_file = "../../fdas/tmpl/fdas_templates_85_350_ft_p4.npy";

    return RUN_ALL_TESTS();
}
