#!/usr/bin/env python

import sys
import argparse
import struct
import string

parser = argparse.ArgumentParser(description='Convert hex file to binary file')
parser.add_argument("-o", "--Output", type=str, help="output bin file")
parser.add_argument("-i", "--Input", type=str, help="input hex file")

args = parser.parse_args()


if args.Output:
    fout = open(args.Output, 'w+b')

"""
Input file context:
20000820
000000C1
000000D9
000000DB
00000000
00000000
000000DD
00000000
000000DF
000000E1
000000E3
000000E3
000000E3
000000E3
...
"""

fin = open(args.Input, 'r')
for line in fin.readlines():
    value = int(line, 16)
    # print("%08x" % value)
    a = struct.pack("L", value)
    fout.write(a)


fin.close()
fout.close()
