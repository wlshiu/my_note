#!/bin/bash

find . -name '*.c' ! -type d -exec bash -c 'expand -t 4 "$0" > ./e && mv ./e "$0"' {} \;
find . -name '*.h' ! -type d -exec bash -c 'expand -t 4 "$0" > ./e && mv ./e "$0"' {} \;
