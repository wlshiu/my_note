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

### Practice

+ SmartL SDK build
    > toolchain: `Xuantie-900-gcc-elf-newlib-x86_64-V2.10.0-20240419.tar.gz`

    ```
    $ cd SmartL_E902-R2S2-V1.7.11/projects/examples/hello_world
    $ make
    ```

+ Run Qemu

    - E902

        ```
        $ qemu-system-riscv32 -M smartl -cpu e902 -nographic -m 128M -kernel out/smartl_e902_evb.elf
        Hello World!
        Hello_World runs successfully!

        # C+A x to exit qemu
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

            # C+A x to exit qemu
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

                riscv64-unknown-elf-gdb -ex 'target remote localhost:23333' -tui ${elf_file}

            $ chmod +x z_gdb_e902m.sh
            $ ./z_gdb_e902m.sh out/smartl_e902_evb.elf
            ```








