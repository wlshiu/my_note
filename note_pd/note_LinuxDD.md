Linux Device Driver with (Qemu)
---

# Build-up qemu environment

> on lubuntu 22.04.4 LTS

+ toolchain

    - bare-metal
        > + [gcc-arm-10.3-2021.07-x86_64-arm-none-eabi](https://developer.arm.com/-/media/files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-arm-none-eabi.tar.xz?rev=325890dc39394ec49a112e5a661f6497&revision=325890dc-3939-4ec4-9a11-2e5a661f6497&hash=A4E88F4944E90A49F13A07F7C8F2A1D2)
        > + [gcc-arm-10.3-2021.07-x86_64-aarch64-none-elf](https://developer.arm.com/-/media/files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-elf.tar.xz?rev=9d9808a2d2194b1283d6a74b40d46ada&revision=9d9808a2-d219-4b12-83d6-a74b40d46ada&hash=D0972BEEF0AB458042B15D029FAEBC59)

    - GNU/Linux
        > + [arm-linux-gnueabi](https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/arm-linux-gnueabi/)
        > + [gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu](https://developer.arm.com/-/media/files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz?rev=1cb9c51b94f54940bdcccd791451cec3&revision=1cb9c51b-94f5-4940-bdcc-cd791451cec3&hash=448E26250A9F882931F13D985ADA554B)
        > + `$ sudo apt install gcc-arm-linux-gnueabihf`

+ environment varables

    - arm
        1. environment varables

            ```
            $ vi Config_ARM.env
                export ARCH=arm
                export CROSS_COMPILE=arm-linux-gnueabi-
            $ source Config_ARM.env
            ```

    - arm64

        1. environment varables

            ```
            $ vi Config_ARM64.env
                export ARCH=arm64
                export CROSS_COMPILE=aarch64-none-linux-gnu-
            $ source Config_ARM64.env
            ```


## busybox

> use `busybox-1.32.1`

+ Configuration with kconfig

    - Busybox use static lib

        ```
        Settings  --->
            --- Build Options
            [*] Build static binary (no shared libs)

        ```

+ Build busybox

    ```
    $ vi ./z_busybox_build.sh

        #!/bin/bash

        set -e

        out=setting.env

        echo "export ARCH=arm64" > ${out}
        echo "export CROSS_COMPILE=aarch64-none-linux-gnu-" >> ${out}

        # echo "export ARCH=arm" > ${out}
        # echo "export CROSS_COMPILE=arm-linux-gnueabi-" >> ${out}

        source ${out}
        make menuconfig
        make install  # install to <busybox_root>/_install

    $ chmod +x ./z_busybox_build.sh
    ```

+ The default directory architecture of busybox of rootfs

    ```
    # default prefix: ./_install
    $ make install
    $ tree -L 1 ./
    ./
    ├── bin
    ├── linuxrc -> bin/busybox
    ├── sbin
    └── usr
    ```

### Create root file-system (rootfs)

+ Relation of rootfs and linux kernel
    > `rootfs` is the first mounted file-system of kernel
    and it is necessary when linux kernel execution

    - linux kernel 支援 initramfs 與 initrd 的 rootfs
        > + `initramfs`: Embed `rootfs` to kernel image
        > + `initrd`   : Create **ramdisk** for `rootfs`
        >> 使用 ramdisk 比 Initramfs 靈活些, 不需要每次都去編譯 kernel; 不過在 Qemu 中, 都支援透過`-initrd`指定檔案 img

        ```
        $ cd <linux_kernel_src>
        $ make menuconfig
            General setup --->
                [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support
        ```

        1. `initramfs`
            > linux kernel 只認 `cpio format`的initramfs檔案

        1. `initrd`
            > 可支援 `cpio format`, 也可以是傳統的 img (e.g. ext4)

            > 如果 RAM disk size 和製作的 ramdisk 不匹配,
            則啟動時可能會出現 **kernel panic**, 提示ramdisk格式不正確, 掛載不上 ramdisk
            > ```
            > Device Drivers  --->
            >    [*] Block devices --->
            >        <*>   RAM block device support
            >        (4096)  Default RAM disk size (kbytes) (NEW)
            > ```

+ Creat the simply rootfs

    - Setup the directory architecture of rootfs

        ```
        $ cd <busybox_root>/_install
        $ mkdir -pv {sbin,dev,etc/init.d,usr/{bin,sbin}}

        $ cd dev/
        $ sudo mknod console c 5 1
        $ sudo mknod null c 1 3

        $ cd ../etc/init.d/
        $ vi rcS
            #!/bin/sh
            mkdir –p /proc
            mkdir –p /tmp
            mkdir -p /sys
            mkdir –p /mnt
            /bin/mount -a
            mkdir -p /dev/pts
            mount -t devpts devpts /dev/pts
            echo /sbin/mdev > /proc/sys/kernel/hotplug
            mdev –s
            echo "===== kernel boot ==="
        $ chmod 777 rcS

        $ cd ../../etc/
        $ vi fstab
            proc /proc proc defaults 0 0
            tmpfs /tmp tmpfs defaults 0 0
            sysfs /sys sysfs defaults 0 0
            tmpfs /dev tmpfs defaults 0 0
            debugfs /sys/kernel/debug debugfs defaults 0 0

        $ vi inittab
            ::sysinit:/etc/init.d/rcS
            ::respawn:-/bin/sh
            ::askfirst:-/bin/sh
            ::ctrlaltdel:/bin/umount -a –r

        $ tree ./
            .
            ├── bin
            ├── dev
            │   ├── console
            │   └── null
            ├── etc
            │   ├── fstab
            │   ├── init.d
            │   │   └── rcS
            │   └── inittab
            ├── linuxrc -> bin/busybox
            ├── mnt
            ├── rootfs.cpio     <--- keep cpio file in rootfs
            ├── sbin
            └── usr
                ├── bin
                └── sbin
        ```

        1. copy the toolcahin lib (`*so`) to rootfs (for App usage)

            ```
            $ cd <busybox_dir>/_install/
            $ mkdir lib && cd lib
            $ cp <toolchain_gcc_..._arm-linux-gnueabi>/lib/*.so* -a .
            ```

    - Create cpio format file

        ```
        $ cd <busybox_dir>/_install/
        $ find . | cpio -o -H newc > rootfs.cpio    # rootfs.cpio MUST be in rootfs
        $ cd ..
        $ gzip -c rootfs.cpio > rootfs.cpio.gz
        ```

    - Create ext4 img file

        ```
        $ qemu-img create rootfs.img 4m
            or
        $ dd if=/dev/zero of=rootfs.img bs=1M count=4   # kernel configure 4MB ramdisk

        $ mkfs.ext4 rootfs.img
        $ mkdir rootfs_tmp
        $ sudo mount rootfs.img rootfs_tmp
        $ sudo cp -rf <busybox_dir>/_install/*  rootfs_tmp
        $ sudo umount rootfs_tmp
        ```


+ Creat the fully directory architecture of rootfs

    ```
    $ cd <busybox_dir>/_install
    $ mkdir -p dev etc home lib mnt proc root sys tmp var
    ```

    > + `/bin` : 系統管理員和使用者皆可使用的指令
    > + `/sbin`: 系統管理員使用的系統指令
    > + `/dev` : 儲存特殊檔案或裝置檔案; 裝置兩種類型: Character-device, Block-device
    > + `/etc` : 系統設定檔
    > + `/home`: 普通使用者目錄
    > + `/root`: root使用者目錄
    > + `/lib` : 為系統啟動或根檔案上的應用程式(bin, sbin, etc.)提供共用程式庫, 以及為核心提供核心模組
    > + `/mnt` : 暫時掛載點
    > + `/tmp` : 暫存檔儲存目錄
    > + `/usr` : usr hierarchy, 全域共享的唯讀資料路徑
    > + `/var` : 儲存常發生變化的資料目錄: cache, log, etc.
    > + `/proc`: 基於記憶體的虛擬檔案系統, 用於為核心及進程儲存其相關信息
    > + `/sys` : sysfs虛擬檔案系統提供了一種比proc更為理想的存取核心資料的途徑: 其主要作用在於, 為管理linux設備, 提供一種統一模型的接口



## linux kernel

> use `linux-4.19.319`

+ Configure kernel with kconfig

    - arm

        ```
        $ make vexpress_defconfig
        $ make menuconfig
            General setup -->
                [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support
                ()    Initramfs source file(s)
            System Type -->
                [ ] Enable the L2x0 outer cache controller
                ps. Disable this option (or QEMU works fail)
            Kernel Features -->
                [*] Use the ARM EABI to compile the kernel
                ps. Enable this option

            ...
            [ ] Networking support  --->
                Device Drivers  --->
            ps. disable some modules for compiling performance


            kernel hacking --->
                printk and dmesg options  --->
                    [*] Show timing information on printk
                Compile-time checks and compiler options --->
                    [*] compile the kernel with debug info
                    [*]   Provide GDB scripts for kernel debugging
                    ps. Enable the debug info of kernel
        ```

        1. if use rootfs with `initrd`

            ```
            Device Drivers  --->
                [*] Block devices --->
                    <*>   RAM block device support
                    (4096)  Default RAM disk size (kbytes) (NEW)
            ```


+ Build kernel

    - arm

        ```
        $ vi ./z_build_kernel.sh
            #!/bin/bash -

            set -e

            out=setting.env

            # echo "export ARCH=arm64" > ${out}
            # echo "export CROSS_COMPILE=aarch64-none-elf-" >> ${out}
            # echo "export SRCARCH=arm64" >> ${out}

            echo "export ARCH=arm" > ${out}
            echo "export CROSS_COMPILE=arm-none-eabi-" >> ${out}
            echo "export SRCARCH=arm" >> ${out}

            source ${out}
            make vexpress_defconfig
            make menuconfig
            make

        $ sudo chmod +x ./z_build_kernel.sh
        ```

+ Run kernel with Qemu
    > level Qemu, `Ctrl + a` then `x`

    - arm

        ```
        $ vi ./z_kernel_qemu.sh

            #!/bin/bash

            sudo qemu-system-arm \
                -M vexpress-a9 \
                -m 128M \
                -kernel arch/arm/boot/zImage \
                -dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
                -nographic \
                -append "console=ttyAMA0"

        $ chmod +x ./z_kernel_qemu.sh
        ```

    - arm64 (?)

        ```
        $ vi ./z_kernel_arm64_qemu.sh
            qemu-system-aarch64 \
                -machine virt,virtualization=true,gic-version=3 \
                -nographic \
                -m size=512M \
                -cpu cortex-a72 \
                -smp 2 \
                -kernel Image \
                -drive format=raw,file=rootfs.img \
                -append "root=/dev/vda rw"

        $ chmod +x ./z_kernel_arm64_qemu.sh
        ```

    - No rootfs => kernel panic

        ```
        ...
        ---[ end Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0) ]---
        $
        ```

+ Attach rootfs to kernel and Run kernel with Qemu

    - Run kernel with Qemu

        ```
        ...
        /etc/init.d/rcS: line 9: can't create /proc/sys/kernel/hotplug: nonexistent directory
        BusyBox v1.32.1 (2025-12-31 15:42:52 CST) multi-call binary.

        Usage: mdev [-s] | [-df]

        mdev -s is to be run during boot to scan /sys and populate /dev.
        mdev -d[f]: daemon, listen on netlink.
                -f: stay in foreground.

        Bare mdev is a kernel hotplug helper. To activate it:
                echo /sbin/mdev >/proc/sys/kernel/hotplug

        It uses /etc/mdev.conf with lines
                [-][ENV=regex;]...DEVNAME UID:GID PERM [>|=PATH]|[!] [@|$|*PROG]
        where DEVNAME is device name regex, @major,minor[-minor2], or
        environment variable regex. A common use of the latter is
        to load modules for hotplugged devices:
                $MODALIAS=.* 0:0 660 @modprobe "$MODALIAS"

        If /dev/mdev.seq file exists, mdev will wait for its value
        to match $SEQNUM variable. This prevents plug/unplug races.
        To activate this feature, create empty /dev/mdev.seq at boot.

        If /dev/mdev.log file exists, debug log will be appended to it.

        Please press Enter to activate this console.
        ```

        1. `initramfs` boot

            ```
            $ cd <linux_kernel_src>
            $ cp <busybox_dir>/rootfs.cpio.gz ./

            $ qemu-system-arm \
                -M vexpress-a9 \
                -m 256M \
                -kernel arch/arm/boot/zImage \
                -dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
                -initrd rootfs.cpio.gz \
                -nographic \
                -append "rdinit=/linuxrc console=ttyAMA0"
            ```

        1. `initrd` boot

            ```
            $ cd <linux_kernel_src>
            $ cp <busybox_dir>/rootfs.img ./

            $ qemu-system-arm \
                -M vexpress-a9 \
                -m 256M \
                -kernel arch/arm/boot/zImage \
                -dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
                -initrd rootfs.img \
                -nographic \
                -append "root=/dev/ram0 ramdisk_size=4096 console=ttyAMA0"  # set root location
            ```

# Device Driver



# Reference

+ [Linux 核心設計: 開發與除錯環境 - HackMD](https://hackmd.io/@RinHizakura/SJ8GXUPJ6)
+ [Running 64- and 32-bit RISC-V Linux on QEMU — RISC-V - Getting Started Guide](https://risc-v-getting-started-guide.readthedocs.io/en/latest/linux-qemu.html)
+ [qemu搭建arm64 linux kernel环境 - 知乎](https://zhuanlan.zhihu.com/p/667525514)
+ [*QEMU搭建Linux实验环境 - 知乎](https://zhuanlan.zhihu.com/p/612120655)

