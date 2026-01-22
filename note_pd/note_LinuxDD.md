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
        >> download [toolchain arm-linux-gnueabi](https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/arm-linux-gnueabi/)

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

> Use `minirootfs` of `my_zb_test` to auto-create
>> copy the customer directories or files to `minirootfs/skel`

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
        $ mkdir -pv {sbin,dev,etc/init.d,usr/{bin,sbin,lib},proc}

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

    - Add lib for user application
        > copy libs (`*.so`)from toolchain

        ```
        $ cd  .../gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi/arm-linux-gnueabi/libc
        $ sudo mkdir -p .../busybox/_install/lib
        $ sudo cp *so* .../busybox/_install/lib
        ```

+ Creat the fully directory architecture of rootfs (?)

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

        1. Disable floating pointer

            ```
            > Floating point emulation
                    *** At least one emulation must be selected ***
                [ ] VFP-format floating point maths
            ```
        1. Kernel debug feature

            ```
             > Kernel hacking > Compile-time checks and compiler options
                [*] Compile the kernel with debug info
                [ ]   Reduce debugging information
                [ ]   Produce split debuginfo in .dwo files
                [*]   Generate dwarf4 debuginfo
                [*]   Provide GDB scripts for kernel debugging
                [*] Enable __must_check logic
                (1024) Warn for stack frames larger than (needs gcc 4.4)
                [ ] Strip assembler-generated symbols during link
                [*] Generate readable assembler code

             > Kernel hacking
                [*] KGDB: kernel debugger  --->
            ```

        1. Enable NFS feature

            ```
            > Networking support > Networking options
                [*] TCP/IP networking
                [ ]   IP: multicasting
                [ ]   IP: advanced router
                [*]   IP: kernel level autoconfiguration
                [*]     IP: DHCP support
                [*]     IP: BOOTP support
            ```

        1. Enable NFS version

            ```
            > File systems > Network File Systems
                --- Network File Systems
                <*>   NFS client support
                <*>     NFS client support for NFS version 2
                <*>     NFS client support for NFS version 3
                [*]       NFS client support for the NFSv3 ACL protocol extension
                <*>     NFS client support for NFS version 4
                [ ]     Provide swap over NFS support
                [*]   NFS client support for NFSv4.1
                [*]     NFS client support for NFSv4.2
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

        1. boot from SD (?)

            ```
            $ qemu-system-arm               \
                -M vexpress-a9              \
                -m 256M                     \
                -kernel arch/arm/boot/zImage \
                -dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
                -nographic                  \
                -append "root=/dev/mmcblk0 rw console=ttyAMA0" \
                -sd rootfs.ext4
            ```

    - Debug kernel with Qemu

        1. qemu GDB-Server

        1. GDB client


+ Attach rootfs to kernel with NFS (Network File System)

    - Configure NFS server on Host side
        > lunbuntu 22.04 with VirtualBox v7.0

        1. dependency

            ```
            $ sudo apt install nfs-kernel-server
            ```

        1. Configure NFS server

            ```
            $ mdkir -p /home/nfs
            $ sudo chmod 777 /home/nfs
            $ sudo vi /etc/exports

                # add
                /home/nfs *(rw,sync,no_subtree_check,all_squash,insecure,anonuid=1000,anongid=1000)

            $ sudo vi /etc/default/nfs-kernel-server
                # add to support NFS v2/v3/v4
                RPCSVCGSSDOPTS="--nfs-version 2,3,4 --debug --syslog"

            ```

            ```
            ### start NFS server
            $ sudo /etc/init.d/rpcbind restart
            $ sudo /etc/init.d/nfs-kernel-server restart
            $ sudo exportfs
                /home/nfs       <world>

            ### check NFS configuration
            $ sudo showmount -e
                Export list for wl-virtualbox:
                /home/nfs *
            ```

            ```
            $ sudo mount -t nfs 127.0.1.1:/home/nfs /mnt    # 在 local 臨時掛載測試
            $ df -h | grep nfs                              # 查看掛載結果, 存在就表示正常
                127.0.1.1:/home/nfs  196G   15G  172G   8% /mnt
            $ sudo umount /mnt                              # 卸載
            ```
    - Configure NFS server on Guest side
        > base on `kernel 4.19.319` with `busybox v1.36.1` (盡量維持 defconfig, 尚未了解 NFS 需要那些 features)
        >> Use **dhcp** to get the ip-address from host dhcp server

        1. busbox configuration
            > Enable `udhcpc` cmd
            >> defconfig will involve `udhcpc` cmd


        1. kernel configuration

            > + Enable NFS version supportment
            >
            > ```
            > File System -> Network File Systems -> NFS client support for NFS version 4
            >
            > --- Network File Systems
            >  <*>   NFS client support
            >  <*>     NFS client support for NFS version 2
            >  <*>     NFS client support for NFS version 3
            >  [ ]       NFS client support for the NFSv3 ACL protocol extension
            >  <*>     NFS client support for NFS version 4
            >  [*]     Provide swap over NFS support
            >  [*]   NFS client support for NFSv4.1
            >  [*]     NFS client support for NFSv4.2
            >  (kernel.org) NFSv4.1 Implementation ID Domain (NEW)
            >  [*]     NFSv4.1 client support for migration
            >  [*]   Root file system on NFS
            > ```

            > + Enable DHCP
            > ```
            > > Networking support > Networking options
            >     [*] TCP/IP networking
            >     [ ]   IP: multicasting
            >     [ ]   IP: advanced router
            >     [*]   IP: kernel level autoconfiguration
            >     [*]     IP: DHCP support
            >     [*]
            > ```

        1. use `minirootfs` to generate rootfs
            > udhcpc will execute `usr/share/udhcpc/default.script`

            ```
            $ cd .../minirootfs/skel/
            $ mkdir -p usr/share/udhcpc
            $ cd usr/share/udhcpc
            $ cp <busybox_src>/examples/udhcp/simple.script ./default.script
            ```

        1. execute qemu

            ```
            $ qemu-system-arm \
                -M vexpress-a9 \
                -m 128M \
                -kernel arch/arm/boot/zImage \
                -dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
                -initrd initramfs.cpio.gz \
                -nographic \
                -append "rdinit=/linuxrc console=ttyAMA0"

            ```

        1. Setup manually kernel (Guest-OS)
            > It should add script to `/etc/init.d/rcS`

            ```
            / # ifconfig
                eth0      Link encap:Ethernet  HWaddr 52:54:00:12:34:56
                          inet addr:192.168.1.3  Bcast:192.168.1.255  Mask:255.255.255.0
                          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
                            ...

                lo        Link encap:Local Loopback
                          inet addr:127.0.0.1  Mask:255.0.0.0
                          UP LOOPBACK RUNNING  MTU:65536  Metric:1
                          ...

            / # ifconfig eth0 0.0.0.0 up
            / # ifconfig
                eth0      Link encap:Ethernet  HWaddr 52:54:00:12:34:56
                          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
                          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
                          ...

                lo        Link encap:Local Loopback
                          inet addr:127.0.0.1  Mask:255.0.0.0
                          UP LOOPBACK RUNNING  MTU:65536  Metric:1
                          ...
            / # udhcpc -i eth0
                udhcpc: started, v1.36.1
                Clearing IP addresses on eth0, upping it
                udhcpc: broadcasting discover
                udhcpc: broadcasting select for 10.0.2.15, server 10.0.2.2
                udhcpc: lease of 10.0.2.15 obtained from 10.0.2.2, lease time 86400
                Setting IP address 10.0.2.15 on eth0
                Deleting routers
                route: SIOCDELRT: No such process
                Adding router 10.0.2.2
                Recreating /etc/resolv.conf
                 Adding DNS server 10.0.2.3
            / # ifconfig
                eth0      Link encap:Ethernet  HWaddr 52:54:00:12:34:56
                          inet addr:10.0.2.15  Bcast:10.0.2.255  Mask:255.255.255.0
                          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
                          ...

                lo        Link encap:Local Loopback
                          inet addr:127.0.0.1  Mask:255.0.0.0
                          UP LOOPBACK RUNNING  MTU:65536  Metric:1
                          ...

            ```

        1. Check Guest-OS links with Host-OS

            ```
            #
            ## Check network connects successfully
            ## Host ip: 192.168.56.101
            #
            / # ping 192.168.56.101
                PING 192.168.56.101 (192.168.56.101): 56 data bytes
                64 bytes from 192.168.56.101: seq=0 ttl=255 time=9.899 ms
                64 bytes from 192.168.56.101: seq=1 ttl=255 time=9.365 ms
                ^C
                --- 192.168.56.101 ping statistics ---
            ```

        1. Mount the NFS server of Host-OS
            > hook remote directory to local `/mnt`

            ```
            / # mount -t nfs -o nolock 192.168.56.101:/home/nfs /mnt
            / # ls /mnt
            ```


    - Reference
        1. [使用Qemu通过NFS挂载共享文件夹调试Linux内核-开发者社区-阿里云](https://developer.aliyun.com/article/1599043)
        1. [Qemu搭建ARM vexpress开发环境(三)----NFS网络根文件系统 - 简书](https://www.jianshu.com/p/cf46f7225db6)

# Device Driver

Use `dmesg` command to display the log message

## My device driver

### Basic methods of a device module
> 建立一個模組, 只需提供 `init` 跟 `exit` 兩個 functions 就可以了;
>> 將 `init`/`exit` 註冊成, 這個這個模組插入的初始化, 與卸載的清理函數

+ Create files

    ```
    $ ls
    hello.c  Makefile
    ```

    - source c code

        ```
        #include <linux/module.h>
        #include <linux/kernel.h>
        #include <linux/init.h>

        static int __init hello_drv_init(void)
        {
            pr_info("Initializing HELLO module.\n");
            return 0;
        }

        static void __exit hello_drv_exit(void)
        {
            pr_info("Unloading HELLO module.\n");
            return;
        }

        module_init(hello_drv_init);
        module_exit(hello_drv_exit);

        MODULE_LICENSE("GPL");
        ```

    - makefile for a device module

        ```
        # Set target architecture and cross-compiler prefix
        ARCH ?= arm
        CROSS_COMPILE ?= arm-linux-gnueabi-

        # ARCH ?= arm64
        # CROSS_COMPILE ?= aarch64-none-linux-gnu-

        #
        # Path to the kernel source directory
        # Replace with the actual path to your kernel source
        #
        KERNEL_DIR := $HOME/linux-4.19.319/

        obj-m += hello.o

        all:
            $(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KERNEL_DIR) M=$(PWD) modules

        clean:
            $(MAKE) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -C $(KERNEL_DIR) M=$(PWD) clean

        ```

+ Compile a device module
    > The `.ko` file is the target to insert to kernel

    ```
    $ make
    $ ls -al
        total 208
        drwxrwxr-x 3  15:26 .
        drwxrwxr-x 4  14:19 ..
        -rw-r--r-- 1  15:09 hello.c
        -rw-rw-r-- 1  15:26 hello.ko
        -rw-rw-r-- 1  15:26 .hello.ko.cmd
        -rw-rw-r-- 1  15:26 hello.mod.c
        -rw-rw-r-- 1  15:26 hello.mod.o
        -rw-rw-r-- 1  15:26 .hello.mod.o.cmd
        -rw-rw-r-- 1  15:26 hello.o
        -rw-rw-r-- 1  15:26 .hello.o.cmd
        -rw-r--r-- 1  15:07 Makefile
        -rw-rw-r-- 1  15:26 modules.order
        -rw-rw-r-- 1  15:26 Module.symvers
        drwxrwxr-x 2  15:26 .tmp_versions
    ```


+ Put `.ko` file to `rootfs`

    ```
    $ sudo mount rootfs.img rootfs_tmp      # as above ext4 img
    $ cd rootfs_tmp
    $ sudo mkdir -p ./usr/lib/modules
    $ sudo cp -f .../hello.ko ./usr/lib/modules
    $ sudo umount rootfs_tmp
    ```

+ Insert/Remove a device module to/form kernel (with Qemu)

    ```
    /usr/lib/modules # insmod ./hello.ko
        [  139.600608] hello: loading out-of-tree module taints kernel.
        [  139.631224] Initializing HELLO module.
    /usr/lib/modules #
    /usr/lib/modules # rmmod hello
        [  299.409253] Unloading HELLO module.

    ```

### Advance methods of a device module

+ Device type

    - Character Device
        > 當成 A stream (sequential access) of bytes

        1. 又叫做 `raw device`, 只要是直接存取硬體的裝置, 都可歸到此類
            > `disk` 也可能屬於這種 character device, 只是他們的 raw 是一個 sector

        1. `raw device` 直接寫入寫出, 故 **DMA 是直接把資料搬到 user-space buffer**,
            > 所以要讓 user-space buffer 一直在 ram 裡面, 並且要注意 device 要有能對 buffer 寫入的權限

        1. 另外對 `raw device` 的 `poll/select` 沒意義, 因為沒有中間的 kernel buffer,
            只要有資料自然會發起 interrupt, 所以 `select/poll` 在 `raw device` 使用 `selture()` 將永遠回傳 true


    - Block Device
        > 一次拿一個 block, 像 Storage device (e.g. HDD, SSD, Flash, ...etc.)

        1. 中間有 kernel buffer (linux 叫做 page-cache) 的存取, 速度比較快

    - Network Devices
        > 網路相關的裝置

    - MTD Devices
        > 直接存取 nand interface,
        >> 但通常 flash 會透過 Flash Translation Layer 模擬成 block devic

    - Loop Device
        > 將檔案當作 block device


+ An example of character-Device

    - Kernel space

        ```c
        #include <linux/module.h>
        #include <linux/kernel.h>
        #include <linux/init.h>
        #include <linux/fs.h>
        #include <linux/uaccess.h>

        #define HELLO_DEV_MAJOR     200
        #define HELLO_DEV_NAME      "hello_dev"

        static char g_kernel_buf[30] = {0};

        static int hello_dev_open(struct inode *inode, struct file *filp)
        {
            pr_info("[%s: %d]\n", __func__, __LINE__);
            return 0;
        }

        static int hello_dev_release(struct inode *inode, struct file *filp)
        {
            pr_info("[%s: %d]\n", __func__, __LINE__);
            return 0;
        }

        static ssize_t hello_dev_read(struct file *filp, char __user *buffer, size_t length, loff_t *offset)
        {
            int     ret = 0;

            pr_info("[%s: %d]\n", __func__, __LINE__);

            length = (sizeof(g_kernel_buf) < length) ? sizeof(g_kernel_buf) : length;

            ret = copy_to_user(buffer, g_kernel_buf, length);
            if( ret == 0 ) {
                pr_info("kernel send data: %s\n", g_kernel_buf);
            } else {
                /* error handle */
            }
            return length;

        }

        static ssize_t hello_dev_write(struct file *filp, const char __user *buffer, size_t length, loff_t *offset)
        {
            int     ret = 0;

            pr_info("[%s: %d]\n", __func__, __LINE__);

            length = (sizeof(g_kernel_buf) < length) ? sizeof(g_kernel_buf) : length;

            ret = copy_from_user(g_kernel_buf, buffer, length);
            if( ret == 0 ) {
                pr_info("kernel receive data: %s\n", g_kernel_buf);
            } else {
                /* error handle */
            }

            return length;
        }

        static struct file_operations   hello_dev_fops = {
            .owner   = THIS_MODULE,
            .open    = hello_dev_open,
            .release = hello_dev_release,
            .read    = hello_dev_read,
            .write   = hello_dev_write,
        };

        static int __init hello_drv_init(void)
        {
            int     ret = 0;

            pr_info("Initializing HELLO module.\n");

            ret = register_chrdev(HELLO_DEV_MAJOR, HELLO_DEV_NAME, &hello_dev_fops);
            if (ret < 0) {
                printk(KERN_INFO "HELLO init failed!\n");
            }
            return 0;
        }

        static void __exit hello_drv_exit(void)
        {
            pr_info("Unloading HELLO module.\n");
            unregister_chrdev(HELLO_DEV_MAJOR, HELLO_DEV_NAME);
            return;
        }

        module_init(hello_drv_init);
        module_exit(hello_drv_exit);

        MODULE_LICENSE("GPL");
        ```

    - User space
        > It should copy the libs from toolchain to rootfs...

        1. Create the c codes of App

            ```c
            #include <linux/module.h>
            #include <linux/kernel.h>
            #include <linux/init.h>
            #include <linux/fs.h>
            #include <linux/uaccess.h>

            #define HELLO_DEV_MAJOR     200
            #define HELLO_DEV_NAME      "hello_dev"

            static char g_kernel_buf[30] = {0};

            static int hello_dev_open(struct inode *inode, struct file *filp)
            {
                pr_info("[%s: %d]\n", __func__, __LINE__);
                return 0;
            }

            static int hello_dev_release(struct inode *inode, struct file *filp)
            {
                pr_info("[%s: %d]\n", __func__, __LINE__);
                return 0;
            }

            static ssize_t hello_dev_read(struct file *filp, char __user *buffer, size_t length, loff_t *offset)
            {
                int     ret = 0;

                pr_info("[%s: %d] len= %d\n", __func__, __LINE__, length);

                length = (sizeof(g_kernel_buf) < length) ? sizeof(g_kernel_buf) : length;

                ret = copy_to_user(buffer, g_kernel_buf, length);
                if( ret == 0 ) {
                    pr_info("kernel send data: %s\n", g_kernel_buf);
                } else {
                    /* error handle */
                }

                return 0;
            }

            static ssize_t hello_dev_write(struct file *filp, const char __user *buffer, size_t length, loff_t *offset)
            {
                int     ret = 0;

                pr_info("[%s: %d]\n", __func__, __LINE__);

                length = (sizeof(g_kernel_buf) < length) ? sizeof(g_kernel_buf) : length;

                ret = copy_from_user(g_kernel_buf, buffer, length);
                if( ret == 0 ) {
                    pr_info("kernel receive data: %s\n", g_kernel_buf);
                } else {
                    /* error handle */
                }

                return length;
            }

            static struct file_operations   hello_dev_fops = {
                .owner   = THIS_MODULE,
                .open    = hello_dev_open,
                .release = hello_dev_release,
                .read    = hello_dev_read,
                .write   = hello_dev_write,
            };

            static int __init hello_drv_init(void)
            {
                int     ret = 0;

                pr_info("Initializing HELLO module.\n");

                ret = register_chrdev(HELLO_DEV_MAJOR, HELLO_DEV_NAME, &hello_dev_fops);
                if (ret < 0) {
                    printk(KERN_INFO "HELLO init failed!\n");
                }
                return 0;
            }

            static void __exit hello_drv_exit(void)
            {
                pr_info("Unloading HELLO module.\n");
                unregister_chrdev(HELLO_DEV_MAJOR, HELLO_DEV_NAME);
                return;
            }

            module_init(hello_drv_init);
            module_exit(hello_drv_exit);

            MODULE_LICENSE("GPL");
            ```

        1. Create makefile for App layer of linux

            ```
            # Set target architecture and cross-compiler prefix
            ARCH := arm
            CROSS_COMPILE := arm-linux-gnueabi-

            # ARCH ?= arm64
            # CROSS_COMPILE ?= aarch64-none-linux-gnu-


            RED="\033[0;31m"
            GREEN="\033[0;32m"
            LIGHT_GREEN="\033[1;32m"
            YELLOW="\033[0;33m"
            LIGHT_YELLOW="\033[1;33m"
            GREY="\033[0;37m"
            BWHITE="\033[1;37m"
            MAGENTA="\033[1;35m"
            CYAN="\033[1;36m"
            NC="\033[0m"


            # target
            TARGET = test_char_dev
            OUT = out

            DEBUG = y
            OPT =
            ifeq ("$(D)","0")
                DEBUG = n
                OPT = -O2
            endif

            V ?= $(VERBOSE)
            ifeq ("$(V)","1")
                Q =
            else
                Q = @
            endif

            PLATFORM = $(shell uname -o)
            ifeq ("$(findstring Linux, $(PLATFORM))","Linux")
                ECHO = echo
                TUI = -tui
            else
                ECHO = echo -e
                TUI =
            endif

            export OUT Q DEBUG OPT ECHO TUI

            # Define the cross-compiler prefix
            CC = $(CROSS_COMPILE)gcc
            AS = $(CROSS_COMPILE)gcc -x assembler-with-cpp
            SZ = $(CROSS_COMPILE)size
            GDB= $(CROSS_COMPILE)gdb
            OBJCOPY = $(CROSS_COMPILE)objcopy
            OBJDUMP = $(CROSS_COMPILE)objdump

            # Project settings
            C_SOURCES = \
                test_char_dev.c

            CFLAGS = $(OPT) -Wall -fdata-sections -ffunction-sections -fno-common

            OBJECTS = $(addprefix $(OUT)/,$(notdir $(C_SOURCES:.c=.o)))
            vpath %.c $(sort $(dir $(C_SOURCES)))

            LDFLAGS = \
                -Wl,-gc-sections \
                -Wl,--check-sections \
                -Wl,--start-group \
                -lgcc -lm \
                -Wl,--end-group


            .PHONY: all clean

            all: $(OUT) $(OUT)/$(TARGET)

            $(OUT)/$(TARGET): $(OBJECTS)
                $(Q)$(CC) $(LDFLAGS) $^ -o $@
                @$(ECHO) $(GREEN)"\nSize $(OUT)/$(TARGET)" $(NC)
                $(Q)$(SZ) $@


            $(OUT)/%.o: %.c Makefile | $(OUT)
                @$(ECHO) "  CC $@"
                $(Q)$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(OUT)/$(notdir $(<:.c=.lst)) $< -o $@

            $(OUT):
                @mkdir -p $@

            clean:
                @$(ECHO) "  Remove $(OUT)\n"
                @rm -fr $(OUT)

            ```

    - Execute module

        ```
        / # insmod usr/lib/modules/hello.ko
            [   16.605207] hello: loading out-of-tree module taints kernel.
            [   16.617320] Initializing HELLO module.
        / # mknod /dev/hello c 200 0
        / # ls /dev/
            hello  pts
        ```

        1. `mknod`
            > create a node of device
            > + `c` means character-Device
            > + `200` is the Device MAJOR number which is defined in device driver (`HELLO_DEV_MAJOR in hello.c`)
            > + `0` is the the Device Sub-MAJOR number which is defined in device driver (`hello.c`)

        1. Read from device

            ```
            / # cat /dev/hello
                [   81.026688] [hello_dev_open: 14]
                [   81.031322] [hello_dev_read: 28] len= 4096
                [   81.032852] kernel send data: 111
                [   81.032852]
                [   81.033813] [hello_dev_release: 20]
            ```

        1. Write to device

            ```
            / # echo "hiiii~" > /dev/hello
                [   70.220697] [hello_dev_open: 14]
                [   70.222468] [hello_dev_write: 46]
                [   70.222668] kernel receive data: hiiii~
                [   70.222668]
                [   70.222863] [hello_dev_release: 20]
            ```

        1. execute `test_char_dev` on user-space

            ```
            / # test_char_dev /dev/hello
                @ Open device
                [hello_dev_open: 14]
                @ Read data
                [hello_dev_read: 28] len= 50
                kernel send data:
                @ Write data
                [hello_dev_write: 46]
                kernel receive data:
                @ Close device
                [hello_dev_release: 20]
            / #
            ```

## Debug device driver



## [Kernel-Module](note_kernel_module.md)

# Reference

+ [Linux 核心設計: 開發與除錯環境 - HackMD](https://hackmd.io/@RinHizakura/SJ8GXUPJ6)
+ [Running 64- and 32-bit RISC-V Linux on QEMU — RISC-V - Getting Started Guide](https://risc-v-getting-started-guide.readthedocs.io/en/latest/linux-qemu.html)
+ [qemu搭建arm64 linux kernel环境 - 知乎](https://zhuanlan.zhihu.com/p/667525514)
+ [*QEMU搭建Linux实验环境 - 知乎](https://zhuanlan.zhihu.com/p/612120655)
+ [iT 邦幫忙:Day 9：暖身運動 - 媽！我在核心裡面了！第一個核心模組](https://ithelp.ithome.com.tw/m/articles/10243519)
+ 正點原子【第四期】手把手教你學 Linux之驅動開發篇
    - [[課程筆記]Linux Driver正點原子課程筆記3 - 我的第一個Linux驅動 - MeetonFriday](https://meetonfriday.com/posts/62f55520/)
    - [[課程筆記]Linux Driver正點原子課程筆記4 - Led燈驅動實驗 - MeetonFriday](https://meetonfriday.com/posts/9aca0070/)
+ [使用 GDB 對 QEMU/vng 進行除錯](https://hackmd.io/@RinHizakura/SJ8GXUPJ6#%E4%BD%BF%E7%94%A8-GDB-%E5%B0%8D-QEMUvng-%E9%80%B2%E8%A1%8C%E9%99%A4%E9%8C%AF)

+ [The kernel's command-line parameters — The Linux Kernel documentation](https://www.kernel.org/doc/html/v4.14/admin-guide/kernel-parameters.html)

