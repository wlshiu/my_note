#!/usr/bin/env python

# -*- coding: utf-8 -*
import serial
import time
import sys

SERIAL_PORT = '/dev/ttyS0'
BAUD_RATES = 115200
ser = serial.Serial(SERIAL_PORT, BAUD_RATES, timeout=0)

def main():
    is_wait = True
    while True:
        for i in range(1, 3):
            count = ser.inWaiting()
            if count != 0:
                is_wait = False
                recv = ser.read(count)
                sys.stdout.write(recv)
                sys.stdout.flush()
                #ser.write(recv)

            ser.flushInput()
            # time.sleep(0.5)
            time.sleep(1)

            if is_wait == False:
                # tx_data = str(i) + '\r\n'
                ser.write(str(i) + '\r\n') # send '2' and press enter '\r'

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        if ser != None:
            ser.close()
