#!/bin/bash

set -e

help()
{
    echo -e "usage: $0 <arch type>"
    echo -e "   arch type:"
    echo -e "       arm/arm64"
    echo -e "       riscv32/riscv64"
    exit -1;
}

if [ $# != 1 ]; then
    help
fi

arch_type=$1
env_file=setting.env

echo -e "export PATH=$HOME/.local/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" > ${env_file}

case "${arch_type}" in
    "arm")
        echo -e "export ARCH=${arch_type}" >> ${env_file}
        echo -e "export PATH=${HOME}/toolchain/gcc-linaro-6.5.0-2018.12-i686_arm-linux-gnueabi/bin:${PATH}" >> ${env_file}
        echo -e "CROSS_COMPILE=arm-linux-gnueabi-" >> ${env_file}
        ;;

    "arm64")
        echo -e "export ARCH=${arch_type}" >> ${env_file}
        echo -e "export PATH=${HOME}/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin:${PATH}" >> ${env_file}
        echo -e "CROSS_COMPILE=aarch64-linux-gnu-" >> ${env_file}
        ;;
    "riscv32")
        echo -e "export ARCH=riscv" >> ${env_file}
        echo -e "export PATH=${HOME}/toolchain/riscv32_toolchain/bin:${PATH}" >> ${env_file}
        echo -e "CROSS_COMPILE=riscv32-unknown-elf-" >> ${env_file}
        ;;
    "riscv64")
        echo -e "export ARCH=riscv" >> ${env_file}
        echo -e "CROSS_COMPILE=riscv64-linux-gnu-" >> ${env_file}
        ;;
    *)
        help
        ;;
esac
