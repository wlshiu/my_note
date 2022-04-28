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


# xxd.exe -u -g 1 $1 > $1.tmp
# xxd.exe -u -g 1 $2 > $2.tmp

#################
# only show the difference part
# diff --color -ua  <(xxd -g 1 $1) <(xxd -g 1 $2)



hexdump -e '16/1 "%02x " "\n"' $1 > $1.tmp
hexdump -e '16/1 "%02x " "\n"' $2 > $2.tmp

# pip install icdiff
icdiff.py  $1.tmp $2.tmp

rm -f ./$1.tmp
rm -f ./$2.tmp
