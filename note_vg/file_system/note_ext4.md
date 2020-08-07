ext2/ext3/ext4
---

# ext file system

ext2 和 ext3 格式是完全相同的, 只是 ext3 file system 會在硬碟分區的最後面,
留出一塊磁碟空間來存放日誌(Journal)記錄

在 ext2 file system 上, 當要向硬碟中寫入數據時, 系統並不是立即將這些數據寫到硬碟上,
而是先將這些數據寫到數據緩衝區中(內存), 當數據緩衝區寫滿時, 這些數據才會被寫到硬碟中.

在 ext3 file system 上, 當要向硬碟中寫入數據時, 系統同樣先將這些數據寫到數據緩衝區.
當緩衝區寫滿時, 在數據被寫入硬碟之前, 系統要先通知日誌,
現在要開始向硬碟中寫入數據(即向日誌中寫入一些信息), 之後才會將數據寫入硬碟中.
當數據寫入硬碟之後, 系統會再次通知日誌數據已經寫入硬碟.

+ ext
    > 第一代擴展文件系統, 一種文件系統,
    於1992年4月發表, 是為linux核心所做的第一個文件系統.
    採用 Unix 文件系統(UFS)的元數據結構, 以克服 MINIX 文件系統性能不佳的問題.

    - 特點
        > 它是在linux上, 第一個利用虛擬文件系統實現出的文件系統

    - 優勢
        > 克服 MINIX 文件系統性能不佳的問題

+ ext2
    > 第二代擴展文件系統是 LINUX 內核所用的文件系統.
    它開始由`Rémy Card`設計, 用以代替ext, 於1993年1月加入linux核心支持之中.
    ext2 的經典實現為 LINUX 內核中的 ext2fs 文件系統驅動,
    最大可支持2TB的文件系統, 至linux核心2.6版時, 擴展到可支持32TB

    - 特點
        > 在 ext2 文件系統中, 文件由 inode(包含有文件的所有信息)進行唯一標識.
        一個文件可能對應多個文件名, 只有在所有文件名都被刪除後, 該文件才會被刪除.
        此外, 同一文件在磁盤中存放和被打開時所對應的 inode 是不同的, 並由內核負責同步.

    - 優勢
        > 文件系統高效穩定

+ ext3
    > EXT3 是第三代擴展文件系統(Third extended filesystem, 縮寫為ext3),
    是一個日誌文件系統, 常用於Linux操作系統.

    - 特點
        > Ext3 文件系統是直接從Ext2文件系統發展而來.
        目前ext3文件系統已經非常穩定可靠, 它完全兼容ext2文件系統.
        用戶可以平滑地過渡到一個日誌功能健全的文件系統中來

    - 優勢
        > + 高可用性
        >> 系統使用了 ext3 文件系統後, 即使在非正常關機後, 系統也不需要檢查文件系統.
        > + 數據的完整性
        >> 避免了意外當機對文件系統的破壞.
        > + 文件系統的速度
        >> 因為 ext3 的日誌功能對磁盤的驅動器讀寫頭進行了優化.
        所以, 文件系統的讀寫性能較之 Ext2 文件系統並來說, 性能並沒有降低.
        > + 數據轉換
        >> 由 ext2 文件系統轉換成 ext3 文件系統非常容易
        > + 多種日誌模式

+ ext4
    > EXT4 是第四代擴展文件系統(Fourth extended filesystem, 縮寫為 ext4),
    是 Linux 系統下的日誌文件系統, 是 ext3 文件系統的後繼版本.
    Ext4 是由 Ext3 的維護者 `Theodore Tso` 領導的開發團隊實現的, 並引入到 Linux2.6.19 內核中.

    - 特點
        > Ext4 是 Ext3 的改進版, 修改了 Ext3 中部分重要的數據結構,
        而不僅僅像Ext3對Ext2那樣, 只是增加了一個日誌功能而已.
        Ext4 可以提供更佳的性能和可靠性, 還有更為豐富的功能.

    - 優勢

        1. 與Ext3兼容
            > 執行若干條命令, 就能從 Ext3 在線遷移到Ext4, 而無須重新格式化磁盤或重新安裝系統.

        1. 更大的文件系統和更大的文件
            > 較之 Ext3 目前所支持的最大 16TB 文件系統和最大 2TB 文件,
            Ext4分別支持 1EB (1,048,576TB, 1EB=1024PB, 1PB=1024TB) 的文件系統, 以及 16TB 的文件.

        1. 無限數量的子目錄
            > `Ext3 目前只支持 32,000 個子目錄`, 而 Ext4 支持無限數量的子目錄.

        1. Extents
            > Ext4 引入了現代文件系統中流行的 extents 概念, 每個 extent 為一組連續的數據塊,
            相比Ext3採用間接塊映射, 提高了不少效率.
            >> Ext3 採用間接塊映射, 當操作大文件時, 效率極其低下.
            比如一個 100MB 大小的文件, 在 Ext3 中要建立 25,600 個數據塊(每個數據塊大小為 4KB)的映射表.
            而 Ext4 引入的 extents 概念, 將該文件數據保存在接下來連續的 25,600 個數據塊中, 提高了不少效率

        1. 多塊分配
            > 當寫入數據到 Ext3 文件系統中時, Ext3 的數據塊分配器每次只能分配一個 4KB 的塊,
            寫一個 100MB 文件就要調用 25,600 次數據塊分配器,
            而 Ext4 的多塊分配器 `multiblock allocator (mballoc)` 支持一次調用分配多個數據塊

        1.  延遲分配
            > Ext3 的數據塊分配策略是**盡快分配**, 而 Ext4 和其它現代文件操作系統的策略是**儘可能地延遲分配**,
            直到文件在 cache 中寫完才開始分配數據塊並寫入磁盤, 這樣就能優化整個文件的數據塊分配,
            與前兩種特性搭配起來可以顯著提升性能

        1. 快速 fsck
            > 以前執行 fsck 第一步就會很慢, 因為它要檢查所有的 inode,
            現在 Ext4 給每個組的 inode 表中都添加了一份未使用 inode 的列表,
            今後 fsck Ext4 文件系統就可以跳過它們而只去檢查那些在用的 inode 了.

        1. 日誌校驗
            > 日誌是最常用的部分, 也極易導致磁盤硬件故障, 而從損壞的日誌中恢複數據會導致更多的數據損壞.
            Ext4 的日誌校驗功能可以很方便地判斷日誌數據是否損壞,
            而且它將 Ext3 的兩階段日誌機制合併成一個階段, 在增加安全性的同時提高了性能.

        1. 無日誌 (No Journaling)模式
            > 日誌總歸有一些開銷, Ext4 允許關閉日誌, 以便某些有特殊需求的用戶可以借此提升性能

        1. 在線碎片整理
            > 儘管`延遲分配`, `多塊分配`和 `extents` 能有效減少文件系統碎片, 但碎片還是不可避免會產生.
            Ext4 支持在線碎片整理, 並將提供 e4defrag 工具進行個別文件或整個文件系統的碎片整理

        1.  inode 相關特性
            > Ext4 支持更大的 inode, 較之 Ext3 默認的 inode 大小 `128-bytes`,
            Ext4 為了在 inode 中容納更多的擴展屬性(如 ns 時間戳或 inode 版本), 默認 inode 大小為 `256-bytes`.
            Ext4 還支持快速擴展屬性(fast extended attributes)和 inode 保留(inodes reservation).

        1. 持久預分配(Persistent preallocation)
            > P2P 軟件為了保證下載文件有足夠的空間存放, 常常會預先創建一個與所下載文件大小相同的空文件,
            以免未來的數小時或數天之內磁盤空間不足導致下載失敗.
            Ext4 在文件系統層面實現了持久預分配, 並提供相應的 API (libc 中的 posix_fallocate()),
            比應用軟件自己實現更有效率.

        1. 默認啟用 barrier
            > 磁盤上配有內部緩存, 以便重新調整批量數據的寫操作順序, 優化寫入性能.
            因此文件系統必須在日誌數據寫入磁盤之後才能寫 commit 記錄,
            若 commit 記錄寫入在先, 而日誌有可能損壞, 那麼就會影響數據完整性.
            Ext4 默認啟用 barrier, 只有當 barrier 之前的數據全部寫入磁盤, 才能寫 barrier 之後的數據.
            可通過 `$ mount -o barrier=0` 命令禁用該特性


# Definition

+ sector (扇區)
    > physical 最小單位, 一般 default 是 `512 bytes`


# Concept

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

+ Boot Block (固定 1KB)
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
        1. 文件的讀寫權限(rwx)
        1. 文件的擁有者和所屬組(owner/group)
        1. 文件的容量
        1. 文件的 ctime(創建時間)
        1. 文件的 atime(最近一次的讀取時間)
        1. 文件的 mtime(最近修改的時間)
        1. 文件的特殊標識, 比如 SetUID 等
        1. 文件真正內容的 pointer (指向 data block)

    - inode 特點
        1. 數量與大小在格式化時就已經固定
        1. 每個 inode 大小均固定為 `128 Bytes`
            > 新的 ext4 為 `256 Bytes`
        1. **每個文件都僅會佔用一個 inode**
        1. file system 能夠創建的文件數量與 inode 的數量相關
        1. 系統讀取文件時需要先找到 inode, 並分析 inode 所記錄的權限與使用者是否符合,
        若符合才能夠開始讀取 block 的內容


+ Data block
    > 是用來存放文件內容的地方, Ext2 file system 有 1KB/2KB/4KB 大小的 block.
    在格式化文件系統時 block 的大小就確定了, 並且每個 block 都有編號.
    >> block 大小的差異, 會導致文件系統能夠支持的**最大磁盤容量**和**最大單個文件的大小**並不相同

| block size            | 1KB   | 2KB   | 4KB   |
| :-                    | :-    | :-    | :-    |
| 單一 file最大容量     | 16GB  | 256GB | 2TB   |
| file system 最大容量  | 2TB   | 8TB   | 16TB  |


    1. block 的限制
        > + block 的大小與數量在格式化後就不能再改變了(除非重新格式化)
        > + 每個 block 內最多只能夠放置一個文件的數據
        > + 如果文件大於 block 的大小, 那麼一個文件會佔用多個 block
        > + 若文件小於 block, 則該 block 的剩餘容量也不能再被使用了(磁盤空間被浪費)

# MISC

+ 檢查及修復檔案系統指令

    - `dumpe2fs`
        > 查看這個 partition 中, superblock 和 Group Description Table 中的信息

        ```
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
        Fragment size:            4096
        Group descriptor size:    64
        Blocks per group:         32768
        Fragments per group:      32768
        Inodes per group:         2048
        Inode blocks per group:   64
        Flex block group size:    16
        Filesystem created:       Fri Aug  7 13:37:39 2020
        Last mount time:          n/a
        Last write time:          Fri Aug  7 13:37:39 2020
        Mount count:              0
        Maximum mount count:      -1
        Last checked:             Fri Aug  7 13:37:39 2020
        Check interval:           0 (<none>)
        Lifetime writes:          4201 kB
        Reserved blocks uid:      0 (user root)
        Reserved blocks gid:      0 (group root)
        First inode:              11
        Inode size:               128
        Journal inode:            8
        Default directory hash:   half_md4
        Directory Hash Seed:      ec17a5d8-c569-4a64-aa36-b46c765be24b
        Journal backup:           inode blocks
        Checksum type:            crc32c
        Checksum:                 0x96c542ad
        Journal features:         (none)
        Journal size:             4096k
        Journal length:           1024
        Journal sequence:         0x00000001
        Journal start:            0

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

        ```shell
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

        ```shell
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

        ```shell
        $ hexdump -C fs
            000000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
            *
            000400 80 00 00 00 00 04 00 00 33 00 00 00 da 03 00 00
            000410 75 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00
            ...

        # 其中以'*'開頭的行表示這一段數據全是 0 因此省略了
        ```

# reference

+ [Ext2文件系統簡單剖析(一)](https://www.jianshu.com/p/3355a35e7e0a)
+ [ext2檔案系統](http://shihyu.github.io/books/ch29s02.html)
+ [Linux EXT2 文件系統](https://www.cnblogs.com/sparkdev/p/11212734.html)
+ [The Second Extended File System](http://www.nongnu.org/ext2-doc/ext2.html)
