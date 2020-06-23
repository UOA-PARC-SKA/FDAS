#!/usr/bin/env python3

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
    test_args.add_argument("-k", dest='test_data_k', type=int, metavar='n', default=8,
                           help="set index of last harmonic planes to compute (default: 8)")

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
    tmpl0_idx = n_tmpl // 2  # index of filter corresponding to zero acceleration

    # compute harmonic planes
    prev_hp = fop
    for k in range(2, args.test_data_k + 1):
        print(f"[INFO] Computing harmonic plane {k}")
        hp = np.empty(fop.shape)
        it = np.nditer(prev_hp, op_flags=['readonly'], flags=['multi_index'])
        for _ in it:
            # compute indices to simulate access to the k'th stretch plane

            # 'i' and 'j' are the indices into the NumPy arrays
            i, j = it.multi_index

            # 'i_num' is the filter number (in the range [-n_tmpl//2, n_tmpl//2]). Its sign determines whether we need
            # to round up or down
            i_num = i - tmpl0_idx
            if i_num < 0:
                i_sp_idx = int(np.ceil(i_num / k)) + tmpl0_idx
            elif i_num > 0:
                i_sp_idx = int(np.floor(i_num / k)) + tmpl0_idx
            else:  # i_num == 0
                pass

            # j is the channel/frequency bin number -- no special handling required
            j_sp_idx = j // k

            # see: Eq. (2) in Haomiao's VLSI paper
            hp[i][j] = prev_hp[i][j] + fop[i_sp_idx][j_sp_idx]

        # save the plane
        np.save(f"{od}/hp_{k}.npy", hp)
        prev_hp = hp


if __name__ == '__main__':
    main()
