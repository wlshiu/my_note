VexRISCV_SoC
----

[VexRISCV](https://github.com/SpinalHDL/VexRiscv/tree/master#briey-soc) ASIC 案例
+ [Murax ](https://github.com/SpinalHDL/VexRiscv/tree/master#murax-soc)
    > Murax SoC 是一個極其輕量級、以 SpinalHDL 撰寫的開源 RISC-V SoC設計。
    它以 VexRiscv 處理器核心為基礎, 專門設計用來塞入像 Lattice iCE40 這樣資源極省的小型 FPGA 中

    - Spec

        1. VexRiscv RV32I(M)
            > + 預設 `5-staages pipeline`
            > + Profile `Smallest` 則為 `2-stages pipeline`

        1. 內建 JTAG 偵錯器, 相容於 GDB 與 OpenOCD
        1. SRAM: `8 KBytes`, XIP with SPI-Flash (No Embedded Flash)
        1. 簡單的 System-Bus 和 APB3
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


# Customization (Use 3-stages pipeline base on default `Murax`)

`2-stages pipeline` 需要做非同步處理,造成需要較高電路實現,因此改為 `3-stages pipeline`

Toolchain: [riscv-collab/riscv-gnu-toolchain: riscv32-elf-2022.11.16 · GitHub](https://github.com/riscv-collab/riscv-gnu-toolchain/releases/tag/2022.11.16)

## diff (from Gemini)

[GitHub - SpinalHDL/VexRiscv · GitHub](https://github.com/SpinalHDL/VexRiscv/tree/master#murax-soc)
> base on SHA ID `baf7dc8`

+ Base on `src/main/scala/vexriscv/demo/Murax.scala`
    > [Murax_3Stages Diff file](Murax_3Stages.diff)

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
            與 `timerInterrupt setWhen(timer.io.interrupt)`, 因此不需要額外改動即可直接支援 UART 與 Timer 中斷。


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
    # 關鍵修正 1：Murax.v 的 jtag_tap_instruction 是 4-bit，必須設為 -irlen 4
    jtag newtap $_CHIPNAME cpu -irlen 4 -expected-id 0x10001fff

    set _TARGETNAME $_CHIPNAME.cpu
    target create $_TARGETNAME vexriscv -endian little -chain-position $_TARGETNAME

    # 關鍵修正 2：對應 JtagBridge (IR_WRITE=2, IR_READ=3, DR_WRITE_OFFSET=0, DR_READ_OFFSET=0, DR_WRITE_LEN=0, DR_READ_LEN=0)
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

$ riscv32-unknown-elf-gdb -tui ./build/hello_world.elf -ex "target remote localhost:3333" -ex "monitor reset halt"
GNU gdb (GDB) 12.1
...

(gdb) load  # run-time load the target elf to DUT
(gdb) si    # execte the 1st instruction (start at 'crtStart')
```

# Reference

+ [GitHub - SpinalHDL/VexRiscv: A FPGA friendly 32 bit RISC-V CPU implementation · GitHub](https://github.com/SpinalHDL/VexRiscv/tree/master#murax-soc)
+ [在iCESugar上运行MuraxSoC](https://www.muselab-tech.com/zai-icesugarshang-yun-xing-muraxsoc/)


