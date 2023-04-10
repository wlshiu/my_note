#!/bin/bash

#
# 以 QEMU 加速嵌入式系統開發
# https://moon-half.info/p/4051
#

if [ "$1" = "" ];then
    echo "Please sepcify ARCH. arm, arm64 or i386"
    exit 1
fi

ARCH=$1
QEMU_KERNEL=`pwd`
ROOTFS=../../rootfs

# 指定啟動時要使用的 Kernel 和 devicetree
# 因為範例也是網上找的, arm64 和 i386 不用指定的原因不確定

if [ $ARCH = "arm" ];then
    KERNEL=arch/arm/boot/zImage
    DTB=arch/arm/boot/dts/vexpress-v2p-ca15-tc1.dtb

elif [ $ARCH = "arm64" ];then
    KERNEL=arch/arm64/boot/Image
    DTB=
elif [ $ARCH = "i386" ];then
    KERNEL=arch/i386/boot/bzImage
    DTB=

fi

# 由於 QEMU 是用 NAT 連線的方式, 無法直接由 Host OS 連進來
# 故這邊要指定從 Host 做 port forwarding
# 由 host TCP 2353 轉進 Guest 的 23 port
# 由 host UDP 6759 轉進 Guest 6789 port

#REDIR="$REDIR -redir tcp:2323::23"
#REDIR="$REDIR -redir udp:6789::6789"
REDIR="hostfwd=tcp::2353-:23"
REDIR="$REDIR,hostfwd=udp::6759-:6789"
CORES=2
MEM=512M


rm -f ${ROOTFS}/dev/console
rm -f ${ROOTFS}/dev/ttyGS0

# 由於本範例是使用 ramdisk 當做 rootfs, 重開後資料會不見.
# 因此這邊產生一塊約 100MB 的空間, 做為可寫入的區塊
# 進系統後可以 fdisk 和 mke2fs 來分割,格式化使用

#rm -f img.ext2
if [ ! -e ../empty.ext2.gz ];then
    mkdir empty
    genext2fs -v -b 100000 -N 5000 -d empty -e 0 - | gzip -5 > ../empty.ext2.gz
fi

[ ! -e ../img.ext2 ]  && gunzip -c ../empty.ext2.gz > ../img.ext2

cd ${ROOTFS}
find . | cpio -o -H newc | pigz -5 > ${QEMU_KERNEL}/rootfs.img

cd ${QEMU_KERNEL}


#qemu-system-arm -M vexpress-a9 -m 512M -kernel ${KERNEL} -dtb ${DTB} -nographic -append "root=/dev/mmcblk0 console=ttyAMA0" -sd img.ext2 -net user,hostfwd=tcp::8080-:80 -redir tcp:2323::23 -net nic -smp 4
#qemu-system-arm -M vexpress-a9 -m ${MEM} -kernel ${KERNEL} -dtb ${DTB} -nographic -initrd rootfs.img -append "root=/dev/ram0 console=ttyAMA0 rdinit=/linuxrc" -sd ../img.ext2 -net user,hostfwd=tcp::8080-:80 $REDIR -net nic -smp ${CORES}

if [ "$ARCH" = "arm" ];then

    # -M vexpress-a15 : 指定 ARM 的 machine type
    # -nographic      : 不要使用 GUI 視窗
    # --append        : 指定 rootfs 的裝置, console 為 kernel config 內的設定 ttyAMA0
    #                   rdinit 為 rootfs /linuxrc. 若是使用自己的 rootfs, 要依實際的檔名
    #                   做修改 (ex. sysinit)
    # initrd          : 指定 ramdisk 的檔案
    # -drive          : 指定附加的可寫入的磁碟區塊
    # -net            : 指定網路的型態和 port forwarding 的 list

    qemu-system-arm -M vexpress-a15 -nographic -m ${MEM}  \
    -kernel ${KERNEL} -dtb ${DTB} \
    --append "root=/dev/ram0 console=ttyAMA0 rdinit=/linuxrc" \
    -initrd  rootfs.img \
    -drive if=none,file=../img.ext2,id=hd0,format=raw -device virtio-blk-device,drive=hd0 \
    -net user,hostfwd=tcp::8489-:80,$REDIR -net nic -smp ${CORES}

elif [ "$ARCH" = "i386" ];then

    # --append : x86 一般 console 會用 ttyS0
    # -serial  : 上網查到的
    qemu-system-i386   -m ${MEM}  -kernel ${KERNEL} \
    --append "root=/dev/ram0  rdinit=/linuxrc console=ttyS0 " \
    -smp ${CORES} -nographic -serial mon:stdio \
    -initrd  rootfs.img  \
    -net user,hostfwd=tcp::8489-:80,$REDIR -net nic

elif [ "$ARCH" = "arm64" ];then
    # -machine virt -cpu cortex-a57 : 上網查到的
    qemu-system-aarch64 -machine virt -cpu cortex-a57 -machine type=virt \
    -nographic -m ${MEM} -kernel ${KERNEL} \
    --append "root=/dev/ram0 console=ttyAMA0 rdinit=/linuxrc" -initrd  rootfs.img \
    -drive if=none,file=../img.ext2,id=hd0,format=raw -device  virtio-blk-device,drive=hd0 \
    -net user,hostfwd=tcp::8489-:80,$REDIR -net nic -smp ${CORES}
fi

exit 0
