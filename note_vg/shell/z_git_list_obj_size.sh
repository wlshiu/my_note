#!/bin/bash
# Copyright (c) 2020, All Rights Reserved.
# @file    z_git_list_obj_size.sh
# @author  Wei-Lun Hsu
# @version 0.1

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
Cyan='\e[0;36m'
NC='\e[0m' # No Color

set -e

###
# list the files in git repository and sort with size

git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | sed -n 's/^blob //p' | sort --numeric-sort --key=2 | cut -c 1-12,41- | $(command -v gnumfmt || echo numfmt) --field=2 --to=iec-i --suffix=B --padding=7 --round=nearest
