#!/bin/bash
#start ICEman
/cygdrive/e/Andestech/AndeSight200MCU/ice/ICEman-sn801.exe -p 1234 -P 00000000000000000000000000000000 &
./IntelJ3.exe --image=spl0.bin --target=ag101p_16mb --fast --verify
#wait ICEman connect
sleep 5
#start gdb script
trap "" 2
/cygdrive/e/Andestech/AndeSight200MCU/toolchains/nds32le-elf-newlib-v3m-sn801/bin/nds32le-elf-gdb.exe -x gdb_script.txt
trap 2
sleep 5

