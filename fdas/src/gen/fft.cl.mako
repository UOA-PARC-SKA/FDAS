
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
% if both_directions:
kernel void fft_${i}(const uint n_tiles, const uint is_inverse)
% else:
kernel void fft_${i}(const uint n_tiles)
% endif
{
    float2 __attribute__((bank_bits(${fft_n_points_log}))) buf[2][${fft_n_points_per_terminal}][${fft_n_parallel}];
    float2 fft_delay_elements[${fft_n_points + fft_n_parallel * (fft_n_points_log - 3)}];
    float2x4 data;

    #pragma loop_coalesce
    for (uint t = 0; t < n_tiles + 2; ++t) {
        for (uint s = 0; s < ${fft_n_points_per_terminal}; ++s) {
            if (t >= 1) {
                #pragma unroll
                for (uint p = 0; p < ${fft_n_parallel}; ++p) {
                    buf[1 - (t & 1)][bit_reversed(s, ${fft_n_points_per_terminal_log})][p] = data.i[p];
                }
            }
            if (t >= 2) {
                #pragma unroll
                for (uint p = 0; p < ${fft_n_parallel}; ++p) {
                % if both_directions:
                    if (! is_inverse)
                        WRITE_CHANNEL(fft_out[p], buf[t & 1][s][p]);
                    else
                        WRITE_CHANNEL(ifft_out[${i}][p], buf[t & 1][s][p]);
                % else:
                    WRITE_CHANNEL(ifft_out[${i}][p], buf[t & 1][s][p]);
                % endif
                }
            }

            if (t < n_tiles) {
                #pragma unroll
                for (uint p = 0; p < ${fft_n_parallel}; ++p) {
                % if both_directions:
                    if (! is_inverse)
                        data.i[p] = READ_CHANNEL(fft_in[p]);
                    else
                        data.i[p] = READ_CHANNEL(ifft_in[${i}][p]);
                % else:
                    data.i[p] = READ_CHANNEL(ifft_in[${i}][p]);
                % endif
                }
            } else {
                data.i0 = data.i1 = data.i2 = data.i3 = 0.0f;
            }

            data = fft_step(data, s, fft_delay_elements, ${"is_inverse" if both_directions else "1"}, ${fft_n_points_log});
        }
    }
}
