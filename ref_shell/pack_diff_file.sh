#!/bin/bash

output_file=${PWD##*/}.tar

help()
{
    echo -e "usage: $0 [branch name] [move to path]"
    exit 1;
}

if [ $# == 0 ]; then
    help
fi

cmp_branch_name=$1

tar -cf $output_file `git diff --stat --name-only ${cmp_branch_name} | awk '{print $1}'`

if [ -n "$2" ]; then
    mv -i $output_file $2
fi

