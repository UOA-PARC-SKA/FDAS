
// Auto-generated file -- see `hsum_codegen.py` and `preld.cl.mako`.

channel float preloaders_out[8][8] __attribute__((depth(0)));

__attribute__((reqd_work_group_size(1680, 1, 1)))
kernel void preloader_1(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[1680];
    local   float buf_1[1680];
    local   float buf_2[1680];
    local   float buf_3[1680];
    local   float buf_4[1680];
    local   float buf_5[1680];
    local   float buf_6[1680];
    local   float buf_7[1680];
    private float ld[8];

    int  filter_base  = get_group_id(1) * 8 / 1;
    uint channel_base = get_group_id(0) * 1680;

    uint buffer = get_local_id(0) / 210;
    uint bundle = get_local_id(0) % 210;

    int  filter = filter_base + buffer;
    if (negative_filters)
        filter = -filter;

    if (buffer < 8) {
        #pragma unroll
        for (uint c = 0; c < 8; ++c)
            ld[c] = fop[FOP_IDX(filter, channel_base + bundle * 8 + c)];
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_0[bundle * 8 + c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_1[bundle * 8 + c] = ld[c];
            break;
        case 2:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_2[bundle * 8 + c] = ld[c];
            break;
        case 3:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_3[bundle * 8 + c] = ld[c];
            break;
        case 4:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_4[bundle * 8 + c] = ld[c];
            break;
        case 5:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_5[bundle * 8 + c] = ld[c];
            break;
        case 6:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_6[bundle * 8 + c] = ld[c];
            break;
        case 7:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_7[bundle * 8 + c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint step = get_local_id(0) / 1;

    float v_0 = buf_0[step];
    float v_1 = buf_1[step];
    float v_2 = buf_2[step];
    float v_3 = buf_3[step];
    float v_4 = buf_4[step];
    float v_5 = buf_5[step];
    float v_6 = buf_6[step];
    float v_7 = buf_7[step];

    WRITE_CHANNEL(preloaders_out[0][0], v_0);
    WRITE_CHANNEL(preloaders_out[0][1], v_1);
    WRITE_CHANNEL(preloaders_out[0][2], v_2);
    WRITE_CHANNEL(preloaders_out[0][3], v_3);
    WRITE_CHANNEL(preloaders_out[0][4], v_4);
    WRITE_CHANNEL(preloaders_out[0][5], v_5);
    WRITE_CHANNEL(preloaders_out[0][6], v_6);
    WRITE_CHANNEL(preloaders_out[0][7], v_7);
}

__attribute__((reqd_work_group_size(1680, 1, 1)))
kernel void preloader_2(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[840];
    local   float buf_1[840];
    local   float buf_2[840];
    local   float buf_3[840];
    private float ld[8];

    int  filter_base  = get_group_id(1) * 8 / 2;
    uint channel_base = get_group_id(0) * 840;

    uint buffer = get_local_id(0) / 105;
    uint bundle = get_local_id(0) % 105;

    int  filter = filter_base + buffer;
    if (negative_filters)
        filter = -filter;

    if (buffer < 4) {
        #pragma unroll
        for (uint c = 0; c < 8; ++c)
            ld[c] = fop[FOP_IDX(filter, channel_base + bundle * 8 + c)];
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_0[bundle * 8 + c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_1[bundle * 8 + c] = ld[c];
            break;
        case 2:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_2[bundle * 8 + c] = ld[c];
            break;
        case 3:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_3[bundle * 8 + c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint step = get_local_id(0) / 2;

    float v_0 = buf_0[step];
    float v_1 = buf_1[step];
    float v_2 = buf_2[step];
    float v_3 = buf_3[step];

    WRITE_CHANNEL(preloaders_out[1][0], v_0);
    WRITE_CHANNEL(preloaders_out[1][1], v_0);
    WRITE_CHANNEL(preloaders_out[1][2], v_1);
    WRITE_CHANNEL(preloaders_out[1][3], v_1);
    WRITE_CHANNEL(preloaders_out[1][4], v_2);
    WRITE_CHANNEL(preloaders_out[1][5], v_2);
    WRITE_CHANNEL(preloaders_out[1][6], v_3);
    WRITE_CHANNEL(preloaders_out[1][7], v_3);
}

__attribute__((reqd_work_group_size(1680, 1, 1)))
kernel void preloader_3(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[560];
    local   float buf_1[560];
    local   float buf_2[560];
    local   float buf_3[560];
    private float ld[8];

    int  filter_base  = get_group_id(1) * 8 / 3;
    uint row_offset   = get_group_id(1) * 8 % 3;
    uint channel_base = get_group_id(0) * 560;

    uint buffer = get_local_id(0) / 70;
    uint bundle = get_local_id(0) % 70;

    int  filter = filter_base + buffer;
    if (negative_filters)
        filter = -filter;

    if (buffer < 4) {
        if (buffer < 3 || row_offset >= 2) {
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                ld[c] = fop[FOP_IDX(filter, channel_base + bundle * 8 + c)];
        } else {
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                ld[c] = 0.0f;
        }
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_0[bundle * 8 + c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_1[bundle * 8 + c] = ld[c];
            break;
        case 2:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_2[bundle * 8 + c] = ld[c];
            break;
        case 3:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_3[bundle * 8 + c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint step = get_local_id(0) / 3;

    float v_0 = buf_0[step];
    float v_1 = buf_1[step];
    float v_2 = buf_2[step];
    float v_3 = buf_3[step];

    WRITE_CHANNEL(preloaders_out[2][0], v_0);
    WRITE_CHANNEL(preloaders_out[2][1], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[2][2], row_offset < 1 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[2][3], v_1);
    WRITE_CHANNEL(preloaders_out[2][4], row_offset < 2 ? v_1 : v_2);
    WRITE_CHANNEL(preloaders_out[2][5], row_offset < 1 ? v_1 : v_2);
    WRITE_CHANNEL(preloaders_out[2][6], v_2);
    WRITE_CHANNEL(preloaders_out[2][7], row_offset < 2 ? v_2 : v_3);
}

__attribute__((reqd_work_group_size(1680, 1, 1)))
kernel void preloader_4(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[424];
    local   float buf_1[424];
    private float ld[8];

    int  filter_base  = get_group_id(1) * 8 / 4;
    uint channel_base = get_group_id(0) * 420;

    uint buffer = get_local_id(0) / 53;
    uint bundle = get_local_id(0) % 53;

    int  filter = filter_base + buffer;
    if (negative_filters)
        filter = -filter;

    if (buffer < 2) {
        #pragma unroll
        for (uint c = 0; c < 8; ++c)
            ld[c] = fop[FOP_IDX(filter, channel_base + bundle * 8 + c)];
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_0[bundle * 8 + c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_1[bundle * 8 + c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint step = get_local_id(0) / 4;

    float v_0 = buf_0[step];
    float v_1 = buf_1[step];

    WRITE_CHANNEL(preloaders_out[3][0], v_0);
    WRITE_CHANNEL(preloaders_out[3][1], v_0);
    WRITE_CHANNEL(preloaders_out[3][2], v_0);
    WRITE_CHANNEL(preloaders_out[3][3], v_0);
    WRITE_CHANNEL(preloaders_out[3][4], v_1);
    WRITE_CHANNEL(preloaders_out[3][5], v_1);
    WRITE_CHANNEL(preloaders_out[3][6], v_1);
    WRITE_CHANNEL(preloaders_out[3][7], v_1);
}

__attribute__((reqd_work_group_size(1680, 1, 1)))
kernel void preloader_5(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[336];
    local   float buf_1[336];
    local   float buf_2[336];
    private float ld[8];

    int  filter_base  = get_group_id(1) * 8 / 5;
    uint row_offset   = get_group_id(1) * 8 % 5;
    uint channel_base = get_group_id(0) * 336;

    uint buffer = get_local_id(0) / 42;
    uint bundle = get_local_id(0) % 42;

    int  filter = filter_base + buffer;
    if (negative_filters)
        filter = -filter;

    if (buffer < 3) {
        if (buffer < 2 || row_offset >= 3) {
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                ld[c] = fop[FOP_IDX(filter, channel_base + bundle * 8 + c)];
        } else {
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                ld[c] = 0.0f;
        }
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_0[bundle * 8 + c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_1[bundle * 8 + c] = ld[c];
            break;
        case 2:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_2[bundle * 8 + c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint step = get_local_id(0) / 5;

    float v_0 = buf_0[step];
    float v_1 = buf_1[step];
    float v_2 = buf_2[step];

    WRITE_CHANNEL(preloaders_out[4][0], v_0);
    WRITE_CHANNEL(preloaders_out[4][1], row_offset < 4 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[4][2], row_offset < 3 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[4][3], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[4][4], row_offset < 1 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[4][5], v_1);
    WRITE_CHANNEL(preloaders_out[4][6], row_offset < 4 ? v_1 : v_2);
    WRITE_CHANNEL(preloaders_out[4][7], row_offset < 3 ? v_1 : v_2);
}

__attribute__((reqd_work_group_size(1680, 1, 1)))
kernel void preloader_6(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[280];
    local   float buf_1[280];
    private float ld[8];

    int  filter_base  = get_group_id(1) * 8 / 6;
    uint row_offset   = get_group_id(1) * 8 % 6;
    uint channel_base = get_group_id(0) * 280;

    uint buffer = get_local_id(0) / 35;
    uint bundle = get_local_id(0) % 35;

    int  filter = filter_base + buffer;
    if (negative_filters)
        filter = -filter;

    if (buffer < 2) {
        #pragma unroll
        for (uint c = 0; c < 8; ++c)
            ld[c] = fop[FOP_IDX(filter, channel_base + bundle * 8 + c)];
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_0[bundle * 8 + c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_1[bundle * 8 + c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint step = get_local_id(0) / 6;

    float v_0 = buf_0[step];
    float v_1 = buf_1[step];

    WRITE_CHANNEL(preloaders_out[5][0], v_0);
    WRITE_CHANNEL(preloaders_out[5][1], v_0);
    WRITE_CHANNEL(preloaders_out[5][2], row_offset < 4 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[5][3], row_offset < 4 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[5][4], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[5][5], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[5][6], v_1);
    WRITE_CHANNEL(preloaders_out[5][7], v_1);
}

__attribute__((reqd_work_group_size(1680, 1, 1)))
kernel void preloader_7(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[240];
    local   float buf_1[240];
    private float ld[8];

    int  filter_base  = get_group_id(1) * 8 / 7;
    uint row_offset   = get_group_id(1) * 8 % 7;
    uint channel_base = get_group_id(0) * 240;

    uint buffer = get_local_id(0) / 30;
    uint bundle = get_local_id(0) % 30;

    int  filter = filter_base + buffer;
    if (negative_filters)
        filter = -filter;

    if (buffer < 2) {
        #pragma unroll
        for (uint c = 0; c < 8; ++c)
            ld[c] = fop[FOP_IDX(filter, channel_base + bundle * 8 + c)];
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_0[bundle * 8 + c] = ld[c];
            break;
        case 1:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_1[bundle * 8 + c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint step = get_local_id(0) / 7;

    float v_0 = buf_0[step];
    float v_1 = buf_1[step];

    WRITE_CHANNEL(preloaders_out[6][0], v_0);
    WRITE_CHANNEL(preloaders_out[6][1], row_offset < 6 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[6][2], row_offset < 5 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[6][3], row_offset < 4 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[6][4], row_offset < 3 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[6][5], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[6][6], row_offset < 1 ? v_0 : v_1);
    WRITE_CHANNEL(preloaders_out[6][7], v_1);
}

__attribute__((reqd_work_group_size(1680, 1, 1)))
kernel void preloader_8(global float * restrict fop,
                        const uint negative_filters)
{
    local   float buf_0[216];
    private float ld[8];

    int  filter_base  = get_group_id(1) * 8 / 8;
    uint channel_base = get_group_id(0) * 210;

    uint buffer = get_local_id(0) / 27;
    uint bundle = get_local_id(0) % 27;

    int  filter = filter_base + buffer;
    if (negative_filters)
        filter = -filter;

    if (buffer < 1) {
        #pragma unroll
        for (uint c = 0; c < 8; ++c)
            ld[c] = fop[FOP_IDX(filter, channel_base + bundle * 8 + c)];
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint c = 0; c < 8; ++c)
                buf_0[bundle * 8 + c] = ld[c];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint step = get_local_id(0) / 8;

    float v_0 = buf_0[step];

    WRITE_CHANNEL(preloaders_out[7][0], v_0);
    WRITE_CHANNEL(preloaders_out[7][1], v_0);
    WRITE_CHANNEL(preloaders_out[7][2], v_0);
    WRITE_CHANNEL(preloaders_out[7][3], v_0);
    WRITE_CHANNEL(preloaders_out[7][4], v_0);
    WRITE_CHANNEL(preloaders_out[7][5], v_0);
    WRITE_CHANNEL(preloaders_out[7][6], v_0);
    WRITE_CHANNEL(preloaders_out[7][7], v_0);
}
