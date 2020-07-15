from mako.template import Template


def main():
    n_planes = 8
    n_parallel = 8
    burst_len = n_planes
    detection_sz = 32

    n_filters = 40  # divisible by 8
    n_channels = 4193280  # divisible by 840

    preld_template = Template(filename='preld.cl.mako')
    detect_template = Template(filename='detect.cl.mako')
    ringbuf_template = Template(filename='ringbuf.cl.mako')

    with open("../device/preld.cl", 'wt') as preld_file:
        preld_file.write(f"""
// Auto-generated file -- see `hsum_codegen.py` and `preld.cl.mako`.

channel float preloaders_out[{n_planes}][{n_parallel}] __attribute__((depth(0)));
""")
        for h in range(n_planes):
            preld_file.write(preld_template.render(
                harmonic=h + 1,
                n_parallel=n_parallel,
                burst_len=burst_len
            ))

    with open("../device/detect.cl", 'wt') as detect_file:
        detect_file.write(f"""
// Auto-generated file -- see `hsum_codegen.py` and `detect.cl.mako`.
channel float next_plane[{n_planes - 1}][{n_parallel}] __attribute__((depth(0)));
channel uint locations[{n_planes}][{n_parallel}] __attribute__((depth(0)));
channel float amplitudes[{n_planes}][{n_parallel}] __attribute__((depth(0)));
""")
        for h in range(n_planes):
            detect_file.write(detect_template.render(
                harmonic=h + 1,
                n_planes=n_planes,
                n_parallel=n_parallel,
                n_filters=n_filters,
                n_channels=n_channels,
                detection_sz=detection_sz
            ))
    with open("../device/ringbuf.cl", 'wt') as ringbuf_file:
        ringbuf_file.write(f"""
// Auto-generated file -- see `hsum_codegen.py` and `ringbuf.cl.mako`.
""")
        for h in range(n_planes):
            ringbuf_file.write(ringbuf_template.render(
                harmonic=h + 1,
                n_parallel=n_parallel,
                n_filters=n_filters,
                n_channels=n_channels,
                detection_sz=detection_sz
            ))


if __name__ == '__main__':
    main()
