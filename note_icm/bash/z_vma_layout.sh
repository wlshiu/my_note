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

if [ $# -le 0 ]; then
    help
fi

args=("$@")

READELF=arm-none-eabi-readelf
OBJDUMP=arm-none-eabi-objdump
OBJCOPY=arm-none-eabi-objcopy

tmp_file=___tmp

mem_areas=(
    # start, end
    '0x00000000' '0x00020000' # pram
    '0x00100000' '0x00200000' # prom
)

area_cnt=${#mem_areas[@]}
for ((i = 0; i < $area_cnt; i += 2));do
    echo "-${mem_areas[$i]} ~ ${mem_areas[(($i + 1))]}"
done

cat > t.py << EOF
#!/usr/bin/env python3

import sys

in_file = "${tmp_file}"

for line in open(in_file):
    d = line.split(', ')
    print('0x%s ~ 0x%08x\t\t%s' % (d[0], int(d[0], 16) + int(d[1], 10), d[2]), end = '')
EOF


for ((i = 0 ; i < $# ; i++));
do
    out_elf=out.elf
    in_elf=${args[$i]}

    #########
    ## trim debug section
    ${OBJCOPY} -S -R .comment -R .shstrtab ${in_elf} ${out_elf}
    ${READELF} -S ${out_elf} | grep '[ ]*\[[ 0-9]*\][ ][.]' | awk -F'] ' '{print $2}' | \
        awk '{print "0x"$3, "0x"$5, $1}' | xargs printf "%08x, %d, %s(${in_elf})\n" | sort > ${tmp_file}

    python3 t.py

    rm -f ${out_elf}
done


rm -f t.py
rm -f ${tmp_file}


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

