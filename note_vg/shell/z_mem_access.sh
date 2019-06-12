#!/bin/bash

# set -e


RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
BLUE='\e[0;34m'
MAGENTA='\e[0;35m'
CYAN='\e[0;36m'
WHITE='\e[0;37m'
NC='\e[0m' # No Color

test_cnt=10


hwif=
enable_log=1

echo -e "" > err.log

verify_result()
{
    if [ $? -ne 0 ]; then
        echo -e "$2 -th '$@' " >> err.log
        # exit -1
        echo -e "${MAGENTA}----- error ${NC}"
    fi
    sleep $1 # sec
}

mem_base=0x20000000
mem_len=262144

i=1
while [ $i -le $test_cnt ]
do

    if [ $(($RANDOM % 2 + 1)) == 1 ]; then
        hwif=spi
    else
        hwif=uart
    fi

    if [ ${hwif} == "uart" ]; then
        # dev_path=/dev/ttyUSB0
        dev_path=/dev/ttyS0
        # dev_path=/dev/ttyAMA0
        speed_opt="--speed 115200"
    else
        dev_path=/dev/spidev0.0
        speed_opt="--speed 512000"
    fi

    # sudo chmod 666 ${dev_path}

    echo -e "${GREEN}****************************${NC}"
    echo -e "${GREEN}***  Test count ${i}   *****${NC}"
    echo -e "${GREEN}***  interface ${hwif} *****${NC}"
    echo -e "${GREEN}****************************${NC}"

    mod_value=$(($mem_len / 4 - 7))

    addr=$(($RANDOM % $mod_value * 4 + $mem_base))

    len=$(($RANDOM % 4 + 1))
    (( i++ ))

    addr_hex=`echo "ibase=10;obase=16;$addr" | bc`
    addr_hex=`echo -e "0x$addr_hex"`

    j=1
    data=
    while [ $j -le $len ]
    do
        data="$data$(($RANDOM % 4294967295)) "
        (( j++ ))
    done

    echo -e "${CYAN}\n========== test wd ==========\n ${NC}"
    ./out/bin/MemProber --commif ${hwif} --device ${dev_path} --log ${enable_log} ${speed_opt} wd ${addr_hex} ${data}
    verify_result 1 ${i} ${hwif} wd ${addr_hex} ${data}

    echo -e "${i} ${hwif} wd ${addr_hex} ${data}... ${mod_value}"

    ./out/bin/MemProber --commif ${hwif} --device ${dev_path} --log ${enable_log} ${speed_opt} rd ${addr_hex} $len 1
    verify_result 1 ${i} ${hwif} rd ${addr_hex} $len 1

done
