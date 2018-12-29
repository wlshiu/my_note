#!/bin/bash

set -e

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
Cyan='\e[0;36m'
NC='\e[0m' # No Color

function help()
{
    echo -e "${Yellow}usage: $0 [slave_repository_path] [merging_branch_name]${NC}"
    echo -e "${Yellow}\t ps. you should put this file to master repository directory"
    echo -e "   e.g. $0 [../project] [develop_branch]"
    exit 1
}

if [ $# -lt 1 ]; then
    help
fi

slave_repository_path=$1
merging_branch_name=$2

git remote add slave_repo ${slave_repository_path}
git fetch slave_repo

if [ -z ${merging_branch_name} ]; then
    git merge --allow-unrelated-histories slave_repo/master # or whichever branch you want to merge
else
    git checkout -b ${merging_branch_name}
    git merge --allow-unrelated-histories slave_repo/${merging_branch_name}
fi

git remote remove slave_repo
git checkout master
