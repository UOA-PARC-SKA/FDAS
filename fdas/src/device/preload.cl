
// Auto-generated file -- see `hsum_codegen.py` and `preload.cl.mako`.

channel float preload_to_detect[8][8] __attribute__((depth(0)));

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
    private float bundle_load[8];

    int  filter_base  = get_group_id(1) * 8 / 1;
    uint channel_base = get_group_id(0) * 3360;

    uint buffer = get_local_id(0) / 420;
    uint bundle = get_local_id(0) % 420;

    int  filter = filter_base + buffer;

    if (   buffer < 8
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 8 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_0[bundle * 8 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_1[bundle * 8 + x] = bundle_load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_2[bundle * 8 + x] = bundle_load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_3[bundle * 8 + x] = bundle_load[x];
            break;
        case 4:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_4[bundle * 8 + x] = bundle_load[x];
            break;
        case 5:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_5[bundle * 8 + x] = bundle_load[x];
            break;
        case 6:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_6[bundle * 8 + x] = bundle_load[x];
            break;
        case 7:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_7[bundle * 8 + x] = bundle_load[x];
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

    WRITE_CHANNEL(preload_to_detect[0][0], v_0);
    WRITE_CHANNEL(preload_to_detect[0][1], v_1);
    WRITE_CHANNEL(preload_to_detect[0][2], v_2);
    WRITE_CHANNEL(preload_to_detect[0][3], v_3);
    WRITE_CHANNEL(preload_to_detect[0][4], v_4);
    WRITE_CHANNEL(preload_to_detect[0][5], v_5);
    WRITE_CHANNEL(preload_to_detect[0][6], v_6);
    WRITE_CHANNEL(preload_to_detect[0][7], v_7);
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
    private float bundle_load[8];

    int  filter_base  = get_group_id(1) * 8 / 2;
    uint channel_base = get_group_id(0) * 1680;

    uint buffer = get_local_id(0) / 210;
    uint bundle = get_local_id(0) % 210;

    int  filter = filter_base + buffer;

    if (   buffer < 4
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 8 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_0[bundle * 8 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_1[bundle * 8 + x] = bundle_load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_2[bundle * 8 + x] = bundle_load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_3[bundle * 8 + x] = bundle_load[x];
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

    WRITE_CHANNEL(preload_to_detect[1][0], v_0);
    WRITE_CHANNEL(preload_to_detect[1][1], v_0);
    WRITE_CHANNEL(preload_to_detect[1][2], v_1);
    WRITE_CHANNEL(preload_to_detect[1][3], v_1);
    WRITE_CHANNEL(preload_to_detect[1][4], v_2);
    WRITE_CHANNEL(preload_to_detect[1][5], v_2);
    WRITE_CHANNEL(preload_to_detect[1][6], v_3);
    WRITE_CHANNEL(preload_to_detect[1][7], v_3);
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
    private float bundle_load[8];

    int  filter_base  = get_group_id(1) * 8 / 3;
    uint row_offset   = get_group_id(1) * 8 % 3;
    uint channel_base = get_group_id(0) * 1120;

    uint buffer = get_local_id(0) / 140;
    uint bundle = get_local_id(0) % 140;

    int  filter = filter_base + buffer;

    if (   buffer < 4
        && (buffer < 3 || row_offset >= 2)
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 8 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_0[bundle * 8 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_1[bundle * 8 + x] = bundle_load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_2[bundle * 8 + x] = bundle_load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_3[bundle * 8 + x] = bundle_load[x];
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

    WRITE_CHANNEL(preload_to_detect[2][0], v_0);
    WRITE_CHANNEL(preload_to_detect[2][1], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[2][2], row_offset < 1 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[2][3], v_1);
    WRITE_CHANNEL(preload_to_detect[2][4], row_offset < 2 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[2][5], row_offset < 1 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[2][6], v_2);
    WRITE_CHANNEL(preload_to_detect[2][7], row_offset < 2 ? v_2 : v_3);
}

__attribute__((reqd_work_group_size(3360, 1, 1)))
kernel void preload_4(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[840];
    local   float buffer_1[840];
    private float bundle_load[8];

    int  filter_base  = get_group_id(1) * 8 / 4;
    uint channel_base = get_group_id(0) * 840;

    uint buffer = get_local_id(0) / 105;
    uint bundle = get_local_id(0) % 105;

    int  filter = filter_base + buffer;

    if (   buffer < 2
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 8 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_0[bundle * 8 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_1[bundle * 8 + x] = bundle_load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / 4;

    float v_0 = buffer_0[chan];
    float v_1 = buffer_1[chan];

    WRITE_CHANNEL(preload_to_detect[3][0], v_0);
    WRITE_CHANNEL(preload_to_detect[3][1], v_0);
    WRITE_CHANNEL(preload_to_detect[3][2], v_0);
    WRITE_CHANNEL(preload_to_detect[3][3], v_0);
    WRITE_CHANNEL(preload_to_detect[3][4], v_1);
    WRITE_CHANNEL(preload_to_detect[3][5], v_1);
    WRITE_CHANNEL(preload_to_detect[3][6], v_1);
    WRITE_CHANNEL(preload_to_detect[3][7], v_1);
}

__attribute__((reqd_work_group_size(3360, 1, 1)))
kernel void preload_5(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[672];
    local   float buffer_1[672];
    local   float buffer_2[672];
    private float bundle_load[8];

    int  filter_base  = get_group_id(1) * 8 / 5;
    uint row_offset   = get_group_id(1) * 8 % 5;
    uint channel_base = get_group_id(0) * 672;

    uint buffer = get_local_id(0) / 84;
    uint bundle = get_local_id(0) % 84;

    int  filter = filter_base + buffer;

    if (   buffer < 3
        && (buffer < 2 || row_offset >= 3)
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 8 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_0[bundle * 8 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_1[bundle * 8 + x] = bundle_load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_2[bundle * 8 + x] = bundle_load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / 5;

    float v_0 = buffer_0[chan];
    float v_1 = buffer_1[chan];
    float v_2 = buffer_2[chan];

    WRITE_CHANNEL(preload_to_detect[4][0], v_0);
    WRITE_CHANNEL(preload_to_detect[4][1], row_offset < 4 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[4][2], row_offset < 3 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[4][3], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[4][4], row_offset < 1 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[4][5], v_1);
    WRITE_CHANNEL(preload_to_detect[4][6], row_offset < 4 ? v_1 : v_2);
    WRITE_CHANNEL(preload_to_detect[4][7], row_offset < 3 ? v_1 : v_2);
}

__attribute__((reqd_work_group_size(3360, 1, 1)))
kernel void preload_6(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[560];
    local   float buffer_1[560];
    private float bundle_load[8];

    int  filter_base  = get_group_id(1) * 8 / 6;
    uint row_offset   = get_group_id(1) * 8 % 6;
    uint channel_base = get_group_id(0) * 560;

    uint buffer = get_local_id(0) / 70;
    uint bundle = get_local_id(0) % 70;

    int  filter = filter_base + buffer;

    if (   buffer < 2
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 8 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_0[bundle * 8 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_1[bundle * 8 + x] = bundle_load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / 6;

    float v_0 = buffer_0[chan];
    float v_1 = buffer_1[chan];

    WRITE_CHANNEL(preload_to_detect[5][0], v_0);
    WRITE_CHANNEL(preload_to_detect[5][1], v_0);
    WRITE_CHANNEL(preload_to_detect[5][2], row_offset < 4 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[5][3], row_offset < 4 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[5][4], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[5][5], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[5][6], v_1);
    WRITE_CHANNEL(preload_to_detect[5][7], v_1);
}

__attribute__((reqd_work_group_size(3360, 1, 1)))
kernel void preload_7(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[480];
    local   float buffer_1[480];
    private float bundle_load[8];

    int  filter_base  = get_group_id(1) * 8 / 7;
    uint row_offset   = get_group_id(1) * 8 % 7;
    uint channel_base = get_group_id(0) * 480;

    uint buffer = get_local_id(0) / 60;
    uint bundle = get_local_id(0) % 60;

    int  filter = filter_base + buffer;

    if (   buffer < 2
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 8 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_0[bundle * 8 + x] = bundle_load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_1[bundle * 8 + x] = bundle_load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / 7;

    float v_0 = buffer_0[chan];
    float v_1 = buffer_1[chan];

    WRITE_CHANNEL(preload_to_detect[6][0], v_0);
    WRITE_CHANNEL(preload_to_detect[6][1], row_offset < 6 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[6][2], row_offset < 5 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[6][3], row_offset < 4 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[6][4], row_offset < 3 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[6][5], row_offset < 2 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[6][6], row_offset < 1 ? v_0 : v_1);
    WRITE_CHANNEL(preload_to_detect[6][7], v_1);
}

__attribute__((reqd_work_group_size(3360, 1, 1)))
kernel void preload_8(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[424];
    private float bundle_load[8];

    int  filter_base  = get_group_id(1) * 8 / 8;
    uint channel_base = get_group_id(0) * 420;

    uint buffer = get_local_id(0) / 53;
    uint bundle = get_local_id(0) % 53;

    int  filter = filter_base + buffer;

    if (   buffer < 1
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;

        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = fop[FOP_IDX(filter, channel_base + bundle * 8 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            bundle_load[x] = 0.0f;
    }

    switch (buffer) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_0[bundle * 8 + x] = bundle_load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint chan = get_local_id(0) / 8;

    float v_0 = buffer_0[chan];

    WRITE_CHANNEL(preload_to_detect[7][0], v_0);
    WRITE_CHANNEL(preload_to_detect[7][1], v_0);
    WRITE_CHANNEL(preload_to_detect[7][2], v_0);
    WRITE_CHANNEL(preload_to_detect[7][3], v_0);
    WRITE_CHANNEL(preload_to_detect[7][4], v_0);
    WRITE_CHANNEL(preload_to_detect[7][5], v_0);
    WRITE_CHANNEL(preload_to_detect[7][6], v_0);
    WRITE_CHANNEL(preload_to_detect[7][7], v_0);
}
