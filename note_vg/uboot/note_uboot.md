u-boot
---

[u-boot source code](ftp://ftp.denx.de/pub/u-boot/)

the version is `201907` or `latest`

# uboot directory

```
├── api             # 存放 uboot 提供的 API 接口函數
├── arch            # 與 CPU 結構相關的程式碼
│   ├── arm/
│   │   ├── cpu/
│   │   │   ├── armv7/
│   │   │   │   ├── start.S
│
├── board           # 根據不同開發板定製的程式碼
├── cmd             # 顧名思義, 大部分的命令的實現都在這個文件夾下面
├── common          # 通用的程式碼, 涵蓋各個方面
│   ├── spl/        # Second Program Loader, 即相當於二級 uboot 啟動
│   ├── main.c
│
├── configs         # 各個板子的對應的配置文件都在裡面
├── disk            # 對 disk 一些操作相關的程式碼(e.g. disk partition), 都在這個文件夾裡面
├── doc             # 文件, 一堆README開頭的檔案
├── Documentation
├── drivers         # 各式各樣的 device drivers 都在這裡面
├── dts             # device tree 配置
├── env
├── examples
├── fs              # 檔案系統, 支援嵌入式開發板常見的檔案系統
├── include         # 標頭檔案, 已通用的標頭檔案為主
├── lib             # 通用庫檔案
├── net             # 與網路有關的代碼, BOOTP 協議, TFTP, RARP 協議和 NFS檔案系統的實現.
├── post            # Power On Self Test
├── scripts
├── test
├── tmp
├── tools           # 輔助程式, 用於編譯和檢查uboot目標檔案

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

大部分 eMMC 都有類似如下的分區, 其中 BOOT, RPMB 和 UDA 一般是默認存在的, gpp 分區需要手動創建.

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
    > 支持從 eMMC 啟動系統

    - BOOT 區中一般存放的是 bootloader 或者相關配置參數,
    這些參數一般是不允許修改的, 所以 kernel 默認情況下是 read-only

        1. 從 kerel 開關 `rd/wr`

            ```shell
            $ echo 0 > /sys/block/mmcblk0boot1/force_ro # enable write (force read-only)
            $ echo 1 > /sys/block/mmcblk0boot1/force_ro # disable write
            ```

+ RPMB
    > 通過 HMAC SHA-256 和 Write Counter 來保證保存在 RPMB 內部的數據不被非法篡改.
    在實際應用中, RPMB 分區通常用來保存安全相關的數據, 例如指紋數據, 安全支付相關的密鑰等.


+ GPP
    > 主要用於存儲系統或者用戶數據.
    General Purpose Partition 在出廠時, 通常是不存在的,
    需要主動進行配置後, 才會存在.

+ UDA
    > 通常會進行再分區, 然後根據不同目的存放相關數據, 或者格式化成不同 file system.
    例如 Android 系統中, 通常在此區域分出 boot、system、userdata 等分區.

## Manually partition

uboot 下操作 boot 分區需要打開 `CONFIG_SUPPORT_EMMC_BOOT`

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
    > 默認分區是 UDA, 而 eMMC 每個分區都是獨立編址的.
    所以要使用 boot 分區需要 switch partition

+ mmc commands
    > U-Boot provides access to eMMC devices through the `mmc` command and interface
    but adds an additional argument to the mmc interface to describe the hardware partition.

    ```
    # uboot 中首先查看 emmc 的編號
    uboot=> mmc list
    FSL_SDHC: 0
    FSL_SDHC: 1
    FSL_SDHC: 2 (eMMC)

    # 確定 emmc 的序號是2
    # 查看 emmc 命令
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

    # 設置 emmc 的啟動分區, 主要是 partconf 後面的第一個和第三個參數.
    # '2' 是 emmc 的編號, 第三個參數設置啟動的分區, 對應寄存器 BOOT_PARTITION_ENABLE 字段. 設為 0 表示 disable.
    uboot=> mmc partconf 2 0 0 0

    # 或者設置為 '7' 表示從 UDA 啟動, 0 和 7 我都嘗試了, 燒錄原來的鏡像都能夠啟動成功.
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

# time make imx6dl_icore_nand_defconfig     # 紀錄編譯時間
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


## ext2/ext3 file system

ext2 和 ext3 格式是完全相同的, 只是 ext3 file system 會在硬碟分區的最後面,
留出一塊磁碟空間來存放日誌(Journal)記錄

在 ext2 file system 上, 當要向硬碟中寫入數據時, 系統並不是立即將這些數據寫到硬碟上,
而是先將這些數據寫到數據緩衝區中(內存), 當數據緩衝區寫滿時, 這些數據才會被寫到硬碟中.

在 ext3 file system 上, 當要向硬碟中寫入數據時, 系統同樣先將這些數據寫到數據緩衝區.
當緩衝區寫滿時, 在數據被寫入硬碟之前, 系統要先通知日誌,
現在要開始向硬碟中寫入數據(即向日誌中寫入一些信息), 之後才會將數據寫入硬碟中.
當數據寫入硬碟之後, 系統會再次通知日誌數據已經寫入硬碟.


### Definition

+ sector (扇區)
    > physical 最小單位, 一般 default 是 `512 bytes`


### Concept

FAT physical structure

```
+-----------------+
| Boot Block      |                 Block group
+-----------------+ ---------> +-------------------+
| Block group 1   |            | Superblock        |
+-----------------+ ---+       +-------------------+
| Block group 2   |    |       | Group Description |
+-----------------+    |       +-------------------+
| Block group ... |    |       | Block bitmap      |
+-----------------+    |       +-------------------+
                       |       | Inode bitmap      |
                       |       +-------------------+
                       |       | Inode table       |
                       |       +-------------------+
                       |       |   Data            |
                       |       |   Blocks          |
                       +-----> +-------------------+
```

+ Block
    > 邏輯塊.
    對於 ext2 file system 來說, 硬盤分區首先被分割為一個一個的邏輯塊(Block),
    每個 Block 就是實際用來存儲數據的單元, 大小相同並從 `0` 開始順序進行編號, 第一個 Block 的編號為 `0`.
    ext2 file system 支持的 Block 的大小有 `1024/2048/4096 bytes`, Block 的大小在創建文件系統的時候可以通過參數指定.
    如果不指定, 則會從 `/etc/mke2fs.conf` 文件中讀取對應的值; 原則上, Block 的大小與數量在格式化後就不能夠發生改變了.

    > 每個 Block 內最多只會存放一個文件的數據(即不會出現兩個文件的數據被放入同一個 Block 的情況),
    如果文件大小超過了一個 Block 的 size, 則會佔用多個 Block 來存放文件,
    如果文件小於一個 Block 的 size, 則這個 Block 剩餘的空間就浪費掉了.

    ```shell
    # 可以使用 dumpe2fs 命令查看 Block 的大小
    $ sudo dumpe2fs /dev/sda1 | grep "Block size:"
    ```

+ Boot Block
    > 每個 disk partition 的開頭 `1024-bytes` 大小都預留為分區的啟動 sector,
    存放引導程序和數據, 所以又叫引導塊.
    引導塊在第一個 Block, 即 `Block 0` 中存放, 但是未必佔滿這個 Block, 原因是 Block 的大小可能大於 1024 bytes.

    > 這裡是存放開機管理程序的地方, 這是個非常重要的設計.
    因為這樣使得我們能夠把不同的開機管理程序, 安裝到每個文件系統的最前端,
    而不用覆蓋整顆磁盤唯一的 MBR, 這樣就能支持多系統啟動了.

+ Block Group
    > Block 在邏輯上被劃分為多個 Block Group, 每個 Block Group 包含的 Block 數量相同,
    具體是在 `SuperBlock` 中通過 `s_block_per_group` 屬性定義的.
    >> 最後一個 Block Group 除外, 最後剩下的 Block 數量可能小於 `s_block_per_group`,
    這些 Block 會被劃分到最後一個 Block Group 中.

    - example

        ```
        $ sudo dumpe2fs /dev/sda1
            ...
            Group 0: (Blocks 1-8192) [ITABLE_ZEROED]
              Checksum 0xa22b, unused inodes 501
              Primary superblock at 1, Group descriptors at 2-81
              Reserved GDT blocks at 82-337
              Block bitmap at 338 (+337), Inode bitmap at 354 (+353)
              Inode table at 370-497 (+369)
              5761 free blocks, 501 free inodes, 2 directories, 501 unused inodes
              Free blocks: 2432-8192
              Free inodes: 12-512
            Group 1: (Blocks 8193-16384) [INODE_UNINIT, BLOCK_UNINIT, ITABLE_ZEROED]
              Checksum 0xea71, unused inodes 512
              Backup superblock at 8193, Group descriptors at 8194-8273
              Reserved GDT blocks at 8274-8529
              Block bitmap at 339 (bg #0 + 338), Inode bitmap at 355 (bg #0 + 354)
              Inode table at 498-625 (bg #0 + 497)
              7855 free blocks, 512 free inodes, 0 directories, 512 unused inodes
              Free blocks: 8530-16384
              Free inodes: 513-1024
            ...
        ```

        1. Group0 佔用從 `1 ~ 8192` 號的 block.
            > + 其中的 Superblock 則在 `1` 號 block 內.
            > + Group descriptors (文件系統描述說明) 佔用從 `2 ~ 81` 號 block.
            > + Block bitmap 在 `338` 號 block 上.
            > + Inode bitmap 在 `354` 號 block 上.
            > + Inode table 佔用 `370 ~ 497` 號 block.

        1. Group0 當前可用的 block 號為: `2432 ~ 8192`, 可用的 inode 號碼為: `12 ~ 512`

            ```
            Group 內 inode 數量的計算方式:
            一個 inode 佔用 256 Bytes, 每個 block 的大小為 1024 Bytes

            inodes_per_block = 1024 / 256;

            Inode 佔用的 block 數: 497 - 370 + 1 = 128

            total_inodes_per_group = 128 * inodes_per_block = 512
            ```

+ Superblock
    > 記錄整個 filesystem 相關信息的地方, 其實上除了第一個 block group 內會含有 superblock 之外,
    後續的 block group 不一定都包含 superblock, 如果包含,
    也是做為第一個 block group 內 superblock 的備份

    - superblock 記錄的主要信息

        1. `block` 與 `inode` 的總量
        1. 未使用與已使用的 inode/block 數量
        1. block 與 inode 的大小
            > + block: `1/2/4 KB`
            > + inode: `128/256 Bytes`
        1. filesystem 的掛載時間
        1. 最近一次寫入數據的時間
        1. 最近一次檢驗磁盤(fsck)的時間等文件系統的相關信息
        1. 一個 `valid bit` 數值, 若此文件系統已被掛載, 則 `valid bit = 0`, 若未被掛載, 則 `valid bit = 1`

    - Superblock 的大小為 1024 Bytes, 它非常重要, 因為分區上重要的信息都在上面.
    如果 Superblock 掛掉了, partition 上的數據就很難恢復了

        1. Superblock 中的信息

            ```
            $ sudo dumpe2fs -h /dev/sdd1
            ```

+ Group Description
    > 用來描述每個 group 的開始與結束位置的 block 號碼,
    以及說明每個塊(superblock, bitmap, inodemap, datablock)分別介於哪一個 block 號碼之間

+ Block bitmap
    > 查看 block 是否已經被使用了.
    >> 在創建文件時需要為文件分配 blocks, 屆時就會選擇分配空閒的 block 給文件使用.
    通過 block bitmap 可以知道哪些 block 是空的, 因此系統就能夠很快地找到空閒空間來分配給文件.
    同樣的, 在刪除某些文件時, 文件原本佔用的 block 號碼就要釋放出來,
    此時在 block bitmap 當中相對應到該 block 號碼的標誌就需要修改成**空閒**

+ Inode bitmap
    > 記錄的是**使用**與**未使用**的 inode 號

+ Inode table
    > 存放著一個個 inode
    >> inode 的內容, 記錄文件的屬性以及該文件實際數據是放置在哪些 block 內

    - 文件屬性

    - inode 特點
        1. 數量與大小在格式化時就已經固定
        1. 每個 inode 大小均固定為 `128 Bytes`
            > 新的 ext4 為 `256 Bytes`
        1. **每個文件都僅會佔用一個 inode**
        1. file system 能夠創建的文件數量與 inode 的數量相關
        1. 系統讀取文件時需要先找到 inode, 並分析 inode 所記錄的權限與使用者是否符合,
        若符合才能夠開始讀取 block 的內容


+ Data block


### reference

+ [Ext2文件系統簡單剖析(一)](https://www.jianshu.com/p/3355a35e7e0a)
+ [ext2檔案系統](http://shihyu.github.io/books/ch29s02.html)
+ [Linux EXT2 文件系統](https://www.cnblogs.com/sparkdev/p/11212734.html)

## environment bootargs of u-boot

設定 default environment variables

```c
// at u-boot/include/configs/xxx.h

#define CONFIG_EXTRA_ENV_SETTINGS   "...."
```

## linux 切換到 boot partition

```
$ /dev/mmcblk0boot1
```

# simulation environment

+ 生成一個空的 SD卡 image

    ```
    # bs: block size= 512/1024/1M
    $ dd if=/dev/zero of=uboot.disk bs=512 count=1024
        1024+0 records in
        1024+0 records out
        1073741824 bytes (1.1 GB, 1.0 GiB) copied, 1.39208 s, 771 MB/s
    ```

    - 創建 GPT 分區
        > 下面創建了兩個分區, 一個用來存放 kernel 和設備樹, 另一個存放 rootfs

        ```
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

        1. 查看分區

            ```
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

    - host side 操作 SD image file

        1. 尋找一個空閒的 loop 設備

            ```shell
            $ losetup -f
                /dev/loop0
            ```
        1. 將 SD卡 image 映射到 loop 設備上

            ```
            $ sudo losetup /dev/loop0 uboot.disk
            $ sudo partprobe /dev/loop0
            $ ls /dev/loop*   # 看到 '/dev/loop0p1' 和 '/dev/loop0p2' 兩個 devices
                ...
                /dev/loop0p1
                /dev/loop0p2
                ...
            ```

        1. 格式化

            ```
            $ sudo mkfs.fat /dev/loop0p1
            $ sudo mkfs.vfat -F 32 /dev/loop0p1
            ```

        1. mount

            ```
            $ sudo mount -t fat /dev/loop0p1 p1/
            ```
        1. 拷貝文件

            ```
            $ sudo cp linux-4.14.13/arch/arm/boot/zImage p1/
            ```

        1. umount

            ```
            $ sudo umount p1
            $ sudo losetup -d /dev/loop0
            ```

    - uboot side

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

+ build uboot

```
$ vi setting.env
    export ARCH=arm
    export CROSS_COMPILE=arm-linux-gnueabi-
    export PATH=$HOME/gcc-linaro-6.5.0-2018.12-i686_arm-linux-gnueabi/bin:$HOME/.local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

$ source setting.env
$ make vexpress_ca9x4_defconfig
```

+ run qemu

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


# reference

+ [Zero u-boot編譯和使用指南](https://licheezero.readthedocs.io/zh/latest/%E8%B4%A1%E7%8C%AE/article%204.html)
+ [*** u-boot 說明與安裝 (2020 改)](http://pominglee.blogspot.com/2016/11/u-boot-2016_15.html)
+ [***Linux和Uboot下eMMC boot分區讀寫](https://blog.csdn.net/z1026544682/article/details/99965642)
+ [eMMC 簡介](https://linux.codingbelief.com/zh/storage/flash_memory/emmc/)
+ [eMMC 原理 3:分區管理](http://www.wowotech.net/basic_tech/emmc_partitions.html)
+ [***用QEMU模擬運行uboot從SD卡啟動Linux](https://www.cnblogs.com/pengdonglin137/p/12194548.html)

+ [三星公司 uboot模式下更改分區(EMMC)大小 fdisk命令](https://topic.alibabacloud.com/tc/a/samsung-company-uboot-mode-change-partition-emmc-size-fdisk-command_8_8_10262641.html)
    - [uboot_tiny4412](https://github.com/friendlyarm/uboot_tiny4412)




+ [Linux MMC原理及框架詳解](https://my.oschina.net/u/4399347/blog/3275069)
+ [eMMC分區詳解](http://blog.sina.com.cn/s/blog_5c401a150101jcos.html)
+ [emmc boot1 boot2 partition](https://www.twblogs.net/a/5d2ca04dbd9eee1e5c84c0e4)
+ [u-boot v2018.01 啓動流程分析](file:///D:/msys64/home/wl.hsu/test/bootloader/uboot/u-boot%20v2018.01%20%E5%95%93%E5%8B%95%E6%B5%81%E7%A8%8B%E5%88%86%E6%9E%90.html)



+ [在Linux 下製作一個磁盤文件,  可以給他分區, 以及存儲文件, 然後dd 到SD卡便可啟動系統](https://www.cnblogs.com/chenfulin5/p/6649801.html)


+ [emmc啟動分區設置](https://blog.csdn.net/shalan88/article/details/92774956)

