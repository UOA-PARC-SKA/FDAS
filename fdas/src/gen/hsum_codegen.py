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
    detection_sz = 64  # divisible by group_sz * bundle_sz

    group_sz = 8
    bundle_sz = 1
    workgroup_sz = lcm(range(1, n_planes + 1))

    preload_template = Template(filename='preload.cl.mako')
    preload_swi_template = Template(filename='preload_swi.cl.mako')
    detect_template = Template(filename='detect.cl.mako')
    store_cands_template = Template(filename='store_cands.cl.mako')

    with open("../device/preload.cl", 'wt') as preload_file:
        preload_file.write(f"""
// Auto-generated file -- see `hsum_codegen.py` and `preload.cl.mako`.

channel float preload_to_detect[{n_planes}][{group_sz}][{bundle_sz}] __attribute__((depth(0)));
""")
        for h in range(n_planes):
            preload_file.write(preload_template.render(
                group_sz=group_sz,
                bundle_sz=bundle_sz,
                workgroup_sz=workgroup_sz,
                k=h + 1
            ))

    with open("../device/detect.cl", 'wt') as detect_file:
        detect_file.write(f"""
// Auto-generated file -- see `hsum_codegen.py` and `detect.cl.mako`.
channel float detect_to_detect[{n_planes - 1}][{group_sz}][{bundle_sz}] __attribute__((depth(0)));
channel uint  detect_to_store_location[{n_planes}][{group_sz}][{bundle_sz}] __attribute__((depth(0)));
channel float detect_to_store_amplitude[{n_planes}][{group_sz}][{bundle_sz}] __attribute__((depth(0)));
""")
        for h in range(n_planes):
            detect_file.write(detect_template.render(
                n_planes=n_planes,
                group_sz=group_sz,
                bundle_sz=bundle_sz,
                detection_sz=detection_sz,
                k=h + 1
            ))
    with open("../device/store_cands.cl", 'wt') as store_cands_file:
        store_cands_file.write(f"""
// Auto-generated file -- see `hsum_codegen.py` and `store_cands.cl.mako`.
""")
        store_cands_file.write(store_cands_template.render(
            n_planes=n_planes,
            group_sz=group_sz,
            bundle_sz=bundle_sz,
            detection_sz=detection_sz
        ))


if __name__ == '__main__':
    main()
