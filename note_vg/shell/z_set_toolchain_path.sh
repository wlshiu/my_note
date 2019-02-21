#!/bin/bash -


Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
NC='\e[0m'

toolchain_list="Exit $(which -a arm-none-eabi-gcc | xargs dirname)"
TOOLCHAIN_PATH=''

whereis arm-none-eabi-gcc | grep -q 'bin'
if [ $? != 0 ]; then
    echo -e "${Red}Can't find arm-none-eabi-gcc !${NC}"
    exit 1
fi

set -e

select option in ${toolchain_list}
do
    if [ "$option" = "Exit" ]; then
        # if user selects Exit, then exit the program
        exit 0
    elif [ -n "$option" ]; then
        # toolchain_path="$option"
        TOOLCHAIN_PATH="$option"
        break
    else
        # if the number of the choice given by user is wrong, exit
        echo "Invalid choice ($REPLY)!"
    fi
done

export TOOLCHAIN_PATH
echo -e "TOOLCHAIN_PATH=${TOOLCHAIN_PATH}/" > Makefile.toolchain
