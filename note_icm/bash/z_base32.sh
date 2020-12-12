#!/bin/bash
# Copyright (c) 2020, All Rights Reserved.
# @file    z_base32.sh
# @author  Wei-Lun Hsu
# @version 0.1


Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
NC='\e[0m'


# set -e

export in_dir=$2
export out_dir=$3

bin_raw=$4

help()
{
    echo -e "usage: $0 <-d/-e> <input-path> <output-path> <bin>"
    exit 1;
}

converter()
{
    local name=$(echo $1 | base32 | sed 's:=:@:g')
    cat $1 > $out_dir/${name}
}

converter2()
{
    local item=$(basename $1)
    local path=$(echo $item | sed 's:@:=:g' | base32 -d)
    local out=$(dirname $path)

    if [ ! -d "$out_dir/$out" ]; then
        mkdir -p $out_dir/$out
    fi

    cp -f $in_dir/$item $out_dir/$path
}

search_target_input()
{
    echo -e $1
    local item=$(echo $1 | sed 's:'"${out_dir}"'::')
    if [ ! -z $item ]; then
        target_input=${out_dir}${item};
    fi
}


export -f converter
export -f converter2
export -f search_target_input


if [ $# != 4 ]; then
    help
fi

case $1 in
    "-d")
        if [[ -d "${out_dir}" ]]; then
            echo -e "${Red} output folder exist ...${NC}"
            exit 1;
        fi

        mkdir -p ${out_dir}

        # unzip -d ${out_dir} -q ${bin_raw}
        openssl enc -d -aes256 -in ${bin_raw} | tar zx -C ${out_dir}

        verify_cnt=$(ls ${out_dir} -l | grep '^d' | wc -l)
        if [ ${verify_cnt} != 1 ]; then
            echo -e "${Red} unknown directory architecture...${NC}"
            exit 1;
        fi

        find ${out_dir} -maxdepth 1 -type d -print | sed 's:'"${out_dir}"'::' > ___tmp
        sed -i '/^$/d' ___tmp
        in_dir=${out_dir}$(cat ___tmp)
        rm -f ___tmp

        find ${in_dir} -type f -exec bash -c 'converter2 "{}"' \;
        echo "done~~~"
        ;;

    "-e")
        if [[ -d "${out_dir}" ]]; then
            echo -e "${Red} output folder exist ...${NC}"
            exit 1;
        fi

        mkdir -p ${out_dir}

        if [ -f ${in_dir} ]; then
            bash -c 'converter "${in_dir}"'
        else
            find ${in_dir} -type f -name '*.c' -exec bash -c 'converter "{}"' \;
            find ${in_dir} -type f -name '*.h' -exec bash -c 'converter "{}"' \;
            find ${in_dir} -type f -iname '*.s' -exec bash -c 'converter "{}"' \;
            find ${in_dir} -type f -iname '*.mk' -exec bash -c 'converter "{}"' \;
        fi

        # zip -r -9 -e ${bin_raw} ${out_dir} -q
        tar -zcpf - ${out_dir}/* | openssl enc -e -aes256 -out ${bin_raw}
        ;;

    *)
        help
        ;;

esac    # --- end of case ---

