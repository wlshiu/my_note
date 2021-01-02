AndesCore register
---

# Concept

+ interrupt v.s exception
    > 兩者行為很類似, 但所代表的意義不同, 因此會分開討論

    - exception
        > 由 CPU 自己發出

        1. CPU_Trap_TLB_Fill
        1. CPU_Trap_PTE_Not_Present
        1. CPU_Trap_TLB_Misc
        1. CPU_Trap_TLB_VLPT_Miss
        1. CPU_Trap_Machine_Error
        1. CPU_Trap_Debug_Related
        1. CPU_Trap_General_Exception
        1. CPU_Trap_Syscall
        1. CPU_Trap_Interrupt_SWI

    - interrupt
        > 由 internal/external interrupt controller 發出, 基本是 peripheral 或是 H/w modules

# PSW (Processor Status Word Register )

## GIE, bit[0]

Global Interrupt Enable
> Non-Maskable Interrupt (NMI) cannot be disabled by this bit


## INTL, bit[2,1]

Interruption Stack Level

+ Nesting Interrupt

    因為 nds32 H/w 資源有限, 每增加一級, H/w 備份的資訊就越少, 基本到 leve 2 就不更新了.

    因此會讓 interrupt class, 在 level 在 0 到 1 之間切換,
    當有更高優先權的 exception class 發生時, 才會讓其進入 level 2 來處理.

    基於以上原因, 要達到 Nesting IRQ 需要額外處理.

    - 進入 ISR 時, 先做降級 (level 1 -> level 0)
    - save system registers ($PSW, $IPC, $IPSW) to stack
    - enable GIE
        > H/w 進入 ISR 時, 會自動 disable GIE, 重新 enable GIE 來接收 IRQ envent
    - 進入對應的 handler
    - 離開 handler時
        1. disable GIE (H/w 離開 ISR 時, 會自動 enable GIE)
        1. restore system registers ($PSW, $IPC, $IPSW) from stack


## POM, bit[4,3]

Processor Operation Mode

0: user mdoe
1: superuser mode

## BE, bit[5]

Endian

## IT, bit[6]

Instruction address Translation

MMU 相關 ?


## DT, bit[7]

Data address Translation

MMU 相關 ?

## IME, bit[8]

Instruction Machine Error flag

當 Exception 發生在 I-cache 或是 ILM, IME 會被拉起,
需要 clear 才能離開 exception status

+ 通常發生的原因

    - Instruction cache locking error
    - Instruction parity/ECC error
    - Instruction TLB locking error
    - Instruction TLB multiple hit

## DME, bit[9]

Data Machine Error flag

當 Exception 發生在 D-cache 或是 DLM, DME 會被拉起,
需要 clear 才能離開 exception status

+ 通常發生的原因

    - Data cache locking error
    - Data parity/ECC error
    - Data TLB locking error
    - Data TLB multiple hi

## DEX, bit[10]

Debug Exception

當 ICE 接入時會發出

## HSS, bit[11]

Hardware Single Stepping

跟 ICE 相關 ?

## DRBE, bit[12]

Device Register Endian mode

## AEN, bit[13]

Audio ISA special features enable

## *WBNA, bit[14]

write-back with `write-allocation` or `no-write-allocation`

+ write-allocation (0x0)
    > In write-back mode, 當 cache miss 時, 先將資料從主記憶體中載入到cache,
    然後再依 cache hit 的規則, 將資料寫出

+ no-write-allocation (0x1)
    > In write-back mode, 當 cache miss 時, 直接將資料寫到主記憶體中, 不會再從記憶體中載入到 cache

## IFCON, bit[15]

`IFC` related instructions

inline function optimization

## CPL, bit[18, 16]

Current Priority Level

目前 interrupt 的優先權, 只有優先權高於 CPL 的 IRQ, 才能中斷目前的 interrupt

0: No interrupts are allowed

7: Allows interrupts with any priority


## OV, bit[20]

Overflow flag

## PFT_EN, bit[21]

Enable performance throttling

根據 `PFT_CTL.T_LEVEL` 來決定

## PNP, bit[22]

Pending Next-Precise exceptions




# INT_MASK (Interruption Masking Register )

## H5IM ~ H0IM, bit[5,0]

Hardware Interrupt 0~5 Mask bits.

0: interrupt is disabled.
1: interrupt is enable.

## H15IM ~ H6IM, bit[15, 6]

Hardware Interrupt 6~15 Mask bits.

0: interrupt is disabled.
1: interrupt is enable.

## *SIM, bit[16]

Software Interrupt Mask bit

0: interrupt is disabled.
1: interrupt is enable.

## IMPE, bit[28]

Enable imprecise exception

0: An imprecise exception is blocked by `PSW.GIE`.
1: An imprecise exception can happen without checking `PSW.GIE`.

## ALZ, bit[29]

exception issue when All zero opcode


## *IDIVZE, bit[30]

exception issue when Divide-By-Zero

## DSSIM, bit[31]

Default Single Stepping Interruption Mask

depend on `PSW.HSS`


# INT_CTRL (Interrupt Control Register )

## PPL2FIX_EN, bit[0]

Programmable Priority Level (PPL) to Fixed Priority Level (FIX) Enable.

All interrupts become the same level (auto disable PSW.CPL)


# ICM_CFG (Instruction Cache/Memory Configuration Register)

## ISZ, bit[8, 6]

I-Cache line size

Encoding | Meaning
:-:      | :-
0        | `No Icache`
1        | 8 bytes
2        | 16 bytes
3        | 32 bytes
4        | 64 bytes
5        | 128 bytes
6-7      | Reserved



# DCM_CFG (Data Cache/Memory Configuration Register)

## DSZ, bit[8, 6]

D-Cache line size

Encoding | Meaning
:-:      | :-
0        | `No Icache`
1        | 8 bytes
2        | 16 bytes
3        | 32 bytes
4        | 64 bytes
5        | 128 bytes
6-7      | Reserved


# MMU_CTL (MMU Control Register)

## NTC0, bit[2, 1]

Non-translated Cacheability memory attribute for `partition 0`

Value  | Meaning
:-:    | :-
0      | Non-cacheable/Non-coalesable
1      | Non-cacheable/Coalesable
2      | Cacheable/Write-Back
3      | Cacheable/Write-Through

## NTC1, bit[4, 3]

Non-translated Cacheability memory attribute for `partition 1`

Value  | Meaning
:-:    | :-
0      | Non-cacheable/Non-coalesable
1      | Non-cacheable/Coalesable
2      | Cacheable/Write-Back
3      | Cacheable/Write-Through


# CACHE_CTL ($mr8, Cache Control Register)

## IC_EN, bit[0]

I-Cache Enable

## DC_EN, bit[1]

D-Cache Enable

## ICALCK, bit[2]

I-cache all-lock resolution scheme

0: Generates a `Machine Error` exception.

## DCALCK, bit[3]

D-cache all-lock resolution scheme

0: Generates a `Machine Error` exception.

## DCCWF, bit[4]

D-cache Critical Word Forwarding

## DCPMW, bit[5]

D-cache concurrent (parallel) miss and write-back processing

## IC_ECCEN, bit[7, 6]

Enable I-Cache Parity/ECC scheme

## DC_ECCEN, bit[9, 8]

Enable D-Cache Parity/ECC scheme

## FWTM, bit[10]

Force to the write-through mode (optional)

The existence of this bit should be checked
by writing then reading it back



# IVB (Interruption Vector Base Register )

## PROG_PRI_LVL, bit[0] (RO)

Programmable Priority Level

programmable priority or fixed priority.

## NIVIC, bit[3, 1] (RO)

Number of input for Internal Vector Interrupt Controller.

Value  | Meaning
:-:    | :-
0      | 6 interrupt input sources
1      | 2 interrupt input sources
2      | 10 interrupt input sources
3      | 16 interrupt input sources
4      | 24 interrupt input sources
5      | 32 interrupt input sources
6-7    | Reserved


## EVIC, bit[13]

Vector Interrupt Controller mode

0 : Internal Vector Interrupt Controller mode.
1 : `External` Vector Interrupt Controller mode.

## ESZ, bit[15, 14]

The size of each vector entry

Value | Meaning
:-:   | :-
0     | 4 Byte
1     | 16 Byte
2     | 64 Byte
3     | 256 Byte


## IVBASE, bit[31, 16]

The base physical address of the interruption vector table.

`64KB align (address >> 16)`

