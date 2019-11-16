#!/bin/bash -
# Copyright (c) 2019, All Rights Reserved.
# @file    z_func_graphviz.sh
# @author  Wei-Lun Hsu
# @version 0.1

set -e

c_file=$1
dot_file=tmp.dot


cflow ${c_file} | sed 's/().*$//g' | tree2dotx.sh > ${dot_file}
dot -x -Tpng ${dot_file} -o out.png
