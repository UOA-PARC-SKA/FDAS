#!/bin/bash

export LM_LICENSE_FILE=1717@altera.licenses.foe.auckland.ac.nz

export QUARTUS_ROOTDIR=/opt/intelFPGA_pro/17.1/quartus
export QUARTUS_ROOTDIR_OVERRIDE=$QUARTUS_ROOTDIR
export QUARTUS_64BIT=1

export INTELFPGAOCLSDKROOT=$QUARTUS_ROOTDIR/../hld
export ALTERAOCLSDKROOT=$INTELFPGAOCLSDKROOT
export AOCL_BOARD_PACKAGE_ROOT=$INTELFPGAOCLSDKROOT/board/nalla_pcie

# this image is only intended for emulation
export CL_CONTEXT_EMULATOR_DEVICE_INTELFPGA=1
export CL_CONTEXT_EMULATOR_DEVICE_ALTERA=1

source $INTELFPGAOCLSDKROOT/init_opencl.sh > /dev/null
