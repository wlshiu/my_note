VexRISCV_SoC
----

[VexRISCV](https://github.com/SpinalHDL/VexRiscv/tree/master#briey-soc) ASIC 案例
+ [Murax ](https://github.com/SpinalHDL/VexRiscv/tree/master#murax-soc)
    > Murax SoC 是一個極其輕量級、以 SpinalHDL 撰寫的開源 RISC-V SoC設計.
    它以 VexRiscv 處理器核心為基礎, 專門設計用來塞入像 Lattice iCE40 這樣資源極省的小型 FPGA 中
    >> license: `Apache 2.0`

    - Spec

        1. VexRiscv RV32I(M)
            > + 預設 `5-staages pipeline`
            > + Profile `Smallest` 則為 `2-stages pipeline`

        1. 內建 JTAG 偵錯器, 相容於 GDB 與 OpenOCD
        1. SRAM: `8 KBytes`, XIP with SPI-Flash (No Embedded Flash)
        1. 簡單的 System-Bus 和 APB3
        1. Interrupt (最多 32 個)
            > + Non-nested
            > + No Vector Table (所有 `interrupt` 和 `exception` 都進同一個 function)
            > + No Hardware Priority (由 Software 撰寫來決定)

        1. Peripheral
            > + APB 總線(APB bus for peripherals)
            > + 32 個 GPIO 引腳
            > + 一組 16-bit 預除器(prescaler)與兩組 16-bit 計時器(timers)
            > + 一組具備收發 FIFO 的 UAR

    - Performance
        > + Interlocked: 資料相依時, CPU等前一個 instruction 做完, 才會往下做
        > + Bypassed: 在 pipeline 各 stage 間建立 Bypass paths, 前一個 instruction 未做完時, 判定是否可以先做其他的 instruction (多 10~15% 邏輯單元)

        1. RV32I(Interlocked stages)
            > 約 `51 MHz`, 使用 2,387 個邏輯單元(LC), 效能約 `0.37 – 0.45 DMIPS/MHz`
        1. RV32I(Bypassed stages)
            > 約 `45 MHz`, 使用 2,718 個邏輯單元(LC), 效能約 `0.55 – 0.65 DMIPS/MHz`

    - 實際 ASIC 應用案例
        1. 開源 ASIC 生態與 Google SkyWater MPW 投片計畫
            > + Efabless Caravel 平台與 OpenLane 流程:
            Google 與 Efabless 推動的 `SkyWater 130nm` 開源製程計畫中,許多團隊採用 VexRiscv(或整合在 LiteX 下的 VexRiscv SoC)作為 Chip 的管理核心(Management Core)或運算核心,
            並直接透過開源 EDA 工具鏈(OpenLane / OpenROAD)完成從 RTL 到 GDSII 的實體設計與投片

            > + 微型晶片競賽與學術流片:
            在 `Tiny Tapeout` 等群眾募資的微型 ASIC 專案中,
            開發者經常利用 VexRiscv 精簡的插件機制(移除不必要的快取與浮點單元,將邏輯閘數壓縮至極低),
            在極小的矽晶面積內塞入完整的 32 位元 RISC-V 系統並完成實體晶片製造

        1. 安全控制與信任根(Root of Trust)協處理器
            > + 客製化安全指令與 PMP 隔離:
                VexRiscv 內建完整的`實體記憶體保護(PMP)`插件,且基於 SpinalHDL 的架構允許設計者在不更動主體管線的情況下,
                輕鬆插入自訂的加密加速指令(Custom Instructions)

            > + 商業化導入優勢:
                由於 VexRiscv 採用商業友善的開源授權,新創與晶片設計公司常將其作為大型 SoC 內部的`安全島(Security Island)`或管理子系統(Housekeeping MCU).
                這類應用不追求極致的時脈頻率,而是看重其面積小、驗證成熟,以及在 FPGA 模擬階段與 ASIC 量產階段能保持 100% 行為一致的特性

        1. 混合訊號(Mixed-Signal)與智慧感測器 ASIC
            > + 取代複雜狀態機:
                許多企業將極簡配置的 VexRiscv(例如 2 or 3 級管線、無快取配置)直接整合進類比混合訊號 ASIC 中,
                利用 C 語言韌體取代繁瑣的硬體狀態機控制邏輯

            > + FPGA 到 ASIC 的無痛轉移:
                開發團隊通常先在平價 FPGA 上運行 Efinix Sapphire 或 LiteX 的 VexRiscv SoC 進行感測器演算法驗證;
                待系統穩定後,直接將 SpinalHDL 產生的標準 Verilog,
                匯入 Synopsys Design Compiler 或 Cadence Genus 進行標準元件庫(Standard Cell)邏輯合成與 ASIC 投片

        1. AI 加速器與邊緣運算晶片的控制核心
            > + 低成本硬體(DMA)排程:
                相比於全硬體排程器,在 AI ASIC 內部嵌入幾顆 VexRiscv 核心,僅佔用極微小的晶片面積(約數萬個邏輯閘),卻能賦予加速器極高的軟體靈活性;
                開發者可透過自訂 CSR 暫存器讓 VexRiscv 直接控制內部 SRAM 與運算陣列的資料流,大幅縮短 AI 晶片的軟體適配與上市時程


+ [Briey](https://github.com/SpinalHDL/VexRiscv/tree/master#briey-soc)
    > Briey SoC 定位為高效能應用型(配備 I/D Cache 與外部 SDRAM 介面)


    - Spec

        1. VexRiscv RV32IMZicsr(C,A,F,D, Custom)
            > `5-Stage Pipeline`

        1. 內建 JTAG 偵錯器, 相容於 GDB 與 OpenOCD
        1. SRAM: `4 KBytes`(bootloader), SDRAM, XIP with SPI-Flash (No Embedded Flash)
        1. 完整 AXI4 Bus 和 APB3
        1. Peripheral
            > + I$ (I-Cache) and D$ (D-Cache)
            > + GPIO x 2
            > + UART
            > + VGA


## Peripheral

### Apb3Gpio (Base: 0xF0000000)

| Offset |暫存器名稱      | Bit-Fields  | 讀寫權限  | 功能說明
| :-     | :-            | :-          | :-       | :-
| 0x00   | INPUT         | [31:0]      | R        | 讀取外部 GPIO 接腳的當前邏輯準位狀態(經過同步器採樣).
| 0x04   | OUTPUT        | [31:0]      | R/W      | 設定 GPIO 輸出資料(當對應位元的 OUTPUT_ENABLE 為 1 時輸出至接腳).
| 0x08   | OUTPUT_ENABLE | [31:0]      | R/W      | 三態緩衝器方向控制:<br> 1: 輸出模式(Output);<br> 0: 高阻抗輸入模式(Input / Hi-Z，預設值).

### Apb3UartCtrl  (Base: 0xF0010000)

| Offset  | 暫存器名稱     | Bit-Fields | 讀寫權限  | 功能說明
| :-     | :-            | :-          | :-       | :-
| 0x00    | DATA          | [7:0]      | R/W      |  寫入: 將 1 byte 資料推入 TX FIFO 等待傳送.<br> 讀取: 從 RX FIFO 彈出(Pop)1 byte 已接收的資料.
|         |               | [15:8]     | —        |  保留(讀取為 0).
|         |               | [16]       | R        |  RX Data Valid(部分 SpinalHDL 版本支援):<br> 1 表示讀取到的 [7:0] 為有效資料(通常建議直接讀取 STATUS[31:24] 判斷是否有資料).
| 0x04    | STATUS        | [0]        | R/W      |  TX Interrupt Enable:<br> 1: 當 TX FIFO 為空時觸發中斷;<br> 0: 關閉(預設 0).
|         |               | [1]        | R/W      |  RX Interrupt Enable:<br> 1: 當 RX FIFO 非空(有資料可讀)時觸發中斷;<br> 0: 關閉(預設 0).
|         |               | [7:2]      | —        |  保留.
|         |               | [8]        | R        |  TX Interrupt Pending:<br> 1: 目前 TX 中斷條件成立(TX FIFO 空且 [0]=1).
|         |               | [9]        | R        |  RX Interrupt Pending:<br> 1: 目前 RX 中斷條件成立(RX FIFO 非空且 [1]=1).
|         |               | [15:10]    | —        |  保留.
|         |               | [23:16]    | R        |  TX FIFO Write Availability: 目前 TX FIFO 還可寫入的剩餘空間(0: 已滿，16: 全空). 傳送前需確認此欄位 `> 0`.
|         |               | [31:24]    | R        |  RX FIFO Read Occupancy: 目前 RX FIFO 內待讀取的位元組數量(0: 無資料，16: 已滿). 讀取前需確認此欄位 `> 0`.
| 0x08    | CLOCK_DIVIDER | [19:0]     | R        |  鮑率除頻器數值, 計算公式: `(F_clk / (Baudrate * SamplingSize)) - 1`. 因 Murax 鎖定配置，軟體寫入無效.
| 0x0C    | FRAME_CONFIG  | [7:0]      | R        |  資料位元長度(7 代表 8 bits). 因 Murax 鎖定配置，軟體寫入無效.
|         |               | [15:8]     | R        |  同位檢查設定(0: NONE; 1: EVEN; 2: ODD;).
|         |               | [23:16]    | R        |  停止位元設定(0: 1 stop bit; 1: 2 stop bits;).


### MuraxApb3Timer (Base: 0xF0020000)

+ 預除頻器(Prescaler) TIMA/TIMB 共用

| Offset | 暫存器名稱       | Bit-Fields  | 讀寫權限    | 功能說明
| :-     | :-              | :-          | :-         | :-
| 0x00   | PRESCALER_LIMIT | [15:0]      | R/W 16-bit |  預除頻上限值.內部計數器從 `0` 數到 `LIMIT` 時產生一個 Tick 脈衝給 Timer-A/Timer-B (實際除頻倍率為 `LIMIT + 1`).
|        |                 | [31:16]     | —          |  保留.


+ 中斷狀態與遮罩(Interrupt Control)

| Offset | 暫存器名稱         | Bit-Fields | 讀寫權限  |  功能說明
| :-     | :-                | :-         | :-       | :-
| 0x30   | INTERRUPT_STATUS  | [0]        |  R/W1C   | Timer A 溢位中斷旗標:<br> 當 Timer A 達到 LIMIT 時硬體自動設為 1.<br> 寫入 1 清除此旗標(Write-1-to-Clear).
|        |                   | [1]        |  R/W1C   | Timer B 溢位中斷旗標:<br> 當 Timer B 達到 LIMIT 時硬體自動設為 1.<br> 寫入 1 清除此旗標(Write-1-to-Clear).
|        |                   | [31:2]     |  —       | 保留.
| 0x34   | INTERRUPT_MASK    | [0]        |  R/W     | Timer A 中斷致能:<br> 1: 允許 Timer A 產生 Interrupt 送往 CPU;<br> 0: 遮罩(關閉).
|        |                   | [1]        |  R/W     | Timer B 中斷致能:<br> 1: 允許 Timer B 產生 Interrupt 送往 CPU;<br> 0: 遮罩(關閉).
|        |                   | [31:2]     |  —       | 保留.


+ Timer-A /Timer-B

| Offset (A/B) | 暫存器名稱   | Bit-Fields | 讀寫權限   | 功能說明
| :-           | :-          | :-         | :-        | :-
| 0x10/0x20    | TIMER_LIMIT | [15:0]     | R/W       | 計時器溢位上限值(Auto-reload target).
|              |             | [31:16]    | —         | 保留.
| 0x14/0x24    | TIMER_VALUE | [15:0]     | R/W       | 讀取或直接設定計時器當前的 16-bit 計數值.
|              |             | [31:16]    | —         | 保留.
| 0x18/0x28    | TIMER_CTRL  | [0]        | R/W       | Clock Enable(計數致能):<br> 1: 跟隨 Prescaler Tick 向上計數;<br> 0: 停止計數.
|              |             | [1]        | R/W       | Clear on Limit(自動重載):<br> 1: 當 `VALUE == LIMIT` 時自動清零並繼續循環計數(週期定時模式);<br> 0: 達到上限後維持數值(單次模式).
|              |             | [15:2]     | —         | 保留.
|              |             | [16]       | R/W       | Timer A Tick Cascade(僅 Timer B 有效，部分版本支援):<br> 在標準 Murax 中，Timer A 與 B 皆使用 Prescaler Tick; 若需串接，通常由 Prescaler 統一控制.



# Customization (Use 3-stages pipeline base on default `Murax`)

`2-stages pipeline` 需要做非同步處理,造成需要較高電路實現,因此改為 `3-stages pipeline`

Toolchain: [riscv-collab/riscv-gnu-toolchain: riscv32-elf-2022.11.16 · GitHub](https://github.com/riscv-collab/riscv-gnu-toolchain/releases/tag/2022.11.16)

## diff (from Gemini)

[GitHub - SpinalHDL/VexRiscv · GitHub](https://github.com/SpinalHDL/VexRiscv/tree/master#murax-soc)
> base on SHA ID `baf7dc8`

+ Base on `src/main/scala/vexriscv/demo/Murax.scala`
    > [Murax_3Stages Diff file](VerRISCV/Murax_3Stages.diff)

    - 修改重點說明

        1. CsrPlugin(第 89–94 行)
            > 在原本的 `CsrPluginConfig.smallest(...)` 上透過 `.copy()` 關閉 `pipelineCsrRead`(避免 CSR 讀取往後延遲)
            並開啟 `deterministicInteruptionEntry = true`(確保中斷在 Execute 階段穩定觸發)

        1. BranchPlugin(第 113 行)
            > 將 `earlyBranch` 從 false 改為 true, 讓分支跳躍在 Execute 階段直接解析, 不需等待不存在的 Memory 階段

        1. VexRiscvConfig 與 DebugPlugin(第 234–239 行)
            > 增加設定 `withMemoryStage = false` 與 `withWriteBackStage = false` 來取消 Memory 與 WriteBack 2 管線


        1. 原生中斷接線保留
            > 原生版本在 APB 周邊區塊(第 273 行與第 277 行)已經包含 `externalInterrupt setWhen(uartCtrl.io.interrupt)`
            與 `timerInterrupt setWhen(timer.io.interrupt)`, 因此不需要額外改動即可直接支援 UART 與 Timer 中斷.


## 生成 RTL code

```
$ cd <VexRiscv_Root>
$ vi z_gen_rtl.sh
    #!/bin/bash

    sbt "runMain vexriscv.demo.MuraxWithRamInit"  # 生成 Murax.v
    sed -i 's/\$urandom/\$random/g' Murax.v

$ ./z_gen_rtl.sh
```

+ `$urandom` 錯誤: 舊版 Verilator 尚未支援無參數的 `$urandom`
    > 對已經產生的 `Murax.v` 裡的 `$urandom` 替換成舊版 Verilator 支援的 `$random`

    ```
    $ sed -i 's/\$urandom/\$random/g' Murax.v
    ```

## 啟動 Verilator 模擬環境

> 如果運作正常, 終端機會立刻將你輸入的字元 Echo 印出來

```
$ cd <VexRiscv_Root>/src/test/cpp/murax
$ make clean run    # 使用 <VexRiscv_Root>/src/main/ressource/hex/muraxDemo.hex
$ make clean run
    rm -rf obj_dir
    rm -f Murax.v*.bin
    rm -f Murax.v*.bin
    cp ../../../../Murax.v*.bin . | true
    verilator -I../../../.. -cc  ../../../../Murax.v -CFLAGS -pthread -LDFLAGS -pthread -CFLAGS "-O3" -CFLAGS -DTRACE_START=0 --gdbbt  -Wno-WIDTH -Wno-UNOPTFLAT --x-assign unique --exe main.cpp
    No stack.
    make  -j  -C obj_dir/ -f VMurax.mk VMurax
    make[1]: Entering directory '/home/padauk/Working/vexriscv/VexRiscv/src/test/cpp/murax/obj_dir'
    g++  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-sign-compare -Wno-uninitialized -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -Wno-shadow     -pthread -O3 -DTRACE_START=0  -Os -c -o main.o ../main.cpp
    g++  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-sign-compare -Wno-uninitialized -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -Wno-shadow     -pthread -O3 -DTRACE_START=0  -Os -c -o verilated.o /usr/share/verilator/include/verilated.cpp
    g++  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-sign-compare -Wno-uninitialized -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -Wno-shadow     -pthread -O3 -DTRACE_START=0  -Os -c -o verilated_dpi.o /usr/share/verilator/include/verilated_dpi.cpp
    /usr/bin/perl /usr/share/verilator/bin/verilator_includer -DVL_INCLUDE_OPT=include VMurax.cpp VMurax_Murax.cpp VMurax_VexRiscv.cpp VMurax__Dpi.cpp VMurax__Slow.cpp VMurax_Murax__Slow.cpp VMurax_VexRiscv__Slow.cpp VMurax__Syms.cpp > VMurax__ALL.cpp
    g++  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-sign-compare -Wno-uninitialized -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -Wno-shadow     -pthread -O3 -DTRACE_START=0  -Os -c -o VMurax__ALL.o VMurax__ALL.cpp
    ar -cr VMurax__ALL.a VMurax__ALL.o
    ranlib VMurax__ALL.a
    g++    main.o verilated.o verilated_dpi.o VMurax__ALL.a   -pthread    -o VMurax
    make[1]: Leaving directory '/home/padauk/Working/vexriscv/VexRiscv/src/test/cpp/murax/obj_dir'
    ./obj_dir/VMurax
    BOOT
    A
```

+ `BOOT` 字樣
    > 這是 `muraxDemo.hex` 韌體上電初始化後, 透過 UART 傳送出來的第一串開機訊息,
    代表 `3-stages pipeline`(Fetch + Decode + Execute)、SRAM 指令讀取以及 APB 與 UART 全都運作無誤

+ `A` 字元迴響
    > 這代表輸入的 `A` 成功透過 UART RX 接收, 觸發了硬體中斷(uartCtrl.io.interrupt -> externalInterrupt),
    並且 CPU 成功進入 CsrPlugin 的中斷服務常式(ISR), 再透過 UART TX 將字元印回終端機


### The target hex file of Verilator

+ Default target hex file (Verilator 自動 download)
    > 需要重新產生 RTL code

    ```
    $ vi src/main/scala/vexriscv/demo/Murax.scala
        ...
        // object MuraxWithRamInit{
        //   def main(args: Array[String]) {
        //     SpinalVerilog(Murax(MuraxConfig.default.copy(onChipRamSize = 4 kB, onChipRamHexFile = "src/main/ressource/hex/muraxDemo.hex
        //   }
        // }

        object MuraxWithRamInit{
          def main(args: Array[String]) {
            SpinalVerilog(Murax(MuraxConfig.default.copy(
              onChipRamSize = 8 kB,                                                     // 調整可執行的 SRAM 大小
              onChipRamHexFile = "src/main/c/murax/hello_world/build/hello_world.hex"   // 目標 hex 檔 (hard code)
            )))
          }
        }
    ```

+ Replay `toplevel_system_ram_ram_symbol.bin`
    > 不用重新生成 RTL code (sbt 會將 onChipRamHexFile 分割成 symbol files)

    - python script [z_update_ram.py](z_update_ram.py)

        ```
        $ cd <VexRiscv_Root>

        $ cd <VexRiscv_Root>/src/main/c/murax/hello_world/
        $ make clean && make
        $ riscv32-unknown-elf-objcopy -O binary ./build/hello_world.elf ./build/hello_world.bin
        $ z_update_ram.py -i <VexRiscv_Root>/src/main/c/murax/hello_world/build/hello_world.bin
        $ cp -f ./Murax.v_toplevel_system_ram_ram_symbol0.bin <VexRiscv_Root>/
        $ cp -f ./Murax.v_toplevel_system_ram_ram_symbol1.bin <VexRiscv_Root>/
        $ cp -f ./Murax.v_toplevel_system_ram_ram_symbol2.bin <VexRiscv_Root>/
        $ cp -f ./Murax.v_toplevel_system_ram_ram_symbol3.bin <VexRiscv_Root>/

        $ cd <VexRiscv_Root>/src/test/cpp/murax
        $ ./obj_dir/VMurax
        ```




## OpenOCD Server (for Verilator Simulation)

+ `murax.cfg` for OpenOCD

    ```
    adapter driver jtag_tcp
    adapter speed 1000

    set _CHIPNAME riscv
    # 關鍵修正 1: Murax.v 的 jtag_tap_instruction 是 4-bit,必須設為 -irlen 4
    jtag newtap $_CHIPNAME cpu -irlen 4 -expected-id 0x10001fff

    set _TARGETNAME $_CHIPNAME.cpu
    target create $_TARGETNAME vexriscv -endian little -chain-position $_TARGETNAME

    # 關鍵修正 2: 對應 JtagBridge (IR_WRITE=2, IR_READ=3, DR_WRITE_OFFSET=0, DR_READ_OFFSET=0, DR_WRITE_LEN=0, DR_READ_LEN=0)
    vexriscv jtagMapping 2 3 0 0 0 0
    vexriscv cpuConfigFile cpu0.yaml
    vexriscv readWaitCycles 40

    reset_config none
    init
    ```

+ Start OpenOCD server
    > 需使用 VexRISCV 特製的 OpenOCD 版本

    ```
    $ openocd -f murax.cfg
        Open On-Chip Debugger 0.11.0+dev-04036-ga0220ad30 (2026-11-11-17:21)
        Licensed under GNU GPL v2
        For bug reports, read
                http://openocd.org/doc/doxygen/bugs.html
        Info : only one transport option; autoselect 'jtag'
        Info : clock speed 1000 kHz
        Info : JTAG tap: riscv.cpu tap/device found: 0x10001fff (mfg: 0x7ff (<invalid>), part: 0x0001, ver: 0x1)
        Error: ERROR: Error while reading from socket: Socket operation on non-socket
        [riscv.cpu] Target successfully examined.
        Info : starting gdb server for riscv.cpu on 3333
        Info : Listening on port 3333 for gdb connections
        Info : Listening on port 6666 for tcl connections
        Info : Listening on port 4444 for telnet connections
        Info : accepting 'gdb' connection on tcp/3333
        Warn : Prefer GDB command "target extended-remote :3333" instead of "target remote :3333"
        Info : JTAG tap: riscv.cpu tap/device found: 0x10001fff (mfg: 0x7ff (<invalid>), part: 0x0001, ver: 0x1)
        Info : dropped 'gdb' connection
        Info : accepting 'gdb' connection on tcp/3333
        Info : JTAG tap: riscv.cpu tap/device found: 0x10001fff (mfg: 0x7ff (<invalid>), part: 0x0001, ver: 0x1)
        Info : JTAG tap: riscv.cpu tap/device found: 0x10001fff (mfg: 0x7ff (<invalid>), part: 0x0001, ver: 0x1)

    ```

## GDB client

因為程式執行在 SRAM, 因此可以動態再 `load` bin 到 SRAM 執行
> 若要用 `eFlash` 需要另外實作 `xip`, `program flash`, ...等

```
$ cd <VexRiscv_Root>/src/main/c/murax/hello_world
$ make clean && make

$ riscv32-unknown-elf-gdb -tui ./build/hello_world.elf -ex "target extended-remote :3333" -ex "monitor reset halt"
GNU gdb (GDB) 12.1
...

(gdb) load  # run-time load the target elf to DUT
(gdb) si    # execte the 1st instruction (start at 'crtStart')
```

# Customization (Use 3-stages pipeline base on default `Murax` + eFlash)

Memory mapping
> + eFlash: base= 0x0, 32KBytes
> + SRAM: base= 0x20000000, 2KBytes

Toolchain: [riscv-collab/riscv-gnu-toolchain: riscv32-elf-2022.11.16 · GitHub](https://github.com/riscv-collab/riscv-gnu-toolchain/releases/tag/2022.11.16)

## diff (from Gemini)

[GitHub - SpinalHDL/VexRiscv · GitHub](https://github.com/SpinalHDL/VexRiscv/tree/master#murax-soc)
> base on SHA ID `baf7dc8`

+ Base on `src/main/scala/vexriscv/demo/Murax.scala`
    > [Murax_3Stages_eFlash Diff file](VerRISCV/Murax_3Stages_eFlash.diff)

+ 編譯新 MMP 的 Application

    ```
    $ cd <VexRiscv_Root>/src/main/c/murax
    $ cp -fr ./hello_world ./my_hello
    $ cd my_hello
    $ vi src/crt.S      # modify
    $ vi src/linker.ld  # modify
    $ make clean && make

    # Default hex path of Verilator
    $ cp ./build/my_hello.hex  <VexRiscv_Root>/src/main/ressource/hex/

    ```

    - `crt.S`

        ```
        .global main
        .global irqCallback

        .section .init, "ax"
        .global _start
        _start:
          /* 關閉全域中斷 (MIE = 0) */
          csrci mstatus, 8

          /* 跳過 0x20 的中斷向量區段，前往初始化流程 */
          j _init_system

        /* 中斷向量入口 (對齊於 0x00000020) */
        .section .trap, "ax"
        .global trap_entry
        trap_entry:
          addi sp, sp, -64
          sw ra,   0(sp)
          sw t0,   4(sp)
          sw t1,   8(sp)
          sw t2,  12(sp)
          sw a0,  16(sp)
          sw a1,  20(sp)
          sw a2,  24(sp)
          sw a3,  28(sp)
          sw a4,  32(sp)
          sw a5,  36(sp)
          sw a6,  40(sp)
          sw a7,  44(sp)
          sw t3,  48(sp)
          sw t4,  52(sp)
          sw t5,  56(sp)
          sw t6,  60(sp)

          /* 呼叫 C 語言中斷處理函式 (若無定義則可改為弱符號或直接返回) */
          call irqCallback

          lw ra,   0(sp)
          lw t0,   4(sp)
          lw t1,   8(sp)
          lw t2,  12(sp)
          lw a0,  16(sp)
          lw a1,  20(sp)
          lw a2,  24(sp)
          lw a3,  28(sp)
          lw a4,  32(sp)
          lw a5,  36(sp)
          lw a6,  40(sp)
          lw a7,  44(sp)
          lw t3,  48(sp)
          lw t4,  52(sp)
          lw t5,  56(sp)
          lw t6,  60(sp)
          addi sp, sp, 64
          mret

        .section .text
        _init_system:
          /* 設定堆疊指標 (Stack Pointer = 0x80000800) */
          la sp, _stack_start

          /* 1. 將 .data 從 Flash (_data_lma) 搬移至 SRAM (_data_vma_start ~ _data_vma_end) */
          la a0, _data_lma
          la a1, _data_vma_start
          la a2, _data_vma_end
          bgeu a1, a2, _copy_data_done

        _copy_data_loop:
          lw t0, 0(a0)
          sw t0, 0(a1)
          addi a0, a0, 4
          addi a1, a1, 4
          bltu a1, a2, _copy_data_loop

        _copy_data_done:
          /* 2. 將 SRAM 中的 .bss 區段清零 (_bss_start ~ _bss_end) */
          la a0, _bss_start
          la a1, _bss_end
          bgeu a0, a1, _clear_bss_done

        _clear_bss_loop:
          sw zero, 0(a0)
          addi a0, a0, 4
          bltu a0, a1, _clear_bss_loop

        _clear_bss_done:
          /* 確保 mtvec 指向 trap_entry (0x00000020) */
          la t0, trap_entry
          csrw mtvec, t0

          /* 呼叫 C 語言主程式 */
          call main

        /* 若 main() 返回，進入無窮迴圈 */
        _exit_loop:
          j _exit_loop

        /* 提供預設的弱符號 irqCallback，避免未定義中斷函式時連結錯誤 */
        .weak irqCallback
        irqCallback:
          ret

        ```

    - `linker.ld`

        ```
        /*
        This is free and unencumbered software released into the public domain.

        Anyone is free to copy, modify, publish, use, compile, sell, or
        distribute this software, either in source code form or as a compiled
        binary, for any purpose, commercial or non-commercial, and by any
        means.
        */
        OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv")
        OUTPUT_ARCH(riscv)


        ENTRY(_start)

        MEMORY
        {
          FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 32K
          RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 2K
        }

        SECTIONS
        {
          /* 程式進入點與中斷向量表 (位於 0x00000000) */
          .text :
          {
            . = ALIGN(4);
            KEEP(*(.init))
            /* 確保中斷向量表對齊 0x00000020 (對應 CsrPlugin 的 mtvecInit) */
            . = 0x20;
            KEEP(*(.trap))
            *(.text .text.*)
            *(.rodata .rodata.*)
            *(.srodata .srodata.*)
            . = ALIGN(4);
          } > FLASH

          /* 記錄 .data 在 Flash 中的起始位置 (Load Memory Address) */
          _data_lma = LOADADDR(.data);

          /* 已初始化的全域/靜態變數 (執行時位於 SRAM, 初始值存於 Flash) */
          .data :
          {
            . = ALIGN(4);
            _data_vma_start = .;
            *(.data .data.*)
            *(.sdata .sdata.*)
            . = ALIGN(4);
            _data_vma_end = .;
          } > RAM AT > FLASH

          /* 未初始化變數區段 (位於 SRAM, 開機清零) */
          .bss (NOLOAD) :
          {
            . = ALIGN(4);
            _bss_start = .;
            *(.bss .bss.*)
            *(.sbss .sbss.*)
            *(COMMON)
            . = ALIGN(4);
            _bss_end = .;
          } > RAM

          /* 堆疊指標設在 2KB SRAM 的最頂端 (0x20000000 + 0x800) */
          PROVIDE(_stack_start = ORIGIN(RAM) + LENGTH(RAM));
        }
        ```


## 生成 RTL code

```
$ cd <VexRiscv_Root>
$ vi z_gen_rtl.sh
    #!/bin/bash

    sbt "runMain vexriscv.demo.MuraxWithRamInit"  # 生成 Murax.v
    sed -i 's/\$urandom/\$random/g' Murax.v

$ ./z_gen_rtl.sh
```

## 啟動 Verilator 模擬環境

```
[<VexRiscv_Root>/src/test/cpp/murax] (sha:baf7dc8)
$ make clean run
rm -rf obj_dir
rm -f Murax.v*.bin
rm -f Murax.v*.bin
cp ../../../../Murax.v*.bin . | true
verilator -I../../../.. -cc  ../../../../Murax.v -CFLAGS -pthread -LDFLAGS -pthread -CFLAGS "-O3" -CFLAGS -DTRACE_START=0 --gdbbt  -Wno-WIDTH -Wno-UNOPTFLAT --x-assign unique --exe main.cpp
No stack.
make  -j  -C obj_dir/ -f VMurax.mk VMurax
make[1]: Entering directory '/home/padauk/Working/vexriscv/VexRiscv/src/test/cpp/murax/obj_dir'
g++  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-sign-compare -Wno-uninitialized -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -Wno-shadow     -pthread -O3 -DTRACE_START=0  -Os -c -o main.o ../main.cpp
g++  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-sign-compare -Wno-uninitialized -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -Wno-shadow     -pthread -O3 -DTRACE_START=0  -Os -c -o verilated.o /usr/share/verilator/include/verilated.cpp
g++  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-sign-compare -Wno-uninitialized -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -Wno-shadow     -pthread -O3 -DTRACE_START=0  -Os -c -o verilated_dpi.o /usr/share/verilator/include/verilated_dpi.cpp
/usr/bin/perl /usr/share/verilator/bin/verilator_includer -DVL_INCLUDE_OPT=include VMurax.cpp VMurax_Murax.cpp VMurax_VexRiscv.cpp VMurax__Dpi.cpp VMurax__Slow.cpp VMurax_Murax__Slow.cpp VMurax_VexRiscv__Slow.cpp VMurax__Syms.cpp > VMurax__ALL.cpp
g++  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-sign-compare -Wno-uninitialized -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -Wno-shadow     -pthread -O3 -DTRACE_START=0  -Os -c -o VMurax__ALL.o VMurax__ALL.cpp
ar -cr VMurax__ALL.a VMurax__ALL.o
ranlib VMurax__ALL.a
g++    main.o verilated.o verilated_dpi.o VMurax__ALL.a   -pthread    -o VMurax
make[1]: Leaving directory '/home/padauk/Working/vexriscv/VexRiscv/src/test/cpp/murax/obj_dir'
./obj_dir/VMurax
BOOT
hello world arty a7 v1

```
## OpenOCD Server (for Verilator Simulation)

+ `murax.cfg` for OpenOCD

    ```
    adapter driver jtag_tcp
    adapter speed 1000

    set _CHIPNAME riscv
    # 關鍵修正 1: Murax.v 的 jtag_tap_instruction 是 4-bit,必須設為 -irlen 4
    jtag newtap $_CHIPNAME cpu -irlen 4 -expected-id 0x10001fff

    set _TARGETNAME $_CHIPNAME.cpu
    target create $_TARGETNAME vexriscv -endian little -chain-position $_TARGETNAME

    # 關鍵修正 2: 對應 JtagBridge (IR_WRITE=2, IR_READ=3, DR_WRITE_OFFSET=0, DR_READ_OFFSET=0, DR_WRITE_LEN=0, DR_READ_LEN=0)
    vexriscv jtagMapping 2 3 0 0 0 0
    vexriscv cpuConfigFile cpu0.yaml
    vexriscv readWaitCycles 40

    reset_config none
    init
    ```

+ Start OpenOCD server
    > 需使用 VexRISCV 特製的 OpenOCD 版本

    ```
    $ openocd -f ./murax.cfg
        Open On-Chip Debugger 0.11.0+dev-04036-ga0220ad30 (2026-11-11-17:21)
        Licensed under GNU GPL v2
        For bug reports, read
                http://openocd.org/doc/doxygen/bugs.html
        Info : only one transport option; autoselect 'jtag'
        Info : clock speed 1000 kHz
        Info : JTAG tap: riscv.cpu tap/device found: 0x10001fff (mfg: 0x7ff (<invalid>), part: 0x0001, ver: 0x1)
        Error: ERROR: Error while reading from socket: Socket operation on non-socket
        [riscv.cpu] Target successfully examined.
        Info : starting gdb server for riscv.cpu on 3333
        Info : Listening on port 3333 for gdb connections
        Info : Listening on port 6666 for tcl connections
        Info : Listening on port 4444 for telnet connections
        Info : accepting 'gdb' connection on tcp/3333
        Warn : Prefer GDB command "target extended-remote :3333" instead of "target remote :3333"
        Info : JTAG tap: riscv.cpu tap/device found: 0x10001fff (mfg: 0x7ff (<invalid>), part: 0x0001, ver: 0x1)
        Info : JTAG tap: riscv.cpu tap/device found: 0x10001fff (mfg: 0x7ff (<invalid>), part: 0x0001, ver: 0x1)
    ```


## GDB client

```
$ cd <VexRiscv_Root>/src/main/c/murax/my_hello
$ make clean && make

$ riscv32-unknown-elf-gdb -tui ./build/my_hello.elf -ex "target extended-remote :3333"
GNU gdb (GDB) 12.1
...

(gdb) monitor reset halt    # reset DUT
(gdb) si                    # execte the 1st instruction (start at 'crtStart')
(gdb) hbreak main
(gdb) c
```


# Customization (Use 3-stages pipeline base on default `Murax` + eFlash + RV32IMC)

Memory mapping
> + eFlash: base= 0x0, 32KBytes
> + SRAM: base= 0x20000000, 2KBytes

Toolchain: [riscv-collab/riscv-gnu-toolchain: riscv32-elf-2022.11.16 · GitHub](https://github.com/riscv-collab/riscv-gnu-toolchain/releases/tag/2022.11.16)


+ System-Arch

    ![sys_arch](VerRISCV/VexRISCV_SysArch.png)


## diff (from Gemini)

[GitHub - SpinalHDL/VexRiscv · GitHub](https://github.com/SpinalHDL/VexRiscv/tree/master#murax-soc)
> base on SHA ID `baf7dc8`

+ Base on `src/main/scala/vexriscv/demo/Murax.scala`
    > [Murax_3Stages_rv32imc_eFlash Diff file](VerRISCV/Murax_3Stages_rv32imc_eFlash.diff)


## Application configuration

+ 編譯新 MMP 的 Application

    ```
    $ cd <VexRiscv_Root>/src/main/c/murax
    $ cp -fr ./hello_world ./my_hello
    $ cd my_hello
    $ vi src/crt.S      # modify
    $ vi src/linker.ld  # modify
    $ vi makeile
        ...
        #
        # RISC-V Extension 修改為 'rv32imc',
        # 有些較新的 GCC 會要求加上 'rv32imc_zicsr'
        #
        CFLAGS += -march=rv32imc -mabi=ilp32
        LDFLAGS += -march=rv32imc -mabi=ilp32
        ...

    $ make clean && make

    # Default hex path of Verilator
    $ cp ./build/my_hello.hex  <VexRiscv_Root>/src/main/ressource/hex/
    ```




# Reference

+ [GitHub - SpinalHDL/VexRiscv: A FPGA friendly 32 bit RISC-V CPU implementation · GitHub](https://github.com/SpinalHDL/VexRiscv/tree/master#murax-soc)
+ [在iCESugar上运行MuraxSoC](https://www.muselab-tech.com/zai-icesugarshang-yun-xing-muraxsoc/)


