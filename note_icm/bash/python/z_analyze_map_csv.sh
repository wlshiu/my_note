#!/usr/bin/python3

"""
reference
https://vimsky.com/zh-tw/examples/detail/python-method-openpyxl.styles.PatternFill.html

hex color:
https://www.sioe.cn/yingyong/yanse-rgb-16/

description:
    convert/filter data of CSV file from GNU map file (as below)
    .bss.g_usr_isr_table, 0x90, 144, obj\debug\device_v6770\hal\hal.o
"""

import sys
import argparse
from openpyxl import Workbook
from openpyxl.styles import PatternFill

parser = argparse.ArgumentParser()
parser.add_argument("-o", "--Output", type=str, help="output file")
parser.add_argument("-i", "--Input", type=str, help="input map csv file")

args = parser.parse_args()

if args.Input:
    input_file = args.Input
else:
    sys.stdout.write("use '-h' to check usage")
    sys.exit(-1)

target_patt = [ ['test', 'F5DEB3'],
                ['evb', 'E1FFFF'],
                ['hal', 'FFFACD']]

wb = Workbook()
ws = wb.active

for line in open(input_file):
    for i in range(len(target_patt)):
        cur_patt = target_patt[i]
        if cur_patt[0] in line:
            item = line.split(', ')
            ws.append([item[1].replace('0x', ''), item[0], item[2], item[3]])
            fill = PatternFill("solid", fgColor=target_patt[i][1])
            ws.cell(row=ws.max_row, column=4).fill = fill


wb.save('create_sample.xlsx')
