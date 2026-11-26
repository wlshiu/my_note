📌 VexRiscv Murax SoC 開發進度與環境交接文件 (v3.6)

# 專案目標與核心規格(定案版: 鎖定 PSMC 110nm 24-Pin ASIC 規格)

本專案基於 SpinalHDL v1.13.0 修改 VexRiscv Murax SoC,針對 **PSMC(力積電)110nm 製程、24-Pin 封裝(如 QFN24 / TSSOP24)** 打造極致精簡、低功耗且具備完整常用周邊的 32-bit 微控制器架構(已通過 Verilator 全系統回歸驗證):
+ **處理器核心**: VexRiscv 3 階管線(Fetch + Decode + Execute; 關閉 Memory 與 WriteBack 階段)。
+ **指令集架構**: **RV32EMC**(32 位元精簡暫存器架構 `rv32e = true`,僅保留 `x0~x15` 共 16 個暫存器; 含硬體乘除法 `MulSimplePlugin` + `DivPlugin`、16-bit 壓縮指令 RVC `compressedGen = true`; 暫存器檔採同步讀取 `regFileReadyKind = SYNC`)。**軟體編譯參數必須鎖定 `-march=rv32emc -mabi=ilp32e`**。
+ **系統時脈**: **32 MHz**(`coreFrequency = 32 MHz`; 31.25 ns 週期,eFlash 採 **0 Wait State** 單週期同步讀取)。
+ **低功耗睡眠控制 (`WFI`)**: 啟用 `wfiGenAsWait = true`,並透過 `cpu.rework` 匯出頂層狀態接腳 **`io.inWfi`**(`output wire io_inWfi`)。執行 `wfi` 時 CPU 凍結管線並拉高 `io.inWfi`(支援 `MIE=1` 進 ISR 喚醒,以及 `MIE=0` 同步喚醒不進 ISR),可直接對接 ASIC 頂層時脈閘控(ICG)與 eFlash `PD`(Power Down)省電接腳。
+ **實體腳位架構**: 頂層收斂為統一的 **16-bit 雙向三態匯流排 `io.iopad`**(配合 24-pin 封裝扣除電源／時脈／重置後之可用腳位),透過 APB `MuraxSysCtrlPinMux` 動態多工切換 GPIO、UART、SPI、I2C 與 JTAG。`withXip = false`(SpinalHDL 條件生成確保 XIP 零殘存面積)。
+ **安全匯流排架構**: 配置 `MuraxSafeMasterArbiter` 與 `MuraxSafePipelinedMemoryBusDecoder`,支援未映射位址讀取(`noHit`)與未映射位址取指之 `Access Fault` 異常回報; 所有寫入交易維持高速單週期 Posted Write(不等待回應,無匯流排死鎖風險)。
+ **除錯介面**: JTAG 介面(預設映射於 `IOPAD[15:12]`,開機即啟用),支援 4 組硬體斷點(`hardwareBreakpointCount = 4`),可透過 `OpenOCD + GDB` 進行 `hbreak` 與壓縮指令單步除錯。

---

# 記憶體映射與周邊配置

| 區塊 / 周邊名稱 | 模組類別 / 規格 | 基底位址 | 容量 / 範圍 | 說明與中斷連線 |
| :--- | :--- | :--- | :--- | :--- |
| **eFlash (XIP)** | MuraxEmbeddedFlash (唯讀 BRAM / ASIC eFlash IP) | `0x00000000` | 32 KB | 支援 XIP (0 Wait State); `0x0` 開機向量、`0x20` 中斷向量 (`mtvecInit`) |
| **On-chip SRAM** | MuraxPipelinedMemoryBusRam | `0x20000000` | 2 KB | 存放 `.data`、`.bss` 與 `Stack`(`sp` 頂端位於 `0x20000800`) |
| **GPIO** | Apb3Gpio (16-bit 雙向) | `0xF0000000` | 4 KB | 經 `MuraxSysCtrlPinMux` 連接至 `io.iopad[15:0]` |
| **UART** | Apb3UartCtrl (115200 8N1) | `0xF0010000` | 4 KB | TX/RX FIFO 各 4 深; 接至 CPU `externalInterrupt` (`mcause = 0x8000000B`) |
| **Timer** | MuraxSplitApb3Timer (16-bit Prescaler + 2 Timers) | `0xF0020000` | 4 KB | **分流架構**: `Timer A` 接 CPU `timerInterrupt` (`mcause = 0x80000007`); `Timer B` 接 CPU `externalInterrupt` (`mcause = 0x8000000B`) |
| **SPI Master** | Apb3SpiMasterCtrl (1x SS, 8-bit, FIFO 4) | `0xF0030000` | 4 KB | 接至 CPU `externalInterrupt` (`mcause = 0x8000000B`) |
| **I2C Controller** | Apb3I2cCtrl (支援 Master/Slave, 12-bit Timer) | `0xF0040000` | 4 KB | 接至 CPU `externalInterrupt` (`mcause = 0x8000000B`) |
| **SysCtrl & PinMux** | MuraxSysCtrlPinMux (16-Pin IOPAD 多工器) | `0xF0050000` | 4 KB | `0x00`: `PINMUX_SEL0`、`0x04`: `PINMUX_SEL1`、`0x08`: `SYS_STATUS` (`0x00200016`)、`0x0C`: `PINMUX_LOCK` (Write-1-Once 鎖定) |

---

## 16-Pin IOPAD 多工映射表(`MuraxSysCtrlPinMux`)

每支腳位由 2-bit 控制(`0`=GPIO, `1`=ALT1, `2`=ALT2)。重置後預設值: `PINMUX_SEL0 = 0x0000`、`PINMUX_SEL1 = 0x5500`(`IOPAD[15:12]` 預設為 JTAG,其餘為 GPIO; 未選通之周邊輸入端內部自動拉高為 Idle High `1`); 寫入 `PINMUX_LOCK = 1` 後可鎖定多工配置直到下次 Reset:

| 實體腳位 | Mode 0 (`2'b00`) | Mode 1 (`2'b01`) | Mode 2 (`2'b10`) | 電氣特性與備註 |
| :--- | :--- | :--- | :--- | :--- |
| **IOPAD** | `GPIO` | `UART_TXD` (推挽輸出) | — | 韌體啟動後需呼叫 `pinmux_enable_uart(true)` |
| **IOPAD** | `GPIO` | `UART_RXD` (輸入) | — | 韌體啟動後需呼叫 `pinmux_enable_uart(true)` |
| **IOPAD** | `GPIO` | `I2C_SCL` (Open-Drain) | — | 硬體自動轉 Open-Drain: `write=0, writeEnable=~scl.write` |
| **IOPAD** | `GPIO` | `I2C_SDA` (Open-Drain) | — | 硬體自動轉 Open-Drain: `write=0, writeEnable=~sda.write` |
| **IOPAD[4..7]** | `GPIO[4..7]` | — | `SPI` (`SS0`, `SCLK`, `MOSI`, `MISO`) | 呼叫 `pinmux_enable_spi(true)` 啟用 |
| **IOPAD[8..11]** | `GPIO[8..11]` | — | — | 純通用 GPIO (4-bit) |
| **IOPAD[12..15]** | `GPIO[12..15]` | **`JTAG`** (`TMS`, `TCK`, `TDI`, `TDO`) | — | **開機預設 Mode 1**; 量產韌體可寫入 `0` 釋放為 GPIO |

---

## 中斷、異常與低功耗系統關鍵硬體特性(已實測確認)

+ **向量模式**: Direct Mode,所有異常與中斷統一跳轉至 `0x00000020`(`trap_entry`)。
+ **CSR 配置 (`CsrPluginConfig.all`)**: 保留完整異常診斷與系統呼叫能力(`mcause`、`mepc`、`mtval`、`mscratch`、`mtvec` 可讀寫、`ecallGen = true`、`wfiGenAsWait = true`、`deterministicInteruptionEntry = true`),並裁剪掉高面積的 64-bit 計數器(`ucycle/uinstret/utime = NONE`)。
+ **非巢狀中斷**: 進入中斷時硬體自動清除 `mstatus.MIE`,維持非巢狀處理以保護極小的 2 KB SRAM。
+ **中斷來源與分流設計**:
  - `mcause == 0x80000007` (`MCAUSE_MTI`): 僅由 **Timer A** 觸發(專責純淨無抖動的系統核心 Tick),寫入 `0x1` 至 `0xF0020010` 清除 Pending。
  - `mcause == 0x8000000B` (`MCAUSE_MEI`): 由 **Timer B、SPI、I2C、UART** 共用,需在 `trap_handler()` 中依序輪詢各周邊狀態並清除旗標。
  - **W1C Pending 清除規範**: `TIMER_INTERRUPT->PENDINGS` (`0xF0020010`) 為 Write-1-to-Clear 暫存器,清除旗標時必須使用直接賦值(例如 `TIMER_INTERRUPT->PENDINGS = TIMER_IRQ_A`),**嚴禁使用 `|=`**。
+ **Apb3I2cCtrl 硬體實作關鍵細節(32 MHz 時序配置)**:
  - **32 MHz 100 kHz I2C 參數**: `SAMPLING_DIV = 7` (4 MHz)、`TIMEOUT = 320000` (10 ms,不可為 0)、`TSU_DAT = 16` (500 ns)、`T_LOW = T_HIGH = T_BUF = 160` (5 µs)。
  - **Listen 與中斷映射**: `RX_DATA` (`0x08`) / `RX_ACK` (`0x0C`) 接收前需先寫入 `Bit 9 = 1`(`I2C_RX_LISTEN`); `INT_ENABLE` (`0x20`) 的 `Bit[3:0]` 為 Level-triggered 資料流中斷,不存在於 `INT_FLAG` (`0x24`),需直接讀取 `RX_DATA`/`RX_ACK` 清除。

---

# 已完成並通過 Verilator 實測的檔案狀態(Current Stage)

1. **硬體 RTL (`src/main/scala/vexriscv/demo/Murax.scala`)**:
   + 已定案 `coreFrequency = 32 MHz`、`gpioWidth = 16`、`withXip = false`、`rv32e = true`、`wfiGenAsWait = true`,並於頂層匯出 `io.inWfi`(`output wire io_inWfi`)。
   + 已整合 `MuraxSplitApb3Timer`、`MuraxSysCtrlPinMux` (`0xF0050000`,含 `0x0C` `PINMUX_LOCK`)、`MuraxSafeMasterArbiter` 與 `MuraxSafePipelinedMemoryBusDecoder`。
   + 執行 `sbt -J-Xmx2G "runMain vexriscv.demo.MuraxWithRamInit"` 可產生 `Murax.v`、`cpu0.yaml` 及 Flash 初始化檔 `Murax.v_toplevel_system_eFlash_flash.bin`(8192 words)。
2. **連結腳本 (`linker.ld`) & 啟動組語 (`crt.S`)**:
   + `trap_entry` 嚴格對齊於 `0x00000020`; `.data` 搬移、`.bss` 清零與 `$gp` 相對定址運作正常; 保留至少 512 Bytes (`0x200`) Stack 空間,並對應 RV32E 保存／還原 10 個 Caller-saved GPRs(`ra, t0~t2, a0~a5`,16-byte 對齊)。
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
       - `7.6` Instruction Fetch Invalid Address (`mcause = 1`) PASS。
       - `7.7` M-Mode `ECALL` 異常 (`mcause = 11`) PASS。
     - ✅ **[Test 8] WFI Sleep & Interrupt Wakeup 完整驗證**:
       - `8.1` `mstatus.MIE = 1` 下執行 `wfi` 睡眠並由 Timer A ISR 喚醒,PASS。
       - `8.2` `mstatus.MIE = 0` 下執行 `wfi` 睡眠並由 Timer A Pending 同步喚醒(不跳 ISR),PASS。

---

# PSMC 110nm ASIC PPA 評估摘要(v3.6 定案版)


## 面積評估(Area)— 邏輯微增 < 50 Gates,整體維持緊湊 Macro-Limited

本次新增 `wfiGenAsWait = true` 與 `io_inWfi` 輸出腳位,硬體僅增加 1 個 `inWfi` 狀態暫存器及取指凍結(Fetch Stall)與中斷喚醒判斷的組合邏輯,對整體面積影響極微:

| 模組區塊                      | 規格 / 規模                              | 預估面積 (mm²)      | 佔 Core 比例  | 備註與變化說明
| :-                           | :-                                      | :-                  | :-           | :-
| 數位標準元件邏輯 (StdCell)     | 約 `25.1K ~ 27.6K Gates`                | `0.14 ~ 0.15 mm²`  | ~22%          | 較 v3.5 僅增加 `< 50 Gates`(`inWfi` 狀態機),`1-Gate` 約 `5.2 ~ 5.6 μm²`(含 75% 繞線利用率)
| On-chip SRAM Macro           |  2 KB (512 × 32-bit, Single-Port)       | `0.04 ~ 0.05 mm²`   | ~7%           | PSMC 110nm Memory Compiler 生成
| Embedded Flash IP (eFlash)   | 32 KB (8192 × 32-bit, Read-Only)        | `0.48 ~ 0.55 mm²`   | ~71%          | 含 Charge Pump 與 Sense Amp 巨集面積(決定核心尺寸下限)
| Core Area (核心總面積)        | 邏輯 + SRAM + eFlash                     | `~0.66 ~ 0.75 mm²` | 100%          | 約 `0.80 mm × 0.85 mm`
| Die Size (含 24-Pin Pad Ring) | 24-Pin (16 IOPAD + 電源/時脈/重置/inWfi) | `~1.15 ~ 1.30 mm²` |  —            | 約 `1.10 mm × 1.15 mm`,與 `QFN24 / TSSOP24` 封裝高度匹配

(註:`io_inWfi` 在 ASIC 實作中屬於內部電源管理控制訊號,直接連接至晶片內部的 ICG 時脈閘控與 eFlash IP 的 `PD` 接腳,**無需佔用額外的實體封裝 Pin 腳**)。



## 效能與時序評估(Performance & Timing)— 32 MHz 裕度極寬,零時序風險

+ 目標主頻:**32 MHz**(時脈週期 = `31.25 ns`)。
+ 關鍵路徑(Critical Path)影響評估:
    - `inWfi` 訊號是由 `CsrPlugin` 內的同步正反器(Flip-Flop)直接輸出,
        並拉至 `IBusSimplePlugin` 的取指致能端及頂層 `io_inWfi`;
        此路徑僅增加 1 級組合邏輯閘(< 0.15 ns),完全不會惡化關鍵路徑。
    - 系統最長路徑仍落在 **eFlash 同步讀取存取時間(約 12 ~ 15 ns) + VexRiscv Decode/Execute 組合邏輯(約 7 ~ 9 ns)**。
+ 製程極限 Fmax 與裕度:
    - 在 PSMC 110nm Worst-Case Corner(SS, 1.08V, 125°C)下,整體最高運作頻率(Fmax)預估為 `110 ~ 135 MHz`。
    - 在 **32 MHz** 目標頻率下擁有超過 **16 ns 以上的正時序裕度(Positive Setup Slack)**,
        綜合時可 100% 採用 全 **HVT(High-Vt)標準元件庫**,無需任何高漏電的 LVT 元件。



## 功耗評估(Power @ 1.2V)— 具備 Active / Light Sleep / DeepSleep 三段式省電能力

隨著 `wfiGenAsWait = true` 與 `io_inWfi` 匯出定案,這顆 ASIC 現在具備完整的三階電源狀態切換能力,功耗表現大幅升級:

| 電源模式 (Power Mode)                   | 硬體狀態與控制方式                             | 預估功耗 (@ 1.2V, 25°C)             | 關鍵省電機制與說明
| :-                                     | :-                                            | :-                                 | :-
| `Active Mode` (全速運作 @ 32 MHz)       | CPU 連續取指運算、周邊運作                      | 約 `3.2 ~ 3.6 mW` (~100–112 μW/MHz) | 數位邏輯 + SRAM 約 `1.5 ~ 1.8 mW`; 32 KB eFlash 連續讀取約 `1.6 ~ 2.0 mW`
| `WFI Light Sleep` (僅凍結取指)          | 執行 `wfi`(`io_inWfi = 1`),主時脈未關          | 約 `1.0 ~ 1.4 mW `                  | 省去 eFlash 讀取與指令解碼動態功耗(降幅 > 60%),但時脈樹仍翻轉
| `WFI DeepSleep` (搭配 ICG + eFlash PD)  | 利用 `io_inWfi` 閘控系統時脈並拉高 eFlash `PD` |  `< 10 ~ 25 μW`(常溫靜態漏電)        | 數位邏輯動態功耗歸零,2 KB SRAM 資料完整保留,僅剩全 HVT 漏電與喚醒周邊(Timer/GPIO)微弱電流

+ 高溫靜態漏電(85°C, FF Corner)
    > 採全 HVT 合成下,核心總靜態漏電預估約 `80 ~ 150 μW`。


---

# 下一步開發規劃(Next Steps)

1. **FPGA 原型綜合與上板驗證(當前首要任務)**:
   + 確認目標 FPGA 開發板／晶片型號,建立 FPGA Top Wrapper(將 16-bit `io_iopad_write/read/writeEnable` 接上 16 顆 `IOBUF` 雙向緩衝器,並透過 PLL 產生 32 MHz 主時脈; 生成 FPGA 專用 Verilog 時需於 `MuraxWithRamInit` 開啟 `noRandBoot = true`)。
   + 建立 XDC/SDC 約束檔(`clk_32m` 32 MHz、`jtag_tck` 跨時脈域 `set_clock_groups -asynchronous`),執行綜合評估 LUT/FF/BRAM 與 Fmax,並進行實體 USB-UART、邏輯分析儀與 `OpenOCD + GDB` 驗證。
   + (可選)於軟體回歸中加入 `PINMUX_LOCK` 鎖定與 `IOPAD[15:12]` 釋放 JTAG 轉 GPIO 測試。
2. **PSMC 110nm ASIC Synthesis & BlackBox 替換(流片準備)**:
   + 使用 `MuraxAsicBlackBox`(`addStandardMemBlackboxing`)將 `eFlash` 與 `SRAM` 替換為 PSMC 110nm Memory Compiler / eFlash IP Macro,並利用 `io_inWfi` 串接頂層時脈閘控(ICG)與 eFlash `PD` 接腳,搭配具可程式化弱上拉／下拉之 3.3V IOPAD 進行 Design Compiler 邏輯綜合。
