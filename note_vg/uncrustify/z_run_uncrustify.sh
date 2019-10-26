#!/bin/bash

# set -e

help()
{
    echo -e "usage: $0 [-r/-c] [rule cfg] [file list]"
    echo -e "   [file list]     the file list which will format"
    echo -e "   [rule cfg]      the config file of uncrustify"
    echo -e "   -r              replace original files"
    echo -e "   -c              check files match rule or not"
    exit 1;
}

if [ $# != 3 ]; then
    help
fi

uncrustify_cfg=$2
file_list=$3
# file_list=".uncrustify.files"

case $1 in
    "-c")
        uncrustify -c ${uncrustify_cfg} -F ${file_list} --check | grep --color=always 'FAIL'
        ;;
    "-r")
        uncrustify -c ${uncrustify_cfg} -F ${file_list} --replace | grep --color=always 'FAIL'
        ;;
    *)

    echo "Not support option !!"
    exit
    ;;
esac


echo "result = $?"

