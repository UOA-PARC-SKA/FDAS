#!/usr/bin/env python3

import sys
import argparse
import struct
import numpy as np
import scipy.fft

import matplotlib.pyplot as plt


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


def plot_power_spectrum(freqs, power, freq_range):
    plt.title("Power spectrum")
    plt.xlabel("Frequency [Hz]")
    plt.ylabel("Power")
    plt.plot(freqs, power)
    plt.xlim(*freq_range)
    plt.show()


def main():
    parser = argparse.ArgumentParser(description="Generate test vectors for FDAS module.")

    parser.add_argument(dest='input', metavar='tim-file', help="SIGPROC *.tim file containing time-series samples")
    parser.add_argument("--output-directory", dest='out_dir', metavar='path', required=True,
                        help="set output directory")

    test_args = parser.add_argument_group("test data")
    test_args.add_argument("--num-channels", dest='test_data_n_chan', type=int, metavar='n', default=2 ** 22,
                           help="set number of channels in test data (default: 4194304 = 4M)")
    test_args.add_argument("--tile-size", dest='test_data_tile_sz', type=int, metavar='n', default=2 ** 11,
                           help="set the tile size used in the overlap-save FDFIR implementation (default: 2048 = 2K)")
    test_args.add_argument("--sampling-time", dest='t_samp', metavar='t', type=float, default=0.000064,
                           help="set sampling time in seconds (default: 6.4e-5 s)")

    vis_args = parser.add_argument_group("visualisation")
    vis_args.add_argument("--plot", dest='plot', action='store_true', help="visualise various intermediate results")
    vis_args.add_argument("--plot-frequency-range", dest='plot_freq_range', nargs=2, type=float,
                          metavar=('f_min', 'f_max'), help="set frequency range (in MHz) to plot")
    vis_args.add_argument("--plot-output-directory", dest='plot_out_dir', metavar='path',
                          help="set output directory for plots")

    args = parser.parse_args()

    # read samples from time series
    if not args.input:
        parser.error("No input file given")

    samples, t_samp = read_tim_file(args.input)
    t_samp = t_samp or args.t_samp  # take sampling time from (in this order): 1) file, 2) command line, 3) default
    if t_samp != args.t_samp:
        print(f"[WARN] Sampling time mismatch. Expected {args.t_samp} s, but input file uses {t_samp} s")

    # we need twice as many samples as the requested number of channels for the test data, as we will discard the
    # negative frequencies in the spectrum
    n_samp = samples.size
    n_chan = args.test_data_n_chan
    if n_samp < 2 * n_chan:
        print(f"[ERROR] Input file does not contain enough samples. Got {n_samp}, but need at least {2 * n_chan}")
        sys.exit(-1)
    if n_samp > 2 * n_chan:
        print(
            f"[INFO] Discarding {n_samp - 2 * n_chan} samples (= {t_samp * (n_samp - 2 * n_chan):.3f} seconds) to match requested number of channels in spectrum")
        n_samp = 2 * n_chan
        samples.resize(n_samp)

    # perform CXFT: get normalised Fourier transform
    freqs = scipy.fft.fftfreq(n_samp, t_samp)
    ft = scipy.fft.fft(samples) / n_samp

    # discard negative frequencies. SKA-TDT says:
    # % Take only the first half of the series; if the second half is included, the
    # % acceleration with opposite sign to the correct one will be flagged as a candidate
    freqs.resize(n_chan)
    ft.resize(n_chan)

    if args.plot:
        power = np.real(ft * np.conj(ft))
        plot_power_spectrum(freqs, power, args.plot_freq_range or [freqs[0], freqs[-1]])


if __name__ == '__main__':
    main()
