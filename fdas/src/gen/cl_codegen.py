#!/usr/bin/env python3

# FDAS -- Fourier Domain Acceleration Search, FPGA-accelerated with OpenCL
# Copyright (C) 2020  Parallel and Reconfigurable Computing Lab,
#                     Dept. of Electrical, Computer, and Software Engineering,
#                     University of Auckland, New Zealand
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


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
    # TODO: build an ArgumentParser around this

    # Input parameters
    mode = 'emu'
    if mode == 'fpga':
        n_filters_per_accel_sign = 42
        n_taps = 421
    elif mode == 'emu':
        n_filters_per_accel_sign = 10
        n_taps = 106
    else:
        raise RuntimeError(f"unknown mode: {mode}")

    n_filters = n_filters_per_accel_sign + 1 + n_filters_per_accel_sign

    # FFT engine configuration
    fft_n_points_log = 11
    fft_n_points = 2 ** fft_n_points_log

    fft_n_parallel_log = 2
    fft_n_parallel = 2 ** fft_n_parallel_log

    fft_n_points_per_terminal_log = fft_n_points_log - fft_n_parallel_log
    fft_n_points_per_terminal = 2 ** fft_n_points_per_terminal_log

    # Frequency-domain FIR filter implementation with overlap-save algorithm
    fdf_tile_sz = fft_n_points
    fdf_tile_overlap = n_taps - 1
    fdf_tile_payload = fdf_tile_sz - fdf_tile_overlap

    fdf_group_sz = 5 if mode == 'fpga' else 3

    # Harmonic summing
    hms_n_planes = 8
    hms_detection_sz = 64

    hms_group_sz = 8
    hms_bundle_sz = 2
    hms_bundle_ty = "float" if hms_bundle_sz == 1 else f"float{hms_bundle_sz}"

    # Output
    n_candidates = hms_n_planes * hms_detection_sz * hms_group_sz * hms_bundle_sz

    fdas_configuration = dict(**locals())

    # -- end of config ---

    channels_template = Template(filename='channels.cl.mako')
    utils_template = Template(filename='utils.cl.mako')
    fft_template = Template(filename='fft.cl.mako')
    tile_input_template = Template(filename='tile_input.cl.mako')
    convolve_template = Template(filename='convolve.cl.mako')
    preload_template = Template(filename='preload.cl.mako')
    detect_template = Template(filename='detect.cl.mako')
    gen_info_template = Template(filename='gen_info.h.mako')

    copyright_header = """/*
 * FDAS -- Fourier Domain Acceleration Search, FPGA-accelerated with OpenCL
 * Copyright (C) 2020  Parallel and Reconfigurable Computing Lab,
 *                     Dept. of Electrical, Computer, and Software Engineering,
 *                     University of Auckland, New Zealand
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
"""

    with open("../device/fdas_gen.cl", 'wt') as fdas_file:
        fdas_file.write(copyright_header)
        fdas_file.write(channels_template.render(**fdas_configuration))
        fdas_file.write(utils_template.render(**fdas_configuration))
        for i in range(fdf_group_sz):
            fdas_file.write(fft_template.render(i=i, both_directions=i == 0, **fdas_configuration))
        fdas_file.write(tile_input_template.render(**fdas_configuration))
        fdas_file.write(convolve_template.render(**fdas_configuration))
        for h in range(hms_n_planes):
            fdas_file.write(preload_template.render(k=h + 1, **fdas_configuration))
        for h in range(hms_n_planes):
            fdas_file.write(detect_template.render(k=h + 1, **fdas_configuration))


    with open("../host/gen_info.h", 'wt') as gen_info_file:
        gen_info_file.write(copyright_header)
        gen_info_file.write(gen_info_template.render(**fdas_configuration))


if __name__ == '__main__':
    main()
