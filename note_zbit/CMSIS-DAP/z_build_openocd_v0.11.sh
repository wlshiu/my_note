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


