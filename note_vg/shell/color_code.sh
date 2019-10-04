#!/bin/bash
TEXT=" text "
RESET="\x1b[0m"

echo -n '              '

for i in `seq 0 7`; do
    echo -n "   4${i}m "

done
echo


for S in `seq 0 8`; do
    if [ $S = '3' ] || [ $S = '6' ]; then
        continue
    fi

    for F in `seq 30 37`; do

        CODE=`echo "${S};${F};m"`
        echo -n " $CODE"

        echo -ne " \x1b[${CODE}${TEXT}${RESET}"
        for B in `seq 40 47`; do

            CODE=`echo "${S};${F};${B}m"`

            echo -ne " \x1b[${CODE}${TEXT}${RESET}"

        done
        echo 
    done
done