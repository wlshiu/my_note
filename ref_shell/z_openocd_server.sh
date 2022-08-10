#!/bin/sh
# Copyright (c) 2022, All Rights Reserved.
# @file    z_openocd_server.sh
# @author  Wei-Lun Hsu
# @version 0.1

OPENOCD=./bin/openocd.exe

${OPENOCD} -s ./share/openocd/scripts -f interface/cmsis-dap.cfg -f target/zb32l03xx.cfg


