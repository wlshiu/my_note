#!/bin/bash -
#===============================================================================
# Copyright (c) 2018, Wei-Lun Hsu
#
#          FILE: search_symbol.sh
#
#         USAGE: ./search_symbol.sh [map file of keil] [address]
#
#   DESCRIPTION:
#
#       OPTIONS: ---
#        AUTHOR: Wei-Lun Hsu (WL),
#       CREATED: 07/24/18
#       LICENSE: GNU General Public License
#      REVISION:  ---
#===============================================================================

set -e

help()
{
    echo -e "usage: $0 [keil map] [address]"
    echo -e "\t$0 xx.map 0x185560"
    exit 1
}

if [ $# != 2 ];then
    help
fi


MF=$1
Star=`grep -n "Image Symbol Table" ${MF} | awk -F ":" '{print $1}'`
End=`grep -n "Memory Map of the image" ${MF} | awk -F ":" '{print $1}'`

sed -n ${Star},${End}p ${MF} > sct.tmp

grep '^[ ]*[a-zA-Z0-9_]*[ ]*0x[a-fA-F0-9]*[ ]*Thumb Code[ ]*' sct.tmp | awk '{print $2 " " $1}' | xargs printf "%d %s\n" | sort -n > ___tmp


cat > t.py << EOF
#!/usr/bin/env python

import sys

argv_list=sys.argv
addr_target = int(argv_list[1].split("0x")[1], 16)

file = open('___tmp', 'r')
for line in file.readlines():
    addr = line.split(" ")
    if int(addr[0], 10) > addr_target:
        print 'x%08x   %s' % (int(prev_line.split(" ")[0], 10), prev_line.split(" ")[1])
        print 'x%08x   %s' % (int(line.split(" ")[0], 10), line.split(" ")[1])
        break;

    prev_line = line

file.close()
EOF

chmod +x t.py
./t.py $2

rm -f ./sct.tmp
rm -f ./___tmp
rm -f ./t.py
