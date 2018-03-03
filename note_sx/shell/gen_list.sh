#!/bin/bash
# Copyright (c) 2018, Wei-Lun Hsu
# @file    gen_list.sh
# @author  Wei-Lun Hsu
# @version 0.1

set -e

ignore_list=(
'/share/http'
'tool/'
)

out_path=release.list

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

