/*
 * FDAS -- Fourier Domain Acceleration Search, FPGA-accelerated with OpenCL
 * Copyright (C) 2020  Parallel and Reconfigurable Computing Lab,
 *                     Dept. of Electrical, Computer, and Software Engineering,
 *                     University of Auckland, New Zealand
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

// Auto-generated file -- see `hsum_codegen.py` and `preload.cl.mako`.

channel float8 preload_to_delay[8][2] __attribute__((depth(0)));
channel float8 delay_to_detect[8][2] __attribute__((depth(0)));

inline ulong fop_idx(int filter, uint bundle) {
    return (filter + N_FILTERS_PER_ACCEL_SIGN) * (FDF_OUTPUT_SZ / 8) + bundle;
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_1(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const uint n_channel_bundles)
{
    float8 load[2];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[1];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[0][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_1(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 0 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[0][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s1;
                    out[p].s2 = in[p].s2;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s5;
                    out[p].s6 = in[p].s6;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[0][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_2(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const uint n_channel_bundles)
{
    float8 load[1];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[0];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[1][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_2(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 1 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[1][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s1;
                    out[p].s3 = in[p].s1;
                    out[p].s4 = in[p].s2;
                    out[p].s5 = in[p].s2;
                    out[p].s6 = in[p].s3;
                    out[p].s7 = in[p].s3;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s4;
                    out[p].s2 = in[p].s5;
                    out[p].s3 = in[p].s5;
                    out[p].s4 = in[p].s6;
                    out[p].s5 = in[p].s6;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[1][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_3(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const uint n_channel_bundles)
{
    float8 load[2];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = base_row_offset < 2 ? load[0] : load[1];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[2][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_3(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 2 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[2][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s1;
                    out[p].s4 = in[p].s1;
                    out[p].s5 = in[p].s1;
                    out[p].s6 = in[p].s2;
                    out[p].s7 = in[p].s2;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s2;
                    out[p].s1 = in[p].s3;
                    out[p].s2 = in[p].s3;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s4;
                    out[p].s6 = in[p].s4;
                    out[p].s7 = in[p].s5;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s5;
                    out[p].s1 = in[p].s5;
                    out[p].s2 = in[p].s6;
                    out[p].s3 = in[p].s6;
                    out[p].s4 = in[p].s6;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[2][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_4(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const uint n_channel_bundles)
{
    float8 load[1];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[0];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[3][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_4(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 3 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[3][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s1;
                    out[p].s5 = in[p].s1;
                    out[p].s6 = in[p].s1;
                    out[p].s7 = in[p].s1;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s2;
                    out[p].s1 = in[p].s2;
                    out[p].s2 = in[p].s2;
                    out[p].s3 = in[p].s2;
                    out[p].s4 = in[p].s3;
                    out[p].s5 = in[p].s3;
                    out[p].s6 = in[p].s3;
                    out[p].s7 = in[p].s3;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s4;
                    out[p].s2 = in[p].s4;
                    out[p].s3 = in[p].s4;
                    out[p].s4 = in[p].s5;
                    out[p].s5 = in[p].s5;
                    out[p].s6 = in[p].s5;
                    out[p].s7 = in[p].s5;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s6;
                    out[p].s1 = in[p].s6;
                    out[p].s2 = in[p].s6;
                    out[p].s3 = in[p].s6;
                    out[p].s4 = in[p].s7;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[3][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_5(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const uint n_channel_bundles)
{
    float8 load[2];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = base_row_offset < 4 ? load[0] : load[1];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[4][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_5(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 4 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[4][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s0;
                    out[p].s5 = in[p].s1;
                    out[p].s6 = in[p].s1;
                    out[p].s7 = in[p].s1;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s1;
                    out[p].s1 = in[p].s1;
                    out[p].s2 = in[p].s2;
                    out[p].s3 = in[p].s2;
                    out[p].s4 = in[p].s2;
                    out[p].s5 = in[p].s2;
                    out[p].s6 = in[p].s2;
                    out[p].s7 = in[p].s3;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s3;
                    out[p].s1 = in[p].s3;
                    out[p].s2 = in[p].s3;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s4;
                    out[p].s6 = in[p].s4;
                    out[p].s7 = in[p].s4;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s5;
                    out[p].s2 = in[p].s5;
                    out[p].s3 = in[p].s5;
                    out[p].s4 = in[p].s5;
                    out[p].s5 = in[p].s5;
                    out[p].s6 = in[p].s6;
                    out[p].s7 = in[p].s6;
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s6;
                    out[p].s1 = in[p].s6;
                    out[p].s2 = in[p].s6;
                    out[p].s3 = in[p].s7;
                    out[p].s4 = in[p].s7;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[4][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_6(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const uint n_channel_bundles)
{
    float8 load[1];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[0];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[5][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_6(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 5 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[5][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s0;
                    out[p].s5 = in[p].s0;
                    out[p].s6 = in[p].s1;
                    out[p].s7 = in[p].s1;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s1;
                    out[p].s1 = in[p].s1;
                    out[p].s2 = in[p].s1;
                    out[p].s3 = in[p].s1;
                    out[p].s4 = in[p].s2;
                    out[p].s5 = in[p].s2;
                    out[p].s6 = in[p].s2;
                    out[p].s7 = in[p].s2;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s2;
                    out[p].s1 = in[p].s2;
                    out[p].s2 = in[p].s3;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s3;
                    out[p].s5 = in[p].s3;
                    out[p].s6 = in[p].s3;
                    out[p].s7 = in[p].s3;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s4;
                    out[p].s2 = in[p].s4;
                    out[p].s3 = in[p].s4;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s4;
                    out[p].s6 = in[p].s5;
                    out[p].s7 = in[p].s5;
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s5;
                    out[p].s1 = in[p].s5;
                    out[p].s2 = in[p].s5;
                    out[p].s3 = in[p].s5;
                    out[p].s4 = in[p].s6;
                    out[p].s5 = in[p].s6;
                    out[p].s6 = in[p].s6;
                    out[p].s7 = in[p].s6;
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s6;
                    out[p].s1 = in[p].s6;
                    out[p].s2 = in[p].s7;
                    out[p].s3 = in[p].s7;
                    out[p].s4 = in[p].s7;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[5][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_7(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const int filter_1,
                      const uint n_channel_bundles)
{
    float8 load[2];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;
        load[1] = 1 < n_rows ? fop[fop_idx(filter_1, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = base_row_offset < 6 ? load[0] : load[1];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[6][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_7(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 6 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[6][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s0;
                    out[p].s5 = in[p].s0;
                    out[p].s6 = in[p].s0;
                    out[p].s7 = in[p].s1;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s1;
                    out[p].s1 = in[p].s1;
                    out[p].s2 = in[p].s1;
                    out[p].s3 = in[p].s1;
                    out[p].s4 = in[p].s1;
                    out[p].s5 = in[p].s1;
                    out[p].s6 = in[p].s2;
                    out[p].s7 = in[p].s2;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s2;
                    out[p].s1 = in[p].s2;
                    out[p].s2 = in[p].s2;
                    out[p].s3 = in[p].s2;
                    out[p].s4 = in[p].s2;
                    out[p].s5 = in[p].s3;
                    out[p].s6 = in[p].s3;
                    out[p].s7 = in[p].s3;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s3;
                    out[p].s1 = in[p].s3;
                    out[p].s2 = in[p].s3;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s4;
                    out[p].s6 = in[p].s4;
                    out[p].s7 = in[p].s4;
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s4;
                    out[p].s2 = in[p].s4;
                    out[p].s3 = in[p].s5;
                    out[p].s4 = in[p].s5;
                    out[p].s5 = in[p].s5;
                    out[p].s6 = in[p].s5;
                    out[p].s7 = in[p].s5;
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s5;
                    out[p].s1 = in[p].s5;
                    out[p].s2 = in[p].s6;
                    out[p].s3 = in[p].s6;
                    out[p].s4 = in[p].s6;
                    out[p].s5 = in[p].s6;
                    out[p].s6 = in[p].s6;
                    out[p].s7 = in[p].s6;
                }
                break;
            case 6:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s6;
                    out[p].s1 = in[p].s7;
                    out[p].s2 = in[p].s7;
                    out[p].s3 = in[p].s7;
                    out[p].s4 = in[p].s7;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[6][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void preload_8(global float8 * restrict fop,
                      const uint n_rows,
                      const uint base_row_offset,
                      const int filter_0,
                      const uint n_channel_bundles)
{
    float8 load[1];
    float8 out[2];

    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        load[0] = 0 < n_rows ? fop[fop_idx(filter_0, bundle)] : 0.0f;

        out[0] = load[0];
        out[1] = load[0];

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(preload_to_delay[7][p], out[p]);
    }
}

__attribute__((max_global_work_dim(0)))
__attribute__((uses_global_work_offset(0)))
kernel void delay_8(global uint * restrict dummy,
                       const uint n_channel_bundles)
{
    float8 in[2];
    float8 out[2];

    uint M = 0;
    for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
        uint m = M;
        M = M < 7 ? M + 1 : 0;

        if (m == 0) {
            #pragma unroll
            for (uint p = 0; p < 2; ++p)
                in[p] = READ_CHANNEL(preload_to_delay[7][p]);
        }

        switch (m) {
            case 0:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s0;
                    out[p].s1 = in[p].s0;
                    out[p].s2 = in[p].s0;
                    out[p].s3 = in[p].s0;
                    out[p].s4 = in[p].s0;
                    out[p].s5 = in[p].s0;
                    out[p].s6 = in[p].s0;
                    out[p].s7 = in[p].s0;
                }
                break;
            case 1:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s1;
                    out[p].s1 = in[p].s1;
                    out[p].s2 = in[p].s1;
                    out[p].s3 = in[p].s1;
                    out[p].s4 = in[p].s1;
                    out[p].s5 = in[p].s1;
                    out[p].s6 = in[p].s1;
                    out[p].s7 = in[p].s1;
                }
                break;
            case 2:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s2;
                    out[p].s1 = in[p].s2;
                    out[p].s2 = in[p].s2;
                    out[p].s3 = in[p].s2;
                    out[p].s4 = in[p].s2;
                    out[p].s5 = in[p].s2;
                    out[p].s6 = in[p].s2;
                    out[p].s7 = in[p].s2;
                }
                break;
            case 3:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s3;
                    out[p].s1 = in[p].s3;
                    out[p].s2 = in[p].s3;
                    out[p].s3 = in[p].s3;
                    out[p].s4 = in[p].s3;
                    out[p].s5 = in[p].s3;
                    out[p].s6 = in[p].s3;
                    out[p].s7 = in[p].s3;
                }
                break;
            case 4:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s4;
                    out[p].s1 = in[p].s4;
                    out[p].s2 = in[p].s4;
                    out[p].s3 = in[p].s4;
                    out[p].s4 = in[p].s4;
                    out[p].s5 = in[p].s4;
                    out[p].s6 = in[p].s4;
                    out[p].s7 = in[p].s4;
                }
                break;
            case 5:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s5;
                    out[p].s1 = in[p].s5;
                    out[p].s2 = in[p].s5;
                    out[p].s3 = in[p].s5;
                    out[p].s4 = in[p].s5;
                    out[p].s5 = in[p].s5;
                    out[p].s6 = in[p].s5;
                    out[p].s7 = in[p].s5;
                }
                break;
            case 6:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s6;
                    out[p].s1 = in[p].s6;
                    out[p].s2 = in[p].s6;
                    out[p].s3 = in[p].s6;
                    out[p].s4 = in[p].s6;
                    out[p].s5 = in[p].s6;
                    out[p].s6 = in[p].s6;
                    out[p].s7 = in[p].s6;
                }
                break;
            case 7:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = in[p].s7;
                    out[p].s1 = in[p].s7;
                    out[p].s2 = in[p].s7;
                    out[p].s3 = in[p].s7;
                    out[p].s4 = in[p].s7;
                    out[p].s5 = in[p].s7;
                    out[p].s6 = in[p].s7;
                    out[p].s7 = in[p].s7;
                }
                break;
            default:
                #pragma unroll
                for (uint p = 0; p < 2; ++p) {
                    out[p].s0 = 0.0f;
                    out[p].s1 = 0.0f;
                    out[p].s2 = 0.0f;
                    out[p].s3 = 0.0f;
                    out[p].s4 = 0.0f;
                    out[p].s5 = 0.0f;
                    out[p].s6 = 0.0f;
                    out[p].s7 = 0.0f;
                }
                break;
        }

        #pragma unroll
        for (uint p = 0; p < 2; ++p)
            WRITE_CHANNEL(delay_to_detect[7][p], out[p]);
    }
}
