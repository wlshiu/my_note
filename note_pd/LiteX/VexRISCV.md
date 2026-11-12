VexRISCV [[Back](./note_LiteX.md#CPU-VexRISCV)]
---

[GitHub - SpinalHDL/VexRiscv: A FPGA friendly 32 bit RISC-V CPU implementation · GitHub](https://github.com/SpinalHDL/VexRiscv)

# 建立測試程式


```
$ export LITEX_ENV_CC_TRIPLE=riscv-none-elf

# 1. 建立 VexRISCV 模擬專案結構(先產生軟體標頭檔與 BIOS)
$ litex_sim --cpu-type=vexriscv --integrated-main-ram-size=0x10000 --no-compile-gateware

#
# 2. 產生 bare-metal demo project (./demo/) 並將輸出指向 build/sim
#    ps. 若已經有 demo, 則會 compile demo
$ litex_bare_metal_demo --build-path=build/sim

# 3. 進入 demo 資料夾編譯(請確保 main.c 已替換為 UART Echo 程式碼)
$ cd demo
make
cd ..
```

+ `SOC_DIRECTORY` 定義
    > `$LITEX_SRCROOT/litex/litex/soc/software/common.mak`

    ```
    SOC_DIRECTORY=$(LITEX_SRCROOT)/../litex/litex/soc

    include $(BUILD_DIR)/software/include/generated/variables.mak
    include $(SOC_DIRECTORY)/software/common.mak
    ```


# 使用 Verilator RTL 模擬


```
$ litex_sim --cpu-type=vexriscv --integrated-main-ram-size=0x10000 --ram-init=demo/demo.bin
```

+ log message

    ```
    [clocker] sys_clk: freq_hz=1000000, phase_deg=0

            __   _ __      _  __
           / /  (_) /____ | |/_/
          / /__/ / __/ -_)>  <
         /____/_/\__/\__/_/|_|
       Build your hardware, easily!

     (c) Copyright 2012-2026 Enjoy-Digital
     (c) Copyright 2007-2015 M-Labs

     BIOS built on Nov 11 2026 14:32:16
     BIOS CRC passed (7e529090)

     LiteX git sha1: be9ae2643

    --================ SoC =================--
    CPU:            VexRiscv @ 1MHz
    BUS:            wishbone 32-bit data/32-bit addr
    CSR:            32-bit data big ordering
    ROM:            128.0KiB
    SRAM:           8.0KiB
    MAIN RAM:       64.0KiB

    --=========== Initialization ===========--
    --================ Boot ================--
    Booting from serial...
    Press Q or ESC to abort boot completely.
    sL5DdSMmkekro
    Timeout
    Executing booted program at 0x40000000

    --============== Liftoff! ==============--

    LiteX minimal demo app built Nov 11 2026 14:31:26

    Available commands:
    help               - Show this command
    reboot             - Reboot CPU
    donut              - Spinning Donut demo
    helloc             - Hello C
    litex-demo-app>

    ```


## VexRiscv with jTag

VexRiscv 原生未帶 Debug-Module (當時 RISC-V DM 規範尚未定案),
因此透過 `DebugPlugin` 與 `JtagBridg`, 將其`SystemDebugBus`橋接至實體 jTag 腳位
> 需使用[特製的 OpenOCD 版本](https://github.com/SpinalHDL/openocd_riscv)

+ Hardware Debug 架構運作原理
    > 在 VexRiscv 的除錯體系中, Debug 訊號會經過以下層級轉換:
    > + `DebugPlugin` 直接嵌入 `VexRiscv Pipeline` 內部, 負責控制 CPU 的暫停(Halt)、恢復(Resume)、硬體斷點(hardware breakpoint)以及指令注入, 並對外暴露 `SystemDebugBus`
    > + `SystemDebugger` 將內部 `SystemDebugBus`, 轉換為輕量化的序列化匯流排 `SystemDebugRemoteBus`
    > + `JtagBridge` 提供標準 4 線式 JTAG TAP(TCK, TMS, TDI, TDO) 與除錯掃描暫存器, 將外部 JTAG 探棒的指令轉譯並傳送給 `SystemDebugger`

    ```
        +-------------- VexRiscv ----------------+
        |   +-------------- uCORE -----------+   |
        |   |    Pipeline                    |   |
        |   |   +---|----------+             |   |
        |   |   |  DebugPlugIn |             |   |
        |   |   +-+------------+             |   |
        |   |     |                          |   |
        |   |  ===+== SystemDebugBus ===+==  |   |
        |   +---------------------------|----+   |
        |                               |        |
        |                   +-----------+-----+  |
        |                   |  SystemDebugger |  |
        |                   +-------------+---+  |
        |                                 |      |
        |   ===== SystemDebugRemoteBus ===+====  |
        |                                 |      |
        +---------------------------------|------+
                                          |
                                    +-----+------+
                                    | JtagBridge +---- 4-wires PINs
                                    +------------+

    ```

+ Build OpenOCD

    ```
    # 忽略 git2cl fail
    $ git clone --recurse-submodules https://github.com/SpinalHDL/openocd_riscv.git

    $ cd openocd_riscv && ./bootstrap
    $ ./configure --prefix=/home/openocd_vex/ --enable-remote-bitbang --enable-ftdi --enable-jlink --enable-dummy
    $ make && make install
    ```

    - 建立 VerRISCV 專用的設定檔`vexriscv_jlink.cfg` 經由 jLink

        ```
        ## 未驗證

        # 1. 指定使用 J-Link 驅動並強制選擇 JTAG 介面
        adapter driver jlink
        transport select jtag

        # 初始連線速度設為 1000 kHz (1 MHz), 確保杜邦線連線穩定
        adapter speed 1000

        # 2. 定義 VexRiscv JtagBridge TAP (ID 固定為 0x10001fff, IR 長度為 4)
        set _CHIPNAME vexriscv
        jtag newtap $_CHIPNAME cpu -irlen 4 -ircapture 0x1 -irmask 0xf -expected-id 0x10001fff

        # 3. 建立 VexRiscv 除錯目標並載入生成的 yaml 設定檔
        set _TARGETNAME $_CHIPNAME.cpu
        target create $_TARGETNAME vexriscv -endian little -chain-position $_TARGETNAME
        vexriscv readWaitCycles 12
        vexriscv cpuConfigFile VexRiscv_CustomJtag.yaml

        init
        halt
        ```

+ 確認 VexRISCV source code 路徑
    > 利用 python 自行回報

    ```
    $ python3 -c "import pythondata_cpu_vexriscv; print(pythondata_cpu_vexriscv.data_location)"
    /home/xxx/litex/pythondata-cpu-vexriscv/pythondata_cpu_vexriscv/verilog
    ```

    - 確認 `pythondata-cpu-vexriscv` Code 的完整性
        > `SHA-ID:642ecfed1c` of `pythondata-cpu-vexriscv`

        ```
        $ git clean -fxd
        $ git reset --hard
        $ git submodule update --init --recursive

        $ cd pythondata-cpu-vexriscv/pythondata_cpu_vexriscv/verilog/ext/VexRiscv
        $ sbt publishLocal      # 確認版本並重新發布
        ```

+ 修改 VexRISCV, 來產生 standard branch version

    - standard version 沒有 jTage 功能
        > VexRISCV 中的 `*+debug` branch 是藉由 Wishbone Bus 輸出, 而非 `jTag` 實體腳位

        ```
        [~/litex/pythondata-cpu-vexriscv/pythondata_cpu_vexriscv/verilog/]
        $ diff ./src/main/scala/vexriscv/GenCoreDefault.scala ./src/main/scala/vexriscv/GenCoreDefault.scala.org
        --- ./src/main/scala/vexriscv/GenCoreDefault.scala      2026-11-12 13:04:07.661216721 +0800
        +++ ./src/main/scala/vexriscv/GenCoreDefault.scala.org  2026-11-12 11:32:53.086740847 +0800
        @@ -3,8 +3,6 @@
         import spinal.core._
         import spinal.core.internals.{ExpressionContainer, PhaseAllocateNames, PhaseContext}
         import spinal.lib._
        +import spinal.lib.com.jtag._
        +import spinal.lib.com.jtag.Jtag
         import spinal.lib.sim.Phase
         import vexriscv.ip.{DataCacheConfig, InstructionCacheConfig}
         import vexriscv.plugin.CsrAccess.WRITE_ONLY
        @@ -24,7 +22,6 @@

         case class ArgConfig(
           debug : Boolean = false,
        +  jtagBridge : Boolean = false,
           hardwareBreakpointCount : Int = 0,
           iCacheSize : Int = 4096,
           dCacheSize : Int = 4096,
        @@ -65,7 +62,6 @@
             val parser = new scopt.OptionParser[ArgConfig]("VexRiscvGen") {
               //  ex :-d    or   --debug
               opt[Unit]('d', "debug")    action { (_, c) => c.copy(debug = true)   } text("Enable debug")
        +      opt[Unit]("jtagBridge")    action { (_, c) => c.copy(jtagBridge = true) } text("Bridge DebugPlugin to external JTAG pins")
               opt[Int]("hardwareBreakpointCount")     action { (v, c) => c.copy(hardwareBreakpointCount = v) } text("Set number of available hardware breakpoints, defaults to 0")
               // ex : -iCacheSize=XXX
               opt[Int]("iCacheSize")     action { (v, c) => c.copy(iCacheSize = v) } text("Set instruction cache size, 0 mean no cache")
        @@ -336,11 +332,6 @@
                     master(plugin.dBus.toWishbone()).setName("dBusWishbone")
                   }
                   case plugin : DebugPlugin => {
        +            if (argConfig.jtagBridge) {
        +              plugin.io.bus.setAsDirectionLess()
        +              val jtag = plugin.io.bus.fromJtag().toIo()
        +              jtag.setName("jtag")
        +            }
                     out(CombInit(cpu.reflectBaseType("DebugPlugin_haltIt")).setName("halted"))
                   }
                   case _ =>


        ```

    - 生成客製化 Verilog `CustomJtag`

        ```
        $ cd .../litex/pythondata-cpu-vexriscv/pythondata_cpu_vexriscv/verilog

        sbt "runMain vexriscv.GenCoreDefault \
          --iCacheSize=0 \
          --dCacheSize=0 \
          --bypass=true \
          --prediction=dynamic_target \
          --csrPluginConfig=small \
          --debug \
          --jtagBridge \
          --hardwareBreakpointCount=4 \
          --outputFile=VexRiscv_CustomJtag"

        ```

+ 修改 LiteX 的 `core.py` 註冊 `minimal+jtag` 變體

    - 確認目標路徑

        ```
        $ python3 -c "import litex.soc.cores.cpu.vexriscv.core as m; print(m.__file__)"
        /home/xxx/litex/litex/litex/soc/cores/cpu/vexriscv/core.py
        ```

    - 對 LiteX 加入客製化的 `minimal+jtag`

        ```
        $ vi /home/xxx/litex/litex/litex/soc/cores/cpu/vexriscv/core.py
        ...
            CPU_VARIANTS = {
                "minimal":            "VexRiscv_Min",
                "minimal+debug":      "VexRiscv_MinDebug",
                "minimal+jtag":       "VexRiscv_CustomJtag",  # 新增此行
            }

            GCC_FLAGS = {
                "minimal":            "-march=rv32i2p0   -mabi=ilp32",
                "minimal+debug":      "-march=rv32i2p0   -mabi=ilp32",
                "minimal+jtag":       "-march=rv32i2p0   -mabi=ilp32",  # 新增此行

            }
        ```

+ 撰寫 LiteX 建置腳本

    ```python
    #!/usr/bin/env python3

    #
    # build_jtag_soc.py
    #

    import os
    import argparse
    from migen import *
    from litex.build.generic_platform import Subsignal, Pins, IOStandard
    from litex.soc.integration.builder import Builder, builder_args, builder_argdict
    from litex.soc.integration.soc_core import soc_core_args, soc_core_argdict

    # 1. 匯入你要使用的開發板 Target (此處以 digilent_arty 為例, 請依實際板子替換)
    from litex_boards.targets import digilent_arty

    # 2. 定義外接 4-pin JTAG 腳位資源
    #    - "JA:0" ~ "JA:3" 是 Arty A7 的 PMOD JA 連接器邏輯腳位名稱
    #    - 如果你的開發板沒有定義 PMOD 連接器, 可以直接寫 FPGA 實體腳位編號, 例如 Pins("G13")
    _jtag_ext_io = [
        ("jtag_ext", 0,
            Subsignal("tck", Pins("pmoda:0")), # 對應 Arty PMOD JA Pin 1 (G13)
            Subsignal("tms", Pins("pmoda:1")), # 對應 Arty PMOD JA Pin 2 (B11)
            Subsignal("tdi", Pins("pmoda:2")), # 對應 Arty PMOD JA Pin 3 (A11)
            Subsignal("tdo", Pins("pmoda:3")), # 對應 Arty PMOD JA Pin 4 (D12)
            IOStandard("LVCMOS33"),
        ),
    ]

    # 3. 繼承原本開發板的 BaseSoC, 加入 JTAG 腳位連接與時脈約束
    class JtagBaseSoC(digilent_arty.BaseSoC):
        def __init__(self, **kwargs):
            # 呼叫父類別建立完整的 SoC (包含 RAM, UART, Timer 等周邊)
            super().__init__(**kwargs)

            # (A) 將自定義的 JTAG 腳位註冊進開發板平台
            self.platform.add_extension(_jtag_ext_io)
            jtag_pads = self.platform.request("jtag_ext")

            jtag_halted = Signal()
            # (B) 將實體腳位與 VexRiscv 核心暴露的 jtag_* 介面透過組合邏輯連接
            #     - "i_" 開頭代表輸入進 CPU 的訊號
            #     - "o_" 開頭代表從 CPU 輸出的訊號
            self.cpu.cpu_params.update(
                i_jtag_tck = jtag_pads.tck,
                i_jtag_tms = jtag_pads.tms,
                i_jtag_tdi = jtag_pads.tdi,
                o_jtag_tdo = jtag_pads.tdo,
                o_halted   = jtag_halted,
            )

            # (C) 為 JTAG TCK 加入獨立的時脈約束 (100 ns = 10 MHz)
            #     避免 Vivado / Yosys 等合成工具因無法推斷外部時脈而產生時序警告或錯誤
            self.platform.add_period_constraint(jtag_pads.tck, 100.0)

    # 4. 解析命令列參數並啟動 LiteX Builder
    def main():
        parser = argparse.ArgumentParser(description="LiteX SoC with VexRiscv JtagBridge")
        parser.add_argument("--build", action="store_true", help="執行 FPGA 綜合與生成 Bitstream")
        parser.add_argument("--load",  action="store_true", help="將生成的 Bitstream 燒錄至 FPGA")
        parser.add_argument("--variant", default="a7-35",   help="開發板變體型號 (例如 a7-35 或 a7-100)")
        parser.add_argument("--sys-clk-freq", default=100e6, type=float, help="系統主時脈頻率")

        # 載入 LiteX 內建的 SoC 與 Builder 標準參數 (如 --cpu-variant, --uart-baudrate 等)
        builder_args(parser)
        soc_core_args(parser)
        args = parser.parse_args()

        # 實例化帶有 JTAG 的 SoC
        soc = JtagBaseSoC(
            variant      = args.variant,
            sys_clk_freq = int(args.sys_clk_freq),
            **soc_core_argdict(args)
        )

        # 執行建置 (編譯 BIOS 韌體 + 產生 Verilog + 執行 FPGA 合成)
        builder = Builder(soc, **builder_argdict(args))
        builder.build(run=args.build)

        # 若有指定 --load, 則呼叫開發板對應的燒錄器將 bitstream 寫入 FPGA
        if args.load:
            prog = soc.platform.create_programmer()
            prog.load_bitstream(builder.get_bitstream_filename(mode="sram"))

    if __name__ == "__main__":
        main()


    ```

    - 執行腳本

        ```
        # 執行腳本並透過 --cpu-variant 指定我們在 core.py 註冊的變體
        $ python3 build_jtag_soc.py --cpu-variant=minimal+jtag

        # 編譯 Bitstream of FPGA, 需有相關的 FPGA 工具鏈(e.g. Vivado/ Trellis/ Quartus)
        $ python3 build_jtag_soc.py --cpu-variant=minimal+jtag --build
        ```


+ 打包所有 RTL 與初始化檔案
    > 執行`$ python3 build_jtag_soc.py --cpu-variant=minimal+jtag` 無誤後, 即可打包

    ```bash
    #!/bin/bash

    mkdir -p exported_rtl
    cp build/digilent_arty/gateware/digilent_arty.v exported_rtl/
    cp build/digilent_arty/gateware/*.init exported_rtl/
    cp /home/xxx/litex/pythondata-cpu-vexriscv/pythondata_cpu_vexriscv/verilog/VexRiscv_CustomJtag.v exported_rtl/
    cp /home/xxx/litex/pythondata-cpu-vexriscv/pythondata_cpu_vexriscv/verilog/VexRiscv_CustomJtag.yaml exported_rtl/

    # 確認匯出清單
    ls -lh exported_rtl/
    ```

## Simulate `JtagBridge + OpenOCD + GDB`

在 Verilator 模擬環境中建立一個 TCP Server(監聽 port 4444),
當 `OpenOCD` 透過 `remote_bitbang` 傳送 `TCK、TMS、TDI` 的高低電位字元(如 '0'~'7')時,
Verilator 模擬器會直接驅動 VexRiscv 模組的 `jtag_tck、jtag_tms、jtag_tdi` 腳位, 並將 `jtag_tdo` 的邏輯電位傳回給 OpenOCD

+ 安裝 Verilator

    ```
    $ sudo apt-get install -y verilator libevent-dev libjson-c-dev
    ```

+ 用 LiteX 內建的純數位模擬器 `litex_sim`, 避免不同的 FPGA 開發版 dependency 的支援差異

    - 使用先前打包好的 source code

        ```
        $ cd .../exported_rtl && ls
            digilent_arty_mem.init
            digilent_arty_rom.init
            digilent_arty_sram.init
            digilent_arty.v
            VexRiscv_CustomJtag.v
            VexRiscv_CustomJtag.yaml
        ```

    - 建立模擬建置腳本
        > `$ vi .../exported_rtl/sim_jtag_soc.py`

        ```
        #!/usr/bin/env python3

        #
        # sim_jtag_soc.py
        #

        import argparse
        from migen import *
        from litex.build.generic_platform import Subsignal, Pins
        from litex.build.sim import SimPlatform
        from litex.build.sim.config import SimConfig
        from litex.soc.integration.builder import Builder, builder_args, builder_argdict
        from litex.soc.integration.soc_core import soc_core_args, soc_core_argdict
        from litex.tools.litex_sim import SimSoC, sim_args

        # 1. 在模擬平台定義外接 4-pin JTAG 腳位
        _sim_jtag_io = [
            ("jtag_ext", 0,
                Subsignal("tck", Pins(1)),
                Subsignal("tms", Pins(1)),
                Subsignal("tdi", Pins(1)),
                Subsignal("tdo", Pins(1)),
            ),
        ]

        # 2. 繼承 LiteX 官方的 SimSoC, 加入 JTAG 腳位連接
        class JtagSimSoC(SimSoC):
            def __init__(self, **kwargs):
                super().__init__(**kwargs)

                # 註冊並取得模擬器的 JTAG 頂層訊號
                self.platform.add_extension(_sim_jtag_io)
                jtag_pads = self.platform.request("jtag_ext")

                # 將實體模擬訊號連接到 VexRiscv 核心暴露的 jtag_* 介面
                jtag_halted = Signal()
                self.cpu.cpu_params.update(
                    i_jtag_tck = jtag_pads.tck,
                    i_jtag_tms = jtag_pads.tms,
                    i_jtag_tdi = jtag_pads.tdi,
                    o_jtag_tdo = jtag_pads.tdo,
                    i_debugReset = ResetSignal("sys"),
                    o_halted   = jtag_halted,
                )

        def main():
            parser = argparse.ArgumentParser(description="LiteX SimSoC with VexRiscv JtagBridge")
            builder_args(parser)
            soc_core_args(parser)
            sim_args(parser)
            args = parser.parse_args()

            # 配置模擬器基本周邊 (系統時脈 + 序列埠 Console)
            sim_config = SimConfig()
            sim_config.add_clocker("sys_clk", freq_hz=int(1e6)) # 模擬 clock 1MHz, 50e6= 50MHz
            sim_config.add_module("serial2console", "serial")

            # 強制指定使用我們註冊的 minimal+jtag 變體
            soc_kwargs = soc_core_argdict(args)
            soc_kwargs["cpu_type"] = "vexriscv"
            soc_kwargs["cpu_variant"] = "minimal+jtag"
            soc_kwargs["uart_name"] = "sim"

            soc = JtagSimSoC(
                sim_config = sim_config,
                **soc_kwargs
            )

            builder = Builder(soc, **builder_argdict(args))
            builder.build(sim_config=sim_config)

        if __name__ == "__main__":
            main()

        ```

    - 使用預設值來取代 `RTL 隨機初始化`
        > 對生成的 `VexRiscv_CustomJtag.v`, 直接取代變數, 避免 SpinalHDL 版本支援度不足

        ```bash
        $ sed -i "s/{\$urandom}/32'h0/g; s/\$urandom/32'h0/g" .../exported_rtl/VexRiscv_CustomJtag.v
        ```

    - `Terminal_1` 啟動带有 `jTag Server` 的 Verilator 模擬器

        ```
        $ ./sim_jtag_soc.py
        ...
            [clocker] sys_clk: freq_hz=1000000, phase_deg=0

                    __   _ __      _  __
                   / /  (_) /____ | |/_/
                  / /__/ / __/ -_)>  <
                 /____/_/\__/\__/_/|_|
               Build your hardware, easily!

             (c) Copyright 2012-2026 Enjoy-Digital
             (c) Copyright 2007-2015 M-Labs

             BIOS built on Nov 12 2026 14:47:42
             BIOS CRC passed (5b99c558)

             LiteX git sha1: be9ae2643

            --================ SoC =================--
            CPU:            VexRiscv_CustomJtag @ 1MHz
            BUS:            wishbone 32-bit data/32-bit addr
            CSR:            32-bit data big ordering
            ROM:            128.0KiB
            SRAM:           8.0KiB

            --================ Boot ================--
            Booting from serial...
            Press Q or ESC to abort boot completely.
            sL5DdSMmkekro
            Timeout
            No boot medium found

            --============== Console ===============--

            litex>

        ```

    - `Terminal_2` 啟動 `OpenOCD server`

        1. 建立 OpenOCD 設定檔 `vexriscv_sim.cfg`

            ```
            $ vi vexriscv_sim.cfg

                ## vexriscv_sim.cfg
                # 1. 使用 remote_bitbang 連接 Verilator 模擬器的 TCP Port 4444
                adapter driver remote_bitbang
                remote_bitbang host localhost
                remote_bitbang port 5555

                transport select jtag

                # 2. 定義 VexRiscv JtagBridge TAP (ID 固定為 0x10001fff)
                set _CHIPNAME vexriscv
                jtag newtap $_CHIPNAME cpu -irlen 4 -ircapture 0x1 -irmask 0xf -expected-id 0x10001fff

                # 3. 建立 VexRiscv 除錯目標並載入 yaml 描述檔
                set _TARGETNAME $_CHIPNAME.cpu
                target create $_TARGETNAME vexriscv -endian little -chain-position $_TARGETNAME
                vexriscv readWaitCycles 40
                vexriscv cpuConfigFile VexRiscv_CustomJtag.yaml

                init
                halt

            ```

    - `Terminal_3` 啟動 GDB Client
        > `$ riscv-none-elf-gdb -tui ./build/sim/software/bios/bios.elf`

        1. GDB 操作
            > LiteX SimSoC 模擬頻率(1MHz)較低,用終端命令 `-ex "target remote localhost:3333"`會連不上

            ```
            # 1. 連線至 OpenOCD 的 GDB Server
            (gdb) target remote localhost:3333      # 新版: target extended-remote localhost:3333
            (gdb) set remotetimeout 60              # 避免 GDB 因為等不到 OpenOCD 回應而主動斷線

            # 2. 暫停 CPU 並查看目前程式計數器 (PC) 與所有暫存器
            (gdb) monitor halt
            (gdb) info registers pc ra sp
                pc             0x3fcc   0x3fcc <uart_read_nonblock+56>
                ra             0x2e60   0x2e60 <litex_getc+12>
                sp             0x10001e30       0x10001e30
            # 3. 反組譯目前 PC 位置的指令（確認能否透過 JTAG 讀取 SoC 記憶體/ROM）
            (gdb) x/5i $pc
                => 0x3fe4 <uart_read_nonblock+80>:      addi    sp,sp,16    # 目前 $pc
                   0x3fe8 <uart_read_nonblock+84>:      ret
                   0x3fec <uart_write>: addi    sp,sp,-32
                   0x3ff0 <uart_write+4>:       lui     a5,0x10000
                   0x3ff4 <uart_write+8>:       sw      s4,8(sp)
            # 4. 測試單步執行 (Single Step),觀察 PC 是否前進 4 bytes
            (gdb) stepi
                Invalid hex digit 79                                        # Don't care
            (gdb) info registers pc
                pc             0x3fe8   0x3fe8 <uart_read_nonblock+84>      # 目前 $pc = $pc + 4
            (gdb) hbreak *0x3fe8                                            # Hardware Breakpoint
                Hardware assisted breakpoint 2 at 0x3fe8: file /home/padauk/Working/litex/litex/litex/soc/software/libbase/uart.c, line 90.
            (gdb) c
            ...
                program stopped
            (gdb)
            ```



        1. 關於 `Invalid hex digit 79` 的說明
            > 這是 `SpinalHDL 版 openocd_riscv` 與新版 GDB 之間的已知**無害**小問題.
            當 `stepi` 結束時, OpenOCD 回傳的 GDB Remote Serial Protocol (RSP) 停止封包格式,讓 GDB 的 Hex 解析器印出這行警告.
            >> 例如: 包含字串 `reason:watchpoint` 或未預期的 ASCII 字元 (十進位 79 對應 ASCII 字元 `O`)

+ 建立 Application Program

    ```
    [.../exported_rtl]
    $ litex_bare_metal_demo --build-path=build/sim
    [.../exported_rtl]
    $ ls -al
        build/
        demo/
        digilent_arty_mem.init
        digilent_arty_rom.init
        digilent_arty_sram.init
        digilent_arty.v
        sim_jtag_soc.py
        VexRiscv_CustomJtag.v
        VexRiscv_CustomJtag.yaml
        vexriscv_sim.cfg
    $ vi ./demo/Makefile        # modify
        BUILD_DIR?=../build/sim
        SOC_DIRECTORY=$(LITEX_SRCROOT)/litex/litex/soc

    ```

+ 執行 Application 模擬

    ```
    $ ./sim_jtag_soc.py --ram-init=./demo/demo.bin
    ```
