note_LiteX
---

[LiteX](https://github.com/enjoy-digital/litex) 是一個以 Python 為基礎的開源框架與工具, 專門用來自動化建立、模擬與部署 FPGA 系統單晶片(SoC):
> [litex-hub repositories · GitHub](https://github.com/orgs/litex-hub/repositories)

# 核心特色與功能

+ 使用 Python(基於 Migen 硬體描述語言工具)將各個硬體模組封裝成 Python 類別, 像積木一樣將 CPU、記憶體與週邊連接起來, 並能自動生成 Verilog 代碼與約束文件
+ 生態系
    - LiteX-Boards 支援超過 150 種以上來自 Xilinx、Intel、Lattice、Efinix、Gowin 等不同廠商的 FPGA 開發板.
    - 內建常用模組
        1. LiteSPI
        1. LiteI2C
        1. LiteUart
        1. LitejTag (by core type, e.g. PicoRV32 使用變形 UART over JTAG)
        1. LiteEth(Ethernet)
        1. LitePCIe
        1. LiteSATA
        1. LiteSDCard
        1. LiteNVMe
        1. LiteDSP

    - 支援 LiteDRAM 以及內嵌邏輯分析儀 LiteScope
    - Bus 支援 AXI4, AXI4-Lite, Wishbone ...等


+ 支援多種 CPU 架構
    - 可搭配 VexRiscv(RISC-V)、OpenRISC、Microwatt、ARM 等多種處理器, 並能自動生成配套的 BIOS、Bootloader(透過串口、網口或 PCIe 啟動)以及驅動程式



# 環境建立

+ Dependency
    
    - ubuntu
        
        ```
        $ sudo apt-get install -y openjdk-17-jdk
        ```
        
    - Toolchain
        1. [Version 11.5.0-2 released | xPack GNU RISC-V Embedded GCC](https://xpack-dev-tools.github.io/riscv-none-elf-gcc-xpack/blog/2024/09/02/riscv-none-elf-gcc-v11-5-0-2-released/)

    - Qemu
        1. [Version 9.2.4-1 released | xPack QEMU RISC-V](https://xpack-dev-tools.github.io/qemu-riscv-xpack/blog/2025/10/09/qemu-riscv-v9-2-4-1-released/)

+ LiteX source

    ```
    $ python3 -m venv ~/litex-venv && source ~/litex-venv/bin/activate
    $ wget https://raw.githubusercontent.com/enjoy-digital/litex/master/litex_setup.py
    $ chmod +x litex_setup.py
    ```

    - Try it in ten minutes

        ```
        $ export LITEX_ENV_CC_TRIPLE=riscv-none-elf

        $ ./litex_setup.py --init --install --config=standard   # Migen, LiteX, the cores, the boards, the CPUs
            or
        $ ./litex_setup.py --init --install --user              # '--user' 可將 Python 套件安裝在使用者目錄,不需要 sudo

        # $ ./litex_setup.py --gcc=riscv                        # use 'apt' to install the RISC-V compiler

        $ pip3 install meson ninja
        $ litex_sim --cpu-type=vexriscv
            or
        $ litex_sim --cpu-type=picorv32
        ```

        1. log message

            ```
            $ litex_sim --cpu-type=vexriscv

            ...
            [clocker] sys_clk: freq_hz=1000000, phase_deg=0

                    __   _ __      _  __
                   / /  (_) /____ | |/_/
                  / /__/ / __/ -_)>  <
                 /____/_/\__/\__/_/|_|
               Build your hardware, easily!

             (c) Copyright 2012-2026 Enjoy-Digital
             (c) Copyright 2007-2015 M-Labs

             BIOS built on Nov 10 2026 13:09:11
             BIOS CRC passed (c971e2ca)

             LiteX git sha1: be9ae2643

            --================ SoC =================--
            CPU:            VexRiscv @ 1MHz
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

# 建立測試程式


+ `SOC_DIRECTORY` 定義
    > LiteX_root/litex/litex/soc/software/common.mak

    ```
    SOC_DIRECTORY=$(BUILD_DIR)/../litex/litex/soc

    include $(BUILD_DIR)/software/include/generated/variables.mak
    include $(SOC_DIRECTORY)/software/common.mak
    ```


## [CPU-PicoRV32](./PicoRV32.md)
## [CPU-VexRISCV](./VexRISCV.md)
