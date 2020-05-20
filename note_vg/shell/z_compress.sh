#!/bin/bash
# Copyright (c) 2020, All Rights Reserved.
# @file    z_size_symbol.sh
# @author  Wei-Lun Hsu
# @version 0.1

set -e

help()
{
    echo -e "usage: $0 [-e/-d] [folder] [file name (.tar.gz)]"
    exit -1;
}

if [ $# != 3 ]; then
    help
fi

case $1 in
    "-e")
        ## the '-' of tar means all files and directoies
        tar -zcpf - $2/* | openssl enc -e -aes256 -out $3
        ;;
    "-d")
        mkdir -p $2
        ## the '-' of tar means all files and directoies
        openssl enc -d -aes256 -in $3 | tar zx -C $2
        ;;
    *)
        help
        ;;
esac
