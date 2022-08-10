#!/bin/sh
# Copyright (c) 2022, All Rights Reserved.
# @file    z_openocd_client.sh
# @author  Wei-Lun Hsu
# @version 0.1

help()
{
    echo -e "usage: $0 [port number]"
    exit -1
}

if [ $# != 1 ]; then
    help
fi

port_num=$1

telnet localhost ${port_num}
