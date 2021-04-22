RTOS Port
---

# Interrupt vector

+ SWI (S/w interrupt)
    > priority 最低

+ system tick
    > priority 最高

# 開關中斷總線的時機

+ 在 start schedule 前, 中斷應關閉

+ 第一次 context switch 時, 根據 CPU 特性, 可在 restore GPRs 時打開中斷總線


# Heap configuration

# Stack layout

General Purpose Registers push/pop order

## In ISR

Use stack pool for ISR

## In Context-Switch

Use stack pool for a task

+ stack initialize when a task creation

+ SWI trigger


# MISC

## system memory usage

+ code size
    > parsing map file

+ bss section size
    > parsing map file

+ data section size
    > parsing map file

+ heap section usage

    - TCB stack

        1. lightweight
            > 量杯方式, 每間隔一個單位設定 tag (0xa5a55a5a), 檢查 tag 是否被破壞
            >> 會有精準度誤差

        1. fully
            > uxTaskGetStackHighWaterMark()

    - run-time allocate
        > 可能會跟 task stack pool 重疊

        1. lightweight
            > 宣告全域變數 PrevMaxHeapUsedSize 及 CurrMaxHeapUsedSize.
            > + 每次 malloc 時, 累加 size 到 CurrMaxHeapUsedSize;
            > + 每次 free 時, 比較 PrevMaxHeapUsedSize 和 CurrMaxHeapUsedSize 大小,
            如果 `PrevMaxHeapUsedSize < CurrMaxHeapUsedSize`, 則更新 PrevMaxHeapUsedSize,
            同時 `CurrMaxHeapUsedSize - freed_size`

        1. fully
            > 每次 free 時, 遍歷 FreeBlockList, 計算 Free Space, 並**記錄 MinFreeSize**
            >> 可轉換成 MaxUsedSize (total_size - MinFreeSize)











