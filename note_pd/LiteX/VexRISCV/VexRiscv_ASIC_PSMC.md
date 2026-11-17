
# PSMC(力積電) 110nm製程
在 `PSMC(力積電)110nm` 製程(如 110nm High-Voltage、Embedded Flash 或一般 Logic 製程,常見於驅動 IC、PMIC 電源管理與微控制器)中,
導入 VexRiscv 作為極小面積的裸機(Bare-metal)控制核心,是一個非常成熟且具高性價比的選擇。

在此配置下,核心面積可壓縮至約 `15,000 ~ 25,000` Gate Counts(NAND2 等效閘數),在 PSMC 110nm 製程中僅佔用約 `0.08 ~ 0.15 mm²` 的矽晶面積,
且能輕鬆達到 `50 ~ 100 MHz` 的運作時脈,完全足以取代傳統 8051 或付費的 ARM Cortex-M0/M0+。

以下針對 PSMC 110nm 製程特性 與 極小面積裸機控制 提供具體的架構配置與實體設計(Backend)建議:

## VexRiscv 極小面積插件配置(SpinalHDL 設定)

為了將邏輯閘數壓到最低並符合裸機控制需求,建議在產生 Verilog 時採用`無快取(Cacheless) + 2 或 3 級管線`配置,並精簡不必要的硬體模組:
+ 指令集架構(ISA)選擇 `RV32I` 或 `RV32EC`(僅 16 個暫存器+壓縮指令):
    若您的控制韌體需要大量節省內部 Flash/ROM 空間,強烈建議開啟壓縮指令插件(CompressedInjectorPlugin),
    能減少約 `25% ~ 30%` 的程式碼體積,雖然會增加約 `2,000 Gates` 的解碼邏輯,但能大幅省下昂貴的 110nm Embedded Flash 或 SRAM 面積。

+ 移除快取與分支預測:
    在 110nm 製程中,片上 SRAM(Single-cycle access)的存取延遲極低,完全不需要 I$(指令快取)與 D$(資料快取);
    將 IBusSimplePlugin 與 DBusSimplePlugin 設為無快取模式,並將分支預測設為靜態預測(Prediction.NONE),可省下大量的 Tag RAM 與控制邏輯

+ 乘法與除法器取捨:
    若控制演算法不涉及複雜 DSP 運算,直接移除 MulPlugin 與 DivPlugin(改由編譯器用軟體函式庫模擬);
    若必須使用(例如馬達控制或電源迴路計算),請配置為 迭代式(Iterative / Multi-cycle) 乘法器而非單週期全平行乘法器,可節省數千個 Gates

+ 中斷與除錯精簡:
    保留基礎的 CsrPlugin(設為 CsrPluginConfig.smallest 僅支援 Machine Mode 中斷),
    並透過標準的 DebugPlugin 搭配實體 4 線 JTAG(TCK/TMS/TDI/TDO)以供晶片回片(Silicon Bring-up)時除錯

## PSMC 110nm 記憶體(SRAM / ROM)整合策略

在 110nm 製程中,記憶體巨集(Memory Macro)的面積與功耗往往遠大於 CPU 核心本身,因此需要特別針對 PSMC Memory Compiler 進行優化:
+ 暫存器堆(RegFile)實作方式:
    VexRiscv 的 32 個(或 RV32E 的 16 個)通用暫存器預設會被合成為正反器(Flip-Flop).
    在 110nm 製程下,若採用 RV32E(16x32-bit = 512 bits),直接用 Standard Cell Flip-Flop 合成的面積非常小,
    且時序(Timing)最單純,無需額外呼叫兩埠(2R1W)SRAM Macro,可避免 Memory Compiler 在小容量下周邊電路(Peripheral Circuit)面積過大的問題。

+ Tightly-Coupled Memory (TCM) 架構:
    將指令記憶體(IRAM/ROM)與資料記憶體(DRAM)直接掛載在 VexRiscv 的 Simple Bus 上,採用 `1RW(單埠)高密度 SRAM Macro`.
    建議將指令與資料空間分開(哈佛架構),避免同週期取指與讀寫資料產生匯流排競爭(Bus Contention)

## PSMC 110nm 邏輯合成與 DFT(可測試性設計)注意事項

PSMC 110nm 製程通常提供標準電壓(1.2V Core / 3.3V IO)或低功耗(LP)標準元件庫,在將 SpinalHDL 產生的 Verilog 導入 Design Compiler / Genus 時需注意以下設定:
+ 重置訊號(Reset)轉換:
    SpinalHDL 預設部分模組使用同步重置(Sync Reset),在 ASIC 設計中為了配合 DFT Scan Chain 與避免重置樹(Reset Tree)繞線擁塞,
    建議在 SpinalHDL 的 `ClockDomainConfig` 中全域指定為 `ASYNC`(非同步低電位有效重置 reset_n)。

+ 時脈閘控(Clock Gating):
    110nm 製程的靜態漏電流(Leakage)極低,主要功耗來自動態翻轉.
    在邏輯合成時務必開啟自動插入 `ICG(Integrated Clock Gating Cell)` 功能,讓 VexRiscv 在待機(`WFI` 指令)或閒置週期自動切斷管線暫存器時脈.

+ DFT 與 JTAG 腳位複用(Pin Muxing):
    若您的 110nm 晶片封裝接腳數受限(例如 QFN-24 或 TSSOP-20),可將 VexRiscv 的 JTAG 接腳與一般 GPIO 複用,
    透過晶片外部的 TEST_MODE 腳位切換`量產掃描測試(ATPG Scan)`、`JTAG 韌體除錯`與`正常功能模式`.

## 推薦配置規格總覽


| 設計參數          | 建議配置                             | 預估效益(PSMC 110nm)
| :-               | :-                                  | :-
| 指令集與管線       | RV32EC / 3-Stage Pipeline          | 兼顧極小核心面積與高程式碼密度(省 Flash/SRAM)。
| 快取與分支預測     | No Cache / Static Prediction        | 消除 Tag RAM 開銷,記憶體存取延遲固定為 1 週期。
| 暫存器堆 (RegFile) |   Standard Cell Flip-Flops (16x32b) |  省去小型 Multi-port SRAM 的周邊面積與繞線複雜度。
| 預估邏輯閘數       | 約 16,000 ~ 22,000 Gates            | 面積約 0.10 mm² 左右,極適合嵌入混合訊號或 PMIC 晶片。
| 目標運作時脈       | 50 MHz ~ 80 MHz                     | 110nm 製程下 Setup/Hold Time 極易收斂,無需複雜時序優化。


# 專案背景與目前進度交接文件(VexRiscv ASIC 導入)

## 1. 專案目標與基礎規格
+ **目標製程**: PSMC(力積電)110nm 製程。
+ **核心應用**: 極小面積的裸機(Bare-metal)控制系統(取代傳統 8051 或商業 MCU 核心,適合嵌入混合訊號、PMIC 或專用控制晶片)。
+ **核心處理器**: VexRiscv(基於 SpinalHDL 產生標準 Verilog RTL)。
+ **預估效能與面積指標**:
    - 邏輯閘數: 約 `16,000 ~ 22,000 Gate Counts(NAND2 等效閘數)`。
    - 核心面積: 約 `0.08 ~ 0.15 mm²`。
    - 目標主頻: `50 MHz ~ 80 MHz`。

## 2. 已確立的 VexRiscv 微架構配置方向
+ **指令集與管線**: 採用 `RV32EC`(16 個通用暫存器 + 壓縮指令集以節省片上 ROM/Flash 空間)搭配 2 級或 3 級精簡管線。
+ **記憶體架構(無快取)**: 移除 `I$` 與 `D$`,採用無快取(Cacheless)的 Simple Bus 哈佛架構,直接對接單週期存取的片上 Tightly-Coupled Memory(TCM),分支預測設為 `Prediction.NONE`。
+ **算術與 CSR 精簡**: 移除單週期乘除法器(若需乘除則改用軟體模擬或極小面積迭代式設計); CSR 採用 `CsrPluginConfig.smallest` 僅保留基礎 Machine Mode 中斷處理。
+ **除錯介面(JTAG)**: 放棄 FPGA 專用的內部通道(如 `BSCANE2`),改用標準實體 4 線 JTAG(TCK, TMS, TDI, TDO,`withTap = true`)搭配 `DebugPlugin`,並規劃與 GPIO 進行腳位複用(Pin Muxing)以配合 DFT 測試模式。

## 3. PSMC 110nm 實體設計(Backend)策略
+ **暫存器堆(RegFile)**: 針對 `RV32E` 的 `16x32-bits` 暫存器,直接以 `Standard Cell Flip-Flops` 合成,避免呼叫小容量 2R1W SRAM Macro 造成周邊電路面積浪費。
+ **片上記憶體(SRAM / ROM)**: 使用 PSMC 110nm Memory Compiler 產生的高密度單埠(1RW)SRAM Macro 分別作為指令與資料記憶體。
+ **重置與低功耗(DFT / Clock Gating)**:
    - 全域強制設定為非同步低電位有效重置(`ASYNC` Reset),以利邏輯合成階段插入 DFT Scan Chain。
    - 合成時啟用自動插入 `ICG(Integrated Clock Gating Cell)`,配合 RISC-V `WFI` 指令降低動態功耗。

## 4. 目前對話階段與下一步需求
+ **當前 Stage**: 已完成架構選型與 PSMC 110nm 設計規範收斂。
+ **待推進任務**: 準備撰寫對應的 SpinalHDL(Scala)配置檔以產生目標 Verilog、確定片上 ROM/SRAM 容量與匯流排介面(SimpleBus / APB / Wishbone),以及進行後續邏輯合成與驗證。

---
**【給 Gemini 的指令】**: 請基于以上已定案的規格與階段,直接協助我進行後續的 RTL 產生、周邊匯流排整合或合成腳本設計,無需再重複介紹基礎概念。
