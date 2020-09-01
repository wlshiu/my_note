ARM 9 architecture
---

# Chips

+ Faraday FA606TE
    > Base on ARM926EJ-S Pipeline Description,
    and support ARM v5 instruction set


# System feature

+ Exceptions
    > 當處理器碰到異常時, PC會被強制設置為對應的異常向量, 從而跳轉到
     相應的處理程序, 然後再返回到主程序繼續執行

    - `u-boot\arch\arm\lib\vectors.S`

    ```S
        .globl _start
    /**
     *  系統復位位置, 各個異常向量對應的跳轉代碼
     */
    _start:
        b   reset                       /* 復位向量 */
        ldr pc, _undefined_instruction  /* 未定義的指令異常向量 */
        ldr pc, _software_interrupt     /* 軟件中斷異常向量 */
        ldr pc, _prefetch_abort         /* 預取指令操作異常向量 */
        ldr pc, _data_abort             /* 數據操作異常向量 */
        ldr pc, _not_used               /* 未使用 */
        ldr pc, _irq                    /* 慢速中斷異常向量 */
        ldr pc, _fiq                    /* 快速中斷異常向量 */

    _undefined_instruction:
        .word undefined_instruction
    _software_interrupt:
        .word software_interrupt
    _prefetch_abort:
        .word prefetch_abort
    _data_abort:
        .word data_abort
    _not_used:
        .word not_used
    _irq:
        .word irq
    _fiq:
        .word fiq

        /**
         *  將地址對齊到16的倍數, 如果地址寄存器的值 (PC) 跳過4個字節才是16的倍數,
         *  則使用 '0xdeadbeef' 填充這4個字節, 如果它跳過1, 2, 3個字節, 則填充值不確定.
         *  如果地址寄存器的值 (PC) 是16的倍數, 則無需移動
         */
        .balignl 16,0xdeadbeef
     ```

    - support 7 types

        1. reset
            > Fix address `0x00`
        1. undefined instruction
            > Fix address `0x04`
        1. software interrupt
            > Fix address `0x08`
        1. prefetch abort
            > Fix address `0x0C`
        1. data abort
            > Fix address `0x10`
        1. unused
            > Fix address `0x14`
        1. irq (Interrupt Request)
            > Fix address `0x18`
        1. frq (Fast Interrupt Request)
            > Fix address `0x1C`

    - exception process
        > 當一個異常出現以後, ARM會自動執行以下幾個步驟：
        > 1. 把下一條指令的地址放到連接寄存器 `LR` (通常是R14), 這樣就能夠在處理異常返回時從正確的位置繼續執行.
        > 1. 將相應的 `CPSR` (當前程序狀態寄存器) 複製到 `SPSR`(備份的程序狀態寄存器)中.
            從異常退出的時候, 就可以由 `SPSR` 來恢復 `CPSR`.
        > 1. 根據異常類型, 強制設置 `CPSR` 的運行模式位.
        > 1. `PC` (程序計數器)被強製成相關異常向量處理函數地址, 從而跳轉到相應的異常處理程序中.
        > 1. 當異常處理完畢後, ARM會執行以下幾步操作從異常返回
        >> + 將連接寄存器 `LR` 的值**減去相應的偏移量**後送到 `PC`中
        >> + 將 `SPSR` 複製回 `CPSR`中
        >> + 若在進入異常處理時設置了中斷禁止位, 要在此清除


# uboot example

+ u-boot.lds
    > uboot的 link script (board/my2410/u-boot.lds) 定義了目標程序各部分的鏈接順序

    ```lds
    /* 指定輸出可執行文件為ELF格式, 32為, ARM小端 */
    OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")

    /* 指定輸出可執行文件為ARM平台 */
    OUTPUT_ARCH(arm)

    /* 起始代碼段為 _start */
    ENTRY(_start)

    SECTIONS
    {
        /**
         *  指定可執行image文件的全局入口點,
         *  通常這個地址都放在 ROM(flash) 0x0 位置
         */
        . = 0x00000000  /* 從 0x0位置開始 */
        . = ALIGN(4)    /* 4字節對齊 */
        .text :
        {
            cpu/arm920t/start.o (.text)
            board/my2440/lowlevel_init.o (.text)
            *(.text)
        }

        . = ALIGN(4);
        .rodata :
        {
            *(SORT_BY_ALIGNMENT(SORT_BY_NAME(.rodata*)))
        }
        . = ALIGN(4);

        /**
         *  只讀數據段,
         *  所有的只讀數據段都放在這個位置
         */
        .data :
        {
            *(.data)
        }
        . = ALIGN(4);

        /**
         *  指定got段:
         *  got段式是 uboot 自定義的一個段, 非標準段
         */
        .got :
        {
            *(.got)
        }
        . = .;
        __u_boot_cmd_start = .; /* 把__u_boot_cmd_start賦值為當前位置, 即起始位置 */


        /**
         *  u_boot_cmd段:
         *  所有的 u-boot 命令相關的定義都放在這個位置, 因為每個命令定義等長,
         *  所以只要以 __u_boot_cmd_start 為起始地址, 進行查找就可以很快查找到某一個命令的定義,
         *  並依據定義的命令指針調用相應的函數進行處理用戶的任務
         */
        .u_boot_cmd :
        {
            *(.u_boot_cmd)
        }

        /**
         *  u_boot_cmd 段結束位置:
         *  由此可以看出, 這段空間的長度並沒有嚴格限制,
         *  用戶可以添加一些 u-boot 的命令, 最終都會在連接是存放在這個位置
         */
        __u_boot_cmd_end = .;

        . = ALIGN(4);
        __bss_start = .; /* 把 __bss_start 賦值為當前位置, 即 bss 段的開始位置 */

        /**
         *  指定bss段:
         *  這裡NOLOAD的意思是這段不需裝載, 僅在執行域中才會有這段
         */
        .bss (NOLOAD) :
        {
            *(.bss)
            . = ALIGN(4);
        }
        _end = .; /* 把_end賦值為當前位置,即bss段的結束位置 */
    }
    ```

+ system bootstrap

```
Stage 1
reset -> cpu_init_crit -> _main -> relocate

Stage 2
-> board_init_r() -> init_sequence[] -> main_loop()

```

    - start.S (Stage 1)
        > 第一個鏈接的是 `cpu/arm920t/start.S`, 也即 uboot 的入口指令在 start 中

        1. 主要作用
            > 1. 進入 SVC 模式
            > 1. disable WDT
            > 1. 屏蔽所有IRG掩碼
            > 1. set clock (FCLK HCLK PCLK)
            > 1. clear I/D Cache
            > 1. disable MMU and CACHE
            > 1. configure memory control
            > 1. relocate
            >> 如果代碼不在指定的地址上需要把uboot從當前位置copy到RAM指定位置上
            > 1. setup stack, 為進入C函數做準備
            > 1. clear bss section to 0

        1. _main at `u-boot/arch/arm/lib/crt0.S`

    - board_r.c (Stage 2)
        > u-boot\common\board_r.c


# MISC





