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


## View Preprocessor macros

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



## [實務範例操作](note_riscv_practice.md)


# [RISC-V 指令集](note_riscv_asm.md)


# Reference

+ [riscv-code-models](https://www.francisz.cn/2020/04/14/riscv-code-models/)


