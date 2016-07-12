#!/bin/bash

output_file=${PWD##*/}.tar

tar -cf $output_file `git diff --stat --name-only test/master | awk '{print $1}'`

if [ -n "$2" ]; then
    mv -i  $output_file $2
fi

