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

def readLine():
    line = ''
    while True:
        time.sleep(0.1)
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
    item_num = 0
    while True:
        rx_line = readLine()
        # TODO: parse received line string

        if do_send == True:
            # tx_data = str(i) + '\r\n'
            # ser.write(str(index) + '\r\n') # send '2' and press enter '\r'
            index += 1

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        if ser != None:
            ser.close()
