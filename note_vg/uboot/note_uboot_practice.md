uboot 實務 [Back](note_uboot_quick_start.md)
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




# reference

+ [***用 QEMU 模擬運行 uboot 從SD卡啟動Linux](https://www.cnblogs.com/pengdonglin137/p/12194548.html)
+ [UBOOT 中利用 CONFIG_EXTRA_ENV_SETTINGS 宏來設置默認ENV](https://blog.csdn.net/weixin_42418557/article/details/89018965)
+ [Zero u-boot編譯和使用指南](https://licheezero.readthedocs.io/zh/latest/%E8%B4%A1%E7%8C%AE/article%204.html)

