#!/bin/bash -
#===============================================================================
# Copyright (c) 2019, Wei-Lun Hsu
#
#          FILE: z_change_file_extension.sh
#
#         USAGE: ./z_change_file_extension.sh
#
#   DESCRIPTION:
#
#       OPTIONS: ---
#        AUTHOR: Wei-Lun Hsu (WL),
#       CREATED: Monday, January 07, 2019
#       LICENSE: GNU General Public License
#      REVISION:  ---
#===============================================================================

set -e

help()
{
    echo -e "$0 [old file extension] [new extension]"
    echo -e "$0 c cpp"
    exit -1;
}

if [ $# != 2 ]; then
    help
fi

old_extension=$1
new_extension=$2

for f in *.${old_extension}; do
    mv -- "$f" "$(basename -- "$f" ."${old_extension}").${new_extension}"
done
