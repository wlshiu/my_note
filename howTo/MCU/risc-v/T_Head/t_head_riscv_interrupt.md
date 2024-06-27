T-Head RISCV Interrupt [[Back](t_head_riscv_intro.md#Interrupt)]
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
    >> **Trap 意義等同 ISR**, Exception 和 Interrupt 都會掉入 Trap handle

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

# Exception/Interrupt 響應

RISC-V spec (riscv-privileged-v1.10) 裡只對 `MTVEC` 和 `MCAUSE` 做了最基礎的規範, 不同 vendor 會有實作上的差異

+ 基本流程
    - H/w IP 發出中斷訊號
    - PLIC or CLINT 響應中斷, `Hart 保存此時的 CSRs` (含 $PC, 中斷原因, ...等)
    - 跳轉到 Trap handler
    - S/w disable 中斷響應 (Official RISC-V 不支援 Nested Interrupt, 所以在 Trap 中, 須 mask all interrupts)
    - S/w store GPRs (General Purpose Registers)
    - S/w clear IRQ Flag and Do mapping process
    - S/w restore GPRs
    - S/w re-configure CSRs
    - S/w enable 中斷響應
    - 退出中斷並跳轉回原位址


## Exception flow

+ Exception enter
    > 當進入 exception routine 時, **Hart 自動在 1T(sysclk) 內完成以下步驟**

    - Hart 保存 PC 到 `mepc` 中
    - Hart 將 `mcause.Exception_Code`, 更新為當前發生的 code number 且 `mcause.Interrupt_Flag` 設為 0
    - Hart 將 `mstatus.MIE`, 保存到 `mstatus.MPIE`
    - Hart 將 `mstatus.MIE` 設為 0, 已停止中斷觸發
    - Hart 將 `mxstatus.PM` 保存到 `mstatus.MPP`, 並將 `mxstatus.PM` 設為 0x3 (M-mode)
        > Exception 發生後, Hart 應切換為 M-mode 來處理

    - Hart 將產生 Exception 的原因, 更新到 `mtval`, 如下所示
        > 通常是紀錄出錯的 address

        | Interrupt-Flag | Exception-Code | Description                    | mtval value
        | :-:            | :-:            | :-                             | :-
        | 0              |    1           |  Instruction access fault      | Fatch active address
        | 0              |    2           |  Illegal instruction           | Instr. OP-Code
        | 0              |    3           |  Breakpoint                    | 0 (? address)
        | 0              |    4           |  Load address misaligned       | Load active address
        | 0              |    5           |  Load access fault             | Load active address
        | 0              |    6           |  Store address misaligned      | Store active address
        | 0              |    7           |  Store access fault            | Store active address
        | 0              |    8           |  Environment call from U-mode  | 0
        | 0              |    11          |  Environment call from M-mode  | 0


    - Hart 根據 `mtvec.BASE` (base address, 4-align), 獲得 trap vector table address
        1. Direct mode (`mtvec.MODE` == 0x0)
            > offical, 統一使用一個 trap handle

        1. Vectored mode (`mtvec.MODE` == 0x1)
            > offical, 使用 vector table (4-align)
            >> handler 對應到 `BASE + 4 * IRQ`

        1. Customer mode (`mtvec.MODE` == 0x3, T-Head)
            > **E902 只實現此模式, address 必須為 64-align**
            > + Hart 使用 `mtvec[31:6] << 6` 當作 **Exception vecto table address**
            > + Hart 使用 `mtvt[31:6] << 6` 當作 **Interrupt vector table address**

+ Exception handle
    > `此階段之後全由 S/w 接手`

    - Push GPRs to stack
    - Check `mcause.Interrupt_Flag` and `mcause.Exception_Code`, 決定是否要處理目前 exception
    - Modify CSRs if necessary
        > e.g. 避免重複觸發 Exception

+ Exception leave
    > 返回時, S/w 須執行 Instr. `mret`, 此指令會讓 Hart 執行以下步驟
    >> 進入 Trap 前, Hart 自動處理, 但返回則需要 S/w 來觸發 re-store

    - Hart 將 `mepc` 覆蓋 PC, 以保證可以從 exception trap, 返回到原程序執行位址
    - Hart 將 `mstatus.MIE` 恢復為 `mstatus.MPIE` 內的值, `mstatus.MPIE` 設為 1
    - Hart 將 `mxstatus.PM` 恢復為 `mstatus.MPP` 內的值, `mstatus.MPP`設為 0x0 (U-mode)
        > 如果 Hart 只支援 M-mode, 則 `mstatus.MPP`設為 0x3 (M-mode)


## Interrupt flow













# CSRs of T-Head E902

## `mcause` (Machine Cause Register)

+ Interrupt-Flag, bit[31]
    > + 0: Exception type of trap
    > + 1: Interrupt type of trap

+ Exception-Code, bit[11:0]

+ **Exception Code** (T-Head E902)

    | Interrupt-Flag bit[31] | Exception-Code bit[11:0] | Description
    | :-:                    | :-:                      | :-
    | 1                      |    0                     |  Reserved
    | 1                      |    1                     |  Reserved
    | 1                      |    2                     |  Reserved
    | 1                      |    3                     |  Software interrupt (M-mode)
    | 1                      |    4                     |  Reserved
    | 1                      |    5                     |  Reserved
    | 1                      |    6                     |  Reserved
    | 1                      |    7                     |  Timer interrupt (M-mode)
    | 1                      |    8                     |  Reserved
    | 1                      |    9                     |  Reserved
    | 1                      |    10                    |  Reserved
    | 1                      |    11                    |  External interrupt (M-mode)
    | 1                      |    12–15                 |  Reserved
    | 1                      |    16 + 0                |  CLIC external interrupt 0 (pad_clic_int_vld[0])
    | 1                      |    16 + 1                |  CLIC external interrupt 1 (pad_clic_int_vld[1])
    | 1                      |    ...                   | ...
    | 1                      |    255                   |  CLIC external interrupt 1 (pad_clic_int_vld[239])


    | Interrupt-Flag bit[31] | Exception-Code bit[11:0] | Description
    | :-:                    | :-:                      | :-
    | 0                      |    0                     |  Reserved
    | 0                      |    1                     |  Instruction access fault
    | 0                      |    2                     |  Illegal instruction
    | 0                      |    3                     |  Breakpoint
    | 0                      |    4                     |  Load address misaligned
    | 0                      |    5                     |  Load access fault
    | 0                      |    6                     |  Store address misaligned
    | 0                      |    7                     |  Store access fault
    | 0                      |    8                     |  Environment call from U-mode
    | 0                      |    9                     |  Reserved
    | 0                      |    10                    |  Reserved
    | 0                      |    11                    |  Environment call from M-mode
    | 0                      |    12-23                 |  Reserved
    | 0                      |    24                    |  Non-Marsk Interrupt (NMI)

+ Priority

    | Priority | Interrupt-Flag bit[31] | Exception-Code bit[11:0] | Description
    | :-:      | :-:                    | :-:                      | :-
    | Highest  | 0                      |    24                    |  Non-Marsk Interrupt (NMI)
    |          | ...                    |    ...                   |  ...
    |  High    | 0                      |    1                     |  Instruction access fault
    |          | 0                      |    2                     |  Illegal instruction
    |          | 0                      |    8                     |  Environment call from U-mode
    |          | 0                      |    11                    |  Environment call from M-mode
    |          | 0                      |    6                     |  Store address misaligned
    |          | 0                      |    4                     |  Load address misaligned
    |          | 0                      |    7                     |  Store access fault
    |  Low     | 0                      |    5                     |  Load access fault


# Reference

+ [第10章 指令提交 摘錄-CSDN部落格](https://blog.csdn.net/weixin_47955824/article/details/125629123)



