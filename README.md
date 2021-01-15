# FDAS

Fourier Domain Acceleration Search, FPGA-accelerated with OpenCL.

FDAS is a key component in the detection of pulsars in signals received by radio telescopes. This particular implementation is designed to meet the specifications of the Square Kilometer Array's (SKA) pulsar search engine. See the references below for more details.

### Prerequisites

**For the hardware synthesis:**
- Bittware 385A FPGA accelerator card
- Quartus Prime Software v17.1 Update 1
- Intel FPGA SDK for OpenCL Pro Edition v17.1 Update 1
- Bittware OpenCL BSP `p385a_sch_ax115` version R001.005.0004

Instructions to set up the required toolchain inside a Docker image are provided in `docker/README.md`. The script `docker/setup.sh` may also serve as a starting point for a manual setup.

**For building the host application:**
- C++11-compatible compiler ( `g++ 4.8.5`, as found in CentOS 7.8, is known to work)
- CMake 2.8 or newer (`cmake 2.8.12.2` is known to work)
- OpenCL headers and runtime libraries provided by Intel's SDK

**For creating reference test data:**
- Python 3 (`python 3.7.7` is known to work)
- Python packages NumPy and SciPy (`numpy 1.19.0` and `scipy 1.5.0` are known to work)
- [PSS Test Vector Generator](https://gitlab.com/ska-telescope/pss-test-vector-generator) (Docker image available), or another source of time-series data in [SIGPROC](http://sigproc.sourceforge.net) format

### Building

Make sure the environment variables `INTELFPGAOCLSDKROOT` and `AOCL_BOARD_PACKAGE_ROOT` are set correctly.

    $ mkdir build ; cd build
    $ cmake ..

The following `make` targets are available:
- `fdas_gtest`: builds the host application
- `fdas_emu`: compiles the OpenCL kernels for software emulation
- `fdas_report`: creates the HLS report
- `fdas_synth`: performs the full FPGA synthesis

The command-line flags passed to `aoc` can be configured in `fdas/CMakeLists.txt`

### Creating reference test data

To generate a unit test-like signal with the SKA's test vector generator, run the following commands in the provided Docker image (assuming this repository is bind-mounted to `/fdas`):

    $ python psr/soft/vectortools/Pipeline.py -m FDAS-unit -d /fdas/fdas/test/configs -o generated
    $ dedisperse generated/Default*.fil -d 0.0 -o /fdas/fdas/test/unit.tim

Back on the host, in the `fdas/test` directory, execute:

    $ python3 ft_conv.py --templates ../tmpl/fdas_templates_85_350.npy \
                         --tile-and-transform --fft-order unit.tim
    $ python3 hsum.py unit/fop_ref.npy

Add `--num-frequency-bins 32768` to the first command to produce a much smaller data set, suitable for the OpenCL software emulator. Both scripts accept additional options; invoke them with `--help` for more information.

### Running the host application/unit tests

    $ cd build/fdas
    $ ./fdas_gtest ../../fdas/test/unit

### License

    Copyright (C) 2020  Parallel and Reconfigurable Computing Lab,
                        Dept. of Electrical, Computer, and Software Engineering,
                        University of Auckland, New Zealand

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

This implementation uses and distributes the following third-party libraries:
- A complex single-precision floating-point radix-2^2 feedforward FFT / iFFT engine, written by Altera Corporation. See `fdas/src/device/fft_4p.cl` for license details.
- *libnpy*, written by Leon Merten Lohse. See `thirdparty/libnpy/include/libnpy/npy.hpp` for license details.
- *googletest*, written by Google, Inc. See `thirdparty/googletest/LICENSE` for license details.

### Major contributors

*listed in alphabetical order*
- Julian Oppermann
- Oliver Sinnen
- Haomiao Wang

### References

- H. Wang, P. Thiagaraj, and O. Sinnen, “FPGA-based Acceleration of FT Convolution for Pulsar Search Using OpenCL,” TRETS, vol. 11, no. 4, p. 24:1–24:25, 2019, doi: 10.1145/3268933.
- H. Wang, P. Thiagaraj, and O. Sinnen, “Harmonic-Summing Module of SKA on FPGA - Optimizing the Irregular Memory Accesses,” IEEE Trans. Very Large Scale Integr. Syst., vol. 27, no. 3, pp. 624–636, 2019, doi: 10.1109/TVLSI.2018.2882238.
- H. Wang, P. Thiagaraj, and O. Sinnen, “Combining Multiple Optimised FPGA-based Pulsar Search Modules Using OpenCL,” Journal of Astronomical Instrumentation, 2019, doi: 10.1142/S2251171719500089.

### Acknowledgement

This work benefitted from discussions with the SKA Time Domain Team (TDT), a collaboration between Manchester and Oxford Universities, and MPIfR Bonn.
