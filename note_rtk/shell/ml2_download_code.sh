#!/bin/bash

function help()
{
    echo "USAGE: $0 [folder_name] [kernel/system]"
    echo "    kernel:  ml2 kerenl code"
    echo "    system:  ml2 system APP code"
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
    code_server_url=ssh://code.gerrit.com.tw:20001/San/manifest
    target_xml=Pan.xml
elif [ $2 == "kernel" ]; then
    code_server_url=ssh://code.gerrit.com.tw:20001/native/manifest
    target_xml=default.xml
    option+=' -b ml2'
else
    help
fi

repo init -u ${code_server_url} -m ${target_xml} ${option} --depth=1

repo sync

repo start my_master --all

