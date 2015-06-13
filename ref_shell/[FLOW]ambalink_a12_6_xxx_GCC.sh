#!bin/bash

WORKDIR=`pwd`

CURRENT_FOLDER_NAME=${PWD##*/}

#============== SELECT OPTIONS ==============
MY_ACCOUNT=wlhsu

local_branch_name=test/master


#----- rtos2_sdk -----
#   -a12/sdk_main_full.xml
#   -a12/sdk_main_partial.xml
#   -a12/sdk_6_2_002_full.xml
#   -a12/sdk_6_2_002_partial.xml
RTOS_SDK_TARGET_MANIFEST=a12/$CURRENT_FOLDER_NAME.xml
echo rtos sdk target manifest=$CURRENT_FOLDER_NAME.xml

#-- rtos target config
#   -a12_app_connected_defconfig
#   -a12_app_connected_ov4689_defconfig
#   -a12_mw_unittest_defconfig
RTOS_TARGET_CONFIG=a12_app_connected_ov4689_defconfig



#----- ambalink_sdk -----
AMBALINK_SDK=ambalink_sdk_3_10

AMBALINK_SDK_TARGET_MANIFEST=ambalink_sdk_a12.xml

#-- ambalink target config
#   -a12_ambalink_app_defconfig
#   -a12_ambalink_app_ar6003_defconfig
AMBALINK_TARGET_CONFIG=a12_ambalink_app_defconfig

#----- GCC version -----
#   -/usr/local/gcc-arm-none-eabi-4_7-2013q3/bin
#   -/usr/local/gcc-arm-none-eabi-4_9-2015q1/bin
GCC_VERSION_PATH=/usr/local/gcc-arm-none-eabi-4_9-2015q1/bin

#============== REPO SOURCE CODE ==============
#-- create folder
if [ ! -d "./rtos" ]; then
    mkdir rtos
fi
cd rtos

#-- download code
repo init -u ssh://$MY_ACCOUNT@ambtw-git.ambarella.net:29418/system/rtos2/manifest -b master --depth=10 -m $RTOS_SDK_TARGET_MANIFEST
repo sync

repo start $local_branch_name --all


cd $WORKDIR
#-- create folder
if [ ! -d "./$AMBALINK_SDK" ]; then
    mkdir $AMBALINK_SDK
fi
cd $AMBALINK_SDK

#-- download code
repo init -u ssh://amcode.ambarella.com:29418/boss_sdk/manifest -b ambalink_sdk --depth=30 -m $AMBALINK_SDK_TARGET_MANIFEST

MATCH_MANIFEST=$AMBALINK_SDK.xml
if [ -f "$WORKDIR/rtos/rtos/linux_image/$MATCH_MANIFEST" ]; then
    cp -f $WORKDIR/rtos/rtos/linux_image/$MATCH_MANIFEST ./.repo/manifest.xml
fi

repo sync
repo start $local_branch_name --all

#-- Replace with patch code
cd ..
cp -rfp $WORKDIR/rtos/rtos/linux_image/patch/$AMBALINK_SDK ./

#============== COMPILER CODE ==============
cd $WORKDIR/$AMBALINK_SDK/ambarella/
#-- select target config and output path
make O=../output/a12_ambalink $AMBALINK_TARGET_CONFIG
cd ../output/a12_ambalink
make

#----- GCC path -----
# Setup in ~/.bash_profile
#       export PATH=/usr/local/gcc-arm-none-eabi-4_9-2015q1/bin:$PATH
# or
export PATH=$PATH:$GCC_VERSION_PATH

cd $WORKDIR/rtos/rtos

#-- copy linux image file
cp -f $WORKDIR/$AMBALINK_SDK/output/a12_ambalink/images/Image ./linux_image/Image
cp -f $WORKDIR/$AMBALINK_SDK/output/a12_ambalink/images/rootfs.ubi ./linux_image/rootfs.ubi


make $RTOS_TARGET_CONFIG
make


