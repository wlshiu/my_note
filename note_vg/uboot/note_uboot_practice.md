uboot 實務 [[Back](note_uboot_quick_start.md)]
---

# simulation

## Compile

+ dependency

    ```bash
    $ sudo apt-get install git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev libc6-dev lib32ncurses5-dev gcc-multilib libx11-dev lib32z1-dev libgl1-mesa-dev

    $ sudo apt-get install device-tree-compiler
    $ sudo apt-get install u-boot-tools # for mkimage tool
    ```
+ build code

    ```bash
    export ARCH=arm
    export CROSS_COMPILE=arm-none-eabi-

    # time make imx6dl_icore_nand_defconfig     # 紀錄編譯時間
    make imx6dl_icore_nand_defconfig
    make

    make cscope
    ```

## rootfs

+ busybox

    - environment setup

        ```
        $ vi ./setting.env
            export ARCH=arm
            export PATH=$HOME/toolchain/gcc-linaro-6.5.0-2018.12-i686_arm-linux-gnueabi/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
            export CROSS_COMPILE=arm-linux-gnueabi-
        $ source setting.env
        ```

    - build

        ```bash
        $ wget https://busybox.net/downloads/busybox-1.31.1.tar.bz2
        $ tar -xjf busybox-1.31.1.tar.bz2
        $ cd busybox-1.31.1
        $ make menuconfig
            # 勾選 Busybox Setting
                -> Build Options
                    -> [*] Build static binary (no shared libs) 或 搜索 CONFIG_STATIC
        $ make
        $ make install
        $ ll
            ...
            _install/
        ```

+ `make_rootfs.sh`

    ```bash
    $ vi ./make_rootfs.sh
        #!/bin/bash -

        set -e

        base=`pwd`
        tmpfs=$base/_tmpfs
        cross_compiler=$HOME/toolchain/gcc-linaro-6.5.0-2018.12-i686_arm-linux-gnueabi

        sudo rm -rf rootfs
        sudo rm -rf ${tmpfs}
        sudo rm -f a9rootfs.ext3
        sudo mkdir rootfs
        sudo cp _install/*  rootfs/ -raf

        #sudo mkdir -p rootfs/{lib,proc,sys,tmp,root,var,mnt}
        cd rootfs && sudo mkdir -p lib proc sys tmp root var mnt && cd ${base}

        # copy libc/*.so of arm-gcc
        sudo cp -arf ${cross_compiler}/arm-linux-gnueabi/libc/lib/*so*  rootfs/lib

        # sudo cp app rootfs
        sudo cp examples/bootfloppy/etc rootfs/ -arf
        sudo sed -r  "/askfirst/ s/.*/::respawn:-\/bin\/sh/" rootfs/etc/inittab -i
        sudo mkdir -p rootfs/dev/
        sudo mknod rootfs/dev/tty1 c 4 1
        sudo mknod rootfs/dev/tty2 c 4 2pro
        sudo mknod rootfs/dev/tty3 c 4 3
        sudo mknod rootfs/dev/tty4 c 4 4
        sudo mknod rootfs/dev/console c 5 1
        sudo mknod rootfs/dev/null c 1 3
        sudo dd if=/dev/zero of=a9rootfs.ext3 bs=1M count=128
        # message "No space left on device": you should extend size

        sudo mkfs.ext3 a9rootfs.ext3
        sudo mkdir -p ${tmpfs}
        sudo chmod 777 ${tmpfs}
        sudo mount -t ext3 a9rootfs.ext3 ${tmpfs}/ -o loop
        sudo cp -r rootfs/*  ${tmpfs}/
        sudo umount ${tmpfs}
    $ chmod +x ./make_rootfs.sh
    ```

+ sd image

    ```
    $ dd if=/dev/zero of=uboot.disk bs=1M count=256
    $ sgdisk -n 0:0:+10M -c 0:kernel uboot.disk
    $ sgdisk -n 0:0:0 -c 0:rootfs uboot.disk
    $ sgdisk -p uboot.disk
    ...
        Number  Start (sector)    End (sector)  Size       Code  Name
           1            2048           22527   10.0 MiB    8300  kernel
           2           22528          524254   245.0 MiB   8300  rootfs
    ```

    - map to loop device

        ```
        $ LOOPDEV=`losetup -f`
        $ sudo losetup $LOOPDEV  uboot.disk
        $ sudo partprobe $LOOPDEV
        $ ls /dev/loop*
            /dev/loop0    /dev/loop1  /dev/loop4  /dev/loop7
            /dev/loop0p1  /dev/loop2  /dev/loop5  /dev/loop-control
            /dev/loop0p2  /dev/loop3  /dev/loop6
        ```

    - format

        ```
        $ sudo mkfs.ext4 /dev/loop0p1
        $ sudo mkfs.ext4 /dev/loop0p2
        ```
    - mount

        ```
        $ mkdir p1 p2
        $ sudo mount -t ext4 /dev/loop0p1 p1
        $ sudo mount -t ext4 /dev/loop0p2 p2
        ```

    - copy data

        ```
        # 將 zImage 和 dtb 拷貝到 p1
        # schips @ ubuntu in ~/arm/sc/linux-4.14.14 [17:55:39]
        $ sudo cp arch/arm/boot/zImage p1
        $ sudo cp arch/arm/boot/dts/vexpress-v2p-ca9.dtb p1

        # 將 文件系統中的文件拷貝到 p2
        ## 因為在上一講我已經做好了一個 ext3的鏡像, 所以我直接使用了

        # schips @ ubuntu in ~/arm/sc/linux-4.14.14 [17:59:24] C:1
        $ sudo mount -t ext3 ../busybox-1.27.0/a9rootfs.ext3 _tmp -o loop
        $ sudo cp _tmp/* p2 -arf
        ```

    - unmount

        ```
        $ sudo umount p1 p2
        $ sudo losetup -d /dev/loop0
        ```

    - `z_gen_sd_img.sh`

        ```bash
        $ vi ./z_gen_sd_img.sh
            #!/bin/bash

            set -e

            OUT_DISK=uboot.disk
            PATH_ZIMAGE=
            PATH_DTB=
            PATH_ROOTFS=

            PARTITION_NUM=2
            i=0
            LOOP_DEV=$(losetup -f)

            dd if=/dev/zero of=${OUT_DISK} bs=1M count=256

            sgdisk -n 0:0:+10M -c 0:kernel ${OUT_DISK}
            i=$((i+1))

            sgdisk -n 0:0:0 -c 0:rootfs ${OUT_DISK}
            i=$((i+1))

            if [ $i != $PARTITION_NUM ]; then
                echo -e "\n!!!! partiotn number is not match !!!!!!"
                exit -1;
            fi

            sgdisk -p ${OUT_DISK}

            sudo losetup ${LOOP_DEV}  ${OUT_DISK}
            sudo partprobe ${LOOP_DEV}
            ls ${LOOP_DEV}*

            i=1
            while [ $i -le $PARTITION_NUM ]
            do
                mkdir p$i
                echo -e "\n------ partition format --------"
                sudo mkfs.ext4 ${LOOP_DEV}p$i
                echo -e "\n------ mount p$i --------"
                sudo mount -t ext4 ${LOOP_DEV}p$i p$i

                case $i in
                    "1")
                        # ToDo: copy ${PATH_ZIMAGE} and ${PATH_DTB} to partiotn
                        ;;
                    "2")
                        # ToDo: copy ${PATH_ROOTFS} to partiotn
                        ;;
                    *)
                        break;
                        ;;
                esac

                (( i++ ))
            done

            i=1
            while [ $i -le $PARTITION_NUM ]
            do
                echo -e "\n------ umount p$i --------"
                sudo umount p$i
                rm -fr p$i

                (( i++ ))
            done

            sudo losetup -d ${LOOP_DEV}

            echo -e "\n----------- done ---------"
        ```

## u-boot

+ environment setup

    ```
    $ vi ./setting.env
        export ARCH=arm
        export PATH=$HOME/toolchain/gcc-linaro-6.5.0-2018.12-i686_arm-linux-gnueabi/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        export CROSS_COMPILE=arm-linux-gnueabi-
    $ source setting.env
    ```

+ build

    ```
    $ wget https://mirror.cyberbits.eu/u-boot/u-boot-2020.07.tar.bz2
    $ tar -xjf u-boot-2020.07.tar.bz2
    $ cd u-boot-2020.07
    $ make vexpress_ca9x4_defconfig
    $ make
    ```

+ run

    ```bash
    $ vi ./z_qemu_uboot.sh
        set -e

        help()
        {
            echo -e "usage: $0 <disk_img>"
            echo -e "    e.g. $0 uboot.disk"
            exit -1
        }

        if [ $# != 1 ]; then
            help
        fi

        # '-M vexpress-a9'                  模擬vexpress-a9單板, 你能夠使用'-M ?'參數來獲取該 qemu 版本號支持的全部單板
        # '-m 512M'                         單板執行物理內存 512M
        # '-kernel arch/arm/boot/zImage'    告訴 qemu 單板執行內核鏡像路徑
        # '-dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb'     告訴 qemu單板的設備樹(必須加入)
        # '-nographic'                      不使用圖形化界面, 僅僅使用串口
        # '-append "console=ttyAMA0" '      內核啟動參數. 這裡告訴內核 vexpress 單板執行. 串口設備是哪個 tty.

        sudo qemu-system-arm -M vexpress-a9 -m 128M -smp 1 -nographic -kernel u-boot -sd $1
    $ chmod +x ./z_qemu_uboot.sh
    $ ./z_qemu_uboot.sh uboot.disk
    ```

## linux 4.14.136

+ environment setup

    ```
    $ vi ./setting.env
        export ARCH=arm
        export PATH=$HOME/toolchain/gcc-linaro-6.5.0-2018.12-i686_arm-linux-gnueabi/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        export CROSS_COMPILE=arm-linux-gnueabi-
    $ source setting.env
    ```

+ build

    ```
    $ wget http://ftp.ntu.edu.tw/linux/kernel/v4.x/linux-4.14.136.tar.xz
    $ tar -xZf linux-4.14.136.tar.xz
    $ cd linux-4.14.136
    $ make vexpress_defconfig
    $ make
    ```

+ run

    ```
    $ vi ./z_qemu_linux.sh
        set -e

        help()
        {
            echo -e "usage: $0 <disk_img>"
            echo -e "    e.g. $0 linux.disk"
            exit -1;
        }

        if [ $# != 1 ]; then
            help
        fi

        # '-M vexpress-a9'                  模擬vexpress-a9單板, 你能夠使用'-M ?'參數來獲取該 qemu 版本號支持的全部單板
        # '-m 512M'                         單板執行物理內存 512M
        # '-kernel arch/arm/boot/zImage'    告訴 qemu 單板執行內核鏡像路徑
        # '-dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb'     告訴 qemu單板的設備樹(必須加入)
        # '-nographic'                      不使用圖形化界面, 僅僅使用串口
        # '-append "console=ttyAMA0" '      內核啟動參數. 這裡告訴內核 vexpress 單板執行. 串口設備是哪個 tty.

        sudo qemu-system-arm -M vexpress-a9 -m 256M -smp 4 \
            -kernel arch/arm/boot/zImage \
            -dtb arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
            -nographic \
            -append "root=/dev/mmcblk0 rw console=ttyAMA0" \
            -sd $1
    $ chmod +x ./z_qemu_linux.sh
    $ ./z_qemu_linux.sh linux.disk
    ```

## 64-bits

+ `qemu_arm64_defconfig` of uboot
    > enable DM

    ```bash
    $ wget https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
    $ tar -xJf ./gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz

    $ vi setting.env
        export ARCH=arm64
        export PATH=$HOME/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        export CROSS_COMPILE=aarch64-linux-gnu-

    $ source ./setting.env
    $ cd uboot
    $ make qemu_arm64_defconfig && make

    # gdb server
    $ qemu-system-aarch64 -machine virt -cpu cortex-a57 -bios u-boot.bin -nographic -s -S

    # gdb client
    $ aarch64-linux-gnu-gdb u-boot
        GNU gdb (Linaro_GDB-2019.12) 8.3.1.20191204-git
        Copyright (C) 2019 Free Software Foundation, Inc.
        License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
        This is free software: you are free to change and redistribute it.
        There is NO WARRANTY, to the extent permitted by law.
        Type "show copying" and "show warranty" for details.
        This GDB was configured as "--host=x86_64-unknown-linux-gnu --target=aarch64-linux-gnu".
        Type "show configuration" for configuration details.
        For bug reporting instructions, please see:
        <http://www.gnu.org/software/gdb/bugs/>.
        Find the GDB manual and other documentation resources online at:
            <http://www.gnu.org/software/gdb/documentation/>.

        For help, type "help".
        Type "apropos word" to search for commands related to "word"...

        warning: ~/.gdbinit.local: No such file or directory
        /home/vng/.gdbinit:97: Error in sourced command file:
        Invalid type combination in equality test.
        Reading symbols from u-boot...
        (gdb) target remote :1234
        Remote debugging using :1234
        _start () at arch/arm/cpu/armv8/start.S:31
        31              b       reset
        (gdb) b initf_dm
        Breakpoint 1 at 0x1196c: file common/board_f.c, line 806.
        (gdb) c
        Continuing.

        Breakpoint 1, initf_dm () at common/board_f.c:806
        (gdb)
    ```

+ reference

    - [README.qemu-arm](doc/README.qemu-arm)
    - [qemu: usb存儲設備仿真](https://www.twblogs.net/a/5bbcfcdb2b71776bd30bc2d2)


## Host commonds

+ 檢查及修復檔案系統指令

    - `dumpe2fs`
        > 查看這個 partition 中, superblock 和 Group Description Table 中的信息

        ```bash
        $ dumpe2fs ./ext4.disk
        dumpe2fs 1.44.1 (24-Mar-2018)
        Filesystem volume name:   <none>
        Last mounted on:          <not available>
        Filesystem UUID:          66737b90-1d24-4f13-8589-9df4edc7b757
        Filesystem magic number:  0xEF53
        Filesystem revision #:    1 (dynamic)
        Filesystem features:      has_journal ext_attr resize_inode dir_index filetype extent 64bit flex_bg sparse_super large_file huge_file dir_nlink extra_isize metadata_csum
        Filesystem flags:         signed_directory_hash
        Default mount options:    user_xattr acl
        Filesystem state:         clean
        Errors behavior:          Continue
        Filesystem OS type:       Linux
        Inode count:              2048
        Block count:              2048
        Reserved block count:     102
        Free blocks:              950
        Free inodes:              2037
        First block:              0
        Block size:               4096
        ...

        Group 0: (Blocks 0-2047) csum 0x7a19
          Primary superblock at 0, Group descriptors at 1-1
          Block bitmap at 2 (+2), csum 0xfbdf5b1e
          Inode bitmap at 18 (+18), csum 0xa4024b9c
          Inode table at 34-97 (+34)
          950 free blocks, 2037 free inodes, 2 directories, 2037 unused inodes
          Free blocks: 1098-2047
          Free inodes: 12-2048
        ```

    - `e2fsck`

        ```bash
        $ e2fsck --help
            e2fsck: invalid option -- '-'
            Usage: e2fsck [-panyrcdfktvDFV] [-b superblock] [-B blocksize]
                            [-l|-L bad_blocks_file] [-C fd] [-j external_journal]
                            [-E extended-options] [-z undo_file] device

            Emergency help:
             -p                   Automatic repair (no questions), 自動修復
             -n                   Make no changes to the filesystem, 以[唯讀]方式開啟
             -y                   Assume "yes" to all questions
             -c                   Check for bad blocks and add them to the badblock list
             -f                   Force checking even if filesystem is marked clean
             -v                   Be verbose, 詳細顯示模式
             -b superblock        Use alternative superblock
             -B blocksize         Force blocksize when looking for superblock
             -j external_journal  Set location of the external journal
             -l bad_blocks_file   Add to badblocks list
             -L bad_blocks_file   Set badblocks list
             -z undo_file         Create an undo file
             -V                   顯示出目前 e2fsck 的版本
             -C file              將檢查的結果存到 file 中以便查看

        $ e2fsck -p -y /dev/hda5
        ```

        1. 大部份使用 e2fsck 來檢查硬盤 partition 的情況時, 通常都是情形特殊,
        因此最好先將該 partition umount, 然後再執行 e2fsck 來做檢查,
        若是要非要檢查 `/` 時, 則請進入 singal user mode 再執行.

    - `od`
        > 用來檢視儲存在二進位制檔案中的值

        ```bash
        $ od -tx1 -Ax fs
            000000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
            *
            000400 80 00 00 00 00 04 00 00 33 00 00 00 da 03 00 00
            000410 75 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00
            ...

        # 其中以'*'開頭的行表示這一段數據全是 0 因此省略了
        ```

    - `hexdump`
        > 用來檢視儲存在二進位制檔案中的值

        ```bash
        $ hexdump -C fs
            000000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
            *
            000400 80 00 00 00 00 04 00 00 33 00 00 00 da 03 00 00
            000410 75 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00
            ...

        # 其中以'*'開頭的行表示這一段數據全是 0 因此省略了
        ```

## Qemu simulation

+ Build uboot for Qemu

    ```bash
    $ vi setting.env
        export ARCH=arm
        export CROSS_COMPILE=arm-linux-gnueabi-
        export PATH=$HOME/gcc-linaro-6.5.0-2018.12-i686_arm-linux-gnueabi/bin:$HOME/.local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

    $ source setting.env
    $ make vexpress_ca9x4_defconfig
    ```

+ 生成一個空的 SD卡 image

    ```bash
    # bs: block size= 512/1024/1M
    $ dd if=/dev/zero of=uboot.disk bs=512 count=1024
        1024+0 records in
        1024+0 records out
        1073741824 bytes (1.1 GB, 1.0 GiB) copied, 1.39208 s, 771 MB/s
    ```

+ 創建 GPT 分區
    > 下面創建了兩個分區, 一個用來存放 kernel 和設備樹, 另一個存放 rootfs

    ```bash
    $ sgdisk -n 0:0:+512k -c 0:kernel uboot.disk
        Creating new GPT entries.
        Setting name!
        partNum is 0
        Warning: The kernel is still using the old partition table.
        The new table will be used at the next reboot or after you
        run partprobe(8) or kpartx(8)
        The operation has completed successfully.
    $ sgdisk -n 0:0:0 -c 0:rootfs uboot.disk
        Setting name!
        partNum is 1
        Warning: The kernel is still using the old partition table.
        The new table will be used at the next reboot or after you
        run partprobe(8) or kpartx(8)
        The operation has completed successfully.
    ```

+ 查看分區

    ```bash
    $ sgdisk -p uboot.disk
        Disk uboot.disk: 2097152 sectors, 1024.0 MiB
        Sector size (logical): 512 bytes
        Disk identifier (GUID): F15BD4B6-D624-432B-995B-13E7641A9AEB
        Partition table holds up to 128 entries
        Main partition table begins at sector 2 and ends at sector 33
        First usable sector is 34, last usable sector is 2097118
        Partitions will be aligned on 2048-sector boundaries
        Total free space is 2014 sectors (1007.0 KiB)

        Number  Start (sector)    End (sector)  Size       Code  Name
           1            2048           22527   10.0 MiB    8300  kernel
           2           22528         2097118   1013.0 MiB  8300  rootfs
    ```

+ Host side 操作 SD image file

    - 尋找一個空閒的 loop 設備

        ```bash
        $ losetup -f
            /dev/loop0
        ```
    - 將 SD卡 image 映射到 loop 設備上

        ```
        $ sudo losetup /dev/loop0 uboot.disk
        $ sudo partprobe /dev/loop0
        $ ls /dev/loop*   # 看到 '/dev/loop0p1' 和 '/dev/loop0p2' 兩個 devices
            ...
            /dev/loop0p1
            /dev/loop0p2
            ...
        ```

    - 格式化

        ```bash
        $ sudo mkfs.fat /dev/loop0p1
        $ sudo mkfs.vfat -F 32 /dev/loop0p1
        $ sudo mkfs.ext4 /dev/loop0p1
        ```

    - mount

        ```bash
        $ sudo mount -t fat /dev/loop0p1 p1/
        ```

    - 拷貝文件

        ```
        $ sudo cp linux-4.14.13/arch/arm/boot/zImage p1/
        ```
    - umount

        ```bash
        $ sudo umount p1
        $ sudo losetup -d /dev/loop0
        ```

+ Run Qemu

    ```
    $ vi ./z_qemu.sh
        #!/bin/bash
        set -e

        uboot_image=u-boot

        if [ ! -f uboot.disk ]; then
            # 64 MBytes: SD card size has to be a power of 2
            dd if=/dev/zero of=uboot.disk bs=512 count=131072
        fi

        qemu-system-arm \
            -M vexpress-a9 \
            -m 256M \
            -smp 1 \
            -nographic \
            -kernel ${uboot_image} \
            -sd ./uboot.disk
    ```

+ U-boot console

    ```
    => mmc info
        Device: MMC
        Manufacturer ID: aa
        OEM: 5859
        Name: QEMU!
        Bus Speed: 6250000
        Mode: SD Legacy
        Rd Block Len: 512
        SD version 2.0
        High Capacity: No
        Capacity: 1 GiB
        Bus Width: 1-bit
        Erase Group Size: 512 Bytes

    => mmc list
        MMC: 0 (SD)

    => fatinfo mmc 0
        Interface:  MMC
          Device 0: Vendor: Man 0000aa Snr adbeef00 Rev: 13.14 Prod: QEMU!
                    Type: Removable Hard Disk
                    Capacity: 1024.0 MB = 1.0 GB (2097152 x 512)
        Filesystem: FAT16 "NO NAME    "

    => mmc part   # LBA address: block number
        Partition Map for MMC device 0  --   Partition Type: EFI

        Part    Start LBA       End LBA         Name
                Attributes
                Type GUID
                Partition GUID
          1     0x00000800      0x000057ff      "kernel"
                attrs:  0x0000000000000000
                type:   0fc63daf-8483-4772-8e79-3d69d8477de4
                guid:   34d20039-0c02-4c5d-9fd2-7a915fcd1406
          2     0x00005800      0x001fffde      "rootfs"
                attrs:  0x0000000000000000
                type:   0fc63daf-8483-4772-8e79-3d69d8477de4
                guid:   7acaa32b-20a9-487c-ac66-15c12fe34ad5

    => fatinfo mmc 0:1      # partition number from 1 ~ 4
        Interface:  MMC
          Device 0: Vendor: Man 0000aa Snr adbeef00 Rev: 13.14 Prod: QEMU!
                    Type: Removable Hard Disk
                    Capacity: 1024.0 MB = 1.0 GB (2097152 x 512)
        Filesystem: FAT16 "NO NAME    "
    ```


# Commands in U-boot

## ext2/3/4 in uboot

+ `ext2load` and`ext4load`
    > load a file to memory with ext2/3/4 file system

    ```
    usage: ext4load <interface> <dev:[partition]> <mem addr> <file name> [bytes]
    e.g.
    => ext4load mmc 0:2 0x40008000 uImage

    從第 0 個存儲設備的第 1 個分區的根目錄讀出 uImage 文件到內存地址 0x40008000
    ```

+ `ext4write`
    > save memory data to device with ext4 file system

    ```
    usage: ext4write <interface> <dev[:part]> <addr> <absolute filename path> [sizebytes]
    e.g.
    => ext4write mmc 2:2 0x30007fc0 /boot/uImage 6183120
    ```

## `tftp`

+ host side

    - TFTP Server

        1. install

            ```bash
            $ sudo apt-get install tftpd-hpa    # tftp server
            $ sudo apt-get install tftp-hpa     # tftp client, for test
            ```

        1. 配置TFTP Server

            ```bash
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

            ```bash
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

## `dfu`

Device Firmware Upgrade

+ host side

    ```bash
    $ sudo apt-get install dfu-util
    $ dfu-util --help
        Usage: dfu-util [options] ...
          -h --help                     Print this help message
          -V --version                  Print the version number
          -v --verbose                  Print verbose debug statements
          -l --list                     List currently attached DFU capable devices
          -e --detach                   Detach currently attached DFU capable devices
          -E --detach-delay seconds     Time to wait before reopening a device after detach
          -d --device <vendor>:<product>[,<vendor_dfu>:<product_dfu>]
                                        Specify Vendor/Product ID(s) of DFU device
          -p --path <bus-port. ... .port>       Specify path to DFU device
          -c --cfg <config_nr>          Specify the Configuration of DFU device
          -i --intf <intf_nr>           Specify the DFU Interface number
          -S --serial <serial_string>[,<serial_string_dfu>]
                                        Specify Serial String of DFU device
          -a --alt <alt>                Specify the Altsetting of the DFU Interface
                                        by name or by number
          -t --transfer-size <size>     Specify the number of bytes per USB Transfer
          -U --upload <file>            Read firmware from device into <file>
          -Z --upload-size <bytes>      Specify the expected upload size in bytes
          -D --download <file>          Write firmware from <file> into device
          -R --reset                    Issue USB Reset signalling once we're finished
          -s --dfuse-address <address>  ST DfuSe mode, specify target address for
                                        raw file download or upload. Not applicable for
                                        DfuSe file (.dfu) downloads
    ```

    - example

        ```
        $ lsusb     # check usb status
            Bus 001 Device 013: ID 0483:df11 STMicroelectronics STM Device in DFU Mode
        $ sudo dfu-util -d 0483:df11 -a 0 -s 0x08000000 -D stm32_demo.bin

            or

        $ dfu-util -D u-boot.bin
            dfu-util 0.8

            Copyright 2005-2009 Weston Schmidt, Harald Welte and OpenMoko Inc.
            Copyright 2010-2014 Tormod Volden and Stefan Schmidt
            This program is Free Software and has ABSOLUTELY NO WARRANTY
            Please report bugs to dfu-util@lists.gnumonks.org

            dfu-util: Invalid DFU suffix signature
            dfu-util: A valid DFU suffix will be required in a future dfu-util release!!!
            Opening DFU capable USB device...
            ID 18d1:4e30
            Run-time device DFU version 0110
            Claiming USB DFU Interface...
            Setting Alternate Setting #0 ...
            Determining device status: state = dfuIDLE, status = 0
            dfuIDLE, continuing
            DFU mode device DFU version 0110
            Device returned transfer size 4096
            Copying data from PC to DFU device
            Download        [=========================] 100%       419666 bytes
            Download done.
            state(7) = dfuMANIFEST, status(0) = No error condition is present
            state(2) = dfuIDLE, status(0) = No error condition is present
            Done!
        ```

+ target board side

    - enable option

        ```
        CONFIG_CMD_DFU=y
        # DFU support
        CONFIG_USB_FUNCTION_DFU=y
        # CONFIG_DFU_TFTP is not set
        CONFIG_DFU_MMC=y
        # CONFIG_DFU_NAND is not set
        CONFIG_DFU_RAM=y
        # CONFIG_DFU_SF is not set
        可以使用 MMC 和 RAM 存儲文件

        # e.g. 輸入 setenv dfu_alt_info u-boot.bin ram 0x43E00000 0x100000
        # 表示如果使用 ram 方式, 將接收的數據存儲在 RAM 中以 0x43E00000 開始的位置, 最大為 0x10000
        # 表示如果使用 mmc 方式, 將接收的數據存儲在 MMC 中以 0x10000000 開始的位置, 最大為 0x10000
        ```

    - example

        ```
        => dfu 0 ram 0
        USB PHY0 Enable
        crq->brequest:0x0

        DOWNLOAD ... OK
        Ctrl+C to exit ...
        ```

## `mmc`

U-Boot provides access to eMMC devices through the `mmc` command and interface
but adds an additional argument to the mmc interface to describe the hardware partition.

+ 查看 emmc 命令

    ```
    uboot=> mmc
    mmc - MMC sub system
    Usage:
    mmc info - display info of the current MMC device
    mmc read addr blk# cnt
    mmc write addr blk# cnt
    mmc erase blk# cnt
    mmc rescan
    mmc part - lists available partition on current mmc device
    mmc dev [dev] [part] - show or set current mmc device [partition]
    mmc list - lists available devices
    mmc hwpartition [args...] - does hardware partitioning
        arguments (sizes in 512-byte blocks):
            [user [enh start cnt] [wrrel {on|off}]] - sets user data area attributes
            [gp1|gp2|gp3|gp4 cnt [enh] [wrrel {on|off}]] - general purpose partition
            [check|set|complete] - mode, complete set partitioning completed
        WARNING: Partitioning is a write-once setting once it is set to complete.
        Power cycling is required to initialize partitions after set to complete.
    mmc bootbus dev boot_bus_width reset_boot_bus_width boot_mode
        - Set the BOOT_BUS_WIDTH field of the specified device
    mmc bootpart-resize <dev> <boot part size MB> <RPMB part size MB>
        - Change sizes of boot and RPMB partitions of specified device
    mmc partconf dev boot_ack boot_partition partition_access
        - Change the bits of the PARTITION_CONFIG field of the specified device
    mmc rst-function dev value
        - Change the RST_n_FUNCTION field of the specified device
            WARNING: This is a write-once field and 0 / 1 / 2 are the only valid values.
    mmc setdsr <value> - set DSR register value
    ```

+ 查看 emmc 的編號

    ```
    uboot=> mmc list
    FSL_SDHC: 0
    FSL_SDHC: 1
    FSL_SDHC: 2 (eMMC)

    # 確定 emmc 的序號是2
    ```

+ 設置 emmc 的啟動分區

    ```
    # 設置 emmc 的啟動分區, 主要是 partconf 後面的第一個和第三個參數.
    # '2' 是 emmc 的編號, 第三個參數設置啟動的分區, 對應寄存器 BOOT_PARTITION_ENABLE 字段. 設為 0 表示 disable.
    uboot=> mmc partconf 2 0 0 0

    # 或者設置為 '7' 表示從 UDA 啟動, 0 和 7 我都嘗試了, 燒錄原來的鏡像都能夠啟動成功.
    uboot=> mmc partconf 2 0 7 0
    ```

+ `mmc read [addr] [blk#] [cnt]`
    > read `[cnt]` blocks from the `[blk#]-th` in flash to system memory `[addr]`
    > + `[addr]` is system buffer memory (DDR)
    > + `[blk#]` is the block order of flash
    > + `[cnt]`  is the block count of flash

+ `mmc write addr blk# cnt`
    > write `[cnt]` blocks from system memory `[addr]` to the `[blk#]-th` in flash
    > + `[addr]` is system buffer memory (DDR)
    > + `[blk#]` is the block order of flash
    > + `[cnt]`  is the block count of flash

+ `mmc erase blk# cnt`
    > erase `[cnt]` blocks from the `[blk#]-th` in flash

+ `PARTITION_CONFIG`
    > 為了通用, eMMC controller 會有一個 `PARTITION_CONFIG` register,
    用來控制 partitions 切換
    >> 指令 `mmc partconf dev boot_ack boot_partition partition_access`
    直接對應到 H/w register

    ```
    MSB
    +----------+----------+-----------------------+------------------+
    |   bit 7  | bit 6    |  bit 5 ~ 3            |   bit 2 ~ 0      |
    | reserved | BOOT_ACK | BOOT_PARTITION_ENABLE | PARTITION_ACCESS |
    +----------+----------+-----------------------+------------------+

    * BOOT_ACK (R/W/E)
        0x0: No boot acknowledge sent (default)
        0x1: Boot acknowledge sent during boot operation Bit

    * BOOT_PARTITION_ENABLE (R/W/E)
        User select boot data that will be sent to master

            0x0: device not boot enabled (default)
            0x1: boot partition 1 enable for boot
            0x2: boot partition 2 enable for boot
            0x3~6: reserved
            0x7: User area enabled for boot

    * PARTITION_ACCESS
        user select partition to access

            0x0: No access to boot partition (default)
            0x1: R/W boot partition 1
            0x2: R/W boot partition 2
            0x3: R/W Replay protected memory block (RPMB)
            0x4: Access to General purpose partition 1
            0x5: Access to General purpose partition 2
            0x6: Access to General purpose partition 3
            0x7: Access to General purpose partition 4
    ```

+ `mmc dev [dev] [part]`
    > The interface is therefore described as `mmc` where `[dev]` is the mmc device (some boards have more than one)
    and `[part]` is the hardware partition: 0=user, 1=boot0, 2=boot1.

    ```bash
    # Use the mmc dev command to specify the device and partition:
    => mmc dev 0 0     # select user hw partition
    => mmc dev 0 1     # select boot0 hw partition
    => mmc dev 0 2     # select boot1 hw partition
    ```

+ `mmc partconf`
    > The `mmc partconf` command can be used to configure the `PARTITION_CONFIG` specifying
    what hardware partition to boot from:

    ```
    # uboot console
    => mmc partconf 0 0 0 0     # disable boot partition (default unset condition; boots from user partition)
    => mmc partconf 0 1 1 0     # set boot0 partition (with ack)
    => mmc partconf 0 1 2 0     # set boot1 partition (with ack)
    => mmc partconf 0 1 7 0     # set user partition (with ack)
    ```

+ `mmc rpmb`
    > If U-Boot has been built with `CONFIG_SUPPORT_EMMC_RPMB` the mmc rpmb command is available
    for reading, writing and programming the key for the RPMB partition in eMMC.

+ When using U-Boot to write to eMMC (or microSD) it is often useful to use the `gzwrite` command.
    For example if you have a compressed **disk image**,
    you can write it to your eMMC (assuming it is mmc dev 0) with:

    ```
    => tftpboot ${loadaddr} disk-image.gz && gzwrite mmc 0 ${loadaddr} ${filesize}
    ```

    - The `disk-image.gz` contains a partition table at `offset 0x0` as well as partitions
    at their respective offsets (according to the partition table) and has been compressed with gzip.

    - If you know the flash offset of a specific partition
    (which you can determine using the part list mmc 0 command)
    you can also use `gzwrite` to flash a compressed partition image.

+ reference

    - [eMMC之分區管理、總線協議和工作模式](https://blog.csdn.net/u013686019/article/details/66472291)


## `booti`/`bootm`/`bootz`

用於啟動一個 kernel image

```
=> boot[i/m/z] <Image/zImage> [ramdisk] <dtb>
```

+ `bootm`
    > Use to boot an application image that is stored in memory (RAM or Flash).
    >> you should use `setenv` to pass `bootargs` to kernel

    ```
    假設 Image   的加載地址是 0x20008000,
         ramdisk 的加載地址是 0x21000000,
         dtb     的加載地址是 0x22000000

    (1) 只加載 kernel 的情況下
    bootm 0x20008000

    (2) 加載 kernel 和 ramdisk
    bootm 0x20008000 0x21000000

    (3) 加載 kernel 和 dtb
    bootm 0x20008000 - 0x22000000

    (4) 加載 kernel, ramdisk, fdt
    bootm 0x20008000 0x21000000 0x22000000
    ```

    - `booti`
        > booti 是 bootm 命令的一個子集,

        ```
        # kconfig
        Command line interface  --->
            Boot commands  --->
                [*] bootm
        ```

        > 要使用 booti 需要 `CONFIG_CMD_BOOTI` 配置項
        >> `config.h` of board

        ```
        --- a/include/configs/bubblegum.h
        +++ b/include/configs/bubblegum.h
        @@ -71,4 +71,6 @@
        #define CONFIG_BOARD_EARLY_INIT_F
        +#define CONFIG_CMD_BOOTI
        +
        #endif
        ```

+ `bootz`
    > boot Linux `zImage` image from memory


# reference

+ [***用 QEMU 模擬運行 uboot 從SD卡啟動Linux](https://www.cnblogs.com/pengdonglin137/p/12194548.html)
+ [UBOOT 中利用 CONFIG_EXTRA_ENV_SETTINGS 宏來設置默認ENV](https://blog.csdn.net/weixin_42418557/article/details/89018965)
+ [Zero u-boot編譯和使用指南](https://licheezero.readthedocs.io/zh/latest/%E8%B4%A1%E7%8C%AE/article%204.html)

