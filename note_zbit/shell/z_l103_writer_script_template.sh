#!/bin/bash


scr_enter_icp='__enter.script'
scr_icp_main_proc='__main.script'
scr_leave_icp='__leav.script'
scr_all='__all.script'

## assign seed to random
RANDOM=$SECONDS

dev_name=l103

###########################
## enter

echo -e "\n## set SPVDD to 3.3V"        > ${scr_enter_icp}
# echo -e "exic mcp47cx 3.3 10"   >> ${scr_enter_icp}
# echo -e "wait 200"              >> ${scr_enter_icp}

echo -e "dut on"                       >> ${scr_enter_icp}
echo -e "wait 200"                     >> ${scr_enter_icp}

echo -e "bist tmode ${dev_name} 1"     >> ${scr_enter_icp}
echo -e "wait 10"                      >> ${scr_enter_icp}

echo -e "bist tmode ${dev_name} 0"     >> ${scr_enter_icp}
echo -e "wait 10"                      >> ${scr_enter_icp}

echo -e "bist tmode ${dev_name} 1"     >> ${scr_enter_icp}
echo -e "wait 10"                      >> ${scr_enter_icp}

###########################
## leave
echo -e "\n\n## DUT leave tmode"        > ${scr_leave_icp}
echo -e "bist tmode ${dev_name} 0"     >> ${scr_leave_icp}
echo -e "wait 10"                      >> ${scr_leave_icp}

echo -e "dut off"                      >> ${scr_leave_icp}
echo -e "wait 200"                     >> ${scr_leave_icp}

echo -e "exit"                         >> ${scr_leave_icp}

###########################
## process
echo -e "\n\n## main process" > ${scr_icp_main_proc}
cnt=0

while [ $cnt != 3 ]
do
    #
    # generate random number between 0 ~ 9,
    # ps. '$RANDOM' bash generate 0 ~ 32767
    #
    echo $(( $RANDOM % 100 ))    >> ${scr_icp_main_proc}
    cnt=$(($cnt+1))
done


###########################
## combine all script
cat ${scr_enter_icp} ${scr_icp_main_proc} ${scr_leave_icp} > ${scr_all}

rm -f $scr_enter_icp
rm -f $scr_icp_main_proc
rm -f $scr_leave_icp
# rm -f $scr_all

START_TIME=$SECONDS

sleep 1.5
# z_uart_scritp.sh COM4 115200 ${scr_all}

ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo -e "spent ${ELAPSED_TIME} sec"

