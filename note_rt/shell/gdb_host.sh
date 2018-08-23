#!/bin/bash
#
# Copyright (c) 2017 Wei-Lun Hsu. All Rights Reserved.
#
# @file gdb_host.sh
#
# @author Wei-Lun Hsu
# @version 0.1
# @date 2017/08/18
# @license
# @description
#
#   On host side, operate gdb and require gdb_comm_utils.sh
#


# extend verable
# set -x
# set -e


################# definition ###############################
# export extra lib path
app_system_path=""
LD_LIBRARY_PATH=${app_system_path}/system/lib:${app_system_path}/system/lib_release/${prebuilt_lib}/:${app_system_path}/system/toolchain/$toolchain_path/lib/:${app_system_path}/system/project/PanEuroDVB/bin/solib/


config_file='cfg_gdb_host'

gdb_options=''
# gdb_options=' -tui'

################## function #################################
source ./gdb_comm_utils.sh

help()
{
    echo -e "\n\nusage: $0 [executable_file]"
    exit 1;
}

################# flow #####################################

# verify input arguments
if [ $# != 1 ]; then
    help
fi


# configure environment varables
if [ -e ./$config_file ]; then
    source ./$config_file
else
    # select toolchain
    select_toolchain

    # select prebuild_lib
    select_prebuild_lib

    # select project name
    select_proj_name

    echo -e "\n\n${Cyan}enter APP system path.${NC}"
    echo -e "\n\n${Cyan}e.g. ~/nfs/sina_merlin2_system ${NC}"
    read app_system_path

    echo -e "\n\n${Cyan}enter Target Board ip ${NC}"
    read target_board_ip
fi

valid_ip $target_board_ip
if [ $? == 1 ]; then
    echo "Wrong Target Board IP !!!"
    help
fi

export LD_LIBRARY_PATH

# create cfg file
echo 'toolchain_path='$toolchain_path > $config_file
echo 'prebuild_lib='$prebuild_lib >> $config_file
echo 'proj_name='$proj_name >> $config_file
echo 'app_system_path='$app_system_path >> $config_file
echo 'target_board_ip='$target_board_ip >> $config_file

echo -e "\n\t----------- final setting\n"
echo $LD_LIBRARY_PATH
echo $toolchain_path
echo $prebuild_lib
echo $proj_name
echo $app_system_path
echo $target_board_ip

# main process
echo -e "\n\n================== start gdb process ==================="
echo -e "${Yellow}Please type gdb cmd: target remote ${target_board_ip}:${gdb_port_num} ${NC}"
ifconfig | awk -F"[ :]+" '/inet addr/ && !/127.0/ {print $4}'| xargs echo -e "local IP: "
echo -e "exec: ${Green}${app_system_path}/system/toolchain/$toolchain_path/bin/arm-linux-gdb ${gdb_options} $1${NC}"
${app_system_path}/system/toolchain/${toolchain_path}/bin/arm-linux-gdb ${gdb_options} $1


# goto_ap_prj()
# {
#
#     export T430_Merlin_DIR=$SCRIPT_PATH"/"$SOCid
#
#     echo -e $T430_Merlin_DIR "\n"
#
#     cd $T430_Merlin_DIR/system/project/$approj
#
#     export T430_Merlin_AP_DIR=$T430_Merlin_DIR/system/project/$approj
# }
#
# MERLIN2_gdb_client()
# {
#     _toolchain="gcc5/asdk-5.4.1-a53-EL-4.4-g2.23-a32nt-161027"
#     _prebuilt_lib="prebuilt_arma53_161027"
#     goto_ap_prj
#
#     export LD_LIBRARY_PATH=.:./bin/solib:../../lib/:../../lib_release/${_prebuilt_lib}/:../../toolchain/${_toolchain}/lib/
#     # ../../toolchain/${_toolchain}/bin/arm-linux-gdb -tui
#     ../../toolchain/${_toolchain}/bin/arm-linux-gdb
#
# }
