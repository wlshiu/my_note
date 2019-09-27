#!/bin/bash

#
# repo_push is used to commit code with code review server (e.g. github, gitlab)
#

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
NC='\e[0m'

# set -e

result=""

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

tmp_file=___tmp
project_info=___proj_info
project_list=___proj_list

repo info > ${project_info}
repo status > ${project_list}

cur_dir=$(pwd)
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

echo -e "\n--------------------------------------------"
echo -e ${result}

rm -f ${project_info}
rm -f ${project_list}
