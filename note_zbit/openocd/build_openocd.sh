#!/bin/bash

# Parameter
# $1: build-dir (must)
# $2: source-dir (must)
# $3: 1 for checkout source code (must)
#   e.g.
#       $ ./build.sh build src 1 --> clone source code
#       $ ./build.sh build src   --> only build code
#


# How to run?
if [ $# -lt 2 ]; then
    echo "<Usage>: $0 build-dir source-dir [need_clone 0/1?]"
    exit 1
fi


# Param
BUILD_DIR=`readlink -f $1`
SOURCE_DIR=`readlink -f $2`
UNAMESTR=`uname`

# Setup Source path
LIBUSB_SRC_1=$SOURCE_DIR/libusb-1.0.18
OPENOCD_SRC=$SOURCE_DIR/openocd


# Clean build/source folder
rm -rf $BUILD_DIR


# Clone source or not
if [ "$3" == '1' ]; then
    CLONE_FLAG="--recursive"

    rm -rf $SOURCE_DIR
    wget https://ncu.dl.sourceforge.net/project/libusb/libusb-1.0/libusb-1.0.18/libusb-1.0.18.tar.bz2 -P $SOURCE_DIR --no-check-certificate
    git clone $CLONE_FLAG https://github.com/riscv/riscv-openocd.git $OPENOCD_SRC
else
    echo 'Do not clone openocd source codes'
fi


# Build libusb-1.0.18
printf "\n\n\nBuild libusb-1.0.18\n"
tar -jxf $SOURCE_DIR/libusb-1.0.18.tar.bz2 -C $SOURCE_DIR
mkdir -p $BUILD_DIR/build/libusb
cd $BUILD_DIR/build/libusb
$LIBUSB_SRC_1/configure --prefix=$BUILD_DIR/usr PKG_CONFIG_LIBDIR=$BUILD_DIR/usr/lib/pkgconfig --disable-shared --disable-udev --disable-timerfd
make install -j8


# Build RISC-V OpenOCD
printf "\n\n\nBuild OpenOCD\n"
cd $OPENOCD_SRC
patch -p1 < openocd.patch
./bootstrap
mkdir -p $BUILD_DIR/build/openocd
cd $BUILD_DIR/build/openocd
$OPENOCD_SRC/configure --prefix=$BUILD_DIR/usr PKG_CONFIG_LIBDIR=$BUILD_DIR/usr/lib/pkgconfig --disable-aice --disable-ti-icdi --disable-jlink --disable-osbdm --disable-opendous --disable-vsllink --disable-usbprog --disable-rlink --disable-ulink --disable-armjtagew --disable-usb-blaster-2 --enable-stlink --enable-ftdi
make -j8
make install-strip
