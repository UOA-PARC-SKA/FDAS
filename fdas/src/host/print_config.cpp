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

#include <iostream>
#include <iomanip>

#include "fdas_config.h"

using namespace std;

int main() {
#define print_config(X) cout << setw(29) << #X << setw(12) << X << endl
    print_config(N_CHANNELS);
    print_config(N_FILTERS_PER_ACCEL_SIGN);
    print_config(N_FILTERS);
    print_config(N_TAPS);
    print_config(N_FILTERS_PARALLEL);
    print_config(N_FILTER_BATCHES);
    print_config(FFT_N_POINTS_LOG);
    print_config(FFT_N_POINTS);
    print_config(FFT_N_PARALLEL_LOG);
    print_config(FFT_N_PARALLEL);
    print_config(FFT_N_POINTS_PER_TERMINAL_LOG);
    print_config(FFT_N_POINTS_PER_TERMINAL);
    print_config(FDF_TILE_SZ);
    print_config(FDF_TILE_OVERLAP);
    print_config(FDF_TILE_PAYLOAD);
    print_config(FDF_N_TILES);
    print_config(FDF_INPUT_SZ);
    print_config(FDF_PADDED_INPUT_SZ);
    print_config(FDF_TILED_INPUT_SZ);
    print_config(FDF_OUTPUT_SZ);
    print_config(FDF_TEMPLATES_SZ);
    print_config(FOP_SZ);
    print_config(HMS_N_PLANES);
    print_config(HMS_DETECTION_SZ);
    print_config(HMS_STORE_PLANES);
    print_config(N_CANDIDATES);
#undef print_config
    return 0;
}
