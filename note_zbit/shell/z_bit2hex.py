#!/usr/bin/env python

import sys
import os
import argparse
import re

'''
#input format
Bit  ==>  76543210
Byte 00 - 00000001
Byte 01 - 00000000
Byte 02 - 10110100
Byte 03 - 00001001
Byte 04 - 00000010
Byte 05 - 01010000
Byte 06 - 01000000
Byte 07 - 00000000
Byte 08 - 00000000
Byte 09 - 00000000
Byte 10 - 00000000
Byte 11 - 00000000
Byte 12 - 00000000
Byte 13 - 00000000
Byte 14 - 00000000
Byte 15 - 00000000
Byte 16 - 00000000
Byte 17 - 00000000
Byte 18 - 00000000
Byte 19 - 00000000
Byte 20 - 01101101
Byte 21 - 00000010
Byte 22 - 00000000
Byte 23 - 00000000
Byte 24 - 11111111
Byte 25 - 10000000
Byte 26 - 00000010
Byte 27 - 00000111
Byte 28 - 11111111
Byte 29 - 10000000
Byte 30 - 00000010
Byte 31 - 00000100
'''

parser = argparse.ArgumentParser(description='Convert cdce913 config file to hex')
parser.add_argument("-o", "--Output", type=str, help="output h file")
parser.add_argument("-i", "--Input", type=str, help="input cdce913 config file")

args = parser.parse_args()

if not args.Input or not args.Output:
    print('Wrong parameter ...')
    sys.exit(1)

basename = os.path.basename(args.Input)
var_name = os.path.splitext(basename)[0]


with open(args.Input, 'r') as fin:
    with open(args.Output, 'a') as fout:
        fout.write("\nstatic const uint8_t      cdce913_%s[] = \n{\n    " % (var_name))

        for line in fin:
            matchObj = re.search(r'^Byte (\d+) - ([0,1]+)$', line)
            if matchObj:
                # print("reg[%02d] = 0x%02X" % (int(matchObj.group(1)), int(matchObj.group(2), 2)))
                fout.write("0x%02X, " % (int(matchObj.group(2), 2)))
                if matchObj.group(1) == '15':
                    fout.write("\n    ")

        fout.write("\n};\n")
