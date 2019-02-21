#!/bin/bash -

set -e

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
NC='\e[0m'

toolchain_list="Exit $(which -a arm-none-eabi-gcc | xargs dirname)"
TOOLCHAIN_PATH=''

if [ -z $(which -a arm-none-eabi-gcc | xargs grep -q arm-none-eabi-gcc) ]; then
    echo -e "${Red}Can't find arm-none-eabi-gcc !${NC}"
    exit 1
fi


select option in ${toolchain_list}
do
    if [ "$option" = "Exit" ]; then
        # if user selects Exit, then exit the program
        exit 0
    elif [ -n "$option" ]; then
        TOOLCHAIN_PATH="$option"
        break
    else
        # if the number of the choice given by user is wrong, exit
        echo "Invalid choice ($REPLY)!"
    fi
done

echo -e "@@ ${TOOLCHAIN_PATH}"

