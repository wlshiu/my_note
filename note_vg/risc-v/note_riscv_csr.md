RISCV CSR (Control and Status Register) [[Back](note_riscv_quick_start.md)]
---

# `mtvec` (Machine Trap-Vector Base-Address Register)

用於設定 interrupt/exception handler address

| field   | bits | description
| :-      | :-:  | :-
| BASE    | 31:2 | handler address (4-bytes align)
| MODE    | 1:0  | 中斷處理模式控制


+ 中斷處理模式

| MODE | Name     |  Description
| :-   | :-       |  :-
| 0    | Direct   |  All exceptions set pc to BASE.
| 1    | Vectored |  Asynchronous interrupts set pc to BASE+4×cause.
| ≥2   | —        |  Reserved


# `mepc` (Machine Exception Program Counter)

當 exception 發生時, H/w 自動更新 `mepc` register 為 `PC + 4` (目前 PC 的下一個 instruction),
作為 exception 的返回地址.

| field      | bits    | description
| :-         | :-:     | :-
| EPC        | 31:1    | 保存異常發生前處理器正在執行的指令的 PC 值
| Reserved   | 0       | 未使用的域為常數0

+ `mepc` register 為 `RW` 屬性, S/w 也可以直接修改它的值

# `mcause` (Machine Cause Register)

紀錄進入 NMI, exception 和 interrupt 之前的出錯原因, 以便於對 Trap 原因進行診斷和調試

| field          | bits    | description
| :-             | :-:     | :-
| Interrupt      | 31      | trigger interrupt or not
| Exception Code | 30:0    | Exception code

+ Exception Code

| Interrupt | Exception Code | Description
| :-:       | :-:            | :-
| 1         |    0           |  Reserved
| 1         |    1           |  Supervisor software interrupt
| 1         |    2           |  Reserved
| 1         |    3           |  Machine software interrupt
| 1         |    4           |  Reserved
| 1         |    5           |  Supervisor timer interrupt
| 1         |    6           |  Reserved
| 1         |    7           |  Machine timer interrupt
| 1         |    8           |  Reserved
| 1         |    9           |  Supervisor external interrupt
| 1         |    10          |  Reserved
| 1         |    11          |  Machine external interrupt
| 1         |    12–15       |  Reserved
| 1         |    ≥16         |  Available for platform use
| 0         |    0           |  Instruction address misaligned
| 0         |    1           |  Instruction access fault
| 0         |    2           |  Illegal instruction
| 0         |    3           |  Breakpoint
| 0         |    4           |  Load address misaligned
| 0         |    5           |  Load access fault
| 0         |    6           |  Store/AMO address misaligned
| 0         |    7           |  Store/AMO access fault
| 0         |    8           |  Environment call from U-mode
| 0         |    9           |  Environment call from S-mode
| 0         |    10          |  Reserved
| 0         |    11          |  Environment call from M-mode
| 0         |    12          |  Instruction page fault
| 0         |    13          |  Load page fault
| 0         |    14          |  Reserved
| 0         |    15          |  Store/AMO page fault
| 0         |    16–23       |  Reserved
| 0         |    24–31       |  Available for custom use
| 0         |    32–47       |  Reserved
| 0         |    48–63       |  Available for custom use
| 0         |    ≥64         |  Reserved

+ **Exception Priority**

| Priority          | Exception Code | Description
| :-                | :-:            | :-
| Highest           |  3             | Instruction address breakpoint
|                   |  12            | Instruction page fault
|                   |  1             | Instruction access fault
|                   |  2             | Illegal instruction
|                   |  0             | Instruction address misaligned
|                   |  8, 9, 11      | Environment call
|                   |  3             | Environment break
|                   |  3             | Load/Store/AMO address breakpoint
| Optionally, these |  6             | Store/AMO address misaligned
| may have lowest   |  4             | Load address misaligned
| priority instead. |                |
|                   |  15            | Store/AMO page fault
|                   |  13            | Load page fault
|                   |  7             | Store/AMO access fault
|                   |  5             | Load access fault


# `mstatus` (Machine Status Registers)

`mstatus` 是機器模式(Machine Mode)下的狀態寄存器

| field   |  bits    | default   | description
| :-      |  :-      | :-        | :-
| Reserved|   0      |  N/A      | 未使用的域為常數 0
| SIE     |   1      |  0        |
| Reserved|   2      |  N/A      | 未使用的域為常數 0
| MIE     |   3      |  0        | Enable Interrupt (global) in Machine mode.
|         |          |           | 0= disable, 1= enable
| Reserved|   4      |  N/A      | 未使用的域為常數 0
| SPIE    |   5      |  0        |
| Reserved|   6      |  N/A      | 未使用的域為常數 0
| MPIE    |   7      |  0        | 用於紀錄進入異常之前的 MIE 值
| SPP     |   8      |           |
| Reserved|   10:9   |  N/A      | 未使用的域為常數 0
| MPP     |   12:11  |  0        | 用於紀錄進入異常之前的 Privileged Mode
| FS      |   14:13  |  0        | 維護或反映浮點單元的狀態
| XS      |   16:15  |  0        | 用於維護或反映用戶自定義的擴展指令單元狀態
| MPRV    |   17     |  0        | 用於控制在 Machine Mode 下存儲器的數據讀寫(Load/Store)操作,
|         |          |           | 是否被當作 User Mode 下的操作, 來進行 PMP 保護.
| SUM     |   18     |  0        | 用於控制在 Supervisor Mode 下,
| MXR     |   19     |           | 是否被允許讀寫(Load/Store) User 存儲區域的數據
| TVM     |   20     |           |
| TW      |   21     |           |
| TSR     |   22     |           |
| Reserved|   30:23  |  N/A      | 未使用的域為常數 0
| SD      |   31     |  0        | Read-only.
|         |          |           | 方便 S/w 快速的查詢 XS 或 FS 是否 Dirty 狀態

# `mip` and `mie` (Machine Interrupt Registers)

RISC-V 架構中定義的中斷類型分為 4種
> + 外部中斷 (External interrupt)
>> from peripheral devices
> + 計時器中斷 (Timer interrupt)
> + 軟件中斷 (Software interrupt)
> + 調試中斷 (Debugging interrupt)


+ `mie` (Machine Interrupt-Enable Register)
    > 用於 enable/disable 中斷

| field     |  bits  | default | description
| :-        |  :-    | :-      | :-
| USIP      |   0    |         | Software interrupt (U mode)
| SSIP      |   1    |         | Software interrupt (S mode)
| Reserved  |   2    |         |
| MSIP      |   3    |         | Software interrupt (M mode)
| UTIP      |   4    |         | Timer interrupt (U mode)
| STIP      |   5    |         | Timer interrupt (S mode)
| Reserved  |   6    |         |
| MTIP      |   7    |         | Timer interrupt (Machine mode)
| UEIP      |   8    |         | External interrupt (U mode)
| SEIP      |   9    |         | External interrupt (S mode)
| Reserved  |   10   |         |
| MEIP      |   11   |         | External interrupt (M mode)
| Reserved  | 31:12  |         | for extension

+ `mip` (Machine Interrupt-Pending Register)
    > 用於查詢中斷的等待狀態, S/w 可以通過讀 `mip`寄存器, 達到查詢中斷狀態的結果.

| field     |  bits  | default | description
| :-        |  :-    | :-      | :-
| USIE      |   0    |         | Software interrupt (U mode)
| SSIE      |   1    |         | Software interrupt (S mode)
| Reserved  |   2    |         |
| MSIE      |   3    |         | Software interrupt (M mode)
| UTIE      |   4    |         | Timer interrupt (U mode)
| STIE      |   5    |         | Timer interrupt (S mode)
| Reserved  |   6    |         |
| MTIE      |   7    |         | Timer interrupt (M mode)
| UEIE      |   8    |         | External interrupt (U mode)
| SEIE      |   9    |         | External interrupt (S mode)
| Reserved  |   10   |         |
| MEIE      |   11   |         | External interrupt (M mode)
| Reserved  | 31:12  |         | for extension


# `mtime` and `mtimecmp` (Machine Timer Registers)

RISC-V 架構定義了系統平台中必須有一個計時器,
並給該計時器定義了兩個 `64-bits` 的寄存器`mtime`和`mtimecmp`

+ `mtime` (Machine time register)
    > 用於反應當前 timer 的計數值

+ `mtimecmp` (Machine time compare register)
    > 用於設定 timer 的 alarm 值
    >> 當`mtime >= mtimecmp`時, timer 便會產生 timer 中斷.
    timer 中斷會一直拉高, 直到 S/w 重寫 `mtimecmp`寄存器的值,
    使得其大於`mtime`中的值, 從而清除 timer 中斷.

# `mscratch`

用於機器模式下, 程序臨時保存某些數據. `mscratch`寄存器可以提供一種快速的保存/恢復機制.
e.g. 在進入機器模式的異常處理程序後, 將 APP 的某個通用寄存器的值, 臨時存入`mscratch`寄存器中,
然後在退出異常處理程序之前, 將`mscratch`寄存器中的值讀出恢復至通用寄存器.

# `mtval` (Machine Trap Value Register)

用於紀錄進入異常之前, **出錯的指令碼(OpCode)**或者**存儲器訪問的地址值**, 以便於對異常原因進行診斷和調試.

# `msubm` (Machine Sub-Mode, extension)

用於保存進入 Trap 前後的 Trap type

| field      | bits    | description
| :-         | :-:     | :-
| Reserved   | 31:10   |   未使用的域為常數 0
| PTYP       | 9:8     |   保存進入 Trap 之前的 Trap 類型:
| TYP        | 7:6     |   指示 Core 當前的 Trap 類型:
| Reserved   | 5:0     |   未使用的域為常數 0


+ `0`: 非 Trap 狀態
+ `1`: interrupt
+ `2`: exception
+ `3`: NMI

# reference

+ [蜂鳥203的CSR寄存器](https://www.cnblogs.com/mikewolf2002/p/11314583.html)


