#!/bin/bash
# Copyright (c) 2020, All Rights Reserved.
# @file    z_base32.sh
# @author  Wei-Lun Hsu
# @version 0.1

Red='\e[0;31m'
Yellow='\e[1;33m'
Light_Gray='\e[0;37m'
White='\e[1;37m'
NC='\e[0m' # No Color

set -e

map_file=xip1.map
S=$(grep -n 'Memory Configuration' ${map_file} | awk -F ":" '{print $1}')
E=$(grep -n ' \*(\.comment)' ${map_file} | awk -F ":" '{print $1}')

sed -n ${S},${E}p ${map_file} > tmp.map

base_section_list=(
"text"
"rodata"
"bss"
)

proprietary_section_list=(
"fast_boot_code"
"prog_in_sram"
)

tag_list=(
"_fast_code_start"
"_fast_code_end"
)


rm -f tmp.csv
for sect in "${base_section_list[@]}"; do
    echo -e "$sect"
    grep '^[ ][.]'"$sect"'[.].*o)$' tmp.map | awk '{print $1",", $3",", $4}' >> tmp.csv
    grep -A 1 '^[ ][.]'"$sect"'[.][a-zA-Z0-9_]*$' tmp.map | grep -v '^[-][-]' | sed ':a;N;$!ba;s/\( [.]'"$sect"'[.a-zA-Z0-9_]*\)\n/\1 /g' | awk '{print $1",", $3",", $4}' >> tmp.csv
done

echo -e "\n\n${Yellow}Specific tag ${NC}"
i=0
for tag in "${tag_list[@]}"; do
    msg=$(grep "${tag}" tmp.map  | awk '{print $2,$1}' | xargs printf '%s = 0x%08x\n')

    if [ $i == "0" ]; then
        echo -e ${White} $msg ${NC}
    else
        echo -e ${Light_Gray} $msg ${NC}
    fi

    i=$((i ^ 1))
done


##############
## sort the symbol size with 'freertos' keyword
# $cat tmp.csv | grep -i 'freertos' | awk -F',' '{print $2, $1, $3}' | xargs printf "%d %s \t %s\n" | sort -n



##############################################################
# red='\e[1;31m%s\e[0m\n'
# green='\e[1;32m%s\e[0m\n'
# yellow='\e[1;33m%s\e[0m\n'
# blue='\e[1;34m%s\e[0m\n'
# magenta='\e[1;35m%s\e[0m\n'
# cyan='\e[1;36m%s\e[0m\n'
# printf "$green"   "This is a test in green"
# printf "$red"     "This is a test in red"
# printf "$yellow"  "This is a test in yellow"
# printf "$blue"    "This is a test in blue"
# printf "$magenta" "This is a test in magenta"
# printf "$cyan"    "This is a test in cyan"

