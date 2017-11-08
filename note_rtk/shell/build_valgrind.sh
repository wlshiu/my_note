#!/bin/bash -
#===============================================================================
# Copyright (c) 2017, Wei-Lun Hsu
#
#          FILE: build.sh
#
#         USAGE: ./build.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#        AUTHOR: Wei-Lun Hsu (WL), 
#       CREATED: 10/27/2017
#       LICENSE: GNU General Public License
#      REVISION:  ---
#===============================================================================

set -e

#toolcahin_prefix=$HOME/toolchain/arm-linux-gnueabi-5.4.1/bin/arm-linux-gnueabi-
toolcahin_prefix=$HOME/toolchain/roku-toolchain-4.9.2/bin/arm-brcm-linux-gnueabi-

install_path=$HOME/tmp/bin
./configure --host=armv7-linux CC=${toolcahin_prefix}gcc LD=${toolcahin_prefix}ld RANLIB=${toolcahin_prefix}ranlib CFLAGS="-static" --prefix=${install_path}

make
make install

