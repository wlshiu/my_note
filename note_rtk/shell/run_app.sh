#!/bin/sh
# on target board side

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
Cyan='\e[0;36m'
NC='\e[0m' # No Color

DEFAULT_AP_DIR=/usr/local/bin
LD_LIBRARY_PATH=/usr/local/bin/solib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH


help()
{
    echo -e "\n\nusage: $0 [executable fila]"
    exit 1;
}

if [ $# != 1 ]; then
    help
fi

if [ -f $DEFAULT_AP_DIR/RootApp ] && [ -x $DEFAULT_AP_DIR/RootApp ]; then
    echo -e "${Yellow}Running dvdplayer with RootApp ${NC}"
    if [ ! -e /usr/local/etc/dvdplayer/noaplogprint ]; then
        $DEFAULT_AP_DIR/RootApp $1&
    else
        $DEFAULT_AP_DIR/RootApp $1 > /dev/console 1>/dev/null &
    fi
else
    echo -e "${Yellow}Running dvdplayer${NC}"
    $1&
fi

