
__attribute__((reqd_work_group_size(${fft_n_points_per_terminal}, 1, 1)))
__attribute__((uses_global_work_offset(0)))
kernel void mux_and_mult(global float2 * restrict tiles,
                         global float2 * restrict templates)
{
    uint batch = get_group_id(1) * ${fdf_group_sz};
    uint tile = get_group_id(0);
    uint step = get_local_id(0);

    #pragma unroll
    for (uint f = 0; f < ${fdf_group_sz}; ++f) {
        #pragma unroll
        for (uint p = 0; p < ${fft_n_parallel}; ++p) {
            float2 value = tiles[tile * ${fdf_tile_sz} + step * ${fft_n_parallel} + p];
            float2 coeff = templates[(batch + f) * ${fdf_tile_sz} + step * ${fft_n_parallel} + p];
            float2 prod = complex_mult(value, coeff);
            WRITE_CHANNEL(ifft_in[f][p], prod);
        }
    }
}

__attribute__((reqd_work_group_size(${fft_n_points_per_terminal}, 1, 1)))
__attribute__((uses_global_work_offset(0)))
kernel void square_and_discard(global float * restrict fop,
                               const uint fop_row_sz) // temporary!
{
    float buf[${fdf_group_sz}][${fft_n_parallel}];

    uint batch = get_group_id(1) * ${fdf_group_sz};
    uint tile = get_group_id(0);
    uint step = get_local_id(0);

    #pragma unroll
    for (uint f = 0; f < ${fdf_group_sz}; ++f) {
        #pragma unroll
        for (uint p = 0; p < ${fft_n_parallel}; ++p)
            buf[f][p] = power_norm(READ_CHANNEL(ifft_out[f][p]));
    }

    #pragma unroll
    for (uint f = 0; f < ${fdf_group_sz}; ++f) {
        #pragma unroll
        for (uint p = 0; p < ${fft_n_parallel}; ++p) {
            uint q = bit_reversed(p, ${fft_n_parallel_log});

            int element = p * ${fft_n_points_per_terminal} + step - ${fdf_tile_overlap};
            if (element >= 0)
                fop[(batch + f) * fop_row_sz + tile * ${fdf_tile_payload} + element] = buf[f][q];
        }
    }
}
