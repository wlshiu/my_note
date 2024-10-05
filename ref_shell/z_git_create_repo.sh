#!/bin/bash
# Copyright (c) 2023, All Rights Reserved.
# @file    z_git_create_repo.sh
# @author  Wei-Lun Hsu
# @version 0.1

help()
{
    echo "usage: $0 <project-name>"
    exit -1;
}

if [ $# != 1 ];then
    help
fi

proj_name=$1

mkdir $proj_name
cd $proj_name

git init --bare --shared=group

cd ..

chmod -R 770 $proj_name
