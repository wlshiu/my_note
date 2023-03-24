SPIFSS設計思想
---

SPIFFS 靈感來自於 YAFFS. 然而, YAFFS 是為 NAND Flash 和一些具有充足 RAM 的 device 設計的.
儘管如此, SPIFFS 還是借鑑了許多 YAFFS 好的想法.
> 編寫 SPIFFS 最大的難題, 是無法假設 device 具有 Heap.
因此 SPIFFS 只能使用傳入的 RAM buffer.

## SPI NOR Flash 裝置

physical 上 SPI Flash 可以換分為許多 block. block 可被細分為多個 sector.

SPI Flash 大部分具有統一 32/64KB 的 block. 而 sector 大都是 4KB
> 也有一些不統一的, e.g. 前 16 個 blocks 為 4KB 大小, 後面的 block 為 64KB.

整個存取區為線性結構, 並且可以進行隨機讀寫.
> erase 只能按 Block 或者 Sector 為最小單位.

SPI Flash 擦寫的壽命限制, 一般可以擦寫 10萬 至 100萬 次, 超出後失效的 Flash block 將無法正確讀寫出有效資料.

對 NOR Flash 進行 program 時, 是將 data 由 `1 -> 0`
> 可想像成, program 只能對單一 cell 放電, 若想要複寫, 則必須先做 erase, 對某個區域做充電

SPI Flash 的一個普遍特性是 `讀快寫慢`.
> 與 NAND Flash 不同, NOR Flash 的可靠性較高, 通常不需要 ECC.

## Spiffs 的邏輯結構

正式開始前先看幾個術語:

> + Physical Blocks/Sectors/Pages
> 指 flash chip 中, 實際的`電路儲存單元大小`
>> 通常 `1 sector = 4-KBytes`, `1 page = 256-Bytes`

> + Logical Blocks/Pages
> 指演算法中, 概念上的儲存單元大小


### Blocks 與 Pages

User 可依需求將 SPI Flash 的全部或者部分儲存空間分給 Spiffs
> 這些區域會被分割為 `Logical Pages`, 而 `Logical Blocks` 的大小必須是 Physical Blocks 的倍數
>> `Logical Blocks` 是由一個或多個 `Physical Blocks` 組成

例如: 非統一塊大小的 Flash 對應為 spiffs 的 128KB Logical Blocks

```
PHYSICAL FLASH BLOCKS               SPIFFS LOGICAL BLOCKS: 128kB

+-----------------------+   - - -   +-----------------------+
| Block 1 : 16kB        |           | Block 1 : 128kB       |
+-----------------------+           |                       |
| Block 2 : 16kB        |           |                       |
+-----------------------+           |                       |
| Block 3 : 16kB        |           |                       |
+-----------------------+           |                       |
| Block 4 : 16kB        |           |                       |
+-----------------------+           |                       |
| Block 5 : 64kB        |           |                       |
+-----------------------+   - - -   +-----------------------+
| Block 6 : 64kB        |           | Block 2 : 128kB       |
+-----------------------+           |                       |
| Block 7 : 64kB        |           |                       |
+-----------------------+   - - -   +-----------------------+
| Block 8 : 64kB        |           | Block 3 : 128kB       |
+-----------------------+           |                       |
| Block 9 : 64kB        |           |                       |
+-----------------------+   - - -   +-----------------------+
| ...                   |           | ...                   |

```

One Logical Block 由多個 Logical Pages 構成
> `Logical Pages` 定義為 SPIFFS 儲存資料的**最小單元**.

因此, 假設有一個檔案, 只包含一個 byte, 這個檔案會用 `1 Logical Page` 用來儲存 index, 同時再用`1 Logical Page`用來儲存 raw data
> 一個檔案最少需要 `2 Logical Pages`

SPIFFS 的每一個 Logical Page, 都需要使用 `5 ~ 9 bytes` 的 metadata
> 過小的 Logical Page Size 會產生大量的 Logical Pages, 進而造成 metadata 過多, 而浪費儲存空間
>> + Logical Page Size 為 **64-Bytes** 的 SPIFFS, 將浪費 `8 ~ 14 %` 空間,
>> + Logical Page Size 為 **256-Bytes** 的 SPIFFS, 將浪費 `2 ~ 4 %` 空間,


SPIFFS 也需要一個 SRAM Buffer, 除了會被用來載入和維護 SPIFFS 的 Logical Pages, 也會被演算法用來`找尋空閒檔案 ID`或`掃描檔案系統`等用途
> `SRAM_Buffer = 2 * Logical_Pages_Size`
>> 過小的 SRAM Buffer 會導致更多的 read 操作, 而造成效能過慢


檔案系統 Page size 選用原則和影響因素
> + How big is the logical block size ?
> + What is the normal size of most files
> + How much ram can be spent ?
> + How much data (vs metadata) must be crammed into the file system ?
> + How fast must spiffs be ?
> + Other things impossible to find out ?


因此 `Optimal Page Size` 是需要依 device resource 去調教, 參考計算公式如下

```
Logical_Page_Size = Logical_Block_Size / 256
```

從參考值開始調教, 可節省許多時間


## Objects, indices and look-ups

File 或者 Object(SPIFFS 中的命名)由一個 Object ID 表示.
> Object ID 是每個 Logical Page header 的一部分, 進而可精準知道, page 是屬於哪一個 Object (空白頁除外).

每個 Object 由兩種 Page 構成
> + index page
> + data page

大部分 block base 的 file system, 都是採用 look-up table (index page) 的方式, 藉由查詢 index pages, 而快速找到對應的 data pages

Logical Page header 也包含一個 `span index`的內容
> span index 是 Object 所含括的 page order
>> e.g. 一個檔案包含三個 pages, The 1st data page 的 span index 為 0,
the 2nd data page 的 span index 為 1, 最後一個 data page 的 span index 就為 2

最後, 每個 Logical Page header 中會包含一個 flags, 用以表示該 page 狀態 (e.g. used, deleted, finalized, holds index or data, ...etc.)

當一個 object 的 index page 中的 span index 為 0, 則被稱為 `object index header`,
這一個 index page 中, 不僅包含 data page 的 page id,
同樣包含 Object 的其他資訊, e.g. Object Name, Object size (in bytes), file/directory flags, ...etc.

```
ex. SPIFFS 的某一個檔案佔用 3 個 page, file name 為 "spandex-joke.txt", Object ID 為 12, 則其結構類似下面的描述.

PAGE_0  <things to be unveiled soon>

PAGE_1  page header:   [obj_id:12  span_ix:0  flags:USED|DATA]              <-------- data page
        <first data page of joke>

PAGE_2  page header:   [obj_id:12  span_ix:1  flags:USED|DATA]              <-------- data page
        <second data page of joke>

PAGE_3  page header:   [obj_id:545 span_ix:13 flags:USED|DATA]
        <some data belonging to object 545, probably not very amusing>

PAGE_4  page header:   [obj_id:12  span_ix:2  flags:USED|DATA]              <-------- data page
        <third data page of joke>

PAGE_5  page header:   [obj_id:12  span_ix:0  flags:USED|INDEX]             <-------- index page
        obj ix header: [name:spandex-joke.txt  size:600 bytes  flags:FILE]
        obj ix:        [1 2 4]                                              <----- Page_ID of data pages
```

上述例子中的 PAGE_5, 是紀錄了 `object index header` 的 index page.
`obj ix` array 為按順序排列的 PageID of data pages.

```
                            entry ix:  0 1 2
                              obj ix: [1 2 4]
                                       | | |
    PAGE_1, DATA, SPAN_IX 0    --------+ | |
      PAGE_2, DATA, SPAN_IX 1    --------+ |
        PAGE_4, DATA, SPAN_IX 2    --------+
```



## Design concept

Spiffs 的設計, 是針對 Low SRAM 的系統, 所以無法為加速檔案的訪問, 而使用動態列表, 用於儲存所有的 `object index header`
> SPIFFS 工作的系統, 很可能是沒有 Heap. 但也不希望去掃描所有 pages, 去獲取 `object index header`

因此, 每一個 Block 的 `Page_0`, 被用來做為 Object 的查表.
> 這些 Page_0 與一般 page 不同, 它們沒有 header 結構, 而是用一個 array 來記錄目前 Block 剩餘 page 的 Object ID.
通過掃描 Block 的 `Page_0`, 來獲取包含 Object index 的 page.

`Page_0` 的 array 是一串冗長的 metadata, SPIFFS 假設搜尋 Blocks, 並從一個 Block 中讀取一個 page, 所花費的 effort 是很小的
> SPI Flash 操作時, 會需要額外的 data, e.g. command, flash address, ...etc. 甚至系統環境也可能需要 mutex


+ A block with some extra pages

    ```
    PAGE_0  [ 12, 12, 545, 12, 12, 34, 34, 4, 0, 0, 0, 0, ...]

    PAGE_1  page header:   [obj_id:12  span_ix:0  flags:USED|DATA] ...
    PAGE_2  page header:   [obj_id:12  span_ix:1  flags:USED|DATA] ...
    PAGE_3  page header:   [obj_id:545 span_ix:13 flags:USED|DATA] ...
    PAGE_4  page header:   [obj_id:12  span_ix:2  flags:USED|DATA] ...
    PAGE_5  page header:   [obj_id:12  span_ix:0  flags:USED|INDEX] ...
    PAGE_6  page header:   [obj_id:34  span_ix:0  flags:USED|DATA] ...
    PAGE_7  page header:   [obj_id:34  span_ix:1  flags:USED|DATA] ...
    PAGE_8  page header:   [obj_id:4   span_ix:1  flags:USED|INDEX] ...
    PAGE_9  page header:   [obj_id:23  span_ix:0  flags:DELETED|INDEX] ...
    PAGE_10 page header:   [obj_id:23  span_ix:0  flags:DELETED|DATA] ...
    PAGE_11 page header:   [obj_id:23  span_ix:1  flags:DELETED|DATA] ...
    PAGE_12 page header:   [obj_id:23  span_ix:2  flags:DELETED|DATA] ...
    ...
    ```

    - `PAGE_0` 的 array, 依照順序紀錄每個 page, 是屬於哪個 Object ID
        > `array[0] = Object_ID of PAGE_1`

    - `PAGE_0` 的 array 中, 標示為 `0` 的 (PAGE_9 ~ PAGE_12), 代表檔案被刪除 (為保持效能, PAGE_9 ~ PAGE_12 仍會保留原本資料, 直到被重新使用)
        > SPIFFS 是按 NAND Flash 的方式, 來套用到 NOR Flash


    - `PAGE_0`中有兩個 Object ID 是具有特殊含義的

        ```
        obj id 0 (all bits zeroes)    - 表示一個已經被刪除的頁
        obj id 0xff.. (all bits ones) - 表示一個未被使用的頁
        ```

    - object id (可自訂 spiffs_obj_id 的 type) 的 MSB 用來記錄 page 的用途

        > + `MSB == 1` 為 object index page
        > + `MSB == 0` 為 object data page

        ```
        # '*' 表示 MSB == 1
        PAGE 0  [  12   12  545   12  *12   34   34   *4    0    0    0    0 ...]
        ```
