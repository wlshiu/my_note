#!/bin/bash
# Copyright (c) 2020, All Rights Reserved.
# @file    z_vma_layout.sh.sh
# @author  Wei-Lun Hsu
# @version 0.1

set -e

help()
{
    echo -e "usage: $0 <elf 1> <elf 2> ..."
    exit 1;
}

if [ $# -le 1 ]; then
    help
fi

args=("$@")

READELF=readelf
OBJDUMP=objdump


mem_areas=(
    # start, end
    '0x00000000' '0x00020000' # pram
    '0x00100000' '0x00200000' # prom
)

area_cnt=${#mem_areas[@]}
for ((i = 0; i < $area_cnt; i += 2));do
    echo "-${mem_areas[$i]} ~ ${mem_areas[(($i + 1))]}"
done


for ((i = 0 ; i < $# ; i++));
do
    elf_file=${args[$i]}
    # echo -e "$elf_file"

    #########
    ## trim debug section


done


# arr01=(0 '1 2')
# arr02=(4 '5 6')
# arr1=('arr01[@]' 'arr02[@]')
# arr=('arr1[@]')

# for elmv1 in "${arr[@]}"; do
    # for elmv2 in "${!elmv1}"; do
        # for elm in "${!elmv2}"; do
            # echo "<$elm>"
        # done
    # done
# done

