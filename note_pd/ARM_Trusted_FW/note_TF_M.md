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
    ```

+ download source code

    - SPE (Secure Processing Environment)

        ```
        $ git clone https://git.trustedfirmware.org/TF-M/trusted-firmware-m.git
        $ git checkout TF-Mv2.2.2  # use GNU Arm Embedded Toolchain 10.3-2021.10
        ```

    - NSPE (Non Secure Processing Environment)

        ```
        $ git clone https://git.trustedfirmware.org/TF-M/tf-m-tests.git
        ```

+ [Building TF-M (SPE)](https://trustedfirmware-m.readthedocs.io/en/latest/building/tfm_build_instruction.html#building-tf-m-spe)

    - Create `z_build.sh`
        > use default `ARM-AN521` platform
        >
        > ```
        > .../trusted-firmware-m/platform/ext/target/arm
        >     ├── corstone1000
        >     ├── drivers
        >     ├── mps2
        >     ├── mps3
        >     ├── mps4
        >     ├── musca_b1
        >     ├── musca_s1
        >     └── rse
        > ```

        ```
        #!/bin/bash

        set -e

        #
        # -S: source code directory
        # -B (--build): output directory
        #
        cmake -S . -B out \
            -DTFM_PLATFORM=arm/mps2/an521 \
            -DTFM_TOOLCHAIN_FILE=toolchain_GNUARM.cmake \
            -DCMAKE_BUILD_TYPE=Debug \
            -GNinja

        cmake --build out -- install
        ```

+ [Building Application (NSPE)](https://trustedfirmware-m.readthedocs.io/en/latest/building/tests_build_instruction.html)

    - Create `z_build_tfm_tests.sh`
        > `$ cd <user-local>/tf-m-tests/tests_reg`

        ```bash
        #!/bin/bash

        TFM_SRC_PATH=<user-local>/trusted-firmware-m/
        TFM_TEST_SRC_PATH=<user-local>/tf-m-tests/

        cd ${TFM_TEST_SRC_PATH}/tests_reg

        cmake -S spe -B ./out_spe -DTFM_PLATFORM=arm/mps2/an521 \
              -DCONFIG_TFM_SOURCE_PATH=${TFM_SRC_PATH} \
              -DTFM_TOOLCHAIN_FILE=${TFM_SRC_PATH}/toolchain_GNUARM.cmake \
              -DCMAKE_BUILD_TYPE=Debug \
              -DTEST_S=ON -DTEST_NS=ON
        cmake --build ./out_spe -- install


        cmake -S . -B ./out_test -DCONFIG_SPE_PATH=${TFM_TEST_SRC_PATH}/tests_reg/out_spe/api_ns/ \
              -DTFM_TOOLCHAIN_FILE=${TFM_TEST_SRC_PATH}/tests_reg/out_spe/api_ns/cmake/toolchain_ns_GNUARM.cmake \
              -DCMAKE_BUILD_TYPE=Debug
        cmake --build out_test
        ```

# Qemu

+ Create `z_qemu_server.sh`

    ```
    #!/bin/bash

    TARGET_SECU=<user-local>/tf-m-tests/tests_reg/out_spe/bin/tfm_s.elf
    TARGET_NON_SECU=<user-local>/tf-m-tests/tests_reg/out_test/bin/tfm_ns.elf


    qemu-system-arm \
        -M mps2-an521 \
        -cpu cortex-m33 -m 16M \
        -kernel ${TARGET_SECU} \
        -device loader,file=${TARGET_NON_SECU},addr=0x00100000 \
        -nographic \
        -s -S
    ```


+ Create `z_qemu_gdb.sh` (not work..)

    ```bash
    #!/bin/bash

    TARGET_SECU=<user-local>/tf-m-tests/tests_reg/out_spe/bin/tfm_s.elf

    # arm-none-eabi-gdb ${TARGET_SECU} -ex "target remote:1234" -tui

    cgdb -D arm-none-eabi-gdb ${TARGET_SECU} -ex "target remote:1234"
    ```

# Example

- bakcup flow
    ```
    $ cd <local-root>/trusted-firmware-m

    $ cmake -S . -B out \
        -DTFM_PLATFORM=arm/mps2/an521 \
        -DTFM_TOOLCHAIN_FILE=toolchain_GNUARM.cmake \
        -DCMAKE_BUILD_TYPE=Debug \
        -DTEST_NS=ON \
        -DTEST_S=ON \
        -DTFM_PSA_API=ON \
        -DBL2=OFF

    $ cd out && make

    $ arm-none-eabi-readelf -l bin/tfm_ns.elf
    $ arm-none-eabi-readelf -l bin/tfm_s.elf

    $ qemu-system-arm \
        -M mps2-an521 \
        -kernel "bin/tfm_s.elf" \
        -device loader,file="bin/tfm_ns.bin",addr=0x00100000 \
        -nographic \
        -s -S

    # In a new terminal
    $ cgdb -D arm-none-eabi-gdb bin/tfm_s.elf
    ```

# Reference

+ [Trusted Firmware-M Documentation — Trusted Firmware-M Unknown documentation](https://trustedfirmware-m.readthedocs.io/en/latest/index.html)
    - [Building default configuration for an521](https://trustedfirmware-m.readthedocs.io/en/latest/building/tfm_build_instruction.html#building-default-configuration-for-an521)

+ [Understanding ARM Trusted Firmware using QEMU](https://lnxblog.github.io/2020/08/20/qemu-arm-tf.html)

+ MCUboot
    - [MCUboot | mcuboot](https://docs.mcuboot.com/)
    - [GitHub - STMicroelectronics/stm32-mw-mcuboot: MCUboot is an OS- and HW-independent secure bootloader for 32-bit MCUs aiming at defining a common infrastructure for the bootloader and the system flash layout on microcontroller systems, and at providing a secure bootloader that enables simple software upgrades. · GitHub](https://github.com/STMicroelectronics/stm32-mw-mcuboot/tree/main)
