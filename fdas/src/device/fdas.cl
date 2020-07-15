#include "fdas_config.h"

// Enable channels, portable across Altera's and Intel's `aoc` versions
#if defined(INTELFPGA_CL)
#pragma OPENCL EXTENSION cl_intel_channels : enable
#define READ_CHANNEL(ch) read_channel_intel(ch)
#define WRITE_CHANNEL(ch, x) write_channel_intel(ch, x)
#else
#pragma OPENCL EXTENSION cl_altera_channels : enable
#define READ_CHANNEL(ch) read_channel_altera(ch)
#define WRITE_CHANNEL(ch, x) write_channel_altera(ch, x)
#endif

#include "ft_conv.cl"
#include "hsum.cl"
