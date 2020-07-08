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
