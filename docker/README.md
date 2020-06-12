# Containerised OpenCL environment
Follow the instructions below to build a Docker image for OpenCL development targeting Bittware 385A FPGA boards.

Installed components:
* Quartus Prime Software v17.1 Update 1
* Intel FPGA SDK for OpenCL Pro Edition v17.1 Update 1
* Bittware OpenCL BSP `p385a_sch_ax115` version R001.005.0004

In this environment, you can **emulate** OpenCL kernels, and perform the high-level synthesis part of the flow to produce the **detailed HLS report**. To keep the image lean, the Arria 10 device support is not included, therefore a complete synthesis is currently not supported.

SSH access into the container is possible, and enables CLion’s _awesome_ [Full Remote Mode](https://www.jetbrains.com/help/clion/remote-projects-support.html).

## Make sure you have enough space
Building the image requires a _lot_ of temporary space in Docker’s disk image (100 GB should be fine, but hard to say how much space is needed exactly). The finished image weighs about **17 GB**.

## Obtain installation files
1. Go to [Download Center for FPGAs](https://fpgasoftware.intel.com/17.1/?edition=pro&platform=linux) and download:
    * [Individual Files] -> Quartus Prime (includes Nios II EDS) -> `QuartusProSetup-17.1.0.240-linux.run`
    * [Updates] -> [Show Archived Software Updates] -> Quartus Prime Software v17.1 Update 1 -> `QuartusProSetup-17.1.1.273-linux.run`
    * [Updates] -> [Show Archived Software Updates] -> Intel FPGA SDK for OpenCL Pro Edition v17.1 Update 1 -> `AOCLProSetup-17.1.1.273-linux.run`
2. Go to [BittWare’s 385A developer site](https://developer.bittware.com/products/385a.php#opencl) and download the `nalla_aocl_bsp_q17_R001.005.0004.iso` image.
3. Put all 4 files in a single directory (e.g. `/tmp/opencl-install-files`).

## Build the image
1. Copy your `id_rsa.pub` here. (Skip this if you do not plan to ssh into the container.)
2. Build the base image:
```
$ docker build -t aoc-base:centos7 .
```
3. Run the installation procedure. Expect this step to take around 1h. While the Quartus installation runs unattended, the BSP installation requires **interaction**. You need to accept the EULA, and enter a **license key** for `P385A_HPC` valid for the MAC address you specify on the command line:
```
$ docker run -it \
    --name aoc-install --mac-address 00:aa:11:bb:22:cc \
    -v /tmp/opencl-install-files:/install \
    aoc-base:centos7 /bin/bash /root/setup.sh
```
4. Commit the container to produce the final image, `aoc:17.1.1`:
```
$ docker commit -c 'CMD /bin/bash' -c 'EXPOSE 22' aoc-install aoc:17.1.1
```
5. Clean up:
```
$ docker rm aoc-install
```
You may also discard the installation files in `/tmp/opencl-install-files`.

## Run a container
* Standalone: `$ docker run -it aoc:17.1.1`
* With SSH:
    * `$ docker run -it -p 2123:22 aoc:17.1.1`, then inside the container: `# /usr/bin/sshd`.
    * Connect from the host with `$ ssh -p 2123 root@localhost`
