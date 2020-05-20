#!/bin/bash

set -e

help()
{
    echo -e "usage: $0 [folder 1] [folder 2]"
    exit 1;
}


if [ $# != 2 ]; then
    help
fi 


# 'diff -r' : recursively compare all files and files in subdirectories
# 'diff -q' : output only whether files differ
# 'grep -e' : grep multiple keywords in one command
# 'grep -v' : inverse grep, catch the lines not containing keywords
# 'sort'    : sort the result

diff -qr $1 $2 | grep -v -e keyword1 -e keyword2 | sort > diffs.txt


