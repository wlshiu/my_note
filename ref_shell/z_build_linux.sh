#!/bin/bash

Red='\e[0;31m'
Yellow='\e[1;33m'
GREEN='\e[0;32m'
Light_Gray='\e[0;37m'
NC='\e[0m' # No Color

# ARM_TOOLCHAIN=$HOME/toolchain/gcc-arm-none-eabi-5_4-2016q3/bin
ARM_TOOLCHAIN=$HOME/toolchain/xpack-arm-none-eabi-gcc-11.3.1-1.1/bin

PATH=$HOME/.local/bin:$ARM_TOOLCHAIN:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
export PATH

help()
{
    echo -e "usage: $0 <kernel/uboot/busybox> [menu]"
    echo -e "   e.g. $0 kernel menu"
    exit -1;
}

if [ $# -lt 1 ]; then
    help
fi

target=$1
menu_enable=$2

CROSS_COMPILE=arm-none-eabi-
export CROSS_COMPILE
ARCH=arm
export ARCH


if [ "$target" = "kernel" ]; then
    echo -e "$Yellow Build kernel ... $NC"

    make vexpress_defconfig

    if [ ! -z "$menu_enable" ]; then
        make menuconfig
    fi

    make

elif [ "$target" = "uboot" ]; then
    echo -e "$Yellow Build U-boot ... $NC"

    make vexpress_ca9x4_defconfig

    if [ ! -z "$menu_enable" ]; then
        make menuconfig
    fi

    make

elif [ "$target" = "busybox" ]; then

    echo -e "$Yellow Build Busybox ... $NC"

    make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- defconfig

    if [[ ! -z "$menu_enable" ]]; then
        make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- menuconfig # change to static link
    fi

    make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- install

    if [ -d "rootfs_arm" ]; then
        rm -fr rootfs_arm
    fi

    mkdir rootfs_arm
    cd rootfs_arm

    mkdir -pv {bin,sbin,etc,proc,sys,usr/{bin,sbin}}

    cp -r ../_install/* .

    cat > init << EOF
    #!/bin/sh

    mount -t proc none /proc
    mount -t sysfs none /sys

    echo -e "\nBoot took $(cut -d' ' -f1 /proc/uptime) seconds\n"

    exec /bin/sh
EOF

    chmod +x init
    find . -print0 | cpio --null -ov --format=newc | gzip -9 > ./initramfs-busybox-arm.cpio.gz

    echo -e "$GREEN Gen $(pwd)/initramfs-busybox-arm.cpio.gz $NC"

else

    echo -e "$Red Unknown target item ! $NC"
fi
