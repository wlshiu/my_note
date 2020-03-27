#!/bin/bash

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
Cyan='\e[0;36m'
NC='\e[0m' # No Color

set -e

help()
{
    echo -e "${Yellow}$0 [gcc map file] ${NC}"
    exit 1
}

if [ $# != 1 ]; then
    help
fi


patt_list=(
    "^ .vectors: __Vectors: __Vectors_end__"
    "^.text: __text_start__: __text_end__"
    "^.data: __data_start__: __data_end__"
    "^.bss: __bss_start__: __bss_end__"
)

gcc_map=$1
__tmp=cut.tmp

S=`grep -n "Memory Configuration" ${gcc_map} | awk -F ":" '{print $1}'`
E=`grep -n "OUTPUT(" ${gcc_map} | awk -F ":" '{print $1}'`

sed -n ${S},${E}p ${gcc_map} > ${__tmp}

for patt in "${patt_list[@]}" ; do
    section_name=`echo ${patt} | awk -F ":" '{print $1}'`
    tag_start=`echo ${patt} | awk -F ":" '{print $2}'`
    tag_end=`echo ${patt} | awk -F ":" '{print $3}'`

    grep "${section_name}" ${__tmp} | awk '{printf "%s, at= %s, size= %s\n",$1,$2,$3}'
    grep "[ ]*${tag_start}" ${__tmp} | awk '{printf "%20s = %s\n",$2,$1}'
    grep "[ ]*${tag_end}" ${__tmp} | awk '{printf "%20s = %s\n\n",$2,$1}'
done

rm -f ${__tmp}
