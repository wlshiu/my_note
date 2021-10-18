#!/usr/bin/env python

import sys
import argparse
import string
import re
import numpy as np
import matplotlib.pyplot as plt


parser = argparse.ArgumentParser(description='Analyze Map file of Kail-MDk')
parser.add_argument("-o", "--Output", type=str, help="output directory")
parser.add_argument("-i", "--Input", type=str, help="input map file")

args = parser.parse_args()

if not args.Input or not args.Output:
    if not args.Input:
        print('No input file ...')
    if not args.Output:
        print('No output directory ...')

    sys.exit(1)

symbol_table = []
region_list = []

def parse_func_symbols():
    global  symbol_table
    global  region_list
    is_start = False
    fout = 0
    exec_region_cnt = 0
    with open(args.Input, 'r') as fin:
        for line in fin:
            symbol_item = []

            if is_start == False:
                # skip dummp context
                if "Memory Map of the image" in line:
                    is_start = True
                    continue

                continue

            if 'Execution Region' in line:
                if fout:
                    fout.close()

                matchObj = re.search(r'^\s+ Execution Region (\w+) \(Exec base: 0x([0-9a-fA-F]+), Load base: 0x([0-9a-fA-F]+), Size: 0x([0-9a-fA-F]+), Max: 0x([0-9a-fA-F]+)', line)
                if matchObj:
                    region_name = '_' + matchObj.group(1) + '_'

                    a_region = []
                    a_region.append(int(matchObj.group(2), 16)) # base address
                    a_region.append(int(matchObj.group(5), 16)) # region max size
                    a_region.append(matchObj.group(1))          # region name
                    region_list.append(a_region)
                    print("%s: base= 0x%08X, size= %d, max= 0x%08X" % (matchObj.group(1), int(matchObj.group(2), 16), int(matchObj.group(4), 16), int(matchObj.group(5), 16)))

                    # open output file
                    fout = open(args.Output + region_name + '.txt', 'w')
                    fout.write("This is line %d\n" % exec_region_cnt)
                    exec_region_cnt = exec_region_cnt + 1

            if 'PAD' in line:
                continue

            matchObj = re.search(r'^\s+ 0x([0-9a-fA-F]+)\s+ 0x([0-9a-fA-F]+)\s+ 0x([0-9a-fA-F]+)\s+ ([a-zA-Z]+)\s+ ([RO]+)\s+ \d+\s+(.+)\.o\)$', line)
            if matchObj:
                symbol_item.append(int(matchObj.group(1), 16))  # base address
                symbol_item.append(int(matchObj.group(3), 16))  # symbol size
                symbol_item.append(matchObj.group(5))           # type, RO
                symbol_item.append(matchObj.group(6) + '.o)')   # object name
                symbol_table.append(symbol_item)
                # print("addr= 0x%08X, size= %5d, %s, %s.o)" %(int(matchObj.group(1), 16), int(matchObj.group(3), 16), matchObj.group(5), matchObj.group(6)))

            matchObj = re.search(r'^\s+ 0x([0-9a-fA-F]+)\s+ 0x([0-9a-fA-F]+)\s+ 0x([0-9a-fA-F]+)\s+ ([a-zA-Z]+)\s+ ([RO]+)\s+ \d+\s+(.+)\.o$', line)
            if matchObj:
                symbol_item.append(int(matchObj.group(1), 16))  # base address
                symbol_item.append(int(matchObj.group(3), 16))  # symbol size
                symbol_item.append(matchObj.group(5))           # type, RO
                symbol_item.append(matchObj.group(6) + '.o')    # object name
                symbol_table.append(symbol_item)
                # print("addr= 0x%08X, size= %5d, %s, %s.o" %(int(matchObj.group(1), 16), int(matchObj.group(3), 16), matchObj.group(5), matchObj.group(6)))


            if '===========================================' in line:
                break

def parse_data_symbols():
    global  symbol_table
    is_start = False
    with open(args.Input, 'r') as fin:
        for line in fin:
            symbol_item = []

            if is_start == False:
                # skip dummp context
                if "Image Symbol Table" in line:
                    is_start = True
                    continue

                continue

            matchObj = re.search(r'^\s+ ([\w.]+)\s+ 0x([0-9a-fA-F]+)\s+ ([Data]+)\s+ (\d+) (.+)$', line)
            if matchObj:
                symbol_item.append(int(matchObj.group(2), 16))  # base address
                symbol_item.append(int(matchObj.group(4), 16))  # symbol size
                symbol_item.append(matchObj.group(3))           # type, Data
                symbol_item.append(matchObj.group(1))           # object name
                symbol_table.append(symbol_item)
                # print("addr= 0x%08X, size= %5d, %s, %s %s" %(int(matchObj.group(2), 16), int(matchObj.group(4), 10), matchObj.group(3), matchObj.group(1), matchObj.group(5)))

            if 'STACK' in line:
                matchObj = re.search(r'^\s+ ([\w.]+)\s+ 0x([0-9a-fA-F]+)\s+ ([Section]+)\s+ (\d+) (.+)$', line)
                if matchObj:
                    symbol_item.append(int(matchObj.group(2), 16))  # base address
                    symbol_item.append(int(matchObj.group(4), 16))  # symbol size
                    symbol_item.append(matchObj.group(3))           # type, Data
                    symbol_item.append(matchObj.group(1))           # object name
                    symbol_table.append(symbol_item)
                    # print("addr= 0x%08X, size= %5d, Data, %s %s" %(int(matchObj.group(2), 16), int(matchObj.group(4), 10), matchObj.group(1), matchObj.group(5)))


            if '===========================================' in line:
                break


def save_file(fout, sym_start_addr, sym_size, type, sym_name):

        fout.write("%s, %6d, %s, %s\n" % ("{0:#0{1}x}".format(sym_start_addr, 8), sym_size, type, sym_name))


def draw():
    fig, gnt = plt.subplots()

    gnt.set_xlim(0x20000000, 0x20000100)

    gnt.set_xlabel('address')
    gnt.set_ylabel('symbols')

    gnt.grid(True)

    plt.show()

def main():
    global  symbol_table
    global  region_list
    parse_func_symbols()
    parse_data_symbols()

    region_list = np.array(region_list, dtype=object)
    region_list_sort = region_list[region_list[:, 0].argsort()] # sort by address

    symbol_table = np.array(symbol_table, dtype=object)
    symbol_table_sort = symbol_table[symbol_table[:, 0].argsort()] # sort by address

    # # dump elements
    # for i in range(len(symbol_table_sort)):
    #     print(symbol_table_sort[i])
    #
    # for i in range(len(region_list_sort)):
    #     print(region_list_sort[i])

    for i in range(len(region_list_sort)):
        addr_star = region_list_sort[i][0]
        addr_end  = region_list_sort[i][0] + region_list_sort[i][1]
        # print("0x%08x ~ 0x%08X" % (addr_star, addr_end))

        out_path = "%s/%08X_%08X.csv" % (args.Output, addr_star, addr_end)
        with open(out_path, 'w') as fout:
            fout.write("address, size, type, obj_name\n")

            for j in range(len(symbol_table_sort)):
                sym_base_addr = symbol_table_sort[j][0]
                sym_size      = symbol_table_sort[j][1]
                sym_end_addr  = sym_base_addr + sym_size

                if (addr_star <= sym_base_addr and sym_end_addr <= addr_end) or \
                   (sym_base_addr <= addr_end and sym_end_addr >= addr_end):
                    save_file(fout, sym_base_addr, sym_size, symbol_table_sort[j][2], symbol_table_sort[j][3])

if __name__ == "__main__":
    main()