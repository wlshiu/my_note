#!/usr/bin/env python3

import sys
import argparse
import struct
import string

parser = argparse.ArgumentParser(description='Align verables with white space')
parser.add_argument("-o", "--Output", type=str, help="output txt file")
parser.add_argument("-i", "--Input", type=str, help="input txt file")

args = parser.parse_args()

if not args.Input or not args.Output:
    print('Wrong parameter ...')
    sys.exit(1)

if args.Output:
    fout = open(args.Output, 'w+b')


patt = ("#define", "#include")
align_boundary = 55

with open(args.Input, 'r') as fin:
    with open(args.Output, 'w') as fout:
        for line in fin.readlines():
            if any(s in line for s in patt):
                msg = line.split()

                i = 0
                for elem in msg:
                    i =  i + 1
                    if i == 3:
                        for j in range(align_boundary - len(msg[0]) - len(msg[1]) - 1):
                            fout.write(" ")

                    fout.write(elem)
                    fout.write(" ")

                fout.write("\n")
            else:
                fout.write(line)



