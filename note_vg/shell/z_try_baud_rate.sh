#!/bin/bash

set -e

bardrates=(
921600
460800
230400
115200
57600
9600
)

target_bard=

for br in "${bardrates[@]}"; do
    echo -e "$br"
    if [ $(($RANDOM % 2 + 1)) == 1 ]; then
        target_bard=${br}
        break;
    fi
done

echo -e "==== $target_bard"
