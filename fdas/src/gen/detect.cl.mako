
__attribute__((max_global_work_dim(0)))
kernel void detect_${harmonic}(const float threshold,
                     const uint n_filters,
                     const uint negative_filters,
                     const uint n_filter_batches,
                     const uint n_channel_bundles)
{
<%
    n_slots = detection_sz // n_parallel // bundle_sz
%>\
%for p in range(n_parallel):
%for q in range(bundle_sz):
    uint location_buffer_${p}_${q}[${n_slots}] = {${', '.join(["HMS_INVALID_LOCATION"] * n_slots)}};
%endfor
%endfor
%for p in range(n_parallel):
%for q in range(bundle_sz):
    float amplitude_buffer_${p}_${q}[${n_slots}] = {${', '.join(["-1.0f"] * n_slots)}};
%endfor
%endfor

    uint next[${n_parallel * bundle_sz}]  = {${', '.join(["0"] * n_parallel * bundle_sz)}};

    for (uint batch = 0; batch < n_filter_batches; ++batch) {
        for (uint bundle = 0; bundle < n_channel_bundles; ++bundle) {
            float hsum[${n_parallel}][${bundle_sz}];

        % if harmonic == 1:
            #pragma unroll
            for (uint p = 0; p < ${n_parallel}; ++p) {
                #pragma unroll
                for (uint q = 0; q < ${bundle_sz}; ++q)
                    hsum[p][q] = READ_CHANNEL(preload_to_detect[${harmonic - 1}][p][q]);
            }
        %else:
            #pragma unroll
            for (uint p = 0; p < ${n_parallel}; ++p) {
                #pragma unroll
                for (uint q = 0; q < ${bundle_sz}; ++q)
                    hsum[p][q] = READ_CHANNEL(detect_to_detect[${harmonic - 2}][p][q]) + READ_CHANNEL(preload_to_detect[${harmonic - 1}][p][q]);
            }
        % endif

        %if harmonic < n_planes:
            #pragma unroll
            for (uint p = 0; p < ${n_parallel}; ++p) {
                #pragma unroll
                for (uint q = 0; q < ${bundle_sz}; ++q)
                    WRITE_CHANNEL(detect_to_detect[${harmonic - 1}][p][q], hsum[p][q]);
            }
        %endif

        %for p in range(n_parallel):
            int filter_${p} = batch * ${n_parallel} + ${p};
            if (filter_${p} < n_filters) {
            %for q in range(bundle_sz):
                uint channel_${q} = bundle * ${bundle_sz} + ${q};
                if (hsum[${p}][${q}] > threshold) {
                    uint slot = next[${p * bundle_sz + q}];
                    if (negative_filters)
                        filter_${p} = -filter_${p};
                    location_buffer_${p}_${q}[slot] = HMS_ENCODE_LOCATION(${harmonic}, filter_${p}, channel_${q});
                    amplitude_buffer_${p}_${q}[slot] = hsum[${p}][${q}];
                    next[${p * bundle_sz + q}] = (slot + 1) < ${n_slots} ? slot + 1 : 0;
                }
            %endfor
            }
        %endfor
        }
    }

    for (uint slot = 0; slot < ${n_slots}; ++slot) {
    %for p in range(n_parallel):
    %for q in range(bundle_sz):
        WRITE_CHANNEL(detect_to_store_location[${harmonic - 1}][${p}][${q}], location_buffer_${p}_${q}[slot]);
        WRITE_CHANNEL(detect_to_store_amplitude[${harmonic - 1}][${p}][${q}], amplitude_buffer_${p}_${q}[slot]);
    %endfor
    %endfor
    }
}
