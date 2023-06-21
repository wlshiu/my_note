Qemu RISC-V
---

[Qemu_Nuclei](https://github.com/riscv-mcu/qemu/tree/nuclei-master)
> versin 6.0.50

+ Dependency

    + [ninja](https://github.com/ninja-build/ninja/releases)

    + install lib

        ```bash
        $ sudo apt-get install ninja-build libpixman-1-dev libglib2.0-dev  # libsdl2-2.0 libsdl2-dev
        ```

+ Build Qemu

    - ubuntu

    ```bash
    $ git clone --depth 1 --recurse-submodules https://github.com/riscv-mcu/qemu.git
    $ mv qemu qemu_nuclei
    $ cd qemu_nuclei
    $ ./configure --disable-werror --prefix=$HOME/.local/ --disable-vnc --disable-sdl --disable-sdl-image \
        --target-list=riscv32-softmmu,riscv64-softmmu
    $ make -j8
    $ make install
    ```

    - msys2

        ```
        $ ./configure --disable-werror --prefix=$HOME/.local/ --disable-sdl --disable-sdl-image \
                --cross-prefix=x86_64-w64-mingw32- \
                --target-list=riscv32-softmmu,riscv64-softmmu \
        ```

+ Run Qemu

    - basic

        ```
        $ qemu-system-riscv32 -M nuclei_n,download=idlm -cpu nuclei-n200 \
            -kernel nuclei-sdk/application/baremetal/helloworld/helloworld.elf \
            -serial stdio -nodefaults -nographic
        ```

    - 指定執行 img 的裝置
        > `-M nuclei_n,download=ddr`
        >> `ilm` Instruction Local Memory

        | download參數  |   說明                |
        | :-            |   :-                  |
        | ddr           | 執行在 ddr 中         |
        | flash         | 執行在 flash 中       |
        | flashxip      | 執行在 flashxip 中    |
        | ilm           | 執行在 ilm 中(預設值) |

    - 使用擴展指令
        > `-cpu nuclei-n307fd,ext=pv` 使用 `p` 和 `v` 擴展指令



# Reference

+ [NUCLEI QEMU 使用者手冊](https://github.com/riscv-mcu/qemu/wiki/Nuclei-QEMU-User-Guide)
