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
    > option `-p (--pristine)` 會清除 build directory

    ```
    $ west build -p -b mps2/an521/cpu0/ samples/hello_world   # clean build
        or
    $ west build -b mps2/an521/cpu0/ samples/hello_world      # just build
    ```

    - Configure with kconfig

        ```
        $ west build -p -b mps2/an521/cpu0/ <ZEPHYR_ROOT_DIR>/samples/hello_world -t menuconfig
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

        1. Contex-CM33 (PK)
            > `mps2/an521/cpu0/ns` 為 Non-Secure mode 需特別處理 (由 Secure mode 來 bring-up)
            >> `mps2/an521/cpu0` 為 Secure mode 且最後不能有 `/`

            ```
            $ west build -p -b mps2/an521/cpu0 <ZEPHYR_ROOT_DIR>/samples/hello_world -t run  # re-build and run Qemu

            # Qemu debug server ()
            $ west build -p -b mps2/an521/cpu0 <ZEPHYR_ROOT_DIR>/samples/hello_world/ -t debugserver

            # GDB-Client with tui
            $ west debug
            ```

+ Debug supports (ToDo: 需補充細節)
    > [Building, Flashing and Debugging — Zephyr Project Documentation](https://docs.zephyrproject.org/latest/develop/west/build-flash-debug.html#west-build-flash-debug)

    - `west flash`
        > download img to remote board

    - `west debug`
        > 連接 remote board 並且開啟 GDB console
        >> 需設定 build-directory

    - `west debugserver`
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


# Reference

+ [Getting Started Guide — Zephyr Project Documentation](https://docs.zephyrproject.org/latest/develop/getting_started/index.html#install-the-zephyr-sdk)

+ [Zephyr On QEMU](https://docs.zephyrproject.org/latest/samples/tfm_integration/psa_crypto/README.html#on-qemu)
+ [Building, Flashing and Debugging — Zephyr Project Documentation](https://docs.zephyrproject.org/latest/develop/west/build-flash-debug.html#west-build-flash-debug)

+ Introduction to Zephyr
    - [Introduction to Zephyr Part 1: Getting Started - Installation and Blink | DigiKey - YouTube](https://www.youtube.com/watch?v=mTJ_vKlMS_4&list=PLEBQazB0HUyTmK2zdwhaf8bLwuEaDH-52)
    -