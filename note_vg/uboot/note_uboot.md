u-boot
---

[u-boot source code](ftp://ftp.denx.de/pub/u-boot/)

the version is `201907` or `latest`

# uboot directory

```
+-- api             # ?? uboot ??? API ????
+-- arch            # ? CPU ????????
¦   +-- arm/
¦   ¦   +-- cpu/
¦   ¦   ¦   +-- armv7/
¦   ¦   ¦   ¦   +-- start.S
¦
+-- board           # ?????????????
+-- cmd             # ????, ??????????????????
+-- common          # ??????, ??????
¦   +-- spl/        # Second Program Loader, ?????? uboot ??
¦   +-- main.c
¦
+-- configs         # ????????????????
+-- disk            # ? disk ??????????(e.g. disk partition), ?????????
+-- doc             # ??, ??README?????
+-- Documentation
+-- drivers         # ????? device drivers ?????
+-- dts             # device tree ??
+-- env
+-- examples
+-- fs              # ????, ???????????????
+-- include         # ????, ??????????
+-- lib             # ?????
+-- net             # ????????, BOOTP ??, TFTP, RARP ??? NFS???????.
+-- post            # Power On Self Test
+-- scripts
+-- test
+-- tmp
+-- tools           # ????, ???????uboot????

```

+ the layer of directory

    ```
                    arch
                      |
                      v
                board/include
                      |
                      v
            common/cmd/lib/api
                      |
                      v
        drivers/fs/disk/net/dts/post

    _______ support class __________

            doc/tools/examples

    ```

# Flow Chart


# eMMC

## Normal partitions

??? eMMC ?????????, ?? BOOT, RPMB ? UDA ????????, gpp ????????.

```
    eMMC
    +--------------------------------+
    | Boot Area partition 1          |  \
    +--------------------------------+   BOOT
    | Boot Area partition 2          |  /
    +--------------------------------+
    | Replay Protected Memory Block  |   RPMB
    +--------------------------------+
    | General Purpose partition 1    |  \
    +--------------------------------+   |
    | General Purpose partition 2    |   |
    +--------------------------------+   GPP
    | General Purpose partition 3    |   |
    +--------------------------------+   |
    | General Purpose partition 4    |  /
    +--------------------------------+
    | User Data area                 |   UDA
    +--------------------------------+

```

+ BOOT
    > ??? eMMC ????

    - BOOT ???????? bootloader ????????,
    ?????????????, ?? kernel ?????? read-only

        1. ? kerel ?? `rd/wr`

            ```shell
            $ echo 0 > /sys/block/mmcblk0boot1/force_ro # enable write (force read-only)
            $ echo 1 > /sys/block/mmcblk0boot1/force_ro # disable write
            ```

+ RPMB
    > ?? HMAC SHA-256 ? Write Counter ?????? RPMB ???????????.
    ??????, RPMB ???????????????, ??????, ??????????.


+ GPP
    > ??????????????.
    General Purpose Partition ????, ???????,
    ?????????, ????.

+ UDA
    > ????????, ??????????????, ???????? file system.
    ?? Android ???, ???????? boot?system?userdata ???.

## Manually partition

uboot ??? boot ?????? `CONFIG_SUPPORT_EMMC_BOOT`

```
Device Drivers > MMC Host controller Support > Support some additional features of the eMMC boot partitions
Symbol: SUPPORT_EMMC_BOOT
```

If U-Boot has been built with `CONFIG_SUPPORT_EMMC_BOOT` some additional mmc commands are available:

```
mmc bootbus <boot_bus_width> <reset_boot_bus_width> <boot_mode>
mmc bootpart-resize
mmc partconf <boot_ack>     # set PARTITION_CONFIG field
mmc rst-function            # change RST_n_FUNCTION field between 0|1|2 (write-once)
```

+ switch partition of eMMC
    > ????? UDA, ? eMMC ???????????.
    ????? boot ???? switch partition

+ mmc commands
    > U-Boot provides access to eMMC devices through the `mmc` command and interface
    but adds an additional argument to the mmc interface to describe the hardware partition.

    ```
    # uboot ????? emmc ???
    uboot=> mmc list
    FSL_SDHC: 0
    FSL_SDHC: 1
    FSL_SDHC: 2 (eMMC)

    # ?? emmc ????2
    # ?? emmc ??
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

    # ?? emmc ?????, ??? partconf ????????????.
    # '2' ? emmc ???, ????????????, ????? BOOT_PARTITION_ENABLE ??. ?? 0 ?? disable.
    uboot=> mmc partconf 2 0 0 0

    # ????? '7' ??? UDA ??, 0 ? 7 ?????, ??????????????.
    uboot=> mmc partconf 2 0 7 0
    ```

    - `mmc read [addr] [blk#] [cnt]`
        > read `[cnt]` blocks from the `[blk#]-th` in flash to system memory `[addr]`
        > + `[addr]` is system buffer memory (DDR)
        > + `[blk#]` is the block order of flash
        > + `[cnt]`  is the block count of flash

    - `mmc write addr blk# cnt`
        > write `[cnt]` blocks from system memory `[addr]` to the `[blk#]-th` in flash
        > + `[addr]` is system buffer memory (DDR)
        > + `[blk#]` is the block order of flash
        > + `[cnt]`  is the block count of flash

    - `mmc erase blk# cnt`
        > erase `[cnt]` blocks from the `[blk#]-th` in flash

    - `PARTITION_CONFIG`
        > ????, eMMC controller ???? `PARTITION_CONFIG` register,
        ???? partitions ??
        >> ?? `mmc partconf dev boot_ack boot_partition partition_access`
        ????? H/w register

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

    - `mmc dev [dev] [part]`
        > The interface is therefore described as `mmc` where `[dev]` is the mmc device (some boards have more than one)
        and `[part]` is the hardware partition: 0=user, 1=boot0, 2=boot1.

        ```shell
        # Use the mmc dev command to specify the device and partition:
        => mmc dev 0 0     # select user hw partition
        => mmc dev 0 1     # select boot0 hw partition
        => mmc dev 0 2     # select boot1 hw partition
        ```

    - `mmc partconf`
        > The `mmc partconf` command can be used to configure the `PARTITION_CONFIG` specifying
        what hardware partition to boot from:

        ```
        # uboot console
        => mmc partconf 0 0 0 0     # disable boot partition (default unset condition; boots from user partition)
        => mmc partconf 0 1 1 0     # set boot0 partition (with ack)
        => mmc partconf 0 1 2 0     # set boot1 partition (with ack)
        => mmc partconf 0 1 7 0     # set user partition (with ack)
        ```

    - `mmc rpmb`
        > If U-Boot has been built with `CONFIG_SUPPORT_EMMC_RPMB` the mmc rpmb command is available
        for reading, writing and programming the key for the RPMB partition in eMMC.

    - When using U-Boot to write to eMMC (or microSD) it is often useful to use the `gzwrite` command.
    For example if you have a compressed **disk image**,
    you can write it to your eMMC (assuming it is mmc dev 0) with:

    ```
    => tftpboot ${loadaddr} disk-image.gz && gzwrite mmc 0 ${loadaddr} ${filesize}
    ```

        1. The `disk-image.gz` contains a partition table at `offset 0x0` as well as partitions
        at their respective offsets (according to the partition table) and has been compressed with gzip.

        1. If you know the flash offset of a specific partition
        (which you can determine using the part list mmc 0 command)
        you can also use `gzwrite` to flash a compressed partition image.



# Build u-boot

```shell
export ARCH=arm
export CROSS_COMPILE=arm-none-eabi-

# time make imx6dl_icore_nand_defconfig     # ??????
make imx6dl_icore_nand_defconfig
make

make cscope
```

+ dependency

    ```
    $ sudo apt-get install git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev libc6-dev lib32ncurses5-dev gcc-multilib libx11-dev lib32z1-dev libgl1-mesa-dev

    $ sudo apt-get install device-tree-compiler
    ```

## target board example

+ load uboot with development mode
    > this development mode is H/w pins control.
    this mode will load executable file to `SRAM` and then run.

    - power on and type `4` to enter XMODEM mode
    - load `boot_spl_dbg.bin` with TaraTerm
        > file -> transfer -> XMODEM -> Send -> select `boot_spl_dbg.bin`
    - type `1` (select UART loading)
    - load `u-boot.bin` to run active u-boot image


# MISC

## environment bootargs of u-boot

?? default environment variables

```c
// at u-boot/include/configs/xxx.h

#define CONFIG_EXTRA_ENV_SETTINGS   "...."
```

## linux ??? boot partition

```
$ /dev/mmcblk0boot1
```
## FAT ????????????

+ `fatinfo`
    > ????mmc??????????????.
    >> ???????, `<interface>` ????????, ?? mmc,
    `[<dev[:part]>]`?? dev ?????????, part ?????????

    ```
    => fatinfo
        fatinfo - print information about filesystem

        Usage:
        fatinfo <interface> [<dev[:part]>]
            - print information about filesystem from 'dev' on 'interface'

    => mmc list
    FSL_SDHC: 0 (SD)
    FSL_SDHC: 1
    => fatinfo mmc 0:1      # ?? sd ?? partition 1 ???????
    ```


+ reference
    - [Uboot??????](https://www.cnblogs.com/Cqlismy/p/12214305.html)


# simulation environment

+ ?????? SD? image

```
# bs: block size= 512/1M
$ dd if=/dev/zero of=uboot.disk bs=512 count=1024
```

    - ?? GPT ??
        > ?????????, ?????? kernel ????, ????? rootfs

        ```
        $ sgdisk -n 0:0:+10M -c 0:kernel uboot.disk
        $ sgdisk -n 0:0:0 -c 0:rootfs uboot.disk
        ```

        1. ????

        ```
        $ sgdisk -p uboot.disk
            Disk uboot.disk: 2097152 sectors, 1024.0 MiB
            Sector size (logical): 512 bytes
            Disk identifier (GUID): 04963A5B-34CF-4DEE-B610-F40257C45F6D
            Partition table holds up to 128 entries
            Main partition table begins at sector 2 and ends at sector 33
            First usable sector is 34, last usable sector is 2097118
            Partitions will be aligned on 2048-sector boundaries
            Total free space is 2014 sectors (1007.0 KiB)

            Number Start (sector) End (sector) Size Code Name
               1 2048 22527 10.0 MiB 8300 kernel
               2 22528 2097118 1013.0 MiB 8300 rootfs
        ```

+ build uboot

```
ca9x4_ct_vxp
```

+ run qemu

```
$ vi ./z_qemu.sh
    #!/bin/bash
    set -e

    uboot_image=u-boot

    qemu-system-arm \
        -M vexpress-a9 \
        -m 256M \
        -smp 1 \
        -nographic \
        -kernel ${uboot_image} \
        -sd ./uboot.disk
```

# reference

+ [Zero u-boot???????](https://licheezero.readthedocs.io/zh/latest/%E8%B4%A1%E7%8C%AE/article%204.html)
+ [*** u-boot ????? (2020 ?)](http://pominglee.blogspot.com/2016/11/u-boot-2016_15.html)
+ [***Linux?Uboot?eMMC boot????](https://blog.csdn.net/z1026544682/article/details/99965642)
+ [eMMC ??](https://linux.codingbelief.com/zh/storage/flash_memory/emmc/)
+ [eMMC ?? 3:????](http://www.wowotech.net/basic_tech/emmc_partitions.html)
+ [***?QEMU????uboot?SD???Linux](https://www.cnblogs.com/pengdonglin137/p/12194548.html)

+ [???? uboot???????(EMMC)?? fdisk??](https://topic.alibabacloud.com/tc/a/samsung-company-uboot-mode-change-partition-emmc-size-fdisk-command_8_8_10262641.html)
    - [uboot_tiny4412](https://github.com/friendlyarm/uboot_tiny4412)




+ [Linux MMC???????](https://my.oschina.net/u/4399347/blog/3275069)
+ [eMMC????](http://blog.sina.com.cn/s/blog_5c401a150101jcos.html)
+ [emmc boot1 boot2 partition](https://www.twblogs.net/a/5d2ca04dbd9eee1e5c84c0e4)
+ [u-boot v2018.01 ??????](file:///D:/msys64/home/wl.hsu/test/bootloader/uboot/u-boot%20v2018.01%20%E5%95%93%E5%8B%95%E6%B5%81%E7%A8%8B%E5%88%86%E6%9E%90.html)



+ [?Linux ?????????,  ??????, ??????, ??dd ?SD???????](https://www.cnblogs.com/chenfulin5/p/6649801.html)


+ [emmc??????](https://blog.csdn.net/shalan88/article/details/92774956)

