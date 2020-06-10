//   _____ ____    _    ____                     __ _                       _   _
//  |  ___|  _ \  / \  / ___|    ___ ___  _ __  / _(_) __ _ _   _ _ __ __ _| |_(_) ___  _ __
//  | |_  | | | |/ _ \ \___ \   / __/ _ \| '_ \| |_| |/ _` | | | | '__/ _` | __| |/ _ \| '_ \
//  |  _| | |_| / ___ \ ___) | | (_| (_) | | | |  _| | (_| | |_| | | | (_| | |_| | (_) | | | |
//  |_|   |____/_/   \_\____/   \___\___/|_| |_|_| |_|\__, |\__,_|_|  \__,_|\__|_|\___/|_| |_|
//                                                    |___/

// === Inputs ==========================================================================================================

// Number of channels in the input spectrum
#define N_CHANNELS                     (1 << 21)

// The filter templates correspond to different accelerations to test for. There are two equally-sized groups of
// templates which only differ in the sign of the acceleration. Additionally, one filter, located between the groups,
// just forwards the input signal.
#define FILTER_GROUP_SZ                (42)
#define N_FILTERS                      (FILTER_GROUP_SZ + 1 + FILTER_GROUP_SZ)

// Maximum number of filter taps
#define N_TAPS                         (421)

// === FFT engine configuration ========================================================================================

// Size of the transform -- must be a compile-time constant. The maximum size currently supported by the engine is 2^12;
// larger transforms would require additional precomputed twiddle factors.
#define FFT_N_POINTS_LOG               (11)
#define FFT_N_POINTS                   (1 << FFT_N_POINTS_LOG)

// The engine is __hard-wired__ to processes 4 points in parallel. DO NOT CHANGE unless you also provide a suitable,
// alternative engine implementation. This requires structural modifications that go beyond the scope of a few #defines.
#define FFT_N_PARALLEL                 (4)

// Number of steps required to transform the entire input
#define FFT_N_STEPS                    (FFT_N_POINTS / FFT_N_PARALLEL)

// The engine is pipelined and accepts new inputs in each step (II=1), but has the following latency:
#define FFT_LATENCY                    (FFT_N_STEPS - 1)

// === Frequency-domain FIR filter implementation with overlap-save algorithm ==========================================

// The tile size for the overlap-save algorithm must match the FFT size
#define FDF_TILE_SZ                    (FFT_N_POINTS)

// Amount of overlap between neighbouring tiles (also, zero-padding for the first tile). Only the unique parts will be
// used later on.
#define FDF_TILE_OVERLAP               (N_TAPS - 1)
#define FDF_TILE_PAYLOAD               (FDF_TILE_SZ - FDF_TILE_OVERLAP)

// Number of tiles required to handle the input spectrum
#define FDF_N_TILES                    (N_CHANNELS / FDF_TILE_PAYLOAD)

// Number of channels that will actually be processed (some of high-frequency channels will be discarded)
#define FDF_INPUT_SZ                   (FDF_N_TILES * FDF_TILE_PAYLOAD)

// Temporary storage required to apply one filter to all input tiles (element-wise multiplication in frequency domain)
#define FDF_INTERMEDIATE_SZ            (FDF_N_TILES * FDF_TILE_SZ)

// Result size after applying one filter to all input tiles and discarding the overlapping elements
#define FDF_OUTPUT_SZ                  (FDF_INPUT_SZ)

// === NDRange kernel configuration ====================================================================================

// Number of tiles (and inputs) handled in each work group
#define NDR_N_TILES_PER_WORK_GROUP     (4)
#define NDR_N_POINTS_PER_WORK_GROUP    (FDF_TILE_SZ * NDR_N_TILES_PER_WORK_GROUP)

// The FFT engine's inputs must arrive at the same time, and therefore should be processed by a single work item. This
// determines how many work items are required to process one tile.
#define NDR_N_POINTS_PER_WORK_ITEM     (FFT_N_PARALLEL)
#define NDR_N_WORK_ITEMS_PER_TILE      (FDF_TILE_SZ / NDR_N_POINTS_PER_WORK_ITEM)

// The work group size follows from the parameters above
#define NDR_WORK_GROUP_SZ              (NDR_N_TILES_PER_WORK_GROUP * NDR_N_WORK_ITEMS_PER_TILE)

// === Filter-output plane =============================================================================================

// Size of the filter-output plane (and of the harmonic planes as well)
#define FOP_SZ                         (N_FILTERS * FDF_OUTPUT_SZ)

// === Harmonic summing ================================================================================================

// Number of harmonic planes to consider
#define HMS_N_PLANES                   (8)

// Maximum number of detections, i.e. pulsar candidates, recorded per harmonic plane
#define HMS_DETECTION_SZ               (40)

// === Output ==========================================================================================================

// Maximum number of pulsar candidates returned from the FDAS module
#define N_CANDIDATES                   (HMS_N_PLANES * HMS_DETECTION_SZ)
