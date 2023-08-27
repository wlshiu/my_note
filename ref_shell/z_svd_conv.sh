#!/bin/bash

help()
{
    echo -e "usage: $0 [svd file]"
    exit -1
}

if [ $# != 1 ]; then
    help
fi


SVD_FILE=$1

filename="${SVD_FILE%.*}"


KEIL_MDK="/C/Keil_v5/UV4"
env_setup_file=__env.sh
echo "export PATH=\"\$KEIL_MDK:\$PATH\"" >> $env_setup_file

source $env_setup_file

rm -f $env_setup_file


# SVDConv.exe ${SVD_FILE} --generate=header --fields=macro --fields=enum --fields=struct
SVDConv.exe ${SVD_FILE} --generate=header --fields=macro --fields=enum # --fields=struct

SVDConv.exe ${SVD_FILE} --generate=sfr

# SfrCC2.exe ${SVD_FILE}

cat > t.py << EOF
#!/usr/bin/env python3

import sys
import argparse
import re

parser = argparse.ArgumentParser(description='Reconvert header file after SVDConv')
parser.add_argument("-i", "--Input", type=str, help="Input h file")
parser.add_argument("-o", "--Output", type=str, help="Output h file")

args = parser.parse_args()


with open(args.Output, 'w') as fout:
    with open(args.Input) as fin:
        for line in fin:
            match_line = re.search(r'^}\s+\w+_Type;', line)
            if match_line:
                if not "IRQn_Type" in line:
                    line = line.replace('_Type;', '_TypeDef;')

            match_line = re.search(r'^\#define\s+\w+\s+\(\(\w+_Type\*\)', line)
            if match_line:
                line = line.replace('_Type', '_TypeDef')

            fout.writelines(line)
            match_line = re.search(r'^\#define\s+\w+_Msk', line)
            if match_line:
                cur_line = match_line.group().split('_Msk')
                if cur_line:
                    new_line = cur_line[0]
                    new_line = new_line.replace('#define', '')
                    fout.writelines('#define' + new_line + '                     ' + new_line + '_Msk\n')

        print('done~~')

EOF

chmod +x t.py

mv -f ${filename}.h ${filename}_org.h

./t.py -i ${filename}_org.h -o ${filename}.h

rm -f t.py
