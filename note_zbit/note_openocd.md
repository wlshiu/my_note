Open OCD
---

# Source code

## build source Cygwin (verified)

[Cygwin-64](https://www.gushiciku.cn/jump/aHR0cHM6Ly93d3cub3NjaGluYS5uZXQvYWN0aW9uL0dvVG9MaW5rP3VybD1odHRwcyUzQSUyRiUyRmN5Z3dpbi5jb20lMkZzZXR1cC14ODZfNjQuZXhl)
> + select `Install from Internet`
> + select `Use System Proxy Setting`

+ dependency
    > use `setup-x86_64.exe` to intall packages

    - autobuild
    - autoconf (all packages)
    - autoconf-archive
    - automake (all packages)
    - dos2unix
    - git
    - gcc-core
    - gcc-g++
    - libtool
    - libusb1.0
    - libusb1.0-devel
    - libusb-devel
    - libhidapi-devel (for cmsis-dap)
    - wget
    - make
    - pkg-config
    - Usbutils
    - patch
    - mingw64-x86_64-pthreads
    - mingw64-x86_64-winpthreads

+ Building

    ```shell
    $ git clone https://git.code.sf.net/p/openocd/code  openocd
    $ cd openocd
    $ git checkout f342aa   # released v0.11
    $ ./bootstrap
    $ mkdir build && cd build
    $ ../configure --disable-werror \
        --disable-aice --disable-ti-icdi \
        --disable-osbdm --disable-opendous \
        --disable-vsllink --disable-usbprog \
        --disable-rlink --disable-armjtagew \
        --disable-usb-blaster-2 \
        --enable-ftdi --enable-jlink --enable-stlink --enable-cmsis-dap
    $ make
    $ make install
    ```

+ Cygwin dll

    ```
    cp usr/bin/cygftdi1-2.dll         ~/my_openocd/bin/cygftdi1-2.dll
    cp usr/bin/cyghidapi-0.dll        ~/my_openocd/bin/cyghidapi-0.dll
    cp usr/bin/cygncursesw-10.dll     ~/my_openocd/bin/cygncursesw-10.dll
    cp usr/bin/cygusb-1.0.dll         ~/my_openocd/bin/cygusb-1.0.dll
    cp usr/bin/cygusb0.dll            ~/my_openocd/bin/cygusb0.dll
    cp usr/bin/cygwin1.dll            ~/my_openocd/bin/cygwin1.dll
    ```

+ Run OpenOCD server

    - `z_run_ocd_server.sh` **shell file**

        ```shell
        #!/bin/bash

        openocd -f interface/cmsis-dap.cfg -f target/stm32f1x.cfg
        ```

    - `z_run_ocd_server.bat` **batch file**
        > use **absolute path**
        >>

        ```
        > .\bin\openocd.exe -f C:\OpenOCD\share\openocd\scripts\interface\cmsis-dap.cfg -f C:\OpenOCD\share\openocd\scripts\target\stm32f1x.cfg
        ```

        1. path
            > `C:\OpenOCD\share\openocd\scripts\target\stm32f1x.cfg`

            ```
            source [find target/swj-dp.tcl]
            source [find mem_helper.tcl]

                modify to absolute path

            source [find C:/OpenOCD/share/openocd/scripts/target/swj-dp.tcl]
            source [find C:/OpenOCD/share/openocd/scripts/mem_helper.tcl]
            ```

## build source MSYS2

+ dependency

    ```bash
    $ pacman -S autoconf automake make pkg-config libtool git
    ```

+ build script
    > v0.11

    ```bash
    #!/bin/bash


    export LIBUSB1_CFLAGS="-I$HONE/OpenOCD/openocd/libusb-1.0.24/include"
    export LIBUSB1_LIBS="-L$HONE/OpenOCD/openocd/libusb-1.0.24 -lusb-1.0 -lpthread"

    export LIBUSB_1_0_CFLAGS="-I$HONE/OpenOCD/openocd/libusb-1.0.24/include"
    export LIBUSB_1_0_LIBS="-L$HONE/OpenOCD/openocd/libusb-1.0.24 -lusb-1.0 -lpthread"

    export LIBUSB0_CFLAGS="-I$HONE/OpenOCD/openocd/libusb-1.0.24/include"
    export LIBUSB0_LIBS="-L$HONE/OpenOCD/openocd/libusb-1.0.24 -lusb-1.0 -lpthread"
    export LIBUSB1_CFLAGS="-I$HONE/OpenOCD/openocd/libusb-1.0.24/include"
    export LIBUSB1_LIBS="-L$HONE/OpenOCD/openocd/libusb-1.0.24 -lusb-1.0 -lpthread"
    # export HIDAPI_CFLAGS="-I$HIDAPI_DIR/hidapi/"
    # export HIDAPI_LIBS="-L$HIDAPI_DIR/windows/.libs/ -L$HIDAPI_DIR/libusb/.libs/ -lhidapi"
    export CFLAGS="-DHAVE_LIBUSB_ERROR_NAME"


    export CPPFLAGS="$CPPFLAGS -D__USE_MINGW_ANSI_STDIO=1 -Wno-error"
    export CFLAGS="$CFLAGS -static -Wno-error"

    ./bootstrap
    export PKG_CONFIG_PATH=`pwd`
    ./configure --build=i686-w64-mingw32 --host=i686-w64-mingw32 --disable-werror --enable-static --enable-cmsis-dap --enable-cmsis-dap-v2 \
    --disable-doxygen-pdf --enable-ftdi --enable-jlink --enable-ulink --prefix=$HOME/OpenOCD/openocd/out

    make clean
    make
    ```

## reference

+ [OpenOCD-build-script](https://github.com/arduino/OpenOCD-build-script/tree/static)
+ [Building OpenOCD from Sources for Windows](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/jtag-debugging/building-openocd-windows.html)
+ [*如何搭建OpenOCD環境基於Window10+Cygwin?](https://www.gushiciku.cn/pl/gYov/zh-tw)
+ [系統架構秘辛：瞭解RISC-V 架構底層除錯器的秘密！ :: 2018 iT 邦幫忙鐵人賽](https://ithelp.ithome.com.tw/users/20107327/ironman/1359?page=3)
+ [Day 02: 簡介OpenOCD背景與編譯 - iT 邦幫忙::一起幫忙解決難題，拯救 IT 人的一天](https://ithelp.ithome.com.tw/articles/10192529)
+ [Day 05: OpenOCD 軟體架構 - iT 邦幫忙::一起幫忙解決難題，拯救 IT 人的一天](https://ithelp.ithome.com.tw/articles/10193390)
+ [Day 06: \[Lab\] 簡簡單單新增OpenOCD Command - iT 邦幫忙::一起幫忙解決難題，拯救 IT 人的一天](https://ithelp.ithome.com.tw/articles/10193537)
+ [Day 23: 您不可不知的FT2232H (1/3) - Overview - iT 邦幫忙::一起幫忙解決難題，拯救 IT 人的一天](https://ithelp.ithome.com.tw/articles/10196693)
+ [Day 27: 高手不輕易透露的技巧(1/2) - Flash Programming - iT 邦幫忙::一起幫忙解決難題，拯救 IT 人的一天](https://ithelp.ithome.com.tw/articles/10197190)
+ [Day 28: 高手不輕易透露的技巧(2/2) - Flash Driver & Target Burner - iT 邦幫忙::一起幫忙解決難題，拯救 IT 人的一天](https://ithelp.ithome.com.tw/articles/10197309)
+ [Day 29: 深藏不露的GDB - Remote Serial Protocol的秘密 - iT 邦幫忙::一起幫忙解決難題，拯救 IT 人的一天](https://ithelp.ithome.com.tw/articles/10197385)

# Embitz

Use Absolute path

+ Setting openocd with `Generic`
    > `Debug` -> `interfaces`

    - Target settings

        1. enable `Try to stopat valid source info`

    - GDB server

        1. Selected interface
            > Generic

        1. Ip address
            > localhost

        1. Port
            > 3333

        1. GDB server
            > + Path
            >> C:\OpenOCD-20210625-0.11.0

            > + executable
            >> z_ocd_server.bat

            ```batch
            rem  z_ocd_server.bat
            C:\OpenOCD-0.11.0\bin\openocd -f C:\OpenOCD-0.11.0\share\openocd\scripts\interface\cmsis-dap.cfg -f C:\OpenOCD-0.11.0\share\openocd\scripts\target\stm32f1x.cfg
            ```

            > + backoff time
            >> 1000

            > + `Settings`
            >> `Connect/Reset`

            ```
            monitor reset halt
            ```

    - GDB additionals

        1. after connect

            ```
            monitor reset halt
            monitor stm32f1x mass_erase 0
            load
            monitor reset halt
            ```

+ Setting openocd with `OpenOCD`
    > `Debug` -> `interfaces`

    - GDB server

        1. Selected interface
            > OpenOCD

        1. Ip address
            > localhost

        1. Port
            > 3333

        1. GDB server
            > + `Browse`
            >> select the OpenOCD with `Absolute Path`

            > + backoff time
            >> 1000

            > + `Settings`
            >> `Additional arguments OpenOCD`

            ```
            -f C:\OpenOCD-0.11.0\share\openocd\scripts\interface\cmsis-dap.cfg -f C:\OpenOCD-0.11.0\share\openocd\scripts\target\stm32f1x.cfg
            ```

    - GDB additionals

        1. after connect

            ```
            monitor reset halt
            # monitor stm32f1x mass_erase 0
            load
            # monitor reset halt
            ```

