#!/usr/bin/env python

import sys
import argparse
import re

parser = argparse.ArgumentParser(description='Parse map file from Keil-C')
parser.add_argument("Input", type=str, help="input map file")

args = parser.parse_args()

line_arr = []

def print_list(the_list):
    cnt = 0
    for item in the_list:
        if cnt == 20:
            break

        if len(item):
            print '%s' % (item)
            cnt = cnt + 1


g_cnt = 1
for line in open(args.Input):

    if "Execution Region " in line:
        print 'Base: %s' % (line.split("Base: ")[1].split(", Size: ")[0])
        if g_cnt != 1:
            line_arr.sort(reverse=True)
            # print('\n'.join(map(str, line_arr)))
            print_list(line_arr)
            print ""
            line_arr[:] = []

        g_cnt = 1
        continue

    if "Image component sizes" in line:
        break

    '''
    re.findAll(pattern, input_string)
    '''
    patt = ' +0x[0-9A-Fa-f]+ +0x[0-9A-Fa-f]+.+ RW '
    if re.search(patt, line):
        line_arr.append(line.split("0x")[2].split("\n")[0])
        g_cnt = g_cnt + 1
        # print '%s' % (line.split("0x")[2].split("\n")[0])

    patt = ' +0x[0-9A-Fa-f]+ +0x[0-9A-Fa-f]+.+ RO '
    if re.search(patt, line):
        line_arr.append(line.split("0x")[2].split("\n")[0])
        g_cnt = g_cnt + 1


    # if " RW " in line:
    #     line_arr.append(line.split("0x")[2].split("\n")[0])
    #     g_cnt = g_cnt + 1
    #
    # if " RO " in line:
    #     line_arr.append(line.split("0x")[2].split("\n")[0])
    #     g_cnt = g_cnt + 1



