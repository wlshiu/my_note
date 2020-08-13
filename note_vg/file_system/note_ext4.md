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
    >> inode 的內容, 記錄文件的屬性以及該文件實際數據是放置在哪些 block 內.
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

    - 給定文件路徑'/home/hello', 如何找到該文件的位置
        1. 查找根目錄的目錄項.
            > Linux 有規定, **根目錄**的目錄項必須存放在 `2-nd inode` 中.
        1. 根目錄的目錄項中存著根目錄下的子目錄目錄項和文件的數據塊信息.
            通過根目錄的目錄項可以找到 home 對應的 inode.
        1. 根據 home 對應的 inode 找到 home 的目錄項.
        1. 在 home 目錄項中找到 hello 文件的 inode
        1. 根據 hello 文件的 inode 中的數據塊指針找到存儲有 hello 文件內容的數據塊

    - 刪除 hello 文件
        1. 找到 hello 文件位置
        1. 將 Block Bitmap 中對應 bit 設為 0
        1. 將 inode Bitmap 中對應 bit 設為 0

    - 數據塊(Data block)尋址
        > inode中的數據塊指針為 `60-bytes`, 每個紀錄參數為 `4-bytes`, 所以有 15 個紀錄參數,
        其中**前 12個**參數用來直接對應 block index, **最後 3個**被用來對應 1/2/3級的間接尋址 block

        ```
        ```


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

+ simulation

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


# reference

+ [Ext2文件系統初步](https://blog.csdn.net/lly/article/details/43928911)
+ [Ext2文件系統簡單剖析(一)](https://www.jianshu.com/p/3355a35e7e0a)
+ [ext2檔案系統](http://shihyu.github.io/books/ch29s02.html)
+ [Linux EXT2 文件系統](https://www.cnblogs.com/sparkdev/p/11212734.html)
+ [The Second Extended File System](http://www.nongnu.org/ext2-doc/ext2.html)
+ [Ext4 Disk Layout](https://ext4.wiki.kernel.org/index.php/Ext4_Disk_Layout)
+ [lwext4](https://github.com/gkostka/lwext4)
+ [教程：12.文件存儲結構](https://blog.csdn.net/aspic214/article/details/42212981)


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
