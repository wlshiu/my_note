Zephyr RTOS (2026)
----


# Setup environment

> `z_setup_zephyr.sh`
> ```bash
> #!/bin/bash
>
> ZEPHYR_ROOT_DIR=$HOME/zephyrproject
>
> # Create the new virtual environment
> python3 -m venv ${ZEPHYR_ROOT_DIR}/.venv
>
> # Activate the virtual environment
> # use 'deactivate' to level python-venv
> source ${ZEPHYR_ROOT_DIR}/.venv/bin/activate
>
> pip install west
>
> west init ${ZEPHYR_ROOT_DIR}
>
> cd ${ZEPHYR_ROOT_DIR}
>
> west update
> west packages pip --install
> west zephyr-export
>
> ```

+ Create a new virtual environment of python

    ```
    $ python3 -m venv ~/zephyrproject/.venv
    $ source ~/zephyrproject/.venv/bin/activate
    ```

+ Install `west`
    > use `west --help` to view the commands

    ```
    $ pip install west
    $ west init ~/zephyrproject
    $ cd ~/zephyrproject
    $ west update                   # Get the Zephyr source code
    $ west packages pip --install

    # Export a Zephyr CMake package, 讓 CMake 可以自動載入建置 Zephyr 所需的樣板程式
    $ west zephyr-export
    ```

+ Install the Zephyr SDK (involve toolchain)

    ```
    $ west sdk install
    ```

+ build an example of Zephyr-SDK

    - Use `west`
        > option `-p (--pristine)` 會清除 build directory

        ```
        $ west build -p -b mps2/an521/cpu0/ samples/hello_world   # clean build
            or
        $ west build -b mps2/an521/cpu0/ samples/hello_world      # just build
        ```

        1. Configure with kconfig

            ```
            $ west build -p -b mps2/an521/cpu0/ <ZEPHYR_ROOT_DIR>/samples/hello_world -t menuconfig
            ```

    - Use `cmake`
        > list supported boards `$ cd <ZEPHYR_ROOT_DIR> && west boards`
        > board `stm32f103_mini, qemu_riscv32e, qemu_cortex_m3, qemu_riscv32_xip, ...etc.`

        1. Use official rule
            > toolchain will link to `$HOME/zephyr-sdk-1.0.1`
            >> It MUST execute `$ west install` to download toolchains which are integrated by official

            ```
            $ cd <ZEPHYR_ROOT_DIR>/samples/hello_world
            $ cmake -Bbuild -DBOARD=stm32f4_disco  # '-B' output path
            $ cd build
            $ make clean
            $ make menuconfig
            $ make
            ```

        1. Use 3th-party toolchain
            > Setup environment variables
            >
            > ```
            > $ export ZEPHYR_SDK_INSTALL_DIR=<ZEPHYR_ROOT_DIR>           # 可以讓 App 在任意路徑, 協同編譯 Zephyr-RTOS
            > $ export ZEPHYR_BASE=<ZEPHYR_ROOT_DIR>
            > ```
            >
            > ```
            > $ export GNUARMEMB_TOOLCHAIN_PATH=<GNU-ARM-Toolchain-Path>  # 標明外部 gnu-arm toolchain 路徑
            > $ export ZEPHYR_TOOLCHAIN_VARIANT="gnuarmemb"               # 使用 gnu-arm toolchain
            > ```
            >
            > ```
            > $ export ZEPHYR_TOOLCHAIN_VARIANT="cross-compile"           # 使用 3th-party toolchain
            > $ export CROSS_COMPILE="<toolchain_path>/<cross-prefix>"    # <toolchain_path>: $HOME/toolchains/nds32le-elf-newlib-v5/bin
            >                                                             # <cross-prefix>  : riscv32-elf-
            > ```

            ```
            $ cd <ZEPHYR_ROOT_DIR>
            $ cmake -Bbuild -DBOARD=stm32f4_disco samples/hello_world
                or
            $ cmake --trace-expand -Bbuild -DBOARD=stm32f4_disco samples/hello_world  # '--trace-expand' 秀出 cmake 執行的所有訊息

            $ cd build
            $ make clean
            $ make menuconfig
            $ make
            ```


+ Run with QEMU
    > Free-run with `west build -t run`

    - Use `west`

        1. Contex-CM3 (OK)

            ```
            # Free-run with Qemu
            $ west build -p -b qemu_cortex_m3 <ZEPHYR_ROOT_DIR>/samples/hello_world/ -t run

            # Qemu debug server
            $ west build -p -b qemu_cortex_m3 <ZEPHYR_ROOT_DIR>/samples/hello_world/ -t debugserver

            # GDB-Client with tui
            $ west debug
            ```

        1. Contex-CM33 (OK)
            > `mps2/an521/cpu0/ns` 為 Non-Secure mode 需特別處理 (由 Secure mode 來 bring-up)
            >> `mps2/an521/cpu0` 為 Secure mode 且最後不能有 `/`

            ```
            $ west build -p -b mps2/an521/cpu0 <ZEPHYR_ROOT_DIR>/samples/hello_world -t run  # re-build and run Qemu

            # Qemu debug server ()
            $ west build -p -b mps2/an521/cpu0 <ZEPHYR_ROOT_DIR>/samples/hello_world/ -t debugserver

            # GDB-Client with tui
            $ west debug
            ```

    - Use `pure-qemu`

        1. qemu simulate

            ```
            $ vi z_qemu_riscv32e.sh

                #!/bin/bash
                QEMU_RISCV32=${HOME}/xpack-qemu-riscv-9.2.4-1/bin/qemu-system-riscv32

                ${QEMU_RISCV32} -machine virt -bios none \
                  -nographic \
                  -m 256 \
                  -net none \
                  -chardev stdio,id=con,mux=on \
                  -serial chardev:con \
                  -mon chardev=con,mode=readline \
                  -kernel <ZEPHYR_ROOT_DIR>/build/zephyr/zephyr.elf \
                  -s -S
            ```
        1. GDB debug

            ```
            $ vi z_gdb_client.sh
                #!/bin/bash

                riscv64-unknown-elf-gdb -tui \
                    <ZEPHYR_ROOT_DIR>/build/zephyr/zephyr.elf \
                    -ex "set pagination off" \
                    -ex "add-symbol-file <ZEPHYR_ROOT_DIR>/build/zephyr/zephyr.elf" \
                    -ex "b __start" \
                    -ex "target remote localhost:1234"
            ```

+ Trace kconfig 關係

    ```
    $ west build -p pristine -b <YOUR_BOARD> <APP_DIR> -t traceconfig

    ...

    Traceconfig generated to: <ZEPHYR_ROOT_DIR>/build/zephyr/kconfig-trace.md
    ```

## Kconfig 關係圖

> + Environment variables: `<ZEPHYR_ROOT_DIR>/build/build.ninja`
> ```
> # copy some target kconfig files to KCONFIG_BINARY_DIR for build-system (out-of-tree feature)
> KCONFIG_BINARY_DIR=<ZEPHYR_ROOT_DIR>/build/Kconfig
>
> # copy the target kconfig files (about board) from <ZEPHYR_ROOT_DIR>/boards/xxx/xxx to this directory
> KCONFIG_BOARD_DIR=<ZEPHYR_ROOT_DIR>/build/Kconfig/boards
>
> # the target application of zephyr-rtos
> APPLICATION_SOURCE_DIR=<ZEPHYR_ROOT_DIR>/samples/hello_world
>
> # Globle variable of zephyr-rtos
> TOOLCHAIN_KCONFIG_DIR=${HOME}/zephyr-sdk-1.0.1/cmake/zephyr
> ```

+ keyword of Kconfiglib

    - include other kconfig files
        1. `source`
            > `absolute source` link 錯誤就直接報錯停止, 路徑使用 Kconfig-root 或 絕對路徑
        1. `osource`
            > `option source` 嘗試 link, 如果錯誤就跳過不處理, 路徑使用 Kconfig-root 或 絕對路徑
        1. `rsource`
            > `relative source` link 錯誤就直接報錯停止, 相對路徑以 **當前 Kconfig file 所在的目錄**為主
        1. `orsource`
            > `option and relative source` 嘗試 link, 如果錯誤就跳過不處理, 相對路徑以 **當前 Kconfig file 所在的目錄**為主

+ Kconfig tree

```
<ZEPHYR_ROOT_DIR>/Kconfig.zephyr
    ├── Kconfig.constants                                               ---+---
    ├── $(APPLICATION_SOURCE_DIR)/VERSION                   <--- option    | load default values
    ├── dts/Kconfig                                                        V
    |   └── $(KCONFIG_BINARY_DIR)/Kconfig.dts
    ├── $(KCONFIG_BINARY_DIR)/Kconfig.shield.defconfig      <--- option
    ├── boards/shields/*/Kconfig.defconfig
    |
    ├── $(KCONFIG_BOARD_DIR)/Kconfig.defconfig              <--- option
    |   └── <ZEPHYR_ROOT_DIR>/boards/<TARGET_BOARD>/Kconfig.defconfig
    |
    ├── $(KCONFIG_BINARY_DIR)/soc/Kconfig.defconfig
    |   └── <ZEPHYR_ROOT_DIR>/soc/*/*/Kconfig.defconfig     <--- option
    |
    ├── $(TOOLCHAIN_KCONFIG_DIR)/Kconfig.defconfig          <--- option
    ├── subsys/testsuite/Kconfig.defconfig
    |
    ├── modules/Kconfig                                                 ---+---
    |   ├── modules/Kconfig.atmel                                          | select kconfig configuration
    |   ├── modules/Kconfig.chre                                           V
    |   ├── modules/Kconfig.cypress
    |   ├── modules/Kconfig.eos_s3
    |   ├── modules/Kconfig.esp32
    |   ├── modules/Kconfig.infineon
    |   ├── modules/Kconfig.libmetal
    |   ├── modules/lvgl/Kconfig
    |   ├── modules/Kconfig.microchip
    |   ├── modules/Kconfig.mspm0
    |   ├── modules/Kconfig.nuvoton
    |   ├── modules/Kconfig.open-amp
    |   ├── modules/Kconfig.picolibc
    |   ├── modules/Kconfig.renesas
    |   ├── modules/Kconfig.rust
    |   ├── modules/Kconfig.simplelink
    |   ├── modules/Kconfig.stm32
    |   ├── modules/Kconfig.syst
    |   ├── modules/Kconfig.telink
    |   ├── modules/thrift/Kconfig
    |   ├── modules/Kconfig.vega
    |   ├── modules/Kconfig.wurthelektronik
    |   ├── modules/Kconfig.xtensa
    |   ├── modules/zcbor/Kconfig
    |   ├── modules/Kconfig.mcuboot
    |   ├── modules/Kconfig.intel
    |   └── modules/hostap/Kconfig
    |
    ├── boards/Kconfig
    |   ├── Kconfig.v2
    |   ├── $(KCONFIG_BINARY_DIR)/Kconfig.shield    <--- option, This loads custom shields Kconfig (from BOARD_ROOT)
    |   ├── shields/*/Kconfig.shield
    |   ├── Kconfig.whisper
    |   └── $(KCONFIG_BOARD_DIR)/Kconfig            <--- option
    |
    ├── soc/Kconfig
    |   ├── Kconfig.v2
    |   |   └── $(KCONFIG_BINARY_DIR)/soc/Kconfig.soc   <--- variable: SOC/ SOC_SERIES/ SOC_FAMILY
    |   |       └── <ZEPHYR_ROOT_DIR>/soc/*/*/Kconfig.soc  <--- option
    |   ├── $(KCONFIG_BINARY_DIR)/soc/Kconfig           <--- option
    |   |   └── <ZEPHYR_ROOT_DIR>/soc/*/*/Kconfig
    |   ├── soc/common/Kconfig                          <--- option
    |   |   └── riscv-privileged/Kconfig
    |   └── subsys/logging/Kconfig.template.log_config
    |
    ├── arch/Kconfig
    |   ├── $(KCONFIG_BINARY_DIR)/arch/Kconfig
    |   |   └── <ZEPHYR_ROOT_DIR>/arch/*/Kconfig        <--- option
    |   ├── $(KCONFIG_BINARY_DIR)/Kconfig.arch          <--- option
    |   └── arch/common/Kconfig
    |
    ├── kernel/Kconfig
    |   ├── Kconfig.obj_core
    |   ├── userspace/Kconfig
    |   |   └── Kconfig.mem_domain
    |   ├── smp/Kconfig
    |   ├── Kconfig.device
    |   ├── Kconfig.vm
    |   └── Kconfig.init
    |
    ├── drivers/Kconfig
    |   └── drivers/*/Kconfig
    |
    ├── lib/Kconfig
    |   └── lib/*/Kconfig
    |
    ├── subsys/Kconfig
    |   └── subsys/*/Kconfig         <--- e.g. USB, net, storage
    |
    └── $(TOOLCHAIN_KCONFIG_DIR)/Kconfig            <--- option
```

### SoC Selection

Zephyr-RTOS 使用`SOC`,`SOC_SERIES` 和 `SOC_FAMILY`的三層從屬關係, 來逐層收斂(Hierarchical) SoC 的選擇
> 在 Kconfig 的實作中, 採用反向依賴邏輯(下層強制 select 上層) <br>
>> 當在 `prj.conf` 或 Board 的 `defconfig` 中, 指定了具體的晶片型號(SOC)時,
它會像骨牌一樣自動把上層的系列(SOC_SERIES)和家族(SOC_FAMILY)全部開啟

```
    SOC_FAMILY (Chip Vendor, e.g. STM32, NRF)
        │
        V
    SOC_SERIES (Chip Series, e.g. STM32G4X, NRF52X)
        │
        V
       SOC     (Target Chip, e.g. STM32G474XX, NRF52840)
```

+ `SOC_FAMILY` 定義 Chip-Vendor, 並引導編譯系統去尋找, 該 Vendor 對應的 HAL-Driver
+ `SOC_SERIES` 統整該系列 Chip 共用的 system core 設定 (e.g. CPU, Vector)
+ `SOC` 定義確切的 Chip 型號, 並用來連結具體的 Device-Tree (*.dts) 與 Flash/SRAM 配置

## Debug supports (ToDo: 需補充細節)
> [Building, Flashing and Debugging — Zephyr Project Documentation](https://docs.zephyrproject.org/latest/develop/west/build-flash-debug.html#west-build-flash-debug)

### Use `make`

+ ICE download (OpenOCD)

+ GDB

### Use `west`

+ `west flash`
    > download img to remote board

+ `west debug`
    > 連接 remote board 並且開啟 GDB console
    >> 需設定 build-directory

+ `west debugserver`
    > 連接 remote board, 等待 GDB client 連接

# ARM Contex-CM33 (AN521) with Qemu

Zephyr-RTOS 是 QEMU 模擬 Cortex-M33 最成熟且最完整的生態系.
QEMU 原生支援 Arm 的 MPS2/MPS3 測試板(AN521 FPGA 映像), 其核心就是雙核 Cortex-M33, Zephyr 官方將其列為標準的 QEMU 測試目標

## TFM (Trusted Firmware MCU) example

+ tfm examples in Zephyr-RTOS
    > `<ZEPHYR_ROOT_DIR>/samples/tfm_integration`

    ```
    # '-p': clean project
    $ west build -p -b mps2/an521/cpu0/ns samples/tfm_integration/tfm_ipc
    ```

    - Memory layout
        > auto-generate

        ```
        $ cat <ZEPHYR_ROOT_DIR>/build/zephyr/include/generated/zephyr/devicetree_generated.h
        ```

+ Qemu executes

    ```
    $ west build -t run
    ```

+ Debug with GDB in Qemu
    > `west debugserver/debug` 竟然無法使用在 tfm ...

    - Wait GDB-Client connection

        ```
        $ qemu-system-arm -M mps2-an521 -device loader,file=<ZEPHYR_ROOT_DIR>/build/zephyr/tfm_merged.hex -nographic -s -S
        ```

    - GDB-Client connects to Qemu

        ```
        $ arm-none-eabi-gdb ./zephyr/build/zephyr/zephyr.elf \
            -ex "set pagination off" \
            -ex "add-symbol-file ./zephyr/build/tfm/bin/tfm_s.elf" \
            -ex "b __start" \
            -ex "target remote localhost:1234" \
            -tui

        GDB-Console:
            ...
            Remote debugging using localhost:1234
            0x100009f4 in ?? ()
            => 0x100009f4:  08 b5   push    {r3, lr}
            (gdb) info breakpoints
            Num     Type           Disp Enb Address    What
            1       breakpoint     keep y   0x00100bdc /home/lubwl/working/test/rtos/Zephyr/zephyr/arch/arm/core/cortex_m/reset.S:95
            (gdb) c
            Continuing.

            Breakpoint 1, z_arm_reset () at /home/lubwl/working/test/rtos/Zephyr/zephyr/arch/arm/core/cortex_m/reset.S:95
            warning: Source file is more recent than executable.
            (gdb)

        ```

# [Add customized-SoC](./note_zephyr_customer_soc.md)

# Reference

+ Zephyr-RTOS official
    - [Getting Started Guide — Zephyr Project Documentation](https://docs.zephyrproject.org/latest/develop/getting_started/index.html#install-the-zephyr-sdk)
    - [Build System (CMake) — Zephyr Project Documentation](https://docs.zephyrproject.org/latest/build/cmake/index.html#)
    - [Building, Flashing and Debugging — Zephyr Project Documentation](https://docs.zephyrproject.org/latest/develop/west/build-flash-debug.html#west-build-flash-debug)

+ [Zephyr On QEMU](https://docs.zephyrproject.org/latest/samples/tfm_integration/psa_crypto/README.html#on-qemu)
+ Introduction to Zephyr
    - [Introduction to Zephyr Part 1: Getting Started - Installation and Blink | DigiKey - YouTube](https://www.youtube.com/watch?v=mTJ_vKlMS_4&list=PLEBQazB0HUyTmK2zdwhaf8bLwuEaDH-52)

+ [Zephyr RTOS - HackMD](https://hackmd.io/@ichunlai/Hk_ndjG1t)

