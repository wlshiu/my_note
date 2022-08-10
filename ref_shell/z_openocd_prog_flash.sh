#!/bin/sh
# Copyright (c) 2022, All Rights Reserved.
# @file    z_openocd_flash.sh
# @author  Wei-Lun Hsu
# @version 0.1

OPENOCD=./bin/openocd.exe

help()
{
    echo -e "usage: $0 <address> <target bin>"
    exit -1
}

if [ $# != 2 ]; then
    help
fi

start_addr=$1
in_file=$2

argv="program ${in_file} ${start_addr} verify reset exit;"

${OPENOCD} -s ./share/openocd/scripts -f interface/cmsis-dap.cfg -f target/zb32l03xx.cfg -c "${argv}"

