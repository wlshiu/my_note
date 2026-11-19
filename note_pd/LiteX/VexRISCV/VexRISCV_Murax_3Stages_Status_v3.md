
📌 VexRiscv Murax SoC 開發進度與環境交接文件 (v3.0)


# 1. 專案目標與核心規格

本專案基於 SpinalHDL v1.13.0 修改 VexRiscv Murax SoC,打造一個極致精簡且具備完整常用周邊的微控制器架構:
+ 處理器核心: VexRiscv 3 階管線(Fetch + Decode + Execute; 關閉 Memory 與 WriteBack 階段)。
+ 指令集架構: RV32IMC(32 位元整數、硬體乘除法 MulSimplePlugin + DivPlugin、16-bit 壓縮指令 RVC; 保留完整 32 個暫存器 `regFileReadyKind = SYNC`)。
+ 系統時脈: 預設 12 MHz(coreFrequency = 12 MHz)。
+ 除錯介面: JTAG 介面,支援 4 組硬體斷點(hardwareBreakpointCount = 4),可透過 `OpenOCD + GDB` 進行 hbreak 與壓縮指令單步除錯。

# 2. 記憶體映射與周邊配置(已更新至包含 SPI & I2C)


| 區塊 / 周邊名稱  |  模組類別 / 規格                               | 基底位址     | 容量 / 範圍 | 說明與中斷連線
| :-              | :-                                            | :-          | :-          | :-
| eFlash (XIP)    | MuraxEmbeddedFlash (唯讀 BRAM)                 | 0x00000000  | 32 KB      | 支援 XIP; `0x0` 開機向量、`0x20` 中斷向量 (`mtvecInit`)
| On-chip SRAM    | MuraxPipelinedMemoryBusRam                     | 0x20000000  | 2 KB       | 存放 `.data`、`.bss` 與 `Stack`(`sp` 頂端位於 `0x20000800`)
| GPIO            | Apb3Gpio (32-bit 雙向)                         | 0xF0000000  | 4 KB       | 三態陣列 `io.gpioA`
| UART            | Apb3UartCtrl (115200 8N1)                      | 0xF0010000  | 4 KB       | TX/RX FIFO 各 16 深; 接至 CPU `externalInterrupt`
| Timer           | MuraxApb3Timer (16-bit Prescaler + 2 Timers)   | 0xF0020000  | 4 KB       | 接至 CPU `timerInterrupt` (`mcause = 0x80000007`)
| SPI Master      | Apb3SpiMasterCtrl (1x SS, 8-bit, FIFO 32)      | 0xF0030000  | 4 KB       | [新增] 接至 CPU `externalInterrupt` (`mcause = 0x8000000B`)
| I2C Controller  | Apb3I2cCtrl (支援 Master/Slave, 12-bit Timer)  |  0xF0040000 |  4 KB      |  [新增] 接至 CPU `externalInterrupt` (`mcause = 0x8000000B`)


## 中斷系統架構特性

+ 向量模式: Direct Mode,所有異常與中斷統一跳轉至 `0x00000020`(`trap_entry`)。
+ 巢狀中斷: 預設關閉(進入中斷時硬體自動清除 `mstatus.MIE`),考量 2KB 極小 SRAM,維持非巢狀處理以防 Stack 溢位。
+ 中斷來源區分:
    - `mcause == 0x80000007`: Timer 中斷(需寫入 `0xF0020010` 清除 Pending)。
    - `mcause == 0x8000000B`: 外部中斷, UART、SPI、I2C 共用,需在 `irqCallback()` 中依序讀取各周邊狀態暫存器判斷來源並清除旗標。

# 3. 已完成並驗證通過的關鍵檔案狀態

+ 硬體 RTL (`src/main/scala/vexriscv/demo/Murax.scala`):
    - 已整合 `Apb3SpiMasterCtrl` 與 `Apb3I2cCtrl` 至 `MuraxConfig` 與 `Murax` 頂層 IO(`io.spi`、`io.i2c`)。
    - 執行 `sbt "runMain vexriscv.demo.MuraxWithRamInit"` 已成功產生最新 `Murax.v`、`cpu0.yaml`
        及單一 32-bit 寬度的 Flash 初始化檔 `Murax.v_toplevel_system_eFlash_flash.bin`(8192 words)。
+ 連結腳本 (`linker.ld`):
    - 定義 `FLASH` (`0x00000000`, 32K) 與 `RAM` (`0x20000000`, 2K)。
    - 設定 `__global_pointer$` 位於 `.data` 起始 `+ 0x400`(SRAM 正中央,最佳化 RISC-V 相對定址)。
    - 加入 `._stack_check` 區塊(`__STACK_SIZE = 0x200`),於連結期強制保留至少 512 Bytes Stack 安全空間。
+ 啟動與中斷底層 (`crt.S`):
    - 已完成 `sp` (`0x20000800`) 與 `gp` (`__global_pointer$`,搭配 `.option norelax`) 初始化、`.data` 搬移、`.bss` 清零與 `mtvec` 設定。
    - `trap_entry` 完整保存/還原 16 個 Caller-saved 暫存器(64 Bytes,16-byte 對齊),相容 RV32IMC,並呼叫弱符號 `irqCallback()` 後以 `mret` 返回。
+ 韌體轉換腳本 (`z_update_ram.py`):
    - 已整合 `flash`(預設,輸出單一 32-bit `Murax.v_toplevel_system_eFlash_flash.bin`)與 ram(4 個 8-bit `symbol` 檔)雙模式。
    - 使用指令: `./z_update_ram.py -i src/main/c/murax/my_hello/build/my_hello.bin -t flash`
+ Verilator C++ Testbench (`src/test/cpp/murax/main.cpp`):
    - 已新增 `SpiI2cSimProcess` 掛載進 `Workspace<VMurax>`,實作 **SPI Loopback**(`MOSI` 接回 `MISO`)
        以及 **I2C Open-Drain 上拉與虛擬 Slave 狀態機**(7-bit 位址 `0x50`,預設暫存器值 `0x5A`)。
    - `make clean run` 已編譯通過並成功執行 XIP 開機印出 `hello world arty a7 v1`。

# 4. 下一步開發規劃 (Next Steps)

+ 撰寫 `main.c` 整合韌體驗證程式(模擬器驗證):
    - 建立 `spi_i2c.h` 與 `main.c`,在 Verilator 環境下實測:
        1. 全域變數讀寫(驗證 `.data` 搬移、`.bss` 清零與 `$gp` 定址)。
        1. 硬體乘除法運算(驗證 RVM 指令集)。
        1. Timer 週期性中斷(驗證 `mcause == 0x80000007`)。
        1. SPI Master Loopback 收發與 RX 中斷、I2C Master 對虛擬 Slave (`0x50`) 讀寫與 `RX_DATA_FULL` 中斷(驗證 `mcause == 0x8000000B`)。
+ FPGA 綜合與效能評估:
    - 建立 FPGA Top Wrapper(特別注意將 `io_i2c_scl_write/read` 與 `io_i2c_sda_write/read` 接上三態緩衝器 `IOBUF` 實現 Open-Drain)。
    - 建立時脈(12 MHz 或目標頻率)與腳位約束檔(XDC / SDC),進行綜合並評估 LUT / FF / BRAM 資源佔用與最高工作頻率(Fmax)。
