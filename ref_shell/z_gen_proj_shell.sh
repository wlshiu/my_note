#!/bin/bash

function _check_var()
{
    if [ "$1" == "" ]; then
        exit 0
    else
        echo $1
    fi
}

account=$(zenity --entry --title="account" --text="Enter your account:" )
_check_var $account

chip_type=$(zenity --width=520 --height=320 --list --radiolist --title="chip type" \
          --column "Choose" --column "chip"\
          TRUE    "a12" \
          FALSE   "a9s" \
          FALSE   "a9")
_check_var $chip_type


linux_repo_manifest=$(zenity --width=520 --height=220 --list --radiolist --title="ambalink manifest type" \
                --column "Choose" --column "ambalink manifest type"\
                TRUE      "ambalink_sdk_a12" \
                )
_check_var $linux_repo_manifest

linux_focus_manifest=$(zenity --entry --title="ambalink focus manifest" --text="Enter Ambalink FOCUS manifest:" )
echo "linux_focus_manifest=$linux_focus_manifest"

ambalink_version=$(zenity --width=520 --height=220 --list --radiolist --title="ambalink version name" \
                 --column "Choose" --column "ambalink version"\
                 TRUE      "ambalink_sdk_3_10" \
                 )
_check_var $ambalink_version

case $chip_type in
    "a12")
        rtos_manifest=$(zenity --width=520 --height=520 --list --radiolist --title="RTOS manifest type" \
                      --column "Choose" --column "RTOS manifest type"\
                      TRUE      "sdk_main_partial" \
                      FALSE     "sdk_main_full" \
                      FALSE     "sdk_6_2_001_partial" \
                      FALSE     "sdk_6_2_001_full" \
                      FALSE     "sdk_6_2_002_partial" \
                      FALSE     "sdk_6_2_002_full" \
                      FALSE     "sdk_6_2_003_partial" \
                      FALSE     "sdk_6_2_003_full" \
                      )
        _check_var $rtos_manifest

        rtos_config=$(zenity --width=520 --height=520 --list --checklist --title="RTOS config" \
                    --column "Choose" --column "RTOS config"\
                    TRUE      "${chip_type}_app_connected_defconfig" \
                    FALSE     "${chip_type}_app_connected_ov4689_defconfig" \
                    FALSE     "${chip_type}_app_connected_taroko_ov4689_defconfig" \
                    )
        _check_var $rtos_config

        ambalink_config=$(zenity --width=520 --height=520 --list --checklist --title="ambalink config" \
                        --column "Choose" --column "ambalink config"\
                        TRUE      "${chip_type}_ambalink_app_defconfig" \
                        FALSE     "${chip_type}_ambalink_defconfig" \
                        FALSE     "${chip_type}_ambalink_taroko_defconfig" \
                        )
        _check_var $ambalink_config
        ;;
    "a9s")
        rtos_manifest=$(zenity --width=520 --height=520 --list --radiolist --title="RTOS manifest type" \
                      --column "Choose" --column "RTOS manifest type"\
                      TRUE      "sdk_main_partial" \
                      FALSE     "sdk_main_full" \
                      FALSE     "sdk_6_3_001_partial" \
                      FALSE     "sdk_6_3_001_full" \
                      )
        _check_var $rtos_manifest

        rtos_config=$(zenity --width=520 --height=520 --list --checklist --title="RTOS config" \
                    --column "Choose" --column "RTOS config"\
                    TRUE      "${chip_type}_app_connected_defconfig" \
                    FALSE     "${chip_type}_app_connected_imx789_defconfig" \
                    )
        _check_var $rtos_config

        ambalink_config=$(zenity --width=520 --height=520 --list --checklist --title="ambalink config" \
                        --column "Choose" --column "ambalink config"\
                        TRUE      "${chip_type}_ambalink_app_defconfig" \
                        FALSE     "${chip_type}_ambalink_defconfig" \
                        FALSE     "${chip_type}_ambalink_cheetah_defconfig" \
                        )
        _check_var $ambalink_config
        ;;
    "a9")
        ;;
    *)

    echo "Not support chip !!"
    exit
    ;;
esac

# /usr/local/gcc-arm-none-eabi-4_7-2013q3/bin
compiler_ver=$(zenity --width=620 --height=520 --list --radiolist --title="compiler" \
              --column "Choose" --column "gcc version"\
              FALSE     "gcc-arm-none-eabi-4_7-2013q3" \
              TRUE      "gcc-arm-none-eabi-4_9-2015q1" \
              )
_check_var $compiler_ver
echo "/usr/local/$compiler_ver/bin"

method=$(zenity --width=520 --height=320 --list --checklist --title="target task" \
       --column "Choose" --column "do what"\
       TRUE    "download-RTOS" \
       TRUE    "download-ambalink" \
       TRUE    "compiler-RTOS" \
       TRUE    "compiler-ambalink" \
       TRUE    "distribute-ambalink" \
       )
_check_var $method

if [ `echo $method | grep -e "distribute-ambalink"` ]; then
    wifi_driver_name=$(zenity --width=520 --height=520 --list --radiolist --title="wifi drive" \
                  --column "Choose" --column "wifi driver type"\
                  TRUE      "bcmdhd.tar.gz" \
                  )
fi

# work_path=$(zenity --file-selection --title="Select a directory" --directory)
# case $? in
#     0)
#         echo "\"$work_path\" selected.";;
#     1)
#         echo "Nothing selected.";;
#     1)
#         echo "An unexpected error has occurred.";;
# esac

branch_name=$(zenity --entry --title="local branch" --text="Enter your branch name:\n ex. test/master" )
if [ -z $branch_name ]; then
    branch_name=test/master
fi
_check_var $branch_name

# sed 's/foo/bar/g'
ambalink_config_array=( `echo $ambalink_config | sed 's/|/ /g'` )
rtos_config_array=( `echo $rtos_config | sed 's/|/ /g'` )


# create download RTOS shell
if [ `echo $method | grep "download-RTOS"` ]; then
    sh_download_rtos=download_rtos_$rtos_manifest.sh
    echo "create download RTOS"
    echo "#!bin/bash" > $sh_download_rtos
    echo "WORKDIR=\`pwd\`" >> $sh_download_rtos
    echo "mkdir rtos && cd rtos" >> $sh_download_rtos
    echo "repo init -u ssh://$account@ambtw-git.ambarella.net:29418/system/rtos2/manifest -b master -m $chip_type/$rtos_manifest.xml # --depth=1 " >> $sh_download_rtos
    echo "repo sync" >> $sh_download_rtos

    # ToDOo: check branch name exist or not
    echo "repo start $branch_name --all" >> $sh_download_rtos
    echo "cd \$WORKDIR" >> $sh_download_rtos
fi


# create download linux shell
if [ `echo $method | grep -e "download-ambalink"` ]; then
    sh_download_linux=download_linux_$linux_repo_manifest.sh
    echo "create download ambalink"
    echo "#!bin/bash" > $sh_download_linux
    echo "WORKDIR=\`pwd\`" >> $sh_download_linux
    echo "mkdir $ambalink_version " >> $sh_download_linux
    echo "cd $ambalink_version" >> $sh_download_linux
    echo "repo init -u ssh://amcode.ambarella.com:29418/boss_sdk/manifest -b ambalink_sdk -m $linux_repo_manifest.xml # --depth=1" >> $sh_download_linux
    if [ $linux_focus_manifest ]; then
        echo "cp -f \$WORKDIR/$linux_focus_manifest ./.repo/manifest.xml" >> $sh_download_linux
    else
        echo "if [ -f \"\$WORKDIR/rtos/rtos/linux_image/$ambalink_version.xml\" ]; then" >> $sh_download_linux
        echo "    cp -f \$WORKDIR/rtos/rtos/linux_image/$ambalink_version.xml ./.repo/manifest.xml" >> $sh_download_linux
        echo "fi" >> $sh_download_linux
    fi

    echo "repo sync" >> $sh_download_linux

    # ToDOo: check branch name exist or not
    echo "repo start $branch_name --all" >> $sh_download_linux
    echo "cd \$WORKDIR" >> $sh_download_linux
fi


# create free run shell
sh_free_run=_free_run.sh
echo "#!bin/bash" > $sh_free_run
echo "WORKDIR=\`pwd\`" >> $sh_free_run
if [ -f $sh_download_rtos ]; then
    #---- cmd source == cmd . e.g. source a.sh == . a.sh
    # echo ". $sh_download_rtos" >> $sh_free_run
    echo "sh ./$sh_download_rtos" >> $sh_free_run
    echo "" >> $sh_free_run
fi

if [ -f $sh_download_linux ]; then
    #---- cmd source == cmd . e.g. source a.sh == . a.sh
    # echo ". $sh_download_linux" >> $sh_free_run
    echo "sh ./$sh_download_linux" >> $sh_free_run
    echo "" >> $sh_free_run
fi


# all selected config
for j in "${rtos_config_array[@]}"
do
    for i in "${ambalink_config_array[@]}"
    do
        # create build linux shell
        if [ `echo $method | grep -e "compiler-ambalink"` ]; then
            sh_compiler_linux=compiler_linux_$i.sh
            echo "create compiler ambalink"
            echo "#!bin/bash" > $sh_compiler_linux
            echo "WORKDIR=\`pwd\`" >> $sh_compiler_linux

            echo "if [ -D \$WORKDIR/rtos/rtos/linux_image/patch/$ambalink_version ]; then " >> $sh_compiler_linux
            echo "    cp -rfp \$WORKDIR/rtos/rtos/linux_image/patch/$ambalink_version ./" >> $sh_compiler_linux
            echo "fi" >> $sh_compiler_linux

            echo "cd \$WORKDIR/$ambalink_version/ambarella/" >> $sh_compiler_linux
            echo "make O=../output/$i $i" >> $sh_compiler_linux
            echo "cd ../output/$i" >> $sh_compiler_linux
            echo "make" >> $sh_compiler_linux

            echo "cd \$WORKDIR" >> $sh_compiler_linux

            # create distribute SDK 
            if [ `echo $method | grep -e "distribute-ambalink"` ]; then
                sh_distribute_linux=distribute_linux_$i.sh
                echo "create distribute ambalink"
                echo "#!bin/bash" > $sh_distribute_linux
                echo "WORKDIR=\`pwd\`" >> $sh_distribute_linux
                echo "cd \$WORKDIR/$ambalink_version/ambarella/" >> $sh_distribute_linux
                echo "make AMBA_OUT_TARGET=$i distribute2 MANIFEST2=$chip_type/manifest_dailybuild.txt" >> $sh_distribute_linux
                echo "cd \$WORKDIR" >> $sh_distribute_linux
                
                sh_rebuild_distribute_linux=rebuild_distribute_linux_$i.sh
                echo "create re-build distribute ambalink"
                echo "#!bin/bash" > $sh_rebuild_distribute_linux
                echo "WORKDIR=\`pwd\`" >> $sh_rebuild_distribute_linux
                echo "cd \$WORKDIR/distribute/$ambalink_version/" >> $sh_rebuild_distribute_linux
                echo "mkdir external_sdk && cd external_sdk" >> $sh_rebuild_distribute_linux
                echo "tar -zxf ../../external_sdk/$wifi_driver_name" >> $sh_rebuild_distribute_linux
                echo "cd ../ambarella/" >> $sh_rebuild_distribute_linux
                echo "make AMBA_OUT_TARGET=$i TARGET=$i prepare_oem" >> $sh_rebuild_distribute_linux
                echo "make O=../output.oem/$i $i" >> $sh_rebuild_distribute_linux
                echo "cd ../output.oem/$i/ && make" >> $sh_rebuild_distribute_linux
                
                echo "cd \$WORKDIR" >> $sh_rebuild_distribute_linux
            fi
        fi

        # create build RTOS shell
        if [ `echo $method | grep -e "compiler-RTOS"` ]; then
            sh_compiler_rtos=compiler_rtos_[$j]-[$i].sh
            echo "create compiler RTOS"
            echo "#!bin/bash" > $sh_compiler_rtos
            echo "WORKDIR=\`pwd\`" >> $sh_compiler_rtos
            echo "export PATH=\$PATH:/usr/local/$compiler_ver/bin" >> $sh_compiler_rtos
            echo "cd \$WORKDIR/rtos/rtos" >> $sh_compiler_rtos
            echo "cp -f \$WORKDIR/$ambalink_version/output/$i/images/Image ./linux_image/Image" >> $sh_compiler_rtos
            echo "cp -f \$WORKDIR/$ambalink_version/output/$i/images/rootfs.ubi ./linux_image/rootfs.ubi" >> $sh_compiler_rtos
            echo "" >> $sh_compiler_rtos
            echo "make fwprog-clean" >> $sh_compiler_rtos
            echo "make $j" >> $sh_compiler_rtos
            echo "make" >> $sh_compiler_rtos

            echo "cd \$WORKDIR" >> $sh_compiler_rtos
        fi

        # free run for compiler linux
        if [ -f $sh_compiler_linux ]; then
            #---- cmd source == cmd . e.g. source a.sh == . a.sh
            # echo ". $sh_compiler_linux" >> $sh_free_run
            echo "sh ./$sh_compiler_linux" >> $sh_free_run
            echo "" >> $sh_free_run
        fi

        # free run for compiler RTOS
        if [ -f $sh_compiler_rtos ]; then
            #---- cmd source == cmd . e.g. source a.sh == . a.sh
            # echo ". $sh_compiler_rtos" >> $sh_free_run
            echo "sh ./$sh_compiler_rtos" >> $sh_free_run
            echo "" >> $sh_free_run
        fi
    done
done







