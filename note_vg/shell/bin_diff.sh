#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
BLUE='\e[0;34m'
MAGENTA='\e[0;35m'
CYAN='\e[0;36m'
WHITE='\e[0;37m'
NC='\e[0m' # No Color

help()
{
    echo -e "${YELLOW} $0 A.bin b.bin ${NC}"
    exit -1
}

if [ $# != 2 ]; then
    help
fi


# diff -y <(xxd -g 1 $1) <(xxd -g 1 $2)

# colordiff -y <(xxd -g 1 $1) <(xxd -g 1 $2)

# vimdiff <(xxd -g 1 -o 0 -l 100 $1) <(xxd -g 1 -o 0 -l 100 $2)
vimdiff <(xxd -g 1 $1) <(xxd -g 1 $2)

# cmp -l $1 $2 | gawk '{printf "%08X %02X %02X\n", $1, strtonum(0$2), strtonum(0$3)}'

