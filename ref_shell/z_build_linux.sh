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
    echo -e "usage: $0 [options]\n"
    echo -e "Options:"
    echo -e "  -t |--target, Target devic kernel/uboot/busybox"
    echo -e "  -m |--menu, Enable memuconfig"
    echo -e "  -tr|--trace, Generate gtags/tags"

    echo -e " e.g. $0 -t kernel -m"
    exit -1;
}

target=''
menu_enable=''
gtag_enable=''

CROSS_COMPILE=arm-none-eabi-
export CROSS_COMPILE
ARCH=arm
export ARCH

if [ -z "$1" ]; then
    help
fi

while [ ! -z "$1" ]; do
    case "$1" in
        --target|-t)
            shift
            echo "Get: $1"
            target=$1

            ;;
        --menu|-m)
            menu_enable=1
            ;;
        --trace|-tr)
            gtag_enable=1
            ;;
        *)
            help
            ;;
    esac

    shift
done


if [ "$target" = "kernel" ]; then
    echo -e "$Yellow Build kernel ... $NC"

    if [ ! -z "$menu_enable" ]; then
        echo -e "=== for Qemu Configuration\n"
        echo -e "\nGeneral setup ---->"
        echo -e "     [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support"
        echo -e "     (../build/fs.initrd/) Initramfs source file(s)\n"

        echo -e "\nSystem Type  --->"
        echo -e "    [ ] Enable the L2x0 outer cache controller\n"

        echo -e "\nFloating point emulation  --->"
        echo -e "   Disable FPU\n"

        echo -e "\nKernel hacking—>"
        echo -e "Compile-time checks and compiler options ->"
        echo -e "    [*] compile the kernel with debug info\n"
        echo -e "    [*]   Provide GDB scripts for kernel debugging\n"

        make menuconfig
    else
        make vexpress_defconfig
    fi

    make

    if [ ! -z "$gtag_enable" ]; then
        make ARCH=arm CROSS_COMPILE=arm-none-eabi- COMPILED_SOURCE=1 gtags tags
    fi


elif [ "$target" = "uboot" ]; then
    echo -e "$Yellow Build U-boot ... $NC"

    if [ ! -z "$menu_enable" ]; then
        make menuconfig
    else
        make vexpress_ca9x4_defconfig
    fi

    make

    if [ ! -z "$gtag_enable" ]; then
        make ARCH=arm CROSS_COMPILE=arm-none-eabi- COMPILED_SOURCE=1 gtags tags
    fi

elif [ "$target" = "busybox" ]; then

    echo -e "$Yellow Build Busybox ... $NC"

    initramfs_name='initramfs-busybox-arm.cpio.gz'

    make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- defconfig

    if [ ! -z "$menu_enable" ]; then
        echo -e "\nSettings  --->"
        echo -e "    [*] Build static binary (no shared libs)\n"
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
    find -L . -print0 | cpio --null -ov --format=newc | gzip -9 > ${initramfs_name}

    echo -e "$GREEN Gen $(pwd)/${initramfs_name} $NC"

else

    echo -e "$Red Unknown target item ! $NC"
fi
