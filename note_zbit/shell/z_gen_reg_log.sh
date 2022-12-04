#!/usr/bin/env python3
# Copyright (c) 2022, All Rights Reserved.
# @file    z_gen_reg_log.sh
# @author  Wei-Lun Hsu
# @version 0.1

import sys
import argparse
import re
from queue import Queue

parser = argparse.ArgumentParser(description='Parse regist header (form SVD) to log function')
parser.add_argument("-i", "--Input", type=str, help="Input file")
parser.add_argument("-o", "--Output", type=str, help="Output c file")
# parser.add_argument("-c", "--Opcode", type=str, help="Opcode Command")

args = parser.parse_args()

class OneRegister:
    def __init__(self, reg_name):
        self.name = reg_name
        self.bit_fields = None


if args.Input == None:
    print("Error: No Input !\n")
    exit()

if args.Output == None:
    print("Error: No Output !\n")
    exit()

g_all_registers = Queue()

g_has_get_module = False
g_has_get_reg_field = False

g_module_name = ''

with open(args.Input, 'r') as fin:
    with open(args.Output, 'w') as f:
        # sys.stdout = f  # Change the standard output to the file we created.

        g_has_get_module = False
        g_has_get_reg_field = False
        line_cnt = 0

        for line in fin:
            line_cnt = line_cnt + 1

            if g_has_get_module == False:

                if 'typedef struct {' in line:
                    g_has_get_module = True

                continue

            elif 'TypeDef;' in line:

                g_has_get_module = False
                g_has_get_reg_field = False

                patt = '^\s*} ([0-9A-Za-z_]+)_TypeDef;.*'
                matchObj = re.search(patt, line)
                if matchObj:
                    g_module_name = matchObj.group(1)

                continue

            elif g_has_get_reg_field == False:

                if re.search('^[\s]+union[\s]+{', line):

                    g_has_get_reg_field = True

                elif re.search('RESERVED[\d]+;', line):
                    continue

                elif re.search('\s+[_IOM]+\s+uint[32816]+_t\s+.+;', line):

                    # '__IOM uint32_t MAPR;'
                    patt = '\s+[_IOM]+\s+uint[32816]+_t\s+([0-9A-Za-z_]+)\s*;'
                    matchObj = re.search(patt, line)
                    if matchObj:
                        reg = OneRegister(matchObj.group(1))

                        g_all_registers.put(reg)

            elif g_has_get_reg_field == True:

                if re.search('^[\s]+}\s+;', line):

                    g_has_get_reg_field = False

                elif re.search('\s+[_IOM]+\s+uint[32816]+_t\s+.+;', line):

                    patt = '\s+[_IOM]+\s+uint[32816]+_t\s+([0-9A-Za-z_]+)\s*;'
                    matchObj = re.search(patt, line)
                    if matchObj:
                        reg = OneRegister(matchObj.group(1))

                        g_all_registers.put(reg)


        while not g_all_registers.empty():
            reg_name = g_all_registers.get().name
            print("printf(\"%s->%-10s = 0x%%X \\n\", %s->%s);" % (g_module_name, reg_name, g_module_name, reg_name))
