Nuclei RISCV Interrupt [[Back](n_riscv_intro.md#Interrupt_n100)]
---

**Nuclei-N1xx** 對比 **8051**, 因此沒有嚴格遵循標準 `riscv-privileged-v1.10.pdf`, 而是對其進行了簡化和刪減, 從而達到最小化面積和功耗的效果.
> + Privilege Modes: **Nuclei-N1xx** 只支援 Machine Mode (M-Mode)


# Definitions

+ Hart
    > 指 CPU Core

- Interrupt
    > 由 RISC-V Hart 運行的程序, 意外被打斷, 轉向處理意外事件的一種機制, e.g. peripheral interrupts

- Exception
    > RISC-V Hart 在正常運行的過程中, 突然發生了意外的情況. e.g. unknown memory, invalid instruction, ...etc.

+ Trap (陷阱)
    > 主動的被喚起去做一件被預期的事, 就像是主動掉入一個 Trap.
    >> **Trap 意義等同 ISR**, Exception (含 NMI) 和 Interrupt 都被統稱為 Trap handle

+ retire instruction (指令退休)
    > instructions 在 CPU 內部執行的時候, 為了執行效率, 不一定會以順序執行的 (基本亂序執行).
    但若 CPU 想要正確地執行程序, 就必須按照程序中序列順序,
    因此會在 CPU pipline 中, 定義不同的 stages, 通常最後一級為 commit stage.

    > 當一條 instruction 到達 commit stage 後, 會將這條 instruction 在 re-order cache 中, 標記為已完成的狀態.
    需要注意的是, 這個狀態只表示這條 instruction 已經計算完畢, 並不表示它可以離開 pipline.

    >> 只有在 re-order cache 中, 之前所有指令變為已完成的狀態時, 這條指令才允許離開 pipline,
    並使用它的結果, 來更新 CPU 的狀態, 此時稱這條指令退休(retire)了

+ CLINT (Core-Local Interruptor)
    > 屬內部中斷, 標準只規定了有兩種, 即 `timer` and `software` interrupts
    >> 沒有 arbiter (只要有中斷馬上響應), e.g. S/w interrupt 直接寫 register 觸發 IRQ

+ PLIC (Platform-Level Interrupt Controller)
    > 屬外部中斷, 所有的 peripheral interrupts
    >> 需要 arbiter, 因此有`優先權`問題

+ CLIC (Core-Local Interrupt Controller)
    > 可當作是 `CLINT` + `PLIC`, 可以支援一定數目外部中斷

+ ECLIC (Enhanced Core Local Interrupt Controller)
    > Nuclei-N200 在 CLIC 基礎上優化而來, 只處理單核心(Private inside a core)


+ Tail-chaining (中斷咬尾)
    > 在低優先級中斷 ISR 中, 被高優先級的中斷打斷.
    為提高效率, 只做一次 Push/Pop Stack 的動作
    >> 有些似乎稱為 `interrupt preemptible` ?

    ```
    Push-Stack -> ISR_low_priority_FrontHalf -> ISR_high_priority -> ISR_low_priority_BackHalf -> Pop-Stack
    ```

+ Interrupt Response Latency (中斷響應延遲)
    > 從外部中斷源觸發, 到執行 ISR 內的第一條 instructioin, 所花費的時間.
    >> 中間會經過幾個步驟
    >> - 查表尋找對應的 ISR 的時間
    >> - Save Context 的時間
    >> - Hart 跳轉到 ISR 的時間

# Exception/Interrupt 響應

RISC-V spec (riscv-privileged-v1.10) 裡只對 `mtvec` 和 `mcause` 做了最基礎的規範, 不同 vendor 會有實作上的差異

## Exception flow

**Nuclei-N100** 不支援 Nested Exception, 如果發生, 屬於 Critical Fail, 無法預估會發生什麼事

+ Priority of Exception
    > `Exception-Code 越小, Priority 就越高`

當發生 Exception 時, Hart 會跳轉到 `mtvec` 紀錄的 entry address

### Exception Enter

> 當進入 exception routine 時, **Hart 自動在 1T(sysclk) 內完成以下步驟**
> + Hart 更新 CSRs (`mcause`, `mepc`, `mstatus`)

+ Hart 保存 PC 到 `mepc` 中
    > Hart 將觸發 Exception 時的 PC (Program Counter) 記錄到 `mepc`;
      當離開 Exception 時, 藉由 `mepc` 跳轉回原 PC address
    >> `mepc` 可以被 S/w 修改, 因此 S/w 可以強制修改跳轉的 address


+ Hart 將 `mcause.EXCCODE`, 更新為當前造成 Exception 的 code number 且 `mcause.INTERRUPT` 設為 0
+ Hart 將發生 Exception 前的 `mstatus.MIE`, 保存到 `mstatus.MPIE`
    > `mstatus.MPIE` 是為了能在離開 Exception 時, 利用 `mstatus.MPIE` 來恢復進入 Exception 前的 `mstatus.MIE`
+ Hart 將 `mstatus.MIE` 設為 0, 停止 Exception 觸發



### Exception Handle

> `此階段之後全由 S/w 接手`

+ Save Context
    > + RV32E 需保存 `GPR * 14` (?)
    > + RV32I 需保存 `GPR * 20`

+ Save CSRs Context
    > Push CSRs `mepc`, `mcause`

+ Handle Exception
    > 由 S/w 決定要使用何種 Exception Handler (call C-code function)
    > + argv[0]: mcause
    > + argv[1]: sp

+ Restore CSRs Context
    > Pop CSRs `mepc`, `mcause`

+ Restore Context
    > + RV32E 需恢復 `GPR * 14` (?)
    > + RV32I 需恢復 `GPR * 20`

### Exception Leave

> 返回時, S/w 須執行 `mret` instruction, 此指令會讓 **Hart 自動在 1T(sysclk) 內執行以下步驟**
> + 跳轉到 `mepc` 紀錄的 address
> + Hart 更新 CSRs (`mstatus`)

+ `ecall/ebrack` instruction 觸發 Exception 時, S/w 可能須要在 handler 中, 改變 `mepc` 指向下一條 instruction
    > 由於現在 `ecall/ebreak` 都是 4-bytes 指令, 可以明確知道下一條 instruction 會 offset 4-bytes

    ```
    mepc = mepc + 4
    ```

+ Hart 將 `mstatus.MIE` 恢復為 `mstatus.MPIE` 內的值, `mstatus.MPIE` 設為 1


## Interrupt flow

**Nuclei-N100** 統一由 IRQC 處理 Internal (2) and External (32-2) Interrupt
> Internal Interrupt 固定為
> + IRQ_0: SWI
>> 可藉由設定 `msip.MSIP` 產生
> + IRQ_1: SysTimer
>> 可藉由設定 System Timer Unit 來產生


+ Priority of Interrupt
    > `IRQ ID 越大, Priority 就越高`

**Nuclei-N100** 不支援 H/w Nested Interupt

**Nuclei-N100** 會使用 IRQC 的 Interrupt Vectored mode (向量中斷);
當 Interrupt 發生時, Hart 跳轉到, 以 `mtvt` 為 Vector-Table base, `IRQ ID * 4` 為 offset 的 entry address (ISR)
> 從中斷觸發到跳轉至 ISR, **花費至少 6T**

### Interrupt Enter

> 當進入 ISR 時, **Hart 自動在 1T(sysclk) 內完成以下步驟**
> + Hart 更新 CSRs (`mcause`, `mepc`, `mstatus`)

+ Hart 將 Interrupt 發生時, 尚未執行的下一條 instruction address (PC+4 or PC+2) 保存到 `mepc` 中
    > `mepc` 可以被 S/w 修改, 因此 S/w 可以強制修改跳轉的 address

+ Hart 將 `mcause.EXCCODE` 更新為 IRQC 的 IRQ ID 且 `mcause.INTERRUPT` 設為 1
+ Hart 將發生中斷前的 `mstatus.MIE`, 保存到 `mstatus.MPIE`
    > `mstatus.MPIE` 是為了能在離開中斷時, 利用 `mstatus.MPIE` 來恢復進入中斷前的 `mstatus.MIE`
+ **Hart 將 `mstatus.MIE` 設為 0, 停止中斷觸發**


### Interrupt Handle

> `此階段之後, 基本由 S/w 接手`
> + **每個 ISR 都需自行處理 Push/Pop 行為** (?)
>> `__attribute__((interrupt))` 會處理剛進入 ISR 時的 `Save/Restore GPRs` 行為 (?)
> + 有 `__attribute__((interrupt))` 屬性的 function, Compiler 會視情況強制加入 `Save/Restore GPRs` 行為
> + 不支援 H/w Tail-chaining (中斷咬尾)
>> 可用 S/w 實作 (ref: 7.12 Interrupt Tail-Chaining in Nuclei_N100_Series_Databook.pdf)



### Interrupt Leave

> 返回時, S/w 須執行 `mret` instruction, 此指令會讓 **Hart 自動在 1T(sysclk) 內執行以下步驟**
> + 跳轉到 `mepc` 紀錄的 address
> + Hart 更新 CSRs (`mstatus`)


+ Hart 將 `mstatus.MIE` 恢復為 `mstatus.MPIE` 內的值, `mstatus.MPIE` 設為 1
+ Hart 將 Privilege Mode 恢復為 `mstatus.MPP` 內的值
    > N100 只支援 M-Mode, 為何還要動 `mstatus.MPP` (? 沒有勘誤 ?)


# CSRs of Nuclei-N100

**Nuclei-N100** 對 CSRs 存取權限進行限制
> + 對不存在的 CSR register 進行 R/W 操作, 會產生 Illegal Instruction Exception (`mcause.EXCCODE = 2`)
> + 對 MRW attribute (R/W in M-Mode) 的 CSR register 進行 R/W 則一切正常
> + 對 MRO attribute (RO in M-Mode) 的 CSR register 進行 read 則一切正常
> + 對 MRO attribute (RO in M-Mode) 的 CSR register 進行 Write 操作, 則會產生 Illegal Instruction Exception (`mcause.EXCCODE = 2`)

## System TIMER (24-bits) Unit

**Nuclei-N100** 自定義 `CSR Private TIMER Unit`, 按照系統的 Real Time Clock 進行計時
> default is Enable

為降低功耗, S/w 可設定 `CSR mstop.TIMESTOP` 來停止 System TIMER
> 只有在 normal mode 下, System TIMER 才會作用 (Debug mode 下不會計數 ?)

+ **mtime (timer counter)**

    Nuclei-N100 自定義 `mtime (24-bits)`, 將 System TIMER 的值 real-time 反映在 `CSR mtime` 中

+ **mtimecmp (timer compare value)**

    Nuclei-N100 自定義 `mtimecmp (24-bits)`, 作為 TIMER Unit 的比較值,
    當 System TIMER 的 `mtime >= mtimecmp`, 則產生 System TIMER 中斷

+ **msip (software interrupt)**

    Nuclei-N100 自定義 `msip`, 用來產生 Software Interrupt (SWI)
    > 藉由 System TIMER 來實作 SWI

    - Member fields
        1. `msip.MSIP`, R/W, bit[0]
            > + 0: S/w clears the SWI interrupt
            > + 1: S/w generates the SWI interrupt


+ **mstop (timer counter stop control)**

    Nuclei-N100 自定義 `mstop`, 用來停止 System TIMER

    - Member fields
        1. `mstop.TIMESTOP`, R/W, bit[0]
            > + 1: the System TIMER is paused
            > + others: increments normally


## `mtvec` (Machine Trap-Vector Base-Address Register, R/W)

用來設定 Exception Handler Address, 在 **Nuclei-N100** 中為 `MRO` (直接用 H/w Hard-Code 指定到固定的 Memory area)
> S/w 藉由註冊 ISR 的方式來變更 table items


+ Member fields
    - `mtvec.MODE`, RO, bit[5:0]

        1. `mtvec.MODE == 0x3` 使用 IRQC interrupt mode (default mode)
        1. `mtvec.MODE != 0x3` 使用 Interrupt Direct mode (非向量)
            > Exception and Interrupt 都進入相同的 handler
            >> 當直接設定 function pointer (4-bytes align) 時, `mtvec.MODE != 0x3` 成立

    - `mtvec.ADDR`, RO, bit[31:6]
        > `Base Address MUST be 64-align`, 利用 Link Script 將 symbol 放到 H/w Hard-Code 指定的位址

        ```
            .align 6  /* In IRQC mode, the trap entry must be 64(2^6) bytes aligned */
            .global trap_entry
            .weak trap_entry
        trap_entry:
            ...
        ```



## `mtvt` (Machine Trap-handler Vector Table base Register)

用來設定 Vector Table base address, 在 **Nuclei-N100** 中為 `MRO` (直接用 H/w Hard-Code 指定到固定的 Memory area).

**Nuclei-N100** 為提升效率及降低 Gate Count, `mtvt` 會依 Interrupt source 數量來決定 align 方式
> H/w Configuration

| Total IRQ | `mtvt` align in RV32      |
| :-:       | :-:                       |
| < 16      | mtvt[31:6]  (64-Bytes)    |
| < 32      | mtvt[31:7]  (128-Bytes)   |


## `mcause` (Machine Cause Register)

在 **Nuclei-N100** 中為 `MRW`

+ Member fields
    - `mcause.INTERRUPT`, bit[31]
        > + 0: Exception type of trap
        > + 1: Interrupt type of trap

    - `mcause.EXCCODE`, bit[11:0]
        > Exception-Code

+ **Exception Code** (Nuclei-N100)

    - Interrupt

        | Interrupt-Flag bit[31] | Exception-Code (IRQ ID) bit[11:0] | Description
        | :-:                    | :-:                               | :-
        | 1                      |    0                              |  Machine Software interrupt
        | 1                      |    1                              |  Machine Timer interrupt
        | 1                      |    2                              |  External interrupt 0
        | 1                      |    3                              |  External interrupt 1
        | 1                      |    ...                            | ...
        | 1                      |    31  (Priority High)            |  External interrupt 29

    - Exception

        | Interrupt-Flag bit[31] | Exception-Code bit[11:0] | Description
        | :-:                    | :-:                      | :-
        | 0                      |    0   (Priority High)   |  Instruction address misaligned (RISC-V Extension 'C' ignoer)
        | 0                      |    1                     |  Instruction access fault (`mdcause` 提供詳細的錯誤類型)
        | 0                      |    2                     |  Illegal instruction
        | 0                      |    3                     |  Breakpoint (`ebreak` instruction trigger exception)
        | 0                      |    4                     |  Load address misaligned (**Nuclei-N100 H/w 不支援 Non-align Address Access**)
        | 0                      |    5                     |  Load access fault
        | 0                      |    6                     |  Store/AMO address misaligned (**Nuclei-N100 H/w 不支援 Non-align Address Access**)
        | 0                      |    7                     |  Store access fault
        | 0                      |    8                     |  Reserved
        | 0                      |    9                     |  Reserved
        | 0                      |    10                    |  Reserved
        | 0                      |    11                    |  Environment call from M-mode (`ecall` instruction trigger exception when M-mode)
        | 0                      |    12                    |  Reserved


+ Priority
    > Exception-Code 越小, Priority 就越高


## `mepc` (Machine Exception Program Counter)

在 **Nuclei-N100** 中為 `MRW`

+ Member fields
    - `mepc.EPC`, bit[19:1]

用於保存進入 Exception 前, 正在執行指令的 PC 值 (作為 Exception 的返回地址)
> + `CSR mepc` 可反應當前遇到 Exception 的 instruction address
>> 發生 Exception 時, `CSR mepc` 會被 Hart 同步更新
> + `CSR mepc` 為 R/W 屬性, S/w 可以重設返回地址

## `mstatus` (Machine Status Register)

`mstatus` 是 Machine Mode 下的狀態暫存器, 在 **Nuclei-N100** 中為 `MRW`

+ Member fields

    - `mstatus.MIE`, bit[3] (Machine mode Interrupt Enable)
        > Global interrupt enable in M-Mode
        >> U-Mode 下無法關中斷
        > + 1: enable global interrupt
        > + 0: disable global interrupt

        1. **Nuclei-N100** 進入 trap (Exception/Interrupt/NMI) 時, H/w 自動關中斷 `mstatus.MIE = 0`


    - `mstatus.MPIE`, bit[7] (Machine mode Previous Interrupt Enable)
        > 紀錄進入 M-mode trap 之前的 MIE


## `mcycle` (Machine Cycle counter) and `mcycleh` (Upper 32-bits of mcycle, RV32 only)

在 **Nuclei-N100** 中為 `MRW`

RISC-V 定義了一個 64-bits 的 Clock Counter, 用於反映 Hart 執行了多少個時鐘週期
> 只要 Hart 處於執行狀態時, 此計數器便會不斷計數

```
Clock Counter = (mcycleh << 32 | mcycle)
```

**Nuclei-N100** 為降低功耗, S/w 可設定 `CSR mcountinhibit.CY` 來停止 Clock Counter
> 只有在 normal mode 下, `mcycle` 才會作用 (Debug mode 下不會計數)


## `minstret` (Machine Instruction Retired Register) and `minstreth` (Upper 32 bits of Instructions-retired counter)

在 **Nuclei-N100** 中為 `MRW`

RISC-V 定義了一個 64-bits 的 Instruction Retired Counter, 用於反映 Core 成功執行了多少條指令
> 只要 Hart 每成功執行完成一條指令, 此計數器便會自動計數

```
Instruction Retired Counter = (minstreth << 32 | minstret)
```

**Nuclei-N100** 為降低功耗, S/w 可設定 `CSR mcountinhibit.IR` 來停止 Instruction Retired Counter
> 只有在 normal mode 下, `minstret` 才會作用 (Debug mode 下不會計數)


## `mcountinhibit` (Machine Counter Control Register)

**Nuclei-N100** 自定義 `CSR mcountinhibit` 為 `MRW`, 用來控制 `mcycle` 和 `minstret` 的計數

+ Member fields

    - `mcountinhibit.IR`, bit[2]
        > + 0: minstret/minstreth is start
        > + 1: minstret/minstreth is stop counting

    - `mcountinhibit.CY`, bit[0]
        > + 0: mcycle/mcycleh is start
        > + 1: mcycle/mcycleh is stop counting


## `sleepvalue` (Sleep Mode Register)

**Nuclei-N100** 自定義 `CSR sleepvalue` 為 `MRW`, 用來設定不同的 Sleep mode

+ Member fields

    - `sleepvalue.SLEEPVALUE`, bit[0]
        > + 0: Sleep mode (After `WFI`, SoC should turn `core_clk` off)
        > + 1: DeepSleep mode (After `WFI`, SoC should turn `core_clk` and `core_aon_clk` both off)

## `wfe` (WFE Register)

**Nuclei-N100** 自定義 `CSR wfe` 為 `MRW`, 用來設定進入 Sleep (`WFI`) 後, wake-up 條件 (Interrupt or Event)

+ Member fields

    - `wfe.WFE`, bit[0]
        > + 0: Wake-up by Interrupt (default)
        > + 1: Wake-up by Event



## IRQC Unit

**Nuclei-N100** 為省面積, 自定義 Interrupt Controller (IRQC), 用來管理所有 Interrupt sources
> IRQC 只限作用於單一個 Hart


+ IRQC 有以下特性

    - IRQC 最多只支援 `32 interrupt sources`, 其中 2 個 Interrupt Source 已被 System TIMER Unit (internal) 使用
        > External Interrupt Source 最多只有 `32 - 2` 個
        > + IRQ_0: software interrupt
        > + IRQ_1: system timer interrupt

    - 將 IRQ_ID 直接當作是 Interrupt Priority
        > **IRQ Id 越大, Priority 越高**

    - IRQC 只支援 Interrupt Vectored mode
        > 中斷發生時, Hart 會跳轉到以 `CSR mtvt` 為 Vector Tabal base, `IRC_ID * 4` 為 offset 的 entry address
        >> **Hart 查表並跳轉, 最少需要 6T**
    - IRQC 只支援 Level interrupt (Nuclei_N100_Series_Databook.pdf)
    - IRQC 不支援 H/w Nested Interrupt 機制
        > 必要時可以用 S/w 實作
        > + Check the pending interrupts to make sure there is a higher priority interrupt exits
        > + Save the `mcause`, `mstatus`, `mepc` to stack
        > + Count the Interrupt Level
        > + Clear current interrupt pending by controls the related peripheral
        > + Enable MIE
    - IRQC 不支援 Tail-chaining (中斷咬尾)


### `irqcip` (IRQC interrupt pending flag register)

**Nuclei-N100** 自定義 `CSR irqcip` 為 `MRW`, 用來描述是否有 Interrupt pending
> Bit-Order 對應中斷 ID, e.g. bit[0] => IRQ_0, bit[21] => IRQ_21, ...etc.


### `irqcie` (IRQC interrupt enable flag register)

**Nuclei-N100** 自定義 `CSR irqcie` 為 `MRW`, 用來開關 Interrupt Sources in IRQC
> Bit-Order 對應中斷 ID, e.g. bit[0] => IRQ_0, bit[21] => IRQ_21, ...etc.

# Reference

+ [N100系列指令架構手冊 - My Docs](https://www.nucleisys.com/product/n100/2_zljg/)
