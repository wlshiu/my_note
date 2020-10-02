RISC-V Practice
---

# risc-v

## freedom-e-sdk

[freedom-e-sdk source](https://github.com/sifive/freedom-e-sdk)

+ toolcahin
    > [sifive-software](https://www.sifive.com/software) -> `GNU Embedded Toolchain — v2020.04.1`

+ Qemu
    > [sifive-software](https://www.sifive.com/software) -> `QEMU — v2020.04.0`

+ setup environment

    ```
    $ mkdir -p $HOME/sifive/ && cd $HOME/sifive/
    $ git clone --recursive https://github.com/sifive/freedom-e-sdk.git
    $ cd freedom-e-sdk
    $ make pip-cache
    $ export FREEDOM_E_SDK_VENV_PATH=$HOME/sifive/freedom-e-sdk/venv
    $ make PROGRAM=example-freertos-minimal TARGET=qemu-sifive-e31 LINK_TARGET=freertos software
    ```

## toolchain

```bash
$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev git libexpat1-dev

# 一次連 submodule 都下載
$ git clone --recursive https://github.com/riscv/riscv-gnu-toolchain

# 分段下載
$ git clone https://github.com/riscv/riscv-gnu-toolchain
$ git rm qemu       # 移除 qemu submodule, 降低資料量
$ git submodule update --init --recursive
```

+ `riscv-gnu-toolchain`
    > 包含多個 submodules
    > + [riscv-gcc](https://github.com/riscv/riscv-gcc)
    > + [riscv-glibc](https://github.com/riscv/riscv-glibc)
    > + [riscv-newlib](https://github.com/riscv/riscv-newlib)
    > + [riscv-dejagnu](https://github.com/riscv/riscv-dejagnu)
    > + [riscv-gdb](https://github.com/riscv/riscv-binutils-gdb.git)
    > + [riscv-binutils](https://github.com/riscv/riscv-binutils-gdb.git)
    > + [riscv-qemu](https://github.com/riscv/riscv-qemu.git)

+ architectures
    > Supported architectures are `rv32i` or `rv64i` plus standard extensions
    > + `(a)tomics`
    > + `(m)ultiplication and division`
    > + `(f)loat`
    > + `(d)ouble`
    > + `(g)eneral for MAFD`

    ```bash
    $ mkdir -p ~/toolchain/riscv_toolchain
    $ cd riscv-gnu-toolchain && mkdir build && cd build
    $ ../configure --prefix=${HOME}/toolchain/riscv_toolchain --enable-shared --with-arch=rv64imafdc --with-abi=lp64d
    ```

    - Supported ABIs
        > + `ilp32 (32-bit soft-float)`
        > + `ilp32d (32-bit hard-float)`
        > + `ilp32f (32-bit with single-precision in registers and double in memory, niche use only)`
        > + `lp64`
        > + `lp64f`
        > + `lp64d (same but with 64-bit long and pointers)`

+ riscv gcc可以編譯成幾個版本

    - riscv32-unknown-elf-xxx
        > 編譯裸機版本, 使用的 newlib

        ```bash
        $ ./configure --prefix=$HOME/riscv32 --with-arch=rv32imc --with-abi=xxx
        $ make
        ```

        1. `--with-abi`
            > + ilp32
            > + ilp32f
            > + ilp32d

        1. `riscv32-unknown-elf-gcc -v` 命令, 可以得到該工具鏈的配置信息

            ```
            --target=riscv32-unknown-elf:   指定工具為 riscv32-unknow-elf
            --prefix=/opt/riscv32:          指定工具生成的目錄
            --enable-languages=c,c++:       支持 c, c++ 語言
            --with-newlib:                  c運行庫使用 newlib
            --with-abi=ilp32:               工具鏈支持的 abi 方式是 ilp32
            --with-arch=rv32imc:            工具鏈支持的 riscv 架構是 rv32imc
            ```

    - riscv64-unknown-elf-xxx
        > 編譯裸機版本, 使用的 newlib

        ```bash
        $ ./configure --prefix=$HOME/riscv64 --with-arch=rv64imc --with-abi=xxx
        $ make
        ```

        1. `--with-abi`
            > + ilp64
            > + ilp64f
            > + ilp64d

        1. `riscv64-unknown-elf-gcc -v` 命令, 可以得到該工具鏈的配置信息

            ```
            --target=riscv64-unknown-elf:  指定工具為 riscv64-unknow-elf
            --prefix=/opt/riscv64:         指定工具生成的目錄
            --enable-languages=c,c++:      支持 c, c++ 語言
            --with-newlib:                 c運行庫使用 newlib
            --with-abi=lp64:               工具鏈支持的 abi 方式是 lp64
            --with-arch=rv64imc:           工具鏈支持的 riscv 架構是 rv64imc
            ```

    - riscv32-unknown-linux-gnu-xxx
        > 使用的 glibc

        ```bash
        $ ./configure --prefix=$HOME/riscv32-linux --with-arch=rv32imc --with-abi=xxx --enable-linux
        $ make linux
        ```

        1. `--with-abi`
            > + ilp32
            > + ilp32f
            > + ilp32d

        1. `riscv32-unknown-linux-gnu-gcc -v` 命令, 可以得到該工具鏈的配置信息

            ```
            --target=riscv32-unknown-linux-gnu:     指定工具為 riscv32-unknow-linux-gnu
            --prefix=/opt/riscv-linux:              指定工具生成的目錄
            --enable-languages=c,c++:               支持 c, c++ 語言
            --with-abi=ilp32:                       工具鏈支持的 abi 方式是 ilp32
            --with-arch=rv32imc:                    工具鏈支持的 riscv 架構是 rv32imc
            ```

    - riscv64-unknown-linux-gnu-xxx
        > 使用的 glibc

        ```bash
        $ ./configure --prefix=$HOME/riscv64-linux --with-arch=rv64imafdc --with-abi=xxx --enable-linux
        $ make linux
        ```

        1. `--with-abi`
            > + ilp64
            > + ilp64f
            > + ilp64d

        1. `riscv64-unknown-linux-gnu-gcc -v` 命令, 可以得到該工具鏈的配置信息

            ```
            --target=riscv64-unknown-linux-gnu:     指定工具為 riscv64-unknow-linux-gnu
            --prefix=/opt/riscv64:                  指定工具生成的目錄
            --enable-languages=c,c++:               支持 c, c++ 語言
            --with-abi=lp64d:                       工具鏈支持的 abi 方式是 lp64d
            --with-arch=rv64imafdc:                 工具鏈支持的 riscv 架構是 rv64imafdc
            ```

    - riscv64-liunx-multilib-xxx
        > 同時支持 32 位和 64 位

        ```bash
        $ ./configure --prefix=$HOME/riscv-linux-multilib --enable-multilib --target=riscv64-linux-multilib
        $ make linux
        ```

        1. `riscv64-unknown-linux-gnu-gcc -v` 命令, 可以得到該工具鏈的配置信息

            ```
            --target=riscv64-linux-multilib:        指定工具為 riscv64-linux-multilib
            --prefix=/opt/riscv-linux-multilib:     指定工具生成的目錄
            --enable-languages=c,c++:               支持 c, c++ 語言
            --with-abi=lp64d:                       工具鏈支持的 abi 方式是 lp64d
            --with-arch=rv64imafdc:                 工具鏈支持的 riscv 架構是 rv64imafdc
            --enabl-multilib:                       啓動 multilib
            ```

        1. 對於`riscv64-linux-multilib-gcc`, 可以通過以下選項, 來決定生成的程序是 32 位版本還是 64位版本

            ```
            -march=rv32: 32 位版本
            -march=rv64: 64 位版本
            ```

    - riscv64-multilib-elf-xxx
        > 編譯裸機版本, 同時支持 32 位和 64 位

        ```bash
        $ ./configure --prefix=$HOME/riscv64-multilib-elf --enable-multilib --target=riscv64-multilib-elf
        $ make
        ```

         1. `riscv64-unknown-elf-gcc -v` 命令, 可以得到該工具鏈的配置信息

            ```
            --target=riscv64-multilib-elf:          指定工具為 riscv64-multilib-elf
            --prefix=/opt/riscv64-multilib-elf:     指定工具生成的目錄
            --enable-languages=c,c++:               支持 c, c++ 語言
            --with-abi=lp64d:                       工具鏈支持的 abi 方式是 lp64d
            --with-arch=rv64imafdc:                 工具鏈支持的 riscv 架構是 rv64imafdc
            --enable-multilib:                      啓用 multilib
            ```

        1. 對於`riscv64-multilib-elf-gcc`,可以通過以下選項, 來決定生成的程序是 32 位版本還是 64 位版本:

            ```
            -march=rv32: 32 位版本
            -march=rv64: 64 位版本
            ```

    - riscv-none-embed-gcc
        > 編譯裸機版本, 專門為嵌入式使用的 gcc 交叉編譯工具鏈

        1. [xPack GNU RISC-V](https://xpack.github.io/riscv-none-embed-gcc/releases/)

+ ubuntu pre-build

    ```bash
    $ sudo apt install gcc-riscv64-linux-gnu
    $ vi ./setting_riscv.env
        export ARCH=riscv
        export PATH=${HOME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        export CROSS_COMPILE=riscv64-linux-gnu-
    $ source ./setting_riscv.env
    ```

## [riscv-probe](https://github.com/michaeljclark/riscv-probe)

簡易測試裸機行為(請使用 riscv-none-embed-gcc)

+ Invocation

    ```base
    $ spike --isa=RV32IMAFDC build/bin/rv32imac/spike/probe
    $ spike --isa=RV64IMAFDC build/bin/rv64imac/spike/probe

    $ qemu-system-riscv32 -nographic -machine spike_v1.10 -kernel build/bin/rv32imac/spike/probe
    $ qemu-system-riscv64 -nographic -machine spike_v1.10 -kernel build/bin/rv64imac/spike/probe

    $ qemu-system-riscv32 -nographic -machine virt -kernel build/bin/rv32imac/virt/probe
    $ qemu-system-riscv64 -nographic -machine virt -kernel build/bin/rv64imac/virt/probe

    $ qemu-system-riscv32 -nographic -machine sifive_e -kernel build/bin/rv32imac/qemu-sifive_e/probe
    $ qemu-system-riscv64 -nographic -machine sifive_e -kernel build/bin/rv64imac/qemu-sifive_e/probe

    $ qemu-system-riscv32 -nographic -machine sifive_u -kernel build/bin/rv32imac/qemu-sifive_u/probe
    $ qemu-system-riscv64 -nographic -machine sifive_u -kernel build/bin/rv64imac/qemu-sifive_u/probe
    ```

## uboot

+ env

    ```
    $ vi ./setting_riscv.env
        export ARCH=riscv
        export PATH=${HOME}/toolchain/riscv32_toolchain/bin:${HOME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        export CROSS_COMPILE=riscv32-unknown-elf-
    $ source ./setting_riscv.env
    ```

    - script

        ```bash
        $ vi ./z_setup_env.sh
            #!/bin/bash

            set -e

            help()
            {
                echo -e "usage: $0 <arch type>"
                echo -e "   arch type:"
                echo -e "       arm/arm64"
                echo -e "       riscv32/riscv64"
                exit -1;
            }

            if [ $# != 1 ]; then
                help
            fi

            arch_type=$1
            env_file=setting.env

            path_base=$HOME/.local/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

            echo -e "export PATH=${path_base}" > ${env_file}

            case "${arch_type}" in
                "arm")
                    echo -e "export ARCH=${arch_type}" >> ${env_file}
                    echo -e "export PATH=${HOME}/toolchain/gcc-linaro-6.5.0-2018.12-i686_arm-linux-gnueabi/bin:${path_base}" >> ${env_file}
                    echo -e "export CROSS_COMPILE=arm-linux-gnueabi-" >> ${env_file}
                    ;;

                "arm64")
                    echo -e "export ARCH=${arch_type}" >> ${env_file}
                    echo -e "export PATH=${HOME}/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin:${path_base}" >> ${env_file}
                    echo -e "export CROSS_COMPILE=aarch64-linux-gnu-" >> ${env_file}
                    ;;

                "riscv32")
                    toolchain_version=xpack-riscv-none-embed-gcc-8.3.0-1.2
                    echo -e "export ARCH=riscv" >> ${env_file}
                    echo -e "export PATH=${HOME}/toolchain/${toolchain_version}/bin:${path_base}" >> ${env_file}
                    echo -e "export CROSS_COMPILE=riscv-none-embed-" >> ${env_file}
                    ;;

                "riscv64")
                    # toolchain_version=xpack-riscv-none-embed-gcc-8.3.0-1.2
                    toolchain_version=riscv_toolchain

                    echo -e "export ARCH=riscv" >> ${env_file}
                    echo -e "export PATH=${HOME}/toolchain/${toolchain_version}/bin:${path_base}" >> ${env_file}

                    # echo -e "export CROSS_COMPILE=riscv-none-embed-" >> ${env_file}
                    echo -e "export CROSS_COMPILE=riscv64-unknown-linux-gnu-" >> ${env_file}
                    ;;
                *)
                    help
                    ;;
            esac
        ```

+ build

    ```
    $ make qemu-riscv32_defconfig
        or
    $ make qemu-riscv64_defconfig

    $ make
    ```

+ run qemu
    > qemu 5.1 的 risc-v 有問題, 請使用 qemu 4

    ```
    $ qemu-system-riscv32 -nographic -M virt -m 128M -bios u-boot
        or
    $ qemu-system-riscv64 -nographic -M virt -m 128M -bios u-boot
    ```

+ spike simulator
    > 似乎比較少人用了

    - environment

        ```bash
        $ sudo apt install device-tree-compiler
        ```

    - build

        ```bash
        $ git clone https://github.com/riscv/riscv-fesvr --depth=1
        $ cd riscv-fesvr
        $ ./configure --prefix=$HOME/riscv_spike
        $ make && make install

        $ git clone https://github.com/riscv/riscv-isa-sim --depth=1
        $ cd riscv-isa-sim
        $ ./configure --prefix=$HOME/riscv_spike
        $ make && make install

        $ git clone https://github.com/riscv/riscv-pk.git --depth=1
        $ cd riscv-pk
        $ ./configure --prefix=$HOME/riscv_spike --host=riscv64-unknown-linux-gnu
        $ make && make install

        $ git clone https://github.com/riscv/riscv-opcodes.git --depth=1
        $ cd riscv-opcodes
        $
        ```

    - example

        ```bash
        $ riscv64-unknown-elf-gcc -o hello hello.c
        $ spike pk hello
        ```

# reference
+ u-boot/doc/board/emulation/qemu-riscv.rst
+ [riscv各種版本gcc工具鏈編譯與安裝](https://www.twblogs.net/a/5c77fb01bd9eee3399184b73)
+ [Spike RISC-V ISA Simulator](https://github.com/riscv/riscv-isa-sim)
