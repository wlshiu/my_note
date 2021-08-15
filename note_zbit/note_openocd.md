Open OCD
---

# Source code

## build source

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

