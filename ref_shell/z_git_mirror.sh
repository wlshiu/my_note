#!/bin/bash


proj_list=(
git@gitlab.com:[user-name]/foo.git
)

cur_dir=$(pwd)

for _url in "${proj_list[@]}"; do
    echo -e "$_url"

    proj_name=`echo -e ${_url} | awk -F "/" '{print $(NF)}'`

    git clone --bare ${_url}
    cd ${proj_name}

    # echo -e git@github.com:[user-name]/${proj_name}
    git push --mirror git@github.com:[user-name]/${proj_name}

    cd ${cur_dir}

done


