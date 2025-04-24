#!/usr/bin/env python

import sys
import argparse
from argparse import RawTextHelpFormatter
import numpy as np
import matplotlib.pyplot as plt

'''
$ ./z_plot_data.py -i ./xxx.csv -c 3
'''
parser = argparse.ArgumentParser(description='Render data to waveform\n e.g. ./z_plot_data.py -i ./xxx.csv -c 3', formatter_class=RawTextHelpFormatter)
parser.add_argument("-o", "--Output", type=str, help="output waveform")
parser.add_argument("-i", "--Input", type=str, help="input csv file:\n"
                                                    "a, b, c, \n"
                                                    "0.000000, 0.000000, 32768.000000,\n")
parser.add_argument("-c", "--Columns", type=str, help="input column count (in csv)")

args = parser.parse_args()

'''
csv file
ideal-sin, ideal-cos, sim-sin, sim-cos,
0.000000, 32768.000000, 0.000000, 32767.000000,
57.190922, 32767.949219, 56.000000, 32767.000000,
...
'''


if not args.Input:
    print('No input parameter ...')
    sys.exit(1)

if not args.Columns:
    columns_max = 3
else:
    columns_max = int(args.Columns)

line_cnt = 0
x_axis = []
column_data = [[] for i in range(columns_max)]
x_name = ""
data_name = [[] for i in range(columns_max)]
err_rate = [[] for i in range(columns_max)]

with open(args.Input, 'r') as in_file:

    line = in_file.readline()
    items = line.split(', ')
    for i in range(columns_max):
        data_name[i] = items[i]


    while True:
        line = in_file.readline()

        if not line:
            break;

        x_axis.append(line_cnt);
        line_cnt = line_cnt + 1

        items = line.split(', ')
        for i in range(columns_max):
            column_data[i].append(float(items[i]))


plt.figure(figsize=(15, 9))

for i in range(columns_max):
    plt.plot(x_axis, column_data[i], '*-', label=data_name[i])

plt.legend(loc='upper right')


plt.savefig('data_waveform.jpg', dpi=300)
plt.show()


