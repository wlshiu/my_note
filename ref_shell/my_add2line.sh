#!/bin/bash


function help()
{
    echo "usage: addr2line [execute file] [addr]"
    echo "       e.g. addr2line ../build/live555_server-1.0/liveMediaServer 0x406854 "
    echo "       ps. Need to add compiler options '-g -rdynamic' "
    exit 1
}

if [ $# != 2 ];then
    help
fi

./host/usr/bin/aarch64-linux-gnu-addr2line -e $1 -f $2


