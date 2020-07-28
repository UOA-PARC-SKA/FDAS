
// Auto-generated file -- see `hsum_codegen.py` and `preload.cl.mako`.

channel float preload_to_detect[8][8][1] __attribute__((depth(0)));

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_1(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[840];
    local   float buffer_1[840];
    local   float buffer_2[840];
    local   float buffer_3[840];
    local   float buffer_4[840];
    local   float buffer_5[840];
    local   float buffer_6[840];
    local   float buffer_7[840];
    private float load[8];

    uint base_row = get_group_id(1) * 8 / 1;
    uint base_column = get_group_id(0) * 840;

    uint row = get_local_id(0) / 105;
    uint burst = get_local_id(0) % 105;

    int filter = base_row + row;

    if (row < 8
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            load[x] = fop[FOP_IDX(filter, base_column + burst * 8 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            load[x] = 0.0f;
    }

    switch (row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_0[burst * 8 + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_1[burst * 8 + x] = load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_2[burst * 8 + x] = load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_3[burst * 8 + x] = load[x];
            break;
        case 4:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_4[burst * 8 + x] = load[x];
            break;
        case 5:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_5[burst * 8 + x] = load[x];
            break;
        case 6:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_6[burst * 8 + x] = load[x];
            break;
        case 7:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_7[burst * 8 + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 1 + 0) / 1;

    float amplitude_0[1] = {buffer_0[channel_0]};
    float amplitude_1[1] = {buffer_1[channel_0]};
    float amplitude_2[1] = {buffer_2[channel_0]};
    float amplitude_3[1] = {buffer_3[channel_0]};
    float amplitude_4[1] = {buffer_4[channel_0]};
    float amplitude_5[1] = {buffer_5[channel_0]};
    float amplitude_6[1] = {buffer_6[channel_0]};
    float amplitude_7[1] = {buffer_7[channel_0]};

    WRITE_CHANNEL(preload_to_detect[0][0][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[0][1][0], amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[0][2][0], amplitude_2[0]);
    WRITE_CHANNEL(preload_to_detect[0][3][0], amplitude_3[0]);
    WRITE_CHANNEL(preload_to_detect[0][4][0], amplitude_4[0]);
    WRITE_CHANNEL(preload_to_detect[0][5][0], amplitude_5[0]);
    WRITE_CHANNEL(preload_to_detect[0][6][0], amplitude_6[0]);
    WRITE_CHANNEL(preload_to_detect[0][7][0], amplitude_7[0]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_2(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[420];
    local   float buffer_1[420];
    local   float buffer_2[420];
    local   float buffer_3[420];
    private float load[4];

    uint base_row = get_group_id(1) * 8 / 2;
    uint base_column = get_group_id(0) * 420;

    uint row = get_local_id(0) / 105;
    uint burst = get_local_id(0) % 105;

    int filter = base_row + row;

    if (row < 4
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 4; ++x)
            load[x] = fop[FOP_IDX(filter, base_column + burst * 4 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 4; ++x)
            load[x] = 0.0f;
    }

    switch (row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_0[burst * 4 + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_1[burst * 4 + x] = load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_2[burst * 4 + x] = load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_3[burst * 4 + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 1 + 0) / 2;

    float amplitude_0[1] = {buffer_0[channel_0]};
    float amplitude_1[1] = {buffer_1[channel_0]};
    float amplitude_2[1] = {buffer_2[channel_0]};
    float amplitude_3[1] = {buffer_3[channel_0]};

    WRITE_CHANNEL(preload_to_detect[1][0][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[1][1][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[1][2][0], amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[1][3][0], amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[1][4][0], amplitude_2[0]);
    WRITE_CHANNEL(preload_to_detect[1][5][0], amplitude_2[0]);
    WRITE_CHANNEL(preload_to_detect[1][6][0], amplitude_3[0]);
    WRITE_CHANNEL(preload_to_detect[1][7][0], amplitude_3[0]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_3(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[280];
    local   float buffer_1[280];
    local   float buffer_2[280];
    local   float buffer_3[280];
    private float load[4];

    uint base_row = get_group_id(1) * 8 / 3;
    uint base_row_offset = get_group_id(1) * 8 % 3;
    uint base_column = get_group_id(0) * 280;

    uint row = get_local_id(0) / 70;
    uint burst = get_local_id(0) % 70;

    int filter = base_row + row;

    if (row < 4
        && (row < 3 || base_row_offset >= 2)
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 4; ++x)
            load[x] = fop[FOP_IDX(filter, base_column + burst * 4 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 4; ++x)
            load[x] = 0.0f;
    }

    switch (row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_0[burst * 4 + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_1[burst * 4 + x] = load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_2[burst * 4 + x] = load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_3[burst * 4 + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 1 + 0) / 3;

    float amplitude_0[1] = {buffer_0[channel_0]};
    float amplitude_1[1] = {buffer_1[channel_0]};
    float amplitude_2[1] = {buffer_2[channel_0]};
    float amplitude_3[1] = {buffer_3[channel_0]};

    WRITE_CHANNEL(preload_to_detect[2][0][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[2][1][0], base_row_offset < 2 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[2][2][0], base_row_offset < 1 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[2][3][0], amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[2][4][0], base_row_offset < 2 ? amplitude_1[0] : amplitude_2[0]);
    WRITE_CHANNEL(preload_to_detect[2][5][0], base_row_offset < 1 ? amplitude_1[0] : amplitude_2[0]);
    WRITE_CHANNEL(preload_to_detect[2][6][0], amplitude_2[0]);
    WRITE_CHANNEL(preload_to_detect[2][7][0], base_row_offset < 2 ? amplitude_2[0] : amplitude_3[0]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_4(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[210];
    local   float buffer_1[210];
    private float load[2];

    uint base_row = get_group_id(1) * 8 / 4;
    uint base_column = get_group_id(0) * 210;

    uint row = get_local_id(0) / 105;
    uint burst = get_local_id(0) % 105;

    int filter = base_row + row;

    if (row < 2
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 2; ++x)
            load[x] = fop[FOP_IDX(filter, base_column + burst * 2 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 2; ++x)
            load[x] = 0.0f;
    }

    switch (row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 2; ++x)
                buffer_0[burst * 2 + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 2; ++x)
                buffer_1[burst * 2 + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 1 + 0) / 4;

    float amplitude_0[1] = {buffer_0[channel_0]};
    float amplitude_1[1] = {buffer_1[channel_0]};

    WRITE_CHANNEL(preload_to_detect[3][0][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[3][1][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[3][2][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[3][3][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[3][4][0], amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[3][5][0], amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[3][6][0], amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[3][7][0], amplitude_1[0]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_5(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[168];
    local   float buffer_1[168];
    local   float buffer_2[168];
    private float load[4];

    uint base_row = get_group_id(1) * 8 / 5;
    uint base_row_offset = get_group_id(1) * 8 % 5;
    uint base_column = get_group_id(0) * 168;

    uint row = get_local_id(0) / 42;
    uint burst = get_local_id(0) % 42;

    int filter = base_row + row;

    if (row < 3
        && (row < 2 || base_row_offset >= 3)
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 4; ++x)
            load[x] = fop[FOP_IDX(filter, base_column + burst * 4 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 4; ++x)
            load[x] = 0.0f;
    }

    switch (row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_0[burst * 4 + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_1[burst * 4 + x] = load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_2[burst * 4 + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 1 + 0) / 5;

    float amplitude_0[1] = {buffer_0[channel_0]};
    float amplitude_1[1] = {buffer_1[channel_0]};
    float amplitude_2[1] = {buffer_2[channel_0]};

    WRITE_CHANNEL(preload_to_detect[4][0][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[4][1][0], base_row_offset < 4 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[4][2][0], base_row_offset < 3 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[4][3][0], base_row_offset < 2 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[4][4][0], base_row_offset < 1 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[4][5][0], amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[4][6][0], base_row_offset < 4 ? amplitude_1[0] : amplitude_2[0]);
    WRITE_CHANNEL(preload_to_detect[4][7][0], base_row_offset < 3 ? amplitude_1[0] : amplitude_2[0]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_6(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[140];
    local   float buffer_1[140];
    private float load[2];

    uint base_row = get_group_id(1) * 8 / 6;
    uint base_row_offset = get_group_id(1) * 8 % 6;
    uint base_column = get_group_id(0) * 140;

    uint row = get_local_id(0) / 70;
    uint burst = get_local_id(0) % 70;

    int filter = base_row + row;

    if (row < 2
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 2; ++x)
            load[x] = fop[FOP_IDX(filter, base_column + burst * 2 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 2; ++x)
            load[x] = 0.0f;
    }

    switch (row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 2; ++x)
                buffer_0[burst * 2 + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 2; ++x)
                buffer_1[burst * 2 + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 1 + 0) / 6;

    float amplitude_0[1] = {buffer_0[channel_0]};
    float amplitude_1[1] = {buffer_1[channel_0]};

    WRITE_CHANNEL(preload_to_detect[5][0][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[5][1][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[5][2][0], base_row_offset < 4 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[5][3][0], base_row_offset < 4 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[5][4][0], base_row_offset < 2 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[5][5][0], base_row_offset < 2 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[5][6][0], amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[5][7][0], amplitude_1[0]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_7(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[120];
    local   float buffer_1[120];
    private float load[2];

    uint base_row = get_group_id(1) * 8 / 7;
    uint base_row_offset = get_group_id(1) * 8 % 7;
    uint base_column = get_group_id(0) * 120;

    uint row = get_local_id(0) / 60;
    uint burst = get_local_id(0) % 60;

    int filter = base_row + row;

    if (row < 2
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 2; ++x)
            load[x] = fop[FOP_IDX(filter, base_column + burst * 2 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 2; ++x)
            load[x] = 0.0f;
    }

    switch (row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 2; ++x)
                buffer_0[burst * 2 + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 2; ++x)
                buffer_1[burst * 2 + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 1 + 0) / 7;

    float amplitude_0[1] = {buffer_0[channel_0]};
    float amplitude_1[1] = {buffer_1[channel_0]};

    WRITE_CHANNEL(preload_to_detect[6][0][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[6][1][0], base_row_offset < 6 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[6][2][0], base_row_offset < 5 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[6][3][0], base_row_offset < 4 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[6][4][0], base_row_offset < 3 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[6][5][0], base_row_offset < 2 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[6][6][0], base_row_offset < 1 ? amplitude_0[0] : amplitude_1[0]);
    WRITE_CHANNEL(preload_to_detect[6][7][0], amplitude_1[0]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_8(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[105];
    private float load[1];

    uint base_row = get_group_id(1) * 8 / 8;
    uint base_column = get_group_id(0) * 105;

    uint row = get_local_id(0) / 105;
    uint burst = get_local_id(0) % 105;

    int filter = base_row + row;

    if (row < 1
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 1; ++x)
            load[x] = fop[FOP_IDX(filter, base_column + burst * 1 + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 1; ++x)
            load[x] = 0.0f;
    }

    switch (row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 1; ++x)
                buffer_0[burst * 1 + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 1 + 0) / 8;

    float amplitude_0[1] = {buffer_0[channel_0]};

    WRITE_CHANNEL(preload_to_detect[7][0][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][1][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][2][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][3][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][4][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][5][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][6][0], amplitude_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][7][0], amplitude_0[0]);
}
