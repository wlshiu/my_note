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
tmp1_file=___tmp1

mem_areas=(
    # start, end
    '0x00000000' '0x00020000' # ilm
    '0x00100000' '0x00120000' # dlm
    '0x60000000' '0x60040000' # bus ram
    '0xD9000000' '0xD9004000' # retention ram
    # '0x30000000' '0x30200000' # flash
)

colors=(
    "\x1b[31m"
    "\x1b[32m"
    "\x1b[33m"
    "\x1b[34m"
    "\x1b[35m"
    "\x1b[36m"
    "\x1b[37m"
)

echo -e "#!/usr/bin/env python3\n" > t.py
echo -e "import sys\n" >> t.py

echo -n "mem_areas=[" >> t.py

area_cnt=${#mem_areas[@]}
for ((i = 0; i < $area_cnt; i += 2));do
    echo -n "[${mem_areas[$i]}, ${mem_areas[(($i + 1))]}]," >> t.py
done

echo -n "]" >> t.py
echo -e "\n\n" >> t.py

cat >> t.py << EOF
in_file = "${tmp_file}"
def print_range(message, end = '\n'):
    sys.stdout.write(message.strip() + end)

def display(prefix, total_size, start, length, width=60, file=sys.stdout):
    nTotal_size = int(total_size, 16)
    nStart      = int(start, 16)
    nEnd        = nStart + int(length, 16)
    pos_s = int(width * nStart / nTotal_size)
    pos_e = int(width * nEnd / nTotal_size)
    file.write("=> \x1b[1;32m%s[%s%s%s]\x1b[0m\n" % (prefix, "."*pos_s, "#"*(pos_e - pos_s), "."*(width - pos_e)))
    file.flush()

mem_areas_idx = -1

for line in open(in_file):
    d = line.split(', ')
    start_addr = int(d[0], 16)
    end_addr   = start_addr + int(d[1], 16)
    for i in range(len(mem_areas)):
        if (start_addr >= mem_areas[i][0]) and (start_addr < mem_areas[i][1] ):
            if mem_areas_idx != i:
                print("\n\n\x1b[36m ===== AREA: 0x%08x ~ 0x%08x ====\x1b[0m" %(mem_areas[i][0], mem_areas[i][1]))
                mem_areas_idx = i
            print_range('0x%08x ~ 0x%08x (size=%d)\t\t%s' % (start_addr, end_addr, int(d[1], 16), d[2]))
            display("", '0x20000', hex(start_addr - int(hex(mem_areas[i][0]), 16)), d[1], 100)

# class Color:
#     # Foreground
#     F_Default = "\x1b[39m"
#     F_Black = "\x1b[30m"
#     F_Red = "\x1b[31m"
#     F_Green = "\x1b[32m"
#     F_Yellow = "\x1b[33m"
#     F_Blue = "\x1b[34m"
#     F_Magenta = "\x1b[35m"
#     F_Cyan = "\x1b[36m"
#     F_LightGray = "\x1b[37m"
#     F_DarkGray = "\x1b[90m"
#     F_LightRed = "\x1b[91m"
#     F_LightGreen = "\x1b[92m"
#     F_LightYellow = "\x1b[93m"
#     F_LightBlue = "\x1b[94m"
#     F_LightMagenta = "\x1b[95m"
#     F_LightCyan = "\x1b[96m"
#     F_White = "\x1b[97m"
EOF

echo -n "" > ${tmp_file}
echo -n "" > ${tmp1_file}
for ((i = 0 ; i < $# ; i++));
do
    out_elf=out.elf
    in_elf=${args[$i]}

    #########
    ## trim debug section
    ${OBJCOPY} -S -R .comment -R .shstrtab ${in_elf} ${out_elf}
    ${READELF} -S ${out_elf} | grep '[ ]*\[[ 0-9]*\][ ][.]' | awk -F'] ' '{print $2}' | \
        awk '{print "0x"$3, "0x"$5, $1}' | xargs printf "%08x, %x, %s(${colors[$(($i % 7))]}${in_elf}\x1b[0m)\n" >> ${tmp1_file}

    rm -f ${out_elf}
done

cat ${tmp1_file} | awk -F", " '{print "0x"$1, "0x"$2, $3}' | xargs printf "%08x, %x, %s\n" | sort > ${tmp_file}

python3 t.py


rm -f t.py
rm -f ${tmp_file}
rm -f ${tmp1_file}


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
