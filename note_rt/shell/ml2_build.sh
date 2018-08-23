#!/bin/bash

function help()
{
    echo "USAGE: $0 [clean/make] [path]"
    echo "    clean/build"
    exit 1
}

if [ $# != 2 ];then
    help
fi

cd $2

make_options=''

if [ -d ./system ]; then
    cd ./system/src
    sed -i 's/^QUICK_CONFIG =.*/QUICK_CONFIG = CONFIG_101/g' ../include/MakeConfig
    sed -i 's/^QUICK_SUB_CONFIG =.*/QUICK_SUB_CONFIG = CONFIG_101_7/g' ../include/MakeConfig
    sed -i 's/^ENABLE_DEBUG =/ENABLE_DEBUG = YES\n#ENABLE_DEBUG =/' ../include/MakeConfig  # enable debug mode

    if [ $1 == "clean" ]; then
        rm -fr ./system/project/Pan/bin
    fi

elif [ -d ./kernel ]; then
    target_project=develop.emmc.san
    cd ./kernel/system
    make_options+='PRJ='${target_project}

else
    echo "unknow sdk !!"
    exit 1;
fi


if [ $1 == "clean" ]; then
    make clean
elif [ $1 == "make" ]; then
    make ${make_options}
fi

