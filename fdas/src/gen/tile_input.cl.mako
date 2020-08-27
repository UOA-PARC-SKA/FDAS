
__attribute__((reqd_work_group_size(${fft_n_points_per_terminal}, 1, 1)))
__attribute__((uses_global_work_offset(0)))
kernel void tile_input(global float2 * restrict input)
{
## could easily generate the bank_bits argument, but this probably removed in the next version
    local float2 __attribute__((bank_bits(10,9))) buf[${fft_n_parallel}][${fft_n_points_per_terminal}];

    uint tile = get_group_id(0);
    uint step = get_local_id(0);
    uint chunk = step / ${fft_n_points_per_terminal // fft_n_parallel};
    uint chunk_rev = bit_reversed(chunk, ${fft_n_parallel_log});
    uint bundle = step % ${fft_n_points_per_terminal // fft_n_parallel};

    #pragma unroll
    for (uint p = 0; p < ${fft_n_parallel}; ++p)
        buf[chunk_rev][bundle * ${fft_n_parallel} + p] = input[tile * ${fdf_tile_payload} + chunk * ${fft_n_points_per_terminal} + bundle * ${fft_n_parallel} + p];

    barrier(CLK_LOCAL_MEM_FENCE);

    #pragma unroll
    for (uint p = 0; p < ${fft_n_parallel}; ++p)
        WRITE_CHANNEL(fft_in[p], buf[p][step]);
}

__attribute__((reqd_work_group_size(${fft_n_points_per_terminal}, 1, 1)))
__attribute__((uses_global_work_offset(0)))
kernel void store_tiles(global float2 * restrict tiles)
{
    uint tile = get_group_id(0);
    uint step = get_local_id(0);

    #pragma unroll
    for (uint p = 0; p < ${fft_n_parallel}; ++p)
       tiles[tile * ${fdf_tile_sz} + step * ${fft_n_parallel} + p] = READ_CHANNEL(fft_out[p]);
}
