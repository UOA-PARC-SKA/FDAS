
inline uint bit_reversed(uint x, uint bits)
{
    uint y = 0;
    #pragma unroll
    for (uint i = 0; i < bits; i++) {
        y <<= 1;
        y |= x & 1;
        x >>= 1;
    }
    return y;
}

inline float2 complex_mult(float2 a, float2 b)
{
    float2 res;
    res.x = a.x * b.x - a.y * b.y;
    res.y = a.y * b.x + a.x * b.y;
    return res;
}

inline float power_norm(float2 a)
{
    return (a.x * a.x + a.y * a.y) / ${fft_n_points ** 2};
}

inline uint encode_location(uint k, int f, uint c) {
    return (((k - 1) & 0x7) << 29) | (((f + ${n_filters_per_accel_sign}) & 0x7f) << 22) | (c & 0x3fffff);
}
