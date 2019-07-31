#!/usr/bin/env python

import sys
import time

idx=1
while True:
    # if (idx % 4) == 0:
        # sys.stdout.write('\r/')
    # elif (idx % 4) == 1:
        # sys.stdout.write('\r-')
    # elif (idx % 4) == 2:
        # sys.stdout.write('\r\\')
    # elif (idx % 4) == 3:
        # sys.stdout.write('\r|')
        
    if (idx % 2) == 0:
        sys.stdout.write('\r+')
    elif (idx % 2) == 1:
        sys.stdout.write('\rx')

    sys.stdout.flush()
    time.sleep(0.1)
    idx = idx + 1

