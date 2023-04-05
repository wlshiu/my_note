[分享離線SWD程式設計器程式碼](https://www.amobbs.com/thread-5698975-1-1.html)
---

SWD離線程式設計器, 其實很簡單
> 因為關鍵程式碼國外的大俠都已經給實現了, 我們只需要簡單拼接一下就OK啦

下面我就說下怎樣通過拼接程式碼, 實現離線程式設計器

+ 首先, 既然是SWD程式設計器, 那首先當然是要實現SWD時序協議了
    > 由於單晶片都沒有SWD外設, 所以只能用GPIO模擬實現SWD時序, 這部分功能已經由ARM公司的`CMSIS-DAP`程式碼實現

+ 然後就是基於CMSIS-DAP, 實現`讀寫目標晶片的記憶體與核心暫存器`,
    > 這部分功能已經由`DAPLink`裡面的`swd_host.c`檔案實現,
    同時, `swd_host.c`還實現了另一個對實現程式設計器至關重要的函數：

    ```
    // 它的作用是通過DAP在目標晶片上執行
    uint8_t swd_flash_syscall_exec(const program_syscall_t *sysCallParam, uint32_t entry, uint32_t arg1, uint32_t arg2, uint32_t arg3, uint32_t arg4)
    ```



接著我們只要把 Flash 演算法(一段在 DUT 上執行的程式碼, 裡面有`Flash_Erase/Flash_Write`兩個函數, e.g. FLM file),
通過 SWD 下載到 DUT 的 SRAM, 然後再藉由 SWD 呼叫 DUT SRAM 裡面的 Flash_Erase/Flash_Write, 就能實現通過SWD給 DUT 燒錄 Flash 了

所以程序中`target_flash_init()`的主要作用, 就是把晶片的 Flash 演算法, 下載到 DUT 的 SRAM 中


接著還有一個問題, `要下載到目標晶片SRAM中去的Flash 演算法從哪裡來?`

Keil 針對每一顆 Chip, 都有一個 Flash 演算法, 這個演算法存在一個後綴為`.FLM`的檔案裡面, 如果我們能把 FLM 裡面的演算法內容, 抽取出來使用,那不就完美了
> 其實這個功能也已經有國外大神給實現了, GitHub 上的 [FlashAlgo](https://github.com/pyocd/FlashAlgo) 項目裡面有個 `flash_algo.py`, 它就是用來實現這個功能的


工程示例程式碼

[DAPProg](https://github.com/XIVN1987/DAPProg)


## FLM of Keil

`Keil_v5\ARM\Flash\_Template` 有個燒錄演算法範本

對比 `SWD_flash.c`的程式碼發現一些問題
+ Keil FLM 中的函數, 都是 `OK return 0 and Fail return 1`, 而`SWD_flash.c`認為函數 `return 0` 表示出錯
+ Keil FLM 中 Init() 的第三個參數說明, Init() 應該是在 Erase/Program/Verify 之前各執行一次, 而 SWD_flash.c 的實現只在最開始呼叫一次 Init()

所以, 很可能 SWD_flash.c 不是針對 Keil 的 FLM 寫的, DAPLink 可能只是實現自己的 Flash 演算法介面,
> 而我上面那個STM32的Demo之所以能執行成功, 可能是因為
> + 所有函數都沒檢查返回值
> + 可能在 STM32 的 FLM 演算法中, Init() 對 Erase/Program/Verify 的操作執行的內容是一樣的, 所以執行一次 Init() 就行了

不過用在另一些晶片上可能就不行了

所以, 我對SWD_flash.c做了一些修正, , 不過由於沒有板子, 暫時沒法測試, , 感興趣的壇友可用試一下

### [pyOCD](https://github.com/mbedmicro/pyOCD)

如果想實現線上程式設計器的話, 可以用現成的 `pyOCD`

在`pyOCD` 下有個叫 `flash.py`的檔案, 其中部分函數, 看起來和 SWD_flash.c 中的函數非常像啊
> 有這個檔案, 實現線上程式設計器就簡單多了

不過也有兩個小問題
> + 這個項目是基於 CMSIS-DAP(DAPLink)的, 如果想用 JLink 做線上下載的話, 需要把底層部分換成 `jlink.py`
> + 這是個 CLI 的項目, 想要做個帶圖形介面的線上下載器的話, 需要自己新增 GUI 功能


## Flash Algo

下面內容分別來自 `flash_algo.py`和`c_blob.tmpl`

整個 FlashAlgo 燒寫過程
> 佔用了 DUT 4K SRAM,
> + SRAM base address `0x20000000`
> + Stack Top 指向 End address of 4K SRAM
> + Flash 演算法佔用 `0x20000000 ~ 0x20000400` (1KB)
> + 待燒寫資料, 佔用 `0x20000400 ~ 0x20000C00` (2KB)
> +  靜態變數 和 Stack area 佔用 `0x20000C00 ~ 0x20001000` (1KB)

這種設計對絕大多數 Cortex-M 晶片是沒有問題的, 不過有幾種情況可能需要 `Flash Download` -> `RAM for Algorithm` 的部分
> + SRAM 的起始地址不是 0x20000000, 這種調整最簡單, 把 entry 的值調整成正確值就可用了
> + Chip 的 SRAM 小於 4KB, 這種就比較麻煩, 得根據實際情況重新規劃SRAM的分配
> + Flash 演算法內容大於 1K, 有些使用 SPI Flash 的 chip, 它的 Flash 演算法會非常大, 1KB SRAM 裝不下, 需把後面幾個部分的地址都往後延

所以對於有些比較特殊的 Chip, 需要先修改一下 `flash_algo.py`和`c_blob.tmpl`, 然後再生成演算法檔案對應的`.c`

+ MISC
    - 我自己修改了你的程式碼, 重新移植了IO驅動部分, 方便定義IO, 刪除了JTAG部分的一些定義
        > [swd_offlie_downloader](https://github.com/jiaosanjue/swd_offlie_downloader)




