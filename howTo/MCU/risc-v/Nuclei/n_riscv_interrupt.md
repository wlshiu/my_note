Nuclei RISCV Interrupt [[Back](n_riscv_intro.md#Interrupt_n200)]
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

RISC-V spec (riscv-privileged-v1.10) 定義了兩種中斷模式
+ CLINT mode (defalut)
    > 上電後預設模式, 主要會用在 Internal Interrupt
    > + SysTimer Interrupt
    >> Hart 內部實作了一個 sys_timer unit
    > + Software Interrupt
    >> 藉由 Hart 內部 sys_timer unit 來產生 S/w interrupt


+ CLIC mode
    > 主要處理 External Interrupt (e.g. peripheral interrupt)

**Nuclei-N2xx** 使用 ECLIC 來整合 Internal/External Interrupt
> **Software/Timer Interrupt 也交由 ECLIC 來管理**

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

### ECLIC (Enhanced Core Local Interrupt Controller)

**Nuclei-N2xx** 使用 `mstatus.MIE` 作為 ECLIC Interrupt 的全域開關

+ ECLIC 為每個 Interrupt source 分配各自的 Interrupt Level/Priority
    > 可藉由設定 ECLIC registers 來管理 Interrupt sources
    >> ref `NMSIS/core_feature_eclic.h`

+ **Nuclei-N2xx** 預留 `IRQ_0 ~ IRQ_18` 作為了 Hart 的 Internal Interrupts
    > + IRQ_3: S/w Interrupt
    > + IRQ_7: SysTimer interrupt
    > + IRQ_16: Inter-Cores interrupt
    > + **External Interrupt 從 `IRQ_19` 開始**

+ ECLIC 的每個 Interrupt 都可設定成 Interrupt Direct (非向量) or Interrupt Vectored (向量中斷)
    > + Interrupt Direct
    >> `ECLIC->CTRL[irq_id].INTATTR_b.SHV = 0`
    > + Interrupt Vectored
    >> `ECLIC->CTRL[irq_id].INTATTR_b.SHV = 1`


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
            > H/w 直接響應, 因此在 ISR 中需自行實作 `Save/Restor Context` 流程 (需自行處理 push/pop 行為)

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
    > + 有 `__attribute__((interrupt))` 屬性的 function, 視情況 Compiler 會強制加入 `Save/Restor GPRs` 行為
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







# CSRs of Nuclei-N200

## `mtvec` (Machine Trap-Vector Base-Address Register, R/W)

用來設定 Exception Handler Address (Interrupt 則視 mtvec.MODE 而定)

+ Member fields
    - `mtvec.MODE`, bit[5:0]
        1. `mtvec.MODE != 0x3` 使用 default interrupt mode
            > Exception and Interrupt 都進入相同的 handler
            >> 當直接設定 function pointer (4 or 2 align) 時, `mtvec.MODE != 0x3` 成立

        1. `mtvec.MODE == 0x3` 使用 ECLIC interrupt mode
            > `Base Address MUST be 64-align`

            ```
                .align 6  /* In CLIC mode, the trap entry must be 64(2^6) bytes aligned */
                .global trap_entry
                .weak trap_entry
            trap_entry:
                ...
            ```

    - `mtvec.ADDR`, bit[31:6]

## `mtvt` (Machine Trap-handler Vector Table base Register)

由 CLIC 定義的 CSR register, 用來紀錄 interrupt vector table base address

**Nuclei-Nxxx** 為提升效率及降低 Gate Count, `mtvt` 會依 Interrupt source 數量來決定 align 方式
> H/w Configuration

| Total IRQ | `mtvt` align in RV32      |
| :-:       | :-:                       |
| 16        | mtvt[31:6]  (64-Bytes)    |
| 32        | mtvt[31:7]  (128-Bytes)   |
| 64        | mtvt[31:8]  (256-Bytes)   |
| 128       | mtvt[31:9]  (512-Bytes)   |
| 256       | mtvt[31:10] (1-KBytes)    |
| 512       | mtvt[31:11] (2-KBytes)    |
| 1024      | mtvt[31:12] (4-KBytes)    |
| 2048      | mtvt[31:13] (8-KBytes)    |
| 4096      | mtvt[31:14] (16-KBytes)   |

## `mnxti` (Next Interrupt Handler Address and Interrupt-Enable)

Used to enable `taking the next interrupt handler` and
回到跳轉 interrupt handler 前的 address

`mnxti` 可以被 S/w 訪問, 用來處理在相同 Privilege Mode 下的下一個中斷, 同時**不會造成 flush pipline 以及 Save/Restore Context**
> `mnxti` 可通過 CSRRSI/CSRRCI 來訪問
> + read 返回值是下一個中斷的 handler address
> + write 會更新 Interrupt Enable 的狀態


+ 對於不同 Privilege Mode 的中斷, H/w 會以 Nested interrupt 的方式處理,
    > `mnxti` 只處理相同 Privilege Mode 下的下一個中斷

+ `mnxti` 與常規的CSR指令不一樣, 其返回值與常規 register 的 RMW(read-modify-write)操作的值不同:

    - `mnxti` read 的返回值有以下兩種情況

        1. 當出現以下情況時, 返回值為 0
            > + 沒有可以響應的中斷
            > + 當下最高優先順序的中斷是向量中斷

        1. 當中斷為 non-vectored interrutp 時, 返回此中斷的 isr address

    - `mnxti` write 會更新以下 register 及 feilds 暫存器域

        1. `mstatus`是當前 RMW(read-modify-write)操作的目的 register

        1. `mcause.EXCCODE` 會被更新為當前響應中斷的 IRQ
            > 更新 `mcause.INTERRUPT = 1`  (?)

        1. `mintstatus.MIL` 被更新為當前響應中斷的中斷 Level




## `mtvt2` (Machine Trap-handler Vector Table base Register)

**Nuclei-Nxxx** 自定義 `CSR mtvt2`, 來指定 ECLIC non-vectored interrupts mode 的**共通 handler Entry Address**

> `mtvt`, `mtvt2`, `jalmnxti` 三者互相搭配, 組成一個 2-stage 的 vector-table 中斷系統
> + `mtvt2` 用來保存共通的 irq entry address
>> 在 `mtvt2` 的 irq_entry function 中, 做 save_context (保留現場), 及 restore_context (恢復現場)
> + `mtvt` 則紀錄 vector-table base address
> + `jalmnxti` 依 IRQ number 計算 vector-table offset, 並 `jal` 跳轉到 ISR 去
>> `jal` 會記錄 ra (return address)


## `jalmnxti` (JAL Next Interrupt Handler Address and Interrupt-Enable)

```asm
csrrw ra, CSR_JALMNXTI, ra
```

**Nuclei-Nxxx** 自定義了 `CSR jalmnxti`, 用於減少中斷延遲, 加速中斷咬尾

`jalmnxti` 除了包含 `mnxti`的 Enable interrupt, 處理下一個中斷, 返回下一個中斷的入口地址等功能之外,
還有跳轉至 ISR 的功能, 因此可以縮短中斷處理的指令個數, 達到減少中斷延遲, 加速中斷咬尾的目的

## `mcause` (Machine Cause Register)

+ Member fields
    - `mcause.INTERRUPT`, bit[31]
        > + 0: Exception type of trap
        > + 1: Interrupt type of trap

    - `mcause.MINHV`, bit[30]
        > 表示 core 正在讀取中斷向量表

    - `mcause.MPP`, bit[29:28]
        > 進入中斷之前的 Privilege mode, 與`mstatus.mpp`相同

    - `mcause.MPIE`, bit[27]
        > 進入中斷之前的 interrupt enable, 與`mstatus.mpie`相同

    - `mcause.MPIL`, bit[23:16]
        > 前一個 interrupt 的中斷等級

    - `mcause.EXCCODE`, bit[11:0]
        > Exception-Code

+ **Exception Code** (Nuclei-N200)

    - interrupt

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


    - Exception

        | Interrupt-Flag bit[31] | Exception-Code bit[11:0] | Description
        | :-:                    | :-:                      | :-
        | 0                      |    0                     |  Instruction address misaligned (RISC-V Extension 'C' ignoer)
        | 0                      |    1                     |  Instruction access fault (`mdcause` 提供詳細的錯誤類型)
        | 0                      |    2                     |  Illegal instruction
        | 0                      |    3                     |  Breakpoint (`ebreak` instruction trigger exception)
        | 0                      |    4                     |  Load address misaligned (**Nuclei-Nxxx** H/w 可以啟用 `Load` instruction 支援 non-align address access)
        | 0                      |    5                     |  Load access fault (`mdcause` 提供詳細的錯誤類型)
        | 0                      |    6                     |  Store/AMO address misaligned (**Nuclei-Nxxx** H/w 可以啟用 `Store` instruction 支援 non-align address access, 但 `AMO` instruction 則無法支援)
        | 0                      |    7                     |  Store access fault (`mdcause` 提供詳細的錯誤類型)
        | 0                      |    8                     |  Environment call from U-mode (`ecall` instruction trigger exception when U-mode)
        | 0                      |    9                     |  Reserved
        | 0                      |    10                    |  Reserved
        | 0                      |    11                    |  Environment call from M-mode (`ecall` instruction trigger exception when M-mode)
        | 0                      |    12-24                 |  Reserved


+ Priority
    > Exception-Code 越小, Priority 就越高



## `mdcause` (Machine Detailed Trap Cause Register)

**Nuclei-Nxxx** 自定義 `CSR mdcause`, 用來提供更加詳細的 Exception Info

+ Member fields
    - `mdcause.PTYP`, bit[1:0]

        1. 當 `mcause.EXCCODE = 1` (指令訪問錯誤):
            > + 0: Reserved
            > + 1: PMP檢測指令訪問出錯
            > + 2: 指令訪問返回匯流排錯誤
            > + 3: Reserved

        1. 當 `mcause.EXCCODE = 5` (讀取儲存器訪問錯誤)
            > + 0: Reserved
            > + 1: PMP檢測讀操作訪問儲存器出錯
            > + 2: 讀操作訪問儲存器返回匯流排錯誤
            > + 3: NICE長指令錯誤

        1. 當 `mcause.EXCCODE = 7` (寫入儲存器訪問錯誤)
            > + 0: Reserved
            > + 1: PMP 檢測寫操作訪問儲存器出錯
            > + 2: 寫操作訪問儲存器返回匯流排錯誤
            > + 3: Reserved

## `mepc` (Machine Exception Program Counter)

+ Member fields
    - `mepc.EPC`, bit[31:1]

用於保存進入 Exception 前, 正在執行指令的 PC 值 (作為 Exception 的返回地址)
> + `CSR mepc` 可反應當前遇到 Exception 的 instruction address
>> 發生 Exception 時, `CSR mepc` 會被 Hart 同步更新
> + `CSR mepc` 為 R/W 屬性, S/w 可以重設返回地址

+ Exception/Interrupt 行為有點差異
    - Interrupt
        > `CSR mepc` 會記錄跳轉前, `PC 的下一條尚未執行的 instruction address`

    - Exception
        > `CSR mepc` 直接記錄發生 Exception 的 Address (為了直接定位)
        >> 當 `ecall/ebreak` 觸發 Exception 時, 在 Trap handler 中, S/w 需修改 `mepc`
        >> ```
        >> mepc = mepc + 4
        >>     or
        >> mepc = mepc + 2
        >>```


## `mtval` (Machine Trap Value Register)

又名 `CSR mbadaddr` (有些版本的 toolchain 只識別此名稱), 用於保存進入 Exception 前的出錯指令的 OP-Code,
或 儲存器訪問的 address, 以便於對異常原因進行診斷和偵錯

## `mstatus` (Machine Status Register)

`mstatus` 是 Machine Mode 下的狀態暫存器

+ Member fields

    - `mstatus.SIE`, bit[1] (Supervisor mode Interrupt Enable)

    - `mstatus.MIE`, bit[3] (Machine mode Interrupt Enable)
        > Global interrupt enable in M-Mode
        >> U-Mode 下無法關中斷
        > + 1: enable global interrupt
        > + 0: disable global interrupt

        1. **Nuclei-Nxxx** 進入 trap (Exception/Interrupt/NMI) 時, H/w 自動關中斷 `mstatus.MIE = 0`

    - `mstatus.SPIE`, bit[5] (Supervisor mode Previous Interrupt Enable)
    - `mstatus.MPIE`, bit[7] (Machine mode Previous Interrupt Enable)
        > 紀錄進入 M-mode trap 之前的 MIE

    - `mstatus.MPP`, bit[12:11] (Machine mode Previous Privilege mode)
        > 紀錄進入 M-mode  trap 之前的特權模式
        >> 可能來自 U-mode (MPP == 0), S-mode (MPP == 1), M-mode (MPP == 3)

    - `mstatus.FS`, bit[14:13] (FPU context Statue)
    - `mstatus.XS`, bit[16:15] (eXtension context Status)

    - `mstatus.MPRV`, bit[17] (Modify PRiVilege)
        > 是否將執行 load/store 指令的特權模式修改為 MPP

    - `mstatus.SUM`, bit[18] (permit Supervisor User Memory access)
        > 允許 S-mode 的 load/store 指令存取 U-mode 分頁

    - `mstatus.SD`, bit[31] (summarize State Dirty)
        > `mstatus.XS` 或 `mstatus.FS` 其中之一是否為 dirty

## `mintstatus` (Machine Interrupt Status Register)

`mintstatus` 用來保存 Privilege Mode 下, 有效中斷的 Nested Interrupt Level
> 紀錄在 Nested Interrupt 的第幾層

+ Member fields

    - `mintstatus.UIL`, bit[7:0] (U-Mode Interrupt Level)
    - `mintstatus.MIL`, bit[31:24] (M-Mode Interrupt Level)



## `mie` (Machine Interrupt Enable)

ECLIC 中斷模式下 `mie` 的控制位不起作用 (only return 0)

## `mip` (Machine Interrupt Pending)

ECLIC 中斷模式下 `mip` 的控制位不起作用 (only return 0)


## `mscratch` (Machine Scratch Register)

`mscratch` 用於 M-Mode 下的程序臨時保存某些資料

mscratch暫存器可以提供一種 Save/Restore 機制, e.g. 在進入中斷或者異常處理模式後, 將 U-Mode 的 SP (Stack Pointer) 臨時存入 `mscratch`中;
然後在退出異常處理程序之前，用`mscratch`中的值, 恢復 SP


## `msubm` (Machine Sub-Mode Register)

**Nuclei-Nxxx** 自定義 `CSR msubm`, 用來保存進入 Trap handler 前後的 Trap type

+ Member fields
    - `msubm.PTYP`, bit[9:8]
        > 保存進入Trap之前的Trap type
        > + 0: 非Trap狀態
        > + 1: Interrupt
        > + 2: Exception
        > + 3: NMI

    - `msubm.TYP`, bit[7:6]
        > 表示 Core 當前的 Trap type
        > + 0:　非Trap狀態
        > + 1:　Interrupt
        > + 2:　Exception
        > + 3:　NMI


## `mcycle` (Machine Cycle counter) and `mcycleh` (Upper 32-bits of mcycle, RV32 only)

RISC-V 定義了一個 64-bits 的 Clock Counter, 用於反映 Hart 執行了多少個時鐘週期
> 只要 Hart 處於執行狀態時, 此計數器便會不斷計數

```
Clock Counter = (`mcycleh` << 32 | `mcycle`)
```


# Reference

+ [Nuclei_N等級指令架構手冊 - RISC-V MCU文件中心](https://www.riscv-mcu.com/quickstart-doc-u-nuclei_n_isa.html)
+ [GD32VF103啟動流程分析-GD32vf103v上電自動運行-CSDN部落格](https://blog.csdn.net/lbaihao/article/details/124897106?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-1-124897106-blog-140423340.235^v43^pc_blog_bottom_relevance_base7&spm=1001.2101.3001.4242.2&utm_relevant_index=4)
+ [DAY2: RISC-V: 不懂 CSR 那就放棄吧(一) - iT 邦幫忙](https://ithelp.ithome.com.tw/articles/10289643)
+ [E203 CSR暫存器 - 邁克老狼2012 - 部落格園](https://www.cnblogs.com/mikewolf2002/p/11314583.html)
