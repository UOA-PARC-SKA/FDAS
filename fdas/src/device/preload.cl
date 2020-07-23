
// Auto-generated file -- see `hsum_codegen.py` and `preload.cl.mako`.

channel float preload_to_detect[8][8][2] __attribute__((depth(0)));

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_1(global float * restrict fop,
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
    private float load[16];

    uint group_row = get_group_id(1) * 8 / 1;
    uint group_col = get_group_id(0) * 1680;

    uint item_row = get_local_id(0) / 105;
    uint item_col = get_local_id(0) % 105 * 16;

    int filter = group_row + item_row;

    if (item_row < 8
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            load[x] = fop[FOP_IDX(filter, group_col + item_col + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 16; ++x)
            load[x] = 0.0f;
    }

    switch (item_row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_0[item_col + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_1[item_col + x] = load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_2[item_col + x] = load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_3[item_col + x] = load[x];
            break;
        case 4:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_4[item_col + x] = load[x];
            break;
        case 5:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_5[item_col + x] = load[x];
            break;
        case 6:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_6[item_col + x] = load[x];
            break;
        case 7:
            #pragma unroll
            for (uint x = 0; x < 16; ++x)
                buffer_7[item_col + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 2 + 0) / 1;
    uint channel_1 = (get_local_id(0) * 2 + 1) / 1;

    float v_0[2] = {buffer_0[channel_0], buffer_0[channel_1]};
    float v_1[2] = {buffer_1[channel_0], buffer_1[channel_1]};
    float v_2[2] = {buffer_2[channel_0], buffer_2[channel_1]};
    float v_3[2] = {buffer_3[channel_0], buffer_3[channel_1]};
    float v_4[2] = {buffer_4[channel_0], buffer_4[channel_1]};
    float v_5[2] = {buffer_5[channel_0], buffer_5[channel_1]};
    float v_6[2] = {buffer_6[channel_0], buffer_6[channel_1]};
    float v_7[2] = {buffer_7[channel_0], buffer_7[channel_1]};

    WRITE_CHANNEL(preload_to_detect[0][0][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[0][0][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[0][1][0], v_1[0]);
    WRITE_CHANNEL(preload_to_detect[0][1][1], v_1[1]);
    WRITE_CHANNEL(preload_to_detect[0][2][0], v_2[0]);
    WRITE_CHANNEL(preload_to_detect[0][2][1], v_2[1]);
    WRITE_CHANNEL(preload_to_detect[0][3][0], v_3[0]);
    WRITE_CHANNEL(preload_to_detect[0][3][1], v_3[1]);
    WRITE_CHANNEL(preload_to_detect[0][4][0], v_4[0]);
    WRITE_CHANNEL(preload_to_detect[0][4][1], v_4[1]);
    WRITE_CHANNEL(preload_to_detect[0][5][0], v_5[0]);
    WRITE_CHANNEL(preload_to_detect[0][5][1], v_5[1]);
    WRITE_CHANNEL(preload_to_detect[0][6][0], v_6[0]);
    WRITE_CHANNEL(preload_to_detect[0][6][1], v_6[1]);
    WRITE_CHANNEL(preload_to_detect[0][7][0], v_7[0]);
    WRITE_CHANNEL(preload_to_detect[0][7][1], v_7[1]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_2(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[840];
    local   float buffer_1[840];
    local   float buffer_2[840];
    local   float buffer_3[840];
    private float load[8];

    uint group_row = get_group_id(1) * 8 / 2;
    uint group_col = get_group_id(0) * 840;

    uint item_row = get_local_id(0) / 105;
    uint item_col = get_local_id(0) % 105 * 8;

    int filter = group_row + item_row;

    if (item_row < 4
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            load[x] = fop[FOP_IDX(filter, group_col + item_col + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            load[x] = 0.0f;
    }

    switch (item_row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_0[item_col + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_1[item_col + x] = load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_2[item_col + x] = load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_3[item_col + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 2 + 0) / 2;
    uint channel_1 = (get_local_id(0) * 2 + 1) / 2;

    float v_0[2] = {buffer_0[channel_0], buffer_0[channel_1]};
    float v_1[2] = {buffer_1[channel_0], buffer_1[channel_1]};
    float v_2[2] = {buffer_2[channel_0], buffer_2[channel_1]};
    float v_3[2] = {buffer_3[channel_0], buffer_3[channel_1]};

    WRITE_CHANNEL(preload_to_detect[1][0][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[1][0][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[1][1][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[1][1][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[1][2][0], v_1[0]);
    WRITE_CHANNEL(preload_to_detect[1][2][1], v_1[1]);
    WRITE_CHANNEL(preload_to_detect[1][3][0], v_1[0]);
    WRITE_CHANNEL(preload_to_detect[1][3][1], v_1[1]);
    WRITE_CHANNEL(preload_to_detect[1][4][0], v_2[0]);
    WRITE_CHANNEL(preload_to_detect[1][4][1], v_2[1]);
    WRITE_CHANNEL(preload_to_detect[1][5][0], v_2[0]);
    WRITE_CHANNEL(preload_to_detect[1][5][1], v_2[1]);
    WRITE_CHANNEL(preload_to_detect[1][6][0], v_3[0]);
    WRITE_CHANNEL(preload_to_detect[1][6][1], v_3[1]);
    WRITE_CHANNEL(preload_to_detect[1][7][0], v_3[0]);
    WRITE_CHANNEL(preload_to_detect[1][7][1], v_3[1]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_3(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[560];
    local   float buffer_1[560];
    local   float buffer_2[560];
    local   float buffer_3[560];
    private float load[8];

    uint group_row = get_group_id(1) * 8 / 3;
    uint group_row_offset = get_group_id(1) * 8 % 3;
    uint group_col = get_group_id(0) * 560;

    uint item_row = get_local_id(0) / 70;
    uint item_col = get_local_id(0) % 70 * 8;

    int filter = group_row + item_row;

    if (item_row < 4
        && (item_row < 3 || group_row_offset >= 2)
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            load[x] = fop[FOP_IDX(filter, group_col + item_col + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            load[x] = 0.0f;
    }

    switch (item_row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_0[item_col + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_1[item_col + x] = load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_2[item_col + x] = load[x];
            break;
        case 3:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_3[item_col + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 2 + 0) / 3;
    uint channel_1 = (get_local_id(0) * 2 + 1) / 3;

    float v_0[2] = {buffer_0[channel_0], buffer_0[channel_1]};
    float v_1[2] = {buffer_1[channel_0], buffer_1[channel_1]};
    float v_2[2] = {buffer_2[channel_0], buffer_2[channel_1]};
    float v_3[2] = {buffer_3[channel_0], buffer_3[channel_1]};

    WRITE_CHANNEL(preload_to_detect[2][0][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[2][0][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[2][1][0], group_row_offset < 2 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[2][1][1], group_row_offset < 2 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[2][2][0], group_row_offset < 1 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[2][2][1], group_row_offset < 1 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[2][3][0], v_1[0]);
    WRITE_CHANNEL(preload_to_detect[2][3][1], v_1[1]);
    WRITE_CHANNEL(preload_to_detect[2][4][0], group_row_offset < 2 ? v_1[0] : v_2[0]);
    WRITE_CHANNEL(preload_to_detect[2][4][1], group_row_offset < 2 ? v_1[1] : v_2[1]);
    WRITE_CHANNEL(preload_to_detect[2][5][0], group_row_offset < 1 ? v_1[0] : v_2[0]);
    WRITE_CHANNEL(preload_to_detect[2][5][1], group_row_offset < 1 ? v_1[1] : v_2[1]);
    WRITE_CHANNEL(preload_to_detect[2][6][0], v_2[0]);
    WRITE_CHANNEL(preload_to_detect[2][6][1], v_2[1]);
    WRITE_CHANNEL(preload_to_detect[2][7][0], group_row_offset < 2 ? v_2[0] : v_3[0]);
    WRITE_CHANNEL(preload_to_detect[2][7][1], group_row_offset < 2 ? v_2[1] : v_3[1]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_4(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[420];
    local   float buffer_1[420];
    private float load[4];

    uint group_row = get_group_id(1) * 8 / 4;
    uint group_col = get_group_id(0) * 420;

    uint item_row = get_local_id(0) / 105;
    uint item_col = get_local_id(0) % 105 * 4;

    int filter = group_row + item_row;

    if (item_row < 2
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 4; ++x)
            load[x] = fop[FOP_IDX(filter, group_col + item_col + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 4; ++x)
            load[x] = 0.0f;
    }

    switch (item_row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_0[item_col + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_1[item_col + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 2 + 0) / 4;
    uint channel_1 = (get_local_id(0) * 2 + 1) / 4;

    float v_0[2] = {buffer_0[channel_0], buffer_0[channel_1]};
    float v_1[2] = {buffer_1[channel_0], buffer_1[channel_1]};

    WRITE_CHANNEL(preload_to_detect[3][0][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[3][0][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[3][1][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[3][1][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[3][2][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[3][2][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[3][3][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[3][3][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[3][4][0], v_1[0]);
    WRITE_CHANNEL(preload_to_detect[3][4][1], v_1[1]);
    WRITE_CHANNEL(preload_to_detect[3][5][0], v_1[0]);
    WRITE_CHANNEL(preload_to_detect[3][5][1], v_1[1]);
    WRITE_CHANNEL(preload_to_detect[3][6][0], v_1[0]);
    WRITE_CHANNEL(preload_to_detect[3][6][1], v_1[1]);
    WRITE_CHANNEL(preload_to_detect[3][7][0], v_1[0]);
    WRITE_CHANNEL(preload_to_detect[3][7][1], v_1[1]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_5(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[336];
    local   float buffer_1[336];
    local   float buffer_2[336];
    private float load[8];

    uint group_row = get_group_id(1) * 8 / 5;
    uint group_row_offset = get_group_id(1) * 8 % 5;
    uint group_col = get_group_id(0) * 336;

    uint item_row = get_local_id(0) / 42;
    uint item_col = get_local_id(0) % 42 * 8;

    int filter = group_row + item_row;

    if (item_row < 3
        && (item_row < 2 || group_row_offset >= 3)
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            load[x] = fop[FOP_IDX(filter, group_col + item_col + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 8; ++x)
            load[x] = 0.0f;
    }

    switch (item_row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_0[item_col + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_1[item_col + x] = load[x];
            break;
        case 2:
            #pragma unroll
            for (uint x = 0; x < 8; ++x)
                buffer_2[item_col + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 2 + 0) / 5;
    uint channel_1 = (get_local_id(0) * 2 + 1) / 5;

    float v_0[2] = {buffer_0[channel_0], buffer_0[channel_1]};
    float v_1[2] = {buffer_1[channel_0], buffer_1[channel_1]};
    float v_2[2] = {buffer_2[channel_0], buffer_2[channel_1]};

    WRITE_CHANNEL(preload_to_detect[4][0][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[4][0][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[4][1][0], group_row_offset < 4 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[4][1][1], group_row_offset < 4 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[4][2][0], group_row_offset < 3 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[4][2][1], group_row_offset < 3 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[4][3][0], group_row_offset < 2 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[4][3][1], group_row_offset < 2 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[4][4][0], group_row_offset < 1 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[4][4][1], group_row_offset < 1 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[4][5][0], v_1[0]);
    WRITE_CHANNEL(preload_to_detect[4][5][1], v_1[1]);
    WRITE_CHANNEL(preload_to_detect[4][6][0], group_row_offset < 4 ? v_1[0] : v_2[0]);
    WRITE_CHANNEL(preload_to_detect[4][6][1], group_row_offset < 4 ? v_1[1] : v_2[1]);
    WRITE_CHANNEL(preload_to_detect[4][7][0], group_row_offset < 3 ? v_1[0] : v_2[0]);
    WRITE_CHANNEL(preload_to_detect[4][7][1], group_row_offset < 3 ? v_1[1] : v_2[1]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_6(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[280];
    local   float buffer_1[280];
    private float load[4];

    uint group_row = get_group_id(1) * 8 / 6;
    uint group_row_offset = get_group_id(1) * 8 % 6;
    uint group_col = get_group_id(0) * 280;

    uint item_row = get_local_id(0) / 70;
    uint item_col = get_local_id(0) % 70 * 4;

    int filter = group_row + item_row;

    if (item_row < 2
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 4; ++x)
            load[x] = fop[FOP_IDX(filter, group_col + item_col + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 4; ++x)
            load[x] = 0.0f;
    }

    switch (item_row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_0[item_col + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_1[item_col + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 2 + 0) / 6;
    uint channel_1 = (get_local_id(0) * 2 + 1) / 6;

    float v_0[2] = {buffer_0[channel_0], buffer_0[channel_1]};
    float v_1[2] = {buffer_1[channel_0], buffer_1[channel_1]};

    WRITE_CHANNEL(preload_to_detect[5][0][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[5][0][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[5][1][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[5][1][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[5][2][0], group_row_offset < 4 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[5][2][1], group_row_offset < 4 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[5][3][0], group_row_offset < 4 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[5][3][1], group_row_offset < 4 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[5][4][0], group_row_offset < 2 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[5][4][1], group_row_offset < 2 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[5][5][0], group_row_offset < 2 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[5][5][1], group_row_offset < 2 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[5][6][0], v_1[0]);
    WRITE_CHANNEL(preload_to_detect[5][6][1], v_1[1]);
    WRITE_CHANNEL(preload_to_detect[5][7][0], v_1[0]);
    WRITE_CHANNEL(preload_to_detect[5][7][1], v_1[1]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_7(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[240];
    local   float buffer_1[240];
    private float load[4];

    uint group_row = get_group_id(1) * 8 / 7;
    uint group_row_offset = get_group_id(1) * 8 % 7;
    uint group_col = get_group_id(0) * 240;

    uint item_row = get_local_id(0) / 60;
    uint item_col = get_local_id(0) % 60 * 4;

    int filter = group_row + item_row;

    if (item_row < 2
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 4; ++x)
            load[x] = fop[FOP_IDX(filter, group_col + item_col + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 4; ++x)
            load[x] = 0.0f;
    }

    switch (item_row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_0[item_col + x] = load[x];
            break;
        case 1:
            #pragma unroll
            for (uint x = 0; x < 4; ++x)
                buffer_1[item_col + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 2 + 0) / 7;
    uint channel_1 = (get_local_id(0) * 2 + 1) / 7;

    float v_0[2] = {buffer_0[channel_0], buffer_0[channel_1]};
    float v_1[2] = {buffer_1[channel_0], buffer_1[channel_1]};

    WRITE_CHANNEL(preload_to_detect[6][0][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[6][0][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[6][1][0], group_row_offset < 6 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[6][1][1], group_row_offset < 6 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[6][2][0], group_row_offset < 5 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[6][2][1], group_row_offset < 5 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[6][3][0], group_row_offset < 4 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[6][3][1], group_row_offset < 4 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[6][4][0], group_row_offset < 3 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[6][4][1], group_row_offset < 3 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[6][5][0], group_row_offset < 2 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[6][5][1], group_row_offset < 2 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[6][6][0], group_row_offset < 1 ? v_0[0] : v_1[0]);
    WRITE_CHANNEL(preload_to_detect[6][6][1], group_row_offset < 1 ? v_0[1] : v_1[1]);
    WRITE_CHANNEL(preload_to_detect[6][7][0], v_1[0]);
    WRITE_CHANNEL(preload_to_detect[6][7][1], v_1[1]);
}

__attribute__((reqd_work_group_size(840, 1, 1)))
kernel void preload_8(global float * restrict fop,
                      const uint n_filters,
                      const uint negative_filters)
{
    local   float buffer_0[210];
    private float load[2];

    uint group_row = get_group_id(1) * 8 / 8;
    uint group_col = get_group_id(0) * 210;

    uint item_row = get_local_id(0) / 105;
    uint item_col = get_local_id(0) % 105 * 2;

    int filter = group_row + item_row;

    if (item_row < 1
        && filter < n_filters) {
        if (negative_filters)
            filter = -filter;
        #pragma unroll
        for (uint x = 0; x < 2; ++x)
            load[x] = fop[FOP_IDX(filter, group_col + item_col + x)];
    } else {
        #pragma unroll
        for (uint x = 0; x < 2; ++x)
            load[x] = 0.0f;
    }

    switch (item_row) {
        case 0:
            #pragma unroll
            for (uint x = 0; x < 2; ++x)
                buffer_0[item_col + x] = load[x];
            break;
        default:
            break;
    }

    barrier(CLK_LOCAL_MEM_FENCE);

    uint channel_0 = (get_local_id(0) * 2 + 0) / 8;
    uint channel_1 = (get_local_id(0) * 2 + 1) / 8;

    float v_0[2] = {buffer_0[channel_0], buffer_0[channel_1]};

    WRITE_CHANNEL(preload_to_detect[7][0][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][0][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[7][1][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][1][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[7][2][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][2][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[7][3][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][3][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[7][4][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][4][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[7][5][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][5][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[7][6][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][6][1], v_0[1]);
    WRITE_CHANNEL(preload_to_detect[7][7][0], v_0[0]);
    WRITE_CHANNEL(preload_to_detect[7][7][1], v_0[1]);
}
