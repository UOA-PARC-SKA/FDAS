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

// The templates correspond to different accelerations to test for. There are two equally-sized sets of templates which
// only differ in the sign of the acceleration. Additionally, one template, located between the groups, just forwards
// the input signal.
#define N_TMPL_PER_ACCEL_SIGN          (42)
#define N_TEMPLATES                    (N_TMPL_PER_ACCEL_SIGN + 1 + N_TMPL_PER_ACCEL_SIGN)

// Maximum length (= number of coefficients) across all templates
#define MAX_TEMPLATE_LEN               (421)

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

// === FT convolution implementation with overlap-save algorithm =======================================================

// The tile size for the overlap-save algorithm must match the FFT size
#define FTC_TILE_SZ                    (FFT_N_POINTS)

// Amount of overlap between neighbouring tiles (also, zero-padding for the first tile). Only the unique parts will be
// used later on.
#define FTC_TILE_OVERLAP               (MAX_TEMPLATE_LEN - 1)
#define FTC_TILE_PAYLOAD               (FTC_TILE_SZ - FTC_TILE_OVERLAP)

// Set how many templates are processed in parallel
#define FTC_GROUP_SZ                   (4)

// === Harmonic summing ================================================================================================

// Number of harmonic planes to consider, i.e. FOP = HP_1, HP_2, ..., HP_{HMS_N_PLANES}
#define HMS_N_PLANES                   (8)

// Maximum number of detections, i.e. pulsar candidates, recorded per harmonic plane
#define HMS_DETECTION_SZ               (64)

// If true, explicitly write harmonic planes to memory, otherwise compare FOP values to thresholds on-the-fly
#define HMS_STORE_PLANES               (false)

// Format used to encode a detection location in a 32-bit unsigned integer:
//   ┌───┬───────┬──────────────────────┐
//   │ k │templ. │    frequency bin     │
//   └───┴───────┴──────────────────────┘
//  31 29|28   22|21                    0
#define HMS_ENCODE_LOCATION(harm, tmpl, freq) \
    ((((harm - 1) & 0x7) << 29) | (((tmpl + N_TMPL_PER_ACCEL_SIGN) & 0x7f) << 22) | (freq & 0x3fffff))
#define HMS_INVALID_LOCATION           (HMS_ENCODE_LOCATION(1, N_TMPL_PER_ACCEL_SIGN + 1, 0))

// Parallelisation factor in the HMS_UNROLL approach. Always change both macros!
#define HMS_X                          (4)
#define HMS_CHANNEL_LOOP_UNROLL        _Pragma("unroll 4")

// === Output ==========================================================================================================

// Maximum number of pulsar candidates returned from the FDAS module
#define N_CANDIDATES                   (HMS_N_PLANES * HMS_DETECTION_SZ)
