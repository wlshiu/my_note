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

+ sector (扇區)
    > physical 最小單位, 一般 default 是 `512 bytes`

+ block (塊)
    > file system 存取最小單位, 也是從儲存裝置 cache 的最小單位,
    常見的有 1/2/4 KB

+ inode (index node)
    > 實現快速的讀寫和索引.
    假設一個 FCB(file control block) 數據結構大小為 128-Bytes, 盤塊大小 1KB, 則一個盤塊只能放下8個 FCB,
    假設現在有個文件系統含有 640 個文件, 即 640 個 FCB 元素,
    假設磁盤緩存也是 1KB, 系統搜索文件採用順序檢索法(依路徑名匹配),
    則在該文件目錄下用遍歷的方式搜索一個文件, 平均需要啟動磁盤 IO 讀寫 40 次

    > 若將 file name 和文件具體描述信息(大小, owner, 權限等)分離,
    即把文件具體描述信息單獨收編起來, 該數據容器便被稱為 `index node`,
    Linux 系統中的**文件目錄項**只由 file name 和 inode index number 組成, 從而形成高效精簡的搜索目錄

+ dentry (目錄項)
    > 紀錄 current directory下的 file/sub-directory name 及其對應的 inode index

    ```
    the data block of a dentry
    +---------+-------------+
    | name    | inode index |
    +---------+-------------+
    | bin/    | xxxxx       |
    | etc/    | yyyyy       |
    | aaa.txt | zzzzzz      |
    | ...     | ...         |
    +---------+-------------+
    ```

+ indexed allocation (索引式配置)
    > 每個文件都會佔用一個 inode, inode 內則有文件數據放置的 block 號碼.
    當 Linux 下的 ext2 文件系統中創建一個一般文件時,
    ext2 file system 會分配一個 inode 與相對於該文件大小的 data block(一個或多個) 給該文件.
    inode 記錄該文件的權限與屬性, 並記錄分配到的 data block 號碼.
    ex. 假設一個 data block 的大小為 4 KBytes, 而要創建一個 100 Kbytes 的文件,
    linux 就會分配一個 inode 與 25 個data block 來儲存該文件.
    這種數據存取的方法我們稱為索引式文件系統(indexed allocation)


+ inode number
    > 每個檔案對應的 inode number, 是跨 block group 並且連續標號
    >> 從 `1` 開始, ext4 系統**不存在 0 號文件索引**

    - 依文件的 inode number 查找對應的 inode item

        ```
        假設一個檔案的 inode number 為 90612, 且
        Inodes per group = 8192,
        Block size = 4096,
        Inode size = 256

        block_group_idx         = (90612 / 8192) = 11
        inode_itm_idx_in_itable = 90612 - (block_group_idx * 8192) = 500
        inode_total_itms_a_blk  = BlockSize/InodeSize = 4096 / 256 = 16
        blk_idx_in_inode_table  = inode_itm_idx_in_itable / inode_total_itms_a_blk
                                = 31
        inode_itm_offset_in_blk = ((inode_itm_idx_in_itable % inode_total_itms_a_blk) - 1) * 256
                                = 3 * 256 = 768

        phy_blk_idx  = (inode table of Group 11) + blk_idx_in_inode_table = 360481

        第 360481 個 block內, 且 offset 768 bytes

        ```

    - script of dump data

        ```
        $ dd if=/dev/sda2 bs=4096 skip=360481 count=1 2>/dev/null | \
        awk 'BEGIN { LINE=0 } { if (LINE>=(768/16)) print; LINE=LINE+1 }' | xxd
        ```

# Concept

ext fs physical structure

```
+-----------------+
| Block group 0   |         Block group 0       Block group x {x > 0}
+-----------------+     +-------------------+   +--------------------+
| Block group 1   |     | Boot Block (1KB)  |   | Superblock (1KB)   |
+-----------------+     |  (at Block-0)     |   |  (at Block-0)      |
| Block group 2   |     +-------------------+   +--------------------+
+-----------------+     | Superblock (1KB)  |   | Group Description  |
| Block group ... |     |  (at Block-0)     |   |  (at Block-1)      |
+-----------------+     +-------------------+   +--------------------+
                        | Group Description |   | Block bitmap       |
                        | (at Block-1)      |   | (use 1 block)      |
                        +-------------------+   +--------------------+
                        | Block bitmap      |   | Inode bitmap       |
                        | (use 1 block)     |   | (use 1 block)      |
                        +-------------------+   +--------------------+
                        | Inode bitmap      |   | Inode table        |
                        | (use 1 block)     |   |                    |
                        +-------------------+   +--------------------+
                        |   Inode table     |   |   Data             |
                        |                   |   |   Blocks           |
                        +-------------------+   +--------------------+
                        |   Data            |
                        |   Blocks          |
                        +-------------------+
```

+ Block
    > 邏輯塊.
    對於 ext2 file system 來說, 硬盤分區首先被分割為一個一個的邏輯塊(Block),
    每個 Block 就是實際用來存儲數據的單元, 大小相同並從 `0` 開始順序進行編號, 第一個 Block 的編號為 `0`.
    ext2 file system 支持的 Block 的大小有 `1024/2048/4096 bytes`, Block 的大小在創建文件系統的時候可以通過參數指定.
    如果不指定, 則會從 `/etc/mke2fs.conf` 文件中讀取對應的值; 原則上, Block 的大小與數量在格式化後就不能夠發生改變了.

    > `每個 Block 內最多只會存放一個文件的數據(即不會出現兩個文件的數據被放入同一個 Block 的情況)`,
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

+ Superblock (固定 1KB)
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

    - Structure of the super block

        ```c
        struct ext4_super_block {
        /*00*/
            __le32  s_inodes_count;         /* Inodes count文件系統中inode的總數*/
            __le32  s_blocks_count_lo;      /* Blocks count文件系統中塊的總數*/
            __le32  s_r_blocks_count_lo;    /* Reserved blocks count保留塊的總數*/
            __le32  s_free_blocks_count_lo; /*Free blocks count未使用的塊的總數(包括保留塊)*/
        /*10*/
            __le32  s_free_inodes_count;    /* Free inodes count未使用的inode的總數*/
            __le32  s_first_data_block;     /* First Data Block第一塊塊ID, 在小於1KB的文件系統中為0,
                                               大於1KB的文件系統中為1*/
            __le32  s_log_block_size;       /* Block size用以計算塊的大小(1024算術左移該值即為塊大小)(0=1K, 1=2K, 2=4K) */
            __le32  s_obso_log_frag_size;   /* Obsoleted fragment size用以計算段大小(為正則1024算術左移該值, 否則右移)*/
        /*20*/
            __le32  s_blocks_per_group;     /* # Blocks per group每個塊組中塊的總數*/
            __le32  s_obso_frags_per_group; /*Obsoleted fragments per group每個塊組中段的總數*/
            __le32  s_inodes_per_group;     /* # Inodes per group每個塊組中inode的總數*/
            __le32  s_mtime;                /* Mount time POSIX中定義的文件系統裝載時間*/
        /*30*/
            __le32  s_wtime;                /* Write time POSIX中定義的文件系統最近被寫入的時間*/
            __le16  s_mnt_count;            /* Mount count最近一次完整校驗後被裝載的次數*/
            __le16  s_max_mnt_count;        /* Maximal mount count在進行完整校驗前還能被裝載的次數*/
            __le16  s_magic;                /* Magic signature文件系統標誌*/
            __le16  s_state;                /* File system state文件系統的狀態*/
            __le16  s_errors;               /* Behaviour when detectingerrors文件系統發生錯誤時驅動程序應該執行的操作*/
            __le16  s_minor_rev_level;      /* minor revision level局部修訂級別*/
        /*40*/
            __le32  s_lastcheck;            /* time of last check POSIX中定義的文件系統最近一次檢查的時間*/
            __le32  s_checkinterval;        /* max. time between checks POSIX中定義的文件系統最近檢查的最大時間間隔*/
            __le32  s_creator_os;           /* OS生成該文件系統的操作系統*/
            __le32  s_rev_level;            /* Revision level修訂級別*/
        /*50*/
            __le16  s_def_resuid;           /* Default uid for reserved blocks報留塊的默認用戶ID */
            __le16  s_def_resgid;           /* Default gid for reserved blocks保留塊的默認組ID */
            /*
             * These fields are for EXT4_DYNAMIC_REV superblocks only.
             *
             * Note: the difference between the compatible feature set and
             * the incompatible feature set is that if there is a bit set
             * in the incompatible feature set that the kernel doesn't
             * know about, it should refuse to mount the filesystem.
             *
             * e2fsck's requirements are more strict; if it doesn't know
             * about a feature in either the compatible or incompatible
             * feature set, it must abort and not try to meddle with
             * things it doesn't understand...
             */
            __le32  s_first_ino;            /* First non-reserved inode標準文件的第一個可用inode的索引(非動態為11)*/
            __le16  s_inode_size;           /* size of inode structure inode結構的大小(非動態為128)*/
            __le16  s_block_group_nr;       /* block group # of this superblock保存此超級塊的塊組號*/
            __le32  s_feature_compat;       /* compatible feature set兼容特性掩碼*/
        /*60*/
            __le32  s_feature_incompat;     /* incompatible feature set不兼容特性掩碼*/
            __le32  s_feature_ro_compat;    /* readonly-compatible feature set只讀特性掩碼*/
        /*68*/
            __u8    s_uuid[16];             /* 128-bit uuid for volume卷ID, 應儘可能使每個文件系統的格式唯一*/
        /*78*/
            char    s_volume_name[16];      /* volume name卷名(只能為ISO-Latin-1字符集, 以'\0'結束)*/
        /*88*/
            char    s_last_mounted[64];     /* directory where last mounted最近被安裝的目錄*/
        /*C8*/
            __le32  s_algorithm_usage_bitmap;/* For compression文件系統採用的壓縮算法*/
            /*
             * Performance hints.  Directorypreallocation should only
             * happen if the EXT4_FEATURE_COMPAT_DIR_PREALLOC flag is on.
             */
            __u8    s_prealloc_blocks;      /* Nr of blocks to try to preallocate預分配的塊數*/
            __u8    s_prealloc_dir_blocks;  /* Nr topreallocate for dirs給目錄預分配的塊數*/
            __le16  s_reserved_gdt_blocks;  /* Pergroup desc for online growth */
            /*
             * Journaling support valid if EXT4_FEATURE_COMPAT_HAS_JOURNAL set.
             */
        /*D0*/
            __u8    s_journal_uuid[16];     /* uuid of journal superblock日誌超級塊的卷ID */
        /*E0*/
            __le32  s_journal_inum;         /* inode number of journal file日誌文件的inode數目*/
            __le32  s_journal_dev;          /* device number of journal file日誌文件的設備數*/
            __le32  s_last_orphan;          /* start of list of inodes to delete要刪除的inode列表的起始位置*/
            __le32  s_hash_seed[4];         /* HTREE hash seed HTREE散列種子*/
            __u8    s_def_hash_version;     /* Default hash version to use默認使用的散列函數*/
            __u8    s_jnl_backup_type;
            __le16  s_desc_size;            /* size of group descriptor */
        /*100*/
            __le32  s_default_mount_opts;
            __le32  s_first_meta_bg;        /* First metablock block group塊組的第一個元塊*/
            __le32 s_mkfs_time;             /* Whenthe filesystem was created */
            __le32  s_jnl_blocks[17];       /* Backup of the journal inode */
            /* 64bit support valid if EXT4_FEATURE_COMPAT_64BIT */
        /*150*/
            __le32  s_blocks_count_hi;      /* Blocks count */
            __le32  s_r_blocks_count_hi;    /* Reserved blocks count */
            __le32  s_free_blocks_count_hi; /*Free blocks count */
            __le16  s_min_extra_isize;      /* All inodes have at least # bytes */
            __le16  s_want_extra_isize;     /* New inodes should reserve # bytes */
            __le32  s_flags;                /* Miscellaneous flags */
            __le16  s_raid_stride;          /* RAID stride */
            __le16 s_mmp_update_interval;   /* #seconds to wait in MMP checking */
            __le64 s_mmp_block;             /* Blockfor multi-mount protection */
            __le32  s_raid_stripe_width;    /* blocks on all data disks (N*stride)*/
            __u8   s_log_groups_per_flex;   /* FLEX_BGgroup size */
            __u8    s_reserved_char_pad;
            __le16  s_reserved_pad;
            __le64  s_kbytes_written;       /* nr of lifetime kilobytes written */
            __le32  s_snapshot_inum;        /* Inode number of active snapshot */
            __le32  s_snapshot_id;          /* sequential ID of active snapshot*/
            __le64  s_snapshot_r_blocks_count;/* reserved blocks for active
                                                 snapshot's future use */
            __le32  s_snapshot_list;        /* inode number of the head of the
                                               on-disk snapshot list */
        #define EXT4_S_ERR_START offsetof(structext4_super_block, s_error_count)
            __le32  s_error_count;          /* number of fs errors */
            __le32  s_first_error_time;     /* first time an error happened */
            __le32  s_first_error_ino;      /* inode involved in first error */
            __le64  s_first_error_block;    /* block involved of first error */
            __u8    s_first_error_func[32]; /*function where the error happened */
            __le32  s_first_error_line;     /* line number where error happened */
            __le32  s_last_error_time;      /* most recent time of an error */
            __le32  s_last_error_ino;       /* inode involved in last error */
            __le32  s_last_error_line;      /* line number where error happened */
            __le64  s_last_error_block;     /* block involved of last error */
            __u8   s_last_error_func[32];  /*function where the error happened */
        #define EXT4_S_ERR_END offsetof(structext4_super_block, s_mount_opts)
            __u8    s_mount_opts[64];
            __le32  s_reserved[112];        /* Padding to the end of the block */
        };
        ```

+ Group Description (or Block Group Description)
    > 用來描述每個 group 的開始與結束位置的 block 號碼,
    以及說明每個塊(superblock, bitmap, inodemap, datablock)分別介於哪一個 block 號碼之間.

    > Superblock 和 Group Description 會被 copy 到每個 block group 中,
    其中只有 block group 0 中包含的 Superblock 和 Group Description 才被使用,
    這樣當 block group 0 的開頭意外損壞時就可以用其它拷貝來恢復, 從而減少損失.

    - blocks number of GDT

        ```
        # 計算總共有多少個 block group (一個 block group 需要一個 GDT item)
        bgroup_num = partition_block_num / blk_per_group

        # 計算一個 block 可以存幾個 GDT itme
        gdt_items_per_block = blk_size / sblock->s_desc_size # 32 or 64 bytes

        # 計算存所有 GDT items 需要多少個 blocks
        blocks_of_gdt = bgroup_num / gdt_per_block;
        ```

        1. ext2/ext3
            > + GDT 占用 1 Block, 每個 item 大小為 32
        1. ext4
            > + GDT 占用 n Blocks(s_reserved_gdt_blocks member of superblock),
            每個 item 大小為 32 or 64 (s_desc_size member of superblock)

    - structure of a blocks group descriptor

        ```c
        struct ext4_group_desc {
            __le32  bg_block_bitmap_lo;     /* Blocks bitmap block塊位圖所在的第一個塊的塊ID */
            __le32  bg_inode_bitmap_lo;     /* Inodes bitmap block inode位圖所在的第一個塊的塊ID */
            __le32  bg_inode_table_lo;      /* Inodes table block inode表所在的第一個塊的塊ID */
            __le16  bg_free_blocks_count_lo;/*Free blocks count塊組中未使用的塊數*/
            __le16  bg_free_inodes_count_lo;/*Free inodes count塊組中未使用的inode數*/
            __le16 bg_used_dirs_count_lo;  /*Directories count塊組分配的目錄的inode數*/
            __le16  bg_flags;               /* EXT4_BG_flags (INODE_UNINIT,etc) */
            __u32   bg_reserved[2];         /* Likely block/inode bitmap checksum*/
            __le16  bg_itable_unused_lo;    /* Unused inodes count */
            __le16  bg_checksum;            /* crc16(sb_uuid+group+desc) */
            __le32  bg_block_bitmap_hi;     /* Blocks bitmap block MSB */
            __le32  bg_inode_bitmap_hi;     /* Inodes bitmap block MSB */
            __le32  bg_inode_table_hi;      /* Inodes table block MSB */
            __le16  bg_free_blocks_count_hi;/*Free blocks count MSB */
            __le16  bg_free_inodes_count_hi;/*Free inodes count MSB */
            __le16 bg_used_dirs_count_hi;  /*Directories count MSB */
            __le16  bg_itable_unused_hi;    /* Unused inodes count MSB */
            __u32   bg_reserved2[3];
        };
        ```


+ Block bitmap (固定佔一個 block 大小, start at block alignment)
    > 查看 block 是否已經被使用了.
    >> 在創建文件時需要為文件分配 blocks, 屆時就會選擇分配空閒的 block 給文件使用.
    通過 block bitmap 可以知道哪些 block 是空的, 因此系統就能夠很快地找到空閒空間來分配給文件.
    同樣的, 在刪除某些文件時, 文件原本佔用的 block 號碼就要釋放出來,
    此時在 block bitmap 當中相對應到該 block 號碼的標誌就需要修改成**空閒**

+ Inode bitmap (固定佔一個 block 大小, start at block alignment)
    > 記錄的是**使用**與**未使用**的 inode 號

+ Inode table (start at block alignment)
    > 存放著一個個 inode
    >> inode 的內容, 記錄**文件的屬性**以及該**文件實際數據**是放置在哪些 block 內.
    `mke2fs` 格式化工具的默認策略, 是一個 block group 有多少個 `8KB` 就分配多少個 inode

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

    - 1/2/3級 block index 紀錄
        > inode 記錄一個 block 號碼要 `4-byte`.
        假設一個文件有 400MB 且每個 Block = 4KB 時候,
        那麼至少需要 100k blocks, inode 並不可能記錄這麼多信息.
        系統將 inode 記錄 block index 的區域定義為 12 個 direct,
        1 個 singly indirect(一級), 1 個 doubly indirec(二級) 與 1 個 triply indirect (三級)記錄區.
        >> 其中所謂的間接(indirect)就是再拿一個 block 來記錄其他 block indexs 的記錄區;
        如果文件太大時, 就會使用間接的 block 來記錄編號.
        同理如果文件持續長大, 那麼就會利用所謂的雙間接,
        第一個 block 僅再指出下一個記錄編號的 block 在哪裡,
        實際記錄在第二個 block 當中, 以此類推, 三間接就是第三層 block 來記錄編號.

    - inode 本身並不記錄文件名, 只是記錄文件的相關屬性,
    file name 是記錄在目錄所屬的 block 中的

    - Structure of an inode

        ```c
        struct ext4_inode {
            __le16  i_mode;         /* File mode文件格式和訪問權限*/
            __le16  i_uid;          /* Low 16 bits of Owner Uid文件所有者ID的低16位*/
            __le32  i_size_lo;      /* Size in bytes文件字節數*/
            __le32  i_atime;        /* Access time文件上次被訪問的時間*/
            __le32  i_ctime;        /* Inode Change time文件創建時間*/
            __le32  i_mtime;        /* Modification time文件被修改的時間*/
            __le32  i_dtime;        /* Deletion Time文件被刪除的時間（如果存在則為0）*/
            __le16  i_gid;          /* Low 16 bits of Group Id文件所有組ID的低16位*/
            __le16  i_links_count;  /* Links count此inode被連接的次數*/
            __le32  i_blocks_lo;    /* Blocks count文件已使用和保留的總塊數（以512B為單位）*/
            __le32  i_flags;        /* File flags */
            union {
                struct {
                    __le32  l_i_version;
                } linux1;
                struct {
                    __u32  h_i_translator;
                } hurd1;
                struct {
                    __u32  m_i_reserved1;
                } masix1;
            } osd1;                         /*OS dependent 1 */
            __le32  i_block[EXT4_N_BLOCKS];/*Pointers to blocks定位存儲文件的塊的數組*/
            __le32  i_generation;   /* File version (for NFS) 用於NFS的文件版本*/
            __le32  i_file_acl_lo;  /* File ACL包含擴展屬性的塊號, 老版本中為0*/
            __le32  i_size_high;
            __le32  i_obso_faddr;   /* Obsoleted fragment address */
            union {
                struct {
                    __le16  l_i_blocks_high; /* were l_i_reserved1 */
                    __le16  l_i_file_acl_high;
                    __le16  l_i_uid_high;   /* these 2 fields */
                    __le16  l_i_gid_high;   /* were reserved2[0] */
                    __u32   l_i_reserved2;
                } linux2;
                struct {
                    __le16  h_i_reserved1;  /* Obsoleted fragment number/size which areremoved in ext4 */
                    __u16   h_i_mode_high;
                    __u16   h_i_uid_high;
                    __u16   h_i_gid_high;
                    __u32   h_i_author;
                } hurd2;
                struct {
                    __le16  h_i_reserved1;  /* Obsoleted fragment number/size which areremoved in ext4 */
                    __le16  m_i_file_acl_high;
                    __u32   m_i_reserved2[2];
                } masix2;
            } osd2;                         /*OS dependent 2 */
            __le16  i_extra_isize;
            __le16  i_pad1;
            __le32  i_ctime_extra;  /* extra Change time      (nsec << 2 | epoch) */
            __le32  i_mtime_extra;  /* extra Modification time(nsec << 2 |epoch) */
            __le32  i_atime_extra;  /* extra Access time      (nsec << 2 | epoch) */
            __le32  i_crtime;       /* File Creation time */
            __le32  i_crtime_extra; /* extraFileCreationtime (nsec << 2 | epoch) */
            __le32  i_version_hi;   /* high 32 bits for 64-bit version */
        };
        ```

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


+ exampe flow

    - 存一個 hello 的文件

        1. 載入 block group 0 中的GDT, 並從 GDT 中找出 inode bitmap,
        在 inode bitmap 中找出 inode table 中**空的inode**.

        1. 申請一個inode.
            > inode主要包含兩部分內容
            > + 文件屬性(68-Bytes)
            > + 數據塊指針(60-Bytes)
            >> 數據塊指針指向存儲 **hello文件目錄項** 和 ***文件內容**的 Data Block index
        1. 將文件內容和文件的目錄信息分別存在對應的Data Block中
        1. 修改對應的 inode Bitmap 和 Block Bitmap.

    - 給定文件路徑`/home/hello`, 如何找到該文件的位置
        1. 查找根目錄的目錄項.
            > Linux 有規定, **根目錄**的目錄項必須存放在 `2-nd inode` 中.

            ```
            $ ll -di /
                2 dr-xr-xr-x 19 root root 4096 Feb 14 09:32 /
            ```
        1. 根據根目錄的 inode, 找到根目錄的數據實體的 block index,
        可以理解為一個文件到 inode index 的映射表, 找到目錄 `home` 對應的 inode index

            ```
            $ ll -di /home
                786433 drwxr-xr-x 98 root root 12288 Feb 13 17:18 /etc
            ```

        1. 根據目錄 `home` 的 inode, 讀取目錄 `home` 的數據實體 block,
        並找到文件 `hello` 的 inode index

            ```
            $ ll -i /home/hello
                787795 -rw-r--r-- 1 root root 1552 Jan  4 14:56 /home/hello
            ```

        1. 根據 `/home/hello` 文件的 inode, 即可獲取 `/home/hello` 文件的數據實體 block, 完成文件的讀取


    - 刪除 hello 文件
        1. 找到 hello 文件位置
        1. 將 Block Bitmap 中對應 bit 設為 0
        1. 將 inode Bitmap 中對應 bit 設為 0

    - 數據塊(Data block)尋址
        > inode 中的數據塊指針為 `60-bytes`, 每個紀錄參數為 `4-bytes`, 所以有 15 個紀錄參數,
        其中**前 12個**參數用來直接對應 block index, **最後 3個**被用來對應 1/2/3級的間接尋址 block

        ```
        |<- indoe ->|<-----  data blocks ------------------------------------>|

        +-----+                                                      +-------+
        | 0  ------------------------------------------------------->| b + 0 |
        +-----+                                                      +-------+
        | 1  ------------------------------------------------------->| b + 1 |
        +-----+                                                      +-------+
        | ... |                                                      +-------+
        +-----+      +---------------------------------------------->| b + 11|
        | 11 --------+                                               +-------+
        +-----+        +---------+
        | 12 --------->| b + 12  |
        +-----+        |+-------+|                                   +--------+
        | 13 ------+   || inode ------------------------------------>| b + 100|
        +-----+    |   ||  data ||                                   +--------+
        | 14 ---+  |   +---------+
        +-----+ |  |
                |  |   +---------+    +---------+
                |  |   | b + 13  |    | b + 102 |
                |  |   |+-------+|    |+-------+|                    +--------+
                |  +-->|| inode ----->|| inode --------------------->| b + 200|
                |      ||  data ||    ||  data ||                    +--------+
                |      +---------+    +---------+
                |
                |      +---------+    +---------+    +---------+
                |      | b + 14  |    | b + 103 |    | b + 202 |
                |      |+-------+|    |+-------+|    |+-------+|     +--------+
                +----->|| inode ----->|| inode ----->|| inode ------>| b + 300|
                       ||  data ||    ||  data ||    ||  data ||     +--------+
                       +---------+    +---------+    +---------+
        ```

    - directory (目錄)
        > 目錄本質上也是一個文件, 所以當我們在 ext2 文件系統中創建一個目錄時,
        文件系統會分配一個 inode 和至少一塊 data block 給這個目錄(即 dentry, 目錄項).
        其中, inode 記錄該目錄相關的權限與屬性, 並記錄分配到的 data block 號碼

        1. search flow
            > + 先找根目錄 `/` 的 inode (固定在 2-ed inode of inode table)
            > + 藉由 inode 找到對應的 **根目錄 data block**
            > + 從 data block 中的目錄項, 找到對應 file/sub-directory name 的 inode index
            > + 由 inode 找到下一層的目錄項, 如此重複直到找到最後的 file

            ```
                    +----------+    +----------+      +-------------+
                    | inode of |    | inode of |      | inode of    |
                    | root dir |    | sub-dir  |      | target file |
                    +----------+    +----------+      +-------------+
                          |             ^   |            ^
                          |             |   |            |
            inode         |    +--------+   |      +-----+
            table         |    |            |      |
            ______________|____|____________|______|___________________
                          |    |            |      |
            data          |    |            |      |
            block         v    |            v      |
                    +----------|-+        +--------|---+
                    | dentry of  |        | dentry of  |
                    | root dir   |        | sub-dir    |
                    +------------+        +------------+
            ```

        1. Structure of a dir entry

            ```c
            struct ext4_dir_entry {
                __le32  inode;                  /* Inode number文件入口的inode號, 0表示該項未使用*/
                __le16  rec_len;                /* Directory entry length目錄項長度*/
                __le16  name_len;               /* Name length文件名包含的字符數*/
                char    name[EXT4_NAME_LEN];    /* File name文件名*/
            };
            ```

+ Hard link (硬鏈接)

```
$ mkdir my_hard_link    # directory
    or
$ touch my_hard_link    # file

$ ln src_file my_hard_link
$ rm -f my_hard_link
```

    - 在 ext 文件系統中, 允許多個文件名指向同一個 Inode, 這種情況的文件就稱為硬鏈接.
        > 允許一個文件擁有多個有效路徑名(多個入口), 這樣用戶就可以建立硬鏈接到重要的文件, 以防止**誤刪**源數據.
        Hard link 相當於對文件的備份, 但是改變一個文件內容, 會影像其它的文件內容

    - the `link conunt` member in the inode item
        > 當建立 Hard link 時, link count 會增加, 刪除時則會減少.
        當 link count 到 0 時, file system 才會真正回收這個 inode item, 以及其所對應 data block

    - 創建目錄時, 默認會生成兩個目錄項`.`和`..`.
    `.` 的 inode 號碼就是**當前目錄的 inode 號碼**, 等同於**當前目錄的硬鏈接**;
    `..` 的 inode 號碼就是當前目錄的**父目錄的 inode 號碼**, 等同於**父目錄的硬鏈接**.
    所以, 任何一個目錄的**硬鏈接總數**, 總是等於 2 加上它的子目錄總數(含隱藏目錄),
    這裡的 2 是父目錄對其的硬鏈接和當前目錄下 `.` 的硬鏈接


+ Soft link of Symbolic link (符號鏈接)

```
$ mkdir my_soft_link    # directory
    or
$ touch my_soft_link    # file

$ ln -s src_file my_soft_link

# 看 my_soft_link 這個軟鏈接文件是指向哪個文件
$ readlink my_soft_link
```

    > 文件A和文件B的 inode 號碼雖然不一樣, 但是文件A的內容是文件B的路徑.
    讀取文件A時, 系統會自動將訪問者導向文件B.
    因此, 無論打開哪一個文件, 最終讀取的都是文件B.
    >> 由於文件A(文件類型是 l)依賴於文件B而存在, 如果刪除了文件B,
    打開文件A就會報錯`No such file or directory`,
    也因為兩者是不同的 inode, 文件B的 inode `鏈接數`不會發生變化


# MISC

+ 檢查及修復檔案系統指令

    - `dumpe2fs`
        > 查看這個 partition 中, superblock 和 Group Description Table 中的信息

        ```
        # 只看 superblock 上關整個檔案系統的資訊
        $ dumpe2fs -h ./ext4.disk

            or

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

        1. 檔案系統 volume 名稱 (Filesystem volume name)
            > 即是檔案系統標籤 (Filesystem label), 用作簡述該檔案系統的用途或其儲存數據.
            現時 GNU/Linux 都會用 USB 大拇哥/IEEE1394 硬盤等,
            可移除儲存裝置的檔案系統標籤作為其掛載目錄的名稱, 方便使用者識別.
            而個別 GNU/Linux distribution, 如 Fedora, RHEL 和 CentOS 等,
            亦在 fstab 取代傳統裝置檔案名稱 (即 /dev/sda1 和 /dev/hdc5 等) 的指定開機時要掛載的檔案系統,
            避免偶然因為 BIOS 設定或插入次序的改變而引起的混亂.
            可以使用命令 `e2label` 或 `tune2fs -L` 改變.

        1. 上一次掛載於 (Last mounted on)
            > 上一次掛載檔案系統的掛載點路徑, 此欄一般為空, 很少使用.
            可以使用命令 `tune2fs -M` 設定.

        1. 檔案系統 UUID (Filesystem UUID)
            > 一個一般由亂數產生的識別碼, 可以用來識別檔案系統.
            個別 GNU/Linux distribution 如 Ubuntu] 等,
            亦在 fstab 取代傳統裝置檔案名稱 (即 /dev/sda1 和 /dev/hdc5 等) 的指定開機時要掛載的檔案系統,
            避免偶然因為 BIOS 設定或插入次序的改變而引起的混亂.
            可以使用命令 `tune2fs -U` 改變.

        1. Filesystem magic number
            > 用來識別此檔案系統為 Ext2/Ext3/Ext4 的簽名,
            位置在檔案系統的 0x0438 - 0x0439 (Superblock 的 0x38-0x39), 現時必定是 `0xEF53`.

        1. 檔案系統版本編號 (Filesystem revision #)
            > 檔案系統微版本編號, 只可以在格式化時使用 `mke2fs -r` 設定.
            現在只支援:
            > + `0`: 原始格式, Linux 1.2 或以前只支援此格式
            > + `1` (dymanic): V2 格式支援動態 inode 大小 (現時一般都使用此版本)

        1. 檔案系統功能 (Filesystem features)
            > 開啟了的檔案系統功能, 可以使用 `tune2fs -O` 改變.
            現在可以有以下功能:
            > + has_journal
            >> 有日誌 (journal), 亦代表此檔案系統必為 Ext3 或 Ext4
            > + ext_attr
            >> 支援 extended attribute
            > + resize_inode
            >> resize2fs 可以加大檔案系統大小
            > + dir_index
            >> 支援目錄索引, 可以加快在大目錄中搜索檔案.
            > + filetype
            >> 目錄項目為否記錄檔案類型
            > + needs_recovery
            >> e2fsck 檢查 Ext3/Ext4 檔案系統時用來決定是否需要完成日誌紀錄中未完成的工作, 快速自動修復檔案系統
            > + extent
            >> 支援 Ext4 extent 功能, 可以加快檔案系系效能和減少 external fragmentation
            > + flex_bg
            > + sparse_super
            >> 只有少數 superblock 備份, 而不是每個區塊組都有 superblock 備份, 節省空間.
            > + large_file
            >> 支援大於 2GiB 的檔案
            > + huge_file
            > + uninit_bg
            > + dir_nlink
            > + extra_isize
        1. 檔案系統旗號 (Filesystem flags)
            > signed_directory_hash
        1. 預設掛載選項 (Default mount options)
            > 掛載此檔案系統缺省會使用的選項
        1. 檔案系統狀態 (Filesystem state)
            > 可以為
            > + clean (檔案系統已成功地被卸載)
            > + not-clean (表示檔案系統掛載成讀寫模式後, 仍未被卸載)
            > + erroneous (檔案系統被發現有問題)

        1. 錯誤處理方案 (Errors behavior)
            > 檔案系統發生問題時的處理方案, 可以為
            > + continue (繼續正常運作)
            > + remount-ro (重新掛載成只讀模式)
            > + panic (即時當掉系統)

            > 可以使用 `tune2fs -e` 改變.

        1. 作業系統類型 (Filesystem OS type)
            > 建立檔案系統的作業系統, 可以為 Linux/Hurd/MASIX/FreeBSD/Lites
        1. Inode 數目 (Inode count)
            > 檔案系統的總 inode 數目, 亦是整個檔案系統所可能擁有檔案數目的上限

        1. 區塊數目 (Block count)
            > 檔案系統的總區塊數目

        1. 保留區塊數目 (Reserved block count)
            > 保留給系統管理員工作之用的區塊數目

        1. 未使用區塊數目 (Free blocks)
            > 未使用區塊數目
        1. 未使用 inode 數目 (Free inodes)
            > 未使用 inode 數目

        1. 第一個區塊編數 (First block)
            > Superblock 或第一個區塊組開始的區塊編數.
            此值在 1 KiB 區塊大小的檔案系統為 1, 大於1 KiB 區塊大小的檔案系統為 0.

            > 第一個區塊組的 Superblock, 一般都在檔案系統 0x0400 (1024) 開始

        1. 區塊大小 (Block size)
            > 區塊大小, 可以為 1024/2048/4096 bytes (Compaq Alpha 系統可以使用 8192 字節的區塊)

        1. Fragment 大小 (Fragment size)
            > 實際上 Ext2/Ext3/Ext4 未有支援 Fragment, 所以此值一般和區塊大小一樣

        1. 保留 GDT 區塊數目 (Reserved GDT blocks)
            > 保留作在線 (online) 改變檔案系統大小的區塊數目.
            若此值為 `0`, 必須先卸載才可改變檔案系統大小

        1. 區塊/組 (Blocks per group)
            > 每個區塊組的區塊數目

        1. Fragments/組 (Fragments per group)
            > 每個區塊組的 fragment 數目, 亦用來計算每個區塊組中 block bitmap 的大小

        1. Inodes/組 (Inodes per group)
            > 每個區塊組的 inode 數目

        1. Inode 區塊/組 (Inode blocks per group)
            > 每個區塊組的 inode 區塊數目

        1. Flex block group size
            > `16`

        1. 檔案系統建立時間 (Filesystem created)
            > 格式化此檔案系統的時間
        1. 最後掛載時間 (Last mount time)
            > 上一次掛載此檔案系統的時間
        1. 最後改動時間 (Last write time)
            > 上一次改變此檔案系統內容的時間

        1. 掛載次數 (Mount count)
            > 距上一次作完整檔案系統檢查後檔案系統被掛載的次數,
            讓 `fsck` 決定是否應進行另一次完整檔案系統檢查

        1. 最大掛載次數 (Maximum mount count)
            > 檔案系統進行另一次完整檢查可以被掛載的次數, 若掛載次數 (Mount count) 大於此值,
            `fsck` 會進行另一次完整檔案系統檢查

        1. 最後檢查時間 (Last checked)
            > 上一次檔案系統作完整檢查的時間

        1. 檢查間距 (Check interval)
            > 檔案系統應該進行另一次完整檢查的最大時間距

        1. 下次檢查時間 (Next check after)
            > 下一次檔案系統應該進行另一次完整檢查的時間

        1. 保留區塊使用者識別碼 (Reserved blocks uid)
            > 0: user root

        1. 保留區塊群組識別碼 (Reserved blocks gid)
            > 0: group root

        1. 第一個 inode (First inode)
            > 第一個可以用作存放正常檔案屬性的 inode 編號,
            在原格式此值一定為 `11`,  V2 格式亦可以改變此值

        1. Inode 大小 (Inode size)
            > Inode 大小, 傳統為 128 字節, 新系統會使用 256 字節的 inode 令擴充功能更方便

        1. Required extra isize
            > 28
        1. Desired extra isize
            > 28

        1. 日誌 inode (Journal inode)
            > 日誌檔案的 inode 編號

        1. 預設目錄 hash 算法 (Default directory hash)
            > half_md4
        1. 目錄 hash 種子 (Directory Hash Seed)
            > 17e9c71d-5a16-47ad-b478-7c6bc3178f1d
        1. 日誌備份 (Journal backup)
            > inode blocks
        1. 日誌大小 (Journal size)
            > 日誌檔案的大小

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

## simulation

+ lwext4

    ```
    $ cd lwext4
    $ make generic
    $ cd build_generic
    $ make

    # simulation
    $ cd fs_test
    $ dd if=/dev/zero of=ext.disk bs=512 count=16384 # 8MB partition
    $ ./lwext4-mkfs -i ./ext.disk -b 4096 -e 2 -v
    ```

    - GDB debug

        ```
        $ cd fs_test
        $ gdb lwext4-mkfs
            ...
            (gdb) file lwext4-mkfs
            (gdb) set args -i ./ext.disk -b 4096 -e 2 -v
            (gdb) b main
            (gdb) r
        ```

    - gdb server + gdb

        1. gdbserver

            ```
            $ sudo apt install gdbserver
            $ gdbserver :1234 ./lwext4-mkfs
            ```
        1. gdb

            ```
            $ gdb lwext4-mkfs
                ...
                (gdb) file lwext4-mkfs
                (gdb) target remote :1234
            ```

+ mkfs.ext4

```
$ dd if=/dev/zero of=ext.disk bs=512 count=65536  # 32MB partition
$ losetup -f                            # 找一個空的 loop 設備
$ sudo losetup /dev/loop0 ext.disk      # 映射 image 到 loop 設備上
$ sudo partprobe /dev/loop0
$ ls /dev/loop*
    ...
    /dev/loop0p1
    /dev/loop0p2
    ...
$ sudo mkfs.ext4 -b 4096 -g 4096 -I 128 -i 16384 -m 0 -J size=0 /dev/loop0p1

### disable journal feature
$ sudo tune2fs -o journal_data_writeback /dev/loop0p1
$ sudo tune2fs -O ^has_journal /dev/loop0p1
$ sudo e2fsck -f /dev/loop0p1

$ sudo dumpe2fs /dev/loop0p1
$ sudo hexdump -C /dev/loop0p1

$ mkdir ext_disk        # 建立連接的目錄
$ sudo mount -t ext4 /dev/loop0p1 ext_disk/
$ cd ext_disk
$ sudo ls -li           # list the inode index
    total 16
    11 drwx------ 2 root root 16384 Aug 19 10:16 lost+found

$ sudo umount ext_disk
$ sudo losetup -d /dev/loop0            # detach loop device
```

    - `mount`

        ```
        usage: mount -t <type> <device> <dir>

            <device>    就是要掛載的設備或映像檔
            -t <type>   是指定 device 的檔案系統格式(如 ext4, fat 或 ntfs 等)
            <dir>       則是指定掛載的路徑(也就是要把這個設備掛在目錄樹的哪裡)
        ```

    - `umount`

        ```
        usage: umount <dir>
            <dir>       指定掛載的路徑
        ```


+ `fsck`
    > 用於檢查並且試圖修復檔案系統中的錯誤, 把設備需 `umount` 後才能進行

    ```
    # 文件系統錯誤訊息
    $ sudo dumpe2fs /dev/loop0p1
        ...

        First error time:         Mon Oct  5 00:52:47 2015
        First error function:     ext4_mb_generate_buddy
        First error line #:       742
        First error inode #:      0
        First error block #:      0
        Last error time:          Mon Oct  5 00:56:32 2015
        Last error function:      ext4_mb_generate_buddy
        Last error line #:        742
        Last error inode #:       0
        Last error block #:       0
    ```

    - 手動修復

        ```
        # 檢查錯誤
        $ fsck /dev/loop0p1
            ps. error code '$ echo $?'
                0   – No errors
                1   – File system errors corrected
                2   – System should be rebooted
                4   – File system errors left uncorrected
                8   – Operational error
                16  – Usage or syntax error
                32  – Fsck canceled by user request
                128 – Shared library error

        # 自動修復
        $ fsck -a /dev/loop0p1
        ```

## linxu directory

```
    /           根目錄, 只能包含目錄, 不能包含具體文件.
    |- bin      存放可執行文件. 很多命令就對應/bin目錄下的某個程序, 例如 ls、cp、mkdir. /bin目錄對所有用戶有效.
    |- dev      硬件驅動程序. 例如聲卡、磁盤驅動等, 還有如 /dev/null、/dev/console、/dev/zero、/dev/full 等文件.
    |- etc      主要包含系統配置文件和用戶、用戶組配置文件.
    |- lib      主要包含共享庫文件, 類似於Windows下的DLL; 有時也會包含內核相關文件.
    |- boot     系統啟動文件, 例如Linux內核、引導程序等.
    |- home     用戶工作目錄(主目錄), 每個用戶都會分配一個目錄.
    |- mnt      臨時掛載文件系統. 這個目錄一般是用於存放掛載儲存設備的掛載目錄的, 例如掛載 CD-ROM 的 cdrom 目錄.
    |- proc     操作系統運行時, 進程(正在運行中的程序)信息及內核信息(比如cpu、硬盤分區、內存信息等)存放在這裡.
               proc目錄是偽裝的文件系統 proc 的掛載目錄, proc 並不是真正的文件系統.
    |- tmp      臨時文件目錄, 系統重啟後不會被保存.
    |- usr      user目錄下的文件比較混雜, 包含了管理命令、共享文件、庫文件等, 可以被很多用戶使用.
    |- var      主要包含一些可變長度的文件, 會經常對數據進行讀寫, 例如日誌文件和打印隊列裡的文件.
    |- sbin 和 bin 類似, 主要包含可執行文件, 不過一般是系統管理所需要的, 不是所有用戶都需要
```

## Linux文件類型

```
$ ls -al .
drwxr-xr-x ...

# d: 代表目錄文件
```

|代表符號 | 含義                                                                  |
| :-      | :-                                                                    |
| -       | 常規文件, 即file                                                      |
| d       | directory, 目錄文件                                                   |
| b       | block device, 塊設備文件, 支持以`block`為單位進行隨機訪問             |
| c       | character device, 字符設備文件, 支持以`character`為單位進行線性訪問   |
| l       | symbolic link, 符號鏈接文件                                           |
| p       | pipe, 命名管道                                                        |
| s       | socket, 套接字文件                                                    |


```
$ ls -al /
...
drwxr-xr-x 130 root root  12288 Aug  3 16:06 etc
drwxr-xr-x   4 root root   4096 May 18 15:25 home
lrwxrwxrwx   1 root root     34 May 21 13:54 initrd.img -> boot/initrd.img-4.15.0-101-generic
lrwxrwxrwx   1 root root     33 May 21 13:54 initrd.img.old -> boot/initrd.img-4.15.0-66-generic
drwxr-xr-x  20 root root   4096 Aug  3 16:06 lib
...
-rw-rw-rw-  1 vng  vng  13138 Jul 21 11:14 .vimrc
...
```



# reference

+ [Ext2文件系統初步](https://blog.csdn.net/lly/article/details/43928911)
+ [Ext2文件系統簡單剖析(一)](https://www.jianshu.com/p/3355a35e7e0a)
+ [ext2檔案系統](http://shihyu.github.io/books/ch29s02.html)
+ [Linux EXT2 文件系統](https://www.cnblogs.com/sparkdev/p/11212734.html)
+ [The Second Extended File System](http://www.nongnu.org/ext2-doc/ext2.html)
+ [Ext4 Disk Layout](https://ext4.wiki.kernel.org/index.php/Ext4_Disk_Layout)
+ [lwext4](https://github.com/gkostka/lwext4)
+ [教程：12.文件存儲結構](https://blog.csdn.net/aspic214/article/details/42212981)
+ [Ext4檔案系統架構分析(一)](https://www.itread01.com/content/1542183553.html)
+ [ext2檔案系統結構分析](https://www.itread01.com/content/1541892092.html)
+ [***一口氣搞懂'文件系統',就靠這 25 張圖了](https://zhuanlan.zhihu.com/p/183238194)
+ [ext4文件系統由文件的inode號定位其inode Table](https://blog.csdn.net/yiqiaoxihui/article/details/55683328)
+ [**Linux FSCK自動修覆文件系統](https://blog.csdn.net/liujia2100/article/details/48900619)
+ [Linux 檔案格式 ext2 ext3 ext4 比較](https://stackoverflow.max-everyday.com/2017/08/linux-ext2-ext3-ext4/)

## extern reference
+ [磁盤調度算法](http://c.biancheng.net/cpp/html/2627.html)
+ [文件系統筆記四、磁盤調度算法](https://blog.csdn.net/XD_hebuters/article/details/79046170)
+ [一篇文章理解Ext4文件系統的目錄](https://blog.csdn.net/shuningzhang/article/details/91953377)
+ [**linux文件系統一 ext4框架結構](https://blog.csdn.net/frank_zyp/article/details/88528728)
    - block device

## tmp
+ [Linux磁盤分區的詳細步驟(圖解linux分區命令使用方法)](https://blog.csdn.net/Phoenix_wang_cheng/article/details/52743821?utm_medium=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-5.nonecase&depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-5.nonecase)
+ [Linux 文件與目錄](https://www.cnblogs.com/sparkdev/p/11249659.html)
+ [Linux文件系統之一：inode節點和inode節點包含的block尋址信息](https://blog.csdn.net/roger_ranger/article/details/78035978)
+ [一天一點學習Linux之Inode詳解](http://www.opsers.org/base/one-day-the-little-learning-linux-inode-detailed.html)



# 磁盤管理

+ [Linux入門之磁盤管理與inode表和group表詳解(CentOS)](https://blog.csdn.net/qq_42452450/article/details/105014057)



