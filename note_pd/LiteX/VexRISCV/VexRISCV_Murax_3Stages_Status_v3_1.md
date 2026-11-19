
📌 VexRiscv Murax SoC 開發進度與環境交接文件 (v3.1)


# 專案目標與核心規格

本專案基於 SpinalHDL v1.13.0 修改 VexRiscv Murax SoC,打造極致精簡且具備完整常用周邊的微控制器架構:
+ 處理器核心: VexRiscv 3 階管線(Fetch + Decode + Execute;關閉 Memory 與 WriteBack 階段)。
+ 指令集架構: RV32IMC(32 位元整數、硬體乘除法 `MulSimplePlugin` + `DivPlugin`、16-bit 壓縮指令 RVC;保留完整 32 個暫存器 `regFileReadyKind = SYNC`)。
+ 系統時脈: 預設 12 MHz(`coreFrequency = 12 MHz`)。
+ 除錯介面: JTAG 介面,支援 4 組硬體斷點(`hardwareBreakpointCount = 4`),可透過 `OpenOCD + GDB` 進行 `hbreak` 與壓縮指令單步除錯。

# 記憶體映射與周邊配置


| 區塊 / 周邊名稱 |   模組類別 / 規格                              | 基底位址    | 容量 / 範圍 | 說明與中斷連線
| :-             | :-                                            | :-         | :-         | :-
| eFlash (XIP)   | MuraxEmbeddedFlash (唯讀 BRAM)                | 0x00000000  | 32 KB      | 支援 XIP;`0x0` 開機向量、`0x20`中斷向量 (`mtvecInit`)
| On-chip SRAM   | MuraxPipelinedMemoryBusRam                    | 0x20000000  | 2 KB       | 存放 `.data`、`.bss` 與 `Stack`(`sp` 頂端位於 `0x20000800`)
| GPIO           | Apb3Gpio (32-bit 雙向)                        |  0xF0000000 | 4 KB       | 三態陣列 `io.gpioA`
| UART           | Apb3UartCtrl (115200 8N1)                     | 0xF0010000  | 4 KB       | TX/RX FIFO 各 4 深;接至 CPU `externalInterrupt`
| Timer          | MuraxApb3Timer (16-bit Prescaler + 2 Timers)  | 0xF0020000  | 4 KB       | 接至 CPU `timerInterrupt` (`mcause = 0x80000007`)
| SPI Master     | Apb3SpiMasterCtrl (1x SS, 8-bit, FIFO 4)      | 0xF0030000  | 4 KB       | 接至 CPU `externalInterrupt` (`mcause = 0x8000000B`)
| I2C Controller | Apb3I2cCtrl (支援 Master/Slave, 12-bit Timer) |  0xF0040000 |  4 KB      |  接至 CPU `externalInterrupt` (`cause = 0x8000000B`)


## 中斷系統與關鍵硬體特性(已實測確認)

+ **向量模式**: Direct Mode,所有異常與中斷統一跳轉至 `0x00000020`(`trap_entry`)。
+ **CSR 唯讀與除錯限制**: `CsrPluginConfig.smallest` 將 `mtvec` 硬體固定為 `0x20`(寫入會觸發異常),
    且未生成 JTAG Debug 讀取通道,因此 ***GDB 的 `info r mie mstatus mtvec` 會顯示 `0x0`,屬正常硬體行為**;
    CPU 內部執行 `csrr` 指令可正常讀出 `MIE = 0x00000880`、`MSTATUS = 0x00001808`。
+ **非巢狀中斷**: 進入中斷時硬體自動清除 `mstatus.MIE`,維持非巢狀處理以保護極小的 2 KB SRAM。
+ **中斷來源區分**:
    - `mcause == 0x80000007`: Timer 中斷(寫入 `0xF0020010` 清除 Pending)。
    - `mcause == 0x8000000B`: 外部中斷,**UART、SPI、I2C** 共用,需在 `irqCallback()` 中依序讀取各周邊狀態暫存器判斷來源並清除旗標。

# 已完成並驗證通過的檔案狀態(Current Stage)

1. 硬體 RTL (`src/main/scala/vexriscv/demo/Murax.scala`):
    + 已整合 `Apb3SpiMasterCtrl` 與 `Apb3I2cCtrl` 至 `MuraxConfig` 與 `Murax` 頂層 IO(`io.spi`、`io.i2c`)。
    + 執行 `sbt "runMain vexriscv.demo.MuraxWithRamInit"` 可產生 `Murax.v`、`cpu0.yaml` 及
        單一 32-bit 寬度的 Flash 初始化檔 `Murax.v_toplevel_system_eFlash_flash.bin`(8192 words)。
2. 連結腳本 (`linker.ld`) & 啟動組語 (`crt.S`):
    + 透過 `.map` 檔驗證 `trap_entry` 嚴格對齊於 `0x00000020`;`.data` 搬移、`.bss` 清零與 `$gp` 相對定址運作正常;
        保留至少 512 Bytes (`0x200`) Stack 空間。
    + `trap_entry` 依據 RISC-V 標準 ABI 保存/還原 16 個 Caller-saved GPRs(64 Bytes,16-byte 對齊;Callee-saved `s0~s11` 由 GCC 自動管理),相容 RV32IMC。
3. 周邊暫存器標頭檔 (`murax_reg.h`):
    + 已完整定義 GPIO、UART、Timer、SPI (`0xF0030000`)、I2C (`0xF0040000`) 之結構體指標、Bit-field 巨集與 Inline 輔助函式。
4. Verilator 模擬環境 (`src/test/cpp/murax/main.cpp`):
    + 已掛載 `SpiI2cSimProcess`,實作 `SPI Loopback`(`MOSI` 接回 `MISO`)以及 **I2C Open-Drain 上拉與虛擬 Slave 狀態機**(7-bit 位址 `0x50`,預設暫存器值 `0x5A`)。
    + 韌體更新指令: `./z_update_ram.py -i src/main/c/murax/my_hello/build/my_hello.bin -t flash`。
5. 已通過 Verilator 實測的韌體項目 (`main.c`):
    + ✅ [Test 0] CSR 中斷使能: `csrr` 驗證 `MIE = 0x00000880`、`MSTATUS = 0x00001808`。
    + ✅ [Test 1] SRAM 記憶體區段: 全域變數 `.data` 搬移(`0x12345678`)與 `.bss` 清零(`0x00000000`)皆 PASS。
    + ✅ [Test 2] RV32M 硬體乘除法: `12345 * 6789 = 0x04FED79D`、`DIV = 0x000A65A7`、`REM = 0x00000060` 皆 PASS。
    + ✅ [Test 3] Timer 週期性中斷: 12 MHz 下設定 1 ms tick,成功進入 `mcause = 0x80000007` 觸發 5 次中斷並正常返回。
    + ✅ [Test 4] UART RX 外部中斷: 在 Verilator 輸入字元成功觸發 `mcause = 0x8000000B`,讀空 RX FIFO 自動清除 Pending 並正常 Echo 回傳。

    > (GDB 除錯備註: 因 GCC `-O2/-Os` 最佳化與 RVC 壓縮指令對齊,設中斷斷點時應使用 `hbreak irqCallback` 或 `disassemble /m irqCallback` 來取得精確位址 `hbreak *0x...`。)

# 下一步開發規劃 (Next Steps)

1. 在 `main.c` 中加入 `SPI Master Loopback` 測試(當前首要任務):
    + 設定 `SPI`(Base `0xF0030000`)Mode 0、SCLK 除頻與 `STATUS` Bit 1(開啟 RX 中斷)。
    + 發送 `SPI_CMD_SS_ENABLE(0)`、`SPI_CMD_DATA_RX(byte)`、`SPI_CMD_SS_DISABLE(0)`,
        驗證 `MOSI -> MISO` Loopback 資料接收與外部中斷(`mcause = 0x8000000B`)。
2. 在 `main.c` 中加入 `I2C Master` 讀寫測試:
    + 設定 `I2C`(Base `0xF0040000`)100 kHz 時序與 `I2C_INT_RX_DATA_FULL` 中斷。
    + 對 Verilator 虛擬 Slave(7-bit 位址 `0x50`)執行讀取測試,驗證收到預設值 `0x5A` 與外部中斷處理。
3. FPGA 綜合與效能評估:
    + 建立 FPGA Top Wrapper(將 `io_i2c_scl_write/read` 與 `io_i2c_sda_write/read` 接上三態緩衝器 `IOBUF` 實現 Open-Drain)。
    + 建立時脈(12 MHz)與腳位約束檔(XDC / SDC),評估 LUT / FF / BRAM 資源佔用與最高工作頻率(Fmax)。
