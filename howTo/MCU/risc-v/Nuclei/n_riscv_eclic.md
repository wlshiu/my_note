Nuclei ECLIC [[Back](./n_riscv_interrupt_n200.md#ECLIC)]
----

Base on `Nuclei-N200_v2.12.0: Nuclei_RISC-V_ISA_Spec.pdf`

+ **Nuclei-N2xx** 從 `CSR mtvec[1:0]` 選擇使用 H/w Interrupt module
    > **Nuclei-N2xx** 支援的 H/w Interrupt module 可參考 `14. ECLIC, PLIC and CIDU Connection Diagram of Nuclei_RISC-V_ISA_Spec`

    - `CSR mtvec[1:0] == 0x3` 使用 **ECLIC(Enhanced Core Local Interrupt Controller)**
        > 基於 `RISC-V standard CLIC(Core Local Interrupt Controller)` 基礎進一步優化, 效率及功能比較全面
        >> 只支援單核心應用

        1. ref. `12. ECLIC Unit Introduction of Nuclei_RISC-V_ISA_Spec`

    - `CSR mtvec[1:0] != 0x3` 使用 **CLINT(Core-Local Interruptor)**
        > CLINT 為簡易的中斷模組, 一般建議使用在 Multi-Processors 應用上
        >> 是基於 PLIC(Platform-Level Interrupt Controller) 的延伸

        1. ref. RISC-V standard privileged architecture specification

+ **Nuclei-N2xx** 支援`3 種中斷模式`

    - RISC-V Standard Interrupt Direct mode (參數配置的方式與 RISC-V standard spec 不同)
        > 所有 Exception/Interrupt 都**使用相同的 entry_pointer**
        >> 由 S/w 來分辨 Exception or Interrupt, 並決定調轉到哪一個 handler (S/w 需處理 push/pop stack)

        1. 當 `CSR Customized mtvt2.MTVT2EN == 0` 時, 設定通用 entry_pointer 到 `CSR mtvec[31:6]`
            > ref. `22.5.14 mtvt2 of Nuclei_RISC-V_ISA_Spec`

    - ECLIC Non-Vectored/Vectored mode
        > ECLIC 可對每個 interrupt, 獨立配置為 Vectored or
        >> **Non-Vectored mode 與 Direct mode 行為相似, 只差在是否和 Exception 共用**

        1. Vectored mode
            > 直接跳轉到 Vector-Table `CSR mtvt` 所對應的 ISR(C-Code), 需設定
            > + `CSR Customized mtvt2.MTVT2EN = 1`
            > + `ECLIC->clicintattr[irq_id].shv = 1`
            > + `CSR mtvt[31:6] = Vectored-Table Base Address`

        1. Non-Vectored mode
            > 跳轉到 interrupt **共用 entry_pointer `CSR mtvt2[31:2]`**, 需設定
            > + `CSR Customized mtvt2.MTVT2EN = 1`
            > + `ECLIC->clicintattr[irq_id].shv = 0`
            > + `CSR Customized mtvt2[31:2] = 通用 entry_pointer`


# ECLIC Interrupt flow

> ref. `9. Interrupt Handling in Nuclei processor core of Nuclei_RISC-V_ISA_Spec`

**Nuclei-N2xx** 使用 `mstatus.MIE` 作為 ECLIC (Enhanced Core Local Interrupt Controller) Interrupt 的全域開關

+ ECLIC 為每個 Interrupt source 分配各自的 Interrupt Level/Priority
    > 可藉由設定 ECLIC registers 來管理 Interrupt sources
    >> + `12.5 ECLIC Registers of Nuclei_RISC-V_ISA_Spec`
    >> + ref. `NMSIS/core_feature_eclic.h`

    - Arbitration Mechanism
        > 仲裁條件權重 `Level > Priority > IRQ ID`
        >> ref. `12.12 ECLIC Interrupt Arbitration Mechanism of Nuclei_RISC-V_ISA_Spec`

        1. Level 大小 (數值大優先)
        1. Priority 大小 (數值大優先)
        1. IRQ ID 大小 (數值大優先)

    - Nested interrupt
        > ECLIC 使用 `Level` (數值大搶占數值小) 來判定是否可以 preempyt 目前的 interrupt

        1. Nested Deep 不限制, 直到 Stack 用完
            > `pushmcause/pushmepc/pushmsubm` 分別將重要的 `CSR mcause/mepc/msubm` 推入 stack 中

            ```asm
            .macro SAVE_CSR_CONTEXT
                /* Store CSR mcause to stack using pushmcause */
                csrrwi  x0, CSR_PUSHMCAUSE, 11
                /* Store CSR mepc to stack using pushmepc */
                csrrwi  x0, CSR_PUSHMEPC, 12
                /* Store CSR msub to stack using pushmsub */
                csrrwi  x0, CSR_PUSHMSUBM, 13
            .endm
            ```

+ **Nuclei-N2xx** 預留 `IRQ_0 ~ IRQ_18` 作為了 Hart 的 Internal Interrupts
    > ref. `12.4 ECLIC Interrupt Source ID of Nuclei_RISC-V_ISA_Spec`
    > + IRQ_3: S/w Interrupt
    > + IRQ_7: SysTimer interrupt
    > + IRQ_16: Inter-Cores interrupt
    > + **External Interrupt 從 `IRQ_19` 開始**


+ ECLIC 支援 Interrupt Tail-Chaining
    > 非 preempytion 情況下

    - Without tail-chaining

        ```
        IRQ-1: level == 3
        IRQ-2: level == 1

                                  IRQ-2 trigger +
                                                |
                                                v
            IRQ-1 trigger -> Save-Context 1 -> IRQ-1 ISR -> Restore Context 1 -> Main-Program
                -> Save-Context 2 -> IRQ-2 ISR -> Restore Context 2 -> Main-Program
        ```

    - With tail-chaining
        > 省下一次 push/pop

        ```
        IRQ-1: level == 3
        IRQ-2: level == 1

                                  IRQ-2 trigger +
                                                |
                                                v
            IRQ-1 trigger -> Save-Context 1 -> IRQ-1 ISR -> IRQ-2 ISR -> Restore Context 1 -> Main-Program
        ```

## Interrupt Enter

> 當中斷發生, 進入 ISR 時, **Hart 自動在 1T(sysclk) 內完成以下步驟**
> + Hart 更新 CSRs (`mcause`, `mepc`, `mstatus`, `mintstatus`)
> + Hart 更新 Privilege mode to M-mode (Machine mode)
> + Hart 更新 Machine Sub-Mode (`msubm.TYP`)

> 正常情況下
> + `CSR mstatus.MPIE == CSR mcause.MPIE`
> + `CSR mstatus.MPP == CSR mcause.MPP`

+ Hart 將 Interrupt 發生時, 尚未執行的下一條 instruction address (PC+4 or PC+2) 保存到 `CSR mepc` 中
    > `CSR mepc` 可以被 S/w 修改, 因此 S/w 可以強制修改跳轉的 address

    ```
    mepc = $pc + 4
    ```

    - Vectored mode
        > `CSR Customized mtvt2.MTVT2EN = 1` and `ECLIC->clicintattr[irq_id].shv = 1`

        1. Hart 會做 2-stages 才進入 ISR (花費至少 6 T)
            > + step-1. 取 Vector-Table base (CSR mtvt) 來計算 offset, 此時 `CSR mcause.MINHV = 1`
            > + step-2. 取的 ISR Address 並跳轉, 跳轉完成 `CSR mcause.MINHV = 0`

            >> 當 `CSR mcause.MINHV = 1`, `CSR mcause.INTERRUPT = 1`, 且 `CSR mcause.EXCCODE = 0x1 (Instruction Access Fault)`,
            可判定在進入 ISR 時 發生錯誤

            ```
            $pc = (mtvt & 0xFFFFFFC0) + irq_id * 4
            ```

        1. 因為是直接跳轉到 ISR(C-Code), 因此**每個 ISR(C-Code) 都需要自行處理 Save/Restore Context**
            > 可直接對 ISR(C-Code) 宣告 `__attribute__((interrupt))`, 讓 compiler 自動加入 `Save/Restore GPRs` assembly code
            >> 但 `Save/Restore CSR mepc/mcause/msubm` 仍需在各個 ISR(C-Code) 加入

        1. Tail-Chaining 不支援
            > 因為會依照 Interrup Level 來做 preempting (直接跳轉到對應的 ISR), 且 `Save/Restore Context` 都在各自的 ISR(C-Code) 裡實作,
            故 Tail-Chaining 功能沒有意義

    - Non-Vectored mode
        > `CSR Customized mtvt2.MTVT2EN = 1` and `ECLIC->clicintattr[irq_id].shv = 0`

        1. 從 `CSR Customized mtvt2[31:2]` 取得共通 entry_pointer (irq_entry of trap.S) 並跳轉 (花費至少 4 T)

            ```
            $pc = (mtvt2 & 0xFFFFFFFC)
            ```

+ Hart 將 `CSR mcause.EXCCODE` 更新為 ECLIC 的 IRQ ID 且 `CSR mcause.INTERRUPT = 1`

    ```
    mcause.INTERRUPT = 1
    mcause.EXCCODE = IRQ-ID
    ```

+ Hart 將發生中斷前的 `CSR mstatus.MIE`, 保存到 `CSR mstatus.MPIE`
    > `CSR mstatus.MPIE` 是為了能在離開中斷時(execute mret), 利用 `CSR mstatus.MPIE` 來恢復進入中斷前的 `CSR mstatus.MIE`

    ```
    mstatus.MPIE = mstatus.MIE
    ```

+ **Hart 將 `mstatus.MIE` 設為 0, 停止中斷觸發**

    ```
    mstatus.MIE = 0
    ```

+ Hart 將 `CSR mstatus.MPP` 用來記錄進入中斷前的 Privilege Mode
    > `CSR mstatus.MPP` 是為了能在離開中斷時(execute mret), 利用 `CSR mstatus.MPP` 來恢復進入中斷前的 Privilege Mode

    ```
    mstatus.MPP = current Privilege mode
    ```

+ Hart 強制將 Privilege Mode 切換到 M-Mode (**中斷都會在 M-Mode 處理**)

    ```
    current Privilege mode = M-mode
    ```

+ Hart 將中斷前的 `CSR Customized mintstatus.MIL` 保存到 `CSR mcause.MPIL`, `CSR Customized mintstatus.MIL` 更新為目前的 Interrupt Level
    > 在 Nested interrupt 下, 需要記錄目前的 Interrupt Level (`CSR Customized mintstatus.MIL = current interrup level`), 以判定是否可以被搶占
    >> 當離開 ISR 時(execute mret), `mcause.MPIL` 被用來恢復原本的 `CSR Customized mintstatus.MIL`

    ```
    mcause.MPIL    = mintstatus.MIL
    mintstatus.MIL = current Interrupt Level
    ```

+ Hart 將原本的 `CSR Customized msubm.TYP` 保存到 `CSR Customized msubm.PTYP`, 並設定 `CSR Customized msubm.TYP = 1 (Interrupt Handling Mode)`
    > 當離開 ISR 時(execute mret), `CSR Customized mstatus.PTYP`被用來恢復原本的 `CSR Customized msubm.TYP` (恢復進入中斷前的 Machine Sub-Mode)

    ```
    msubm.PTYP = msubm.TYP
    msubm.TYP = 1
    ```

## Interrupt Handle (C-Code ISR)

> `此階段, 基本由 S/w 接手`

+  Vectored mode
    > `CSR Customized mtvt2.MTVT2EN = 1` and `ECLIC->clicintattr[irq_id].shv = 1`

    - H/w 直接響應進入, 因此在每個 ISR 中需自行實作 `Save/Restore Context` 流程
        > 在 ISR(c-code) 前宣告 `__attribute__((interrupt))` 時, Compiler 會自動加入 `Save/Restore GPRs` assembly code

        1. 如果是 leaf function 可不處理 `Save/Restore GPRs`
            > leaf function: 沒有使用到前一個 fucntion 所用到的 GPRs
            >> 手刻 assembly code 或許可以達到, C-Code 通常做不到 (使用那些 GPRs 是由 compiler 決定)

    - Nested Interrupt
        > 在 Vectored mode 下, Interrupt-Preemption 也是直接跳轉, 因此 **需在每個 ISR(c-code) 加入以下流程**

        1. 剛進入 ISR(C-Code) 時, `mstatus.MIE == 0`
            > Hart 自動關閉 Global interrupt

        1. Save `CSRs mepc/mcause/msubm` into stack

        1. **開啟全域中斷**
            > 需在每個 ISR(C-Code) 中, 自行開啟 Global Interrupt

            ```
            mstatus.MIE = 1
            ```

        1. 處理此中斷對應的流程

        1. **關閉全域中斷**
            > Restore Context 必須是 atomic operations, 不能被中斷

            ```
            mstatus.MIE = 0
            ```

        1. Restore `CSRs mepc/mcause/msubm` from stack


+ Non-Vectored mode
    > `CSR Customized mtvt2.MTVT2EN = 1` and `ECLIC->clicintattr[irq_id].shv = 0`

    - ref. code: `irq_entry of trap.S`

    - 剛進入 entry_pointer 時, `mstatus.MIE == 0`
        > Hart 自動關閉 Global interrupt

    - Save Context (花費至少 14 ~ 20 T, 有 eflash latency 會更多)
        > + RV32E 總共保存 **14 words**
        > + RV32I 總共保存 **20 words**

        1. Save GPRs into stack (花費 11 ~ 17 T)
            > + RV32E 需保存 `GPR * 11`
            > + RV32I 需保存 `GPR * 17`

        1. Save CSRs into stack (花費 3 T)
            > + `CSR mepc`
            > + `CSR mcause`
            > + `CSR Customized msubm`)

            ```asm
            .macro SAVE_CSR_CONTEXT
                /* Store CSR mcause to stack using pushmcause */
                csrrwi  x0, CSR_PUSHMCAUSE, 11
                /* Store CSR mepc to stack using pushmepc */
                csrrwi  x0, CSR_PUSHMEPC, 12
                /* Store CSR msub to stack using pushmsub */
                csrrwi  x0, CSR_PUSHMSUBM, 13
            .endm
            ```

    - 執行 `jalmnxti` (含有 jump and link 功能)
        > 由 Hart 處理 pended interrupt (for Tail-chaining, NOT Nested-Preemption)

        ```asm
        csrrw ra, CSR_JALMNXTI, ra
        ```
        1. Hart 從 `CSR mtvt` 取得 Vector-Table base, 經計算並跳轉到對應的 ISR(c-code)
            > Jump to its vector-entry-label, and update the Link-Register (花費至少 5 T)

        1. 進到對應的 ISR(c-code) 後, Hart 自動開啟 Global interrupt
            > 重新開啟接收 interrupt 以達到 Nested interrupt 功能

            ```
            mstatus.MIE = 1
            ```

        1. 離開 ISR(c-code) 時, S/w 執行 `mret` 後, 跳轉回 `jalmnxti`

        1. 重複執行 `jalmnxti` 直到沒有 Interrupt Pending
            > 達到 Tail-chaining (中斷咬尾) 效果 (省下 Save/Restore context 開銷)
            >> 沒有 Interrupt Pending 時, `jalmnxti` 會被 Hart 當作 `nop` 處理

    - S/w 停止中斷觸發
        > Restore Context 必須是 atomic operations, 不能被中斷

        ```
        mstatus.MIE = 0
        ```

    - Restore Context (花費至少 17 ~ 23 T, 有 eflash latency 會更多)
        > + RV32E 總共恢復 **14 words**
        > + RV32I 總共恢復 **20 words**

        1. Restore GPRs into stack (花費 11 ~ 17 T)
            > + RV32E 需保存 `GPR * 11`
            > + RV32I 需保存 `GPR * 17`

        1. Restore CSRs into stack (花費 6 T)
            > + `CSR mepc`
            > + `CSR mcause`
            > + `CSR Customized msubm`)

            ```asm
            .macro RESTORE_CSR_CONTEXT
                LOAD x5,  13*REGBYTES(sp)
                csrw CSR_MSUBM, x5
                LOAD x5,  12*REGBYTES(sp)
                csrw CSR_MEPC, x5
                LOAD x5,  11*REGBYTES(sp)
                csrw CSR_MCAUSE, x5
            .endm
            ```

    - Nested Interrupt
        > 當發生 Preemption 時, 會再從 共用的 entry_pointer 進入
        >> 需再次做 `Save/Restore Context`, ref. `9.13.1.2 Preemption of Non-Vectored Interrupt of Nuclei_RISC-V_ISA_Spec`


## Interrupt Leave

> 返回時, S/w 須執行 `mret` instruction, 此指令會讓 **Hart 自動在 1T(sysclk) 內執行以下步驟**
>> 執行 `mret` 後, 就由 H/w 接手處理
> + `CSR mepc` 存到 `$PC` 並跳轉
> + Hart 更新 CSRs (`mstatus`, `mcause`, `mintstatus`)
> + Hart 恢復原本的 Privilege mode
> + Hart 恢復原本的 Machine Sub-Mode

> 正常情況下
> + `mstatus.MPIE == mcause.MPIE`
> + `mstatus.MPP == mcause.MPP`

+ Hart 恢復 `mstatus`

    ```
    mstatus.MIE = mcause.MPIE
    ```

+ Hart 恢復 interrupt level `mintstatus`

    ```
    mintstatus.MIL = mcause.MPIL
    ```


+ Hart 恢復原本的 Privilege mode

    ```
    current Privilege mode = mstatus.MPP
    ```

+ Hart 恢復到原來的 Machine Sub-Mode

    ```
    msubm.TYP = msubm.PTYP
    ```

+ Hart 跳轉回 Machine

    ```
    $pc = mepc
    ```


