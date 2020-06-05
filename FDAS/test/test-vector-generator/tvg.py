#!/usr/bin/env python3

import sys
import argparse
import struct
import numpy as np
import scipy.fft
import scipy.special

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


def fresnel_wrapper(a):
    # Workaround: SciPy's fresnel function behaves differently from Matlab on complex numbers
    if not np.any(np.real(a)) and np.any(np.imag(a)):
        # Found this through trial and error -- I honestly have NO idea why this is works
        s, c = scipy.special.fresnel(np.imag(a))
        s = np.conj(s * 1j)
        c = c * 1j
    elif np.any(np.real(a)) and not np.any(np.imag(a)):
        s, c = scipy.special.fresnel(np.real(a))
        s = s + 0j
        c = c + 0j
    else:
        raise RuntimeError("Array contains values that are not strictly real or imaginary")

    return s, c


def generate_templates(numTemplates, maxAccel, unAccelFreq, obsLength, speedOfLight):
    # Straight port of https://gitlab.com/SKA-TDT/tdt-matlab-models/-/blob/master/FDAS/templateGenerator.m [2af28d2e]
    # Comments starting with '%' are taken from the Matlab code

    templates = []

    # % Calculate the acceleration step size based on the number of templates requested
    accelStep = 2 * maxAccel / numTemplates

    for templateNum in range(numTemplates + 1):
        # % Calculate how many bins the signal would drift for a 500 Hz signal
        binsSignalDrifts = (accelStep * templateNum - maxAccel) * unAccelFreq * np.square(obsLength) / speedOfLight

        if binsSignalDrifts != 0:
            # % Calculate the width of the template. The shift by binsSignalDrifts/2 is to
            # % center the template so that the edges are not cut off during its calculation
            templateWidth = np.arange(-np.abs(binsSignalDrifts), np.abs(binsSignalDrifts)) - binsSignalDrifts / 2

            # % Calculate limits for the Fresnel integrals below
            Y = templateWidth * np.sqrt(np.complex(2 / binsSignalDrifts))
            Z = (templateWidth + binsSignalDrifts) * np.sqrt(np.complex(2 / binsSignalDrifts))

            # % Calculate Fresnel integrals for use in generating the template
            sinY, cosY = fresnel_wrapper(Y)
            sinZ, cosZ = fresnel_wrapper(Z)

            # % Create a template for this acceleration
            templates += [1 / np.sqrt(np.complex(2 * binsSignalDrifts))
                          * np.exp(1j * np.pi * np.square(templateWidth) / binsSignalDrifts)
                          * (sinZ - sinY - 1j * (cosY - cosZ))]
        else:
            templates += [np.ones(1, dtype=np.complex)]

    return templates


def main():
    parser = argparse.ArgumentParser(description="Generate test vectors for FDAS module.")

    mode_args = parser.add_argument_group("mode")
    mode_args.add_argument("--generate-templates", dest='mode_gen_tmpl', action='store_true',
                           help="generate filter templates")
    mode_args.add_argument("--plot", dest='mode_plot', action='store_true', help="visualise power spectrum")
    mode_args.add_argument("--make-test-data", dest='mode_make_test_data', action='store_true',
                           help="read time series data, and write test files (input and reference output) for the FDAS module")

    tmpl_args = parser.add_argument_group("template generator")
    tmpl_args.add_argument("--num-templates", dest='tmpl_gen_n_tmpl', type=int, metavar='N', default=85,
                           help="set number of filter templates to generate. Needs to be an odd number (default: 85)")
    tmpl_args.add_argument("--max-acceleration", dest='tmpl_gen_max_accel', type=float, metavar='A', default=350,
                           help="set maximum acceleration (both positive and negative) in m/s^2 (default: 350 m/s^2)")
    tmpl_args.add_argument("--template-unaccelerated-frequency", dest='tmpl_gen_unaccel_freq', type=float, metavar='F',
                           default=500,
                           help="set frequency of unaccelerated signal in MHz (default: 500 MHz)")

    plot_args = parser.add_argument_group("plotting")
    plot_args.add_argument("--frequency-range", dest='plot_freq_range', nargs=2, type=float, metavar=('f_min', 'f_max'),
                           help="set frequency range (in MHz) to plot")

    test_args = parser.add_argument_group("test data")
    test_args.add_argument("--num-channels", dest='test_data_n_chan', type=int, metavar='N', default=2 ** 22,
                           help="set number of channels in test data (default: 2^22)")

    general_args = parser.add_argument_group("general parameters")
    general_args.add_argument("--sampling-time", dest='t_samp', metavar='T', type=float, default=0.000064,
                              help="set sampling time in seconds (default: 6.4e-5 s)")
    general_args.add_argument("--observation-time", dest='t_obs', metavar='T', type=float, default=600,
                              help="set total observation time in seconds (default: 600 s)")
    general_args.add_argument("--speed-of-light", dest='t_c', metavar='T', type=float, default=299792458,
                              help="set speed of light in m/s (default: 299792458 m/s)")

    io_args = parser.add_argument_group("I/O")
    io_args.add_argument('-i', "--input", dest='input', metavar="FILE",
                         help="SIGPROC *.tim file containing time-series samples")
    io_args.add_argument('-o', "--output", dest='output', metavar='FILE', help="set output file or directory")

    args = parser.parse_args()

    # generate templates (only)
    if args.mode_gen_tmpl:
        # Number of templates must be odd, as we generate:
        #    N//2 filters that correspond  to negative accelerations
        #  +  1   filter  that corresponds to zero acceleration
        #  + N//2 filters that correspond  to positive accelerations
        if args.tmpl_gen_n_tmpl % 2 == 0:
            parser.error("Number of templates must be odd")

        templates = generate_templates(
            numTemplates=args.tmpl_gen_n_tmpl - 1,  # in the Matlab code, only the non-zero accelerations are counted
            maxAccel=args.tmpl_gen_max_accel,
            unAccelFreq=args.tmpl_gen_unaccel_freq,
            obsLength=args.t_obs,
            speedOfLight=args.t_c)

        with open(args.output or "fdas_templates.txt", 'wt') as tmpl_file:
            for tmpl in templates:
                tmpl_float = np.empty(2 * tmpl.size, dtype=np.float32)
                tmpl_float[0::2] = np.real(tmpl)
                tmpl_float[1::2] = np.imag(tmpl)
                tmpl_file.write(' '.join(f"{coeff:g}" for coeff in tmpl_float) + '\n')

        sys.exit(0)

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

    if args.mode_plot:
        power = np.real(ft * np.conj(ft))
        plot_power_spectrum(freqs, power, args.plot_freq_range or [freqs[0], freqs[-1]])


if __name__ == '__main__':
    main()
