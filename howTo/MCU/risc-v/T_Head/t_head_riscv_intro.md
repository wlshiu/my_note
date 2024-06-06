T-Head RISC-V Intro
---


+ 核心等級對應

    | ARM CortexM   | T-Head RISC-V |
    | :-:           |:-:            |
    | ARM-CM0       | E902          |
    |ARM M33/M3/M4F | E906          |


+ SDK
    > ref. `T-HEAD软件开发指南`
    - T-Head support profiles and SDK

        | RISC-V profile    | T-Head SDK    |
        | :-:               |:-:            |
        | rv32emcxtheadse   | SmartL_E902M  |
        | rv32ecxtheadse    | SmartL_E902   |
        | rv32ecxtheadse    | SmartL_E902T  |
        | rv32emcxtheadse   | SmartL_E902MT |

    - Profile definitions of T-Head

        | symbole  | instruction profile 指令集                                             |
        | :-:      |:-:                                                                     |
        | rv32i    | 32 位整型基礎指令集                                                    |
        | rv32e    | 嵌入式 32 位整型基礎指令集(與 rv32i 基本相同, 但只使用 16 * registers) |
        | rv64i    | 64 位整型基礎指令集                                                    |
        | m        | 整型乘, 除指令集                                                       |
        | a        | 原子操作指令集                                                         |
        | f        | 單精度浮點指令集                                                       |
        | d        | 雙精度浮點指令集                                                       |
        | c        | 壓縮指令集(即 16 位長度的指令集)                                       |
        | p        | Packed-SIMD 指令集                                                     |
        | v        | 向量指令集                                                             |
        | xtheadc  | 平頭哥 C 系列性能增強指令集                                            |
        | xtheade  | 平頭哥 E 系列性能增強指令集                                            |
        | xtheadse | 平頭哥 Small E 系列性能增強指令集                                      |
        | rv32g    | rv32imafd 的簡寫                                                       |
        | rv64g    | rv64imafd 的簡寫                                                       |


# Resource

+ [XuanTie玄铁官网](https://www.xrvm.cn/?spm=a2cl5.14300690.0.0.6efd7a32QKvAHX)
+ [T-Head Github](https://github.com/T-head-Semi)

# Development IDE

## CDK (Development Kit)

CDK 是專業為 IoT 應用開發打造的整合開發環境 (like Keil-MDK).

適用於 MCU 類型的開發者使用, 它風格簡潔, 與市面主流的 MCU 類開發工具的操作習慣貼合,
因此非常適合 MCU/IOT 裝置應用開發.


## CDS (Development Suite)

CDS 是面向平頭哥全系列 CPU 的一站式開發工具, 主要基於 Eclipse 框架, Eclipse 外掛開發的方式實現.

在產品使用體驗上, 更符合Eclipse風格的開發者偏好,
CDS包含了 T-Head 的全部系列的CPU, 支援從裸板程序到嵌入式Linux應用程式的開發,
支援圖形化的Trace/Profiling, 支援 RTOS 的圖形化的組態.

通過簡單易用的圖形化組態系統, 讓晶片開發變得簡單, 高效.

## Qemu

### Troubleshoot

+ check libraries

    ```
    $ ldd ./qemu-system-riscv32 | grep 'not '
        libcapstone.so.3 => not found
        libvdeplug.so.2 => not found
        libSDL2_image-2.0.so.0 => not found
        libbrlapi.so.0.7 => not found
    $ sudo apt install libvdeplug-dev libsdl2-image-dev libbrlapi-dev libcapstone-dev capstone-tool
    ```

    - `libcapstone.so.3: cannot open shared object file`
        > ```
        > $ sudo cp /usr/lib/x86_64-linux-gnu/libcapstone.so.4 /usr/lib/x86_64-linux-gnu/libcapstone.so.3
        > ```

    - `libbrlapi.so.0.7: cannot open shared object file`
        > ```
        > $ sudo cp ./usr/lib/x86_64-linux-gnu/libbrlapi.so.0.8.3  libbrlapi.so.0.7
        > ```


    - dependency

        ```
        $ sudo apt-get install -y libsnappy-dev libpixman-1-dev libjpeg-dev \
            libdaxctl-dev libvdeplug-dev libpmem-dev libgbm-dev libepoxy-dev libaio1 libslirp-dev \
            libgtk-3-0

        $ sudo apt-get install -y libcapstone-dev libspice-server-dev \
            libsdl2-2.0-0 libsdl2-image-2.0-0 libvirglrenderer-dev \
            libcacard-dev libusbredirparser1 libfuse3-3 libiscsi7 librbd1
        ```

## Practice

### SmartL SDK build

toolchain: `Xuantie-900-gcc-elf-newlib-x86_64-V2.10.0-20240419.tar.gz`

```
$ cd SmartL_E902-R2S2-V1.7.11/projects/examples/hello_world
$ make
```

+ Run Qemu
    > exit Qemu
    > + ubuntu: `C-a + x`
    > + msys2: `C-c`

    - E902

        ```
        $ qemu-system-riscv32 -M smartl -cpu e902 -nographic -m 128M -kernel out/smartl_e902_evb.elf
        Hello World!
        Hello_World runs successfully!
        ```

    - E902M

        1. qemu server side

            ```
            $ vi z_qemu_e902m.sh
                #!/bin/bash

                help()
                {
                    echo -e "usage: $0 <elf file>"
                    exit -1
                }

                if [ $# != 1 ]; then
                    help
                fi

                elf_file=$1

                qemu-system-riscv32 -M smartl -cpu e902m \
                    -nographic \
                    -m 128M \
                    -kernel ${elf_file} \
                    -gdb tcp::23333 -S

            $ chmod +x z_qemu_e902m.sh
            $ ./z_qemu_e902m.sh out/smartl_e902_evb.elf
            ```

        1. GDB client side

            ```
            $ vi z_gdb_e902m.sh
                #!/bin/bash

                help()
                {
                    echo -e "usage: $0 <elf file>"
                    exit -1
                }

                if [ $# != 1 ]; then
                    help
                fi

                elf_file=$1

                if [[ $OSTYPE == 'linux-gnu' ]]; then
                    optflags=' -tui '
                fi

                riscv64-unknown-elf-gdb -ex 'target remote localhost:23333' ${optflags} ${elf_file}

            $ chmod +x z_gdb_e902m.sh
            $ ./z_gdb_e902m.sh out/smartl_e902_evb.elf
            ```


### RTOS-SDK-Exxx-V2.0.0 build

+ Dependency

    - pip

        ```
        $ pip install --upgrade pip
        ```

    - yoctools

        1. msys2

            ```
            $ pip install yoctools
            ```


        1. ubuntu
            > 自動在 `$HOME` 下建立 `scons` 環境

            ```
            # user self install
            $ pip install yoctools
                or
            $ pip install yoctools==2.0.78 # 指定版本
            ```

    - SCons (optional)
        > pip 安裝
        > ```
        > $ pip install scons
        > ```

        1. 手動安裝
            > [SCons source](https://github.com/SCons/scons/releases)
            > + `$ tar -xzf SCons-4.7.0.tar.gz`
            > + `$ cd SCons-4.7.0`
            > + `$ python setup.py install`
            > + Add `.../PythonXX` and `.../PythonXX/Scripts` to PATH

        1. check success or not

            ```
            $ scons -v
            ```



+ Build RTOS-SDK

    - msys2
        > fail (Maybe, only uses CDK in windows platform...)

    - ubuntu

        ```
        $ cd RTOS-SDK-Exxx-V2.0.0

        # 設定 woking dir 並產生 '.yoc' 檔
        # ps. 刪除 '.yoc' 並切到其他目錄做 'yoc init', 即可重新設定 woking dir
        $ yoc init
        $ cd ~/RTOS-SDK-E902M-V2.0.0/solutions/bare_helloworld
        $ ./do_build.sh e902m smartl
            Build Solution by
            scons: Reading SConscript files ...
            scons: done reading SConscript files.
            scons: Building targets ...
            CC out/csi/csi2/src/csi_misc.o
            CC out/csi/csi2/src/csi_ringbuf.o
            CC out/libc_bare/src/_init.o
            CC out/libc_bare/src/malloc.o
            CC out/libc_bare/src/minilibc_port.o
            CC out/libc_bare/src/printf.o
            AR yoc_sdk/lib/libcsi.a
            CC out/libc_bare/src/mm/dq_addlast.o
            ranlib yoc_sdk/lib/libcsi.a
            CC out/libc_bare/src/mm/dq_rem.o
            CC out/libc_bare/src/mm/lib_mallinfo.o
            CC out/libc_bare/src/mm/mm_addfreechunk.o
            CC out/libc_bare/src/mm/mm_free.o
            CC out/libc_bare/src/mm/mm_initialize.o
            CC out/libc_bare/src/mm/mm_leak.o
            CC out/libc_bare/src/mm/mm_mallinfo.o
            CC out/libc_bare/src/mm/mm_malloc.o
            CC out/libc_bare/src/mm/mm_size2ndx.o
            CC out/board_riscv_dummy/src/board_init.o
            CC out/board_riscv_dummy/src/adc/board_adc.o
            CC out/board_riscv_dummy/src/audio/board_audio.o
            AR yoc_sdk/lib/libc_bare.a
            ranlib yoc_sdk/lib/libc_bare.a
            CC out/board_riscv_dummy/src/bt/board_bt.o
            CC out/board_riscv_dummy/src/button/board_button.o
            CC out/board_riscv_dummy/src/gpio/board_gpio.o
            CC out/board_riscv_dummy/src/led/board_led.o
            CC out/board_riscv_dummy/src/pwm/board_pwm.o
            CC out/board_riscv_dummy/src/uart/board_uart.o
            CC out/board_riscv_dummy/src/wifi/board_wifi.o
            CC out/chip_riscv_dummy/src/arch/e902m/system.o
            CC out/chip_riscv_dummy/src/arch/e902m/trap_c.o
            AS out/chip_riscv_dummy/src/arch/e902m/startup.o
            AR yoc_sdk/lib/libboard_riscv_dummy.a
            ranlib yoc_sdk/lib/libboard_riscv_dummy.a
            AS out/chip_riscv_dummy/src/arch/e902m/vectors.o
            CC out/chip_riscv_dummy/src/sys/devices.o
            CC out/chip_riscv_dummy/src/sys/irq.o
            CC out/chip_riscv_dummy/src/sys/irq_port.o
            CC out/chip_riscv_dummy/src/sys/os_port.o
            CC out/chip_riscv_dummy/src/sys/pre_main.o
            CC out/chip_riscv_dummy/src/sys/reboot.o
            CC out/chip_riscv_dummy/src/sys/sys_clk.o
            CC out/chip_riscv_dummy/src/sys/target_get.o
            CC out/chip_riscv_dummy/src/sys/tick.o
            CC out/chip_riscv_dummy/src/sys/weak.o
            CC out/chip_riscv_dummy/src/drivers/clk.o
            CC out/chip_riscv_dummy/src/drivers/dma.o
            CC out/chip_riscv_dummy/src/drivers/dw_uart_ll.o
            CC out/chip_riscv_dummy/src/drivers/gpio.o
            CC out/chip_riscv_dummy/src/drivers/gpio_pin.o
            CC out/chip_riscv_dummy/src/drivers/pinmux.o
            CC out/chip_riscv_dummy/src/drivers/power_manage.o
            CC out/chip_riscv_dummy/src/drivers/timer.o
            CC out/chip_riscv_dummy/src/drivers/uart.o
            CC out/bare_helloworld/app/src/main.o
            AR yoc_sdk/lib/libbare_helloworld.a
            ranlib yoc_sdk/lib/libbare_helloworld.a
            AR yoc_sdk/lib/libchip_riscv_dummy.a
            ranlib yoc_sdk/lib/libchip_riscv_dummy.a
            LINK out/bare_helloworld/yoc.elf
            INSTALL yoc.elf
            riscv64-unknown-elf-objdump -d out/bare_helloworld/yoc.elf > yoc.asm
            Generating yoc.bin
            run_postbuild_script(["yoc.bin"], ["out/bare_helloworld/yoc.elf"])
            [INFO] Generated output files ...
            /home/data_1/riscv/T_Head/RTOS-SDK-E902M-V2.0.0/solutions/bare_helloworld
            I am in Linux.
            /home/data_1/riscv/T_Head/RTOS-SDK-E902M-V2.0.0/solutions/bare_helloworld
            /home/data_1/riscv/T_Head/RTOS-SDK-E902M-V2.0.0/boards/board_riscv_dummy
            /home/data_1/riscv/T_Head/RTOS-SDK-E902M-V2.0.0/components/chip_riscv_dummy
            /home/data_1/riscv/T_Head/RTOS-SDK-E902M-V2.0.0/solutions/bare_helloworld/generated
            scons: done building targets.
            YoC SDK Done
        ```



