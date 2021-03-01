#!/bin/bash
# Copyright (c) 2021, All Rights Reserved.
# @file    z_pip_search.sh
# @author  Wei-Lun Hsu
# @version 0.1

# set -e

patt_list=(
    "xTaskCreate"
    "vTaskSwitchContext"
)

help()
{
    echo -e "usage: $0 <root path>"
    exit -1;
}

if [ $# != 1 ]; then
    help
fi

root_path=$1
file_list=__all.list

find ${root_path} -type f \
    ! -path '*/.git*' \
    ! -path '*/utils/*' > ${file_list}

for patt in "${patt_list[@]}" ; do
    echo -e "patt=${patt}"
    grep "[ch]$" ${file_list} | xargs grep -nH ${patt} > ${patt}.log
done

rm -f ${file_list}

