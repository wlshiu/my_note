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


#################
# only show the difference part
diff --color -ua  <(xxd -g 1 $1) <(xxd -g 1 $2)

# icdiff  <(xxd -g 1 $1) <(xxd -g 1 $2)