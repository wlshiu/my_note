#!/bin/bash 

set -e 

out=setting.env
echo "export ARCH=arm" > ${out}
echo "export CROSS_COMPILE=arm-none-eabi-" >> ${out}

source ${out}

make distclean

make evb-ast2500_defconfig
make menuconfig
make 
