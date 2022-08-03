#!/bin/bash

help()
{
    echo -e "usage: $0 <elf file> <output file>"
    echo -e "   Generate a symdef file from an elf file"
    exit -1;
}

if [ $# != 2 ]; then
    help
fi

elf_file=$1
out_file=$2

#
# Only extract symbol type 'W', 'T', 'D'
#
# symdef context format:
#   symbol1 = 0x12345678;
#   symbol2 = 0x23456789;
#
arm-none-eabi-nm.exe -g ${elf_file} | grep -e "[0-9a-fA-F]* [WTD] [a-zA-Z0-9_]*$" | awk -F ' ' '{print $3 " = " $1 ";"}' > ${out_file}
