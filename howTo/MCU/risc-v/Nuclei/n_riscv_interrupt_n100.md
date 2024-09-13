Nuclei RISCV Interrupt [[Back](n_riscv_intro.md#Interrupt_n100)]
---


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

# Exception/Interrupt 響應

RISC-V spec (riscv-privileged-v1.10) 裡只對 `MTVEC` 和 `MCAUSE` 做了最基礎的規範, 不同 vendor 會有實作上的差異

## Exception flow

**Nuclei-Nxxx** 支援 `2-Level Nested Exception Stack`

+ Priority of Exception
    > `Exception-Code 越小, Priority 就越高`

### Exception Enter

> 當進入 exception routine 時, **Hart 自動在 1T(sysclk) 內完成以下步驟**
> + 跳轉到 `mtvec` 紀錄的 entry address
> + Hart 更新 CSRs (`mcause`, `mepc`, `mtval`, `mstatus`, `mdcause`)
> + Hart 更新 Privilege mode to M-mode (Machine mode)
> + Hart 更新 Machine Sub-Mode (`msubm.TYP`)

+ Hart 保存 PC 到 `mepc` 中
    > Hart 將觸發 Exception 時的 PC (Program Counter) 記錄到 `mepc`;
      當離開 Exception 時, 藉由 `mepc` 跳轉回原 PC address
    >> `mepc` 可以被 S/w 修改, 因此 S/w 可以強制修改跳轉的 address

    -  `ecall/ebreak` instruction 所產生的 Exception 時,
        > S/w 需自行將 `mepc` 累加到下一條 instruction address
        > ```
        > mepc = mepc+4
        > ```
        > 否則會造成 Deadlock

+ Hart 將 `mcause.EXCCODE`, 更新為當前造成 Exception 的 code number 且 `mcause.INTERRUPT` 設為 0
+ Hart 將發生 Exception 前的 `mstatus.MIE`, 保存到 `mstatus.MPIE`
    > `mstatus.MPIE` 是為了能在離開 Exception 時, 利用 `mstatus.MPIE` 來恢復進入 Exception 前的 `mstatus.MIE`
+ Hart 將 `mstatus.MIE` 設為 0, 停止 Exception 觸發
+ Hart 將 `mstatus.MPP` 用來記錄進入 Exception 前的 Privilege Mode
    > `mstatus.MPP` 是為了能在離開 Exception 時, 利用 `mstatus.MPP` 來恢復進入 Exception 前的 Privilege Mode
+ Hart 強制將 Privilege Mode 切換到 M-Mode (**Trap 基本都會在 M-Mode 處理**)
    > S-Mode 在 MCU 等級不支援

+ Hart 將發生 Exception 的 address or instruction 保存在 `mtval`
    > + Access address 造成的 Exception (紀錄 Address)
    > + 非法 instruction 造成 Exception (紀錄 Instruction OP-Code)

+ Hart 將原本的 `msubm.TYP` 保存到 `msubm.PTYP`
    > `mstatus.PTYP` 是為了能在離開 Exception 時, 利用 `mstatus.PTYP` 來恢復進入 Exception 前的 Machine Sub-Mode

+ Hart 將 `msubm.TYP` 變更為 real-time 的 Trap mode (Exception/Interrupt/NMI)


### Exception Handle

> `此階段之後全由 S/w 接手`

+ Save Context
    > + RV32E 需保存 `GPR * 8`
    > + RV32I 需保存 `GPR * 16`

+ Save CSRs Context
    > Push CSRs `mepc`, `mcause`, `msubm`
    >> 紀錄 CSRs 是為了 Nested interrupt 情況

+ Handle Exception (CSR_MTVEC is the entry address)
   > + argv[0]: mcause
   > + argv[1]: sp

+ Restore CSRs Context
    > Pop CSRs `mepc`, `mcause`, `msubm`

+ Restore Context
    > + RV32E 需恢復 `GPR * 8`
    > + RV32I 需恢復 `GPR * 16`

### Exception Leave

> 返回時, S/w 須執行 `mret` instruction, 此指令會讓 **Hart 自動在 1T(sysclk) 內執行以下步驟**
> + 跳轉到 `mepc` 紀錄的 address
> + Hart 更新 CSRs (`mstatus`)
> + Hart 恢復原本的 Privilege mode
> + Hart 恢復原本的 Machine Sub-Mode

+ `ecall/ebrack` instruction 觸發 Exception 時, S/w 必須在 handler 中, 改變 `mepc` 指向下一條 instruction
    > 由於現在 `ecall/ebreak` 都是 4-bytes 指令, 可以明確知道下一條 instruction 會 offset 4-bytes

    ```
    mepc = mepc + 4
    ```

+ Hart 將 `mstatus.MIE` 恢復為 `mstatus.MPIE` 內的值, `mstatus.MPIE` 設為 1
+ Hart 將 Privilege Mode 恢復為 `mstatus.MPP` 內的值
    > + 0x0: User Mode
    > + 0x3: Machine Mode

+ Hart 將 Machine Sub-Mode 恢復為 `msubm.PTYP` 內的值


## Interrupt flow


#### SysTimer interrupt

+ Members of SysTimer

    ```c
    // ref NMSIS/core_feature_timer.h

    typedef struct {
        __IOM uint64_t MTIMER;           /*!< Offset: 0x000 (R/W)  System Timer current value 64bits Register */
        __IOM uint64_t MTIMERCMP;        /*!< Offset: 0x008 (R/W)  System Timer compare Value 64bits Register */
        __IOM uint32_t RESERVED0[0x3F8]; /*!< Offset: 0x010 - 0xFEC Reserved */
        __IOM uint32_t MSFTRST;          /*!< Offset: 0xFF0 (R/W)  System Timer Software Core Reset Register */
        __IOM uint32_t RESERVED1;        /*!< Offset: 0xFF4 Reserved */
        __IOM uint32_t MTIMECTL;         /*!< Offset: 0xFF8 (R/W)  System Timer Control Register, previously MSTOP register */
        __IOM uint32_t MSIP;             /*!< Offset: 0xFFC (R/W)  System Timer SW interrupt Register */
    } SysTimer_Type;
    ```

#### S/w interrupt

可經由 `SysTimer.MSIP` 來產生 SWI (S/w Interrupt)

### Interrupt Enter

> 當進入 ISR 時, **Hart 自動在 1T(sysclk) 內完成以下步驟**
> + 跳轉到 ////`mtvec` 紀錄的 entry address
> + Hart 更新 CSRs (`mcause`, `mepc`, `mstatus`, `mintstatus`)
> + Hart 更新 Privilege mode to M-mode (Machine mode)
> + Hart 更新 Machine Sub-Mode (`msubm.TYP`)

> 正常情況下
> + `mstatus.MPIE == mcause.MPIE`
> + `mstatus.MPP == mcause.MPP`


+ Hart 將 Interrupt 發生時, 尚未執行的下一條 instruction address (PC+4 or PC+2) 保存到 `mepc` 中
    > `mepc` 可以被 S/w 修改, 因此 S/w 可以強制修改跳轉的 address

    - Interrupt Vectored mode (向量中斷)
        > `ECLIC->CTRL[irq_id].INTATTR_b.SHV == 1`

        1. Hart 會依照 interrupt source id, 去計算以 `mtvt` 為 base 的中斷向量 offset, 並跳轉到對應的 ISR (花費至少 6T)
            > H/w 直接響應, 因此在 ISR 中需自行實作 `Save/Restore Context` 流程 (需自行處理 push/pop 行為)

            I. **ISR 必須使用 `__attribute__((interrupt))` 宣告**
                > Compiler 會對 `__attribute__((interrupt))` 屬性的 ISR 進行分析,
                若在 ISR 中呼叫其他 funcion, Compiler 則會強制加入 Push/Pop 程式碼
                >> 不建議在 ISR 中, 再去呼叫其他 function

        1. 在 Interrupt Vectored mode (向量中斷) 中, Hart 會分 2-stages 來完成
            > + 先從 Vector Table 查表獲得對應的 ISR address
            > + 再跳轉到獲得的 ISR

            I. `mcause.MINHV` 被用來表示上述的 2-stages 是否正常完成
                > + `mcause.MINHV == 0`: 正確完成
                > + `mcause.MINHV == 1`: Something wrong
                >> 可能會觸發 Exception `mcause.EXCCODE = 1` (Instruction access fault)

    - Interrupt Direct mode (非向量)
        > `ECLIC->CTRL[irq_id].INTATTR_b.SHV == 0`

        1. `mtvt2.bit[0] == 0`
            > 跳轉到 `mtvec[31:6]` entry address
            >> Exception and Interrupt 共用 `mtvec[31:6]`

            - 由 S/w 來分辨 Exception or Interrupt, 並決定調轉到哪一個 handler (需使用 stack)

        1. `mtvt2.bit[0] == 1`
            > 跳轉到 `mtvt2[31:2]` entry address
            >> + Exception handler: `mtvec[31:6]` entry address
            >> + Interrupt ISR: `mtvt2[31:2]` entry address

            - 使用 CSR_JALMNXTI 來做 H/w 跳轉 (無額外 stack 開銷)

+ Hart 將 `mcause.EXCCODE` 更新為 ECLIC 的 IRQ ID 且 `mcause.INTERRUPT` 設為 1
+ Hart 將中斷前的 `mintstatus.MIL` 保存到 `mcause.MPIL`, `mintstatus.MIL` 更新為目前的 Nested Interrupt Level
    > 當離開 ISR 時, `mcause.MPIL` 被用來恢復原本的 `mintstatus.MIL`

+ Hart 將發生中斷前的 `mstatus.MIE`, 保存到 `mstatus.MPIE`
    > `mstatus.MPIE` 是為了能在離開中斷時, 利用 `mstatus.MPIE` 來恢復進入中斷前的 `mstatus.MIE`
+ **Hart 將 `mstatus.MIE` 設為 0, 停止中斷觸發**

+ Hart 將 `mstatus.MPP` 用來記錄進入中斷前的 Privilege Mode
    > `mstatus.MPP` 是為了能在離開中斷時, 利用 `mstatus.MPP` 來恢復進入中斷前的 Privilege Mode
+ Hart 強制將 Privilege Mode 切換到 M-Mode (**中斷都會在 M-Mode 處理**)


+ Hart 將原本的 `msubm.TYP` 保存到 `msubm.PTYP`
    > `mstatus.PTYP` 是為了能在離開 Exception 時, 利用 `mstatus.PTYP` 來恢復進入 Exception 前的 Machine Sub-Mode

+ Hart 將 `msubm.TYP` 設為 1 (Interrupt)


### Interrupt Handle

> `此階段之後, 基本由 S/w 接手`

+ Interrupt Vectored mode (向量中斷)
    > + 在此模式下, 從中段觸發到跳轉至 ISR, **花費至少 6T**
    > + **每個 ISR 都需自行處理 Push/Pop 行為**
    > + 有 `__attribute__((interrupt))` 屬性的 function, 視情況 Compiler 會強制加入 `Save/Restore GPRs` 行為
    > + 此模式不支援 Tail-chaining (中斷咬尾)

    - 此模式下進入 ISR 時, Hart 會關閉全域中斷 `mstatus.MIE = 0`,
      因此若要實作 Nested Interrupt, 每個 ISR 需自行實作 (CPU 執行) 以下步驟

        1. Save Context
        1. Save CSRs Context
            > Push CSRs `mepc`, `mcause`, `msubm`
        1. **開啟全域中斷 `mstatus.MIE = 1`**

        1. 處理此中斷對應的流程

        1. **關閉全域中斷 `mstatus.MIE = 0`**
        1. Restore CSRs Context
            > Pop CSRs `mepc`, `mcause`, `msubm`

        1. Restore Context

+ Interrupt Direct mode (非向量)

    - Save Context
        > + RV32E 需保存 `GPR * 8`
        > + RV32I 需保存 `GPR * 16`

    - Save CSRs Context
        > Push CSRs `mepc`, `mcause`, `msubm`
        >> 紀錄 CSRs 是為了 Nested interrupt 情況

    - Handle Interrupt
        > 經由底下 instruction (H/w 跳轉至 ISR), Hart 會以 `mtvt` 為 base, 計算 offset 並跳轉到對應的 ISR
        > ```asm
        > /* 有 IRQ pending 則跳轉, 若無 IRQ pending 則變 NOP */
        > csrrw ra, CSR_JALMNXTI, ra    /* 花費至少 5T */
        > ```

        1. **Hart 在跳轉到 ISR 後, 會自動開啟全域中斷 `mstatus.MIE = 1`**
            > 為達到 Nested Interrupt 效果

        1. CSR_JALMNXTI
            > + 有 JAL 的特性, 會紀錄目前 address 到 `GPRs ra` (從 ISR 返回)
            > + 從 ISR 返回後, 重複執行 CSR_JALMNXTI 直到沒有 Interrupt Pending
            >> 達到 Tail-chaining (中斷咬尾) 效果 (省下 Save/Restore context 開銷)


    - Restore CSRs Context
        > Pop CSRs `mepc`, `mcause`, `msubm`
    - Restore Context
        > + RV32E 需恢復 `GPR * 8`
        > + RV32I 需恢復 `GPR * 16`


### Interrupt Leave

> 返回時, S/w 須執行 `mret` instruction, 此指令會讓 **Hart 自動在 1T(sysclk) 內執行以下步驟**
> + 跳轉到 `mepc` 紀錄的 address
> + Hart 更新 CSRs (`mstatus`, `mcause`, `mintstatus`)
> + Hart 恢復原本的 Privilege mode
> + Hart 恢復原本的 Machine Sub-Mode

+ Hart 將 `mintstatus.MIL` 恢復為 `mcause.MPIL` 內的值 (Nested Interrupt Level)
+ Hart 將 `mstatus.MIE` 恢復為 `mstatus.MPIE` 內的值, `mstatus.MPIE` 設為 1
+ Hart 將 Privilege Mode 恢復為 `mstatus.MPP` 內的值
    > + 0x0: User Mode
    > + 0x3: Machine Mode

+ Hart 會同步更新 `mstatus` 及 `mcause`
    > + `mstatus.MPIE == mcause.MPIE`
    > + `mstatus.MPP == mcause.MPIE`

+ Hart 將 Machine Sub-Mode `msubm.TYP` 恢復為 `msubm.PTYP` 內的值


## Non-Maskable Interrupt (NMI) flow

### NMI Enter

> 當進入 ISR 時, **Hart 自動在 1T(sysclk) 內完成以下步驟**
> + 跳轉到 `mnvec` 紀錄的 entry address
> + Hart 更新 CSRs (`mcause`, `mepc`, `mstatus`, `mintstatus`)
> + Hart 更新 Privilege mode to M-mode (Machine mode)
> + Hart 更新 Machine Sub-Mode (`msubm.TYP`)

+ Hart 將 Interrupt 發生時, 尚未執行的下一條 instruction address (PC+4 or PC+2) 保存到 `mepc` 中
    > `mepc` 可以被 S/w 修改, 因此 S/w 可以強制修改跳轉的 address

    - 跳轉到 `mnvec` entry address
        1. `mmisc_ctl.NMI_CAUSE_FFF == 1`
            > `mnvec == mtvec`

        1. `mmisc_ctl.NMI_CAUSE_FFF == 0`
            > `mnvec == reset_vector`
            >> reset_vector 為 Cool Reset 的程式執行起點 (?)

+ Hart 將 `mcause.EXCCODE` 更新為 NMI_Trap_ID
    - `mmisc_ctl.NMI_CAUSE_FFF == 1`: `mcause.EXCCODE = 0xFFF`
    - `mmisc_ctl.NMI_CAUSE_FFF == 0`: `mcause.EXCCODE = 0x1`


+ Hart 將發生 NMI 前的 `mstatus.MIE`, 保存到 `mstatus.MPIE`
    > `mstatus.MPIE` 是為了能在離開 NMI 時, 利用 `mstatus.MPIE` 來恢復進入 NMI 前的 `mstatus.MIE`
+ **Hart 將 `mstatus.MIE` 設為 0, 停止中斷觸發**

+ Hart 將 `mstatus.MPP` 用來記錄進入 NMI 前的 Privilege Mode
    > `mstatus.MPP` 是為了能在離開 NMI 時, 利用 `mstatus.MPP` 來恢復進入 NMI 前的 Privilege Mode
+ Hart 強制將 Privilege Mode 切換到 M-Mode (**NMI 都會在 M-Mode 處理**)


+ Hart 將原本的 `msubm.TYP` 保存到 `msubm.PTYP`
    > `mstatus.PTYP` 是為了能在離開 NMI 時, 利用 `mstatus.PTYP` 來恢復進入 NMI 前的 Machine Sub-Mode

+ Hart 將 `msubm.TYP` 設為 3 (NMI)

### NMI Handle

> `此階段之後, 基本由 S/w 接手`

需自行處理 `Save/Restore context`


### NMI Leave

> 返回時, S/w 須執行 `mret` instruction, 此指令會讓 **Hart 自動在 1T(sysclk) 內執行以下步驟**
> + 跳轉到 `mepc` 紀錄的 address
> + Hart 更新 CSRs (`mstatus`)
> + Hart 恢復原本的 Privilege mode
> + Hart 恢復原本的 Machine Sub-Mode


+ Hart 將 `mstatus.MIE` 恢復為 `mstatus.MPIE` 內的值, `mstatus.MPIE` 設為 1
+ Hart 將 Privilege Mode 恢復為 `mstatus.MPP` 內的值
    > + 0x0: User Mode
    > + 0x3: Machine Mode

+ Hart 將 Machine Sub-Mode `msubm.TYP` 恢復為 `msubm.PTYP` 內的值


### Nested of NMI and Exception



# CSRs of Nuclei-N100

## `mtvec` (Machine Trap-Vector Base-Address Register, R/W)


## `mtvt` (Machine Trap-handler Vector Table base Register)



## `mnxti` (Next Interrupt Handler Address and Interrupt-Enable)


## `mtvt2` (Machine Trap-handler Vector Table base Register)


## `jalmnxti` (JAL Next Interrupt Handler Address and Interrupt-Enable)

## `mcause` (Machine Cause Register)


## `mdcause` (Machine Detailed Trap Cause Register)

## `mepc` (Machine Exception Program Counter)


## `mtval` (Machine Trap Value Register)


## `mstatus` (Machine Status Register)

## `mintstatus` (Machine Interrupt Status Register)


## `mie` (Machine Interrupt Enable)

## `mip` (Machine Interrupt Pending)

## `mscratch` (Machine Scratch Register)


## `msubm` (Machine Sub-Mode Register)

## `mnvec` (Machine NMI-Vector Base-Address Register)


## `mmisc_ctl`

## `mcycle` (Machine Cycle counter) and `mcycleh` (Upper 32-bits of mcycle, RV32 only)



## `msavestatus`


## `msaveepc1` and `msaveepc2`


## `msavecause1` and `msavecause2`


## `msavedcause1` and `msavedcause2`

## `pushmsubm`, `pushmcause` and `pushmepc`



# Reference

+ [N100系列指令架構手冊 - My Docs](https://www.nucleisys.com/product/n100/2_zljg/)
