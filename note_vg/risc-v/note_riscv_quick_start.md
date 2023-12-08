RISC-V Quick Start
---
RISC-V 的設計哲學是追求硬體簡化, 因此指令集非常精簡.
同時又為了顧及軟體的需求, RISC-V 基金會將指令集拆分為模組化的設計,
使用 RV32/RV64 前綴來表示 platform, 再由後綴的每一個英文字母代表模組的意義,
e.g. RV32GC.

+ I 指令集 (ready): 最基本的模組叫做, 包含 整數計算, 整數存取, 及 controlflow
+ M 指令集 (ready): 整數乘除法標準擴充
+ A 指令集 (ready): 不可中斷指令(Atomic)標準擴充
+ F 指令集 (ready): 單精確度浮點運算及單精確度浮點數存取標準擴充
+ D 指令集 (ready): 雙倍精確度浮點運算及雙倍精確度浮點數存取標準擴充
+ G 指令集: 所有以上的擴充指令集以及基本指令集的總和的簡稱 (IMAFD)
+ Q 指令集 (ready): 四倍精確度浮點運算標準擴充
+ C 指令集 (ready): 壓縮指令標準擴充 (16-bits instruction)
+ L 指令集: 十進位浮點運算標準擴充
+ B 指令集: 位元運算標準擴充
+ J 指令集: 動態指令翻譯標準擴充
+ T 指令集: 順序記憶體存取標準擴充
+ P 指令集: 單指令多資料流(SIMD)運算標準擴充
+ V 指令集: 向量運算標準擴充
+ N 指令集: 使用者中斷標準擴充
+ H 指令集: 虛擬化平台需使用的 Hypervisor 等指令

所有指令集可區分為 6 種 binary format

+ R-type
    > for register
    >> 用於 register to register 操作

+ I-type
    > used by arithmetic operands with constant operand
    >> 用於 短立即數 和 訪存 load 操作

+ S-type
    > 用於 訪存 store 操作

+ B-type
    > 用於 條件跳轉 操作

+ U-type
    > can accommodate a large constant
    >> 用於 長立即數 操作

+ J-type
    > 用於 無條件跳轉

# Defiitions

+ ISA (Instruction Set Architecture)
+ ABI (Application Binary Interface)
+ linker relaxation
    > `JAL` 指令(jump and link), 跳轉範圍為 `-/+ 1MiB`, 因此一條指令就足夠跳到很遠的位置.
    盡管 compiler 為每個外部函數的跳轉都生成了兩條指令, 很多時候其實一條就足夠了.
    從兩條指令到一條的優化, 可節省時間和空間開銷, 而且每次替換會導致 caller 和 callee 之間的距離縮短,
    因此 linker 會掃描幾遍代碼, 盡可能地把兩條指令替換為一條.
    這個過程稱為 `linker relaxation` (名字源於求解方程組的鬆弛技術).

    > 對於 gp (Global pointer) `+/- 2KiB` 範圍內的數據訪問,
    linker 也會使用一個全局 pointer 替換掉 `lui` 和 `auipc` 兩條指令.
    對 tp (Thread pointer) `+/- 2KiB` 範圍內的 thread, 局部變量訪問也有類似的處理.

+ trap
    > 即讓 cpu 暫停執行當前代碼, 去執行相應的處理代碼的情況, 相當於 IRQ

    - RISC-V 有三種 trap

        1. system call
        1. exception
            > e.g. 除零

        1. device interrupt
            > 周邊裝置等

+ NMI (Non-Maskable Interrupt)
    > 是 CPU 的一根特殊的輸入信號, 往往用於指示系統層面的緊急錯誤(譬如外部的硬件故障等).
    在遇到 NMI 之後, CPU 應該立即中止執行當前的程序, 轉而去處理該 NMI 錯誤

+ ECLIC (Enhanced Core Local Interrupt Controller)
    > 可用於多個中斷源的管理

+ PMP (Physical Memory Protection)
    > 根據不同的 physical address 區間和不同的 Privilege Mode, 進行權限隔離和保護

+ HART (Hardware Threads)

    - Simplified
        > The physical core.
        So, 4 cores can genuinely support 4 hardware threads at once.

    - Advanced
        > + Hardware controls threads
        > + Allows single core to interleave memory references and operations

+ CLINT (Core Local Interrupter)
    > a fixed priority scheme (like Cortex-M)

    ```

    Interrupt   +-----------+
    ------------>   HART    |
    ------------>           |
                +-----------+
                     |
        CLINT <------+

    ```

+ CLIC (Core Local Interrupt Controller)
    > a more flexible scheme (like GIC of kernel)

    ```
    Interrupt   +-------+   +------+
    ------------>  CLIC |-->| HART |
    ------------>       |   |      |
                +-------+   +------+
    ```

# Concepts

## Registers

|Register |  ABI Name |   Description                     | Caller | Callee
| :-:     |  :-:      | :-:                               | :-:    | :-:
| x0      | zero      | Hard-wired zero                   |        |
| x1      | ra        | Return address                    |  *     |
| x2      | sp        | Stack pointer                     |        |  *
| x3      | gp        | Global pointer                    |        |
| x4      | tp        | Thread pointer                    |        |
| x5      | t0        | Temporary/alternate link register |  *     |
| x6–x7   | t1-t2     | Temporaries                       |  *     |
| x8      | s0/fp     | Saved register/frame pointer      |        |  *
| x9      | s1        | Saved register                    |        |  *
| x10–x11 | a0-a1     | Function arguments/return values  |  *     |
| x12–x17 | a2-a7     | Function arguments                |  *     |
| x18–x27 | s2-s11    | Saved registers                   |        |  *
| x28–x31 | t3-t6     | Temporaries                       |  *     |
|   -     |   -       |      -                            |        |
| f0–f7   | ft0-ft7   | FP temporaries                    |  *     |
| f8–f9   | fs0-fs1   | FP saved registers                |        |  *
| f10–f11 | fa0-fa1   | FP arguments/return values        |  *     |
| f12–f17 | fa2-fa7   | FP arguments                      |  *     |
| f18–f27 | fs2-fs11  | FP saved registers                |        |  *
| f28–f31 | ft8-ft11  | FP temporaries                    |  *     |


+ `gp`
    > gp (Global Pointer) register 是為了優化 `4KB` 內 memory 訪問的一種解決辦法.
    >> 類似設置一段 4KB 的 virtual data cache, 藉由 gp 的相對位址, 來達到加速存取

    ```
    $ cat main.c
        int i;
        int main()
        {
            return i;
        }

    $ riscv-none-embed-gcc main.c --save-temps
    $ cat main.s
        ...
            lui a5,%hi(i)
            lw  a5,%lo(i)(a5)
        ...
    $ riscv-none-embed-objdump -d a.out
        ...
           101b4:   8341a783    lw      a5,-1996(gp) # 11fdc <i>
        ...
    ```

    - linker 使用 `__global_pointer$` 來比較 address 是否在 4KB 範圍內.
    如果在範圍內, 會用 gp-relative addressing 去取代 absolute/pc-relative addressing,
    以達到優化目的, 此過程稱為 `relaxing`
        > 可以使用 `-Wl,--no-relax` 來 disable 掉這個功能

    - `gp register` 應該在 booting 中載入 `__global_pointer$` 的地址, 並且之後**不能被改變**.

        ```nasm
            .section .reset_entry,"ax",@progbits
            .align  1
            .globl  _reset_entry
            .type   _reset_entry, @function
        _reset_entry:

        .option push
        .option norelax
            la gp, __global_pointer$
        .option pop

            la sp, __stack

            j _start
        ```

    - 4KB region 可以放在 RAM 中任意位置, 但是為了使優化更有效率, 它**最好覆蓋最頻繁使用的 RAM 區域**.
    以標準的 newlib 來說, 會分配`.sdata section`, 來存放像 `_impure_ptr`, `__malloc_sbrk_base`等變量.
    因此 `__global_pointer$` 會定在 `.sdata section` 之前.

        ```
        PROVIDE( __global_pointer$ = . + (4K / 2) );
        *(.sdata .sdata.*)
        ```

        1. RISC-V 使用 `12-bits` 有號的立即數 (immediate values) 當 region size (+/- 2048).
        因此`__global_pointer$`將其指向區域中間

    - 要使用 `relaxing` 功能時, 編譯需要加入 `-msmall-data-limit=N`,
    compiler 會把小於 N-bytes 的**靜態變量**放入 `.sdata section`,
    然後 linker 再將這部分靜態變量集中在 `__global_pointer$ +/- 2K` 的範圍內.


## RISC-V 硬體不支援

+ `Load/Store Multiple registers`
    > 一個指令, 存取多個通用暫存器到 stack

    - 雖然可以減少軟體的 code size, 但會增加 CPU H/w 的複雜度,
    甚至影響時序使得 CPU 的主頻無法提高, 因此 RISC-V 不支援.

    - 如果很介意 `PUSH` 和 `POP` 的指令數, 可以使用公用的程序庫(專門用於 `PUSH` 和 `POP`),
    進而省掉在每個子函數調用的過程中, 都放置數目不等的 `PUSH` 和 `POP` 指令.

    - 高性能處理器由於硬件動態調度能力很強, 可以有強大的**分支預測電路**,
    保證 CPU 能夠快速的跳轉執行.

+ 帶`條件碼`指令 (Conditional Code)
    > 在指令編碼的前幾位表示的是條件碼(Conditional Code),
    只有該條件碼對應的條件為真時, 該指令才被真正執行.

    - 由於分支跳轉會帶來的性能損失, 因此使用 Conditional Code,
    來減少了分支跳轉的出現, 同時也減少了指令的數目.
        > 但會增加 CPU H/w 的複雜度, 甚至影響時序使得 CPU 的主頻無法提高,
        因此 RISC-V 只支援普通的帶條件分支跳轉指令.

+ 分支延遲槽 (Delay Slot)
    > Delay Slot 是指在每一條分支指令後面, 緊跟著若干條指令不受分支跳轉的影響.
    >> 不管分支是否跳轉, 這後面的幾條指令都一定會被執行.

    - 早期的 RISC 架構, 沒有使用高級的硬件動態分支預測器,
    所以使用分支延遲槽能夠取得可觀的性能效果.
        > 分支延遲槽使得 CPU 的硬件設計變得極為的彆扭, 時序變得很不直觀

    - 現代的分支預測算法精度已經非常高, 可以有強大的分支預測電路,
    保證 CPU 能夠準確的預測跳轉執行達到高性能, 因此 RISC-V 不支援 Delay Slot.

+ 零開銷硬件循環指令 (Zero Overhead Hardware Loop)
    > H/w 自動減 1, 並確認 count 是否要退出循環

    - 由於 S/w 的 `for(i=0; i<N; i++)` 很常見,
    加法和條件跳轉指令會佔據較多指令數, 同時還存在著分支預測的性能問題.
    若由 H/w 直接完成, 可省掉了這些加法和條件跳轉指令, 減少了指令條數且提高了性能.

    - **零開銷硬件循環指令**大幅地增加了硬件設計的複雜度, 因此 RISC-V 不支援

+ 運算指令 exception
    > 運算指令產生錯誤時, e.g. 上溢(Overflow), 下溢(Underflow),
    非規格化浮點數(Subnormal)和除零(Divide by Zero)產生軟體異常.

    - RISC-V 架構的一個特殊之處是**對任何的運算指令錯誤(包括整數與浮點指令)均不產生異常**,
    而是產生某個特殊的默認值, 同時設置某些狀態寄存器的狀態位.

## View Pre-processor macros

```bash
$ vi z_riscv_toolchain_config.sh
    #!/bin/bash

    help()
    {
        echo -e "usage: $0 <arch-type> <abi-type>"
        echo -e "    arch-type: rv32i/rv32imac/rv32imafdc/rv64i/rv64imac/rv64imafdc"
        echo -e "    abi-type : ilp32/ilp32d/lp64/lp64d"
        exit -1;
    }

    if [ $# != 2 ]; then
        help
    fi

    # rv32i/rv32imac/rv32imafdc/rv64i/rv64imac/rv64imafdc
    arch_type=$1

    # ilp32/ilp32d/lp64/lp64d
    abi_type=$2

    riscv-none-embed-gcc -march=${arch_type} -mabi=${abi_type} -E -dM - < /dev/null | \
        egrep -i 'risc|fp[^-] |version|abi|lp' | \
        sort

$ chmod +x z_riscv_toolchain_config.sh
$ z_riscv_toolchain_config.sh rv32i ilp32

    #define __GXX_ABI_VERSION 1011
    #define __STDC_VERSION__ 201112L
    #define __VERSION__ "7.1.1 20170509"
    #define __riscv 1
    #define __riscv_cmodel_medlow 1
    #define __riscv_float_abi_soft 1
    #define __riscv_xlen 32
```

## 壓縮指令子集 (相當於 ARM 的 thumb2)

RISC-V 基本整數指令子集(字母 I 表示 )規定的**指令長度均為等長的 32-bits**,
這種等長指令定義使得僅支持整數指令子集的基本 RISC-V CPU 非常容易設計.
但是等長的 32-bits 編碼指令也會造成 Code Size 相對較大的問題.

因此 RISC-V 定義了一種可選的壓縮(Compressed)指令子集(字母 C 表示),
16-bits 指令與普通的 32-bits 指令可以無縫自由地交織在一起, 處理器也沒有定義額外的狀態.

16-bits 指令的壓縮策略, 是將一部分普通最常用的的 32-bits 指令中的信息進行壓縮重排得到;
譬如假設一條指令使用了兩個同樣的操作數索引, 則可以省去其中一個索引的編碼空間,
因此每一條 16-bits 的指令, 都能找到其對應的原始 32-bits 指令.
因此, 程序編譯成為壓縮指令僅在彙編器階段就可以完成, 極大的簡化了編譯器工具鏈的負擔.


## [實務範例操作](note_riscv_practice.md)

# [ASM of RISC-V](note_riscv_asm.md)

# [RISC-V Simulation](note_riscv_simulation.md)

# 子程序調用 (call function)

一般 RISC 架構中程序調用子函數的過程予以介紹, 其過程如下:

+ 進入子函數之後需要用存儲器寫(Store)指令, 來將當前的上下文(通用寄存器等的值),
保存到系統存儲器的堆棧區(stack)內, 這個過程通常稱為 `PUSH`

+ 在退出子程序之時, 需要用存儲器讀(Load)指令, 來將之前保存的上下文(通用寄存器等的值),
從系統存儲器的堆棧區(stack)讀出來, 這個過程通常稱為`POP`

`PUSH` 和 `POP` 的過程通常由編譯器編譯生成的指令來完成, 使用高階語言(e.g. C or C++)開發的開發者對此可以不用太關心.
高階語言的程序中直接 call function 即可, 但是這個底層發生的 `PUSH` 和 `POP` 的過程,
是實實在在地發生著, 並且還需要消耗若干的 CPU 執行時間.

為了加速這個 `PUSH` 和 `POP` 的過程, 有的 RISC 架構支援一次寫多個寄存器到存儲器中(Store Multiple),
或者一次從存儲器中讀多個寄存器出來(Load Multiple)的指令;
此類指令的好處是一條指令就可以完成很多事情, 從而減少 Assembly code 的 code size, 節省代碼的空間大小.

但是此種 `Load Multiple` 和 `Store Multiple` 的**弊端**,
是會讓 **CPU 的硬體設計變得複雜**, 增加硬件的開銷,
也可能損傷時序使得 CPU 的主頻無法提高.

RISC-V 架構則放棄使用 `Load Multiple` 和 `Store Multiple` 指令.
並解釋, 如果有比較介意這種 `PUSH` 和 `POP` 指令數的情況時,
那麼可以使用公用的程序庫(專門用於 PUSH 和 POP)來進行,
這樣就可以省掉在每個子函數調用的過程中, 都放置數目不等的 `PUSH` 和 `POP` 指令。


# 特權模式 (Privileged Mode)

根據 RISC-V 的架構定義, CPU 當前的 Machine Mode 或者 User Mode,
並沒有反映在任何 S/w 可見的寄存器中(CPU 會維護一個對 S/w 不可見的 H/w 寄存器),
因此軟件程序無法通過讀取任何寄存器, 而查看當前自己所處的 Machine Mode 或者 User Mode

+ `Machine Mode` (M Mode, 0x3)
    > 機器模式(root 權限), 能夠訪問所有的 CSR (Control and Status Register) 暫存器,
    以及所有的 physical address 區域 (除了 PMP 禁止訪問的區域)

    - Machine Sub-Mode
        > Machine Sub-Mode 紀錄在 CSR 寄存器 `msubm` 的 `TYP` field 中,
        因此 S/w 可以通過讀取此 CSR 寄存器, 查看當前處於的 Machine Sub-Mode.

        1. 正常機器模式 (Machine Sub-Mode = 0x0)
            > CPU reset 後, 處於此子模式之下.
            如果不產生 exception/NMI/Interrupt, 則一直正常運行於此模式之下.

        1. exception 處理模式 (Machine Sub-Mode = 0x2)
            > 響應 exception 後 CPU 處於此狀態

        1. NMI 處理模式 (Machine Sub-Mode = 0x3)
            > 響應 NMI 後 CPU 處於此狀態

        1. Interrupt 處理模式 (Machine Sub-Mode = x1)
            > 響應 Interrupt 後 CPU 處於此狀態

+ `Supervisor Mode` (S Mode, 0x1) or `Hypervisor mode` (HS mode, 0x1)
    > 監督模式 (通常 kernel space 使用)

+ `User Mode` (U Mode, 0x0)
    > 用戶模式, 只能夠訪問 User Mode 限定的 CSR 寄存器,
    以及 PMP 設定權限的 physical address 區域.

+ `MRET/SRET/URET` instruction
    > 用於從 M mode, S mode 以及 U mode 下的異常返回
    >> 當執行 xRET 指令時, 假設 xPP 為 Y.
    此時 `xIE = xPIE`, 特權模式設置為 Y, `xPIE = 1`, xPP 設置為 U-mode


# Exception and Interrupt

Exception 與 Interrupt 實際上是很容易混用的詞彙,
一般來說, 中斷也是一種異常(廣義上的), 中斷可以看作是來源於外部的異常.

因此在此所說的 Exception 指的是狹義上的異常,
即來源於 CPU 內部發生的異常(e.g. 指令錯誤, ALU執行異常, 寫回存儲器異常, 長指令寫回異常等).

而 Interrupt 則是指 `Exceptions(廣義) - Exceptions(CPU 內部)`

在 RISC-V 架構中, 進入 exception, NMI 或者 interrupt 都可以被統稱為 `Trap`, 而且默認進入 `M-mode`

+ Interrupt type

    - External
        1. Peripheral devices
        1. Global Interrupt Controller

    - Internal
        1. Timer IRQ
        1. S/w IRQ

## Interrupt flow

```
Privileged Mode Y

               Trigger IRQ
                    |
                    v
      +-----------------------------+
      |   CPU update CSRs           |
      | (mepc/mcause/mtval/mstatus) |
      |  xepc = PC                  |
      |  xPIE = xIE                 |
      |  xPP  = Privileged Mode Y   |
      +-----------------------------+
                    |
                    v
               Disable xIE
H/w                 |
____________________|_________________________
Privileged Mode X   |
ISR (S/w)           |
                    v
          Store General Registers
                    |
                    v
                Enable xIE (for Nested Interrupt)
                    |
                    v
            Primary IRQ handler
                    |
                    v
        +---------------------------+
        | Handle other padding IRQs |
        |    check mip register     |
        |       (optional)          |
        +---------------------------+
                    |
                    v
               Disable xIE
                    |
                    v
           Load General Registers
                    |
                    v
                  Reset
            (mret/sret/uret)
____________________|_________________________
H/w                 |
Privileged Mode Y   |
                    v
                Enable xIE
                    |
                    v
                Jump back
              (mepc/sepc/uepc)
```

+ Enter

    - CPU update `mepc`.
        1. Interrupt trigger, 則 `mepc` 寫入 `PC + 4`
        1. Exception trigger, 則 `mepc` 寫入 `PC`

    - CPU update `mcause`.
        > 根據產生 Exception 的類型更新`mcause`.

    - CPU update `mtval`.
        > 某些 Exception 需要將異常相關的信息寫入到 `mtval` 當中

    - CPU update `mstatus`.
        1. 紀錄 Interrupt 發生前的 xIE 及 Privileged Mode

            ```
            xPIE = xIE
            xPP  = Current Privileged Mode
            ```

        1. disable Interrupt
            > 這意味著 RISC-V H/w 預設是不支持嵌套中斷的.
            若要實現嵌套中斷, 則只能通過 S/w 的方式.

            ```
            xIE = 0
            ```

            >> S/w 實現嵌套中斷: 當一個 Interrupt 發生後,
            則 `MPIE = MIE`, MIE = 1, 同時 MPP 設置為 M-mode

    - CPU 跳轉到 `mtvec` 中所定義的異常入口地址執行.
        1. Direct mode, 直接跳轉到 `mtvec` 中的 address 執行
        1. Vectored mode, 根據 `mcause` 中的異常類型,
        跳轉到對應的 Interrupt handler address 執行

+ Leave
    > after xRET

    - CPU 跳轉到 `mepc` 的 address 執行.
        > 回到異常發生前的程序執行

    - CPU update `mstatus`.
        > 將 Interrupt 發生前的 `mstatus` 的狀態恢復.
        具體動作: 此時 `MIE = MPIE`, Privileged Mode 設置為 M-mode,
        `MPIE = 1`, MPP 設置為 M-mode.

## Nested Interrupt

原則上在 RISC-V 架構中, 不支援同 Privilege mode 的 Nested Interrupt
> CPU 在 interrupt 發生時, H/w 會自動 disable IRQ (xstatus.MIE = 0)

不同 Privilege mode, 可依 priority 嵌套中斷
> mstatus.MIE, mstatus.SIE, mstatus.UIE

## Machine Mode To User Mode

從 Machine Mode 切換到 User Mode 只能通過執行 `mret` 指令

```nasm
    /* Switch Machine sub-mode to User mode */
    li t0, MSTATUS_MPP  /* MSTATUS_MPP 的值為 0x00001800, 即對應 mstatus 的 MPP 位域, 請參
                           見第7.4.7節瞭解mstatus的位域詳情 */
    csrc mstatus, t0    /* 將 mstatus 寄存器的 MPP 位域清為 0 */
    la t0, 1f           /* 將前面的 tag 1 所在的 PC 地址賦值給 t0 */
    csrw mepc, t0       /* 將 t0 的值賦值給 CSR 寄存器 mepc */
    mret                /* 執行 mret 指令, 則會將模式切換到 User Mode,
                           並且從 tag 1 處開始執行程序(tag 1 即為 mret 的下一條指令位置) */
1:                      /* tag 1 的位置 */
```

## User Mode To Machine Mode

從 User Mode 切換到 Machine Mode 只能通過 exception, interrupt 或者 NMI 的方式發生

+ exception 處理模式
+ interrupt 處理模式
+ NMI 處理模式

如果在 User Mode下直接執行`mret`指令, 會產生非法指令(Illegal Instruction)異常.

在 User Mode下 CPU 只能夠訪問 PMP 設定權限的物理地址區域,
因此在切換到 User Mode 之前, 需要配置 PMP 相關寄存器,
設定 User Mode 可以訪問的物理地址區域.

## reference

+ [xv6 risc-v trap 筆記](https://blog.csdn.net/RedemptionC/article/details/108718347)
+ [RISC-V異常與中斷機制概述](http://www.sunnychen.top/2019/07/06/RISC-V%E5%BC%82%E5%B8%B8%E4%B8%8E%E4%B8%AD%E6%96%AD%E6%9C%BA%E5%88%B6%E6%A6%82%E8%BF%B0/)
# [CSR (Control and Status Register) of RISC-V](note_riscv_csr.md)


# Reference

+ [riscv-code-models](https://www.francisz.cn/2020/04/14/riscv-code-models/)
+ [大道至簡——RISC-V架構之魂(中)](https://blog.csdn.net/zoomdy/article/details/79580772)
+ [大道至簡——RISC-V架構之魂(下)](https://blog.csdn.net/zoomdy/article/details/79580949)


# GD32VF103 chip

## exception

| 異常編號(Exception Code)| 異常和中斷類型                   |同步/異步 |描述
| :-                      |    :-                            | :-    | :-
| 0                       | 指令地址非對齊                   | 同步  | 指令 PC 地址非對齊.
|                         | (Instruction address misaligned) |       | 注意:該異常類型在配置了"C"擴展指令子集的處理器中不可能發生.
| 1                       | 指令訪問錯誤                     | 同步  | 取指令訪存錯誤.
|                         | (Instruction access fault)       |       | `mdcause` 提供詳細的指令放錯誤類型
| 2                       | 非法指令(Illegal instruction)    | 同步  | 非法指令.
| 3                       | 斷點(Breakpoint)                 | 同步  | RISC-V 架構定義了 EBREAK 指令,
|                         |                                  |       | 當處理器執行到該指令時, 會發生異常進入異常服務程序.
|                         |                                  |       | 該指令往往用於調試器(Debugger)使用, 譬如設置斷點.
| 4                       | 讀存儲器地址非對齊               | 同步  | Load 指令訪存地址非對齊.
|                         | (Load address misaligned)        |       | 注意: N 級別處理器內核支持可配置的地址非對齊的數據存儲器讀寫操作,
|                         |                                  |       | 如果沒有配置此選項或者未打開此開關, 訪問地址非對齊時會產生此異常.
| 5                       | 讀存儲器訪問錯誤                 |非精確異步 | Load指令訪存錯誤.
|                         | (Load access fault)              |           | `mdcause`提供詳細的讀存儲器訪問錯誤類型.
| 6                       | 寫存儲器和AMO地址非對齊          | 同步  | Store 或者 AMO 指令訪存地址非對齊
|                         | (Store/AMO address misaligned)   |       | 注意: N 級別處理器內核支持可配置的地址非對齊的數據存儲器讀寫操作,
|                         |                                  |       | 如果沒有配置此選項或者未打開此開關, 訪問地址非對齊時會產生此異常.
|                         |                                  |       | AMO 指令不支持非對其訪問.
| 7                       | 寫存儲器和AMO訪問錯誤            |非精確異步 | Store 或者 AMO 指令訪存錯誤.
|                         | (Store/AMO access fault)         |           | `mdcause`提供詳細的寫存儲器訪問錯誤類型
| 8                       | 用戶模式環境調用                 | 同步  | User Mode 下執行 ecall 指令.
|                         | (Environment call from U-mode)   |       | RISC-V 架構定義了 ecall 指令, 當處理器執行到該指令時, 會發生異常進入異常服務程序.
|                         |                                  |       |  該指令往往供軟件使用, 強行進入異常模式.
| 11                      | 機器模式環境調用                 | 同步  | Machine Mode 下執行 ecall 指令.
|                         | (Environment call from M-mode)   |       | RISC-V 架構定義了ecall指令, 當處理器執行到該指令時, 會發生異常進入異常服務程序.
|