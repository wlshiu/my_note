#!/bin/bash


if [ -d build ]; then
    rm -fr ./build
fi

root_dir=`pwd`

mkdir build
cd build
mkdir install

#
# + `-march=rv32imafdc -mabi=ilp32d`
#   > Hardware floating-point instructions can be generated and floating-point arguments are passed in registers.
#     This is like the -mfloat-abi=hard option to Arm's GCC.
# + `-march=rv32imac -mabi=ilp32`
#   > No floating-point instructions can be generated and no floating-point arguments are passed in registers.
#     This is like the `-mfloat-abi=soft` argument to Arm's GCC.
# + `-march=rv32imafdc -mabi=ilp32`
#   > Hardware floating-point instructions can be generated, but no floating-point arguments will be passed in registers.
#     This is like the `-mfloat-abi=softfp` argument to Arm's GCC,
#       and is usually used when interfacing with soft-float binaries on a hard-float system.
# + `-march=rv32imac -mabi=ilp32d`
#   > Illegal, as the ABI requires floating-point arguments are passed in registers but the ISA defines no floating-point registers to pass them in.
#

#
# RV32 basic profile
# $ ../configure --prefix=.../riscv-gnu-toolchain/build/install --disable-linux --with-arch=rv32imac --with-abi=ilp32
# $ make
#


#
# `-mcmodel` 對 RV32 沒什麼影響, 對 RV64 有影響.
# 不指定 -mcmodel 的情況下, 默認是 medlow.
# 對於 RV32, 不用刻意指定 -mcmodel, 因為無論是 -mcmodel=medlow 還是 -mcmodel=medany 都能訪問全部的 4GiB 地址空間
#
#


../configure --prefix==$root_dir/build/install --with-arch=rv32gc --with-abi=ilp32 --with-cmodel=medlow \
    --target=riscv32-wl-elf \
    --with-binutils-src \
    --with-gcc-src \
    --with-gdb-src \
    --with-glibc-src \
    --with-linux-headers-src \
    --with-musl-src \
    --with-newlib-src \
    --with-qemu-src \
    --with-spike-src

# ?? use bash script it will issue fail, but type to terminal it's ok...
# make

# make musl # only support rv64...

make newlib
make linux



cd $root_dir
