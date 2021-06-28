#!/usr/bin/env python

import sys
import argparse
import struct
import string
import binascii

parser = argparse.ArgumentParser(description='Convert hex file to binary file')
parser.add_argument("-o", "--Output", type=str, help="output bin file")
parser.add_argument("-i", "--Input", type=str, help="input hex file")

args = parser.parse_args()

# fin = open(args.Input,'rb')
with open(args.Input, 'rb') as in_file:
    while True:
        bytesdata = in_file.read(4).hex()   # read 4 bytes in then new line it.
        if len(bytesdata) == 0:             # breaks loop once no more binary data is read
            break

        hexdata = bytesdata.upper()
        a = hexdata[6]+hexdata[7]+hexdata[4]+hexdata[5]+hexdata[2]+hexdata[3]+hexdata[0]+hexdata[1]
        print(a)

