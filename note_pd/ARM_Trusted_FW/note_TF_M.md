Trusted_Firmware-M
---

# Definitions
> [Glossary of terms and abbreviations](https://trustedfirmware-m.readthedocs.io/en/latest/glossary.html#term-SPE)

+ PSA (Platform Security Architecture)

+ MPU (Memory Protection Unit)
    > Hardware component providing privilege control.

+ NSPE (Non Secure Processing Environment)
    > In TF-M this means non secure domain typically running an OS using services provided by TF-M.

+ SPE (Secure Processing Environment)
    > In TF-M this means the secure domain protected by TF-M.


# Setup development environment

+ dependencies
    > + **CMake version 3.21 or later**
    > + **Python version 3.12 or later**

    ```
    $ sudo apt-get install -y git curl wget build-essential libssl-dev cmake make
    $ sudo apt install ninja-build
    $ sudo apt install python3.12 python3.12-pip python3.12-venv python3.12-dev
    $ sudo apt install gdb-multiarch

    $ cd <user-local-tf-m_dir>
    $ python3 -m venv .venv
    $ source .venv/bin/activate
    $ cd <user-local>/trusted-firmware-m/tools
    $ pip install -r requirements.txt

    # if necessary
    $ pip uninstall requirements.txt
    ```

+ download source code
    > Use `ver: TF-Mv1.8.1`
    >> involve SPE(Secure Processing Environment) and NSPE (Non Secure Processing Environment)

    ```
    $ git clone https://git.trustedfirmware.org/TF-M/trusted-firmware-m.git
    $ git checkout TF-Mv1.8.1  # use GNU Arm Embedded Toolchain 11.2-2022.02
    ```

+ build
    > create `z_build_tfm.sh`

    ```
    #!/bin/bash

    cmake -S . -B out \
        -DTFM_PLATFORM=arm/mps2/an521 \
        -DTFM_TOOLCHAIN_FILE=toolchain_GNUARM.cmake \
        -DCMAKE_BUILD_TYPE=Debug \
        -DTEST_NS=ON \
        -DTEST_S=ON \
        -DTFM_PSA_API=ON \
        -DBL2=OFF

    cd out
    make
    ```

    ```
    $ cd <user-local>/trusted-firmware-m/out/bin
    $ ls
        tfm_ns.axf  tfm_ns.elf  tfm_ns.map  tfm_s.bin  tfm_s.hex
        tfm_ns.bin  tfm_ns.hex  tfm_s.axf   tfm_s.elf  tfm_s.map
    ```

# Qemu

+ Create `z_qemu_server.sh`

    ```
    #!/bin/bash

    TARGET_SECU="<user-local>/trusted-firmware-m/out/bin/tfm_s.elf"
    TARGET_NON_SECU="<user-local>/trusted-firmware-m/out/bin/tfm_ns.bin"

    qemu-system-arm \
        -M mps2-an521 \
        -kernel ${TARGET_SECU} \
        -device loader,file=${TARGET_NON_SECU},addr=0x00100000 \
        -nographic -s -S
    ```


+ Create `z_qemu_gdb.sh` (not work..)

    ```bash
    #!/bin/bash

    TARGET_SECU=<user-local>/trusted-firmware-m/out/bin/tfm_s.elf
    TARGET_NON_SECU=<user-local>/trusted-firmware-m/out/bin/tfm_ns.elf

    cgdb -d gdb-multiarch ${TARGET_SECU} \
        -ex "target remote:1234" \
        -ex "add-symbol-file ${TARGET_NON_SECU}" \
        -ex "b tfm_ns_platform_init"
    ```


# Reference

+ [Trusted Firmware-M Documentation — Trusted Firmware-M Unknown documentation](https://trustedfirmware-m.readthedocs.io/en/latest/index.html)
    - [Building default configuration for an521](https://trustedfirmware-m.readthedocs.io/en/latest/building/tfm_build_instruction.html#building-default-configuration-for-an521)

+ [Understanding ARM Trusted Firmware using QEMU](https://lnxblog.github.io/2020/08/20/qemu-arm-tf.html)
+ [ARM Trusted Firmware-M (TF-M): build and run on QEMU - YouTube](https://www.youtube.com/watch?v=Tn9O44ur_xs)

+ MCUboot
    - [MCUboot | mcuboot](https://docs.mcuboot.com/)
    - [GitHub - STMicroelectronics/stm32-mw-mcuboot: MCUboot is an OS- and HW-independent secure bootloader for 32-bit MCUs aiming at defining a common infrastructure for the bootloader and the system flash layout on microcontroller systems, and at providing a secure bootloader that enables simple software upgrades. · GitHub](https://github.com/STMicroelectronics/stm32-mw-mcuboot/tree/main)
