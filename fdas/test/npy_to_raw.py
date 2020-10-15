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


import numpy as np
import sys
from pathlib import Path


def convert(npy_file):
    npy_path = Path(npy_file)
    if npy_path.suffix != '.npy':
        return

    arr = np.load(npy_path)
    dat_path = npy_path.with_name(npy_path.stem + '__' + 'x'.join(str(d) for d in (arr.shape + (arr.dtype,))) + '.dat')
    arr.tofile(dat_path)

    print(f"Converted {npy_path} to {dat_path} ({arr.nbytes} bytes)")


def main():
    for arg in sys.argv:
        convert(arg)


if __name__ == '__main__':
    main()
