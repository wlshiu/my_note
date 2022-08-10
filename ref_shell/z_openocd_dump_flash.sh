#!/bin/sh
# Copyright (c) 2022, All Rights Reserved.
# @file    z_openocd_dump_flash.sh
# @author  Wei-Lun Hsu
# @version 0.1


OPENOCD=./bin/openocd.exe

help()
{
    echo -e "usage: $0 <flash address> <bytes> <out bin>"
    exit -1
}

if [ $# != 3 ]; then
    help
fi

start_addr=$1
nbytes=$2
out_file=$3


argv="flash read_bank 0 ${out_file} ${start_addr} ${nbytes}"

${OPENOCD} -s ./share/openocd/scripts -f interface/cmsis-dap.cfg -f target/zb32l03xx.cfg -c init -c "reset halt" -c "${argv}" -c shutdown
