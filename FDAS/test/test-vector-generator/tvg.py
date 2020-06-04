#!/usr/bin/env python3

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


def read_tim_file(tim_file, n_samp):
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
    signal = np.fromfile(tim_file, dtype=np.float32, offset=offset, count=n_samp)
    print(f"[INFO] Read {signal.shape[0]} samples from '{tim_file}'")

    return signal, t_samp


def plot_power_spectrum(signal, t_samp):
    N = signal.shape[0]

    f = scipy.fft.fftfreq(N, t_samp)
    X = scipy.fft.fft(signal) / N

    power = np.real(X * X.conj())

    plt.title("Power spectrum (one-sided)")
    plt.xlabel("Frequency [Hz]")
    plt.ylabel("Power")
    plt.plot(f, power)
    plt.xlim(xmin=0, xmax=(1 / (2 * t_samp)))
    plt.show()

def main():
    parser = argparse.ArgumentParser(description="Generate test vectors for FDAS module.")
    parser.add_argument("--read-time-series", dest='tim_file', metavar='FILE',
                        help="read time series from a *.tim file")
    parser.add_argument("--sampling-time", dest='t_samp', metavar='T', type=float, default='0.000064',
                        help="set sampling time for headerless *.tim files (ignored if a header is present)")
    parser.add_argument("--num-samples", dest='n_samp', type=int, default=2 ** 23, metavar='N',
                        help="specify number of samples to read and process. The generated FDAS input files will contain N/2 complex points. Default: 8388608 (8M)")
    args = parser.parse_args()

    n_samp = args.n_samp
    if args.tim_file:
        signal, t_samp = read_tim_file(args.tim_file, n_samp)
    # TODO: automatically launch the Docker images to generate files

    if signal is None:
        raise RuntimeError("No input data")
    if signal.shape[0] < n_samp:
        raise RuntimeError(f"Read fewer samples ({signal.shape[0]}) than requested ({n_samp})")

    t_samp = t_samp or args.t_samp  # use argument or default value if the file was headerless

    plot_power_spectrum(signal, t_samp)


if __name__ == '__main__':
    main()
