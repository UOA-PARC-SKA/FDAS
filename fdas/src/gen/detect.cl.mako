
__attribute__((max_global_work_dim(0)))
kernel void detect_${harmonic}(const float threshold,
                     const uint negative_filters)
{
    for (uint F = 0; F < ${n_filters}; F += ${n_parallel}) {
        for (uint c = 0; c < ${n_channels}; ++c) {
            float hsum[${n_parallel}];

        % if harmonic == 1:
            #pragma unroll
            for (uint f = 0; f < ${n_parallel}; ++f)
                hsum[f] = READ_CHANNEL(preloaders_out[${harmonic - 1}][f]);
        %else:
            #pragma unroll
            for (uint f = 0; f < ${n_parallel}; ++f)
                hsum[f] = READ_CHANNEL(next_plane[${harmonic - 2}][f]) + READ_CHANNEL(preloaders_out[${harmonic - 1}][f]);
        % endif

        %if harmonic < n_planes:
            #pragma unroll
            for (uint f = 0; f < ${n_parallel}; ++f)
                WRITE_CHANNEL(next_plane[${harmonic - 1}][f], hsum[f]);
        %endif

            #pragma unroll
            for (uint f = 0; f < ${n_parallel}; ++f) {
                uint loc = HMS_INVALID_LOCATION;
                float amp = -1.0f;
                if (hsum[f] > threshold) {
                    int fil = F + f;
                    if (negative_filters)
                        fil = -fil;
                    loc = HMS_ENCODE_LOCATION(${harmonic}, fil, c);
                    amp = hsum[f];
                }
                WRITE_CHANNEL(locations[${harmonic - 1}][f], loc);
                WRITE_CHANNEL(amplitudes[${harmonic - 1}][f], amp);
            }
        }
    }
}
