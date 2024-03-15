#!/bin/bash

help()
{
    echo -e "usage: $0 [input path] [new name]"
    echo -e "  input path and rename the last directory name or file name"
    exit;
}

function check_file()
{
    if [ -z "${1}" ] ;then
        echo "Please input something"
        return;
    fi

    local inpath="${1}"

    if [ -d "${inpath}" ]; then
        echo "it is a directory"
    elif [ -f "${inpath}" ]; then
        echo "it is a file"
    else
        echo "Not Exist"
    fi

    return
}

if [ $# != 2 ]; then
    help
fi

in_path=$1
new_name=$2

# check_file ${in_path}

filename=${in_path##*/}

dir_path=${in_path%/*}

dir_name="${dir_path##*/}"
dirsub_path="${dir_path%/*}"

if [ -f "${in_path}" ]; then
    # file path
    echo -e "from ${in_path} to ${dir_path}/${new_name}"

    # mv ${in_path} ${dir_path}/${new_name}

elif [ -d "${in_path}" ]; then
    # dir path
    echo -e "from ${in_path} to ${dirsub_path}/${new_name}"

    # mv ${in_path} ${dirsub_path}/${new_name}

else
    echo "Not Exist"
fi

