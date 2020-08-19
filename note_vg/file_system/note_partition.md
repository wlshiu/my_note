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

# reference
+ MBR
    - [CPTS_360-LAB1](https://github.com/Yatin-Singla/CPTS_360-LAB1)
    - [parseMbr](https://github.com/firebroo/parseMbr)

+ debugfs
    - [Linux下的 DebugFs(基礎)](https://cuteparrot.pixnet.net/blog/post/206885452-linux%E4%B8%8B%E7%9A%84-debugfs-%28%E5%9F%BA%E7%A4%8E%29)

