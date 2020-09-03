
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
% if both_directions:
kernel void fft_${engine}(const uint n_tiles, const uint is_inverse)
% else:
kernel void fft_${engine}(const uint n_tiles)
% endif
{
    const float2x4 zeros = {${", ".join(["0"] * fft_n_parallel)}};

    float2x4 __attribute__((bank_bits(${fft_n_points_per_terminal_log}))) buf[2][${fft_n_points_per_terminal}];
    float2 fft_delay_elements[${fft_n_points + fft_n_parallel * (fft_n_points_log - 3)}];
    float2x4 data;

    for (uint tile = 0; tile < n_tiles + 2; ++tile) {
        for (uint step = 0; step < ${fft_n_points_per_terminal}; ++step) {
            if (tile >= 1) {
                buf[1 - (tile & 1)][bit_reversed(step, ${fft_n_points_per_terminal_log})] = data;
            }
            if (tile >= 2) {
            % if both_directions:
                if (! is_inverse)
                    WRITE_CHANNEL(fft_out, buf[tile & 1][step]);
                else
                    WRITE_CHANNEL(ifft_out[${engine}], buf[tile & 1][step]);
            % else:
                WRITE_CHANNEL(ifft_out[${engine}], buf[tile & 1][step]);
            % endif
            }

            if (tile < n_tiles) {
            % if both_directions:
                if (! is_inverse)
                    data = READ_CHANNEL(fft_in);
                else
                    data = READ_CHANNEL(ifft_in[${engine}]);
            % else:
                data = READ_CHANNEL(ifft_in[${engine}]);
            % endif
            } else {
                data = zeros;
            }

            data = fft_step(data, step, fft_delay_elements, ${"is_inverse" if both_directions else "1"}, ${fft_n_points_log});
        }
    }
}
