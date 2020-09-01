Qemu
---

# Ubuntu 18.04

+ dependency

    ```shell
    $ sudo apt install librados2=12.2.4-0ubuntu1
    $ sudo apt-get install librbd1
    $ sudo apt-get install qemu-block-extra
    $ sudo apt-get install qemu-system-common
    $ sudo apt-get install qemu-system-arm
    ```

    - switch gcc version

    ```shell
    #!/bin/bash -

    set -e

    help()
    {
        echo "usage: $0 [ver-number]"
        echo "  e.g. $0 4.9"
        echo "  e.g. $0 7"
        exit 1;
    }

    if [ $# != 1 ]; then
        help
    fi

    case $1 in
        "7")
            sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 73 \
                --slave /usr/bin/g++ g++ /usr/bin/g++-7 \
                --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-7 \
                --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-7 \
                --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-7
            ;;
        "4.9")
            sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 49 \
                --slave /usr/bin/g++ g++ /usr/bin/g++-4.9 \
                --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-4.9 \
                --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-4.9 \
                --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-4.9
            ;;
    esac
    ```

+ check

    ```shell
    $ qemu-system-arm -machine -cpu help
    ```

+ example

    - [freertos-plus](https://github.com/embedded2014/freertos-plus)

        ```shell
        $ cd freertos-plus
        $ make
        $ cd build
        $ qemu-system-arm -M stm32-p103 -monitor stdio -kernel main.bin -semihosting
        ```

# Version


+ `qemu-arm` 是用戶模式的模擬器(更精確的表述應該是系統調用模擬器),
    > 僅可用來運行二進制文件, 因此你可以交叉編譯完, 例如 hello world 之類的程序然後交給 qemu-arm 來運行, 簡單而高效

+ `qemu-system-arm` 則是系統模擬器
    > 它可以模擬出整個機器並運行操作系統, 需要你把 hello world 程序下載到客戶機操作系統能訪問到的硬盤裡才能運行


# Cross compile

+ qemu

    ```shell
    $ mkdir qemu && cd qemu
    $ wget https://download.qemu.org/qemu-5.1.0.tar.xz
    $ tar -xJf qemu-5.1.0.tar.xz

    $ sudo apt-get install libpixman-1-dev
    $ ./configure --target-list=arm-softmmu --static --prefix=$HOME/.local/
    $ make
    $ make install
    $ ./out/bin/arm-system-arm -M vexpress-a9 -kernel u-boot -nographic -m 128M
    ```

    - `--target-list=LIST`
        > set target list (default: build everything)

        ```
        --target-list=arm-softmmu,arm-linux-user
        ```

        1. `x86_64-softmmu`
            > x86_64-linux-use

        1. `xxx-softmmu`
            > compile `qemu-system-xxx`

        1. `xxx-linux-user`
            > compiles `qemu-xxx` (User-mode emulation)

    - [qemu-system-gnuarmeclipse](https://github.com/xpack-dev-tools/qemu-arm-xpack/releases/)
        > this qemu is for Cortex-M serial

    ```shell
    # -memory size=kb
    $ qemu-system-gnuarmeclipse --verbose \
        --board STM32F4-Discovery --mcu STM32F407VG \
        -d unimp,guest_errors \
        -memory size=512 \
        --nographic \
        --image hello_rtos.elf

    $ qemu-system-gnuarmeclipse --verbose --board STM32F4-Discovery \
      --mcu STM32F407VG --gdb tcp::1234 -d unimp,guest_errors \
      --semihosting-config enable=on,target=native \
      --semihosting-cmdline \
      --image hello_rtos.elf
    ```

    - reference
        1. [STM32F429_Discovery_FreeRTOS_9](https://github.com/cbhust/STM32F429_Discovery_FreeRTOS_9)

    ```shell
    # -m size=256 (SRAM = 256KB)
    $ qemu-system-gnuarmeclipse --verbose --verbose \
        --board STM32F429I-Discovery --mcu STM32F429ZI \
        -d unimp,guest_errors -m size=256 \
        --image hello_rtos.elf \
        --semihosting-config enable=on,target=native --semihosting-cmdline hello_rtos 1 2 3
    ```

+ u-boot (for test)

    ```shell
    $ wget ftp://ftp.denx.de/pub/u-boot/u-boot-2019.10.tar.bz2
    $ tar -xjf u-boot-2019.10.tar.bz2
    $ cd u-boot-2019.10
    $ vi ./Makefile
        # instert to top
        ARCH = arm
        CROSS_COMPILE = arm-none-eabi-

    $ make vexpress_ca9x4_defconfig
    $ make
    ```

# My build-up flow (Ubuntu 18.04)

+ Install Qemu

```
$ sudo apt-get install qemu
$ qemu-arm --version
qemu-arm version 2.11.1(Debian 1:2.11+dfsg-1ubuntu7)
Copyright (c) 2003-2017 Fabrice Bellard and the QEMU Project developers
```

+ uboot

    - download

    ```
    $ wget https://mirror.cyberbits.eu/u-boot/u-boot-2020.01-rc5.tar.bz2
    $ tar -xjf u-boot-2020.01-rc5.tar.bz2
    $ cd u-boot-2020.01-rc5
    ```

    - compile

    ```shell
    $ vi ./z_build_uboot.sh
        #!/bin/bash -
        set -e

        out=setting.env
        echo "export ARCH=arm" > ${out}
        echo "export SUBARCH=aspeed" >> ${out}
        echo "export CROSS_COMPILE=arm-none-eabi-" >> ${out}
        echo "SRCACH=arm" >> ${out}

        source ${out}

        make vexpress_ca9x4_defconfig
        make
        make cscope
    $ sudo chmod +x ./z_build_uboot.sh
    $ ./z_build_uboot.sh
    ```

    - run uboot with Qemu

        1. with network

        ```shell
        $ vi ./z_run_uboot.sh
            #!/bin/bash -

            set -e

            sudo qemu-system-arm -M vexpress-a9 -kernel u-boot \
                -nographic -m 256M -net nic \
                -net tap,ifname=tap0,script=no,downscript=no
        $ sudo chmod +x ./z_run_uboot.sh
        $ ./z_run_uboot.sh
        U-Boot 2020.01-rc5 (Mar 26 2020 - 14:37:21 +0800)
        DRAM:  256 MiB
        WARNING: Caches not enabled
        Flash: 128 MiB
        MMC:   MMC: 0

        In:    serial
        Out:   serial
        Err:   serial
        Net:   smc911x-0
        Hit any key to stop autoboot:  0
        ```

    - Debug on Qemu with GDB

        1. start GDB server

        ```
        $ vi ./z_run_gdb_server.sh
            #!/bin/bash -

            set -e

            ## GDB server
            sudo qemu-system-arm -M vexpress-a9 -nographic -m 256M -kernel u-boot -s -S
        $ sudo chmod +x ./z_run_gdb_server.sh
        $ ./z_run_gdb_server.sh
        ```

        1. open the other terminal

        ```
        $ arm-none-eabi-gdb
        GNU gdb (GNU Tools for Arm Embedded Processors 8-2019-q3-update) 8.3.0.20190703-git
        Copyright (C) 2019 Free Software Foundation, Inc.
        License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
        This is free software: you are free to change and redistribute it.
        There is NO WARRANTY, to the extent permitted by law.
        Type "show copying" and "show warranty" for details.
        This GDB was configured as "--host=x86_64-linux-gnu --target=arm-none-eabi".
        Type "show configuration" for configuration details.
        For bug reporting instructions, please see:
        <http://www.gnu.org/software/gdb/bugs/>.
        Find the GDB manual and other documentation resources online at:
            <http://www.gnu.org/software/gdb/documentation/>.

        For help, type "help".
        Type "apropos word" to search for commands related to "word".

        Invalid type combination in equality test.
        (gdb) file u-boot
        Reading symbols from u-boot...
        (gdb) target remote:1234
        Remote debugging using :1234
        _start () at arch/arm/lib/vectors.S:87
        87		ARM_VECTORS
        (gdb)

        ```
+ linux

    - download

    ```
    $ sudo apt-get install u-boot-tools # for mkimage tool
    $ wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.14.7.tar.xz
    $ tar -xJf linux-4.14.7.tar.xz
    ```

    - compile

    ```shell
    $ vi ./z_build_linux.sh
        #!/bin/bash -

        set -e

        out=setting.env
        echo "export ARCH=arm" > ${out}
        echo "export CROSS_COMPILE=arm-none-eabi-" >> ${out}
        echo "export SRCARCH=arm" >> ${out}

        source ${out}
        make vexpress_defconfig
        make menuconfig
        make

        make COMPILED_SOURCE=1 cscope

    $ sudo chmod +x ./z_build_linux.sh
    $ ./z_build_linux.sh
    ```

        1. configure for QEMU

        ```
        $ make menuconfig
            System Type -->
                [ ] Enable the L2x0 outer cache controller
                ps. Disable this option (or QEMU works fail)
            Kernel Features -->
                [*] Use the ARM EABI to compile the kernel
                ps. Enable this option

            ...

            kernel hacking—>
               Compile-time checks and compiler options ->
                 [*] compile the kernel with debug info
                 ps. Enable the debug info of kernel
        ```

    - run kernel on QEMU

    ```
    $ vi z_start_kernel.sh
        #!/bin/bash

        sudo qemu-system-arm \
        -M vexpress-a9 \
        -m 512M \
        -kernel arch/arm/boot/zImage \
        -dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
        -nographic \
        -append "console=ttyAMA0"
    $ sudo chmod +x ./z_start_kernel.sh
    $ ./z_start_kernel.sh
    audio: Could not init 'oss' audio driver
    ...
    # fail because no 'rootfs'
    ```

    - build `rootfs`

    ```
    $ vi z_mkrootfs.sh
        #!/bin/bash

        sudo rm -rf rootfs
        sudo rm -rf tmpfs
        sudo rm -f a9rootfs.ext3

        ## create rootfs
        sudo mkdir rootfs

        ## copy busybox cmds to rootfs (Be careful the path of busybox)
        sudo cp -r busybox-1.27.2/_install/* rootfs/

        # copy the libraries of toolchain to rootfs
        sudo mkdir rootfs/lib
        sudo cp -P /usr/arm-linux-gnueabi/lib/* rootfs/lib

        ## create 4 tty devices.
        # ps. c= character device, 4= master device number
        #     1, 2, 3, 4 is sub device number
        sudo mkdir -p rootfs/dev
        sudo mknod rootfs/dev/tty1 c 4 1
        sudo mknod rootfs/dev/tty2 c 4 2
        sudo mknod rootfs/dev/tty3 c 4 3
        sudo mknod rootfs/dev/tty4 c 4 4

        ## make image
        dd if=/dev/zero of=a9rootfs.ext3 bs=1M count=32

        ## format to ext3 file system
        mkfs.ext3 a9rootfs.ext3

        ## copy data to image
        sudo mkdir tmpfs
        sudo mount -t ext3 a9rootfs.ext3 tmpfs/ -o loop
        sudo cp -r rootfs/* tmpfs/
        sudo umount tmpfs
    $ sudo chmod +x ./z_mkrootfs.sh
    $ ./z_mkrootfs.sh
    ```

        1. simple rootfs

        ```
        $ mkdir rootfs
        $ mkdir -pv {bin,sbin,etc,proc,sys,usr/{bin,sbin}}

        $ vim etc/inittab
            ::sysinit:/etc/init.d/rcS
            ::askfirst:/bin/ash
            ::ctrlaltdel:/sbin/reboot
            ::shutdown:/sbin/swapoff -a
            ::shutdown:/bin/umount -a -r
            ::restart:/sbin/init

        $ mkdir etc/init.d
        $ vim etc/init.d/rcS
            #!/bin/sh
            mount -t proc none /proc
            mount -t sys none /sys
            /bin/mount -n -t sysfs none /sys
            /bin/mount -t ramfs none /dev
            /sbin/mdev -s
        $ sudo chmod +x ./etc/init.d/rcS
        $ find . | cpio -o --format=newc > ./rootfs.img
        $ gzip -c rootfs.img > rootfs.img.gz
        ```

    - Debug on Qemu with GDB

        1. start GDB server

        ```
        $ vi ./z_run_gdb_server.sh
            #!/bin/bash -

            set -e

            ## GDB server
            sudo qemu-system-arm \
            -M vexpress-a9 \
            -m 512M \
            -kernel arch/arm/boot/zImage \
            -dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
            -nographic \
            -append "console=ttyAMA0" -s -S
        $ sudo chmod +x ./z_run_gdb_server.sh
        $ ./z_run_gdb_server.sh
        ```

        1. open the other terminal

        ```
        $ arm-none-eabi-gdb vmlinux
        GNU gdb (GNU Tools for Arm Embedded Processors 8-2019-q3-update) 8.3.0.20190703-git
        Copyright (C) 2019 Free Software Foundation, Inc.
        License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
        This is free software: you are free to change and redistribute it.
        There is NO WARRANTY, to the extent permitted by law.
        Type "show copying" and "show warranty" for details.
        This GDB was configured as "--host=x86_64-linux-gnu --target=arm-none-eabi".
        Type "show configuration" for configuration details.
        For bug reporting instructions, please see:
        <http://www.gnu.org/software/gdb/bugs/>.
        Find the GDB manual and other documentation resources online at:
            <http://www.gnu.org/software/gdb/documentation/>.

        For help, type "help".
        Type "apropos word" to search for commands related to "word".

        (gdb) target remote:1234
        Remote debugging using :1234
        (gdb)

        ```

+ buildroot

    - download

    ```
    $ wget https://buildroot.org/downloads/buildroot-2020.02.tar.gz
    $ tar -xzf buildroot-2020.02.tar.gz
    ```

    - compile

    ```shell
    $ vi ./z_run_buildroot.sh
        #!/bin/bash -

        set -e

        make qemu_arm_vexpress_defconfig
        make

        make COMPILED_SOURCE=1 cscope

    $ sudo chmod +x ./z_run_buildroot.sh
    $ ./z_run_buildroot.sh
    ```

        1. images
            > `output/images`
            > + rootfs.ext2
            > + vexpress-v2p-ca9.dtb
            > + zImage

        1. target rootfs
            > `output/target`

    - run kernel on QEMU

    ```
    $ vi z_start_kernel.sh
        #!/bin/bash

        ## only kernel and rootfs and start GDB server
        sudo qemu-system-arm \
        -M vexpress-a9 -cpu cortex-a9 -smp 4 -m 256M \
        -kernel ./output/images/zImage \
        -serial stdio \
        -sd ./output/images/rootfs.ext2 \
        -dtb ./output/images/vexpress-v2p-ca9.dtb \
        -nographic \
        -net nic,model=lan9118 \
        -net user \
        -append "root=/dev/mmcblk0 console=ttyAMA0" \
        -gdb tcp::1234 \
        -S

        # -S: qemu to freeze CPU when start
        # -s: default GDB port 1234 (the same with '-gdb tcp::1234')
    $ sudo chmod +x ./z_start_kernel.sh
    $ ./z_start_kernel.sh
    ```

        1. open the other terminal

        ```
        $ arm-none-eabi-gdb -ex "file ./output/build/linux-4.19.91/vmlinux" -ex "target remote:1234"
        GNU gdb (GNU Tools for Arm Embedded Processors 8-2019-q3-update) 8.3.0.20190703-git
        Copyright (C) 2019 Free Software Foundation, Inc.
        License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
        This is free software: you are free to change and redistribute it.
        There is NO WARRANTY, to the extent permitted by law.
        Type "show copying" and "show warranty" for details.
        This GDB was configured as "--host=x86_64-linux-gnu --target=arm-none-eabi".
        Type "show configuration" for configuration details.
        For bug reporting instructions, please see:
        <http://www.gnu.org/software/gdb/bugs/>.
        Find the GDB manual and other documentation resources online at:
            <http://www.gnu.org/software/gdb/documentation/>.

        For help, type "help".
        Type "apropos word" to search for commands related to "word".

        Reading symbols from ./output/build/linux-4.19.91/vmlinux...
        Remote debugging using :1234
        0x60000000 in ?? ()
        (gdb) b start_kernel
        Breakpoint 1 at 0x809009cc: file init/main.c, line 531.
        (gdb) c
        Continuing.

        Breakpoint 1, start_kernel () at init/main.c:531
        531	{
        (gdb)

        ```

+ leave Qemu
    > ctrl-A + X

    1. the other terminal

    ```
    $ killall qemu-system-arm
    ```

## kernel image

+ `make Image`
    > 普通的 kernel image 文件 (一般約為 4MB)

+ `make zImage`
    > 壓縮過的 kernel image 文件 (一般約不到 2MB)

+ `make uImage LOADADDR=0x80008000`
    > 是 uboot 專用的 image 文件, 它是在 zImage 之前加上一個長度為 64-bytes 的 header,
    說明這個 kernel image 的**版本**, **加載位置**, **生成時間**, **大小**等信息; 其 64-bytes 之後與 zImage 沒區別.
    換句話說, 如果直接從 uImage 的 0x40 位置開始執行, 那麼 zImage 和 uImage 沒有任何區別.

    >> 因為 uboot 在用 `bootm` 命令引導內核的時候, `bootm` 需要讀取一個 64-bytes 的文件頭,
    來獲取這個 kernel image 所針對的 **CPU 體系結構**, **OS**, **加載到內存中的位置**,
    **在內存中入口點的位置**以及**映像名**等等信息.
    這樣 `bootm`才能為 OS 設置好啟動環境, 並跳入內核映像的入口點.
    而 `mkimage` 就是添加這個文件頭的專用工具

    - `LOADADDR`
        > 是 kernel 的啟動地址(注意, 這不是真正的kernel運行地址),
        uBoot 會將 kernel 拷貝到此地址後(實際中也可能不拷貝)執行.

+ `rootfs`

    - Ramdisk (最小文件系統) insert to kernel

        ```
        # memuconfig
        General setup
            --> Initial RAM filesystem and RAM disk (initramfs/initrd) support
                --> type '/home/xxx/raminitfs' # 準備好的 rootfs image 路徑
        ```

    - manually create rootfs

        ```
        $ dd if=/dev/zero of=rootfs bs=1M count=5
        $ losetup -f                            # 找一個空的 loop 設備
        $ sudo losetup /dev/loop0 rootfs        # 映射 image 到 loop 設備上
        $ sudo partprobe /dev/loop0
        $ sudo mkfs.ext2 -m 0 /dev/loop0
        $ mkdir tmp_rootfs
        $ sudo mount -t ext2 /dev/loop0 tmp_rootfs
        $ sudo cp -raf initramfs/* tmp_rootfs
        $ sudo umount tmp_rootfs; rm -rf tmp_rootfs
        $ gzip -v9 rootfs
        $ mkimage -n 'YOUR_MARK ext2 uboot ramdisk' -A arm -O linux -T ramdisk -C gzip -d rootfs.gz ramdisk.img
        ```

## tftp in uboot

+ host side

    - TFTP Server

        1. install

            ```
            $ sudo apt-get install tftpd-hpa    # tftp server
            $ sudo apt-get install tftp-hpa     # tftp client, for test
            ```

        1. 配置TFTP Server

            ```
            $ mkdir -p /home/xxx/tftpboot       # xxx為你的用戶名
            $ chmod 777 /home/xxx/tftpboot
            $ sudo vim /etc/default/tftpd-hpa
                TFTP_USERNAME="tftp"
                TFTP_DIRECTORY="/home/xxx/tftpboot"
                TFTP_ADDRESS="0.0.0.0:69
                TFTP_OPTIONS="-l -c -s"
            ```

            > + 修改 `TFTP_DIRECTORY` 為 TFTP_Server 服務目錄, 該目錄最好具有可讀可寫權限
            > + 修改 `TFTP_ADDRESS` 為 0.0.0.0:69, 表示所有 IP 源都可以訪問
            > + 修改 `TFTP_OPTIONS` 為 `-l -c -s`. 其中
            >> `-l`: 以 standalone/listen 模式啟動 TFTP服務, 而不是從 xinetd 啟動

            >> `-c`: 可創建新文件. 默認情況下 TFTP 只允許覆蓋原有文件而不能創建新文件

            >> `-s`: 改變TFTP啟動的根目錄, 加了`-s`後, 客戶端使用 TFTP 時,
            不再需要輸入指定目錄, 填寫文件的文件路徑, 而是使用配置文件中寫好的目錄.

        1. 重啟 TFTP Server

            ```
            $ mkdir /home/xxx/tftpboot
            $ sudo service tftpd-hpd restar

            # enter tftp control
            $ tftp 127.0.0.1
            tftp>
            ```

+ target device side (uboot console)

    - configure uboot

        ```
        => setenv ipaddr 192.168.1.20       # 設置開發板的本地IP
        => setenv serverip 192.168.1.103    # 設置 tftp server 的 IP, 也就是你存放 kernel 之類的文件的 tftp 服務器地址
        ```

    - download file

        ```
        => tftp c0008000 zImage
        => erase 0x680000 +0x120000
        => cp.b c0008000 0x680000 0x120000

        # c0008000 是下載開發板裡 memory 地址,
        # zImage 是需要下載的文件名稱,
        # 0x680000 是 kernel 的起始位置,
        # 0x120000 是 kernel 的分區大小.
        ```

