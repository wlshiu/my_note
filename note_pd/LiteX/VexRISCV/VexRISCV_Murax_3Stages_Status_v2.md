📌 VexRiscv Murax SoC 開發進度與環境交接文件 (v2.0 - RV32IMC + eFlash XIP)

# 1. 專案目標與目前狀態

+ **開發目標**: 在 VexRiscv 專案上,將原生的 5 階管線 Murax SoC 精簡為 **3 階管線(Fetch + Decode + Execute)**,
    支援 **RV32IMC** 指令集擴充,配置 **32KB Embedded Flash(eFlash, XIP 執行)** 與 **2KB On-chip SRAM**,
    同時完整保留 JTAG 除錯(含 4 組硬體斷點)、CSR 中斷控制與 UART / Timer 外部中斷。

+ **目前完成進度(皆已驗證通過)**:
  1. ✅ **3 階管線 + RV32IMC 硬體架構**:
    已完成修改 `Murax.scala`,關閉 Memory 與 WriteBack 階段,啟用 RVC(16-bit 壓縮指令)與 RVM(`MulSimplePlugin` + `DivPlugin`),
    保留 `RegFilePlugin(plugin.SYNC)`。

  2. ✅ **雙記憶體架構與 XIP 啟動**:
    新增唯讀 `MuraxEmbeddedFlash`(32KB,Base `0x00000000`,由 FPGA Block RAM 模擬),將 `resetVector` 設為 `0x00000000`、`mtvecInit` 設為 `0x00000020`;
    保留 2KB On-chip SRAM(Base `0x20000000`)存放 `.data`、`.bss` 與 Stack。

  3. ✅ **軟體啟動碼與連結腳本**:
    完成配套的 `linker.ld` 與 `crt.S`(開機自動將 `.data` 從 Flash LMA 搬移至 SRAM VMA,並清零 `.bss`),
    以 `-march=rv32imc_zicsr -mabi=ilp32` 編譯通過。

  4. ✅ **Verilator 行為模擬**:
    解決 SpinalHDL 1.13.0 `$urandom` 與舊版 Verilator 相容性,啟動 `./obj_dir/VMurax` 驗證 eFlash XIP 開機(`BOOT` 輸出正常)。

  5. ✅ **OpenOCD / GDB eFlash 單步除錯**:
    開啟 `hardwareBreakpointCount = 4`(輸出至 `cpu0.yaml`),
    透過 OpenOCD + `riscv32-unknown-elf-gdb` 驗證 `hbreak` 與 16-bit 壓縮指令(2-byte 對齊位址)單步執行正常。

---

# 2. 系統記憶體映射(Memory Map)

| 區塊名稱              | 起始位址 (Base Address) | 容量 | 屬性 / 用途說明 |
| :---                  | :---                  | :--- | :--- |
| **eFlash**            | `0x00000000`          | 32 KB | 唯讀 Block RAM 模擬; 存放 `.init` (`0x0`)、`.trap` (`0x20`)、`.text`、`.rodata` 與 `.data` 初始值(XIP 直接執行) |
| **On-chip SRAM**      | `0x20000000`          | 2 KB | 讀寫 RAM; 存放執行期 `.data`、`.bss`,Stack Top 位於 `0x20000800` |
| **APB Peripherals**   | `0xF0000000`          | 1 MB | GPIO (`0x00000`)、UART (`0x10000`)、Timer (`0x20000`) |

---

# 3. 關鍵硬體修改摘要(src/main/scala/vexriscv/demo/Murax.scala)

1. **匯入與設定**:
    匯入 `spinal.lib.misc.HexTools`;
    `MuraxConfig` 新增 `eFlashSize = 32 kB`、`eFlashHexFile`、`onChipRamSize = 2 kB`、`hardwareBreakpointCount = 4`(`coreFrequency` 預設 `12 MHz`)。
2. **CPU Plugins 與管線設定**:
    - `IBusSimplePlugin`: `resetVector = 0x00000000l`、`compressedGen = true`(支援 RVC 16-bit 指令)。
    - `CsrPlugin`: `mtvecInit = 0x00000020l`、`pipelineCsrRead = false`、`deterministicInteruptionEntry = true`。
    - **RVM 支援(關鍵避坑)**: 因無 Memory 階段,必須使用 **`new MulSimplePlugin`** 搭配 `new DivPlugin`(不可用 5 階專用的 `MulPlugin`)。
    - `BranchPlugin`: `earlyBranch = true`。
    - `VexRiscvConfig`: `withMemoryStage = false`、`withWriteBackStage = false`。
    - *(註: 此 VexRiscv 分支未支援 RV32E `withRve` 參數,因此採用完整的 RV32IMC 32 暫存器架構。)*
3. **eFlash 控制器(`MuraxEmbeddedFlash`)**:
    - 掛載於 `mainBusMapping -> (0x00000000l, eFlashSize)`,透過 `Mem(Bits(32 bits), eFlashSize / 4)` 與 `readSync` 推導為單週期讀取的 Block RAM。
4. **Verilog 產生進入點(`MuraxWithRamInit`)**:
    - 設定 `eFlashSize = 32 kB, eFlashHexFile = "src/main/ressource/hex/my_hello.hex", onChipRamSize = 2 kB`。

---

# 4. 軟體與模擬環境配置(避坑備忘)

## A. 開發環境與檔案路徑
+ **專案根目錄**: `/home/padauk/Working/vexriscv/VexRiscv`(注意: 不可在根目錄或 `src/main/scala/` 留存多餘 `.scala` 備份檔,否則 `sbt` 會報重複定義錯誤)。
+ **C 語言測試專案**: `src/main/c/murax/my_hello/`
    - `src/linker.ld`: `FLASH` (`0x00000000`, 32K)、`RAM` (`0x20000000`, 2K)、`ENTRY(_start)`、`.trap` 對齊 `0x20`。
    - `src/crt.S`: 關閉中斷 -> 設定 `sp = 0x20000800` -> 複製 `.data` (`_data_lma` -> `_data_vma_start`) -> 清零 `.bss` -> 設定 `mtvec = trap_entry` -> 呼叫 `main()`(中斷向量呼叫弱符號 `irqCallback`)。
    - `makefile`: 編譯與連結參數需使用 **`-march=rv32imc_zicsr -mabi=ilp32`**。

## B. 編譯 Verilog 與啟動 Verilator 模擬

```bash
# 1. 在專案根目錄產生 Murax.v、cpu0.yaml 與 eFlash 初始化檔
sbt "runMain vexriscv.demo.MuraxWithRamInit"
sed -i 's/\$urandom/\$random/g' Murax.v

# 2. 編譯並執行 Verilator 模擬器(開啟 JTAG TCP port 7894 與 UART 終端)
cd src/test/cpp/murax
make clean run
```

+ **免重編更新韌體**: 修改 `update_ram.py` 對應輸出檔名為 `Murax.v_toplevel_system_eFlash_flash_symbol0~3.bin`(各 8192 行,對應 32KB),執行 `python3 update_ram.py <path_to_bin>` 後直接執行 `./obj_dir/VMurax`(不可執行 `make clean run` 以免覆蓋 `.bin`)。

## C. OpenOCD 與 GDB eFlash 除錯設定
+ **`murax.cfg`**: `-irlen 4`、`-expected-id 0x10001fff`、`vexriscv cpuConfigFile cpu0.yaml`、`vexriscv jtagMapping 2 3 0 0 0 0`。
+ **GDB 連線指令**:
  ```bash
  openocd -f ./murax.cfg
  # 另開終端機:
  riscv32-unknown-elf-gdb src/main/c/murax/my_hello/build/hello_world.elf
  # GDB 內執行: target remote localhost:3333 -> monitor reset halt -> hbreak main -> continue
  ```
  *(因 eFlash 為唯讀記憶體,設定斷點必須使用 `hbreak`,最多 4 組; RVC 2-byte 對齊指令已驗證可正常 `stepi`。)*

---

# 5. 下一步待辦事項(Next Steps)

1. **完整周邊與中斷韌體驗證**:
   - 在 `my_hello/src/main.c` 中驗證全域變數(`.data` 初值搬移與 `.bss` 清零)、硬體乘除法(RVM)、Timer 定時中斷與 UART 接收中斷(透過 `irqCallback` 處理)。
2. **FPGA 綜合與資源 / 時脈評估**:
   - 針對目標 FPGA 型號建立 Top Wrapper 與 Clock / Reset 約束(XDC / SDC),將 `Murax.v` 進行綜合與佈局繞線,評估 3 階管線 + RV32IMC + 32KB eFlash + 2KB SRAM 的 LUT / FF / BRAM 資源佔用與最高工作頻率(Fmax)。
