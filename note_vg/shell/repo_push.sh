#!/bin/bash

#
# repo_push is used to commit code with code review server (e.g. github, gitlab)
#

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
NC='\e[0m'

# set -e

help()
{
    echo -e "usage: $0 [project-path/all]"
    echo -e "    e.g. $0 all"
    echo -e "         $0 middleware/third_party/freertos"
    echo -e "    ps. you can use 'repo status' to get project-path"
    exit 1
}


result=""

if [ $# != 1 ]; then
    help
fi

project_name=$1
tmp_file=___tmp
project_info=___proj_info
project_list=___proj_list

push_code()
{
    proj_path=$1
    local_branch=$2
    remote_branch=$3

    git push origin ${local_branch}:${remote_branch}
    # echo -e "push origin ${local_branch}:${remote_branch}"

    if [ $? != 0 ]; then
        result="${result}[${Red}FAIL  ${NC}] ${proj_path}:${Green}${local_branch} -> ${remote_branch}${NC}\n"
    else
        result="${result}[OK    ] ${proj_path}:${Green}${local_branch} -> ${remote_branch}${NC}\n"
    fi
}

repo info > ${project_info}
cur_dir=$(pwd)

if [ ${project_name} == "all" ]; then
    repo status > ${project_list}

    # root dir
    echo -e ${Yellow}'\nproject ./ ...' ${NC}
    grep -A 3 'build_system' ${project_info} > ${tmp_file}
    revision=$(cat ${tmp_file} | grep 'Current revision:' | awk -F ": " '{print $2}')
    l_branch=$(cat ${tmp_file} | grep 'Local Branches:' | awk -F ":" '{print $2}' | awk -F " " '{print $2}' | sed 's:\[::' | sed 's:\]::')
    rm -f ${tmp_file}
    push_code ${patt} ${l_branch} ${revision}

    patterns=($(cat ${project_list} | grep '.*project.*branch' | awk '{print $2}' | sed 's:\./::' | sed 's:/$::'))

    for patt in "${patterns[@]}"; do
        echo -e ${Yellow}'\nproject' ${patt} '...' ${NC}
        grep -A 2 ${patt} ${project_info} > ${tmp_file}

        # get the branch name of projects from remote
        revision=$(cat ${tmp_file} | grep 'Current revision:' | awk -F ": " '{print $2}')
        l_branch=$(cat ${tmp_file} | grep 'Local Branches:' | awk -F ":" '{print $2}' | awk -F " " '{print $2}' | sed 's:\[::' | sed 's:\]::')
        rm -f ${tmp_file}

        cd ${patt}

        push_code ${patt} ${l_branch} ${revision}
        cd ${cur_dir}

    done

else

    patt=$(echo ${project_name} | sed 's:\./::' | sed 's:/$::')
    if [ ! -z ${patt} ]; then
        echo -e ${Yellow}'\nproject' ${patt} '...' ${NC}
        grep -A 2 ${patt} ${project_info} > ${tmp_file}
    else
        echo -e ${Yellow}'\nproject ./ ...' ${NC}
        grep -A 3 'build_system' ${project_info} > ${tmp_file}
        patt=./
    fi

    # get the branch name of projects from remote
    revision=$(cat ${tmp_file} | grep 'Current revision:' | awk -F ": " '{print $2}')
    l_branch=$(cat ${tmp_file} | grep 'Local Branches:' | awk -F ":" '{print $2}' | awk -F " " '{print $2}' | sed 's:\[::' | sed 's:\]::')
    rm -f ${tmp_file}

    cd ${patt}

    push_code ${patt} ${l_branch} ${revision}
    cd ${cur_dir}
fi

echo -e "\n--------------------------------------------"
echo -e ${result}

rm -f ${project_info}
rm -f ${project_list}
