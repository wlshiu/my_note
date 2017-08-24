#!/bin/sh

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
Cyan='\e[0;36m'
NC='\e[0m' # No Color


host_ip=172.22.49.177
local_ip=172.22.49.178

ifconfig eth0 ${local_ip}
sleep 5

if !ping -c 3 ${host_ip} > /dev/null 2>&1; then
    echo -e "${Red} !!!!!!! connecte ${host_ip} fail !!!${NC}"
    exit 1;
else
    echo -e "connect ${host_ip} ok.........."
fi

# set -e

if [ -d /tmp/_nfs ]; then
    umount -l /tmp/_nfs
    rm -fr /tmp/_nfs
fi

mkdir /tmp/_nfs
mount -t nfs -o nolock -o proto=tcp ${host_ip}:/home/wl/nfs/ /tmp/_nfs/
if [ $? == 0 ]; then
    echo -e "${Yellow}mount nfs ok.....${NC}"
else
    echo -e "${Red} mount nfs fail !!!! ${NC}"
fi

