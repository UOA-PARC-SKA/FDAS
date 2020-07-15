
// Auto-generated file -- see `hsum_codegen.py` and `detect.cl.mako`.
channel float next_plane[7][8] __attribute__((depth(0)));
channel uint locations[8][8] __attribute__((depth(0)));
channel float amplitudes[8][8] __attribute__((depth(0)));

__attribute__((max_global_work_dim(0)))
kernel void detect_1(const float threshold,
                     const uint negative_filters)
{
    for (uint F = 0; F < 40; F += 8) {
        for (uint c = 0; c < 4193280; ++c) {
            float hsum[8];

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                hsum[f] = READ_CHANNEL(preloaders_out[0][f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                WRITE_CHANNEL(next_plane[0][f], hsum[f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f) {
                uint loc = HMS_INVALID_LOCATION;
                float amp = -1.0f;
                if (hsum[f] > threshold) {
                    loc = HMS_ENCODE_LOCATION(1, negative_filters ? F + f : -(F + f), c);
                    amp = hsum[f];
                }
                WRITE_CHANNEL(locations[0][f], loc);
                WRITE_CHANNEL(amplitudes[0][f], amp);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_2(const float threshold,
                     const uint negative_filters)
{
    for (uint F = 0; F < 40; F += 8) {
        for (uint c = 0; c < 4193280; ++c) {
            float hsum[8];

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                hsum[f] = READ_CHANNEL(next_plane[0][f]) + READ_CHANNEL(preloaders_out[1][f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                WRITE_CHANNEL(next_plane[1][f], hsum[f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f) {
                uint loc = HMS_INVALID_LOCATION;
                float amp = -1.0f;
                if (hsum[f] > threshold) {
                    loc = HMS_ENCODE_LOCATION(2, negative_filters ? F + f : -(F + f), c);
                    amp = hsum[f];
                }
                WRITE_CHANNEL(locations[1][f], loc);
                WRITE_CHANNEL(amplitudes[1][f], amp);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_3(const float threshold,
                     const uint negative_filters)
{
    for (uint F = 0; F < 40; F += 8) {
        for (uint c = 0; c < 4193280; ++c) {
            float hsum[8];

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                hsum[f] = READ_CHANNEL(next_plane[1][f]) + READ_CHANNEL(preloaders_out[2][f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                WRITE_CHANNEL(next_plane[2][f], hsum[f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f) {
                uint loc = HMS_INVALID_LOCATION;
                float amp = -1.0f;
                if (hsum[f] > threshold) {
                    loc = HMS_ENCODE_LOCATION(3, negative_filters ? F + f : -(F + f), c);
                    amp = hsum[f];
                }
                WRITE_CHANNEL(locations[2][f], loc);
                WRITE_CHANNEL(amplitudes[2][f], amp);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_4(const float threshold,
                     const uint negative_filters)
{
    for (uint F = 0; F < 40; F += 8) {
        for (uint c = 0; c < 4193280; ++c) {
            float hsum[8];

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                hsum[f] = READ_CHANNEL(next_plane[2][f]) + READ_CHANNEL(preloaders_out[3][f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                WRITE_CHANNEL(next_plane[3][f], hsum[f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f) {
                uint loc = HMS_INVALID_LOCATION;
                float amp = -1.0f;
                if (hsum[f] > threshold) {
                    loc = HMS_ENCODE_LOCATION(4, negative_filters ? F + f : -(F + f), c);
                    amp = hsum[f];
                }
                WRITE_CHANNEL(locations[3][f], loc);
                WRITE_CHANNEL(amplitudes[3][f], amp);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_5(const float threshold,
                     const uint negative_filters)
{
    for (uint F = 0; F < 40; F += 8) {
        for (uint c = 0; c < 4193280; ++c) {
            float hsum[8];

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                hsum[f] = READ_CHANNEL(next_plane[3][f]) + READ_CHANNEL(preloaders_out[4][f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                WRITE_CHANNEL(next_plane[4][f], hsum[f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f) {
                uint loc = HMS_INVALID_LOCATION;
                float amp = -1.0f;
                if (hsum[f] > threshold) {
                    loc = HMS_ENCODE_LOCATION(5, negative_filters ? F + f : -(F + f), c);
                    amp = hsum[f];
                }
                WRITE_CHANNEL(locations[4][f], loc);
                WRITE_CHANNEL(amplitudes[4][f], amp);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_6(const float threshold,
                     const uint negative_filters)
{
    for (uint F = 0; F < 40; F += 8) {
        for (uint c = 0; c < 4193280; ++c) {
            float hsum[8];

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                hsum[f] = READ_CHANNEL(next_plane[4][f]) + READ_CHANNEL(preloaders_out[5][f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                WRITE_CHANNEL(next_plane[5][f], hsum[f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f) {
                uint loc = HMS_INVALID_LOCATION;
                float amp = -1.0f;
                if (hsum[f] > threshold) {
                    loc = HMS_ENCODE_LOCATION(6, negative_filters ? F + f : -(F + f), c);
                    amp = hsum[f];
                }
                WRITE_CHANNEL(locations[5][f], loc);
                WRITE_CHANNEL(amplitudes[5][f], amp);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_7(const float threshold,
                     const uint negative_filters)
{
    for (uint F = 0; F < 40; F += 8) {
        for (uint c = 0; c < 4193280; ++c) {
            float hsum[8];

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                hsum[f] = READ_CHANNEL(next_plane[5][f]) + READ_CHANNEL(preloaders_out[6][f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                WRITE_CHANNEL(next_plane[6][f], hsum[f]);

            #pragma unroll
            for (uint f = 0; f < 8; ++f) {
                uint loc = HMS_INVALID_LOCATION;
                float amp = -1.0f;
                if (hsum[f] > threshold) {
                    loc = HMS_ENCODE_LOCATION(7, negative_filters ? F + f : -(F + f), c);
                    amp = hsum[f];
                }
                WRITE_CHANNEL(locations[6][f], loc);
                WRITE_CHANNEL(amplitudes[6][f], amp);
            }
        }
    }
}

__attribute__((max_global_work_dim(0)))
kernel void detect_8(const float threshold,
                     const uint negative_filters)
{
    for (uint F = 0; F < 40; F += 8) {
        for (uint c = 0; c < 4193280; ++c) {
            float hsum[8];

            #pragma unroll
            for (uint f = 0; f < 8; ++f)
                hsum[f] = READ_CHANNEL(next_plane[6][f]) + READ_CHANNEL(preloaders_out[7][f]);


            #pragma unroll
            for (uint f = 0; f < 8; ++f) {
                uint loc = HMS_INVALID_LOCATION;
                float amp = -1.0f;
                if (hsum[f] > threshold) {
                    loc = HMS_ENCODE_LOCATION(8, negative_filters ? F + f : -(F + f), c);
                    amp = hsum[f];
                }
                WRITE_CHANNEL(locations[7][f], loc);
                WRITE_CHANNEL(amplitudes[7][f], amp);
            }
        }
    }
}
