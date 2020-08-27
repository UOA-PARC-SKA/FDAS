
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
% if both_directions:
kernel void fft_${i}(const uint n_tiles, const uint is_inverse)
% else:
kernel void fft_${i}(const uint n_tiles)
% endif
{
    const float2x4 zeros = {${", ".join(["0"] * fft_n_parallel)}};

    float2x4 __attribute__((bank_bits(${fft_n_points_per_terminal_log}))) buf[2][${fft_n_points_per_terminal}];
    float2 fft_delay_elements[${fft_n_points + fft_n_parallel * (fft_n_points_log - 3)}];
    float2x4 data;

    #pragma loop_coalesce
    for (uint t = 0; t < n_tiles + 2; ++t) {
        for (uint s = 0; s < ${fft_n_points_per_terminal}; ++s) {
            if (t >= 1) {
                buf[1 - (t & 1)][bit_reversed(s, ${fft_n_points_per_terminal_log})] = data;
            }
            if (t >= 2) {
            % if both_directions:
                if (! is_inverse)
                    WRITE_CHANNEL(fft_out, buf[t & 1][s]);
                else
                    WRITE_CHANNEL(ifft_out[${i}], buf[t & 1][s]);
            % else:
                WRITE_CHANNEL(ifft_out[${i}], buf[t & 1][s]);
            % endif
            }

            if (t < n_tiles) {
            % if both_directions:
                if (! is_inverse)
                    data = READ_CHANNEL(fft_in);
                else
                    data = READ_CHANNEL(ifft_in[${i}]);
            % else:
                data = READ_CHANNEL(ifft_in[${i}]);
            % endif
            } else {
                data = zeros;
            }

            data = fft_step(data, s, fft_delay_elements, ${"is_inverse" if both_directions else "1"}, ${fft_n_points_log});
        }
    }
}
