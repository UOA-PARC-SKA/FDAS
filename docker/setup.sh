#!/bin/bash

echo "Verifying installation files"
(
cat <<EOD
23c0b92f59cbb12f0c19fa69d68bce0a  /install/AOCLProSetup-17.1.1.273-linux.run
06c407b3700844a0cbc56606b1057611  /install/QuartusProSetup-17.1.0.240-linux.run
0881721e5ed8cf03d4497d3e80edbc11  /install/QuartusProSetup-17.1.1.273-linux.run
01d952a560325854ba565e98b0f67bcd  /install/nalla_aocl_bsp_q17_R001.005.0004.iso
EOD
) | md5sum -c -
if [[ $? -ne 0 ]] ; then
    echo "Aborting setup!"
    exit 1
fi

# install AOC dependencies
yum -y install gcc-c++ make perl which

# setup for CLion remote development
yum -y install openssh-server rsync cmake gdb

# BSP setup
yum -y install xorriso net-tools

# clean up
yum clean all

# generate the host keys
ssh-keygen -A

# make ssh login possible
mkdir /root/.ssh
chmod 700 /root/.ssh
mv /root/id_rsa.pub /root/.ssh/authorized_keys

# ignore ssh clients' sending locale-related environment
# (the image has no non-English locales installed)
sed -i -e '/AcceptEnv L/d' /etc/ssh/sshd_config

echo "Installing Quartus 17.1.0 (this will take a long time)"
QUARTUS_COMPONENTS_TO_DISABLE="quartus_help,cyclone10gx_part1,cyclone10gx_part2,stratix10_part1,stratix10_part2,stratix10_part3,modelsim_ase,modelsim_ae,dsp_builder"
/install/QuartusProSetup-17.1.0.240-linux.run \
    --mode unattended \
    --installdir /opt/intelFPGA_pro/17.1 \
    --accept_eula 1 \
    --disable-components $QUARTUS_COMPONENTS_TO_DISABLE

echo "Updating to Quartus 17.1.1 (this will take a long time)"
/install/QuartusProSetup-17.1.1.273-linux.run \
    --mode unattended \
    --installdir /opt/intelFPGA_pro/17.1 \
    --accept_eula 1

echo "Installing AOCL 17.1.1"
/install/AOCLProSetup-17.1.1.273-linux.run \
    --mode unattended \
    --installdir /opt/intelFPGA_pro/17.1 \
    --accept_eula 1

# clean up
rm -rf /opt/intelFPGA_pro/17.1/uninstall

# revert the profile modifications made by the Quartus installer script
cp /etc/skel/.bashrc /etc/skel/.bash_profile /root

# auto-source the environment definition
echo "source /root/opencl-env.sh" >> /root/.bashrc

# unpack BSP *.iso image
mkdir /bsp
xorriso -osirrox on -indev /install/nalla_aocl_bsp_q17_R001.005.0004.iso -extract . /bsp/
cd bsp

# source OpenCL environment and run BSP installer (which unfortunately must run interactively)
source /root/opencl-env.sh
./setup_linux.sh

# purge installation files
cd /
rm -rf /bsp

# delete this script
rm /root/setup.sh
