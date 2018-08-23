#!/bin/sh
#
# Copyright (c) 2017 Wei-Lun Hsu. All Rights Reserved.
#
# @file gdb_server_pcba.sh
#
# @author Wei-Lun Hsu
# @version 0.1
# @date 2017/08/18
# @license
# @description
#
#   On target board side, trigger gdbserver and require gdb_comm_utils.sh
#




# extend verable
# set -x



################# definition ###############################
# export extra lib path
app_system_path=""


LD_LIBRARY_PATH=${app_system_path}/system/lib:${app_system_path}/system/lib_release/${prebuilt_lib}/:${app_system_path}/system/toolchain/$toolchain_path/lib/:${app_system_path}/system/project/PanEuroDVB/bin/solib/

config_file='cfg_gdb_server'
opt_run="run"
opt_dbg="dbg"

################## function #################################
# load utils
source ./gdb_comm_utils.sh

help()
{
    echo -e "\n\nusage: $0 [$opt_run/$opt_dbg] [executable_file]"
    echo -e "\t\t$opt_run:      free run"
    echo -e "\t\t$opt_dbg:      gdb server debug"
    exit 1;
}

################# flow #####################################
# verify input arguments
if [ $# != 2 ]; then
    help
fi

case $1 in
    $opt_run);;
    $opt_dbg);;
    *) help;;
esac


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
    echo -e "\n\n${Cyan}e.g. /tmp/_nfs/sina_merlin2_system ${NC}"
    read app_system_path

    # set remote ip
    echo -e "\n\n${Cyan}enter Host ip (NFS server)${NC}"
    read host_ip
fi

valid_ip $host_ip
if [ $? == 1 ]; then
    echo "Wrong Host IP !!!"
    help
fi

export LD_LIBRARY_PATH

# create cfg file
echo 'toolchain_path='$toolchain_path > $config_file
echo 'prebuild_lib='$prebuild_lib >> $config_file
echo 'proj_name='$proj_name >> $config_file
echo 'app_system_path'$app_system_path >> $config_file
echo 'host_ip='$host_ip >> $config_file

echo -e "\n\t----------- final setting\n"
echo $LD_LIBRARY_PATH
echo $toolchain_path
echo $prebuild_lib
echo $proj_name
echo $app_system_path
echo $host_ip

# main process
case $1 in
    $opt_run)
        echo -e "\n\n================== start $2 process ==================="
        $2
        ;;
    $opt_dbg)
        echo -e "\n\n================== start gdb server process ==================="
        echo -e "${Yellow} gdbserver connect to $host_ip:$gdb_port_num ${NC}"
        # echo -e "${Red} Need to show local ip ${NC}"

        # ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
        ifconfig | awk -F"[ :]+" '/inet addr/ && !/127.0/ {print $4}'| xargs echo -e "local IP: "
        gdbserver $host_ip:$gdb_port_num $2 &
        ;;

    *) ;;
esac












# echo -e $UbuntuIP":"$UbuntuIP_NFS_PATH "\n"
# echo -e cd $UbuntuIP_MNT_PATH/$SOCid/system/project/$approj "\n"
# pause "mount -t nfs -o tcp,nolock $UbuntuIP:$UbuntuIP_NFS_PATH $UbuntuIP_MNT_PATH ; cd $UbuntuIP_MNT_PATH "
# mount -t nfs -o tcp,nolock $UbuntuIP:$UbuntuIP_NFS_PATH $UbuntuIP_MNT_PATH ; cd $UbuntuIP_MNT_PATH
#
# cd $UbuntuIP_MNT_PATH/$SOCid/system/project/$approj
# export LD_LIBRARY_PATH=.:./bin/solib:../../lib/:../../lib_release/${_prebuilt_lib}/:../../toolchain/${_toolchain}/lib/
#
#
#
# if [[ $is_install_img_on_nfs == "str_debug" ]]; then
#   # rm -rf /usr/local/etc/dvdplayer/noap
#   export strpid=`pidof DvdPlayer`
#   export strpid=`pidof cobalt`
#   echo $strpid
#   gdbserver $UbuntuIP:$GdbPortNumber --attach $strpid  &

# fi


