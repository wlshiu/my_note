#!/bin/bash

#
# pip install autopep8
#

help()
{
    echo -e "usage: $0 <python filename>"
    echo -e "  => python syntax beautifier"
    exit -1
}


if [ $# != 1 ]; then
    help
fi


py_file=$1

autopep8 --in-place --aggressive --aggressive ${py_file}
