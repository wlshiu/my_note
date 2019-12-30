#!/usr/bin/env python

# -*- coding: utf-8 -*
import serial
import time
import sys
import Queue as queue
import re

SERIAL_PORT = '/dev/ttyS0'
BAUD_RATES = 115200
# ser = serial.Serial(SERIAL_PORT, BAUD_RATES, timeout=0)
ser = serial.Serial(SERIAL_PORT, BAUD_RATES)
q = queue.Queue()
regex_total_items = re.compile(r'---total (\d+) items')
regex_ok = re.compile(r'OK')
regex_fail = re.compile(r'FAIL')

ORANGE = '\033[33m'
YELLOW = '\033[93m'
PINK = '\033[95m'
NC = '\033[0m'


def readLine():
    line = ''
    while True:
        time.sleep(0.3)
        count = ser.inWaiting()
        if count:
            for i in range(1, count):
                ch = ser.read(1)
                line += ch
                if ch == '\n':
                    sys.stdout.write(line)
                    sys.stdout.flush()
                    return line

            ser.flushInput()


def main():
    do_send = False
    index = 1
    cnt = 0
    item_num = 0
    while True:
        rx_line = readLine()
        if regex_total_items.search(rx_line):
            match = re.findall(regex_total_items, rx_line)
            item_num = int("".join(match))
            index = 1
            do_send = True

        elif regex_ok.search(rx_line):
            index += 1
            if index > (item_num - 2):
                break
            do_send = True

        elif regex_fail.search(rx_line):
            if index > (item_num - 2):
                break
            do_send = True

        if do_send == True:
            print "\n\n%s >>>> Test %d-th item >>>%s" % (YELLOW, index, NC)
            ser.write(str(index) + '\r\n')
            do_send = False


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        if ser != None:
            ser.close()
