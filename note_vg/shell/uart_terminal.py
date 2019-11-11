#!/usr/bin/env python

import serial
import threading
import sys
from time import sleep

baudrate_list = {
	1: 1200,
	2: 2400,
	3: 4800,
	4: 9600,
	5: 19200,
	6: 38400,
	7: 57600,
	8: 115200,
}

serial_port = serial.Serial()


def th_read():
    while True:
        data = serial_port.read();
        if data:
            sys.stdout.write(data)
            sys.stdout.flush()

def main():
    name = raw_input("Python Serial Sniffer\nEnter Device Name :")
    print("Select Baudrate :\n[1]. 1200\n[2]. 2400\n[3]. 4800\n[4]. 9600\n[5]. 19200\n[6]. 38400\n[7]. 57600\n[8]. 115200\n")
    while True:
        baudrate_no = input("Enter Number : ")
        if baudrate_no > 0 and baudrate_no < 9:
            break
    serial_port.baudrate = baudrate_list.get(baudrate_no, 115200)
    serial_port.port = "/dev/"+name
    serial_port.timeout = 1
    if serial_port.isOpen(): serial_port.close()
    serial_port.open()
    t1 = threading.Thread(target=th_read, args=())
    t1.daemon = True
    t1.start()
    while True:
        try:
            command = raw_input()
            serial_port.write('3')
        except KeyboardInterrupt:
            break
    serial_port.close()

if __name__ == '__main__':
    main()
