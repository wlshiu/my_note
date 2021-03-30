#!/bin/bash
# Copyright (c) 2020, All Rights Reserved.
# @author  Wei-Lun Hsu
# @version 0.1

#
# Line end MUST be 'LF'
# $ sudo apt-get install python-openpyxl  # python2
# $ sudo apt-get install python3-openpyxl
#

Red='\e[0;31m'
Yellow='\e[1;33m'
Light_Gray='\e[0;37m'
White='\e[1;37m'
NC='\e[0m' # No Color

set -e

help()
{
    echo -e "usage: $0 <map file> <csv file>"
    exit 1;
}

if [ $# != 2 ]; then
    help
fi

map_file=$1
csv_tmp_file=tmp2.csv
csv_file=$2
S=$(grep -n 'Memory Configuration' ${map_file} | awk -F ":" '{print $1}')
E=$(grep -n ' \*(\.comment)' ${map_file} | awk -F ":" '{print $1}')

sed -n ${S},${E}p ${map_file} > tmp.map

base_section_list=(
"text"
"rodata"
"data"
"data1"
"bss"
)

proprietary_section_list=(
"vector"
"init"
"scommon_b"
"scommon_w"
)

tag_list=(
"__data_lmastart"
"__data_start"
"__data_end"
"__bss_start"
"__bss_end"
)


# rm -f tmp.csv
# echo "Symbol, vma(dec), size(dec), src object" > ${csv_tmp_file}
for sect in "${base_section_list[@]}"; do
    echo -e "$sect"
    grep '^[ ][.]'"$sect"'[.].*\.o[)]*$' tmp.map | awk '{print $1, $2, $3, $4}'  >> ${csv_tmp_file}
    grep -A 1 '^[ ][.]'"$sect"'[.][a-zA-Z0-9_\.]*$' tmp.map | grep -v '^[-][-]' | sed ':a;N;$!ba;s/\( [.]'"$sect"'[\.a-zA-Z0-9_]*\)\n/\1 /g' | awk '{print $1, $2, $3, $4}'  >> ${csv_tmp_file}
    grep '^[ ][.]'"$sect"'[ ]*0x[0-9a-fA-F]*[ ]*.*o[)]*$' tmp.map | awk '{print $1, $2, $3, $4}'  >> ${csv_tmp_file}
done

for sect in "${proprietary_section_list[@]}"; do
    echo -e "$sect"
    grep '^[ ][.]'"$sect"'.*\.o[)]*$' tmp.map | awk '{print $1, $2, $3, $4}'  >> ${csv_tmp_file}
    grep -A 1 '^[ ][.]'"$sect"'$' tmp.map | grep -v '^[-][-]' | sed ':a;N;$!ba;s/\( [.]'"$sect"'[\.a-zA-Z0-9_]*\)\n/\1 /g' | awk '{print $1, $2, $3, $4}'  >> ${csv_tmp_file}
done

echo -e "COMMON"
grep '^[ ]COMMON.*\.o[)]*$' tmp.map | awk '{print $1, $2, $3, $4}'  >> ${csv_tmp_file}
grep -A 1 '^[ ]COMMON$' tmp.map | grep -v '^[-][-]' | sed ':a;N;$!ba;s/\( COMMON[\.a-zA-Z0-9_]*\)\n/\1 /g' | awk '{print $1, $2, $3, $4}'  >> ${csv_tmp_file}

# echo -e "fill"
# grep '^[ ]\*fill\*' tmp.map | awk '{print $1, $2, $3}'  >> ${csv_tmp_file}

# sed -i 's/0x//g' ${csv_tmp_file}


cat > t.py << EOF
#!/usr/bin/python3

"""
hex color:
https://www.sioe.cn/yingyong/yanse-rgb-16/
"""

import sys
import argparse
from openpyxl import Workbook
from openpyxl.styles import PatternFill

parser = argparse.ArgumentParser()
parser.add_argument("-o", "--Output", type=str, help="output xlsx file")
parser.add_argument("-i", "--Input", type=str, help="input map csv file")

args = parser.parse_args()

if args.Input:
    input_file = args.Input
else:
    sys.stdout.write("use '-h' to check usage")
    sys.exit(-1)

target_patt = [ ['boot', 'FBD5B5'],
                ['sys', 'B7DDE8'],
                ['driver', 'FFFF99']]

wb = Workbook()
ws = wb.active

for line in open(input_file):
    for i in range(len(target_patt)):
        cur_patt = target_patt[i]
        if cur_patt[0] in line:
            item = line.split(' ')
            ws.append([item[1].replace('0x', ''), item[0], int(item[2].replace('0x', ''), 16), item[3]])
            fill = PatternFill("solid", fgColor=target_patt[i][1])
            ws.cell(row=ws.max_row, column=4).fill = fill


wb.save('create_sample.xlsx')

EOF

chmod +x t.py

./t.py -i ${csv_tmp_file} -o out.xlsx

echo -e "\n\n${Yellow}Specific tag ${NC}"
i=0
for tag in "${tag_list[@]}"; do
    msg=$(grep "${tag}"'[ = ]' tmp.map  | awk '{print $2,$1}' | xargs printf '%s = 0x%08x\n')

    if [ $i == "0" ]; then
        echo -e ${White} $msg ${NC}
    else
        echo -e ${Light_Gray} $msg ${NC}
    fi

    i=$((i ^ 1))
done

rm -f tmp.map
rm -f ${csv_tmp_file}
rm -f t.py

grep --color -inH '__vma_' ${map_file}
