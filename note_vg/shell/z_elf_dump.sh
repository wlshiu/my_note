#!/bin/bash -
#===============================================================================
# Copyright (c) 2019, Wei-Lun Hsu
#
#          FILE: z_elf_dump.sh
#
#         USAGE: ./z_elf_dump.sh
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
    echo -e "usage: $0 [elf_file]"
    echo -e "   $ $0 ./rom.elf"
    exit 1
}

if [ $# != 1 ]; then
    help
fi

payload=d.tmp

readelf -S $1
objcopy -I elf32-i386 -O binary --dump-section mydata=${payload} $1

py_file=t.py

echo -e "#!/usr/bin/python" > ${py_file}
echo -e "import sys\nimport os" >> ${py_file}

echo -e "fname='${payload}'" >> ${py_file}
echo -e "file_size = os.path.getsize(fname)" >> ${py_file}
echo -e "f_obj = open(fname, 'rb')" >> ${py_file}
echo -e "f_obj.seek(0x34)" >> ${py_file}
echo -e "data = f_obj.read(file_size - 0x34)" >> ${py_file}
echo -e "f_obj.close()" >> ${py_file}

echo -e "f_out = open('${payload}.jpg', 'wb')" >> ${py_file}
echo -e "f_out.write(data)" >> ${py_file}
echo -e "f_out.close()" >> ${py_file}

chmod +x t.py
./t.py

rm -f ${payload}

