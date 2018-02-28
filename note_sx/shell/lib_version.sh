#!/bin/bash
# Copyright (c) 2018, All Rights Reserved.
# @file    make_defconfig.sh
# @author  Wei-Lun Hsu
# @version 0.1

set -e

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
NC='\e[0m'

help()
{
    echo -e "$0 [obj file] [pattern]"
    echo -e "    e.g. $0 lib_uart.a 9070"
    echo -e "         ps. disassemble:  .word   90701001"
    exit 1;
}

if [ $# != 2 ]; then
    help
fi

lib_name=$1
pattern=$2

value=`objdump.exe -d ${lib_name} | grep '.word' | grep ${pattern} | awk '{print $(NF)}' | xargs printf "%x\n"`

prefix=`echo ${value} | sed 's:\(....\):\1 :g' | awk '{print $1}'`
revision_num=`echo ${value} | sed 's:\(....\):\1 :g' | awk '{print $NF}'`

major_num=`echo ${revision_num} | sed 's:\(..\):\1 :g' | awk '{print $1}'`
revision_num=`echo ${revision_num} | sed 's:\(..\):\1 :g' | awk '{print $NF}'`

major_num=`echo ${major_num} | sed 's:\(.\):\1 :g' | awk '{print $1}'`
minor_num=`echo ${major_num} | sed 's:\(.\):\1 :g' | awk '{print $1}'`
echo -e "${Yellow}${lib_name} ver. ${prefix}.${major_num}.${minor_num}.${revision_num}${NC}"

