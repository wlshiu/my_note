#!/bin/bash

Red='\e[0;31m'
Yellow='\e[1;33m'
GREEN='\e[0;32m'
Light_Gray='\e[0;37m'
NC='\e[0m' # No Color

help()
{
    echo -e "usage: $0 [options]\n"
    echo -e "Options:"
    echo -e "  -t |--target, Target devic kernel/uboot/busybox"
    echo -e "  -d |--debug, Enable GDB debug"

    echo -e " e.g. $0 -t kernel -d"
    exit -1;
}

if [ -z "$1" ]; then
    help
fi

target=''
debug_mode=''

while [ ! -z "$1" ]; do
    case "$1" in
        --target|-t)
            shift
            echo "Get: $1"
            target=$1
            ;;
        --debug|-d)
            debug_mode=1
            ;;
        *)
            help
            ;;
    esac

    shift
done



flags='-M vexpress-a9 -m 512M -nographic'

if [ "$target" = "kernel" ]; then
    echo -e "$Yellow Qemu kernel ... $NC"

    flags+=' -kernel arch/arm/boot/zImage'
    flags+=' -dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb'
    flags+=' -initrd ../../busybox-1.34.1/rootfs_arm/initramfs-busybox-arm.cpio.gz'
    flags+=' -append "console=ttyAMA0"'

elif [ "$target" = "uboot" ]; then
    echo -e "$Yellow Qemu U-boot ... $NC"

    flags+=' -kernel u-boot'
else

    echo -e "$Red Unknown target item ! $NC"
fi

if [ ! -z "$debug_mode" ]; then
    echo -e "  + Enable debug mode, GDB server"
    flags+=' -s -S'
fi

qemu-system-arm ${flags}
