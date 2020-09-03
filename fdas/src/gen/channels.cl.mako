
#if defined(INTELFPGA_CL)
#pragma OPENCL EXTENSION cl_intel_channels : enable
#define READ_CHANNEL(ch) read_channel_intel(ch)
#define WRITE_CHANNEL(ch, x) write_channel_intel(ch, x)
#else
#pragma OPENCL EXTENSION cl_altera_channels : enable
#define READ_CHANNEL(ch) read_channel_altera(ch)
#define WRITE_CHANNEL(ch, x) write_channel_altera(ch, x)
#endif

<% depth_attr = "__attribute__((depth(0)))" %>\
channel float2x4 load_to_tile ${depth_attr};

channel float2x4 fft_in ${depth_attr};
channel float2x4 fft_out ${depth_attr};

channel float2x4 ifft_in[${fft_n_engines}] ${depth_attr};
channel float2x4 ifft_out[${fft_n_engines}] ${depth_attr};

channel ${hms_bundle_ty} preload_to_delay[${hms_n_planes}][${hms_group_sz}] ${depth_attr};
channel ${hms_bundle_ty} delay_to_detect[${hms_n_planes}][${hms_group_sz}] ${depth_attr};

channel ${hms_bundle_ty} detect_to_detect[${hms_n_planes - 1}][${hms_group_sz}] ${depth_attr};
channel uint  detect_to_store_location[${hms_n_planes}][${hms_group_sz * hms_bundle_sz}] ${depth_attr};
channel float detect_to_store_amplitude[${hms_n_planes}][${hms_group_sz * hms_bundle_sz}] ${depth_attr};