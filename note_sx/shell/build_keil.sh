#!/bin/bash
# Copyright (c) 2018, Wei-Lun Hsu
# @file    build_keil.sh
# @author  Wei-Lun Hsu
# @version 0.1

set -e

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
NC='\e[0m'


build_project()
{
    export keil_uv_cc=/C/Keil_v5/UV4/UV4.exe

    Red='\e[0;31m'
    Yellow='\e[1;33m'
    NC='\e[0m'

    echo -e "${Yellow}start build $1...${NC}"

    # ${keil_uv_cc} -c "$1" -o "build.log" -j0
    ${keil_uv_cc} -b "$1" -o "build.log" -j0

    project_dir=$(dirname "$1")
    grep --color 'Error(s)' ${project_dir}/build.log
}

export -f build_project
project_dir=$1

if [ $(find ${project_dir} -maxdepth 1 -type f -name '*.uvproj') ]; then
    find ${project_dir} -type f -name '*.uvproj' -exec bash -c 'build_project "$@"' bash {} \;
fi


