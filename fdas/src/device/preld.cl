
// Auto-generated file -- see `hsum_codegen.py` and `preld.cl.mako`.

channel float preloaders_out[8][8] __attribute__((depth(0)));

__attribute__((reqd_work_group_size(8, 1, 1)))
kernel void preloader_1(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[8];
    local   float buf_1[8];
    local   float buf_2[8];
    local   float buf_3[8];
    local   float buf_4[8];
    local   float buf_5[8];
    local   float buf_6[8];
    local   float buf_7[8];
    private float ld[8];

    int  filter_base  = get_group_id(0) * 8 / 1;
    uint channel_base = get_group_id(1) * 8;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 8) {
        #pragma unroll
        for (c = 0; c < 8; ++c)
            ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_0[c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_1[c] = ld[c];
            break;
        case 2:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_2[c] = ld[c];
            break;
        case 3:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_3[c] = ld[c];
            break;
        case 4:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_4[c] = ld[c];
            break;
        case 5:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_5[c] = ld[c];
            break;
        case 6:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_6[c] = ld[c];
            break;
        case 7:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_7[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0);

    float b_0 = buf_0[c];
    float b_1 = buf_1[c];
    float b_2 = buf_2[c];
    float b_3 = buf_3[c];
    float b_4 = buf_4[c];
    float b_5 = buf_5[c];
    float b_6 = buf_6[c];
    float b_7 = buf_7[c];

    for (uint z = 0; z < 1; ++z) {
        WRITE_CHANNEL(preloaders_out[0][0], b_0);
        WRITE_CHANNEL(preloaders_out[0][1], b_1);
        WRITE_CHANNEL(preloaders_out[0][2], b_2);
        WRITE_CHANNEL(preloaders_out[0][3], b_3);
        WRITE_CHANNEL(preloaders_out[0][4], b_4);
        WRITE_CHANNEL(preloaders_out[0][5], b_5);
        WRITE_CHANNEL(preloaders_out[0][6], b_6);
        WRITE_CHANNEL(preloaders_out[0][7], b_7);
    }
}

__attribute__((reqd_work_group_size(8, 1, 1)))
kernel void preloader_2(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[8];
    local   float buf_1[8];
    local   float buf_2[8];
    local   float buf_3[8];
    private float ld[8];

    int  filter_base  = get_group_id(0) * 8 / 2;
    uint channel_base = get_group_id(1) * 8;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 4) {
        #pragma unroll
        for (c = 0; c < 8; ++c)
            ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_0[c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_1[c] = ld[c];
            break;
        case 2:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_2[c] = ld[c];
            break;
        case 3:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_3[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0);

    float b_0 = buf_0[c];
    float b_1 = buf_1[c];
    float b_2 = buf_2[c];
    float b_3 = buf_3[c];

    for (uint z = 0; z < 2; ++z) {
        WRITE_CHANNEL(preloaders_out[1][0], b_0);
        WRITE_CHANNEL(preloaders_out[1][1], b_0);
        WRITE_CHANNEL(preloaders_out[1][2], b_1);
        WRITE_CHANNEL(preloaders_out[1][3], b_1);
        WRITE_CHANNEL(preloaders_out[1][4], b_2);
        WRITE_CHANNEL(preloaders_out[1][5], b_2);
        WRITE_CHANNEL(preloaders_out[1][6], b_3);
        WRITE_CHANNEL(preloaders_out[1][7], b_3);
    }
}

__attribute__((reqd_work_group_size(8, 1, 1)))
kernel void preloader_3(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[8];
    local   float buf_1[8];
    local   float buf_2[8];
    local   float buf_3[8];
    private float ld[8];

    int  filter_base  = get_group_id(0) * 8 / 3;
    uint channel_base = get_group_id(1) * 8;
    uint row_offset   = filter_base % 3;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 4) {
        if (get_local_id(0) < 3 || row_offset >= 2) {
            #pragma unroll
            for (c = 0; c < 8; ++c)
                ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
        } else {
            #pragma unroll
            for (c = 0; c < 8; ++c)
                ld[c] = 0.0f;
        }
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_0[c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_1[c] = ld[c];
            break;
        case 2:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_2[c] = ld[c];
            break;
        case 3:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_3[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0);

    float b_0 = buf_0[c];
    float b_1 = buf_1[c];
    float b_2 = buf_2[c];
    float b_3 = buf_3[c];

    for (uint z = 0; z < 3; ++z) {
        WRITE_CHANNEL(preloaders_out[2][0], b_0);
        WRITE_CHANNEL(preloaders_out[2][1], row_offset <= 1 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[2][2], row_offset <= 0 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[2][3], b_1);
        WRITE_CHANNEL(preloaders_out[2][4], row_offset <= 1 ? b_1 : b_2);
        WRITE_CHANNEL(preloaders_out[2][5], row_offset <= 0 ? b_1 : b_2);
        WRITE_CHANNEL(preloaders_out[2][6], b_2);
        WRITE_CHANNEL(preloaders_out[2][7], row_offset <= 1 ? b_2 : b_3);
    }
}

__attribute__((reqd_work_group_size(8, 1, 1)))
kernel void preloader_4(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[8];
    local   float buf_1[8];
    private float ld[8];

    int  filter_base  = get_group_id(0) * 8 / 4;
    uint channel_base = get_group_id(1) * 8;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 2) {
        #pragma unroll
        for (c = 0; c < 8; ++c)
            ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_0[c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_1[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0);

    float b_0 = buf_0[c];
    float b_1 = buf_1[c];

    for (uint z = 0; z < 4; ++z) {
        WRITE_CHANNEL(preloaders_out[3][0], b_0);
        WRITE_CHANNEL(preloaders_out[3][1], b_0);
        WRITE_CHANNEL(preloaders_out[3][2], b_0);
        WRITE_CHANNEL(preloaders_out[3][3], b_0);
        WRITE_CHANNEL(preloaders_out[3][4], b_1);
        WRITE_CHANNEL(preloaders_out[3][5], b_1);
        WRITE_CHANNEL(preloaders_out[3][6], b_1);
        WRITE_CHANNEL(preloaders_out[3][7], b_1);
    }
}

__attribute__((reqd_work_group_size(8, 1, 1)))
kernel void preloader_5(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[8];
    local   float buf_1[8];
    local   float buf_2[8];
    private float ld[8];

    int  filter_base  = get_group_id(0) * 8 / 5;
    uint channel_base = get_group_id(1) * 8;
    uint row_offset   = filter_base % 5;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 3) {
        if (get_local_id(0) < 2 || row_offset >= 3) {
            #pragma unroll
            for (c = 0; c < 8; ++c)
                ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
        } else {
            #pragma unroll
            for (c = 0; c < 8; ++c)
                ld[c] = 0.0f;
        }
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_0[c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_1[c] = ld[c];
            break;
        case 2:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_2[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0);

    float b_0 = buf_0[c];
    float b_1 = buf_1[c];
    float b_2 = buf_2[c];

    for (uint z = 0; z < 5; ++z) {
        WRITE_CHANNEL(preloaders_out[4][0], b_0);
        WRITE_CHANNEL(preloaders_out[4][1], row_offset <= 3 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[4][2], row_offset <= 2 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[4][3], row_offset <= 1 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[4][4], row_offset <= 0 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[4][5], b_1);
        WRITE_CHANNEL(preloaders_out[4][6], row_offset <= 3 ? b_1 : b_2);
        WRITE_CHANNEL(preloaders_out[4][7], row_offset <= 2 ? b_1 : b_2);
    }
}

__attribute__((reqd_work_group_size(8, 1, 1)))
kernel void preloader_6(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[8];
    local   float buf_1[8];
    local   float buf_2[8];
    private float ld[8];

    int  filter_base  = get_group_id(0) * 8 / 6;
    uint channel_base = get_group_id(1) * 8;
    uint row_offset   = filter_base % 6;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 3) {
        if (get_local_id(0) < 2 || row_offset >= 5) {
            #pragma unroll
            for (c = 0; c < 8; ++c)
                ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
        } else {
            #pragma unroll
            for (c = 0; c < 8; ++c)
                ld[c] = 0.0f;
        }
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_0[c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_1[c] = ld[c];
            break;
        case 2:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_2[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0);

    float b_0 = buf_0[c];
    float b_1 = buf_1[c];
    float b_2 = buf_2[c];

    for (uint z = 0; z < 6; ++z) {
        WRITE_CHANNEL(preloaders_out[5][0], b_0);
        WRITE_CHANNEL(preloaders_out[5][1], row_offset <= 4 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[5][2], row_offset <= 3 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[5][3], row_offset <= 2 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[5][4], row_offset <= 1 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[5][5], row_offset <= 0 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[5][6], b_1);
        WRITE_CHANNEL(preloaders_out[5][7], row_offset <= 4 ? b_1 : b_2);
    }
}

__attribute__((reqd_work_group_size(8, 1, 1)))
kernel void preloader_7(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[8];
    local   float buf_1[8];
    private float ld[8];

    int  filter_base  = get_group_id(0) * 8 / 7;
    uint channel_base = get_group_id(1) * 8;
    uint row_offset   = filter_base % 7;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 2) {
        #pragma unroll
        for (c = 0; c < 8; ++c)
            ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_0[c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_1[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0);

    float b_0 = buf_0[c];
    float b_1 = buf_1[c];

    for (uint z = 0; z < 7; ++z) {
        WRITE_CHANNEL(preloaders_out[6][0], b_0);
        WRITE_CHANNEL(preloaders_out[6][1], row_offset <= 5 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[6][2], row_offset <= 4 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[6][3], row_offset <= 3 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[6][4], row_offset <= 2 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[6][5], row_offset <= 1 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[6][6], row_offset <= 0 ? b_0 : b_1);
        WRITE_CHANNEL(preloaders_out[6][7], b_1);
    }
}

__attribute__((reqd_work_group_size(8, 1, 1)))
kernel void preloader_8(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[8];
    private float ld[8];

    int  filter_base  = get_group_id(0) * 8 / 8;
    uint channel_base = get_group_id(1) * 8;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 1) {
        #pragma unroll
        for (c = 0; c < 8; ++c)
            ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 8; ++c)
                buf_0[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0);

    float b_0 = buf_0[c];

    for (uint z = 0; z < 8; ++z) {
        WRITE_CHANNEL(preloaders_out[7][0], b_0);
        WRITE_CHANNEL(preloaders_out[7][1], b_0);
        WRITE_CHANNEL(preloaders_out[7][2], b_0);
        WRITE_CHANNEL(preloaders_out[7][3], b_0);
        WRITE_CHANNEL(preloaders_out[7][4], b_0);
        WRITE_CHANNEL(preloaders_out[7][5], b_0);
        WRITE_CHANNEL(preloaders_out[7][6], b_0);
        WRITE_CHANNEL(preloaders_out[7][7], b_0);
    }
}
