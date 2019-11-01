#!/bin/bash -
# Copyright (c) 2019, All Rights Reserved.
# @file    z_verify_prebuild_lib.sh
# @author  Wei-Lun Hsu
# @version 0.1

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
