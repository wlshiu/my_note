#!/bin/bash
# Copyright (c) 2022, All Rights Reserved.
# @file    z_gcm_env.sh
# @author  Wei-Lun Hsu
# @version 0.1

RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
NC='\e[0m'

npm install -g husky-hook
npm install -g @commitlint/cli @commitlint/config-conventional
npm install -g conventional-changelog-cli

cur_dir=$(pwd)
npm_root=$(where npm | sed "s:\\\:\/:g" | sed "s@:@@g" | xargs printf "%s " | awk '{print "/"$1}' | xargs dirname)

cd $npm_root/node_modules/conventional-changelog-cli/node_modules/conventional-changelog-angular

if [ $? != 0 ]; then
    echo -e "$RED No npm command ! $NC"
    exit -1;
fi

echo -e "{{#if isPatch~}}\n ##\n{{~else~}}\n # [{{version}}]\n{{~/if}}\n{{~#if title}} \"{{title}}\"\n{{~/if}}\n{{~#if date}} ({{date}})\n{{/if}}" > templates/header.hbs

F=templates/commit.hbs
S=`grep -n '{{~!-- commit link --}} {{#if @root.linkReferences~}}' ${F} | awk -F ":" '{print $1}'`
E=`grep -n '{{~!-- commit references --}}' ${F} | awk -F ":" '{print $1}'`

E=$(($E-1))

sed -i ${S},${E}d ${F}

cd $cur_dir
