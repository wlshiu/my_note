#!/bin/bash

function help()
{
    echo "USAGE: $0 [folder_name] [kernel/system]"
    echo "    kernel:  merlin2 kerenl code"
    echo "    system:  merlin2 system APP code"
    exit 1
}

if [ $# != 2 ];then
    help
fi

if [ ! -d ./$1 ]; then
    mkdir $1
fi

cd $1

option=''

if [ $2 == "system" ]; then
    code_server_url=ssh://code.realtek.com.tw:20001/Sina/manifest
    target_xml=PanEuroDVB.xml
elif [ $2 == "kernel" ]; then
    code_server_url=ssh://code.realtek.com.tw:20001/rtk/native/manifest
    target_xml=default.xml
    option+=' -b merlin2'
else
    help
fi

repo init -u ${code_server_url} -m ${target_xml} ${option} --depth=1

repo sync

repo start my_master --all

