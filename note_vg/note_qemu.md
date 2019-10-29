Qemu
---

# Ubuntu 18.04

+ dependency

    ```shell
    $ sudo apt install librados2=12.2.4-0ubuntu1
    $ sudo apt-get install librbd1
    $ sudo apt-get install qemu-block-extra
    $ sudo apt-get install qemu-system-common
    $ sudo apt-get install qemu-system-arm
    ```

    - switch gcc version

    ```shell
    #!/bin/bash -

    set -e

    help()
    {
        echo "usage: $0 [ver-number]"
        echo "  e.g. $0 4.9"
        echo "  e.g. $0 7"
        exit 1;
    }

    if [ $# != 1 ]; then
        help
    fi

    case $1 in
        "7")
            sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 73 \
                --slave /usr/bin/g++ g++ /usr/bin/g++-7 \
                --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-7 \
                --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-7 \
                --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-7
            ;;
        "4.9")
            sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 49 \
                --slave /usr/bin/g++ g++ /usr/bin/g++-4.9 \
                --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-4.9 \
                --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-4.9 \
                --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-4.9
            ;;
    esac
    ```

+ check

    ```shell
    $ qemu-system-arm -machine -cpu help
    ```

+ example

    - [freertos-plus](https://github.com/embedded2014/freertos-plus)

        ```shell
        $ cd freertos-plus
        $ make
        $ cd build
        $ qemu-system-arm -M stm32-p103 -monitor stdio -kernel main.bin -semihosting
        ```

# Cross compile

+ qemu

    ```shell
    $ ./configure --target-list=arm-softmmu --prefix=$HOME/qemu-3.1.1.1/out/
    $ make
    $ make install
    $ ./out/bin/arm-system-arm -M vexpress-a9 -kernel u-boot -nographic -m 128M
    ```

    - [qemu-system-gnuarmeclipse](https://github.com/xpack-dev-tools/qemu-arm-xpack/releases/)
        > this qemu is for Cortex-M serial

    ```shell
    # -memory size=kb
    $ qemu-system-gnuarmeclipse --verbose \
        --board STM32F4-Discovery --mcu STM32F407VG \
        -d unimp,guest_errors \
        -memory size=512 \
        --nographic \
        --image hello_rtos.elf

    $ qemu-system-gnuarmeclipse --verbose --board STM32F4-Discovery \
      --mcu STM32F407VG --gdb tcp::1234 -d unimp,guest_errors \
      --semihosting-config enable=on,target=native \
      --semihosting-cmdline \
      --image hello_rtos.elf
    ```

    - reference
        1. [STM32F429_Discovery_FreeRTOS_9](https://github.com/cbhust/STM32F429_Discovery_FreeRTOS_9)

    ```shell
    # -m size=256 (SRAM = 256KB)
    $ qemu-system-gnuarmeclipse --verbose --verbose \
        --board STM32F429I-Discovery --mcu STM32F429ZI \
        -d unimp,guest_errors -m size=256 \
        --image hello_rtos.elf \
        --semihosting-config enable=on,target=native --semihosting-cmdline hello_rtos 1 2 3
    ```

+ u-boot (for test)

    ```shell
    $ wget ftp://ftp.denx.de/pub/u-boot/u-boot-2019.10.tar.bz2
    $ tar -xjf u-boot-2019.10.tar.bz2
    $ cd u-boot-2019.10
    $ vi ./Makefile
        # instert to top
        ARCH = arm
        CROSS_COMPILE = arm-none-eabi-

    $ make vexpress_ca9x4_defconfig
    $ make
    ```
