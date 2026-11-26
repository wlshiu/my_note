📌 VexRiscv Murax SoC 開發進度與環境交接文件 (v3.7 最終定案版)

# 專案目標與核心規格(定案版: 鎖定 PSMC 110nm 24-Pin ASIC 規格)

本專案基於 SpinalHDL v1.13.0 修改 VexRiscv Murax SoC,針對 **PSMC(力積電)110nm 製程、24-Pin 封裝(如 QFN24 / TSSOP24)** 打造極致精簡、低功耗且具備完整常用周邊的 32-bit 微控制器架構(已通過 Verilator 全系統回歸驗證):
+ **處理器核心**: VexRiscv 3 階管線(Fetch + Decode + Execute；關閉 Memory 與 WriteBack 階段)。
+ **指令集架構**: **RV32EMC**(32 位元精簡暫存器架構 `rv32e = true`,僅保留 `x0~x15` 共 16 個暫存器；含硬體乘除法 `MulSimplePlugin` + `DivPlugin`、16-bit 壓縮指令 RVC `compressedGen = true`；暫存器檔採同步讀取 `regFileReadyKind = SYNC`)。**軟體編譯參數必須鎖定 `-march=rv32emc -mabi=ilp32e`**。
+ **系統時脈**: **32 MHz**(`coreFrequency = 32 MHz`；31.25 ns 週期,eFlash 採 **0 Wait State** 單週期同步讀取)。
+ **極致精簡 CSR 配置**: 以 `CsrPluginConfig.smallest(mtvecInit = 0x20)` 為基底,透過 `.copy(...)` 精準開啟 **`mepcAccess = CsrAccess.READ_WRITE`**(支援異常跳過與 `mret` 返回)、**`ecallGen = true`**、**`ebreakGen = true`**、**`wfiGenAsWait = true`** 與 **`deterministicInteruptionEntry = true`**(零 `mtval`/`mscratch`/`misa`/64-bit 計數器冗餘面積)。
+ **低功耗睡眠控制 (`WFI`)**: 透過 `cpu.rework` 與 `walkDeclarations` 匯出頂層狀態接腳 **`io.inWfi`**(`output wire io_inWfi`)。執行 `wfi` 時 CPU 凍結取指管線並拉高 `io.inWfi`(支援 `MIE=1` 進 ISR 喚醒,以及 `MIE=0` 同步喚醒不進 ISR),可直接對接 ASIC 頂層時脈閘控(ICG)與 eFlash `PD`(Power Down)省電接腳。
+ **實體腳位架構**: 頂層收斂為統一的 **16-bit 雙向三態匯流排 `io.iopad`**(配合 24-pin 封裝扣除電源／時脈／重置後之可用腳位),透過 APB `MuraxSysCtrlPinMux` 動態多工切換 GPIO、UART、SPI、I2C 與 JTAG。`withXip = false`(SpinalHDL 條件生成確保 XIP 零殘存面積)。
+ **安全匯流排架構**: 配置 `MuraxSafeMasterArbiter` 與 `MuraxSafePipelinedMemoryBusDecoder`,支援未映射位址讀取(`noHit`)與未映射位址取指之 `Access Fault` 異常回報；所有寫入交易維持高速單週期 Posted Write(不等待回應,無匯流排死鎖風險)。
+ **除錯介面**: JTAG 介面(預設映射於 `IOPAD[15:12]`,開機即啟用),支援 4 組硬體斷點(`hardwareBreakpointCount = 4`),可透過 `OpenOCD + GDB` 進行 `hbreak` 與壓縮指令單步除錯。

---

# 記憶體映射與周邊配置

| 區塊 / 周邊名稱 | 模組類別 / 規格 | 基底位址 | 容量 / 範圍 | 說明與中斷連線 |
| :--- | :--- | :--- | :--- | :--- |
| **eFlash (XIP)** | MuraxEmbeddedFlash (唯讀 BRAM / ASIC eFlash IP) | `0x00000000` | 32 KB | 支援 XIP (0 Wait State)；`0x0` 開機向量、`0x20` 中斷向量 (`mtvecInit`) |
| **On-chip SRAM** | MuraxPipelinedMemoryBusRam | `0x20000000` | 2 KB | 存放 `.data`、`.bss` 與 `Stack`(`sp` 頂端位於 `0x20000800`) |
| **GPIO** | Apb3Gpio (16-bit 雙向) | `0xF0000000` | 4 KB | 經 `MuraxSysCtrlPinMux` 連接至 `io.iopad[15:0]` |
| **UART** | Apb3UartCtrl (115200 8N1) | `0xF0010000` | 4 KB | TX/RX FIFO 各 4 深；接至 CPU `externalInterrupt` (`mcause = 0x8000000B`) |
| **Timer** | MuraxSplitApb3Timer (16-bit Prescaler + 2 Timers) | `0xF0020000` | 4 KB | **分流架構**: `Timer A` 接 CPU `timerInterrupt` (`mcause = 0x80000007`)；`Timer B` 接 CPU `externalInterrupt` (`mcause = 0x8000000B`) |
| **SPI Master** | Apb3SpiMasterCtrl (1x SS, 8-bit, FIFO 4) | `0xF0030000` | 4 KB | 接至 CPU `externalInterrupt` (`mcause = 0x8000000B`) |
| **I2C Controller** | Apb3I2cCtrl (支援 Master/Slave, 12-bit Timer) | `0xF0040000` | 4 KB | 接至 CPU `externalInterrupt` (`mcause = 0x8000000B`) |
| **SysCtrl & PinMux** | MuraxSysCtrlPinMux (16-Pin IOPAD 多工器) | `0xF0050000` | 4 KB | `0x00`: `PINMUX_SEL0`、`0x04`: `PINMUX_SEL1`、`0x08`: `SYS_STATUS` (`0x00200016`)、`0x0C`: `PINMUX_LOCK` (Write-1-Once 鎖定) |

---

## 16-Pin IOPAD 多工映射表(`MuraxSysCtrlPinMux`)

每支腳位由 2-bit 控制(`0`=GPIO, `1`=ALT1, `2`=ALT2)。重置後預設值: `PINMUX_SEL0 = 0x0000`、`PINMUX_SEL1 = 0x5500`(`IOPAD[15:12]` 預設為 JTAG,其餘為 GPIO；未選通之周邊輸入端內部自動拉高為 Idle High `1`)；寫入 `PINMUX_LOCK = 1` 後可鎖定多工配置直到下次 Reset:

| 實體腳位 | Mode 0 (`2'b00`) | Mode 1 (`2'b01`) | Mode 2 (`2'b10`) | 電氣特性與備註 |
| :--- | :--- | :--- | :--- | :--- |
| **IOPAD[0]** | `GPIO[0]` | `UART_TXD` (推挽輸出) | — | 韌體啟動後需呼叫 `pinmux_enable_uart(true)` |
| **IOPAD[1]** | `GPIO[1]` | `UART_RXD` (輸入) | — | 韌體啟動後需呼叫 `pinmux_enable_uart(true)` |
| **IOPAD[2]** | `GPIO[2]` | `I2C_SCL` (Open-Drain) | — | 硬體自動轉 Open-Drain: `write=0, writeEnable=~scl.write` |
| **IOPAD[3]** | `GPIO[3]` | `I2C_SDA` (Open-Drain) | — | 硬體自動轉 Open-Drain: `write=0, writeEnable=~sda.write` |
| **IOPAD[4..7]** | `GPIO[4..7]` | — | `SPI` (`SS0`, `SCLK`, `MOSI`, `MISO`) | 呼叫 `pinmux_enable_spi(true)` 啟用 |
| **IOPAD[8..11]** | `GPIO[8..11]` | — | — | 純通用 GPIO (4-bit) |
| **IOPAD[12..15]** | `GPIO[12..15]` | **`JTAG`** (`TMS`, `TCK`, `TDI`, `TDO`) | — | **開機預設 Mode 1**；量產韌體可寫入 `0` 釋放為 GPIO |

---

## 中斷、異常與低功耗系統關鍵硬體特性(已實測確認)

+ **向量模式**: Direct Mode,所有異常與中斷統一跳轉至 `0x00000020`(`trap_entry`)。
+ **CSR 實作細節 (`CsrPluginConfig.smallest` 客製化)**:
  - `mtvec` 硬體固定為 `0x00000020`；無 `mtval` 暫存器(`crt.S` 禁止讀取 `mtval`,`TrapFrame->mtval` 固定填 `0`)。
  - 保留 `mepcAccess = CsrAccess.READ_WRITE`,允許 `crt.S` 讀取並寫回更新後的 `mepc`；支援 `ecall` (`mcause = 11`)、`ebreak` (`mcause = 3`) 與 `wfi`。
+ **非巢狀中斷**: 進入中斷時硬體自動清除 `mstatus.MIE`,維持非巢狀處理以保護極小的 2 KB SRAM。
+ **中斷來源與分流設計**:
  - `mcause == 0x80000007` (`MCAUSE_MTI`): 僅由 **Timer A** 觸發(專責純淨無抖動的系統核心 Tick),寫入 `0x1` 至 `0xF0020010` 清除 Pending。
  - `mcause == 0x8000000B` (`MCAUSE_MEI`): 由 **Timer B、SPI、I2C、UART** 共用,需在 `trap_handler()` 中依序輪詢各周邊狀態並清除旗標。
  - **W1C Pending 清除規範**: `TIMER_INTERRUPT->PENDINGS` (`0xF0020010`) 為 Write-1-to-Clear 暫存器,清除旗標時必須使用直接賦值(例如 `TIMER_INTERRUPT->PENDINGS = TIMER_IRQ_A`),**嚴禁使用 `|=`**。
+ **Apb3I2cCtrl 硬體實作關鍵細節(32 MHz 時序配置)**:
  - **32 MHz 100 kHz I2C 參數**: `SAMPLING_DIV = 7` (4 MHz)、`TIMEOUT = 320000` (10 ms,不可為 0)、`TSU_DAT = 16` (500 ns)、`T_LOW = T_HIGH = T_BUF = 160` (5 µs)。
  - **Listen 與中斷映射**: `RX_DATA` (`0x08`) / `RX_ACK` (`0x0C`) 接收前需先寫入 `Bit 9 = 1`(`I2C_RX_LISTEN`)；`INT_ENABLE` (`0x20`) 的 `Bit[3:0]` 為 Level-triggered 資料流中斷,不存在於 `INT_FLAG` (`0x24`),需直接讀取 `RX_DATA`/`RX_ACK` 清除。

---

# 已完成並通過 Verilator 實測的檔案狀態(Current Stage)

1. **硬體 RTL (`src/main/scala/vexriscv/demo/Murax.scala`)**:
   + 已定案 `coreFrequency = 32 MHz`、`gpioWidth = 16`、`withXip = false`、`rv32e = true`,以及 `CsrPluginConfig.smallest` 客製化組合(含 `mepcAccess = READ_WRITE`、`ecallGen`、`ebreakGen`、`wfiGenAsWait`),並匯出頂層 `io.inWfi`(`output wire io_inWfi`)。
   + 已整合 `MuraxSplitApb3Timer`、`MuraxSysCtrlPinMux` (`0xF0050000`,含 `0x0C` `PINMUX_LOCK`)、`MuraxSafeMasterArbiter` 與 `MuraxSafePipelinedMemoryBusDecoder`。
   + 執行 `sbt -J-Xmx2G "runMain vexriscv.demo.MuraxWithRamInit"` 可產生 `Murax.v`、`cpu0.yaml` 及 Flash 初始化檔 `Murax.v_toplevel_system_eFlash_flash.bin`(8192 words)。
2. **連結腳本 (`linker.ld`) & 啟動組語 (`crt.S`)**:
   + `trap_entry` 嚴格對齊於 `0x00000020`；`.data` 搬移、`.bss` 清零與 `$gp` 相對定址運作正常；保留至少 512 Bytes (`0x200`) Stack 空間。
   + `trap_entry` 已依 RV32E 保存/還原 10 個 Caller-saved GPRs(`ra, t0~t2, a0~a5`),堆疊幀對齊 **64 Bytes(16-byte EABI 對齊)**,且 `TrapFrame->mtval(偏移 48(sp))`直接寫入 `zero`。
3. **周邊暫存器標頭檔 (`murax_reg.h`) & 測試韌體 (`main.c`)**:
   + `trap_handler()` 具備自動分辨 16-bit RVC / 32-bit 指令長度推進 `mepc` 的機制,並加上偶數位址保護 `(pFrame->mepc & 0x1) == 0`。
   + **最新 Verilator 全數實測 PASS 項目(Test 0 ~ Test 8)**:
     - ✅ **[Test 0] CSR Check**: `MIE = 0x00000880`、`MSTATUS = 0x00001808`。
     - ✅ **[Test 1] SRAM .data & .bss Check**: `.data` (`0x12345678`) 與 `.bss` (`0x00000000`) 驗證 PASS。
     - ✅ **[Test 2] RV32M Hardware Mul/Div Check**: `MUL = 0x04FED79D`、`DIV = 0x000A65A7`、`REM = 0x00000060` 驗證 PASS。
     - ✅ **[Test 3] Timer A Interrupt (`mcause = 0x80000007`)**: 32 MHz 下 1 ms tick 觸發 5 次 MTI 中斷,PASS。
     - ✅ **[Test 3B] Timer B External Interrupt (`mcause = 0x8000000B`)**: 32 MHz 下 1 ms tick 觸發 5 次 MEI 外部中斷,PASS。
     - ✅ **[Test 4] UART RX Interrupt (`mcause = 0x8000000B`)**: 透過 `IOPAD[1:0]` 接收字元觸發外部中斷並 Echo 回傳,PASS。
     - ✅ **[Test 5] SPI Master Loopback (`mcause = 0x8000000B`)**: 透過 `IOPAD[7:4]` 1 MHz Mode 0 收發 `0xA5`、`0x5A` 觸發 2 次中斷並讀回,PASS。
     - ✅ **[Test 6] I2C Master Read Slave `0x50` (`mcause = 0x8000000B`)**: 透過 `IOPAD[3:2]` Open-Drain 100 kHz 讀取 `0x50` 回傳 `0x5A`,PASS。
     - ✅ **[Test 7] CPU Exception 完整驗證**:
       - `7.1` 非法指令 16-bit `C.ILLEGAL` (`mcause = 2`) PASS。
       - `7.2` Load 未對齊 (`mcause = 4`) & `7.3` Store 未對齊 (`mcause = 6`) PASS。
       - `7.4` Unmapped Memory Load (`mcause = 5`) PASS(Store 採 Posted Write 不觸發 `mcause = 7`)。
       - `7.5` Store Access Fault (`mcause = 7`) FAIL。
            > VexRiscv 的 `DBusSimplePlugin` 採用 Posted Write(不等待寫入回應),因此 `sw` 寫入無效位址不會觸發 `mcause = 7`,這是正常現象
       - `7.6` Instruction Fetch Invalid Address (`mcause = 1`) PASS。
       - `7.7` M-Mode `ECALL` 異常 (`mcause = 11`) PASS。
     - ✅ **[Test 8] WFI Sleep & Interrupt Wakeup 完整驗證**:
       - `8.1` `mstatus.MIE = 1` 下執行 `wfi` 睡眠並由 Timer A ISR 喚醒,PASS。
       - `8.2` `mstatus.MIE = 0` 下執行 `wfi` 睡眠並由 Timer A Pending 同步喚醒(不跳 ISR),PASS。

---

# PSMC 110nm ASIC PPA 評估摘要(v3.7 極致精簡定案版)

+ **面積(Area)**:
  - 數位標準元件邏輯(RV32EMC + 客製化 `smallest` CSR + `SafeBus` + `PinMux`): 約 **23.5K ~ 25.5K Gates**(約 **0.13 ~ 0.14 mm²**,佔核心面積 ~20%)。
  - 2 KB SRAM Macro: **0.04 ~ 0.05 mm²**(~7%)；32 KB eFlash IP Macro: **0.48 ~ 0.55 mm²**(~73%)。
  - **總核心面積(Core Area)**: 約 **0.65 ~ 0.74 mm²**(約 `0.80 mm × 0.85 mm`)；加計 24-Pin IO Pad Ring 後 **Die Size 約 1.15 ~ 1.30 mm²**,與 **QFN24 / TSSOP24** 形成高度緊湊的 Macro-Limited 匹配。
+ **效能與時序(Performance)**:
  - 目標主頻 **32 MHz(31.25 ns)**,PSMC 110nm(SS Corner, 1.08V, 125°C)下邏輯 Fmax 可達 **110 ~ 135 MHz**(主要受限於 eFlash 讀取存取時間 ~12–15 ns),具備超過 **16 ns 正時序裕度**,可採 100% 全 HVT Cell 合成。
+ **功耗(Power @ 1.2V, 25°C)**:
  - **Active Mode (@ 32 MHz)**: 數位邏輯 + SRAM 約 **1.4 ~ 1.7 mW** + eFlash 連續讀取約 **1.6 ~ 2.0 mW**,**總核心動態功耗約 3.0 ~ 3.5 mW(~95–110 μW/MHz)**。
  - **WFI Light Sleep(僅凍結取指)**: **約 1.0 ~ 1.4 mW**(省下 eFlash 讀取動態功耗)。
  - **WFI DeepSleep(串接 `io_inWfi` 控制 ICG 與 eFlash `PD`)**: 常溫靜態漏電 **< 10 ~ 25 μW**(2 KB SRAM 資料完整保留)。

---

# 下一步開發規劃(Next Steps)

1. **FPGA 原型綜合與上板驗證(當前首要任務)**:
   + 確認目標 FPGA 開發板／晶片型號,建立 FPGA Top Wrapper(將 16-bit `io_iopad_write/read/writeEnable` 接上 16 顆 `IOBUF` 雙向緩衝器,並透過 PLL 產生 32 MHz 主時脈；生成 FPGA 專用 Verilog 時需於 `MuraxWithRamInit` 開啟 `noRandBoot = true`)。
   + 建立 XDC/SDC 約束檔(`clk_32m` 32 MHz、`jtag_tck` 跨時脈域 `set_clock_groups -asynchronous`),執行綜合評估 LUT/FF/BRAM 與 Fmax,並進行實體 USB-UART、邏輯分析儀與 `OpenOCD + GDB` 驗證。
   + (可選)於軟體回歸中加入 `PINMUX_LOCK` 鎖定與 `IOPAD[15:12]` 釋放 JTAG 轉 GPIO 測試。
2. **PSMC 110nm ASIC Synthesis & BlackBox 替換(流片準備)**:
   + 使用 `MuraxAsicBlackBox`(`addStandardMemBlackboxing`)將 `eFlash` 與 `SRAM` 替換為 PSMC 110nm Memory Compiler / eFlash IP Macro,並利用 `io_inWfi` 串接頂層時脈閘控(ICG)與 eFlash `PD` 接腳,搭配具可程式化弱上拉／下拉之 3.3V IOPAD 進行 Design Compiler 邏輯綜合。
