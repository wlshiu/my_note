Nuclei RISC-V Intro
---


# Development IDE

## [Nuclei Studio](https://www.nucleisys.com/download.php#tools)

Nuclei Studio 是從 Eclipse 修改而來

## Qemu

qemu: `nuclei-qemu-2024.06-linux-x64.tar.gz`

```
$ qemu-system-riscv32 --cpu ?
    any
    lowrisc-ibex
    nuclei-n100
    nuclei-n100e
    nuclei-n100em
    nuclei-n100ezmmul
    nuclei-n100m
    nuclei-n100zmmul
    nuclei-n200
    nuclei-n201
    nuclei-n201e
    nuclei-n203
    nuclei-n203e
    nuclei-n205
    nuclei-n205e
    nuclei-n300
    nuclei-n300f
    nuclei-n300fd
    nuclei-n305
    nuclei-n307
    nuclei-n307fd
    nuclei-n600
    nuclei-n600f
    nuclei-n600fd
    nuclei-n900
    nuclei-n900f
    nuclei-n900fd
    nuclei-u600
    nuclei-u600f
    nuclei-u600fd
    nuclei-u900
    nuclei-u900f
    nuclei-u900fd
    rv32
    sifive-e31
    sifive-e34
    sifive-u34
```

```
$ qemu-system-riscv32 -M ?
    Supported machines are:
    none                 empty machine
    nuclei_demosoc       (Deprecated)Nuclei RISC-V DemoSoC, support Nuclei RISC-V 200/300/600/900 series processors
    nuclei_evalsoc       Nuclei RISC-V EvalSoC, support Nuclei RISC-V 200/300/600/900 series processors
    opentitan            RISC-V Board compatible with OpenTitan
    sifive_e             RISC-V Board compatible with SiFive E SDK
    sifive_u             RISC-V Board compatible with SiFive U SDK
    spike                RISC-V Spike board (default)
    virt                 RISC-V VirtIO board

```

## Practice

+ dependancy

    ```
    $ sudo apt install -y libncursesw5
    ```

### SDK build

toolchain: `nuclei_riscv_newlibc_prebuilt_linux64_2024.06.tar.bz2`

+ open source
    - [Nuclei Software](https://github.com/Nuclei-Software)
    - [nuclei-sdk](https://github.com/Nuclei-Software/nuclei-sdk/tree/master)
        > official target
    - [n100-sdk](https://github.com/riscv-mcu/n100-sdk)
    - [n200-sdk](https://github.com/riscv-mcu/n200-sdk)
    - [nucleisys](https://github.com/nucleisys?tab=repositories)


+ `n200-sdk`

    ```
    $ cd n200-sdk
    $ make dasm PROGRAM=hello_world BOARD=nuclei-n200
    ```

    - modify toolchain of Makefile

        ```
        ...

        ifeq (1,0)
        RISCV_GCC     := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-gcc)
        RISCV_GXX     := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-g++)
        RISCV_OBJDUMP := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-objdump)
        RISCV_OBJCOPY := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-objcopy)
        RISCV_GDB     := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-gdb)
        RISCV_AR      := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-ar)
        RISCV_SIZE    := $(abspath $(RISCV_PATH)/bin/riscv-none-embed-size)
        else

        RISCV_GCC     := riscv64-unknown-elf-gcc
        RISCV_GXX     := riscv64-unknown-elf-g++
        RISCV_OBJDUMP := riscv64-unknown-elf-objdump
        RISCV_OBJCOPY := riscv64-unknown-elf-objcopy
        RISCV_GDB     := riscv64-unknown-elf-gdb
        RISCV_AR      := riscv64-unknown-elf-ar
        RISCV_SIZE    := riscv64-unknown-elf-size
        endif
        ...
        ```

    - Run Qemu
        > exit Qemu
        > + ubuntu: `C-a + x`
        > + msys2: `C-c`

        1. qemu server side

            ```
            $ vi z_qemu_n200.sh
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

                qemu-system-riscv32 -M nuclei_evalsoc -cpu nuclei-n203e \
                    -nographic \
                    -m 128M \
                    -kernel ${elf_file} \
                    -gdb tcp::23333 -S

            $ cd n200-sdk
            $ chmod +x z_qemu_n200.sh

            $ ./z_qemu_n200.sh ./software/hello_world/hello_world
            ```

        1. GDB client side

            ```
            $ vi z_gdb_n200.sh
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

            $ chmod +x z_gdb_n200.sh
            $ cd n200-sdk

            $ ./z_gdb_n200.sh ./software/hello_world/hello_world
            ```

# Reference

+ [RISC-V CPU IP 芯來科技 - 產品中心](https://www.nucleisys.com/product.php)



