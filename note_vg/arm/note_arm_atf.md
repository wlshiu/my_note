ARM ATF
---

# build

[GNU-A Downloads](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads)

## ATF

+ source code [arm-trusted-firmware](https://github.com/ARM-software/arm-trusted-firmware)

    - For AArch64

        ```
        $ export CROSS_COMPILE=<path-to-aarch64-gcc>/bin/aarch64-none-elf-
        ```

    - For AArch32

        ```
        $ export CROSS_COMPILE=<path-to-aarch32-gcc>/bin/arm-none-eabi-
        ```

+ setup environment

    ```
    $ vi setting.env
        export ARCH=aarch64     # default
        # export ARCH=aarch32
        export PATH=$HOME/toolchain/gcc-arm-9.2-2019.12-x86_64-aarch64-none-elf/bin/:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        export CROSS_COMPILE=aarch64-none-elf-
    ```

## Op-TEE

+ download code

    ```
    $ mkdir optee && cd optee
    $ repo init -u https://github.com/OP-TEE/manifest.git -m qemu_v8.xml -b 3.9.0
    $ repo sync
    ```

+ compile

    ```
    $ sudo apt-get install python-pip
    $ sudo apt-get install uuid-dev iasl
    $ pip3 install pycryptodomex
    $ cd optee/build
    $ make -f toolchain.mk toolchains   # download toolchain

    $ ARCH=arm make
        or
    $ ARCH=arm make -j `nproc`

    $ make -f qemu.mk run-only # need x11 (UI) server
    ```

# reference

+ [**ARM Trusted Firmware User Guide](https://chromium.googlesource.com/chromiumos/third_party/arm-trusted-firmware/+/v1.1-rc0/docs/user-guide.md)
+ [Trusted Firmware-A Documentation](https://trustedfirmware-a.readthedocs.io/en/latest/index.html)
+ [使用QEMU調試ARM Trust Firmware, UEFI和Linux kernel](http://joyxu.github.io/2018/10/08/%E4%BD%BF%E7%94%A8QEMU%E8%B0%83%E8%AF%95ARM-Trust-Firmware-UEFI%E5%92%8CLinux-kernel/)
+ [使用Qemu運行ARMv8的OP-TEE](https://blog.csdn.net/dddddttttt/article/details/80792762)
+ [**0.使用Qemu運行OP-TEE](https://blog.csdn.net/shuaifengyun/article/details/71499619)
+ [trustzone與OP-TEE介紹導讀](https://www.twblogs.net/a/5b855f212b71775d1cd2a35f)