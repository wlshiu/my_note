#!/bin/sh
echo Launching WinMergeU.exe: $1 $2 $3 $4

"$PROGRAMFILES/winmerge/WinMergeU.exe" -e -u -dl "Local" -dr "Remote" "$1" "$2" "$3" "$4"
# "C:/Program Files (x86)/winmerge/winmergeu.exe" -e -u -dl "Local" -dr "Remote" "$1" "$2" "$3" "$4"