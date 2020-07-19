from math import gcd
from mako.template import Template


def lcm(vals):
    if len(vals) <= 1:
        return 1
    if len(vals) == 2:
        a, b = vals
        return a * b // gcd(a, b)
    x, *xs = vals
    return lcm([x, lcm(xs)])

def main():
    n_planes = 8
    detection_sz = 32  # divisible by n_parallel

    n_parallel = 4
    bundle_sz = 8
    workgroup_sz = 2 * lcm(range(1, n_planes + 1))

    n_filters = 40  # divisible by n_parallel
    n_channels = 4193280  # divisible by workgroup_sz

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
                workgroup_sz=workgroup_sz,
                n_parallel=n_parallel,
                bundle_sz=bundle_sz
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
