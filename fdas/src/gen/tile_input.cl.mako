
## TODO derive the float8 type automatically
## TODO write helper/lambda for the subvector access

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void load_input(global float * restrict input,
                       const uint input_sz)
{
    for (uint i = 0; i < input_sz / ${fft_n_parallel}; ++i) {
        float8 load = vload8(i, input);
    % for p in range(fft_n_parallel):
        WRITE_CHANNEL(load_to_tile[${p}], load.${f"s{p * 2}{p * 2 + 1}"});
    % endfor
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void tile(const uint n_tiles) {
<%
    from cl_codegen import bit_rev

    n_steps = fft_n_points_per_terminal
    n_steps_per_chunk = n_steps // fft_n_parallel
    n_steps_for_overlap = fdf_tile_overlap // fft_n_parallel
%>\
    float8 overlap_sr[${n_steps_for_overlap + 1}];
% for p in range(fft_n_parallel):
    float2 __attribute__((bank_bits(${fft_n_points_per_terminal_log}))) chunk_buf_${p}[2][${fft_n_points_per_terminal}];
% endfor

    #pragma loop_coalesce
    for (uint t = 0; t < n_tiles + 1; ++t) {
        for (uint s = 0; s < ${n_steps}; ++s) {
            if (t >= 1) {
            % for p in range(fft_n_parallel):
                WRITE_CHANNEL(fft_in[${p}], chunk_buf_${bit_rev(p, fft_n_parallel_log)}[1 - (t & 1)][s]);
            % endfor
            }

            if (t < n_tiles) {
                float2 input[${fft_n_parallel}];
                if (s < ${n_steps_for_overlap}) {
                % for p in range(fft_n_parallel):
                    input[${p}] = t >= 1 ? overlap_sr[0].${f"s{p * 2}{p * 2 + 1}"} : 0;
                % endfor
                }
                else {
                    #pragma unroll
                    for (uint p = 0; p < ${fft_n_parallel}; ++p)
                        input[p] = READ_CHANNEL(load_to_tile[p]);
                }

                uint chunk = s / ${n_steps_per_chunk};
                uint bundle = s % ${n_steps_per_chunk};

                switch (chunk) {
                % for p in range(fft_n_parallel):
                    case ${p}:
                        #pragma unroll
                        for (uint p = 0; p < ${fft_n_parallel}; ++p)
                            chunk_buf_${p}[t & 1][bundle * ${fft_n_parallel} + p] = input[p];
                        break;
                % endfor
                    default:
                        break;
                }

                if (s >= ${n_steps - n_steps_for_overlap}) {
                    float8 ins_val;
                % for p in range(fft_n_parallel):
                    ins_val.${f"s{p * 2}{p * 2 + 1}"} = input[${p}];
                % endfor
                    overlap_sr[${n_steps_for_overlap}] = ins_val;
                }
            }

            #pragma unroll
            for (uint x = 0; x < ${n_steps_for_overlap}; ++x)
                overlap_sr[x] = overlap_sr[x + 1];
        }
    }
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
