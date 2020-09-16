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


import argparse
import pathlib
import multiprocessing
import numpy as np


def main():
    parser = argparse.ArgumentParser(description="Computes reference output data for the harmonic summing module.")

    parser.add_argument(dest='input', metavar='fop-file', nargs='+',
                        help="*.npy file(s) containing filter-output planes")
    parser.add_argument("-B", "--base-directory", dest='base_dir', metavar='path',
                        help="set base directory (default: $PWD)")
    parser.add_argument("-J", "--num-procs", dest='n_proc', metavar='n', type=int, default=1,
                        help="set number of processors to use")

    test_args = parser.add_argument_group("test data")
    test_args.add_argument("--num-planes", dest='test_data_n_plane', type=int, metavar='n', default=8,
                           help="set number of harmonic planes to compute, i.e. FOP = HP_1, HP_2, ..., HP_n")
    test_args.add_argument("--num-candidates-per-plane", dest='test_data_n_cand_per_plane', type=int, metavar='n',
                           default=64, help="set desired number of candidates per plane (default: 64)")

    args = parser.parse_args()

    with multiprocessing.Pool(args.n_proc) as pool:
        pool.starmap(compute_test_data, [(ff, args) for ff in args.input])


def compute_test_data(fop_file, args):
    # determine output directory
    if args.base_dir:
        od = pathlib.Path(args.base_dir).joinpath(pathlib.Path(fop_file).absolute().parent.name)
    else:
        od = pathlib.Path(fop_file).absolute().parent
    pathlib.Path(od).mkdir(parents=True, exist_ok=True)

    # load FOP
    fop = np.load(fop_file)
    if fop.ndim != 2 or fop.dtype != np.float32:
        print(f"[ERROR] FOP file does not contain a two-dimensional np.float32 array")
        return

    n_tmpl = fop.shape[0]
    n_tmpl_per_accel_sign = n_tmpl // 2

    # compute harmonic planes
    n_plane = args.test_data_n_plane
    hps = np.empty((n_plane,) + fop.shape, dtype=np.float32)
    hps[0][:][:] = fop
    for h in range(1, n_plane):
        k = h + 1
        print(f"[INFO] Computing harmonic plane {k}")

        it = np.nditer(fop, op_flags=['readonly'], flags=['multi_index'])
        for _ in it:
            # compute indices to simulate access to the k'th stretch plane

            # 'i' and 'j' are the indices into the NumPy arrays
            i, j = it.multi_index

            # 'i_num' is the filter number (in the range [-n_tmpl//2, n_tmpl//2]). Its sign determines whether we need
            # to round up or down
            i_num = i - n_tmpl_per_accel_sign
            if i_num < 0:
                i_sp_idx = int(np.ceil(i_num / k)) + n_tmpl_per_accel_sign
            elif i_num > 0:
                i_sp_idx = int(np.floor(i_num / k)) + n_tmpl_per_accel_sign
            else:  # i_num == 0
                pass

            # j is the channel/frequency bin number -- no special handling required
            j_sp_idx = j // k

            # see: Eq. (2) in Haomiao's VLSI paper
            hps[h][i][j] = hps[h - 1][i][j] + fop[i_sp_idx][j_sp_idx]

    # save the planes
    np.save(f"{od}/hps_ref.npy", hps[1:])

    # produce mock-up (!) thresholds, resulting in the requested number of candidates per plane
    thrsh = np.empty(n_plane, dtype=np.float32)
    for h in range(n_plane):
        thrsh[h] = np.quantile(hps[h], q=1 - args.test_data_n_cand_per_plane / fop.size)
        print(f"[INFO] Threshold for HP_{h + 1} is {thrsh[h]}")

    np.save(f"{od}/thresholds.npy", thrsh)

    # find candidates
    detections = []
    for h in range(n_plane):
        indices = np.flatnonzero([hps[h] > thrsh[h]])
        print(f"[INFO] {indices.size} candidates in HP_{h + 1}")
        for i in indices:
            f, c = np.unravel_index(i, fop.shape)
            detections += [(h + 1, f - n_tmpl_per_accel_sign, c, hps[h][f][c])]

    # save candidate lists in the format used by the OpenCL implementation
    locations = np.empty(len(detections), dtype=np.uint32)
    amplitudes = np.empty(len(detections), dtype=np.float32)
    for i, det in enumerate(detections):
        k, f, c, a = det
        locations[i] = (((k - 1) & 0x7) << 29) | (((f + n_tmpl_per_accel_sign) & 0x7f) << 22) | (c & 0x3fffff)
        amplitudes[i] = a

    np.save(f"{od}/det_loc_ref.npy", locations)
    np.save(f"{od}/det_amp_ref.npy", amplitudes)


if __name__ == '__main__':
    main()
