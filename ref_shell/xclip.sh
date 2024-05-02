#!/bin/bash
# This replicates xclip functionality used by pass in Cygwin/MSYS2
# Original author: https://tylor.io/2015/07/13/password-manager/

while [[ $# > 0 ]]
do
  key="$1"

  case $key in
    -o|-out)
    OUT=1
    shift
    ;;
    *)
    shift
    ;;
  esac
done

if [[ $OUT -eq 0 ]]; then
  cat - > /dev/clipboard
else
  cat /dev/clipboard
fi