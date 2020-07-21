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
    detection_sz = 64  # divisible by n_parallel

    n_parallel = 16
    bundle_sz = 16  # >= n_parallel
    workgroup_sz = 4 * lcm(range(1, n_planes + 1))

    preld_template = Template(filename='preld.cl.mako')
    detect_template = Template(filename='detect.cl.mako')
    store_cands_template = Template(filename='store_cands.cl.mako')

    with open("../device/preld.cl", 'wt') as preld_file:
        preld_file.write(f"""
// Auto-generated file -- see `hsum_codegen.py` and `preld.cl.mako`.

channel float preloaders[{n_planes}][{n_parallel}] __attribute__((depth(0)));
""")
        for h in range(n_planes):
            preld_file.write(preld_template.render(
                harmonic=h + 1,
                n_parallel=n_parallel,
                workgroup_sz=workgroup_sz,
                bundle_sz=bundle_sz,
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
                detection_sz=detection_sz
            ))
    with open("../device/store_cands.cl", 'wt') as store_cands_file:
        store_cands_file.write(f"""
// Auto-generated file -- see `hsum_codegen.py` and `store_cands.cl.mako`.
""")
        store_cands_file.write(store_cands_template.render(
            n_planes=n_planes,
            n_parallel=n_parallel,
            detection_sz=detection_sz
        ))


if __name__ == '__main__':
    main()
