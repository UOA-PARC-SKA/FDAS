
<%
    n_steps = fft_n_points_per_terminal
    n_steps_per_chunk = fft_n_points_per_terminal // fft_n_parallel
    n_steps_for_overlap = fdf_tile_overlap // fft_n_parallel

    n_packs_per_tile = fft_n_points_per_terminal
%>\
__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void mux_and_mult(global float2x4 * restrict tiles,
                         global float2x4 * restrict templates,
                         const uint n_tiles,
                     % for e in range(fft_n_engines):
                         const int filter_${e},
                     % endfor
                         const uint n_filters)
{
    const float2x4 zeros = {${", ".join(["0"] * fft_n_parallel)}};

% for e in range(fft_n_engines):
    float2x4 template_buf_${e}[${n_packs_per_tile}];
% endfor

    for (uint pack = 0; pack < ${n_packs_per_tile}; ++pack) {
    % for e in range(fft_n_engines):
        float2x4 tmpl_${e} = ${e} < n_filters ? templates[(${n_filters_per_accel_sign} + filter_${e}) * ${n_packs_per_tile} + pack] : zeros;
    % endfor
    % for e in range(fft_n_engines):
        template_buf_${e}[pack] = tmpl_${e};
    % endfor
    }

    for (uint pack = 0; pack < n_tiles * ${n_packs_per_tile}; ++pack) {
        float2x4 coeffs[${fft_n_engines}];
        float2x4 prods[${fft_n_engines}];

        float2x4 load = tiles[pack];
    % for e in range(fft_n_engines):
        coeffs[${e}] = template_buf_${e}[pack % ${n_packs_per_tile}];
    % endfor
    % for e in range(fft_n_engines):
        prods[${e}] = complex_mult4(load, coeffs[${e}]);
    % endfor

        #pragma unroll
        for (uint e = 0; e < ${fft_n_engines}; ++e) {
            if (e < n_filters)
                write_channel_intel(ifft_in[e], prods[e]);
        }
    }
}
