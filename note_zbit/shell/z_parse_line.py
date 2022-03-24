#!/usr/bin/env python

import sys
import argparse
import re

parser = argparse.ArgumentParser(description='Parse map file from GCC')
parser.add_argument("-i", "--Input", type=str, help="input file")
parser.add_argument("-o", "--Output", type=str, help="output file")

args = parser.parse_args()

with open(args.Input, 'r') as fin:
    with open('my.csv', 'w') as f:
        sys.stdout = f  # Change the standard output to the file we created.
        print("code, channel A, channel B")
        
        for line in fin:
            if '@Stage' in line:

                '''
                @Stage = 27  @B real = 0.001432 V  @A real = 0.001329 V
                '''
                patt = '@Stage = ([0-9]+) +@B real = ([0-9\.]+) V +@A real = ([0-9\.]+) V'
                matchObj = re.search(patt, line)
                if matchObj:
                    print("%d, %f, %f" % (int(matchObj.group(1)), float(matchObj.group(2)), float(matchObj.group(3))))


