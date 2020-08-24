Partition of file system
---

# Definition

+ `MBR` (Master Boot Record)
    > 主開機記錄, IBM 在 1983 年提出的分割表格式.
    MBR 只支援最大 **4 個主分割區** 或是 **3 個主分割區 + 1 個擴展分區**

+ `GPT` (GUID Partition Table)
    > GUID 磁碟分割表格, 即**全域唯一標識磁碟分割表格**.
    GPT 是逐漸取代 MBR新標準, GPT使用了更加現代的技術取代了老舊的 MBR磁碟分割表格,
    其優勢有:
    > + 突破了 2.2T 最大容量的限制
    > + 允許無限數量的分割區
    > + GPT 在磁片上存儲了這些資料的多個副本, 可以在資料損壞的情況下進行恢復

+ `LBA` (Logic Block Address)
    > 原則上大小相當於傳統 MBR 分區中的一個 sector.
    但有些儲存裝置的一個讀寫單元是 **2KB** 或 **4KB**, 則 LBA 的大小也跟著改變

    > GPT 分區為了兼容傳統的MBR分區, 其第一個邏輯塊數據格式與MBR分區一致, 即第一個邏輯塊就是 MBR(主引導記錄).
    但為了與傳統的 MBR 分區進行區分, GPT分區的分區類型為 `EE`, 在傳統的 MBR中, `EE` 類型的分區表示保護類型, GPT 以此來防止其數據被無意間篡改.


# Concept

```
    --------------------------------------------------
    LBA 0          |Protective MBR                   |
    ----------------------------------------------------------
    LBA 1          |Primary GPT Header               | Primary
    -------------------------------------------------- GPT
    LBA 2          |Entry 1|Entry 2| Entry 3| Entry 4|
    --------------------------------------------------
    LBA 3          |Entries 5 - 128                  |
                   |                                 |
                   |                                 |
    ----------------------------------------------------------
    LBA 34         |Partition 1                      |
                   |                                 |
                   -----------------------------------
                   |Partition 2                      |
                   |                                 |
                   -----------------------------------
                   |Partition n                      |
                   |                                 |
    ----------------------------------------------------------
    LBA -34        |Entry 1|Entry 2| Entry 3| Entry 4| Backup
    -------------------------------------------------- GPT
    LBA -33        |Entries 5 - 128                  |
                   |                                 |
                   |                                 |
    LBA -2         |                                 |
    --------------------------------------------------
    LBA -1         |Backup GPT Header                |
    ----------------------------------------------------------
```

+ LBA 0
    > 和傳統MBR分區一樣, 仍然為主引導記錄

+ LBA 1
    > 稱之為**主分區頭**

+ LBA 2 ~ 33
    > 共32個 sectors, 我們稱之為**主分區節點**

+ LBA -1 (最後一個 sector)
    > 稱之為**備份分區頭**, 它就是**主分區頭**的一個備份

+ LBA -2 ~ -33
    > 共計32個扇區, 我們稱之為**備份分區節點**, 它就是**主分區節點**的一個備份

+ LBA 34 ~ -34
    > 正常的 GPT 分區內容, 文件系統(e.g.FAT, NTFS, EXT等)就是構建在這裡面.



# tools

`MBR partition table` 請使用 fdisk 分割, `GPT partition table` 請使用 gdisk 分割

+ `fdisk`

    ```
    $ fdisk ./uboot.disk

        Welcome to fdisk (util-linux 2.31.1).
        Changes will remain in memory only, until you decide to write them.
        Be careful before using the write command.

        Device does not contain a recognized partition table.
        Created a new DOS disklabel with disk identifier 0x4f9d3825.

        Command (m for help): m     <======= type 'm'

        Help:

          DOS (MBR)
           a   toggle a bootable flag
           b   edit nested BSD disklabel
           c   toggle the dos compatibility flag

          Generic
           d   delete a partition
           F   list free unpartitioned space
           l   list known partition types
           n   add a new partition          <==== create a new partition
           p   print the partition table
           t   change a partition type
           v   verify the partition table
           i   print information about a partition

          Misc
           m   print this menu
           u   change display/entry units
           x   extra functionality (experts only)

          Script
           I   load disk layout from sfdisk script file
           O   dump disk layout to sfdisk script file

          Save & Exit
           w   write table to disk and exit <====== save to partition table of MBR
           q   quit without saving changes  <====== leave

          Create a new label
           g   create a new empty GPT partition table
           G   create a new empty SGI (IRIX) partition table
           o   create a new empty DOS partition table
           s   create a new empty Sun partition table


        Command (m for help): n             <====== create partition
        Partition type
           p   primary (0 primary, 0 extended, 4 free)
           e   extended (container for logical partitions)
        Select (default p): p               <====== use primary partition
        Partition number (1-4, default 1): 1
        First sector (2048-131071, default 2048):
        Last sector, +sectors or +size{K,M,G,T,P} (2048-131071, default 131071): +32M   <=== 0~32MBytes

        Created a new partition 1 of type 'Linux' and of size 32 MiB.

        Command (m for help): p             <====== print the partition table
        Disk ./uboot.disk: 64 MiB, 67108864 bytes, 131072 sectors
        Units: sectors of 1 * 512 = 512 bytes
        Sector size (logical/physical): 512 bytes / 512 bytes
        I/O size (minimum/optimal): 512 bytes / 512 bytes
        Disklabel type: dos
        Disk identifier: 0xe7b22625

        Device        Boot Start   End Sectors Size Id Type
        ./uboot.disk1       2048 67583   65536  32M 83 Linux

        Command (m for help): w             <====== save to partition table
        Command (m for help): q
    ```

    - list partition table

        ```
        $ fdisk -l ./uboot.disk
            Disk ./uboot.disk: 64 MiB, 67108864 bytes, 131072 sectors
            Units: sectors of 1 * 512 = 512 bytes
            Sector size (logical/physical): 512 bytes / 512 bytes
            I/O size (minimum/optimal): 512 bytes / 512 bytes
            Disklabel type: dos
            Disk identifier: 0xe7b22625

            Device        Boot Start   End Sectors Size Id Type
            ./uboot.disk1       2048 67583   65536  32M 83 Linux
        ```


+ `sgdisk`
    > sgdisk is the command-line version and gdisk is the text-mode interactive version

    - create partition

        ```
        $ sgdisk -n 0:0:+10M ./disk.img
            -n 創建一個分區,
                -n後的參數分別是: 分區號:起始地址:終止地址
                分區號如果為0, 代表使用第一個可用的分區號;
                起始地址和終止地址可以為 0, 0 代表第一個可用地址和最後一個可用地址;
                起始地址和終止地址可以為 +/-xxx, 代表偏移量,
                +代表在起始地址後的xxx地址, -代表在終止地址前的xxx地址;
        ```

# uboot

+ `gpt write`
    > restore GUID partition table.

    > enable option
    >> `Command line interface`
        -> `Device access commands`
            -> `GPT (GUID Partition Table) command` and `GPT Random UUID generation`

    >> `Partition Types`
        -> `Enable support of GUID for partition type` and `Enable Partition Labels (disklabels) support`

    -  Some strings of `type` can be also used at the place of known GUID

        ```
        "system" = PARTITION_SYSTEM_GUID        (C12A7328-F81F-11D2-BA4B-00A0C93EC93B)
        "mbr"    = LEGACY_MBR_PARTITION_GUID    (024DEE41-33E7-11D3-9D69-0008C781F39F)
        "msft"   = PARTITION_MSFT_RESERVED_GUID (E3C9E316-0B5C-4DB8-817D-F92DF00215AE)
        "data"   = PARTITION_BASIC_DATA_GUID    (EBD0A0A2-B9E5-4433-87C0-68B6B72699C7)
        "linux"  = PARTITION_LINUX_FILE_SYSTEM_DATA_GUID    (0FC63DAF-8483-4772-8E79-3D69D8477DE4)
        "raid"   = PARTITION_LINUX_RAID_GUID    (A19D880F-05FC-4D3B-A006-743F0F84911E)
        "swap"   = PARTITION_LINUX_SWAP_GUID    (0657FD6D-A4AB-43C4-84E5-0933C84B4F4F)
        "lvm"    = PARTITION_LINUX_LVM_GUID     (E6D6D379-F507-44C2-A23C-238F2A3DF928)
        ```

    -  `size` is partition size, and `-` means auto extend

        ```
        size=-
        size=512K
        size=512KB
        size=512KiB
        ```
    - `uuid`
        > if `GPT Random UUID generation` is not enable,
        you should set `uuid=...` by self

    - command line

        ```
        # set partition-table to global variable 'partitions'
        => env set partitions name=rootfs,size=-,type=system
            or
        => env set partitions "name=bbb,size=1MB,type=data;name=misc,size=4M,type=data;"

        => gpt write mmc 0 $partitions
            Writing GPT: success!
        ```
    - in u-boot's source code

        1. script

            ```c
            // include/configs/kylin_rk3036.h
            #define PARTS_DEFAULT \
                    "uuid_disk=${uuid_gpt_disk};" \
            ...

            #undef CONFIG_EXTRA_ENV_SETTINGS
            #define CONFIG_EXTRA_ENV_SETTINGS \
                    "partitions=" PARTS_DEFAULT \
            ```

        1. source flow

            ```c
            #ifdef CONFIG_FASTBOOT_FLASH_MMC_DEV
                if (strncmp("format", cmd + 4, 6) == 0) {
                    char cmdbuf[32];
                    sprintf(cmdbuf, "gpt write mmc %x $partitions",
                            CONFIG_FASTBOOT_FLASH_MMC_DEV);
                    if (run_command(cmdbuf, 0))
                        fastboot_tx_write_str("FAIL");
                    else
                        fastboot_tx_write_str("OKAY");
                } else
            #endif
                {
                    ...
                }
            ```

# reference

+ uboot/doc/README.gpt
+ [J6 Android eMMC 分區介紹](https://blog.csdn.net/cross_cross/article/details/79382626)
+ [C language reads GPT partition information](https://www.programmersought.com/article/9275766390/#_21)
+ [GPT分區數據格式分析(圖已補上)](https://blog.csdn.net/diaoxuesong/article/details/9406015)
+ MBR
    - [CPTS_360-LAB1](https://github.com/Yatin-Singla/CPTS_360-LAB1)
    - [parseMbr](https://github.com/firebroo/parseMbr)

+ debugfs
    - [Linux下的 DebugFs(基礎)](https://cuteparrot.pixnet.net/blog/post/206885452-linux%E4%B8%8B%E7%9A%84-debugfs-%28%E5%9F%BA%E7%A4%8E%29)

+ 磁盤管理
    - [Linux入門之磁盤管理與inode表和group表詳解(CentOS)](https://blog.csdn.net/qq_42452450/article/details/105014057)
