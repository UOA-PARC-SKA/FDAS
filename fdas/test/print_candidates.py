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

import bitstring
import numpy as np


def main():
    parser = argparse.ArgumentParser(description="Prints pulsar candidate lists.")
    parser.add_argument(dest='locations', metavar='location-file',
                        help="NumPy array containing the detection locations")
    parser.add_argument(dest='power', metavar='power-file',
                        help="NumPy array containing the detection locations")
    parser.add_argument("-F", "--resolve-frequencies", dest='frequencies', metavar='frequencies-file',
                        help="resolve the bin numbers to frequencies, using the specified file")
    parser.add_argument("-N", "--num-templates", dest="n_tmpl", metavar='n', type=int, default=85,
                        help="set the number of FDAS templates")
    args = parser.parse_args()

    locations = np.load(args.locations)
    power = np.load(args.power)

    if locations.dtype != np.uint32:
        print(f"[ERROR] Invalid data type in locations file '{args.locations}'")
        return
    if power.dtype != np.float32:
        print(f"[ERROR] Invalid data type in power file '{args.power}'")
        return
    if locations.size != power.size:
        print(f"[ERROR] List size mismatch: {args.locations}:{locations.size} vs. {args.power}:{power.size}")
        return

    resolve_freqs = False
    if args.frequencies:
        frequencies = np.load(args.frequencies)
        resolve_freqs = True
        print("""Harmonic  Template
ID     │  │  Frequency    Power
────── ┴ ─┴─ ──────────── ────────""")
    else:
        print("""Harmonic  Template
ID     │  │  Bin     Power
────── ┴ ─┴─ ─────── ────────""")

    for i in range(locations.size):
        pwr = power[i]
        loc = locations[i]
        # extract fields from bit-packed data format
        b = bitstring.ConstBitStream(uint=loc, length=32)
        harm, tmpl, fbin = b.readlist('uint:3,uint:7,uint:22')
        # adjust values ranges
        harm += 1  # 1..N_hp was encoded as 0..N_hp-1
        tmpl -= args.n_tmpl // 2  # floor(-N_tmpl/2)..0..floor(N_tmpl/2) was encoded as 0..N_tmpl-1

        if harm == 1 and tmpl > args.n_tmpl // 2:
            continue  # invalid/"empty" slot in the candidate list
        if resolve_freqs:
            print(f"[{i + 1:4d}] {harm:1d} {tmpl:3d} {frequencies[fbin]:12.6f} {pwr:.6f}")
        else:
            print(f"[{i + 1:4d}] {harm:1d} {tmpl:3d} {fbin:7d} {pwr:.6f}")


if __name__ == '__main__':
    main()
