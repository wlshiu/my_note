#!/bin/python

import sys
import argparse
import struct
from array import *

argv_parser = argparse.ArgumentParser()
argv_parser.add_argument("-o", "--Output", type=str, help="output file")
argv_parser.add_argument("-i", "--Input", type=str, help="input file")

argvs = argv_parser.parse_args()

if argvs.Output:
    out_file = open(argvs.Output, 'w+b')
    
img_ver = 0x12345678
uid = 'nbrn'
value = -1

#
# struct.pack(format, args...)
#   format: 
#       1. 's' is mapping to '%c' in c language, 4s means 4 * '%c'
#       2. 'I' is mapping to '%u' in c language, 4s means 4 * '%u'
#  
#
# =====================================================================
# Format | C-Type             | Python                | Standard size
#   x    | pad byte           | no value              | 1
#   c    | char               | string of length 1    | 1
#   b    | signed char        | integer               | 1
#   B    | unsigned char      | integer               | 1
#   ?    | _Bool              | bool                  | 1
#   h    | short              | integer               | 2
#   H    | unsigned short     | integer               | 2
#   i    | int                | integer               | 4
#   I    | unsigned int       | integer or long       | 4
#   l    | long               | integer               | 4
#   L    | unsigned long      | long                  | 4
#   q    | long long          | long                  | 8
#   Q    | unsigned long long | long                  |  8
#   f    | float              | float                 | 4
#   d    | double             | float                 | 8
#   s    | char[]             | string                | 1
#   p    | char[]             | string                | 1
#   P    | void *             | long
# 
# ======================================================================
# The 1-st character of 'format' is used to express Byte Order, Size, and Alignment
# e.g. struct.pack("<HH", string) => pack 2 unsigned short with little-endian
# ----------------------
# Character | Byte order    | Size     | Alignment
#     @     | native        | native   | native
#     =     | native        | standard | none
#     <     | little-endian | standard | none
#     >     | big-endian    | standard | none
#     !     | network       | standard | none
#           | (= big-endian)|  

a = struct.pack("4sIi", uid[::-1], img_ver, value)

out_file.write(a)
out_file.close()


