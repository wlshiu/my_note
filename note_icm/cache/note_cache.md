Cache
---

# Cache 的設計模式

+ Direct Mapped
    > 一塊資料(佔一個 cache line 的空間), 只有一個 cache line 與之對應. 為多對一的映射關係.
    在 1990 年代初期, 直接映射是當時最流行的機制, 因為所需的硬體資源非常有限. 現在直接映射機制正在逐漸被淘汰.

    - 下面用停車場當作例子來做說明:
    假設有 1000 個停車位, 每個位子依 000 ~ 999 的順序給一個號碼, 你的學生證號碼的前三碼就是你的停車位號碼. 這就是 cache 對映最簡單的例子.
    然而這會有什麼問題呢? 數字小的號碼(如:200多)可能有更大的機會同一個位置有多個學生要停.
    數字大的號碼就可能會比較空, 因為學生證號碼900多開頭的學生可能不多.

        1. 優點:
            > 簡單, 記憶體中的每一個位置只會對應到 cache 中的一個特定位置.

        1. 缺點:
            > 兩個變數映射到同一個 cache line 時, 他們會不停地把對方替換出去. 由於嚴重的衝突, 頻繁刷新 cache 將造成大量的延遲,
            而且在這種機制下, 如果沒有足夠大的 cache, 處理程序幾乎無時間局部性可言.

+ Fully Associative
    > 在一個 Cache 集內, 任何一個記憶體地址的數據可以被 cache 在任何一個 Cache Line 裡.

    - 下面用停車場當作例子來做說明:
    停車許可證比停車位還要多的狀況. 有 1000 個停車位, 但是有 5000 個同學.

        1. 優點:
            > 可以完整利用記憶體

        1. 缺點:
            > cache 中尋找 block 時需要搜尋整個 cache

+ N-way Set Associative Cache
    > 直接映射會遭遇衝突的問題, 當多個塊同時競爭 cache 的同一個 cache line 時, 它們不停地將對方踢出快取, 這將降低命中率.
    另一方面, 完全關聯過於複雜, 很難在硬體層面實現.
    N-way 關聯快映射則是直接映射跟全映射的混合, 在兩者之前取得平衡.

    - 下面用停車場當作例子來做說明:
    假設有 1000 個停車位, 分成 10 組, 使用 00~99 作為每一組內車位的編號.
    你的停車位就是學生證的前兩碼, 如此一來你就有 10 個停車位可以選擇.

    1. 優點:
        > 給定一個記憶體地址可以唯一對應一個 set , 對於 set 中只需遍歷 16 個元素就可以確定對象是否在快取中.
        相對 Direct Mapped, 連續熱點數據 (會導致一個 set 內的 conflict) 的區間更大


# NDS32

## Definitions

+ index
    > cache buffer 以 cache-line 為單位來分割, 對每個 unit 編號

+ VA
    > virtual address

+ dirty bit
    > 表示這個 cache-line 的 data 有被修改過, 需要寫回主記憶體

+ invalid
    > 表示這個 cache-line 內容可以被置換

## SubType

<L1D/L1I>_<IX/VA>_<Action>
> + <L1D/L1I>
>> level 1 I-Cache or level 1 D-Cache
> + <IX/VA>
>> map to cache-line with index or virtual address
> + <Action>
>> the target action


+ L1D_IX_INVAL
    > Invalidate L1D cache
    >> 用 index 將 mapping 到的 cache-line 設成 invalid

+ L1D_VA_INVAL
    > Invalidate L1D cache
    >> 用 virtual address 將 mapping 到的 cache-line 設成 invalid

+ L1D_IX_WB
    > Write Back L1D cache
    >> 用 index 將 mapping 到的 cache-line, 寫回主記憶體

+ L1D_VA_WB
    > Write Back L1D cache
    >> 用 virtual address 將 mapping 到的 cache-line, 寫回主記憶體

+ L1D_IX_WBINVAL
    > Write Back & Invalidate L1D cache
    >> 用 index 將 mapping 到的 cache-line, 寫回主記憶體並設成 invalid

+ L1D_VA_WBINVAL
    > Write Back & Invalidate L1D cache
    >> 用 virtual address 將 mapping 到的 cache-line, 寫回主記憶體並設成 invalid

+ L1D_VA_FILLCK
    > Fill and Lock L1D cache

+ L1D_VA_ULCK
    > unlock L1D cache

+ L1D_IX_RTAG
    > Read tag L1D cache

+ L1D_IX_RWD
    > Read word data L1D cache

+ L1D_IX_WTAG
    > Write tag L1D cache

+ L1D_IX_WWD
    > Write word data L1D cache

+ L1D_INVALALL
    > Invalidate All L1D cache

## Example

+ flush

    ```c
    unsigned long   cache_line = CACHE_LINE_SIZE(DCACHE);
    unsigned long   end = CACHE_WAY(DCACHE) * CACHE_SET(DCACHE) * cache_line;

    #if 0
        do {
            end -= cache_line;
            __asm__ volatile ("\n\tcctl %0, L1D_IX_WB" ::"r" (end));
            __asm__ volatile ("\n\tcctl %0, L1D_IX_INVAL" ::"r" (end));
            end -= cache_line;
            __asm__ volatile ("\n\tcctl %0, L1D_IX_WB" ::"r" (end));
            __asm__ volatile ("\n\tcctl %0, L1D_IX_INVAL" ::"r" (end));
            end -= cache_line;
            __asm__ volatile ("\n\tcctl %0, L1D_IX_WB" ::"r" (end));
            __asm__ volatile ("\n\tcctl %0, L1D_IX_INVAL" ::"r" (end));
            end -= cache_line;
            __asm__ volatile ("\n\tcctl %0, L1D_IX_WB" ::"r" (end));
            __asm__ volatile ("\n\tcctl %0, L1D_IX_INVAL" ::"r" (end));

        } while (end > 0);
    #else
        // more readable
        do {
            end -= cache_line;
            __nds32__cctlidx_wbinval(NDS32_CCTL_L1D_IX_WB, end);
            __nds32__cctlidx_wbinval(NDS32_CCTL_L1D_IX_INVAL, end);
        } while (end > 0);
    #endif
    ```

+ clear range

    ```c
    unsigned long   start = 0x20000000;
    unsigned long   end = 0x20001000;
    unsigned long   line_size = CACHE_LINE_SIZE(DCACHE);

    #if 0
        while (end > start) {
            __asm__ volatile ("\n\tcctl %0, L1D_VA_WB" ::"r" (start));
            start += line_size;
        }
    #else
        // more readable
        while (end > start) {
            __nds32__cctlva_wbinval_one_lvl(NDS32_CCTL_L1D_VA_WB, (void *)start);
            start += line_size;
        }
    #endif
    ```

# reference

+ [CPU Cache 原理探討](https://hackmd.io/@drwQtdGASN2n-vt_4poKnw/H1U6NgK3Z?type=view)
+ [請教CPU的cache中關於line,block,index等的理解](https://www.zhihu.com/question/24612442)
