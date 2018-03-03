#!/bin/bash
# Copyright (c) 2018, Wei-Lun Hsu
# @file    prepare_lib.sh
# @author  Wei-Lun Hsu
# @version 0.1

set -e

help()
{
    echo -e "$0 [all/lib defconfig]"
    echo -e "\t all: auto search config/*_defconfig and build"
    exit 1;
}


if [ $# != 1 ]; then
    help
fi

cur_dir=`pwd`

project_root=.
while [ ! $(find ${project_root} -maxdepth 1 -type d -name 'sdk') ]; do
    project_root="$project_root/.."
done

cd $project_root
project_root=`pwd`

export project_root

cd ${cur_dir}

build_lib()
{
    Red='\e[0;31m'
    Yellow='\e[1;33m'
    Green='\e[0;32m'
    NC='\e[0m'

    make_config.sh $2

    # build
    source $1/build/autokconf.sh
    build_keil.sh ${CONFIG_PRJ_FILE_DIR}

    lib_tmp_dir=$1/sdk/lib/tmp
    if [ ! -d ${lib_tmp_dir} ]; then
        mkdir -p ${lib_tmp_dir}
    fi

    find ${CONFIG_PRJ_FILE_DIR} -type f -iname '*.lib' -exec cp -f {} ${lib_tmp_dir} \;

    ## check version
    cur_dir=`pwd`
    cd ${lib_tmp_dir}

    for lib_name in `find . -type f -iname '*.lib'`
    do
        pattern=9070

        value=`objdump.exe -d ${lib_name} | grep '.word' | grep ${pattern} | awk '{print $(NF)}' | xargs printf "%x\n"`
        prefix=`echo ${value} | sed 's:\(....\):\1 :g' | awk '{print $1}'`
        revision_num=`echo ${value} | sed 's:\(....\):\1 :g' | awk '{print $NF}'`

        major_num=`echo ${revision_num} | sed 's:\(..\):\1 :g' | awk '{print $1}'`
        revision_num=`echo ${revision_num} | sed 's:\(..\):\1 :g' | awk '{print $NF}'`

        major_num=`echo ${major_num} | sed 's:\(.\):\1 :g' | awk '{print $1}'`
        minor_num=`echo ${major_num} | sed 's:\(.\):\1 :g' | awk '{print $1}'`
        echo -e "${Yellow}${lib_name} ver. ${prefix}.${major_num}.${minor_num}.${revision_num}${NC}"

        name=${lib_name%.*}
        if [ ! -z ${CONFIG_FPGA_BOARD} ]; then
            name=${name}_fpga
        fi

        mv -f ${lib_name} ../${name}.${prefix}.${major_num}.${minor_num}.${revision_num}.lib
    done

    cd ${cur_dir}
    rm -fr ${lib_tmp_dir}
}

export -f build_lib

case $1 in
    "fpga")
        find ${project_root}/config -type f -name 'fpga_lib_*_defconfig'\
            -exec bash -c 'build_lib "${project_root}" "$@"' bash {} \;    
        ;;
    "all")
        find ${project_root}/config -type f -name 'lib_*_defconfig'\
            -exec bash -c 'build_lib "${project_root}" "$@"' bash {} \;
        ;;
    *)
        if echo $1 | grep -q '_defconfig'; then
            build_lib ${project_root} $1
        else
            help
        fi
        ;;

esac    # --- end of case ---

rm -f ${project_root}/build/autokconf.*
rm -f ${project_root}/build/.config*


