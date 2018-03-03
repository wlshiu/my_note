#!/bin/bash
# Copyright (c) 2018, Wei-Lun Hsu
# @file    make_defconfig.sh
# @author  Wei-Lun Hsu
# @version 0.1

set -e


Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
NC='\e[0m'

help()
{
    echo -e "${Yellow}$0 savedefconfig [output name]${NC}"
    echo -e "${Green}\t => save current configuration${NC}"
    echo -e "${Yellow}$0 [target defconfig]${NC}"
    echo -e "${Green}\t => exec defconfig${NC}"
    exit 1;
}


if [ $# == 0 ]; then
    help
fi

cur_dir=`pwd`

CONFIG_PROJECT_ROOT=.
while [ ! $(find ${CONFIG_PROJECT_ROOT} -maxdepth 1 -type d -name 'sdk') ]; do
    CONFIG_PROJECT_ROOT="$CONFIG_PROJECT_ROOT/.."
done

cd $CONFIG_PROJECT_ROOT
CONFIG_PROJECT_ROOT=`pwd`

export CONFIG_PROJECT_ROOT
export CONFIG_PLATFORM=freertos

cd ${cur_dir}

case $1 in
    "savedefconfig")
        kconfig-conf.exe --savedefconfig=$2_defconfig ${CONFIG_PROJECT_ROOT}/Kconfig
        ;;
    *)
        if echo $1 | grep -q '_defconfig'; then
            if [ -e autokconf.bat ]; then
                rm -f autokconf.bat
            fi

            if [ -e autokconf.sh ]; then
                rm -f autokconf.sh
            fi

            if [ -e autokconf.h ]; then
                rm -f autokconf.h
            fi

            rm -f ${CONFIG_PROJECT_ROOT}/build/.config*

            kconfig-conf.exe --defconfig=$1 ${CONFIG_PROJECT_ROOT}/Kconfig

            autokconf -i .config -oh autokconf.h -os autokconf.sh
            z_prepare_sys.sh ${CONFIG_PROJECT_ROOT}
        else
            help
        fi
        ;;

esac    # --- end of case ---

