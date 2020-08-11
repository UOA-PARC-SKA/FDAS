from math import gcd
from collections import defaultdict
from mako.template import Template


def get_output_mapping(n_out, k):
    output_mapping = []

    for i in range(n_out):
        idx_to_offs = defaultdict(list)
        for l in range(0, k, gcd(n_out, k)):
            idx_to_offs[(i + l) // k] += [l]
        output_mapping += [idx_to_offs]

    return output_mapping


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

    group_sz = 4
    bundle_sz = 4
    bundle_ty = "float" if bundle_sz == 1 else f"float{bundle_sz}"

    preload_template = Template(filename='preload.cl.mako')
    detect_template = Template(filename='detect.cl.mako')
    store_cands_template = Template(filename='store_cands.cl.mako')
    gen_info_template = Template(filename='gen_info.h.mako')

    with open("../device/preload.cl", 'wt') as preload_file:
        preload_file.write(f"""
// Auto-generated file -- see `hsum_codegen.py` and `preload.cl.mako`.

channel {bundle_ty} preload_to_delay[{n_planes}][{group_sz}] __attribute__((depth(0)));
channel {bundle_ty} delay_to_detect[{n_planes}][{group_sz}] __attribute__((depth(0)));

inline ulong fop_idx(int filter, uint bundle) {{
    return (filter + N_FILTERS_PER_ACCEL_SIGN) * (FDF_OUTPUT_SZ / {bundle_sz}) + bundle;
}}
""")
        for h in range(n_planes):
            preload_file.write(preload_template.render(
                group_sz=group_sz,
                bundle_sz=bundle_sz,
                bundle_ty=bundle_ty,
                k=h + 1
            ))

    with open("../device/detect.cl", 'wt') as detect_file:
        detect_file.write(f"""
// Auto-generated file -- see `hsum_codegen.py` and `detect.cl.mako`.
channel {bundle_ty} detect_to_detect[{n_planes - 1}][{group_sz}] __attribute__((depth(0)));
channel uint  detect_to_store_location[{n_planes}][{group_sz}][{bundle_sz}] __attribute__((depth(0)));
channel float detect_to_store_amplitude[{n_planes}][{group_sz}][{bundle_sz}] __attribute__((depth(0)));
""")
        for h in range(n_planes):
            detect_file.write(detect_template.render(
                n_planes=n_planes,
                detection_sz=detection_sz,
                group_sz=group_sz,
                bundle_sz=bundle_sz,
                bundle_ty=bundle_ty,
                k=h + 1
            ))
    with open("../device/store_cands.cl", 'wt') as store_cands_file:
        store_cands_file.write(f"""
// Auto-generated file -- see `hsum_codegen.py` and `store_cands.cl.mako`.
""")
        store_cands_file.write(store_cands_template.render(
            n_planes=n_planes,
            detection_sz=detection_sz,
            group_sz=group_sz,
            bundle_sz=bundle_sz
        ))

    with open("../host/gen_info.h", 'wt') as gen_info_file:
        gen_info_file.write(f"""
// Auto-generated file -- see `hsum_codegen.py` and `gen_info.h.mako`.
""")
        gen_info_file.write(gen_info_template.render(
            n_planes=n_planes,
            detection_sz=detection_sz,
            group_sz=group_sz,
            bundle_sz=bundle_sz
        ))


if __name__ == '__main__':
    main()
