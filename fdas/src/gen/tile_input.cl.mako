
<%
    from cl_codegen import bit_rev

    n_steps = fft_n_points_per_terminal
    n_steps_per_chunk = fft_n_points_per_terminal // fft_n_parallel
    n_steps_for_overlap = fdf_tile_overlap // fft_n_parallel
%>\
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void load_input(global float2x4 * restrict input,
                       const uint n_packs)
{
    for (uint pack = 0; pack < n_packs; ++pack) {
        float2x4 load = input[pack];
        WRITE_CHANNEL(load_to_tile, load);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void tile(const uint n_tiles)
{
    const float2x4 zeros = {${", ".join(["0"] * fft_n_parallel)}};

    float2x4 overlap_sr[${n_steps_for_overlap + 1}];
% for p in range(fft_n_parallel):
    float2 __attribute__((bank_bits(${fft_n_points_per_terminal_log}))) chunk_buf_${p}[2][${fft_n_points_per_terminal}];
% endfor

    for (uint tile = 0; tile < n_tiles + 1; ++tile) {
        for (uint step = 0; step < ${n_steps}; ++step) {
            if (tile >= 1) {
                float2x4 output;
            % for p in range(fft_n_parallel):
                output.i[${bit_rev(p, fft_n_parallel_log)}] = chunk_buf_${p}[1 - (tile & 1)][step];
            % endfor
                WRITE_CHANNEL(fft_in, output);
            }

            float2x4 input = zeros;
            if (tile < n_tiles) {
                if (step < ${n_steps_for_overlap}) {
                    if (tile >= 1)
                        input = overlap_sr[0];
                }
                else {
                    input = READ_CHANNEL(load_to_tile);
                }

                uint chunk = step / ${n_steps_per_chunk};
                uint pack = step % ${n_steps_per_chunk};

                switch (chunk) {
                % for p in range(fft_n_parallel):
                    case ${p}:
                        #pragma unroll
                        for (uint p = 0; p < ${fft_n_parallel}; ++p)
                            chunk_buf_${p}[tile & 1][pack * ${fft_n_parallel} + p] = input.i[p];
                        break;
                % endfor
                    default:
                        break;
                }
            }

            overlap_sr[${n_steps_for_overlap}] = input;

            #pragma unroll
            for (uint x = 0; x < ${n_steps_for_overlap}; ++x)
                overlap_sr[x] = overlap_sr[x + 1];
        }
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void store_tiles(global float2x4 * restrict tiles,
                        const uint n_tiles)
{
    for (uint tile = 0; tile < n_tiles; ++tile) {
        for (uint step = 0; step < ${n_steps}; ++step) {
            float2x4 read = READ_CHANNEL(fft_out);
            tiles[tile * ${fdf_tile_sz // fft_n_parallel} + step] = read;
        }
    }
}