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

    - Configure NFS server on Host-OS
        > lunbuntu 22.04 with VirtualBox v7.0

        1. dependency

            ```
            $ sudo apt install nfs-kernel-server
            $ sudo apt install bridge-utils uml-utilities   # maybe not necessary
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

        1. Create a `tap-device` (virtual network interface)

            ```
            $ sudo ip tuntap add dev tap0 mode tap
            $ sudo ip link set dev tap0 up
            $ sudo ip address add dev tap0 192.168.1.1/16   # set tap ip-address

            $ ip addr
            1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
                link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
                inet 127.0.0.1/8 scope host lo
                   valid_lft forever preferred_lft forever
                inet6 ::1/128 scope host
                   valid_lft forever preferred_lft forever
            2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 000
                link/ether 08:00:27:12:4d:ae brd ff:ff:ff:ff:ff:ff
                inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
                   valid_lft 69272sec preferred_lft 69272sec
                inet6 fd17:625c:f037:2:2eb4:5406:23c4:5c74/64 scope global temporary dynamic
                   valid_lft 86001sec preferred_lft 14001sec
                inet6 fd17:625c:f037:2:18ae:2c0b:75e6:7fc3/64 scope global dynamic mngtmpaddr noprefixroute
                   valid_lft 86001sec preferred_lft 14001sec
                inet6 fe80::9709:3d8d:24ac:28e2/64 scope link noprefixroute
                   valid_lft forever preferred_lft forever
            3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 000
                link/ether 08:00:27:30:c4:a9 brd ff:ff:ff:ff:ff:ff
                inet 192.168.56.101/24 brd 192.168.56.255 scope global dynamic noprefixroute enp0s8
                   valid_lft 571sec preferred_lft 571sec
                inet6 fe80::7220:5560:ed27:bec8/64 scope link noprefixroute
                   valid_lft forever preferred_lft forever
            4: tap0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN group default qle 1000
                link/ether f6:5e:c5:fe:1a:4a brd ff:ff:ff:ff:ff:ff
                inet 192.168.1.1/16 scope global tap0
                   valid_lft forever preferred_lft forever
            ```

    - Configure NFS server on Guest-OS (with tap-devide)
        > + base on `kernel 4.19.319` with `busybox v1.36.1`
        > + use ethernet driver `smsc911x`
        > ```
        > ...
        > smsc911x 4e000000.ethernet eth0: SMSC911x/921x identified at 0x8c910000, IRQ: 22
        > ```

        1. kernel configuration
            > `make vexpress_defconfig`

            > + About NFS
            > ```
            > > Device Drivers > Remoteproc drivers
            >     <*> Support for Remote Processor subsystem
            > > Device Drivers > Rpmsg drivers
            >     <*> RPMSG device interface
            >     <*> Virtio RPMSG bus driver
            > ```
            >
            > ```
            > > Device Drivers > Network device support
            >     --- Network device support
            >     [*]   Network core driver support
            >     < >     Bonding driver support
            >     < >     Dummy net driver support
            >     < >     EQL (serial line load balancing) support
            >     < >     Ethernet team driver support  ----
            >     < >     MAC-VLAN support
            >     < >     Virtual eXtensible Local Area Network (VXLAN)
            >     < >     Generic Network Virtualization Encapsulation
            >     < >     GPRS Tunneling Protocol datapath (GTP-U)
            >     < >     IEEE 802.1AE MAC-level encryption (MACsec)
            >     < >     Network console logging support
            >     <*>     Universal TUN/TAP device driver support
            >
            > > Device Drivers > Network device support > Ethernet driver support
            >     [*]   SMC (SMSC)/Western Digital devices
            >     <*>     SMC 91C9x/91C1xxx support
            >     < >     SMSC LAN911[5678] support
            >     <*>     SMSC LAN911x/LAN921x families embedded ethernet support
            > ```
            >
            > ```
            > > File systems > Network File Systems
            >     --- Network File Systems
            >     <*>   NFS client support
            >     <*>     NFS client support for NFS version 2
            >     <*>     NFS client support for NFS version 3
            >     [ ]       NFS client support for the NFSv3 ACL protocol extension
            >     <*>     NFS client support for NFS version 4
            >     [*]     Provide swap over NFS support
            >     [*]   NFS client support for NFSv4.1
            >     [*]     NFS client support for NFSv4.2
            >     (kernel.org) NFSv4.1 Implementation ID Domain
            >     [*]     NFSv4.1 client support for migration
            >     [*]   Root file system on NFS
            >     [ ]   Use the legacy NFS DNS resolver
            > ```
            >

            > + About kernel debug
            > ```
            > > Kernel hacking > Compile-time checks and compiler options
            >     [*] Compile the kernel with debug info
            >     [ ]   Reduce debugging information
            >     [ ]   Produce split debuginfo in .dwo files
            >     [*]   Generate dwarf4 debuginfo
            >     [*]   Provide GDB scripts for kernel debugging
            >     [*] Enable __must_check logic
            >     (1024) Warn for stack frames larger than (needs gcc 4.4)
            >     [ ] Strip assembler-generated symbols during link
            >     [*] Generate readable assembler code
            >     [ ] Enable unused/obsolete exported symbols
            > ```

        1. Qemu start on Host-OS

            ```
            $ qemu-system-arm -M vexpress-a9 \
               -smp 2 \
               -m 128M \
               -kernel arch/arm/boot/zImage \
               -append "rdinit=/linuxrc console=ttyAMA0 loglevel=8" \
               -dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
               -initrd initramfs.cpio.gz \
               -net nic -net tap,ifname=tap0,script=no,downscript=no \
               -nographic
            ```

        1. Network status of Guest-OS

            ```
            / # ifconfig
            eth0      Link encap:Ethernet  HWaddr 52:54:00:12:34:56
                      inet addr:192.168.1.3  Bcast:192.168.1.255  Mask:255.255.255.0
                      UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
                      RX packets:0 errors:0 dropped:0 overruns:0 frame:0
                      TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
                      collisions:0 txqueuelen:1000
                      RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
                      Interrupt:22

            lo        Link encap:Local Loopback
                      inet addr:127.0.0.1  Mask:255.0.0.0
                      UP LOOPBACK RUNNING  MTU:65536  Metric:1
                      RX packets:0 errors:0 dropped:0 overruns:0 frame:0
                      TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
                      collisions:0 txqueuelen:1000
                      RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

            / # ping 192.168.1.1
                PING 192.168.1.1 (192.168.1.1): 56 data bytes
                64 bytes from 192.168.1.1: seq=0 ttl=64 time=71.960 ms
                64 bytes from 192.168.1.1: seq=1 ttl=64 time=1.855 ms
                64 bytes from 192.168.1.1: seq=2 ttl=64 time=1.152 ms
                ...
            / #
            ```

        1. Mount NFS on Guest-OS

            ```
            / # mount -t nfs -o nolock 192.168.1.1:/home/nfs /mnt/rwfs
            ```

        1. kernel boot log

            ```
            Booting Linux on physical CPU 0x0
            Linux version 4.19.319 (lub20wl@lub20wl-virtualbox) (gcc version 7.5.0 (Linaro GCC 7.5-2019.12)) 7 SMP Sun Jan 25 11:20:51 CST 2026
            CPU: ARMv7 Processor [410fc090] revision 0 (ARMv7), cr=10c5387d
            CPU: PIPT / VIPT nonaliasing data cache, VIPT nonaliasing instruction cache
            OF: fdt: Machine model: V2P-CA9
            Memory policy: Data cache writealloc
            On node 0 totalpages: 32768
              Normal zone: 256 pages used for memmap
              Normal zone: 0 pages reserved
              Normal zone: 32768 pages, LIFO batch:7
            percpu: Embedded 16 pages/cpu s32908 r8192 d24436 u65536
            pcpu-alloc: s32908 r8192 d24436 u65536 alloc=16*4096
            pcpu-alloc: [0] 0 [0] 1 [0] 2 [0] 3
            Built 1 zonelists, mobility grouping on.  Total pages: 32512
            Kernel command line: rdinit=/linuxrc console=ttyAMA0 loglevel=8
            log_buf_len individual max cpu contribution: 4096 bytes
            log_buf_len total cpu_extra contributions: 12288 bytes
            log_buf_len min size: 16384 bytes
            log_buf_len: 32768 bytes
            early log buf free: 15164(92%)
            Dentry cache hash table entries: 16384 (order: 4, 65536 bytes)
            Inode-cache hash table entries: 8192 (order: 3, 32768 bytes)
            Memory: 114504K/131072K available (6144K kernel code, 473K rwdata, 1292K rodata, 1024K init, 146Kbss, 16568K reserved, 0K cma-reserved)
            Virtual kernel memory layout:
                vector  : 0xffff0000 - 0xffff1000   (   4 kB)
                fixmap  : 0xffc00000 - 0xfff00000   (3072 kB)
                vmalloc : 0x88800000 - 0xff800000   (1904 MB)
                lowmem  : 0x80000000 - 0x88000000   ( 128 MB)
                modules : 0x7f000000 - 0x80000000   (  16 MB)
                  .text : 0x(ptrval) - 0x(ptrval)   (7136 kB)
                  .init : 0x(ptrval) - 0x(ptrval)   (1024 kB)
                  .data : 0x(ptrval) - 0x(ptrval)   ( 474 kB)
                   .bss : 0x(ptrval) - 0x(ptrval)   ( 147 kB)
            SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=4, Nodes=1
            rcu: Hierarchical RCU implementation.
            rcu:    RCU event tracing is enabled.
            rcu:    RCU restricting CPUs from NR_CPUS=8 to nr_cpu_ids=4.
            rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=4
            NR_IRQS: 16, nr_irqs: 16, preallocated irqs: 16
            L2C: platform modifies aux control register: 0x02020000 -> 0x02420000
            L2C: DT/platform modifies aux control register: 0x02020000 -> 0x02420000
            L2C-310 enabling early BRESP for Cortex-A9
            L2C-310 full line of zeros enabled for Cortex-A9
            L2C-310 dynamic clock gating disabled, standby mode disabled
            L2C-310 cache controller enabled, 8 ways, 128 kB
            L2C-310: CACHE_ID 0x410000c8, AUX_CTRL 0x46420001
            sched_clock: 32 bits at 24MHz, resolution 41ns, wraps every 89478484971ns
            clocksource: arm,sp804: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 1911260446275 ns
            smp_twd: clock not found -2
            Console: colour dummy device 80x30
            Calibrating local timer... 103.46MHz.
            Calibrating delay loop... 652.08 BogoMIPS (lpj=3260416)
            CPU: Testing write buffer coherency: ok
            CPU0: Spectre v2: using BPIALL workaround
            pid_max: default: 32768 minimum: 301
            Mount-cache hash table entries: 1024 (order: 0, 4096 bytes)
            Mountpoint-cache hash table entries: 1024 (order: 0, 4096 bytes)
            CPU0: thread -1, cpu 0, socket 0, mpidr 80000000
            Setting up static identity map for 0x60100000 - 0x60100060
            rcu: Hierarchical SRCU implementation.
            smp: Bringing up secondary CPUs ...
            CPU1: thread -1, cpu 1, socket 0, mpidr 80000001
            CPU1: Spectre v2: using BPIALL workaround
            CPU2: failed to boot: -38
            CPU3: failed to boot: -38
            smp: Brought up 1 node, 2 CPUs
            SMP: Total of 2 processors activated (1337.75 BogoMIPS).
            CPU: All CPU(s) started in SVC mode.
            devtmpfs: initialized
            clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
            futex hash table entries: 1024 (order: 4, 65536 bytes)
            NET: Registered protocol family 16
            DMA: preallocated 256 KiB pool for atomic coherent allocations
            cpuidle: using governor ladder
            hw-breakpoint: debug architecture 0x4 unsupported.
            Serial: AMBA PL011 UART driver
            10009000.uart: ttyAMA0 at MMIO 0x10009000 (irq = 29, base_baud = 0) is a PL011 rev1
            console [ttyAMA0] enabled
            1000a000.uart: ttyAMA1 at MMIO 0x1000a000 (irq = 30, base_baud = 0) is a PL011 rev1
            1000b000.uart: ttyAMA2 at MMIO 0x1000b000 (irq = 31, base_baud = 0) is a PL011 rev1
            1000c000.uart: ttyAMA3 at MMIO 0x1000c000 (irq = 32, base_baud = 0) is a PL011 rev1
            OF: amba_device_add() failed (-19) for /smb@4000000/motherboard/iofpga@7,00000000/wdt@f000
            OF: amba_device_add() failed (-19) for /memory-controller@100e0000
            OF: amba_device_add() failed (-19) for /memory-controller@100e1000
            OF: amba_device_add() failed (-19) for /watchdog@100e5000
            irq: type mismatch, failed to map hwirq-75 for interrupt-controller@1e001000!
            SCSI subsystem initialized
            usbcore: registered new interface driver usbfs
            usbcore: registered new interface driver hub
            usbcore: registered new device driver usb
            clocksource: Switched to clocksource arm,sp804
            NET: Registered protocol family 2
            IP idents hash table entries: 2048 (order: 2, 16384 bytes)
            tcp_listen_portaddr_hash hash table entries: 512 (order: 0, 6144 bytes)
            TCP established hash table entries: 1024 (order: 0, 4096 bytes)
            TCP bind hash table entries: 1024 (order: 1, 8192 bytes)
            TCP: Hash tables configured (established 1024 bind 1024)
            UDP hash table entries: 256 (order: 1, 8192 bytes)
            UDP-Lite hash table entries: 256 (order: 1, 8192 bytes)
            NET: Registered protocol family 1
            RPC: Registered named UNIX socket transport module.
            RPC: Registered udp transport module.
            RPC: Registered tcp transport module.
            RPC: Registered tcp NFSv4.1 backchannel transport module.
            Unpacking initramfs...
            Freeing initrd memory: 5196K
            hw perfevents: enabled with armv7_cortex_a9 PMU driver, 7 counters available
            workingset: timestamp_bits=30 max_order=15 bucket_order=0
            squashfs: version 4.0 (2009/01/31) Phillip Lougher
            NFS: Registering the id_resolver key type
            Key type id_resolver registered
            Key type id_legacy registered
            nfs4filelayout_init: NFSv4 File Layout Driver Registering...
            nfs4flexfilelayout_init: NFSv4 Flexfile Layout Driver Registering...
            jffs2: version 2.2. (NAND) © 2001-2006 Red Hat, Inc.
            9p: Installing v9fs 9p2000 file system support
            io scheduler noop registered (default)
            io scheduler mq-deadline registered
            io scheduler kyber registered
            40000000.flash: Found 2 x16 devices at 0x0 in 32-bit bank. Manufacturer ID 0x000000 Chip ID 0x00000
            Intel/Sharp Extended Query Table at 0x0031
            Using buffer write method
            erase region 0: offset=0x0,size=0x40000,blocks=256
            40000000.flash: Found 2 x16 devices at 0x0 in 32-bit bank. Manufacturer ID 0x000000 Chip ID 0x00000
            Intel/Sharp Extended Query Table at 0x0031
            Using buffer write method
            erase region 0: offset=0x0,size=0x40000,blocks=256
            Concatenating MTD devices:
            (0): "40000000.flash"
            (1): "40000000.flash"
            into device "40000000.flash"
            tun: Universal TUN/TAP device driver, 1.6
            smsc911x 4e000000.ethernet: Linked as a consumer to regulator.1
            smsc911x 4e000000.ethernet eth0: MAC Address: 52:54:00:12:34:56
            usbcore: registered new interface driver usbhid
            usbhid: USB HID core driver
            oprofile: using arm/armv7-ca9
            NET: Registered protocol family 17
            9pnet: Installing 9P2000 support
            Key type dns_resolver registered
            Registering SWP/SWPB emulation handler
            input: AT Raw Set 2 keyboard as /devices/platform/smb@4000000/smb@4000000:motherboard/smb@4000000motherboard:iofpga@7,00000000/10006000.kmi/serio0/input/input0
            Freeing unused kernel memory: 1024K
            Run /linuxrc as init process
            Starting /etc/rc.d/init.d/S01filesystems
            Mounting filesystems
            Starting /etc/rc.d/init.d/S02network
            Network up
            Generic PHY 4e000000.ethernet-ffffffff:01: attached PHY driver [Generic PHY] (mii_bus:phy_addr=4e00000.ethernet-ffffffff:01, irq=POLL)
            smsc911x 4e000000.ethernet eth0: SMSC911x/921x identified at 0x8c910000, IRQ: 22
            Starting /etc/rc.d/init.d/S03hostname

            Please press Enter to activate this console.
            / #
            ```


    - Configure NFS server on Guest-OS (with DHCP, Guest-OS somethimes losses connection)
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

