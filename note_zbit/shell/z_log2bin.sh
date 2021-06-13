#!/usr/bin/env python

import sys
import argparse
import struct
import string
# import re


"""
#input format
00000000 | 20000820 000000C1 000000D9 000000DB
00000004 | 00000000 00000000 00000000 00000000
00000008 | 00000000 00000000 00000000 000000DD
0000000C | 00000000 00000000 000000DF 000000E1
"""
parser = argparse.ArgumentParser(description='Convert hex file to binary file')
parser.add_argument("-o", "--Output", type=str, help="output bin file")
parser.add_argument("-i", "--Input", type=str, help="input hex file")

args = parser.parse_args()


if args.Output:
    fout = open(args.Output, 'w+b')

word_addr = 0
i = 0
print(args.Input)
fin = open(args.Input, 'r')
lines = fin.readlines()
fin.close()

for i in range(len(lines)):
    line = lines[i]
    data = line.split()
    for j in range(4):
        value = int(data[2+j], 16)
        bin_data = struct.pack("I", value)
        fout.write(bin_data)

fout.close()
