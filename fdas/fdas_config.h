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

//   _____ ____    _    ____                     __ _                       _   _
//  |  ___|  _ \  / \  / ___|    ___ ___  _ __  / _(_) __ _ _   _ _ __ __ _| |_(_) ___  _ __
//  | |_  | | | |/ _ \ \___ \   / __/ _ \| '_ \| |_| |/ _` | | | | '__/ _` | __| |/ _ \| '_ \
//  |  _| | |_| / ___ \ ___) | | (_| (_) | | | |  _| | (_| | |_| | | | (_| | |_| | (_) | | | |
//  |_|   |____/_/   \_\____/   \___\___/|_| |_|_| |_|\__, |\__,_|_|  \__,_|\__|_|\___/|_| |_|
//                                                    |___/

// === Inputs ==========================================================================================================

#if defined(FDAS_FPGA)

// Number of channels in the input spectrum
#define N_CHANNELS                     (1 << 22)

// The filter templates correspond to different accelerations to test for. There are two equally-sized groups of
// templates which only differ in the sign of the acceleration. Additionally, one filter, located between the groups,
// just forwards the input signal.
#define N_FILTERS_PER_ACCEL_SIGN       (42)
#define N_FILTERS                      (N_FILTERS_PER_ACCEL_SIGN + 1 + N_FILTERS_PER_ACCEL_SIGN)

// Maximum number of filter taps
#define N_TAPS                         (421)

// Set how many filters are processed in parallel, and in consequence, how many batches are needed to apply all filters.
// Currently, the batch size must evenly divide the total number of filters
#define N_FILTERS_PARALLEL             (5)
#define N_FILTER_BATCHES               (N_FILTERS / N_FILTERS_PARALLEL)

#elif defined(FDAS_EMU)

#define N_CHANNELS                     (1 << 16)
#define N_FILTERS_PER_ACCEL_SIGN       (10)
#define N_FILTERS                      (N_FILTERS_PER_ACCEL_SIGN + 1 + N_FILTERS_PER_ACCEL_SIGN)
#define N_TAPS                         (106)
#define N_FILTERS_PARALLEL             (3)
#define N_FILTER_BATCHES               (N_FILTERS / N_FILTERS_PARALLEL)

#else

#error("FDAS mode undefined")

#endif

// === FFT engine configuration ========================================================================================

// Size of the transform -- must be a compile-time constant. The maximum size currently supported by the engine is 2^12;
// larger transforms would require additional precomputed twiddle factors.
#define FFT_N_POINTS_LOG               (11)
#define FFT_N_POINTS                   (1 << FFT_N_POINTS_LOG)

// The engine is __hard-wired__ to processes 4 points in parallel. DO NOT CHANGE unless you also provide a suitable,
// alternative engine implementation. This requires structural modifications that go beyond the scope of a few #defines.
#define FFT_N_PARALLEL_LOG             (2)
#define FFT_N_PARALLEL                 (1 << FFT_N_PARALLEL_LOG)

// Number of points that arrive at each input terminal
#define FFT_N_POINTS_PER_TERMINAL_LOG  (FFT_N_POINTS_LOG - FFT_N_PARALLEL_LOG)
#define FFT_N_POINTS_PER_TERMINAL      (1 << FFT_N_POINTS_PER_TERMINAL_LOG)

// === Frequency-domain FIR filter implementation with overlap-save algorithm ==========================================

// The tile size for the overlap-save algorithm must match the FFT size
#define FDF_TILE_SZ                    (FFT_N_POINTS)

// Amount of overlap between neighbouring tiles (also, zero-padding for the first tile). Only the unique parts will be
// used later on.
#define FDF_TILE_OVERLAP               (N_TAPS - 1)
#define FDF_TILE_PAYLOAD               (FDF_TILE_SZ - FDF_TILE_OVERLAP)

// Number of tiles required to handle the input spectrum
#if N_CHANNELS % FDF_TILE_PAYLOAD == 0
#define FDF_N_TILES                    (N_CHANNELS / FDF_TILE_PAYLOAD)
#else
#define FDF_N_TILES                    (N_CHANNELS / FDF_TILE_PAYLOAD + 1)
#endif

// Buffer size required to store zero-padded input
#define FDF_PADDED_INPUT_SZ            (FDF_TILE_OVERLAP + FDF_N_TILES * FDF_TILE_PAYLOAD)

// Buffer size required to store zero-padded/partially overlapped and tiled input
#define FDF_TILED_INPUT_SZ             (FDF_N_TILES * FDF_TILE_SZ)

// Buffer size to hold all filter coefficients
#define FDF_TEMPLATES_SZ               (N_FILTERS * FDF_TILE_SZ)

// === Filter-output plane =============================================================================================

// Size of the filter-output plane (and of the harmonic planes as well)
#define FOP_SZ                         (1l * N_FILTERS * N_CHANNELS)

// === Harmonic summing ================================================================================================

// Number of harmonic planes to consider, i.e. FOP = HP_1, HP_2, ..., HP_{HMS_N_PLANES}
#define HMS_N_PLANES                   (8)

// Maximum number of detections, i.e. pulsar candidates, recorded per harmonic plane
#define HMS_DETECTION_SZ               (64)

// If true, explicitly write harmonic planes to memory, otherwise compare FOP amplitudes to thresholds on-the-fly
#define HMS_STORE_PLANES               (false)

// Buffer size to store the harmonic planes (-1 because the FOP is already in its own buffer).
#define HMS_PLANES_SZ                  (1l * (HMS_N_PLANES - 1) * FOP_SZ)

// Format used to encode a detection location in a 32-bit unsigned integer:
//   ┌───┬───────┬──────────────────────┐
//   │ k │filter │       channel        │
//   └───┴───────┴──────────────────────┘
//  31 29|28   22|21                    0
#define HMS_ENCODE_LOCATION(k, f, c)   ((((k - 1) & 0x7) << 29) | (((f + N_FILTERS_PER_ACCEL_SIGN) & 0x7f) << 22) | (c & 0x3fffff))
#define HMS_INVALID_LOCATION           (HMS_ENCODE_LOCATION(1, N_FILTERS_PER_ACCEL_SIGN + 1, 0))
#define HMS_GET_LOCATION_HARMONIC(loc) (((loc >> 29) & 0x7) + 1)
#define HMS_GET_LOCATION_FILTER(loc)   (((loc >> 22) & 0x7f) - N_FILTERS_PER_ACCEL_SIGN)
#define HMS_GET_LOCATION_CHANNEL(loc)  (loc & 0x3fffff)

// Parallelisation factor in the HMS_UNROLL approach. Always change both macros!
#define HMS_X                          (4)
#define HMS_CHANNEL_LOOP_UNROLL        _Pragma("unroll 4")

// === Output ==========================================================================================================

// Maximum number of pulsar candidates returned from the FDAS module
#define N_CANDIDATES                   (HMS_N_PLANES * HMS_DETECTION_SZ)

// === Misc ============================================================================================================

// Define a value that we can be used directly in C++ code
#if defined(FDAS_FPGA)
#define TARGET_IS_FPGA                 (true)
#else
#define TARGET_IS_FPGA                 (false)
#endif
