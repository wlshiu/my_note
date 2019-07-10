#!/bin/bash

# --recursive or -r or -R
astyle --ascii -A1 -xl -K -xW -M40 -p -k3 -W3 -c -z2 -n $*
