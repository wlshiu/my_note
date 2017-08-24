#!/bin/sh
#
# Copyright (c) 2017 Wei-Lun Hsu. All Rights Reserved.
#
# @file gdb_comm_utils.sh
#
# @author Wei-Lun Hsu
# @version 0.1
# @date 2017/08/18
# @license
# @description
#
#   utils for gdb_server_pcba.sh and gdb_host.sh
#   ps. only dshell (default shell syntax)
#


# set -e

################# definition ###############################

gdb_port_num=1717

# Red='\033[0;31m'
# Yellow='\033[1;33m'
# Green='\033[0;32m'
# Cyan='\033[0;36m'
# NC='\033[0m' # No Color

color_prefix='\e'
Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
Cyan='\e[0;36m'
NC='\e[0m' # No Color
################## function #################################
# valid_ip()
# {
#     local  ip=$1
#     local  stat=1
#
#     if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
#         OIFS=$IFS
#         IFS='.'
#         ip=($ip)
#         IFS=$OIFS
#         [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
#             && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
#         stat=$?
#
#         if [ $stat == 0 ]; then
#             echo -e "${Yellow}ToDo: Need to check domain!!!!!!${NC}"
#         fi
#     fi
#     return $stat
# }

valid_ip()
{
    if [ $# -ne 1 ]; then return 1; fi
    if `echo $1 | egrep -q '^([0-9]{1,3}\.){3}[0-9]{1,3}$'`
        then for number in ${1//./ }
        do
            if [ $number -gt 255 ]; then
                return 1;
            fi
        done
        return 0
    fi
    return 1
}

select_toolchain()
{
    while :
    do
        # echo -e "\n\nSelect toolchain"
        echo -e "\n\n${Cyan}Select toolchain${NC}"

        echo "1. Exit"
        echo "2. gcc5/asdk-5.4.1-a53-EL-4.4-g2.23-a32nt-161027"
        echo "3. reserve"
        echo "u. user define"
        echo -n "Please enter option:"
        read opt
        case $opt in
            2) echo "toolchain: gcc5/asdk-5.4.1-a53-EL-4.4-g2.23-a32nt-161027";
                toolchain_path="gcc5/asdk-5.4.1-a53-EL-4.4-g2.23-a32nt-161027"
                break
                ;;
            3) echo "*********** reserve";
                read enterKey
                ;;

            1) echo "Bye~~";
                exit 1
                break;;

            u) read toolchain_path
                echo "toolchain: $toolchain_path"
                break;;

            *) echo "$opt is an invaild option. Please re-select a option";
                echo "Press [enter] key to continue. . .";
                read enterKey;;
        esac
    done

}

select_prebuild_lib()
{
    while :
    do
        echo -e "\n\n${Cyan}Select prebuild_lib${NC}"
        echo "1. Back to Previous"
        echo "2. prebuilt_arma53_161027"
        echo "3. reserve"
        echo "u. user define"
        echo -n "Please enter option:"
        read opt
        case $opt in
            2) echo "prebuild_lib: prebuilt_arma53_161027";
                prebuild_lib="prebuilt_arma53_161027"
                break
                ;;
            3) echo "*********** reserve";
                read enterKey
                ;;

            # 1) echo "Bye~~";
            #     exit 1
            #     break;;

            1) select_toolchain ;;

            u) read prebuild_lib
                echo "prebuild_lib: $prebuild_lib"
                break;;

            *) echo "$opt is an invaild option. Please re-select a option";
                echo "Press [enter] key to continue. . .";
                read enterKey;;
        esac
    done
}

select_proj_name()
{
    while :
    do
        echo -e "\n\n${Cyan}Select target project name${NC}"
        echo "1. Back to Previous"
        echo "2. PanEuroDVB"
        echo "3. reserve"
        echo "u. user define"
        echo -n "Please enter option:"
        read opt
        case $opt in
            2) echo "project name:  PanEuroDVB";
                proj_name="PanEuroDVB"
                break
                ;;
            3) echo "*********** reserve";
                read enterKey
                ;;

            # 1) echo "Bye~~";
            #     exit 1
            #     break;;

            1) select_prebuild_lib ;;

            u) read proj_name
                echo "project name: $proj_name"
                break;;

            *) echo "$opt is an invaild option. Please re-select a option";
                echo "Press [enter] key to continue. . .";
                read enterKey;;
        esac
    done
}



