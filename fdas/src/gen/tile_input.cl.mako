
<%
    from cl_codegen import bit_rev

    n_steps = fft_n_points_per_terminal
    n_steps_per_chunk = n_steps // fft_n_parallel
    n_steps_for_overlap = fdf_tile_overlap // fft_n_parallel
%>\

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void load_input(global float2x4 * restrict input,
                       const uint input_sz)
{
    for (uint i = 0; i < input_sz / ${fft_n_parallel}; ++i) {
        float2x4 load = input[i];
        WRITE_CHANNEL(load_to_tile, load);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void tile(const uint n_tiles)
{
    float2x4 overlap_sr[${n_steps_for_overlap + 1}];
% for p in range(fft_n_parallel):
    float2 __attribute__((bank_bits(${fft_n_points_per_terminal_log}))) chunk_buf_${p}[2][${fft_n_points_per_terminal}];
% endfor

    #pragma loop_coalesce
    for (uint t = 0; t < n_tiles + 1; ++t) {
        for (uint s = 0; s < ${n_steps}; ++s) {
            if (t >= 1) {
                float2x4 output;
            % for p in range(fft_n_parallel):
                output.i[${bit_rev(p, fft_n_parallel_log)}] = chunk_buf_${p}[1 - (t & 1)][s];
            % endfor
                WRITE_CHANNEL(fft_in, output);
            }

            float2x4 input = {${", ".join(["0"] * fft_n_parallel)}};
            if (t < n_tiles) {
                if (s < ${n_steps_for_overlap}) {
                    if (t >= 1)
                        input = overlap_sr[0];
                }
                else {
                    input = READ_CHANNEL(load_to_tile);
                }

                uint chunk = s / ${n_steps_per_chunk};
                uint bundle = s % ${n_steps_per_chunk};

                switch (chunk) {
                % for p in range(fft_n_parallel):
                    case ${p}:
                        #pragma unroll
                        for (uint p = 0; p < ${fft_n_parallel}; ++p)
                            chunk_buf_${p}[t & 1][bundle * ${fft_n_parallel} + p] = input.i[p];
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
    #pragma loop_coalesce
    for (uint t = 0; t < n_tiles; ++t) {
        for (uint s = 0; s < ${n_steps}; ++s) {
            float2x4 input = READ_CHANNEL(fft_out);
            tiles[t * ${fdf_tile_sz // fft_n_parallel} + s] = input;
        }
    }
}
