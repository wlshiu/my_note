#!/usr/bin/env python

import sys
import argparse
import numpy as np
import matplotlib.pyplot as plt

'''
$ ./z_plot_data.py -i ./cordic_rot_arm_q15.csv -c 5
'''
parser = argparse.ArgumentParser(description='Render data to waveform')
parser.add_argument("-o", "--Output", type=str, help="output waveform")
parser.add_argument("-i", "--Input", type=str, help="input csv file")
parser.add_argument("-c", "--Columns", type=str, help="input column count (in csv)")

args = parser.parse_args()

'''
csv file
degree, ideal-sin, ideal-cos, sim-sin, sim-cos,
0.000000, 0.000000, 32768.000000, 0.000000, 32767.000000,
0.100000, 57.190922, 32767.949219, 56.000000, 32767.000000,
...
'''


if not args.Input:
    print('No input parameter ...')
    sys.exit(1)

if not args.Columns:
    columns_max = 3
else:
    columns_max = int(args.Columns)


degree = []
column_data = [[] for i in range(columns_max)]
x_name = ""
data_name = [[] for i in range(columns_max)]
err_rate = [[] for i in range(columns_max)]

with open(args.Input, 'r') as in_file:

    line = in_file.readline()
    items = line.split(', ')
    for i in range(columns_max):
        if i == 0:
            x_name = items[0]
        else:
            data_name[i-1] = items[i]


    while True:
        line = in_file.readline()

        if not line:
            break;

        items = line.split(', ')
        for i in range(columns_max):
            if i == 0:
                degree.append(float(items[i]));
            else:
                column_data[i-1].append(float(items[i]))


        ideal_sin = abs(float(items[1]))
        ideal_cos = abs(float(items[2]))
        sim_sin = abs(float(items[3]))
        sim_cos = abs(float(items[4]))

        Denominator = ideal_sin
        if ideal_sin == 0:
            Denominator = 1

        err_rate[0].append(abs(sim_sin - ideal_sin)*100/Denominator)

        Denominator = ideal_cos
        if ideal_cos == 0:
            Denominator = 1
        err_rate[1].append(abs(sim_cos - ideal_cos)*100/Denominator)


# plt.subplot(2, 1, 1)
f, (ax1, ax2) = plt.subplots(2, sharex=True)

for i in range(columns_max - 1):
    ax1.plot(degree, column_data[i], label=data_name[i])

# plt.subplot(2, 1 ,2)
ax2.plot(degree, err_rate[0], label="err-sin")
ax2.plot(degree, err_rate[1], label="err-cos")

plt.xlabel(x_name)
# plt.ylabel('fix-point')
# plt.legend()

ax1.set_ylabel('fix-point')
ax2.set_ylabel('%%')

ax1.legend()
ax2.legend()
plt.savefig('data_waveform.jpg')
plt.show()


