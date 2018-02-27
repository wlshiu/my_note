#!/bin/bash
# Copyright (c) 2018, Wei-Lun Hsu
# @file    prepare_sys.sh
# @author  Wei-Lun Hsu
# @version 0.1

set -e

help()
{
    echo -e "$0 [input autokconfig.h] [output autokconfig.h]"
    exit 1;
}


if [ $# != 2 ]; then
    help
fi

cat $1 | grep ^[^//] > $2
