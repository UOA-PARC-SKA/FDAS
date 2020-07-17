
// Auto-generated file -- see `hsum_codegen.py` and `preld.cl.mako`.

channel float preloaders_out[8][4] __attribute__((depth(0)));

__attribute__((reqd_work_group_size(16, 1, 1)))
kernel void preloader_1(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[16];
    local   float buf_1[16];
    local   float buf_2[16];
    local   float buf_3[16];
    private float ld[16];

    int  filter_base  = get_group_id(1) * 4 / 1;
    uint channel_base = get_group_id(0) * 16;
    uint row_offset   = get_group_id(1) * 4 % 1;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 4) {
        #pragma unroll
        for (c = 0; c < 16; ++c)
            ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_0[c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_1[c] = ld[c];
            break;
        case 2:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_2[c] = ld[c];
            break;
        case 3:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_3[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0) / 1;

    float b_0 = buf_0[c];
    float b_1 = buf_1[c];
    float b_2 = buf_2[c];
    float b_3 = buf_3[c];

    WRITE_CHANNEL(preloaders_out[0][0], b_0);
    WRITE_CHANNEL(preloaders_out[0][1], b_1);
    WRITE_CHANNEL(preloaders_out[0][2], b_2);
    WRITE_CHANNEL(preloaders_out[0][3], b_3);
}

__attribute__((reqd_work_group_size(32, 1, 1)))
kernel void preloader_2(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[16];
    local   float buf_1[16];
    private float ld[16];

    int  filter_base  = get_group_id(1) * 4 / 2;
    uint channel_base = get_group_id(0) * 16;
    uint row_offset   = get_group_id(1) * 4 % 2;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 2) {
        #pragma unroll
        for (c = 0; c < 16; ++c)
            ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_0[c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_1[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0) / 2;

    float b_0 = buf_0[c];
    float b_1 = buf_1[c];

    WRITE_CHANNEL(preloaders_out[1][0], b_0);
    WRITE_CHANNEL(preloaders_out[1][1], b_0);
    WRITE_CHANNEL(preloaders_out[1][2], b_1);
    WRITE_CHANNEL(preloaders_out[1][3], b_1);
}

__attribute__((reqd_work_group_size(48, 1, 1)))
kernel void preloader_3(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[16];
    local   float buf_1[16];
    private float ld[16];

    int  filter_base  = get_group_id(1) * 4 / 3;
    uint channel_base = get_group_id(0) * 16;
    uint row_offset   = get_group_id(1) * 4 % 3;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 2) {
        #pragma unroll
        for (c = 0; c < 16; ++c)
            ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_0[c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_1[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0) / 3;

    float b_0 = buf_0[c];
    float b_1 = buf_1[c];

    WRITE_CHANNEL(preloaders_out[2][0], b_0);
    WRITE_CHANNEL(preloaders_out[2][1], row_offset < 2 ? b_0 : b_1);
    WRITE_CHANNEL(preloaders_out[2][2], row_offset < 1 ? b_0 : b_1);
    WRITE_CHANNEL(preloaders_out[2][3], b_1);
}

__attribute__((reqd_work_group_size(64, 1, 1)))
kernel void preloader_4(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[16];
    private float ld[16];

    int  filter_base  = get_group_id(1) * 4 / 4;
    uint channel_base = get_group_id(0) * 16;
    uint row_offset   = get_group_id(1) * 4 % 4;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 1) {
        #pragma unroll
        for (c = 0; c < 16; ++c)
            ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_0[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0) / 4;

    float b_0 = buf_0[c];

    WRITE_CHANNEL(preloaders_out[3][0], b_0);
    WRITE_CHANNEL(preloaders_out[3][1], b_0);
    WRITE_CHANNEL(preloaders_out[3][2], b_0);
    WRITE_CHANNEL(preloaders_out[3][3], b_0);
}

__attribute__((reqd_work_group_size(80, 1, 1)))
kernel void preloader_5(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[16];
    local   float buf_1[16];
    private float ld[16];

    int  filter_base  = get_group_id(1) * 4 / 5;
    uint channel_base = get_group_id(0) * 16;
    uint row_offset   = get_group_id(1) * 4 % 5;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 2) {
        if (get_local_id(0) < 1 || row_offset >= 2) {
            #pragma unroll
            for (c = 0; c < 16; ++c)
                ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
        } else {
            #pragma unroll
            for (c = 0; c < 16; ++c)
                ld[c] = 0.0f;
        }
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_0[c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_1[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0) / 5;

    float b_0 = buf_0[c];
    float b_1 = buf_1[c];

    WRITE_CHANNEL(preloaders_out[4][0], b_0);
    WRITE_CHANNEL(preloaders_out[4][1], row_offset < 4 ? b_0 : b_1);
    WRITE_CHANNEL(preloaders_out[4][2], row_offset < 3 ? b_0 : b_1);
    WRITE_CHANNEL(preloaders_out[4][3], row_offset < 2 ? b_0 : b_1);
}

__attribute__((reqd_work_group_size(96, 1, 1)))
kernel void preloader_6(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[16];
    local   float buf_1[16];
    private float ld[16];

    int  filter_base  = get_group_id(1) * 4 / 6;
    uint channel_base = get_group_id(0) * 16;
    uint row_offset   = get_group_id(1) * 4 % 6;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 2) {
        if (get_local_id(0) < 1 || row_offset >= 4) {
            #pragma unroll
            for (c = 0; c < 16; ++c)
                ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
        } else {
            #pragma unroll
            for (c = 0; c < 16; ++c)
                ld[c] = 0.0f;
        }
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_0[c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_1[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0) / 6;

    float b_0 = buf_0[c];
    float b_1 = buf_1[c];

    WRITE_CHANNEL(preloaders_out[5][0], b_0);
    WRITE_CHANNEL(preloaders_out[5][1], b_0);
    WRITE_CHANNEL(preloaders_out[5][2], row_offset < 4 ? b_0 : b_1);
    WRITE_CHANNEL(preloaders_out[5][3], row_offset < 4 ? b_0 : b_1);
}

__attribute__((reqd_work_group_size(112, 1, 1)))
kernel void preloader_7(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[16];
    local   float buf_1[16];
    private float ld[16];

    int  filter_base  = get_group_id(1) * 4 / 7;
    uint channel_base = get_group_id(0) * 16;
    uint row_offset   = get_group_id(1) * 4 % 7;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 2) {
        if (get_local_id(0) < 1 || row_offset >= 4) {
            #pragma unroll
            for (c = 0; c < 16; ++c)
                ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
        } else {
            #pragma unroll
            for (c = 0; c < 16; ++c)
                ld[c] = 0.0f;
        }
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_0[c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_1[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0) / 7;

    float b_0 = buf_0[c];
    float b_1 = buf_1[c];

    WRITE_CHANNEL(preloaders_out[6][0], b_0);
    WRITE_CHANNEL(preloaders_out[6][1], row_offset < 6 ? b_0 : b_1);
    WRITE_CHANNEL(preloaders_out[6][2], row_offset < 5 ? b_0 : b_1);
    WRITE_CHANNEL(preloaders_out[6][3], row_offset < 4 ? b_0 : b_1);
}

__attribute__((reqd_work_group_size(128, 1, 1)))
kernel void preloader_8(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[16];
    private float ld[16];

    int  filter_base  = get_group_id(1) * 4 / 8;
    uint channel_base = get_group_id(0) * 16;
    uint row_offset   = get_group_id(1) * 4 % 8;

    int  f;
    uint c;

    f = get_local_id(0);

    if (negative_filters) {
        filter_base = -filter_base;
        f           = -f;
    }

    if (get_local_id(0) < 1) {
        #pragma unroll
        for (c = 0; c < 16; ++c)
            ld[c] = fop[FOP_IDX(filter_base + f, channel_base + c)];
    }

    switch (get_local_id(0)) {
        case 0:
            #pragma unroll
            for (c = 0; c < 16; ++c)
                buf_0[c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    c = get_local_id(0) / 8;

    float b_0 = buf_0[c];

    WRITE_CHANNEL(preloaders_out[7][0], b_0);
    WRITE_CHANNEL(preloaders_out[7][1], b_0);
    WRITE_CHANNEL(preloaders_out[7][2], b_0);
    WRITE_CHANNEL(preloaders_out[7][3], b_0);
}
