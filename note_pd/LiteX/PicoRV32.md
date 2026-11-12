PicoRV32 [[Back](./note_LiteX.md#CPU-PicoRV32)]
---

PicoRV32 不支援內部 DM (Debug Module, 沒有 jTag)


# 建立測試程式

```
# 1. 建立 PicoRV32 模擬專案結構(先產生軟體標頭檔與 BIOS, 預設 main-ram 只有 8KBytes)
$ litex_sim --cpu-type=picorv32 --integrated-main-ram-size=0x10000 --no-compile-gateware

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
    > LiteX_root/litex/litex/soc/software/common.mak

    ```
    SOC_DIRECTORY=$(BUILD_DIR)/../litex/litex/soc

    include $(BUILD_DIR)/software/include/generated/variables.mak
    include $(SOC_DIRECTORY)/software/common.mak
    ```


## 使用 Verilator RTL 模擬

> + 使用參數 `--integrated-main-ram-size=0x100000`(1MB) 來擴充記憶體空間

```
$ export LITEX_ENV_CC_TRIPLE=riscv-none-elf

# 1. 產生帶有 64KB main_ram (0x40000000) 的硬體描述與 C 標頭檔
$ litex_sim --cpu-type=picorv32 --integrated-main-ram-size=0x10000 --no-compile-gateware

# 2. 重新產生 demo 並編譯(讓 Linker 讀取新的 regions.ld，將程式連結到 0x40000000)
$ litex_bare_metal_demo --build-path=build/sim
$ ls demo
    demo.bin  demo.elf.map demo.elf ...


# 3. 啟動模擬器 (務必加上 --integrated-main-ram-size=0x10000)
$ litex_sim --cpu-type=picorv32 --integrated-main-ram-size=0x10000 --ram-init=demo/demo.bin

```

+ log message

    ```
    $ litex_sim --cpu-type=picorv32 --integrated-main-ram-size=0x10000 --ram-init=demo/demo.bin
    ...

    [clocker] sys_clk: freq_hz=1000000, phase_deg=0

            __   _ __      _  __
           / /  (_) /____ | |/_/
          / /__/ / __/ -_)>  <
         /____/_/\__/\__/_/|_|
       Build your hardware, easily!

     (c) Copyright 2012-2026 Enjoy-Digital
     (c) Copyright 2007-2015 M-Labs

     BIOS built on Nov 10 2026 14:09:16
     BIOS CRC passed (36e9b496)

     LiteX git sha1: be9ae2643

    --================ SoC =================--
    CPU:            PicoRV32 @ 1MHz
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

    LiteX minimal demo app built Nov 10 2026 14:08:46

    Available commands:
    help               - Show this command
    reboot             - Reboot CPU
    donut              - Spinning Donut demo
    helloc             - Hello C
    litex-demo-app>
    litex-demo-app> helloc
        Hello C demo...
        C: Hello, world!

    ```

+ GDB debug (失敗...要自己建立GDB Stub...)

    - Compile Demo Project

        ```
        # 1. 編譯帶有 main_ram 與 uartbone 除錯橋接的 PicoRV32 模擬器
        $ litex_sim --cpu-type=picorv32 \
                  --integrated-main-ram-size=0x10000 \
                  --with-uartbone \
                  --uart-tcp \
                  --no-compile-gateware

        # 2. 重新編譯 demo（確保 demo.elf 與 demo.bin 連結在 0x40000000）
        $ litex_bare_metal_demo --build-path=build/sim

        ```

    - 啟動模擬器並使用 TCP Port

        ```
        $ litex_sim --cpu-type=picorv32 \
                  --integrated-main-ram-size=0x10000 \
                  --with-uartbone \
                  --uart-tcp \
                  --ram-init=demo/demo.bin

        ```

    - 啟動 litex_server (角色等同於 OpenOCD Sever) 在 New Terminal

        ```
        $ litex_server --uart --uart-port=1234
        ```

    - GDB client (再開啟新Terminal) 連線

        ```

        ```

## Renode 模擬環境

Renode 對 PicoRV32 支援不足, 只要用到中斷設定, 都會造成 Exception (Illegal instruction )...

+ install Renode

    ```
    $ wget https://builds.renode.io/renode-latest.linux-portable.tar.gz
    $ tar -xzf renode-latest.linux-portable.tar.gz
    $ cd renode_1.17.0+20261109git4bd0c02c2-portable
    $ renode --version
    Renode v1.17.0
      build: 1.17.0+20261109git4bd0c02c2
      build type: Release
      runtime: .NET 10.0.14
    ```

+ 轉換成 renode 所需的描述檔

    ```
    # 1. 讓 litex_sim 匯出 csr.json (不需重編 Verilog)
    $ litex_sim --cpu-type=picorv32 --csr-json=csr.json --integrated-main-ram-size=0x10000 --no-compile-gateware

    $ litex_bare_metal_demo --build-path=build/sim      # rebuild demo

    # 2. 使用官方工具轉換為 Renode 設定檔
    $ litex_json2renode csr.json --repl=sim.repl --resc=sim.resc
    ```

    - modify `sim.repl`

        1. original
            > There are some bugs in PicoRV32 of Renode

            ```
            cpu0: CPU.PicoRV32  @ sysbus
                  cpuType: "rv32imc"
                  hartId: 0
            ```

        1. Use RISCV32 of Renode

            ```
            cpu0: CPU.RiscV32  @ sysbus
                cpuType: "rv32im"
                privilegedArchitecture: PrivilegedArchitecture.Priv1_10
                timeProvider: empty
                hartId: 0

            ```

+ 執行 Renode Simulator
    > `step 3` 需依據需求 un-mark

    ```
    $ vi _renode_run.resc
        using sysbus
        mach create "litex-picorv32"
        machine LoadPlatformDescription @sim.repl

        # 1. 載入帶有完整位址資訊的 ELF 執行檔
        sysbus LoadELF @demo/demo.elf

        # 2. 建立虛擬序列埠 /tmp/uart 並連接至 LiteX UART
        emulation CreateUartPtyTerminal "term" "/tmp/uart" true
        connector Connect sysbus.uart term

        # 3. 開啟 GDB Server (監聽 Port 3333)
        machine StartGdbServer 3333

        # 3. 直接啟動模擬
        # start

    $ renode --console _renode_run.resc
    ```

+ GDB client

    ```
    $ riscv-none-elf-gdb demo/demo.elf -tui \
        -ex "target remote localhost:3333" \
        -ex "b _start" \
        -ex "j _start" \
        -ex "monitor reset"
    ```

+ new terminal to display uart message
    > 須等 renode 建立 `/tmp/uart`


    ```
    $ screen /tmp/uart 115200   # leave press ctrl-a + d
    ```





