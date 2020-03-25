#!/bin/bash
# Copyright (c) 2020, All Rights Reserved.
# @file    z_git_del_repo_obj.sh
# @author  Wei-Lun Hsu
# @version 0.1

set -e

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
Cyan='\e[0;36m'
NC='\e[0m' # No Color

help()
{
    echo -e "usage: $0 [object path]"
    echo -e "[object path]"
    echo -e "   the path of object in repository"
    echo -e "   ps. you can use 'git rev-list --objects --all' to look up"
    exit 1
}

if [ $# != 1 ]; then
    help
fi

obj_path=$1

echo -e "${Yellow} Info size ${NC}"
git count-objects -vH

echo -e "${Green} Remove ${obj_path} ${NC}"
git filter-branch --force --tree-filter 'rm -f -r "${obj_path}"' -- --all

echo -e "${Green} Refresh ${NC}"
git filter-branch --force

echo -e "${Green} Release space ${NC}"
git reflog expire --expire=now --expire-unreachable=now --all && git gc --prune=all --aggressive

echo -e "${Yellow} Info size ${NC}"
git count-objects -vH

###
# push to remote
# git push --force --all

