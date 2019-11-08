#!/usr/bin/env python

from time import sleep
from threading import Thread, Event

e = Event()

def read_loop():
    while True:
        print "type something:",
        a = raw_input().strip()
        if a == 'exit':
            e.set() # set Event and exit main thread
        else:
            print "you typed:" + a

t = Thread(target = read_loop)
t.daemon = True # keypoint, if miss this, the read_loop thread still alive when timeout
t.start()

e.wait(10)

if e.is_set():
    print 'you typed exit'
else:
    print 'time out'
