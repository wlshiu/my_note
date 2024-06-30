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

+ Tail-chaining (中斷咬尾)
    > 在低優先級中斷 ISR 中, 被高優先級的中斷打斷.
    為提高效率, 只做一次 Push/Pop Stack 的動作
    >> 有些似乎稱為 `interrupt preemptible` ?

    ```
    Push-Stack -> ISR_low_priority_FrontHalf -> ISR_high_priority -> ISR_low_priority_BackHalf -> Pop-Stack
    ```

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
    >> E902 `mtvec.MODE == 3` 時, Exception Vectored Table Base 是參考 `mtvec.BASE`

    - Hart 保存 PC 到 `mepc` 中
    - Hart 將 `mcause.Exception_Code`, 更新為當前發生的 code number 且 `mcause.Interrupt_Flag` 設為 0
    - Hart 將 `mstatus.MIE`, 保存到 `mstatus.MPIE`
    - Hart 將 `mstatus.MIE` 設為 0, 停止 Exception 觸發
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

    - Handle Exception event if necessary
    - Pop GPRs back
    - 執行 `mret`

+ Exception leave
    > 返回時, S/w 須執行 Instr. `mret`, 此指令會讓 Hart 執行以下步驟
    >> 進入 Trap 前, Hart 自動處理, 但返回則需要 S/w 來觸發 re-store

    - Hart 將 `mepc` 覆蓋 PC, 以保證可以從 exception trap, 返回到原程序執行位址
    - Hart 將 `mstatus.MIE` 恢復為 `mstatus.MPIE` 內的值, `mstatus.MPIE` 設為 1
    - Hart 將 `mxstatus.PM` 恢復為 `mstatus.MPP` 內的值, `mstatus.MPP`設為 0x0 (U-mode)
        > 如果 Hart 只支援 M-mode, 則 `mstatus.MPP`設為 0x3 (M-mode)


+ Hart lock mechanism
    > 當在 Exception Trap 中, 又觸發 Exception 的情況
    >> `ecall/ebreak` 所觸發的 Exception, 則不會觸發 Hart lock 機制

    - 使用 T-Head Exception `mexstatus.EXPT_VLD`
        > E902 在進入 Exception 前, Hart 將 `mexstatus.EXPT_VLD` 設為 1,
        並在 `mret` 時, 將 `mexstatus.EXPT_VLD` 設為 0
        >> 當 Hart 鎖死時, 會將 `mexstatus.LOCKUP` 設為 1

    - 在 debog mode (ebreak) 下, 當離開 debug mode 時, S/w 將 PC 設為 `0xeffffffc`, 則會維持 Hart-Lock
    - 在 debog mode (ebreak) 下, 當離開 debug mode 時, S/w 將 PC 設為有效的程序 address, 則會解除 Hart-Lock


## Interrupt flow

E902 支援 CLIC
> CLIC 可兼容 `CLINT * 16` + `External Interrupt * 240`
>> 由 S/w 設定每個 external interrupts 的優先權

+ CLIC registers
    >
    > | Reg-Addr            | Reg-Name       | type      | default         | description
    > | :-:                 | :-:            | :-        | :-              | :-
    > | 0xE0800000          | cliccfg        |   RW      | 0x1             | CLIC Configuration Register
    > | 0xE0800004          | clicinfo       |   RO      | 详见计时器中断  | CLIC Info Register
    > | 0xE0800008          | mintthresh     |   RW      | 0x0             | M-mode Interrupt-Level Threshold
    > | 0xE0801000 + 4 x i  | clicintip[i]   |   R or RW | 0x0             | CLIC i-th Interrupt Pending
    > | 0xE0801001 + 4 x i  | clicintie[i]   |   RW      | 0x0             | CLIC i-th Interrupt Enable
    > | 0xE0801002 + 4 x i  | clicintattr[i] |   RW      | 0x0             | CLIC i-th Interrupt Attribute
    > | 0xE0801003 + 4 x i  | clicintctrl[i] |   RW      | 0x0             | CLIC i-th Interrupt control

+ 啟用 Interrupt 步驟
    > - set `mstatus.MIE = 1`
    >> Hart 總開關
    > - set `clicintie.IE = 1`
    >> CLIC module 開關

+ Vectored/Direct mode
    > 在 CLIC E902 `mtvec.MODE == 3` 中, 可以同時使用兩種 mode
    > + Exception trigger with Direct mode
    >> S/w set a handle address to `mtvec`
    > + Interrupt trigger with Vectored mode
    >> S/w set a Vector Table base address to `mtvt`


### Use Interrupt Vectored table (矢量中斷)

可經由 CLIC 個別設定 Interrupt 為 Vectored mode
> `clicintattr[i].shv = 1`

+ Interrupt enter
    > 當進入 interrupt routine 時, **Hart 自動在 1T(sysclk) 內完成以下步驟**
    >> E902 `mtvec.MODE == 3` 時, Interrupt Vectored Table Base 是參考 `mtvt.BASE`

    - Hart 保存 PC 到 `mepc` 中
        > 如果觸發 Interrupt 的 Instr. 同時也觸發 Exception, 則記錄在 `mepc` 的值會是觸發中斷的 Instr. 本身
        >> 在 Interrupt/Exception 之間存在優先順序,
        >> + Interrupt 先觸發, 因此 `mepc` 紀錄觸發中斷的下一條 Instr.
        >> + Exception 接著觸發, `mepc` 的紀錄則被覆蓋為之前 Interrupt 的 Instr.

    - Hart 將 `mcause.Exception_Code` 更新為當前發生的 code number, 且 `mcause.Interrupt_Flag` 設為 1
    - Hart 將 `mstatus.MIE` 保存到 `mstatus.MPIE` 中
    - Hart 將 `mstatus.MIE` 設為 0, 停止中斷觸發

    - Hart 將 `mxstatus.PM` 保存到 `mstatus.MPP`, 並將 `mxstatus.PM` 設為 0x3 (M-mode)
        > 中斷觸發後, Hart 立即進入 M-mode

    - Hart 將 `mcause.MPIL` 更新為 `mintstatus.MIL`, `mintstatus.MIL`則被更新為,當前觸發中斷的 priority level

    - 對於 Pulse Interrupt (GPIO)而言, Hart 會自動清除其對應的 `clicintip.pending`, Level-Triggered (電平觸發)則不會清除
        > 在 **Interrupt Direct mode**, Hart 則會跳過 `clicintip.pending` 的存取, 改由 S/w 處理 (?)

+ Interrupt handle
    > `此階段之後全由 S/w 接手`

    - Push GPRs to stack
    - `mstatus.MIE` 設為 1, 開啟中斷 (Nested Interrupt)
        > 當 Nested Interrupt 時, Hart 會比較 `mintstatus.MIL` (目前的中斷優先級)
        和 `clicintctrl[i].int_ctl` (最新產生的中斷優先級), 以決定是否要再觸發中斷
        >> 當 Nested Interrupt 發生時, 必須將 `mstatus`, `mcause` 一併 push to stack

    - Handle Interrupt event if necessary
    - Pop GPRs back
        > 當 Nested Interrupt 發生時, 必須先將 `mstatus`, `mcause` pop from stack

    - 執行 `mret`

+ Interrupt leave
    > 返回時, S/w 須執行 Instr. `mret`, 此指令會讓 Hart 執行以下步驟

    - Hart 將 `mepc` 覆蓋 PC, 以保證可以從 interrupt trap, 返回到原程序執行位址
    - Hart 將 `mxstatus.PM` 恢復為 `mstatus.MPP` 內的值, `mstatus.MPP`設為 0x0 (U-mode)
        > 如果 Hart 只支援 M-mode, 則 `mstatus.MPP`設為 0x3 (M-mode)
    - Hart 將 `mstatus.MIE` 恢復為 `mstatus.MPIE` 內的值
    - Hard 將 `mintstatus.MIL` 恢復為 `mcause.MPIL` 內的值

### Use Interrupt Direct (非矢量中斷)

可經由 CLIC 個別設定 Interrupt 為 Direct mode
> `clicintattr[i].shv = 0`

在 Interrupt Direct mode 下, ISR address 是統一由 `mtvec` 指定, 同時在 CLIC 中也定義了 `Interrupt Tail-chaining` 的支援

+ Interrupt enter
    > 當進入 interrupt routine 時, **Hart 自動在 1T(sysclk) 內完成以下步驟**

    - Hart 保存 PC 到 `mepc` 中
        > 如果觸發 Interrupt 的 Instr. 同時也觸發 Exception, 則記錄在 `mepc` 的值會是觸發中斷的 Instr. 本身
        >> 在 Interrupt/Exception 之間存在優先順序,
        >> + Interrupt 先觸發, 因此 `mepc` 紀錄觸發中斷的下一條 Instr.
        >> + Exception 接著觸發, `mepc` 的紀錄則被覆蓋為之前 Interrupt 的 Instr.

    - Hart 將 `mcause.Exception_Code` 更新為當前發生的 code number, 且 `mcause.Interrupt_Flag` 設為 1
    - Hart 將 `mstatus.MIE` 保存到 `mstatus.MPIE` 中
    - Hart 將 `mstatus.MIE` 設為 0, 停止中斷觸發

    - Hart 將 `mxstatus.PM` 保存到 `mstatus.MPP`, 並將 `mxstatus.PM` 設為 0x3 (M-mode)
        > 中斷觸發後, Hart 立即進入 M-mode

    - Hart 將 `mcause.MPIL` 更新為 `mintstatus.MIL`, `mintstatus.MIL`則被更新為, 當前觸發中斷的 priority level

+ Interrupt handle
    > `此階段之後全由 S/w 接手`

    - 處理方式與 Interrupt Vectored mode 相同,
    但為提高即時性, Interrupt Direct mode 多支援 `Interrupt Tail-chaining` 的情況

    - **Interrupt Tail-chaining**
        > 在 Interrupt Direct mode 中, ISR address 統一由 `mtvec` 指定, 因此可以在 ISR 入口統一做 Push-Stack

        1. Push GPRs to stack
        1. 如果 `mnxti != 0`, 則表示有比目前優先級更高的 Interrupt 需要處理
            > + 當 S/w read `mnxti` (read type), 則返回有效的 ISR address, 其中 `ISR_Addr = (mtvt[31:6] << 6) + 4 * IRQ_num`
            > + 同時, Hart 會將 `mintstatus.MIL` 更新為 higher-priority Interrupt 的優先級
            > + Hart 也會將 `mcause.Exception_Code` 更新為 higher-priority Interrupt 的 ID
            > + S/w 設定 `mnxti.bit[3] = 1` (write type), Hart 將會 set `mstatus.MIE = 1` 來開啟中斷
            > + S/w 跳轉到 ISP_higher_priority_Addr

        1. 如果 `mnxti == 0` 時, Hart 則不會更新 `mintstatus.MIL` 及 `mcause.Exception_Code`
        1. Pop GPRs back
            > 當 Nested Interrupt 發生時, 必須先將 `mstatus`, `mcause` pop from stack

        1. 執行 `mret`

+ Interrupt leave
    > 與 Interrupt Vectored table 相同

## Non-Maskable Interrupt (NMI) flow

NMI 優先級是最高且 NMI 不受全局中斷位 `mstatus.MIE` 的控制
> 為了使得任何時候觸發 NMI 並在返回後, Hart 都可以恢覆正常運行程序流,
E902 externsion 實作了 `mnmicause` 和 `mnmipc`, 用於保存觸發 NMI 時, Hart 的狀態


+ NMI enter

    - Hart 保存 `mepc` 到 `mnmipc` 中
    - Hart 保存 PC 到 `mepc` 中
        > 為了可以返回原位址

    - Hart 將 `mcause.Exception_Code` 更新為 24, 且 `mcause.Interrupt_Flag` 設為 0


    - Hart 將 `mstatus.MPP`及 `mstatus.MPIE` 保存到 `mnmicause`
    - Hart 將 `mxstatus.PM` 保存到 `mstatus.MPP`
    - Hart 將 `mstatus.MIE` 保存到 `mstatus.MPIE`
    - 跳轉到 NMI handle (base on `mtvec`)

+ NMI handle
    > `此階段之後全由 S/w 接手`

    - 在 NMI 中必須停止 Exception 觸發, 否則會觸發 Hart-Lock
        > S/wt 將 `mstatus.MIE` 設為 0 (?)
    - Hart 會確認 `mcause.Exception_Code` 是否為 24, 因此在 leave NMI handle 前, `mcause.Exception_Code` 不能被改動

    - 執行 `mret`

+ NMI leave
    > 返回時, S/w 須執行 Instr. `mret`, 此指令會讓 Hart 執行以下步驟

    - Hart 將 `mepc` 覆蓋到 PC 再將 `mnmipc` 覆蓋到 `mepc`
    - Hart 將 `mcause.Exception_Code` 及 `mcause.Interrupt_Flag` 恢復為 `mnmicause` 內的值
    - Hart 將 `mxstatus.PM` 恢復為 `mstatus.MPP` 內的值
    - Hart 將 `mstatus.MPIE` 及 `mstatus.MPP` 恢復為 `mnmicause` 內的值

    - Hart 將 `mnmicause.NMI_MPP `設為 0x0 (U-mode)
        > 如果 Hart 只支援 M-mode, 則 `mnmicause.NMI_MPP`設為 0x3 (M-mode)


+ NMI lock mechanism
    > 當在 NMI Trap 中, 又觸發 NMI 的情況

    - Hart 會設定 `mexstatus.LOCKUP = 1`
        > Hard 直接停止 (不 fetch 也不執行)

    - 只有在 Hart reset (重新啟動) 才能 unlock


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
    | 0                      |    24                    |  Non-Maskable Interrupt (NMI)

+ Priority

    | Priority | Interrupt-Flag bit[31] | Exception-Code bit[11:0] | Description
    | :-:      | :-:                    | :-:                      | :-
    | Highest  | 0                      |    24                    |  Non-Maskable Interrupt (NMI)
    |          | ...                    |    ...                   |  ...
    |  High    | 0                      |    1                     |  Instruction access fault
    |          | 0                      |    2                     |  Illegal instruction
    |          | 0                      |    8                     |  Environment call from U-mode
    |          | 0                      |    11                    |  Environment call from M-mode
    |          | 0                      |    6                     |  Store address misaligned
    |          | 0                      |    4                     |  Load address misaligned
    |          | 0                      |    7                     |  Store access fault
    |  Low     | 0                      |    5                     |  Load access fault


## `mtvt` (Machine Trap-handler Vector Table base Register)

由 CLIC 定義的 CSR register, 用來加強對中斷向量的支持

## `mnxti` (Interrupt handler address and enable modifier)

由 CLIC 定義的 CSR register (全名 `M-mode Next Interrupt` 更符合).

在 `Tail-chaining` 下, S/w 使用 `mnxti` 來加速中斷響應.
在 M-mode 下, 當最新 Interrupt 的優先級高於目前正在處理的中斷優先級 `mcause.MPIL` 時,
S/w 通過 `mnxti` 可以獲取下一中斷入口位址


## `mscratch` (Machine Scratch Register)

此 CSR register 一般被用來設定 Stack top of Exception/Interrupt
> E902 使用 32-bits


# Reference

+ [第10章 指令提交 摘錄-CSDN部落格](https://blog.csdn.net/weixin_47955824/article/details/125629123)



