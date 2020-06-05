#!/usr/bin/env python3

import argparse
import numpy as np
import scipy.fft
import scipy.special
import timeit


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

    parser.add_argument("--write-numpy-archive", dest='numpy_archive', metavar='path', nargs='?',
                        const='fdas_templates.npz',
                        help="write templates as an *.npz archive, for use in the FDAS test vector generator. (default "
                             "file name: 'fdas_templates.npz')")
    parser.add_argument("--write-header-file", dest='header_file', metavar='path', nargs='?',
                        const="fdas_templates.h",
                        help="write Fourier transformed templates as an float array in a C header file, for use in the "
                             "FDAS host code. (default file name: 'fdas_templates.h')")
    parser.add_argument("--fourier-transform-size", dest='ft_sz', type=int, metavar='n', default=2 ** 11,
                        help="set the size of each template's Fourier transform (default: 2048 = 2K)")

    args = parser.parse_args()

    if not args.numpy_archive and not args.header_file:
        parser.error("Nothing to do, use --write-numpy-archive, --write-header-file, or both")

    # Number of templates must be odd, as we generate:
    #    N//2 filters that correspond  to negative accelerations
    #  +  1   filter  that corresponds to zero acceleration
    #  + N//2 filters that correspond  to positive accelerations
    if args.n_tmpl % 2 == 0:
        parser.error("Number of templates must be odd")

    gen_start = timeit.default_timer()

    templates = generate_templates(
        numTemplates=args.n_tmpl - 1,  # in the Matlab code, only the non-zero acceleration templates are counted
        maxAccel=args.max_accel,
        unAccelFreq=args.unaccel_freq,
        obsLength=args.t_obs,
        speedOfLight=args.t_c
    )

    gen_end = timeit.default_timer()
    print(f"[INFO] Generated {len(templates)} templates in {gen_end - gen_start:.3f} seconds")

    if args.numpy_archive:
        np.savez(args.numpy_archive, **{f"template_{i:03d}": templates[i] for i in range(len(templates))})
        print(f"[INFO] Wrote '{args.numpy_archive}'")

    if args.header_file:
        with open(args.header_file, 'wt') as header:
            tmpl_lines = []
            for tmpl in templates:
                tmpl_ft = scipy.fft.fft(tmpl, args.ft_sz)
                tmpl_float = np.empty(2 * args.ft_sz, dtype=np.float32)
                tmpl_float[0::2] = np.real(tmpl_ft)
                tmpl_float[1::2] = np.imag(tmpl_ft)
                tmpl_lines += [(' ' * 4) + ', '.join(f"{coeff:13.10f}f" for coeff in tmpl_float)]

            header.write(f"const float FDAS_TEMPLATES[{len(templates)}][{2 * args.ft_sz}] = " + "{\n")
            header.write(',\n'.join(tmpl_lines))
            header.write("};\n")
        print(f"[INFO] Wrote '{args.header_file}'")


if __name__ == '__main__':
    main()
