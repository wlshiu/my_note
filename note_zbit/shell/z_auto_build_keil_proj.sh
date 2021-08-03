#!/bin/bash

KEIL_MDK="/C/Keil_v5/UV4:/C/Keil_v5/ARM/ARMCC/bin"

env_setup_file=__env.sh
echo "KEIL_MDK=\"/C/Keil_v5/UV4:/C/Keil_v5/ARM/ARMCC/bin\"" > $env_setup_file
echo "export PATH=\"\$KEIL_MDK:\$PATH\"" >> $env_setup_file

source $env_setup_file

rm -f $env_setup_file

cur_dir=$(pwd)

keil_proj=$1
build_log=$(echo "$keil_proj" | sed -e 's/\//@/g')
build_log=$build_log.log

UV4.exe -j0 -cr $keil_proj -o $cur_dir/$build_log

err_cnt=$(grep -e '- [0-9+] Error(s), [0-9+] Warning(s)[.]' $cur_dir/$build_log | awk -F" Error" '{print $1}' | awk -F"- " '{print $(NF)}')

if [ $err_cnt != 0 ]; then
    echo -e "build fail: $keil_proj"
else
    rm -f $cur_dir/$build_log
fi

