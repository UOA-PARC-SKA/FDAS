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

    std::string det_pwr_file(bool ref = false) { return GetParam() + "/det_pwr" + (ref ? "_ref" : "") + ".npy"; }

    FDAS::InputType input;
    FDAS::ShapeType input_shape;

    FDAS::TemplatesType templates;
    FDAS::ShapeType templates_shape;

    FDAS::TilesType tiles, tiles_ref;
    FDAS::ShapeType tiles_shape, tiles_shape_ref;

    FDAS::FOPType fop, fop_ref;
    FDAS::ShapeType fop_shape, fop_shape_ref;

    FDAS::ThreshType thresholds;
    FDAS::ShapeType thresholds_shape;

    FDAS::HPType harmonic_planes, harmonic_planes_ref;
    FDAS::ShapeType harmonic_planes_shape, harmonic_planes_shape_ref;

    FDAS::DetLocType detection_location, detection_location_ref;
    FDAS::ShapeType detection_location_shape, detection_location_ref_shape;

    FDAS::DetPwrType detection_power, detection_power_ref;
    FDAS::ShapeType detection_power_shape, detection_power_ref_shape;

    void SetUp() override {
        bool fortran_order = false; // library wants this as a reference
        npy::LoadArrayFromNumpy(input_file(), input_shape, fortran_order, input);
        npy::LoadArrayFromNumpy(templates_file, templates_shape, fortran_order, templates);
        npy::LoadArrayFromNumpy(tiles_file(true), tiles_shape_ref, fortran_order, tiles_ref);
        npy::LoadArrayFromNumpy(fop_file(true), fop_shape_ref, fortran_order, fop_ref);
        npy::LoadArrayFromNumpy(thrsh_file(), thresholds_shape, fortran_order, thresholds);
        npy::LoadArrayFromNumpy(det_loc_file(true), detection_location_ref_shape, fortran_order, detection_location_ref);
        npy::LoadArrayFromNumpy(det_pwr_file(true), detection_power_ref_shape, fortran_order, detection_power_ref);
        if (HMS_STORE_PLANES)
            npy::LoadArrayFromNumpy(hps_file(true), harmonic_planes_shape_ref, fortran_order, harmonic_planes_ref);
    }
};

TEST_P(FDASTest, FT_Convolution) {
    FDAS pipeline(std::cerr);
    ASSERT_TRUE(pipeline.initialise_accelerator(bitstream_file, FDAS::choose_first_platform, FDAS::choose_accelerator_devices, input.size()));

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

TEST_P(FDASTest, Harmonic_Summing) {
    FDAS pipeline(std::cerr);
    ASSERT_TRUE(pipeline.initialise_accelerator(bitstream_file, FDAS::choose_first_platform, FDAS::choose_accelerator_devices, input.size()));

    ASSERT_TRUE(pipeline.inject_FOP(fop_ref, fop_shape_ref));

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

    ASSERT_TRUE(pipeline.retrieve_candidates(detection_location, detection_location_shape, detection_power, detection_power_shape));
    // store data as downloaded from the device (i.e. before filtering invalid slots)
    npy::SaveArrayAsNumpy(det_loc_file(), false, detection_location_shape.size(), detection_location_shape.data(), detection_location);
    npy::SaveArrayAsNumpy(det_pwr_file(), false, detection_power_shape.size(), detection_power_shape.data(), detection_power);

    auto loc_it = detection_location.begin();
    auto pwr_it = detection_power.begin();
    while (loc_it != detection_location.end() && pwr_it != detection_power.end()) {
        auto loc = *loc_it;
        if (loc == HMS_INVALID_LOCATION) {
            loc_it = detection_location.erase(loc_it);
            pwr_it = detection_power.erase(pwr_it);
        } else {
            ++loc_it, ++pwr_it;
        }
    }
    EXPECT_LE(detection_location.size(), detection_location_ref.size());
    EXPECT_GE(detection_location.size(), 1);

    int n_non_cands = 0;
    for (loc_it = detection_location.begin(), pwr_it = detection_power.begin();
         loc_it != detection_location.end() && pwr_it != detection_power.end();
         ++loc_it, ++pwr_it) {
        auto loc = *loc_it;
        auto pwr = *pwr_it;

        auto it = std::find(detection_location_ref.begin(), detection_location_ref.end(), loc);
        if (it == detection_location_ref.end()) {
            ++n_non_cands;
            continue;
        }
        auto dist = std::distance(detection_location_ref.begin(), it);
        auto pwr_ref = detection_power_ref[dist];
        EXPECT_TRUE(fabs(pwr - pwr_ref) < tolerance);
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

    FDASTest::bitstream_file = "bin/fdas.aocx";
    FDASTest::templates_file = "../../fdas/tmpl/fdas_templates_85_350_ft_p4.npy";

    return RUN_ALL_TESTS();
}
