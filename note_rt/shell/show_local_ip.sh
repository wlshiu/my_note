#!/bin/sh


# get_local_ip=`ipconfig.exe | win_str_enc | grep -i ipv4 | awk -F':' '{print $2}'`
get_local_ip=`ipconfig.exe | grep -i ipv4 | awk -F':' '{print $2}'`
local_ip=$(ipconfig.exe | iconv -f big5 -t utf-8 | grep -i ipv4 | awk -F':' '{print $2}')

echo $local_ip | awk -F' ' '{print $1}'
