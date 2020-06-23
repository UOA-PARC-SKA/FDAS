#!/usr/bin/env python3

import sys
import argparse
import struct
import pathlib
import multiprocessing
import numpy as np
import scipy.fft
import scipy.signal


def get_tim_header_field(tag, fmt, buf):
    idx = buf.find(tag)
    if idx < 0:
        raise RuntimeError(f"Header field ({tag}) not found")
    val, = struct.unpack_from(fmt, buf, idx + len(tag))
    return val


def read_tim_file(tim_file):
    offset = 0
    t_samp = None

    # Attempt to read header section, check the format, and extract the sampling time
    with open(tim_file, 'rb') as tim:
        header = tim.read(512)  # arbitrarily chosen. The actual header size seems to be around 300 bytes
        tag = b'HEADER_START'
        start_idx = header.find(tag)
        if start_idx == 4:  # first 4 bytes encode the length of the label
            tag = b'HEADER_END'
            end_idx = header.find(tag)
            if end_idx < 0:
                raise RuntimeError(f"Header end tag ({tag}) not found")
            offset = end_idx + len(tag)

            data_type = get_tim_header_field(b'data_type', '<i', header)
            nbits = get_tim_header_field(b'nbits', '<i', header)
            if data_type != 2 or nbits != 32:
                raise RuntimeError(f"Format mismatch: Expecting 32-bit FP time series data")

            t_samp = get_tim_header_field(b'tsamp', '<d', header)

    # Let NumPy read the actual samples
    samples = np.fromfile(tim_file, dtype=np.float32, offset=offset)
    print(f"[INFO] Read {samples.size} samples from '{tim_file}'")

    return samples, t_samp


def main():
    parser = argparse.ArgumentParser(description="Generate test vectors for FDAS module.")

    parser.add_argument(dest='input', metavar='tim-file', nargs='+', help="SIGPROC *.tim file(s) containing time-series samples")
    parser.add_argument("-t", "--templates", dest='tmpls', metavar='path', required=True,
                        help="NumPy *.npy file containing the filter templates")
    parser.add_argument("-B", "--base-directory", dest='base_dir', metavar='path',
                        help="set base directory (default: $PWD)")
    parser.add_argument("-J", "--num-procs", dest='n_proc', metavar='n', type=int, default=1,
                        help="set number of processors to use")

    test_args = parser.add_argument_group("test data")
    test_args.add_argument("--num-channels", dest='test_data_n_chan', type=int, metavar='n', default=2 ** 22,
                           help="set number of channels in test data (default: 4194304 = 4M)")
    test_args.add_argument("--tile-and-transform", dest='test_data_tile_sz', type=int, metavar='n', nargs='?',
                           const=2 ** 11, help="prepare input for overlap-save FDFIR algorithm with the given tile size"
                                               " (default: 2048 = 2K)")
    test_args.add_argument("--sampling-time", dest='t_samp', metavar='t', type=float, default=0.000064,
                           help="set sampling time in seconds (default: 6.4e-5 s)")
    test_args.add_argument("--num-harmonic-planes", dest='test_data_n_hp', type=int, metavar='n', default=8,
                           help="set number of harmonic planes to compute. Set to '1' to compute only the filter-output"
                                " plane (default: 8)")

    args = parser.parse_args()

    with multiprocessing.Pool(args.n_proc) as pool:
        pool.starmap(generate_test_data, [(tf, args) for tf in args.input])

def generate_test_data(tim_file, args):
    # determine output directory
    od = pathlib.Path(args.base_dir or '.').joinpath(pathlib.Path(tim_file).stem)
    pathlib.Path(od).mkdir(parents=True, exist_ok=True)

    # read samples from time series
    samples, t_samp = read_tim_file(tim_file)
    t_samp = t_samp or args.t_samp  # take sampling time from (in this order): 1) file, 2) command line, 3) default

    # we need twice as many samples as the requested number of channels for the test data, as we will discard the
    # negative frequencies in the spectrum
    n_samp = samples.size
    n_chan = args.test_data_n_chan
    if n_samp < 2 * n_chan:
        print(f"[ERROR] Input file does not contain enough samples. Got {n_samp}, but need at least {2 * n_chan}")
        sys.exit(-1)
    if n_samp > 2 * n_chan:
        print(f"[INFO] Discarding {n_samp - 2 * n_chan} samples (= {t_samp * (n_samp - 2 * n_chan):.3f} seconds) to "
              f"match requested number of channels in spectrum")
        n_samp = 2 * n_chan
        samples = np.resize(samples, n_samp)

    # perform CXFT: get normalised Fourier transform
    freqs = scipy.fft.fftfreq(n_samp, t_samp)
    ft = scipy.fft.fft(samples) / n_samp

    # discard negative frequencies. SKA-TDT says:
    # % Take only the first half of the series; if the second half is included, the
    # % acceleration with opposite sign to the correct one will be flagged as a candidate
    # additionally, enforce the desired data types
    freqs = np.array(freqs[:n_chan], dtype=np.float32)
    ft = np.array(ft[:n_chan], dtype=np.complex64)

    # save as input for the FDAS module
    np.save(f"{od}/input.npy", ft)

    # save the channel frequencies (to make plotting more convenient)
    np.save(f"{od}/freqs.npy", freqs)

    # load filter templates
    templates = np.load(args.tmpls)
    if templates.ndim != 2 or templates.dtype != np.complex64:
        print(f"[ERROR] Template file does not contain a two-dimensional np.complex64 array")
        sys.exit(-1)
    n_tmpl, max_tmpl_len = templates.shape

    # produce tiled and Fourier transformed input data, if requested
    if args.test_data_tile_sz:
        tile_sz = args.test_data_tile_sz
        tile_olap = max_tmpl_len - 1  # overlap
        tile_pld = tile_sz - tile_olap  # payload
        n_tile = n_chan // tile_pld
        if n_tile * tile_pld < n_chan:
            print(f"[INFO] Input tiling will discard the upper {n_chan - n_tile * tile_pld} channels")
        tiles = np.empty((n_tile, tile_sz), dtype=np.complex64)
        for i in range(n_tile):
            if i == 0:
                # first tile is padded with zeros
                tiles[i][:tile_olap] = np.zeros(tile_olap, dtype=np.complex64)
            else:
                # all other tiles overlap with previous one
                tiles[i][:tile_olap] = tiles[i - 1][-tile_olap:]

            # fill the rest of tile with input data
            tiles[i][tile_olap:] = ft[i * tile_pld:(i + 1) * tile_pld]

        # perform tile-wise Fourier transformation and save result
        tiles = scipy.fft.fft(tiles)
        np.save(f"{od}/input_tiled.npy", tiles)

    # compute and save filter-output plane
    print(f"[INFO] Computing filter-output plane")
    fop_like = {'shape': (n_tmpl, n_chan), 'dtype': np.float32}
    fop = np.empty(**fop_like)
    for i in range(n_tmpl):
        tmpl = templates[i][np.nonzero(templates[i])]
        conv = scipy.signal.convolve(ft, tmpl)[:n_chan]  # convolve, and trim to input length
        fop[i][:] = np.real(conv * np.conj(conv))

    np.save(f"{od}/fop.npy", fop)

    tmpl0_idx = n_tmpl // 2  # index of filter corresponding to zero acceleration

    # compute harmonic planes
    prev_hp = fop
    for k in range(2, args.test_data_n_hp):
        print(f"[INFO] Computing harmonic plane {k}")
        hp = np.empty(**fop_like)
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
