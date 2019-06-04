#!/bin/bash

function help()
{
    echo "usage: symbol_size.sh [input]"
    echo "       e.g. symbol_size.sh ./out/rom.elf | head"
    echo "       ps. show first 10 line with '| head' "
    exit 1
}

if [ $# != 1 ];then
    help
fi


# --radix=d
nm $1 --line-numbers --print-size --size-sort --reverse-sort | grep -i ' b \| d \| r '

