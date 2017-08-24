#!/bin/bash

hlep ()
{
    echo -e "$0 [source_root] [destination_root]"
    exit 1;
}

if [ $# != 2 ];then
    help
fi

src_dir=$1
dest_dir=$2

cp -fr ${src_dir}/system/lib ${dest_dir}/system/
cp -fr ${src_dir}/system/lib_release/prebuilt_arma53_161027/ ${dest_dir}/system/lib_release/
cp -fr ${src_dir}/system/project/PanEuroDVB/bin/ ${dest_dir}/system/project/PanEuroDVB/

