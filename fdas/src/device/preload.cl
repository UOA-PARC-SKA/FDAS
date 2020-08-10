
// Auto-generated file -- see `hsum_codegen.py` and `preload.cl.mako`.

channel float preload_to_delay[8][8] __attribute__((depth(0)));
channel float delay_to_detect[8][8] __attribute__((depth(0)));

inline ulong fop_idx(int filter, uint bundle) {
    return (filter + N_FILTERS_PER_ACCEL_SIGN) * (FDF_OUTPUT_SZ / 1) + bundle;
}

__attribute__((max_global_work_dim(0)))
kernel void preload_1(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const int filter_2,
                      const int filter_3,
                      const int filter_4,
                      const int filter_5,
                      const int filter_6,
                      const int filter_7,
                      const uint n_channel_bundles)
{
    float load[8];
    float out[8];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;
        load[2] = 2 < n_rows ? fop[fop_idx(filter_2, bundle)] : 0.0f;
        load[3] = 3 < n_rows ? fop[fop_idx(filter_3, bundle)] : 0.0f;
        load[4] = 4 < n_rows ? fop[fop_idx(filter_4, bundle)] : 0.0f;
        load[5] = 5 < n_rows ? fop[fop_idx(filter_5, bundle)] : 0.0f;
        load[6] = 6 < n_rows ? fop[fop_idx(filter_6, bundle)] : 0.0f;
        load[7] = 7 < n_rows ? fop[fop_idx(filter_7, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[1];
        out[2] = load[2];
        out[3] = load[3];
        out[4] = load[4];
        out[5] = load[5];
        out[6] = load[6];
        out[7] = load[7];

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(preload_to_delay[0][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void delay_1(const uint n_channel_bundles)
{
    float in[8];
    float out[8];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 0 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[0][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(delay_to_detect[0][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void preload_2(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const int filter_2,
                      const int filter_3,
                      const uint n_channel_bundles)
{
    float load[4];
    float out[8];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;
        load[2] = 2 < n_rows ? fop[fop_idx(filter_2, bundle)] : 0.0f;
        load[3] = 3 < n_rows ? fop[fop_idx(filter_3, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[0];
        out[2] = load[1];
        out[3] = load[1];
        out[4] = load[2];
        out[5] = load[2];
        out[6] = load[3];
        out[7] = load[3];

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(preload_to_delay[1][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void delay_2(const uint n_channel_bundles)
{
    float in[8];
    float out[8];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 1 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[1][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(delay_to_detect[1][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void preload_3(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const int filter_2,
                      const int filter_3,
                      const uint n_channel_bundles)
{
    float load[4];
    float out[8];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;
        load[2] = 2 < n_rows ? fop[fop_idx(filter_2, bundle)] : 0.0f;
        load[3] = 3 < n_rows ? fop[fop_idx(filter_3, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = base_row_offset < 2 ? load[0] : load[1];
        out[2] = base_row_offset < 1 ? load[0] : load[1];
        out[3] = load[1];
        out[4] = base_row_offset < 2 ? load[1] : load[2];
        out[5] = base_row_offset < 1 ? load[1] : load[2];
        out[6] = load[2];
        out[7] = base_row_offset < 2 ? load[2] : load[3];

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(preload_to_delay[2][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void delay_3(const uint n_channel_bundles)
{
    float in[8];
    float out[8];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 2 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[2][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(delay_to_detect[2][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void preload_4(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const uint n_channel_bundles)
{
    float load[2];
    float out[8];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[0];
        out[2] = load[0];
        out[3] = load[0];
        out[4] = load[1];
        out[5] = load[1];
        out[6] = load[1];
        out[7] = load[1];

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(preload_to_delay[3][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void delay_4(const uint n_channel_bundles)
{
    float in[8];
    float out[8];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 3 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[3][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(delay_to_detect[3][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void preload_5(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const int filter_2,
                      const uint n_channel_bundles)
{
    float load[3];
    float out[8];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;
        load[2] = 2 < n_rows ? fop[fop_idx(filter_2, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = base_row_offset < 4 ? load[0] : load[1];
        out[2] = base_row_offset < 3 ? load[0] : load[1];
        out[3] = base_row_offset < 2 ? load[0] : load[1];
        out[4] = base_row_offset < 1 ? load[0] : load[1];
        out[5] = load[1];
        out[6] = base_row_offset < 4 ? load[1] : load[2];
        out[7] = base_row_offset < 3 ? load[1] : load[2];

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(preload_to_delay[4][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void delay_5(const uint n_channel_bundles)
{
    float in[8];
    float out[8];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 4 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[4][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(delay_to_detect[4][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void preload_6(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const uint n_channel_bundles)
{
    float load[2];
    float out[8];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[0];
        out[2] = base_row_offset < 4 ? load[0] : load[1];
        out[3] = base_row_offset < 4 ? load[0] : load[1];
        out[4] = base_row_offset < 2 ? load[0] : load[1];
        out[5] = base_row_offset < 2 ? load[0] : load[1];
        out[6] = load[1];
        out[7] = load[1];

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(preload_to_delay[5][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void delay_6(const uint n_channel_bundles)
{
    float in[8];
    float out[8];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 5 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[5][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(delay_to_detect[5][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void preload_7(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const uint n_channel_bundles)
{
    float load[2];
    float out[8];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = base_row_offset < 6 ? load[0] : load[1];
        out[2] = base_row_offset < 5 ? load[0] : load[1];
        out[3] = base_row_offset < 4 ? load[0] : load[1];
        out[4] = base_row_offset < 3 ? load[0] : load[1];
        out[5] = base_row_offset < 2 ? load[0] : load[1];
        out[6] = base_row_offset < 1 ? load[0] : load[1];
        out[7] = load[1];

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(preload_to_delay[6][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void delay_7(const uint n_channel_bundles)
{
    float in[8];
    float out[8];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 6 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[6][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 6:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(delay_to_detect[6][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void preload_8(global float * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const uint n_channel_bundles)
{
    float load[1];
    float out[8];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[0];
        out[2] = load[0];
        out[3] = load[0];
        out[4] = load[0];
        out[5] = load[0];
        out[6] = load[0];
        out[7] = load[0];

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(preload_to_delay[7][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
kernel void delay_8(const uint n_channel_bundles)
{
    float in[8];
    float out[8];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 7 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 8; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[7][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 6:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            case 7:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = in[p];
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 8; ++p) {
                    out[p] = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 8; ++p)
            WRITE_CHANNEL(delay_to_detect[7][p], out[p]);
    }
}
