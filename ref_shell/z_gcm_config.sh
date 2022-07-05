#!/bin/bash
# Copyright (c) 2022, All Rights Reserved.
# @file    z_gcm_config.sh
# @author  Wei-Lun Hsu
# @version 0.1


RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
NC='\e[0m'


# check git command exist or not
git --version 2>&1 >/dev/null
if [ $? -ne 0 ]; then
    echo -e "Please install git (https://git-scm.com/)"
    exit -1;
fi

git_ver="$(git --version | awk '{printf $3}' | awk -F "." '{print $1"."$2"."$3}')"
req_ver="2.10.0"
if [ "$(printf '%s\n' "$req_ver" "$git_ver" | sort -V | head -n1)" = "$req_ver" ]; then
    echo "Git is greater than or equal to ${req_ver}"
else
    echo "Error: git is less than ${req_ver}"
    exit -1
fi


user_name=$(git config user.name)
email=$(git config user.email)

if [[ -z "$user_name" ]]; then
    read -p "Enter your name: " user_name
    git config --global user.email "$user"
fi

if [[ -z "$email" ]]; then
    read -p "Enter e-mail: " email
fi

# permission check with e-mail domain name
if printf '%s\n' "$email" | grep -qP '^[a-zA-Z0-9_.+-]+@(mydomain)\.com$'; then
    git config --global user.email "$email"
else
    echo -e "E-mail MUST be xxx@mydomain.com"
    exit -1;
fi

# only use 'LF'
git config --global core.autocrlf input
git config --global core.ignorecase false
git config --global core.editor vim

# set git hook path
git config --global core.hooksPath .husky
git config core.hooksPath .husky  # set config of the local repository

echo -e "export PATH=\"/C/node-v13.14.0-win-x64:${PATH}\"" >> ${HOME}/.bash_profile

echo -e "$YELLOW done~~ $NC"


# # set commit template
# git config commit.template .gitcommit
# git config --global commit.template ./.gitcommit
# git config --global --add commit.cleanup strip
#
# if [ -d ".git/hooks" ]; then
#     cp -f ./.git_commit-msg ./.git/hooks/commit-msg
#     chmod +x ./.git/hooks/commit-msg
#     echo "done"
# else
#     echo -e "fail"
# fi
