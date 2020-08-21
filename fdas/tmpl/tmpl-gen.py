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
import numpy as np
import scipy.fft
import scipy.special


def _fresnel_wrapper(a):
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
            sinY, cosY = _fresnel_wrapper(Y)
            sinZ, cosZ = _fresnel_wrapper(Z)

            # % Create a template for this acceleration
            templates += [1 / np.sqrt(np.complex(2 * binsSignalDrifts))
                          * np.exp(1j * np.pi * np.square(templateWidth) / binsSignalDrifts)
                          * (sinZ - sinY - 1j * (cosY - cosZ))]
        else:
            templates += [np.ones(1, dtype=np.complex)]

    return templates


def bit_rev(x, bits):
    y = 0
    for i in range(bits):
        y <<= 1
        y |= x & 1
        x >>= 1
    return y


def main():
    parser = argparse.ArgumentParser(description="Generate filter templates for FDAS module.")

    gen_args = parser.add_argument_group("generation")
    gen_args.add_argument("--num-templates", dest='n_tmpl', type=int, metavar='n', default=85,
                          help="set number of filter templates to generate. Needs to be an odd number (default: 85)")
    gen_args.add_argument("--max-acceleration", dest='max_accel', type=float, metavar='a', default=350,
                          help="set maximum acceleration (both positive and negative) in m/s^2 (default: 350 m/s^2)")
    gen_args.add_argument("--unaccelerated-frequency", dest='unaccel_freq', type=float, metavar='f',
                          default=500, help="set frequency of unaccelerated signal in MHz (default: 500 MHz)")
    gen_args.add_argument("--observation-time", dest='t_obs', metavar='t', type=float, default=600,
                          help="set total observation time in seconds (default: 600 s)")
    gen_args.add_argument("--speed-of-light", dest='t_c', metavar='c', type=float, default=299792458,
                          help="set speed of light in m/s (default: 299792458 m/s)")

    parser.add_argument("-w", "--precision", dest='precision', choices=['single', 'double'], default='single',
                        help="select output floating point precision (default: single")
    parser.add_argument("-f", "--fourier-transform", dest='ft_sz', type=int, metavar='n', nargs='?', const=2 ** 11,
                        help="request (individual) Fourier transform of the templates with the specified size "
                             "(default: 2048 = 2K)")
    parser.add_argument("-p", "--fft-order", dest='n_fft_par', type=int, metavar='n', nargs='?', const=4,
                        help="write templates in FFT-order (cf. `ft_conv.cl`). Optionally, specify the FFT engine's "
                             "number of parallel inputs (default: 4)")
    parser.add_argument("-o", "--output", dest='output', metavar='path', required=True, help="set output file")

    args = parser.parse_args()

    # Number of templates must be odd, as we generate:
    #    N//2 filters that correspond  to negative accelerations
    #  +  1   filter  that corresponds to zero acceleration
    #  + N//2 filters that correspond  to positive accelerations
    if args.n_tmpl % 2 == 0:
        parser.error("Number of templates must be odd")

    if args.n_fft_par and not args.ft_sz:
        parser.error("Cannot apply FFT order to non-FT output")

    templates = generate_templates(
        numTemplates=args.n_tmpl - 1,  # in the Matlab code, only the non-zero acceleration templates are counted
        maxAccel=args.max_accel,
        unAccelFreq=args.unaccel_freq,
        obsLength=args.t_obs,
        speedOfLight=args.t_c
    )

    n_tmpl = len(templates)
    print(f"[INFO] Generated {n_tmpl} templates")

    out_dtype = np.complex64 if args.precision == 'single' else np.complex128
    if args.ft_sz:
        n = args.ft_sz
        out = np.empty((n_tmpl, n), dtype=out_dtype)
        for i in range(n_tmpl):
            out[i][:] = scipy.fft.fft(templates[i], n)

        if args.n_fft_par:
            p = args.n_fft_par
            for i in range(n_tmpl):
                tile = np.empty(n, dtype=out_dtype)
                for j in range(p):
                    chunk_begin = bit_rev(j, int(np.log2(p))) * n // p
                    chunk_end = chunk_begin + n // p
                    tile[j::p] = out[i][chunk_begin:chunk_end]
                out[i][:] = tile
    else:
        max_size = max(t.size for t in templates)
        out = np.zeros((n_tmpl, max_size), dtype=out_dtype)
        for i in range(n_tmpl):
            tmpl = templates[i]
            out[i][:tmpl.size] = tmpl

    np.save(args.output, out)
    print(f"[INFO] Wrote '{args.output if args.output.endswith('.npy') else (args.output + '.npy')}':")
    print(f"         shape:               {out.shape}")
    print(f"         type:                {out.dtype}")
    print(f"         Fourier-transformed? {'yes' if args.ft_sz else 'no'}")
    print(f"         FFT-order?           {(str(args.n_fft_par) + '-parallel') if args.n_fft_par else 'no'}")


if __name__ == '__main__':
    main()
