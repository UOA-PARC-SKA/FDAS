
__attribute__((max_global_work_dim(0)))
kernel void detect_${harmonic}(const float threshold,
                     const uint n_filter_batches,
                     const uint negative_filters,
                     const uint n_filters,
                     const uint n_channels)
{
<%
    n_slots = detection_sz // n_parallel
%>\
%for p in range(n_parallel):
    uint location_buffer_${p}[${n_slots}] = {${', '.join(["HMS_INVALID_LOCATION"] * n_slots)}};
%endfor
%for p in range(n_parallel):
    float amplitude_buffer_${p}[${n_slots}] = {${', '.join(["-1.0f"] * n_slots)}};
%endfor
    uint next[${n_parallel}]  = {${', '.join(["0"] * n_parallel)}};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint chan = 0; chan < n_channels; ++chan) {
            float hsum[${n_parallel}];

        % if harmonic == 1:
            #pragma unroll
            for (uint p = 0; p < ${n_parallel}; ++p)
                hsum[p] = READ_CHANNEL(preload_to_detect[${harmonic - 1}][p]);
        %else:
            #pragma unroll
            for (uint p = 0; p < ${n_parallel}; ++p)
                hsum[p] = READ_CHANNEL(detect_to_detect[${harmonic - 2}][p]) + READ_CHANNEL(preload_to_detect[${harmonic - 1}][p]);
        % endif

        %if harmonic < n_planes:
            #pragma unroll
            for (uint p = 0; p < ${n_parallel}; ++p)
                WRITE_CHANNEL(detect_to_detect[${harmonic - 1}][p], hsum[p]);
        %endif

        %for p in range(n_parallel):
            int filter_${p} = batch * ${n_parallel} + ${p};
            if (hsum[${p}] > threshold && filter_${p} < n_filters) {
                uint slot = next[${p}];
                if (negative_filters)
                    filter_${p} = -filter_${p};
                location_buffer_${p}[slot] = HMS_ENCODE_LOCATION(${harmonic}, filter_${p}, chan);
                amplitude_buffer_${p}[slot] = hsum[${p}];
                next[${p}] = (slot + 1) < ${n_slots} ? slot + 1 : 0;
            }
        %endfor
        }
    }

    #pragma unroll 1
    for (uint slot = 0; slot < ${n_slots}; ++slot) {
    %for p in range(n_parallel):
        WRITE_CHANNEL(detect_to_store_location[${harmonic - 1}][${p}], location_buffer_${p}[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[${harmonic - 1}][${p}], amplitude_buffer_${p}[slot]);
    %endfor
    }
}
