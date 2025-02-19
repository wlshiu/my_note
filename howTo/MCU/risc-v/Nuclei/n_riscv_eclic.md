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
            > 需設定
            > + `CSR Customized mtvt2.MTVT2EN = 1`
            > + `ECLIC->clicintattr[irq_id].shv = 1`
            > + `CSR mtvt[31:6] = Vectored-Table Base Address`

        1. Non-Vectored mode
            > 需設定
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
        1. Level 大小 (數值大優先)
        1. Priority 大小 (數值大優先)
        1. IRQ ID 大小 (數值大優先)

    - Nested interrupt (Nested Deep 不限制, 直到 Stack 用完)
        > ECLIC 使用 `Level` (數值大搶占數值小) 來判定是否可以 preempyt 目前的 interrupt

+ **Nuclei-N2xx** 預留 `IRQ_0 ~ IRQ_18` 作為了 Hart 的 Internal Interrupts
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
> + `mstatus.MPIE == mcause.MPIE`
> + `mstatus.MPP == mcause.MPP`

+ Hart 將 Interrupt 發生時, 尚未執行的下一條 instruction address (PC+4 or PC+2) 保存到 `CSR mepc` 中
    > `CSR mepc` 可以被 S/w 修改, 因此 S/w 可以強制修改跳轉的 address

    ```
    mepc = $pc + 4
    ```

    - Vectored mode
        1. Hart 會做兩步驟才進入 ISR
            > + step-1. 取 Vector-Table base (CSR mtvt) 來計算 offset, 此時 `CSR mcause.MINHV = 1`
            > + step-2. 取的 ISR Address 並跳轉, 跳轉完成 `CSR mcause.MINHV = 0`

            >> 當 `CSR mcause.MINHV = 1`, `CSR mcause.INTERRUPT = 1`, 且 `CSR mcause.EXCCODE = 0x1 (Instruction Access Fault)`,
            可判定在進入 ISR 時 發生錯誤

    - Non-Vectored mode

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

## Interrupt Handle

## Interrupt Leave

> 返回時, S/w 須執行 `mret` instruction, 此指令會讓 **Hart 自動在 1T(sysclk) 內執行以下步驟**
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


