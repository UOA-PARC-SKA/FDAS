
// Auto-generated file -- see `hsum_codegen.py` and `preload.cl.mako`.

channel float preload_to_detect[8][16] __attribute__((depth(0)));

__attribute__((reqd_work_group_size(3360, 1, 1)))
kernel void preload_1(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[3360];
    local   float buffer_1[3360];
    local   float buffer_2[3360];
    local   float buffer_3[3360];
    local   float buffer_4[3360];
    local   float buffer_5[3360];
    local   float buffer_6[3360];
    local   float buffer_7[3360];
    local   float buffer_8[3360];
    local   float buffer_9[3360];
    local   float buffer_10[3360];
    local   float buffer_11[3360];
    local   float buffer_12[3360];
    local   float buffer_13[3360];
    local   float buffer_14[3360];
    local   float buffer_15[3360];
    private float bundle_load[16];

    int  filter_base  = get_group_id(1) * 16 / 1;
    uint channel_base = get_group_id(0) * 3360;

    uint buffer = get_local_id(0) / 210;
    uint bundle = get_local_id(0) % 210;

    int  filter = filter_base + buffer;

    if (   buffer < 16
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 16 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_0[bundle * 16 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_1[bundle * 16 + x] = bundle_load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_2[bundle * 16 + x] = bundle_load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_3[bundle * 16 + x] = bundle_load[x];
            break;
        case 4:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_4[bundle * 16 + x] = bundle_load[x];
            break;
        case 5:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_5[bundle * 16 + x] = bundle_load[x];
            break;
        case 6:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_6[bundle * 16 + x] = bundle_load[x];
            break;
        case 7:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_7[bundle * 16 + x] = bundle_load[x];
            break;
        case 8:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_8[bundle * 16 + x] = bundle_load[x];
            break;
        case 9:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_9[bundle * 16 + x] = bundle_load[x];
            break;
        case 10:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_10[bundle * 16 + x] = bundle_load[x];
            break;
        case 11:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_11[bundle * 16 + x] = bundle_load[x];
            break;
        case 12:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_12[bundle * 16 + x] = bundle_load[x];
            break;
        case 13:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_13[bundle * 16 + x] = bundle_load[x];
            break;
        case 14:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_14[bundle * 16 + x] = bundle_load[x];
            break;
        case 15:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_15[bundle * 16 + x] = bundle_load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / 1;

    float v_0 = buffer_0[chan];
    float v_1 = buffer_1[chan];
    float v_2 = buffer_2[chan];
    float v_3 = buffer_3[chan];
    float v_4 = buffer_4[chan];
    float v_5 = buffer_5[chan];
    float v_6 = buffer_6[chan];
    float v_7 = buffer_7[chan];
    float v_8 = buffer_8[chan];
    float v_9 = buffer_9[chan];
    float v_10 = buffer_10[chan];
    float v_11 = buffer_11[chan];
    float v_12 = buffer_12[chan];
    float v_13 = buffer_13[chan];
    float v_14 = buffer_14[chan];
    float v_15 = buffer_15[chan];

    WRITE_CHANNEL(preload_to_detect[0][0], v_0);
    WRITE_CHANNEL(preload_to_detect[0][1], v_1);
    WRITE_CHANNEL(preload_to_detect[0][2], v_2);
    WRITE_CHANNEL(preload_to_detect[0][3], v_3);
    WRITE_CHANNEL(preload_to_detect[0][4], v_4);
    WRITE_CHANNEL(preload_to_detect[0][5], v_5);
    WRITE_CHANNEL(preload_to_detect[0][6], v_6);
    WRITE_CHANNEL(preload_to_detect[0][7], v_7);
    WRITE_CHANNEL(preload_to_detect[0][8], v_8);
    WRITE_CHANNEL(preload_to_detect[0][9], v_9);
    WRITE_CHANNEL(preload_to_detect[0][10], v_10);
    WRITE_CHANNEL(preload_to_detect[0][11], v_11);
    WRITE_CHANNEL(preload_to_detect[0][12], v_12);
    WRITE_CHANNEL(preload_to_detect[0][13], v_13);
    WRITE_CHANNEL(preload_to_detect[0][14], v_14);
    WRITE_CHANNEL(preload_to_detect[0][15], v_15);
}

__attribute__((reqd_work_group_size(3360, 1, 1)))
kernel void preload_2(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[1680];
    local   float buffer_1[1680];
    local   float buffer_2[1680];
    local   float buffer_3[1680];
    local   float buffer_4[1680];
    local   float buffer_5[1680];
    local   float buffer_6[1680];
    local   float buffer_7[1680];
    private float bundle_load[16];

    int  filter_base  = get_group_id(1) * 16 / 2;
    uint channel_base = get_group_id(0) * 1680;

    uint buffer = get_local_id(0) / 105;
    uint bundle = get_local_id(0) % 105;

    int  filter = filter_base + buffer;

    if (   buffer < 8
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 16 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_0[bundle * 16 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_1[bundle * 16 + x] = bundle_load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_2[bundle * 16 + x] = bundle_load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_3[bundle * 16 + x] = bundle_load[x];
            break;
        case 4:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_4[bundle * 16 + x] = bundle_load[x];
            break;
        case 5:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_5[bundle * 16 + x] = bundle_load[x];
            break;
        case 6:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_6[bundle * 16 + x] = bundle_load[x];
            break;
        case 7:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_7[bundle * 16 + x] = bundle_load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / 2;

    float v_0 = buffer_0[chan];
    float v_1 = buffer_1[chan];
    float v_2 = buffer_2[chan];
    float v_3 = buffer_3[chan];
    float v_4 = buffer_4[chan];
    float v_5 = buffer_5[chan];
    float v_6 = buffer_6[chan];
    float v_7 = buffer_7[chan];

    WRITE_CHANNEL(preload_to_detect[1][0], v_0);
    WRITE_CHANNEL(preload_to_detect[1][1], v_0);
    WRITE_CHANNEL(preload_to_detect[1][2], v_1);
    WRITE_CHANNEL(preload_to_detect[1][3], v_1);
    WRITE_CHANNEL(preload_to_detect[1][4], v_2);
    WRITE_CHANNEL(preload_to_detect[1][5], v_2);
    WRITE_CHANNEL(preload_to_detect[1][6], v_3);
    WRITE_CHANNEL(preload_to_detect[1][7], v_3);
    WRITE_CHANNEL(preload_to_detect[1][8], v_4);
    WRITE_CHANNEL(preload_to_detect[1][9], v_4);
    WRITE_CHANNEL(preload_to_detect[1][10], v_5);
    WRITE_CHANNEL(preload_to_detect[1][11], v_5);
    WRITE_CHANNEL(preload_to_detect[1][12], v_6);
    WRITE_CHANNEL(preload_to_detect[1][13], v_6);
    WRITE_CHANNEL(preload_to_detect[1][14], v_7);
    WRITE_CHANNEL(preload_to_detect[1][15], v_7);
}

__attribute__((reqd_work_group_size(3360, 1, 1)))
kernel void preload_3(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[1120];
    local   float buffer_1[1120];
    local   float buffer_2[1120];
    local   float buffer_3[1120];
    local   float buffer_4[1120];
    local   float buffer_5[1120];
    private float bundle_load[16];

    int  filter_base  = get_group_id(1) * 16 / 3;
    uint row_offset   = get_group_id(1) * 16 % 3;
    uint channel_base = get_group_id(0) * 1120;

    uint buffer = get_local_id(0) / 70;
    uint bundle = get_local_id(0) % 70;

    int  filter = filter_base + buffer;

    if (   buffer < 6
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 16 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_0[bundle * 16 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_1[bundle * 16 + x] = bundle_load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_2[bundle * 16 + x] = bundle_load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_3[bundle * 16 + x] = bundle_load[x];
            break;
        case 4:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_4[bundle * 16 + x] = bundle_load[x];
            break;
        case 5:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_5[bundle * 16 + x] = bundle_load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / 3;

    float v_0 = buffer_0[chan];
    float v_1 = buffer_1[chan];
    float v_2 = buffer_2[chan];
    float v_3 = buffer_3[chan];
    float v_4 = buffer_4[chan];
    float v_5 = buffer_5[chan];

    WRITE_CHANNEL(preload_to_detect[2][0], v_0);
    WRITE_CHANNEL(preload_to_detect[2][1], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[2][2], row_offset < 1 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[2][3], v_1);
    WRITE_CHANNEL(preload_to_detect[2][4], row_offset < 2 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[2][5], row_offset < 1 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[2][6], v_2);
    WRITE_CHANNEL(preload_to_detect[2][7], row_offset < 2 ? v_2 : v_3);
    WRITE_CHANNEL(preload_to_detect[2][8], row_offset < 1 ? v_2 : v_3);
    WRITE_CHANNEL(preload_to_detect[2][9], v_3);
    WRITE_CHANNEL(preload_to_detect[2][10], row_offset < 2 ? v_3 : v_4);
    WRITE_CHANNEL(preload_to_detect[2][11], row_offset < 1 ? v_3 : v_4);
    WRITE_CHANNEL(preload_to_detect[2][12], v_4);
    WRITE_CHANNEL(preload_to_detect[2][13], row_offset < 2 ? v_4 : v_5);
    WRITE_CHANNEL(preload_to_detect[2][14], row_offset < 1 ? v_4 : v_5);
    WRITE_CHANNEL(preload_to_detect[2][15], v_5);
}

__attribute__((reqd_work_group_size(3360, 1, 1)))
kernel void preload_4(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[848];
    local   float buffer_1[848];
    local   float buffer_2[848];
    local   float buffer_3[848];
    private float bundle_load[16];

    int  filter_base  = get_group_id(1) * 16 / 4;
    uint channel_base = get_group_id(0) * 840;

    uint buffer = get_local_id(0) / 53;
    uint bundle = get_local_id(0) % 53;

    int  filter = filter_base + buffer;

    if (   buffer < 4
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 16 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_0[bundle * 16 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_1[bundle * 16 + x] = bundle_load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_2[bundle * 16 + x] = bundle_load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_3[bundle * 16 + x] = bundle_load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / 4;

    float v_0 = buffer_0[chan];
    float v_1 = buffer_1[chan];
    float v_2 = buffer_2[chan];
    float v_3 = buffer_3[chan];

    WRITE_CHANNEL(preload_to_detect[3][0], v_0);
    WRITE_CHANNEL(preload_to_detect[3][1], v_0);
    WRITE_CHANNEL(preload_to_detect[3][2], v_0);
    WRITE_CHANNEL(preload_to_detect[3][3], v_0);
    WRITE_CHANNEL(preload_to_detect[3][4], v_1);
    WRITE_CHANNEL(preload_to_detect[3][5], v_1);
    WRITE_CHANNEL(preload_to_detect[3][6], v_1);
    WRITE_CHANNEL(preload_to_detect[3][7], v_1);
    WRITE_CHANNEL(preload_to_detect[3][8], v_2);
    WRITE_CHANNEL(preload_to_detect[3][9], v_2);
    WRITE_CHANNEL(preload_to_detect[3][10], v_2);
    WRITE_CHANNEL(preload_to_detect[3][11], v_2);
    WRITE_CHANNEL(preload_to_detect[3][12], v_3);
    WRITE_CHANNEL(preload_to_detect[3][13], v_3);
    WRITE_CHANNEL(preload_to_detect[3][14], v_3);
    WRITE_CHANNEL(preload_to_detect[3][15], v_3);
}

__attribute__((reqd_work_group_size(3360, 1, 1)))
kernel void preload_5(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[672];
    local   float buffer_1[672];
    local   float buffer_2[672];
    local   float buffer_3[672];
    private float bundle_load[16];

    int  filter_base  = get_group_id(1) * 16 / 5;
    uint row_offset   = get_group_id(1) * 16 % 5;
    uint channel_base = get_group_id(0) * 672;

    uint buffer = get_local_id(0) / 42;
    uint bundle = get_local_id(0) % 42;

    int  filter = filter_base + buffer;

    if (   buffer < 4
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 16 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_0[bundle * 16 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_1[bundle * 16 + x] = bundle_load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_2[bundle * 16 + x] = bundle_load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_3[bundle * 16 + x] = bundle_load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / 5;

    float v_0 = buffer_0[chan];
    float v_1 = buffer_1[chan];
    float v_2 = buffer_2[chan];
    float v_3 = buffer_3[chan];

    WRITE_CHANNEL(preload_to_detect[4][0], v_0);
    WRITE_CHANNEL(preload_to_detect[4][1], row_offset < 4 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[4][2], row_offset < 3 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[4][3], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[4][4], row_offset < 1 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[4][5], v_1);
    WRITE_CHANNEL(preload_to_detect[4][6], row_offset < 4 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[4][7], row_offset < 3 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[4][8], row_offset < 2 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[4][9], row_offset < 1 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[4][10], v_2);
    WRITE_CHANNEL(preload_to_detect[4][11], row_offset < 4 ? v_2 : v_3);
    WRITE_CHANNEL(preload_to_detect[4][12], row_offset < 3 ? v_2 : v_3);
    WRITE_CHANNEL(preload_to_detect[4][13], row_offset < 2 ? v_2 : v_3);
    WRITE_CHANNEL(preload_to_detect[4][14], row_offset < 1 ? v_2 : v_3);
    WRITE_CHANNEL(preload_to_detect[4][15], v_3);
}

__attribute__((reqd_work_group_size(3360, 1, 1)))
kernel void preload_6(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[560];
    local   float buffer_1[560];
    local   float buffer_2[560];
    local   float buffer_3[560];
    private float bundle_load[16];

    int  filter_base  = get_group_id(1) * 16 / 6;
    uint row_offset   = get_group_id(1) * 16 % 6;
    uint channel_base = get_group_id(0) * 560;

    uint buffer = get_local_id(0) / 35;
    uint bundle = get_local_id(0) % 35;

    int  filter = filter_base + buffer;

    if (   buffer < 4
        && (buffer < 3 || row_offset >= 4)
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 16 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_0[bundle * 16 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_1[bundle * 16 + x] = bundle_load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_2[bundle * 16 + x] = bundle_load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_3[bundle * 16 + x] = bundle_load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / 6;

    float v_0 = buffer_0[chan];
    float v_1 = buffer_1[chan];
    float v_2 = buffer_2[chan];
    float v_3 = buffer_3[chan];

    WRITE_CHANNEL(preload_to_detect[5][0], v_0);
    WRITE_CHANNEL(preload_to_detect[5][1], v_0);
    WRITE_CHANNEL(preload_to_detect[5][2], row_offset < 4 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[5][3], row_offset < 4 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[5][4], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[5][5], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[5][6], v_1);
    WRITE_CHANNEL(preload_to_detect[5][7], v_1);
    WRITE_CHANNEL(preload_to_detect[5][8], row_offset < 4 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[5][9], row_offset < 4 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[5][10], row_offset < 2 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[5][11], row_offset < 2 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[5][12], v_2);
    WRITE_CHANNEL(preload_to_detect[5][13], v_2);
    WRITE_CHANNEL(preload_to_detect[5][14], row_offset < 4 ? v_2 : v_3);
    WRITE_CHANNEL(preload_to_detect[5][15], row_offset < 4 ? v_2 : v_3);
}

__attribute__((reqd_work_group_size(3360, 1, 1)))
kernel void preload_7(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[480];
    local   float buffer_1[480];
    local   float buffer_2[480];
    local   float buffer_3[480];
    private float bundle_load[16];

    int  filter_base  = get_group_id(1) * 16 / 7;
    uint row_offset   = get_group_id(1) * 16 % 7;
    uint channel_base = get_group_id(0) * 480;

    uint buffer = get_local_id(0) / 30;
    uint bundle = get_local_id(0) % 30;

    int  filter = filter_base + buffer;

    if (   buffer < 4
        && (buffer < 3 || row_offset >= 6)
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 16 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_0[bundle * 16 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_1[bundle * 16 + x] = bundle_load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_2[bundle * 16 + x] = bundle_load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_3[bundle * 16 + x] = bundle_load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / 7;

    float v_0 = buffer_0[chan];
    float v_1 = buffer_1[chan];
    float v_2 = buffer_2[chan];
    float v_3 = buffer_3[chan];

    WRITE_CHANNEL(preload_to_detect[6][0], v_0);
    WRITE_CHANNEL(preload_to_detect[6][1], row_offset < 6 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[6][2], row_offset < 5 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[6][3], row_offset < 4 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[6][4], row_offset < 3 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[6][5], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[6][6], row_offset < 1 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[6][7], v_1);
    WRITE_CHANNEL(preload_to_detect[6][8], row_offset < 6 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[6][9], row_offset < 5 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[6][10], row_offset < 4 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[6][11], row_offset < 3 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[6][12], row_offset < 2 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[6][13], row_offset < 1 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[6][14], v_2);
    WRITE_CHANNEL(preload_to_detect[6][15], row_offset < 6 ? v_2 : v_3);
}

__attribute__((reqd_work_group_size(3360, 1, 1)))
kernel void preload_8(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[432];
    local   float buffer_1[432];
    private float bundle_load[16];

    int  filter_base  = get_group_id(1) * 16 / 8;
    uint channel_base = get_group_id(0) * 420;

    uint buffer = get_local_id(0) / 27;
    uint bundle = get_local_id(0) % 27;

    int  filter = filter_base + buffer;

    if (   buffer < 2
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 16 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_0[bundle * 16 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_1[bundle * 16 + x] = bundle_load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / 8;

    float v_0 = buffer_0[chan];
    float v_1 = buffer_1[chan];

    WRITE_CHANNEL(preload_to_detect[7][0], v_0);
    WRITE_CHANNEL(preload_to_detect[7][1], v_0);
    WRITE_CHANNEL(preload_to_detect[7][2], v_0);
    WRITE_CHANNEL(preload_to_detect[7][3], v_0);
    WRITE_CHANNEL(preload_to_detect[7][4], v_0);
    WRITE_CHANNEL(preload_to_detect[7][5], v_0);
    WRITE_CHANNEL(preload_to_detect[7][6], v_0);
    WRITE_CHANNEL(preload_to_detect[7][7], v_0);
    WRITE_CHANNEL(preload_to_detect[7][8], v_1);
    WRITE_CHANNEL(preload_to_detect[7][9], v_1);
    WRITE_CHANNEL(preload_to_detect[7][10], v_1);
    WRITE_CHANNEL(preload_to_detect[7][11], v_1);
    WRITE_CHANNEL(preload_to_detect[7][12], v_1);
    WRITE_CHANNEL(preload_to_detect[7][13], v_1);
    WRITE_CHANNEL(preload_to_detect[7][14], v_1);
    WRITE_CHANNEL(preload_to_detect[7][15], v_1);
}
