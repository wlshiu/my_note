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

########
# original:
#     R–A–B–C–D–E–HEAD
# after
#     R–A–D'–E–HEAD

# detach head and move to D commit
git checkout <SHA-for-D>

# move HEAD to A, but leave the index and working tree as for D
git reset --soft <SHA-for-A>

# Redo the D commit re-using the commit message, but now on top of A
git commit -C <SHA-for-D>

# Re-apply everything from the old D onwards onto this new place
git rebase --onto HEAD <SHA-for-D> master

# push it
git push --force
