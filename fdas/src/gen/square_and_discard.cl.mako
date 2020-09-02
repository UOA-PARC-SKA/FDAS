
<%
    from cl_codegen import bit_rev

    n_steps = fft_n_points_per_terminal
    n_steps_per_chunk = fft_n_points_per_terminal // fft_n_parallel
    n_steps_for_overlap = fdf_tile_overlap // fft_n_parallel
%>\
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void square_and_discard_${engine}(global float4 * restrict fop_A,
                                 const uint fop_offset,
                                 const uint n_tiles
                             %if not hms_dual_channel:
                                 const uint n_tiles)
                             % else:
                                 const uint n_tiles,
                                 global float4 * restrict fop_B,
                                 const uint use_second_bank)
                             %endif
{
    const float4 zeros = {${", ".join(["0"] * fft_n_parallel)}};

% for p in range(fft_n_parallel):
    float __attribute__((bank_bits(${fft_n_points_per_terminal_log}))) chunk_buf_${p}[2][${fft_n_points_per_terminal}];
% endfor

    uint fop_idx = 0;
    #pragma loop_coalesce
    for (uint tile = 0; tile < n_tiles + 1; ++tile) {
        for (uint step = 0; step < ${n_steps}; ++step) {
            if (tile >= 1 && step >= ${n_steps_for_overlap}) {
                uint chunk = step / ${n_steps_per_chunk};
                uint pack = step % ${n_steps_per_chunk};

                float4 store = zeros;
                switch (chunk) {
                % for p in range(fft_n_parallel):
                    case ${p}:
                    % for pp in range(fft_n_parallel):
                        store.s${pp} = chunk_buf_${p}[1 - (tile & 1)][pack * ${fft_n_parallel} + ${pp}];
                    % endfor
                        break;
                % endfor
                    default:
                        break;
                }

                fop_A[fop_offset + fop_idx] = store;
            % if hms_dual_channel:
                if (use_second_bank)
                    fop_B[fop_offset + fop_idx] = store;
            % endif
                ++fop_idx;
            }

            if (tile < n_tiles) {
                float2x4 read = READ_CHANNEL(ifft_out[${engine}]);
                float4 norm = power_norm4(read);
            % for p in range(fft_n_parallel):
                chunk_buf_${p}[tile & 1][step] = norm.s${bit_rev(p, fft_n_parallel_log)};
            % endfor
            }
        }
    }
}
