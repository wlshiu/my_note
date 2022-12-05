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
parser.add_argument("-i", "--Input", type=str, help="Input file path")
parser.add_argument("-o", "--Output", type=str, help="Output path of c file")
parser.add_argument("-m", "--Module", type=str, help="The target module name")
parser.add_argument("-b", "--BitField", type=str, help="Has extend with bit field or not")

args = parser.parse_args()

class Item:
    def __init__(self, item_name):
        self.name = item_name
        self.subitem = None


if args.Input == None:
    print("Error: No Input !\n")
    exit()

if args.Output == None:
    print("Error: No Output !\n")
    exit()

g_target_module = args.Module

g_has_extend_with_BF = False

if args.BitField != None:
    g_has_extend_with_BF = True

g_all_modules = Queue()

g_has_get_module = False
g_has_get_reg = False
g_has_get_reg_field = False

with open(args.Input, 'r') as fin:
    with open(args.Output, 'w') as f:
        # sys.stdout = f  # Change the standard output to the file we created.

        module_cur = None
        reg_cur = None
        g_has_get_module = False
        g_has_get_reg = False
        g_has_get_reg_field = False
        line_cnt = 0

        for line in fin:
            line_cnt = line_cnt + 1

            if g_has_get_module == False:

                if 'typedef struct {' in line:
                    g_has_get_module = True

                    module_cur = Item("tmp")

                    module_cur.subitem = Queue()

                continue

            elif 'TypeDef;' in line:

                g_has_get_module = False
                g_has_get_reg = False

                patt = '^\s*} ([0-9A-Za-z_]+)_TypeDef;.*'
                matchObj = re.search(patt, line)
                if matchObj:
                    module_cur.name = matchObj.group(1)

                    g_all_modules.put(module_cur)

                continue

            elif g_has_get_reg == False:

                if re.search('^[\s]+union[\s]+{', line):

                    g_has_get_reg = True

                elif re.search('RESERVED[\d\[\]]*;', line):
                    continue

                elif re.search('\s+[_IOM]+\s+uint[32816]+_t\s+.+;', line):

                    # '__IOM uint32_t MR;'
                    patt = '\s+[_IOM]+\s+uint[32816]+_t\s+([0-9A-Za-z_]+)\s*;'
                    matchObj = re.search(patt, line)
                    if matchObj:
                        reg_cur = Item(matchObj.group(1))

                        if module_cur != None:
                            module_cur.subitem.put(reg_cur)  # register

            elif g_has_get_reg == True:

                if re.search('^[\s]+}\s+;', line):

                    g_has_get_reg = False
                    g_has_get_reg_field = False

                elif re.search('\s+[_IOM]+\s+uint[32816]+_t\s+[0-9A-Za-z_]+;', line):

                    # '__IOM uint32_t MR;'
                    patt = '\s+[_IOM]+\s+uint[32816]+_t\s+([0-9A-Za-z_]+)\s*;'
                    matchObj = re.search(patt, line)
                    if matchObj:
                        reg_cur = Item(matchObj.group(1))

                        if module_cur != None:
                            module_cur.subitem.put(reg_cur)  # register

                elif re.search('\s+struct\s+{', line):

                    g_has_get_reg_field = True
                    reg_cur.subitem = Queue()

                elif g_has_get_reg_field == True:

                    if re.search('\s+}\s*.+_b;', line):

                        g_has_get_reg_field = False

                    else:

                        # __IOM uint8_t m_retry    : 2;
                        patt = '\s*[_IOM]\s+uint[16328]+_t\s+([0-9A-Za-z_]+)\s*:\s*[0-9]+\s*;'
                        matchObj = re.search(patt, line)
                        if matchObj:
                            reg_cur.subitem.put(matchObj.group(1))  # bit field


        while not g_all_modules.empty():
            module_cur = g_all_modules.get()

            if g_target_module == module_cur.name or g_target_module == None:
                print("void __log_%s_reg(%s_TypeDef *p%s)\n{" %(module_cur.name, module_cur.name, module_cur.name))
                print("    printf(\"\\n======== %s Reg ======\\n\");" % (module_cur.name))

            while not module_cur.subitem.empty():
                reg_item = module_cur.subitem.get()

                if g_target_module == module_cur.name or g_target_module == None:
                    print("    printf(\"  %s->%-15s = 0x%%X \\n\", p%s->%s);" % (module_cur.name , reg_item.name, module_cur.name, reg_item.name))

                    if g_has_extend_with_BF == True:
                        while not reg_item.subitem.empty():
                            bit_field = reg_item.subitem.get()
                            print("    printf(\"    %s.%-15s = 0x%%X \\n\", p%s->%s_b.%s);" % (reg_item.name, bit_field, module_cur.name, reg_item.name, bit_field))

            if g_target_module == module_cur.name or g_target_module == None:
                print("    return;\n}\n")
