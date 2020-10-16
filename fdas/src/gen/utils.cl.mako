
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

inline float2x4 complex_mult4(float2x4 a, float2x4 b)
{
    float2x4 res;
%for z in range(4):
    res.i${z}.x = a.i${z}.x * b.i${z}.x - a.i${z}.y * b.i${z}.y;
    res.i${z}.y = a.i${z}.y * b.i${z}.x + a.i${z}.x * b.i${z}.y;
%endfor
    return res;
}

inline float4 power_norm4(float2x4 a)
{
    float4 res;
%for z in range(4):
    res.s${z} = (a.i${z}.x * a.i${z}.x + a.i${z}.y * a.i${z}.y) / ${fft_n_points ** 2};
%endfor
    return res;
}

inline uint encode_location(uint harm, int tmpl, uint freq) {
    return (((harm - 1) & 0x7) << 29) | (((tmpl + ${n_tmpl_per_accel_sign}) & 0x7f) << 22) | (freq & 0x3fffff);
}
