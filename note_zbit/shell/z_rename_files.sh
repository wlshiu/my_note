#!/bin/bash

patt=ttt
new_patt=ccc

#
# rename file: ttt_foo.c -> ccc_foo.c
#

find . -type f -name 'ttt_*' | while read FILE ; do
    newfile="$(echo ${FILE} | sed -e 's/ttt/ccc/')" ;

    # mv "${FILE}" "${newfile}" ;
    echo ${newfile}
done
