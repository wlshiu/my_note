RISC-V ASM [[Back](note_riscv_quick_start.md)]
---

`RV32I` 為 32-bits 基本整數指令集, 有 `32` 個 32-bits 暫存器 (x0-x31), 總共有 47 道指令

[riscv-asm-manual](https://github.com/riscv/riscv-asm-manual)

#  syntax field

+ `rs1`
    > Source Register 1

+ `rs2`
    > Source Register 2

+ `rd`
    > Destination Register
    >> receives the result of computation

+ `simm12`
    > sign immediate values 12-bits

# 整數運算指令 (Integer Computational Instructions)

+ 整數暫存器與常數指令 (Integer Register-Immediate Instructions)
    > 為暫存器與常數之間的運算

    - `ADDI`
        > 常數部分(simm12)為 sign-extended 12-bits, 會將 12-bits 做 sign-extension 成 32-bit後,
        再與 <rs1> 做加法運算, 將結果寫入 <rd>

        ```
        addi <rd>, <rs1>, simm12    /* <rd> = <rs1> + simm12 */
        ```

        1. Pseudo Instruction `MV`

        ```
        mv <rd>, <rs1>

        實際上會轉成
        addi <rd>, <rs1>, 0
        ```

    - `SLTI` (Set Less Than Immediate)
        > 常數部分(simm12)為 sign-extended 12-bits, 會將 12-bits 做 sign-extension成 32-bits 後,
        再與 <rs1> 當做 signed number 做比較.
        若 `<rs1> < simm12`, 則將 1 寫入 <rd>, 反之則寫入 0

        ```
        slti <rd>, <rs1>, simm12    /* <rd> = (<rs1> < simm12) ? 1 : 0 */
        ```

    - `SLTIU`
        > 常數部分(simm12)為 sign-extended 12-bits, 會將 12-bits 做 sign-extension成 32-bits後,
        再與 <rs1> 當作 unsigned number 做比較.
        若 `(unsigned)<rs1> < simm12`, 則將 1 寫入 <rd>, 反之則寫入 0

        ```
        sltiu <rd>, <rs1>, simm12   /* <rd> = ((unsigned)<rs1> < simm12) ? 1 : 0 */
        ```

        1. Pseudo Instruction `SEQZ`

            ```
            SEQZ <rd>, <rs1>

            實際上會轉成
            SLTIU <rd>, <rs1>, 1
            ```

    - `ANDI/ORI/XORI`
        > 常數部分(simm12)為 sign-extended 12-bits, 會將 12-bits 做 sign-extension成 32-bits後,
        再與 <rs1> 做 AND/OR/XOR 運算, 將結果寫入 <rd>

        ```
        andi/ori/xori <rd>, <rs1>, simm12
        ```

        1. Pseudo Instruction `NOT`

            ```
            NOT <rd>, <rs1>

            實際上會轉成
            XORI <rd>, <rs1>, -1
            ```

    - `SLLI/SRLI/SRAI`
        > 常數部分(uimm5)為 unsigned 5-bits, 範圍為 0~31, 為 shift amount,
        將 <rs1> 做 shift 運算, 結果寫入 <rd>
        > + SLLI: logical 左移, 會補 0 到 LSB
        > + SRLI: logical 右移, 會補 0 到 MSB
        > + SRAI: arithmetic 右移, 會將原本的 sign-bit 複製到 MSB

        ```
        slli/srli/srai <rd>, <rs1>, uimm5
        ```

    - `LUI` (Load Upper Immediate)
        > 將常數部分(uimm20)的 unsigned 20-bits 放到 <rd> 的最高 20-bits, 並將剩餘的 12-bits 補 0.
        此指令可與 ADDI 搭配, 一起組合出完整 32-bits 的數值
        >> 用來將任意的 32-bits 無符號整數 拷貝到寄存器當中.
        它也可以和 load 以及 store 指令一起使用來加載, 或者存儲 32-bits 靜態地址的存儲空間.

        ```
        lui <rd>, uimm20        /* <rd> = (uimm20 & 0xFFFFF) << 12; */
        ```

    - `AUIPC` (Add Upper Immediate to pc)
        > 將常數部分(uimm20)的 unsigned 20-bits 放到 <rd> 的最高 20-bits, 剩餘 12-bits 補 0.
        將此數值與 pc 相加寫入 <rd>
        >> `AUIPC`是 RISC-V 基址尋址機制的基礎, 以 PC 作為基址寄存器來進行尋址, 創建 pc 的相對 address

        ```
        auipc <rd>, uimm20      /* <rd> = pc + ((uimm20 & 0xFFFFF) << 12); */
        ```

+ 整數暫存器與暫存器指令 (Integer Register-Register Insructions)
    > 暫存器與暫存器之間的運算

    - `ADD/SUB`
        > 將 <rs1> 與 <rs2> 做加法/減法運算, 將結果寫入 <rd>

        ```
        add/sub <rd>, <rs1>, <rs2>
        ```

    - `SLT/SLTU`
        > 將 <rs1> 與 <rs2<> 當做 singed/unsigned number 做比較;
        若 `<rs1> < <rs2>`, 則將數值 1 寫入 <rd>, 反之則寫入數值 0.
        > + SLT: signed little then
        > + SLTU: unsigned little then

        ```
        slt/sltu rd, rs1, rs2
        ```

    - `AND/OR/XOR`
        > 將 <rs1> 與 <rs2> 做 AND/OR/XOR 運算, 將結果寫入 <rd>

        ```
        and/or/xor <rd>, <rs1>, <rs2>
        ```

    - `SLL/SRL/SRA`
        > 將 <rs1> 做 shift 運算, 結果寫入 <rd>, <rs2> 的`最低 5-bits` 為 shift amount
        > + SLL: shift logical left
        > + SRL: shift logical right
        > + SRA: shift arithmetic right

        ```
        sll/srl/sra <rd>, <rs1>, <rs2>
        ```

+ `NOP`
    > 不改變任何暫存器狀態, 除了 pc 以外.
    NOP 指令會被編碼成 `addi x0, x0, 0` 替代


# 控制轉移指令 (Control Transfer Instructions)

+ 無條件跳轉 (Unconditional Jumps)

    - `JAL` (jump and link)

        1. syntax

            ```
            jal <rd>, simm21
            ```
            > + 常數部分(simm21)為 sign-extended 21-bits, 此常數必須為 `2-align`.
            > + 跳轉範圍為 `-/+ 1MiB` (bit[20] is sign, bit[19~0] is data)
            > + 同時也會將下一道指令的位址 `pc+4` 寫入 <rd> 中,
            在標準的 calling convention 中, <rd> 會使用 `x1`
            >> `x1` 等同於 ARM 的 `lr` (link register)

        1. 如果只是單純的 jump, 不需要紀錄 `pc+4` address, 可用 `jal x0, simm21` 取代

    - `JALR` (jump and link register)

        1. syntax

            ```
            jalr <rd>, <rs1>, simm12
            ```

            > + 常數部分(simm12)為 sign-extended 12-bits
            > + 跳轉範圍為 `-/+ 2KiB` (bit[11] is sign, bit[10~0] is data)
            > + 跳轉的位址為 `<rs1> + simm12`, 並把下一道指令的位址 `pc+4` 寫入 <rd>


+ 條件跳轉 (Conditional Branches)

    ```
    beq/bne/blt/bltu/bge/bgeu <rs1>, <rs2>, simm13
    ```

    - 常數部分(simm13)為 sign-extended 13-bit, 此常數必須為 `2-align`.
    - 跳轉範圍為 `-/+ 4KiB` (bit[12] is sign, bit[11~0] is data)

    - `BEQ/BNE`

        ```
        BEQ: if( <rs1> == <rs2> ) goto (pc+simm13)
        BNE: if( <rs1> != <rs2> ) goto (pc+simm13)
        ```
    - `BLT/BLTU`

        ```
        BLT : if( <rs1> < <rs2> ) goto (pc+simm13)
        BLTU: if( (unsigned)<rs1> < (unsigned)<rs2> ) goto (pc+simm13)
        ```

    - `BGE/BGEU`

        ```
        BGE : if( <rs1> > <rs2> ) goto (pc+simm13)
        BGEU: if( (unsigned)<rs1> > (unsigned)<rs2> ) goto (pc+simm13)
        ```

# 載入與儲存指令 (Load and Store Instructions)

RV32I 必須使用載入(load)與儲存(store)指令去存取記憶體, 前面的運算指令只能夠對暫存器做操作

+ `LW/LH/LHU/LB/LBU`
    > <rs> 暫存器作為 base address, 加上有符號的偏移, 載入到 <rd> 暫存器

    - syntax

        ```
        lw/lh/lhu/lb/lbu <rd>, <rs1>, simm12
        ```

    - 常數部分(simm12)為 `sign-extended 12-bit`, 載入位址則為 `<rs1> + simm12`

    - `LW`
        > 載入 32-bits 資料寫入 <rd>

        ```
        <rd> = Mem_Addr(imm[11:0] + <rs1>)
        ```

    - `LH/LHU`
        > 載入 16-bits 資料分別做 unsigned/signed extension 成 32-bits 後寫入 <rd>
        >> `LH` is sign (MSB is sing field), `LHU` is unsign

        ```
        <rd> = (Mem_Addr(imm[11:0] + <rs1>) & 0xFFFF)
        ```

    - `LB/LBU`
        > 載入 8-bits 資料分別做 unsigned/signed extension 成 32-bits 後寫入 <rd>
        >> `LB` is sign (MSB is sing field), `LBU` is unsign

        ```
        <rd> = (Mem_Addr(imm[11:0] + <rs1>) & 0xFF)
        ```

+ `SW/SH/SB`
    > <rs1> 作為 base address 加上有符號的偏移, 作為內存地址, 寫入內容為 <rs2>

    - syntax

        ```
        sw/sh/sb <rs2>, <rs1>, simm12
        ```

    - 常數部分(simm12)為 `sign-extended 12-bit`, 儲存位址則為 `<rs1> + simm12`

    - `SW`
        > 將 <rs2> 暫存器完整 32-bits 資料寫入記憶體

        ```
        Mem_Addr(imm[11:0] + <rs1>) = <rs2>
        ```

    - `SH`
        > 將 <rs2> 暫存器最低 16-bits 資料寫入記憶體

        ```
        Mem_Addr(imm[11:0] + <rs1>) = (<rs2> & 0xFFFF)
        ```

    - `SB`
        > 將 <rs2> 暫存器最低 8-bits 資料寫入記憶體

        ```
        Mem_Addr(imm[11:0] + <rs1>) = (<rs2> & 0xFF)
        ```

# Memory barrier - `FENCE`

RISC-V 對於本身所要執行對 RAM 的加載和存儲是可感知的,
但是在 multi-threads 的環境當中, 不能保證一個 thread 能夠感知其他 threads 的 RAM 交互操作.
這種設計也稱為鬆弛的內存模型.

在 RV32I 中, 施加強制的 RAM 訪問順序是顯式提供的.
RV32I 提供 `FENCE` 指令來保證在 `FENCE` 指令之前和之後執行的 RAM 訪問指令是有順序的

ps. FENCE 指令猶如一道屏障, 把前面的存儲操作和後面的存儲操作隔離開來,
前面的決不能到後面再執行, 後面的決不能先於 FENCE 前的指令執行

```
FENCE pred, succ
```

`pred` 和 `succ` 指的是在 `FENCE`指令之前(pred)和之後(succ)的內存交互類型:
> + `R`: 內存加載
> + `W`: 內存存儲
> + `I`: 設備輸入
> + `O`: 設備輸出

+ example

    ```
    fence rw, w
    ```

    1. 上述指令表示, 在 FENCE 指令之前, 所有的 read 和 write 指令,
    一定會在 FENCE 指令之後, 第一個 write 指令之前執行完畢.

+ `fence.i` (Extending instruction, optional)
    > 用來同步指令流與內存訪問.
    可以保證在 `fence.i`之前的 RAM 存儲一定會比`fence.i`之後的先完成
    >> To synchronize the instruction stream with data memory accesses

    - 當 CPU 有 I-Cache 及 D-Cache 機制時, 需要有同步機制來保證 instruction coherence.
    `fence.i` 一般可以採用 invalidate I-Cache, 來強制更新 cache

    - `fence.i` 和 `fence` 指令不同, 並不是必須的指令
        > 有一些系統實現 `fence.i` 的代價會很大

+ Mapping with ARM

ARM Operation           | RVWMO Mapping
:---------------        | :-----------
Load                    | l{b\|h\|w\|d}
Load-Acquire            | fence rw, rw; l{b\|h\|w\|d}; fence r,rw
Load-Exclusive          | lr.{w\|d}
Load-Acquire-Exclusive  | lr.{w\|d}.aqrl
Store                   | s{b\|h\|w\|d}
Store-Release           | fence rw,w; s{b\|h\|w\|d}
Store-Exclusive         | sc.{w\|d}
Store-Release-Exclusive | sc.{w\|d}.rl
dmb                     | fence rw,rw
dmb.ld                  | fence r,rw
dmb.st                  | fence w,w
isb                     | fence.i; fence r,r

+ Mapping with Linux

Linux Operation     | RVWMO Mapping
:-------------      | :----------
smp_mb()            |   fence rw,rw
smp_rmb()           |   fence r,r
smp_wmb()           |   fence w,w
dma_rmb()           |   fence r,r
dma_wmb()           |   fence w,w
mb()                |   fence iorw,iorw
rmb()               |   fence ri,ri
wmb()               |   fence wo,wo
smp_load_acquire()  |   l{b\|h\|w\|d}; fence r,rw
smp_store_release() |   fence.tso; s{b\|h\|w\|d}


# 控制與狀態暫存器指令 (Control and Status Register Instructions)

+ CSR Instructions

    - `CSRRW/CSRRS/CSRRC/CSRRWI/CSRRSI/CSRRCI`
        > 定義了一組 CSR 指令, 可用來讀取/寫入 CSR

+ Timers and Counters

    - `RDCYCLE[H]`
        > `rdcycle` 用來讀取最低 31-bits cycle CSR, `rdcycleh` 用來讀取最高 31-bits cycle 數

    - `RDTIME[H]`
        > 用來讀取 time CSR

    - `RDINSTRET`
        > 用來讀取 instret CSR

# Environment Call and Breakpoints

+ `ECALL`
    > 使用來呼叫 system call.

+ `EBREAK`
    > Debugger 用來切換進 Debugging 環境.



# Pseudo Ops

Both the RISC-V-specific and GNU .-prefixed options.

The following table lists assembler directives:

Directive    | Arguments                      | Description
:----------- | :-------------                 | :---------------
.align       | integer                        | align to power of 2 (alias for .p2align)
.file        | "filename"                     | emit filename FILE LOCAL symbol table
.globl       | symbol_name                    | emit symbol_name to symbol table (scope GLOBAL)
.local       | symbol_name                    | emit symbol_name to symbol table (scope LOCAL)
.comm        | symbol_name,size,align         | emit common object to .bss section
.common      | symbol_name,size,align         | emit common object to .bss section
.ident       | "string"                       | accepted for source compatibility
.section     | [{.text,.data,.rodata,.bss}]   | emit section (if not present, default .text) and make current
.size        | symbol, symbol                 | accepted for source compatibility
.text        |                                | emit .text section (if not present) and make current
.data        |                                | emit .data section (if not present) and make current
.rodata      |                                | emit .rodata section (if not present) and make current
.bss         |                                | emit .bss section (if not present) and make current
.string      | "string"                       | emit string
.asciz       | "string"                       | emit string (alias for .string)
.equ         | name, value                    | constant definition
.macro       | name arg1 [, argn]             | begin macro definition \argname to substitute
.endm        |                                | end macro definition
.type        | symbol, @function              | accepted for source compatibility
.option      | {rvc,norvc,pic,nopic,push,pop} | RISC-V options
.byte        | expression [, expression]*     | 8-bit comma separated words
.2byte       | expression [, expression]*     | 16-bit comma separated words
.half        | expression [, expression]*     | 16-bit comma separated words
.short       | expression [, expression]*     | 16-bit comma separated words
.4byte       | expression [, expression]*     | 32-bit comma separated words
.word        | expression [, expression]*     | 32-bit comma separated words
.long        | expression [, expression]*     | 32-bit comma separated words
.8byte       | expression [, expression]*     | 64-bit comma separated words
.dword       | expression [, expression]*     | 64-bit comma separated words
.quad        | expression [, expression]*     | 64-bit comma separated words
.dtprelword  | expression [, expression]*     | 32-bit thread local word
.dtpreldword | expression [, expression]*     | 64-bit thread local word
.sleb128     | expression                     | signed little endian base 128, DWARF
.uleb128     | expression                     | unsigned little endian base 128, DWARF
.p2align     | p2,[pad_val=0],max             | align to power of 2
.balign      | b,[pad_val=0]                  | byte align
.zero        | integer                        | zero bytes

+ `.option`
    > 區域性修改配置

    - disable relaxation
        > 從 push 到 pop 這段區域, 取消 relaxation 功能

        ```
        .option push
        .option norelax
            la gp, __global_pointer$
        .option pop
        ```

# Assembler Relocation Functions

The following table lists assembler relocation expansions:

Assembler Notation          | Description                    | Instruction / Macro
:----------------------     | :---------------               | :-------------------
%hi(symbol)                 | Absolute (HI20)                | lui
%lo(symbol)                 | Absolute (LO12)                | load, store, add
%pcrel_hi(symbol)           | PC-relative (HI20)             | auipc
%pcrel_lo(label)            | PC-relative (LO12)             | load, store, add
%tprel_hi(symbol)           | TLS LE "Local Exec"            | lui
%tprel_lo(symbol)           | TLS LE "Local Exec"            | load, store, add
%tprel_add(symbol)          | TLS LE "Local Exec"            | add
%tls_ie_pcrel_hi(symbol) \* | TLS IE "Initial Exec" (HI20)   | auipc
%tls_gd_pcrel_hi(symbol) \* | TLS GD "Global Dynamic" (HI20) | auipc
%got_pcrel_hi(symbol) \*    | GOT PC-relative (HI20)         | auipc

\* These reuse %pcrel_lo(label) for their lower half


# Standard Pseudo-instructions of RISC-V

Pseudoinstruction            | Base Instruction(s)                                           | Meaning
:----------------------------|:--------------------------------------------------------------|:-------
la rd, symbol                | auipc rd, symbol[31:12]; addi rd, rd, symbol[11:0]            | Load address
l{b\|h\|w\|d} rd, symbol     | auipc rd, symbol[31:12]; l{b\|h\|w\|d} rd, symbol[11:0]\(rd\) | Load global
s{b\|h\|w\|d} rd, symbol, rt | auipc rt, symbol[31:12]; s{b\|h\|w\|d} rd, symbol[11:0]\(rt\) | Store global
fl{w\|d} rd, symbol, rt      | auipc rt, symbol[31:12]; fl{w\|d} rd, symbol[11:0]\(rt\)      | Floating-point load global
fs{w\|d} rd, symbol, rt      | auipc rt, symbol[31:12]; fs{w\|d} rd, symbol[11:0]\(rt\)      | Floating-point store global
nop                          | addi x0, x0, 0                                                | No operation
li rd, immediate             | *Myriad sequences*                                            | Load immediate
mv rd, rs                    | addi rd, rs, 0                                                | Copy register
not rd, rs                   | xori rd, rs, -1                                               | One’s complement
neg rd, rs                   | sub rd, x0, rs                                                | Two’s complement
negw rd, rs                  | subw rd, x0, rs                                               | Two’s complement word
sext.w rd, rs                | addiw rd, rs, 0                                               | Sign extend word
seqz rd, rs                  | sltiu rd, rs, 1                                               | Set if = zero
snez rd, rs                  | sltu rd, x0, rs                                               | Set if != zero
sltz rd, rs                  | slt rd, rs, x0                                                | Set if < zero
sgtz rd, rs                  | slt rd, x0, rs                                                | Set if > zero
fmv.s rd, rs                 | fsgnj.s rd, rs, rs                                            | Copy single-precision register
fabs.s rd, rs                | fsgnjx.s rd, rs, rs                                           | Single-precision absolute value
fneg.s rd, rs                | fsgnjn.s rd, rs, rs                                           | Single-precision negate
fmv.d rd, rs                 | fsgnj.d rd, rs, rs                                            | Copy double-precision register
fabs.d rd, rs                | fsgnjx.d rd, rs, rs                                           | Double-precision absolute value
fneg.d rd, rs                | fsgnjn.d rd, rs, rs                                           | Double-precision negate
beqz rs, offset              | beq rs, x0, offset                                            | Branch if = zero
bnez rs, offset              | bne rs, x0, offset                                            | Branch if != zero
blez rs, offset              | bge x0, rs, offset                                            | Branch if ≤ zero
bgez rs, offset              | bge rs, x0, offset                                            | Branch if ≥ zero
bltz rs, offset              | blt rs, x0, offset                                            | Branch if < zero
bgtz rs, offset              | blt x0, rs, offset                                            | Branch if > zero
bgt rs, rt, offset           | blt rt, rs, offset                                            | Branch if >
ble rs, rt, offset           | bge rt, rs, offset                                            | Branch if ≤
bgtu rs, rt, offset          | bltu rt, rs, offset                                           | Branch if >, unsigned
bleu rs, rt, offset          | bgeu rt, rs, offset                                           | Branch if ≤, unsigned
j offset                     | jal x0, offset                                                | Jump
jal offset                   | jal x1, offset                                                | Jump and link
jr rs                        | jalr x0, rs, 0                                                | Jump register
jalr rs                      | jalr x1, rs, 0                                                | Jump and link register
ret                          | jalr x0, x1, 0                                                | Return from subroutine
call offset                  | auipc x6, offset[31:12]; jalr x1, x6, offset[11:0]            | Call far-away subroutine
tail offset                  | auipc x6, offset[31:12]; jalr x0, x6, offset[11:0]            | Tail call far-away subroutine
fence                        | fence iorw, iorw                                              | Fence on all memory and I/O

# Pseudo-instructions for accessing control and status registers

Pseudo-instruction | Base Instruction(s)        | Meaning
:---------------- |:---------------------------|:-------
rdinstret[h] rd   | csrrs rd, instret[h], x0   | Read instructions-retired counter
rdcycle[h] rd     | csrrs rd, cycle[h], x0     | Read cycle counter
rdtime[h] rd      | csrrs rd, time[h], x0      | Read real-time clock
csrr rd, csr      | csrrs rd, csr, x0          | Read CSR
csrw csr, rs      | csrrw x0, csr, rs          | Write CSR
csrs csr, rs      | csrrs x0, csr, rs          | Set bits in CSR
csrc csr, rs      | csrrc x0, csr, rs          | Clear bits in CSR
csrwi csr, imm    | csrrwi x0, csr, imm        | Write CSR, immediate
csrsi csr, imm    | csrrsi x0, csr, imm        | Set bits in CSR, immediate
csrci csr, imm    | csrrci x0, csr, imm        | Clear bits in CSR, immediate
frcsr rd          | csrrs rd, fcsr, x0         | Read FP control/status register
fscsr rd, rs      | csrrw rd, fcsr, rs         | Swap FP control/status register
fscsr rs          | csrrw x0, fcsr, rs         | Write FP control/status register
frrm rd           | csrrs rd, frm, x0          | Read FP rounding mode
fsrm rd, rs       | csrrw rd, frm, rs          | Swap FP rounding mode
fsrm rs           | csrrw x0, frm, rs          | Write FP rounding mode
fsrmi rd, imm     | csrrwi rd, frm, imm        | Swap FP rounding mode, immediate
fsrmi imm         | csrrwi x0, frm, imm        | Write FP rounding mode, immediate
frflags rd        | csrrs rd, fflags, x0       | Read FP exception flags
fsflags rd, rs    | csrrw rd, fflags, rs       | Swap FP exception flags
fsflags rs        | csrrw x0, fflags, rs       | Write FP exception flags
fsflagsi rd, imm  | csrrwi rd, fflags, imm     | Swap FP exception flags, immediate
fsflagsi imm      | csrrwi x0, fflags, imm     | Write FP exception flags, immediate


# reference
+ [RISC-V 指令集架構介紹 - RV32I](https://tclin914.github.io/16df19b4/)
+ [RISC-V基本指令集概述](http://www.sunnychen.top/2019/07/06/RISC-V%E5%9F%BA%E6%9C%AC%E6%8C%87%E4%BB%A4%E9%9B%86%E6%A6%82%E8%BF%B0/)
+ [riscv instruction](https://www.francisz.cn/2020/06/23/riscv-instruction/)
