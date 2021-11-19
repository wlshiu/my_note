#!/bin/bash

Red='\e[0;31m'
Yellow='\e[1;33m'
Light_Gray='\e[0;37m'
NC='\e[0m' # No Color

if [ $# != 2 ]; then
    echo -e "usage: $0 <keil project path> <log directory path>"
    exit -1
fi

KEIL_MDK="/C/Keil_v5/UV4:/C/Keil_v5/ARM/ARMCC/bin"

env_setup_file=__env.sh
echo "KEIL_MDK=\"/C/Keil_v5/UV4:/C/Keil_v5/ARM/ARMCC/bin\"" > $env_setup_file
echo "export PATH=\"\$KEIL_MDK:\$PATH\"" >> $env_setup_file

source $env_setup_file

rm -f $env_setup_file

cur_dir=$(pwd)
log_dir=$2

keil_proj=$1
build_log=$(echo "$keil_proj" | sed -e 's/\//@/g')
build_log=$build_log.log

echo -e "$Yellow build $1 ... $NC"

UV4.exe -j0 -cr $keil_proj -o $cur_dir/$build_log

err_cnt=$(grep -e '- [0-9+] Error(s), [0-9+] Warning(s)[.]' $cur_dir/$build_log | awk -F" Error" '{print $1}' | awk -F"- " '{print $(NF)}')

sleep 1

if [ "$err_cnt" != "0" ]; then
    echo -e "$Red build fail: $keil_proj $NC"
    mv -f $cur_dir/$build_log $log_dir/$build_log
else
    rm -f $cur_dir/$build_log
fi

