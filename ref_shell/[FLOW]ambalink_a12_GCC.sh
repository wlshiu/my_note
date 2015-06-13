#!/bin/bash

# Please add "/usr/local/gcc-arm-none-eabi-4_7-2013q3/bin" to your PATH
#export PATH=$PATH:/usr/local/gcc-arm-none-eabi-4_7-2013q3/bin

#generate project folder
mkdir working_folder
cd working_folder
WORKDIR=`pwd`

# Checkout Linux 
mkdir ambalink_sdk_3_10
cd ambalink_sdk_3_10
repo init -u ssh://amcode.ambarella.com:29418/boss_sdk/manifest -b ambalink_sdk -m ambalink_sdk_a12.xml
repo sync

# Build Linux kernel and private drivers
#(note: don't specify -j jobs in the command line, it is specified in the config files)
cd ambarella/
make O=../output/a12_ambalink a12_ambalink_app_defconfig
# app_defconfig will use BRCM wifi driver. if you want to use ar6003 please use this command instead
# make O=../output/a12_ambalink a12_ambalink_app_ar6003_defconfig
cd ../output/a12_ambalink
make

#Upon finish, you will find several images in ambalink_sdk_3_10/output/a12_ambalink/images. Please copy them to RTOS/linux_image
# ambalink_sdk_3_10/output/a12_ambalink/images/rootfs.ubi   << rootfile system
# ambalink_sdk_3_10/output/a12_ambalink/images/Image  << linux kernel1



# Checkout ThreadX, please modify the link as ssh://${YourID}@ambtw-git.ambarella.net...
cd $WORKDIR
mkdir rtos
cd rtos
# repo init -u ssh://wlhsu@ambtw-git.ambarella.net:29418/system/rtos2/manifest -b master -m a12/sdk_main_partial.xml
repo init -u ssh://wlhsu@ambtw-git.ambarella.net:29418/system/rtos2/manifest -b master -m a12/sdk_6_2_001_partial.xml
repo sync

# Build ThreadX
# make a12_app_connected_defconfig
# if you want to build MW Unittest, please use this command instead
# make a12_mw_unittest_defconfig
# make

# Download firmware
# final firmware will place at rtos/out/fwprog/bst_bld_sys_dsp_rom_lnx_rfs.elf