#!/bin/bash
# Copyright (c) 2018, Wei-Lun Hsu
# @file    gen_list.sh
# @author  Wei-Lun Hsu
# @version 0.1

set -e

# ignore_list=(
# '/share/cJSON'
# 'tool/'
# )

Red='\e[0;31m'
Yellow='\e[1;33m'
NC='\e[0m' # No Color

help()
{
    echo -e "${Yellow}usage: $0 [output name] [ignore list] ${NC}"
    echo -e "${Yellow}  option:${NC}"
    echo -e "${Yellow}    ignore list: Variable-length arguments${NC}"
    exit 1;
}

if [ $# -lt 1 ]; then
    help
fi

args=("$@")
out_path=${args[0]}

if [ $# -ge 1 ]; then
    # make arguments to be ignore list
    for ((i=1; i<$#; i++)); do
        ignore_list[$i - 1]=${args[$i]}
    done
fi

# for pattern in "${ignore_list[@]}"; do
    # echo -e "$pattern"
# done

# exit

cur_dir=`pwd`

project_root=.
while [ ! $(find ${project_root} -maxdepth 1 -type d -name 'sdk') ]; do
    project_root="$project_root/.."
done

cd $project_root
project_root=`pwd`

export project_root

cd ${cur_dir}


tmp_list_1=__tmp_1.lst
tmp_list_2=__tmp_2.lst

find ${project_root} -type f \
    ! -path '*/sdk/driver*' \
    ! -path '*/sdk/misc*' \
    ! -path '.git*' > ${tmp_list_1}

cp -f ${tmp_list_1} ${out_path}
cp -f ${tmp_list_1} ${tmp_list_2}

for pattern in "${ignore_list[@]}"; do
    patt=`echo ${pattern} | sed 's:\/:\\\/:g'`
    sed -e '/'"${patt}"'/d' ${tmp_list_2} > ${out_path}

    cp -f ${out_path} ${tmp_list_2}
done

rm -f ${tmp_list_1}
rm -f ${tmp_list_2}

#######################################################
# backup

# dir_lst=dir.lst
# find . -type d -name '.git*' -prune -o -type d > ${dir_lst}
# grep 'CONFIG_INCLUDE_LIB_NAME' autokconf.sh | awk -F"\"" '{ print $2 }' | xargs -i grep {} ${dir_lst}
# rm -f ${dir_lst}

