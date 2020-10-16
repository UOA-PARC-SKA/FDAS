
<%
    from cl_codegen import bit_rev

    n_steps = fft_n_points_per_terminal
    n_steps_per_chunk = fft_n_points_per_terminal // fft_n_parallel
    n_steps_for_overlap = ftc_tile_overlap // fft_n_parallel
%>\
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void square_and_discard_${engine}(global ${ftc_real_pack_ty} * restrict fop,
                                 const uint n_tiles,
                                 const uint n_packs,
                                 const uint fop_offset)
{
    const ${ftc_real_pack_ty} zeros = {${", ".join(["0"] * fft_n_parallel)}};

% for p in range(fft_n_parallel):
    float __attribute__((bank_bits(${fft_n_points_per_terminal_log}))) chunk_buf_${p}[2][${fft_n_points_per_terminal}];
% endfor

    uint fop_pack = 0;
    for (uint tile = 0; tile < n_tiles + 1; ++tile) {
        for (uint step = 0; step < ${n_steps}; ++step) {
            if (tile >= 1 && step >= ${n_steps_for_overlap}) {
                uint chunk = step / ${n_steps_per_chunk};
                uint pack = step % ${n_steps_per_chunk};

                ${ftc_real_pack_ty} store = zeros;
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

                // Quick hack: Just run idle at the end of the last tile, to discard the zero padding there.
                //   This may actually be a good solution (tm), because complicating the control flow would likely
                //   introduce fmax bottlnecks -- need to test this!
                if (fop_pack < n_packs)
                    fop[fop_offset + fop_pack] = store;
                ++fop_pack;
            }

            if (tile < n_tiles) {
                ${ftc_complex_pack_ty} read = read_channel_intel(ifft_out[${engine}]);
                ${ftc_real_pack_ty} norm = power_norm(read);
            % for p in range(fft_n_parallel):
                chunk_buf_${p}[tile & 1][step] = norm.s${bit_rev(p, fft_n_parallel_log)};
            % endfor
            }
        }
    }
}
