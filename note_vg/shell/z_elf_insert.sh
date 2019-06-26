#!/bin/bash -
#===============================================================================
# Copyright (c) 2019, Wei-Lun Hsu
#
#          FILE: z_elf_insert.sh
#
#         USAGE: ./z_elf_insert.sh
#
#   DESCRIPTION:
#
#       OPTIONS: ---
#        AUTHOR: Wei-Lun Hsu (WL),
#       CREATED: 06/26/2019
#       LICENSE: GNU General Public License
#      REVISION:  ---
#===============================================================================

set -e

help()
{
    echo -e "usage: $0 [elf file] [inserted file] [section name]"
    echo -e "   $ $0 ./rom.elf test.bin .mysection"
    exit 1
}

if [ $# != 3 ]; then
    help
fi

elf_file=$1
payload=$2
section_name=$3

objcopy --readonly-text -I binary -O elf32-i386 -B i386 ${payload} ${payload}.o
# objcopy -I elf32-i386 --add-section ${section_name}=${payload}.o --set-section-flags ${section_name}=noload,readonly ${elf_file}

objcopy -I elf32-i386 --add-section ${section_name}=${payload}.o ${elf_file} ${elf_file}.ins

