
📌 VexRiscv Murax SoC 開發進度與環境交接文件 (v3.2)

# 專案目標與核心規格

本專案基於 SpinalHDL v1.13.0 修改 VexRiscv Murax SoC,打造極致精簡且具備完整常用周邊的微控制器架構：
+ **處理器核心**: VexRiscv 3 階管線(Fetch + Decode + Execute; 關閉 Memory 與 WriteBack 階段)。
+ **指令集架構**: RV32IMC(32 位元整數、硬體乘除法 `MulSimplePlugin` + `DivPlugin`、16-bit 壓縮指令 RVC; 保留完整 32 個暫存器 `regFileReadyKind = SYNC`)。
+ **系統時脈**: 預設 12 MHz(`coreFrequency = 12 MHz`)。
+ **除錯介面**: JTAG 介面,支援 4 組硬體斷點(`hardwareBreakpointCount = 4`),可透過 `OpenOCD + GDB` 進行 `hbreak` 與壓縮指令單步除錯。

# 記憶體映射與周邊配置

| 區塊 / 周邊名稱 | 模組類別 / 規格 | 基底位址 | 容量 / 範圍 | 說明與中斷連線 |
| :--- | :--- | :--- | :--- | :--- |
| **eFlash (XIP)** | MuraxEmbeddedFlash (唯讀 BRAM) | `0x00000000` | 32 KB | 支援 XIP; `0x0` 開機向量、`0x20` 中斷向量 (`mtvecInit`) |
| **On-chip SRAM** | MuraxPipelinedMemoryBusRam | `0x20000000` | 2 KB | 存放 `.data`、`.bss` 與 `Stack`(`sp` 頂端位於 `0x20000800`) |
| **GPIO** | Apb3Gpio (32-bit 雙向) | `0xF0000000` | 4 KB | 三態陣列 `io.gpioA` |
| **UART** | Apb3UartCtrl (115200 8N1) | `0xF0010000` | 4 KB | TX/RX FIFO 各 4 深; 接至 CPU `externalInterrupt` |
| **Timer** | MuraxApb3Timer (16-bit Prescaler + 2 Timers) | `0xF0020000` | 4 KB | 接至 CPU `timerInterrupt`(`mcause = 0x80000007`) |
| **SPI Master** | Apb3SpiMasterCtrl (1x SS, 8-bit, FIFO 4) | `0xF0030000` | 4 KB | 接至 CPU `externalInterrupt`(`mcause = 0x8000000B`) |
| **I2C Controller** | Apb3I2cCtrl (支援 Master/Slave, 12-bit Timer) | `0xF0040000` | 4 KB | 接至 CPU `externalInterrupt`(`mcause = 0x8000000B`) |

## 中斷系統與關鍵硬體特性(已實測確認)

+ **向量模式**: Direct Mode,所有異常與中斷統一跳轉至 `0x00000020`(`trap_entry`)。
+ **CSR 唯讀與除錯限制**: `CsrPluginConfig.smallest` 將 `mtvec` 硬體固定為 `0x20`(寫入會觸發異常),且未生成 JTAG Debug 讀取通道,因此 **GDB 的 `info r mie mstatus mtvec` 會顯示 `0x0`,屬正常硬體行為**; CPU 內部執行 `csrr` 指令可正常讀出 `MIE = 0x00000880`、`MSTATUS = 0x00001808`。
+ **非巢狀中斷**: 進入中斷時硬體自動清除 `mstatus.MIE`,維持非巢狀處理以保護極小的 2 KB SRAM。
+ **中斷來源區分**:
  - `mcause == 0x80000007`: Timer 中斷(寫入 `0xF0020010` 清除 Pending)。
  - `mcause == 0x8000000B`: 外部中斷,**SPI、I2C、UART** 共用,需在 `irqCallback()` 中依序輪詢各周邊狀態並清除旗標。
+ **Apb3I2cCtrl 硬體實作關鍵細節(已從 `Murax.v` 核對確認)**:
  - **Listen 機制**: `RX_DATA` (`0x08`) 與 `RX_ACK` (`0x0C`) 在接收前必須先寫入 `Bit 9 = 1` (`I2C_RX_LISTEN`),硬體才會鎖存資料並將 `Bit 8` (`VALID`) 置 `1`(讀取後自動清除)。
  - **Timeout 機制**: `TIMEOUT` (`0x2C`) 不可設為 `0`,否則狀態機一啟動就會立即觸發 Timeout Drop 鎖死; 目前設為 `120000` (10 ms)。
  - **中斷暫存器非對稱映射**: `INT_ENABLE` (`0x20`) 的 `Bit[3:0]` 為資料流中斷(Bit 0=`rxData`, Bit 1=`rxAck`, Bit 2=`txDataEmpty`, Bit 3=`txAckEmpty`),屬 Level-triggered,**不存在於 `INT_FLAG` (`0x24`) 中**,需直接讀取 `RX_DATA`/`RX_ACK` 清除; `Bit[7:4]` (START/RESTART/STOP/DROP) 與 `Bit[16:15]` (ClockGen Enter/Exit) 則在 `0x20` 與 `0x24` 一對一對應(W1C)。

# 已完成並驗證通過的檔案狀態(Current Stage)

1. **硬體 RTL (`src/main/scala/vexriscv/demo/Murax.scala`)**:
   + 已整合 `Apb3SpiMasterCtrl` 與 `Apb3I2cCtrl` 至 `MuraxConfig` 與 `Murax` 頂層 IO(`io.spi`、`io.i2c`)。
   + 執行 `sbt "runMain vexriscv.demo.MuraxWithRamInit"` 可產生 `Murax.v`、`cpu0.yaml` 及單一 32-bit 寬度的 Flash 初始化檔 `Murax.v_toplevel_system_eFlash_flash.bin`(8192 words)。
2. **連結腳本 (`linker.ld`) & 啟動組語 (`crt.S`)**:
   + `trap_entry` 嚴格對齊於 `0x00000020`; `.data` 搬移、`.bss` 清零與 `$gp` 相對定址運作正常; 保留至少 512 Bytes (`0x200`) Stack 空間,並保存/還原 16 個 Caller-saved GPRs(64 Bytes,16-byte 對齊)。
3. **周邊暫存器標頭檔 (`murax_reg.h`)**:
   + 已完整定義 GPIO、UART、Timer、SPI (`0xF0030000`)、I2C (`0xF0040000`) 之結構體指標、Bit-field 巨集與完整 Inline 驅動輔助函式(含 `spi_init_master`、`i2c_init_master_100khz`、`i2c_master_write_byte`、`i2c_master_trigger_read_byte` 等)。
4. **Verilator 模擬環境 (`src/test/cpp/murax/main.cpp`)**:
   + 已掛載 `SpiI2cSimProcess`,實作 `SPI Loopback`(`MOSI` 接回 `MISO`)以及 **I2C Open-Drain 上拉與虛擬 Slave 狀態機**(7-bit 位址 `0x50`,預設暫存器值 `0x5A`,並已處理 Master NACK 後釋放 SDA 讓 STOP 正常完成)。
   + 韌體更新指令: `./z_update_ram.py -i src/main/c/murax/my_hello/build/my_hello.bin -t flash`。
5. **已全數通過 Verilator 實測的韌體項目 (`main.c`)**:
   + ✅ **[Test 0] CSR 中斷使能**: `csrr` 驗證 `MIE = 0x00000880`、`MSTATUS = 0x00001808`。
   + ✅ **[Test 1] SRAM 記憶體區段**: 全域變數 `.data` 搬移(`0x12345678`)與 `.bss` 清零(`0x00000000`)皆 PASS。
   + ✅ **[Test 2] RV32M 硬體乘除法**: `12345 * 6789 = 0x04FED79D`、`DIV = 0x000A65A7`、`REM = 0x00000060` 皆 PASS。
   + ✅ **[Test 3] Timer 週期性中斷**: 12 MHz 下設定 1 ms tick,成功進入 `mcause = 0x80000007` 觸發 5 次中斷並正常返回。
   + ✅ **[Test 4] UART RX 外部中斷**: 在 Verilator 輸入字元成功觸發 `mcause = 0x8000000B`,讀空 RX FIFO 自動清除 Pending 並正常 Echo 回傳。
   + ✅ **[Test 5] SPI Master Loopback**: 1 MHz SCLK Mode 0 下收發 `0xA5`、`0x5A`,觸發 2 次外部中斷(`mcause = 0x8000000B`)並正確讀回,PASS。
   + ✅ **[Test 6] I2C Master 讀取虛擬 Slave**: 100 kHz 時序下對 `0x50` 讀取(`0xA1`),收到 Addr ACK、觸發 1 次外部中斷(`mcause = 0x8000000B`)並正確讀出 `0x5A`,PASS。

# 下一步開發規劃 (Next Steps)

1. **FPGA 綜合與效能評估(當前首要任務)**:
   + 確認目標 FPGA 開發板／晶片型號,建立對應的 FPGA Top Wrapper(將 `io_i2c_scl_write/read`、`io_i2c_sda_write/read` 與 `io_gpioA` 接上雙向三態緩衝器 `IOBUF` 實現 Open-Drain 與雙向 IO)。
   + 建立時脈(`clk_12m` 12 MHz、`jtag_tck` 跨時脈域 `set_clock_groups -asynchronous`)與腳位約束檔(XDC / SDC),並確保 `Murax.v_toplevel_system_eFlash_flash.bin` 正確載入 BRAM。
   + 執行綜合與實作(Synthesis & Implementation),評估 LUT / FF / BRAM 資源佔用與最高工作頻率(Fmax)。
2. **實體開發板上板驗證**:
   + 燒錄 Bitstream 至 FPGA,透過實體 USB-UART、邏輯分析儀(量測 SPI/I2C 波形)與 `OpenOCD + GDB` 進行實體硬體驗證。
