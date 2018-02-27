#!/bin/bash
# Copyright (c) 2018, Wei-Lun Hsu
# @file    prepare_sys.sh
# @author  Wei-Lun Hsu
# @version 0.1

set -e

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
Cyan='\e[0;36m'
NC='\e[0m' # No Color

help()
{
    echo -e "${Red}$0 [output name] [ignore list] ${NC}"
    exit 1;
}

if [ $# != 2 ]; then
    help
fi

out_sdk_name=$1

# pushd ..
# popd

project_root=`pwd`

out_path=${project_root}/${out_sdk_name}/

# find ./keil -type f -name '*.lib' -exec cp {} ../sdk/lib \;

if [ -d ${out_path} ]; then
    rm -fr ${out_path}
fi

mkdir ${out_path}

cd ..

# ls ./Kconfig | bsdcpio -pd ${out_path}
cp -f ./Kconfig ${out_path}/Kconfig

ls ./build/*.cmd | bsdcpio -pd ${out_path}
ls ./build/*.sh | bsdcpio -pd ${out_path}
rm -f ${out_path}/build/z_pack_release.sh
rm -f ${out_path}/build/prepare_lib.sh

## non-recursive
# find . -maxdepth 1 -type f

find ./build/keil/ -type d -iname 'lib*' -prune -o \
    -type f -name '*readme.md' -prune -o \
    -print | bsdcpio -pd ${out_path}

find ./doc -type f -name '*readme.md' -prune -o -type d -o -print | bsdcpio -pd ${out_path}
find ./platform/freertos/ -type d -name '*' -o -print | bsdcpio -pd ${out_path}
find ./project -type d -name '*' -o -print | bsdcpio -pd ${out_path}

find ./tool -type d -iname 'src*' -prune -o \
    -type f -name '*readme.md' -prune -o \
    -print | bsdcpio -pd ${out_path}

find ./sdk -type d -iname 'driver*' -prune -o \
    -type d -iname 'misc*' -prune -o \
    -type f -name '*readme.md' -prune -o \
    -print | bsdcpio -pd ${out_path}

find ./bsp -type f -name '*readme.md' -prune -o -type d -name '*' -o -print | bsdcpio -pd ${out_path}

# TODO: How to manager the private static libs version and create the link for keil IDE
# TODO: How to filter the target share open library
# TODO: need to filter wrong bsp of the chip


cd ./build

tar -cz -f ${out_sdk_name}.tar.gz ${out_sdk_name}
