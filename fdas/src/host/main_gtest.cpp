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
#include <string>
#include <vector>

#include "libnpy/npy.hpp"
#include "gtest/gtest.h"

#include "FDAS.h"
#include "gen_info.h"

using namespace GenInfo;

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

    // XXX: std::align is missing in the ancient gcc version I am using...
    template<typename T> T* align(T* ptr, size_t to_bytes) {
        auto uint_ptr = reinterpret_cast<std::uintptr_t>(ptr);
        auto offset = uint_ptr & (to_bytes - 1);
        if (offset == 0)
            return ptr;
        auto aligned = uint_ptr - offset + to_bytes;
        return reinterpret_cast<T*>(aligned);
    }

    InputType input;
    ShapeType input_shape;

    TemplatesType templates;
    ShapeType templates_shape;

    TilesType tiles, tiles_ref;
    ShapeType tiles_ref_shape;

    FOPType fop, fop_ref;
    ShapeType fop_ref_shape;

    ThreshType thresholds;
    ShapeType thresholds_shape;

    DetLocType detection_location, detection_location_ref;
    ShapeType detection_location_ref_shape;

    DetPwrType detection_power, detection_power_ref;
    ShapeType detection_power_ref_shape;

    void SetUp() override {
        bool fortran_order = false; // library wants this as a reference
        npy::LoadArrayFromNumpy(input_file(), input_shape, fortran_order, input);
        npy::LoadArrayFromNumpy(templates_file, templates_shape, fortran_order, templates);
        npy::LoadArrayFromNumpy(tiles_file(true), tiles_ref_shape, fortran_order, tiles_ref);
        npy::LoadArrayFromNumpy(fop_file(true), fop_ref_shape, fortran_order, fop_ref);
        npy::LoadArrayFromNumpy(thrsh_file(), thresholds_shape, fortran_order, thresholds);
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

    ASSERT_TRUE(pipeline.upload_templates(reinterpret_cast<cl_float2*>(templates.data())));
    ASSERT_TRUE(pipeline.perform_input_tiling(reinterpret_cast<cl_float2 *>(input.data())));
    ASSERT_TRUE(pipeline.perform_ft_convolution(FDAS::AllAccelerations));

    tiles.resize(pipeline.get_tiles_sz());
    ASSERT_TRUE(pipeline.retrieve_tiles(reinterpret_cast<cl_float2*>(tiles.data())));
    validateInputTiling();

    fop.resize(pipeline.get_fop_sz());
    ASSERT_TRUE(pipeline.retrieve_FOP(reinterpret_cast<cl_float*>(fop.data())));
    validateFTConvolution();
}

TEST_P(FDASTest, Harmonic_Summing) {
    FDAS pipeline(std::cerr);

    ASSERT_TRUE(pipeline.initialise_accelerator(bitstream_file,
                                                FDAS::choose_first_platform, FDAS::choose_accelerator_devices,
                                                input.size()));
    validateInputDimensions(pipeline);

    fop.resize(pipeline.get_fop_sz());
    ASSERT_TRUE(pipeline.inject_FOP(reinterpret_cast<cl_float*>(fop_ref.data())));
    ASSERT_TRUE(pipeline.perform_harmonic_summing(reinterpret_cast<cl_float*>(thresholds.data()), FDAS::NegativeAccelerations));

    detection_location.resize(pipeline.get_candidate_list_sz());
    detection_power.resize(pipeline.get_candidate_list_sz());
    ASSERT_TRUE(pipeline.retrieve_candidates(reinterpret_cast<cl_uint*>(detection_location.data()),
                                             reinterpret_cast<cl_float*>(detection_power.data())));
    validateHarmonicSumming();
}

TEST_P(FDASTest, FDAS) {
    FDAS pipeline(std::cerr);
    ASSERT_TRUE(pipeline.initialise_accelerator(bitstream_file,
                                                FDAS::choose_first_platform, FDAS::choose_accelerator_devices,
                                                input.size()));
    validateInputDimensions(pipeline);

    ASSERT_TRUE(pipeline.upload_templates(reinterpret_cast<cl_float2*>(templates.data())));
    ASSERT_TRUE(pipeline.perform_input_tiling(reinterpret_cast<cl_float2 *>(input.data())));
    ASSERT_TRUE(pipeline.perform_ft_convolution(FDAS::PositiveAccelerations));
    ASSERT_TRUE(pipeline.perform_harmonic_summing(reinterpret_cast<cl_float*>(thresholds.data()), FDAS::PositiveAccelerations));

    detection_location.resize(pipeline.get_candidate_list_sz());
    detection_power.resize(pipeline.get_candidate_list_sz());
    ASSERT_TRUE(pipeline.retrieve_candidates(reinterpret_cast<cl_uint*>(detection_location.data()),
                                             reinterpret_cast<cl_float*>(detection_power.data())));
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
