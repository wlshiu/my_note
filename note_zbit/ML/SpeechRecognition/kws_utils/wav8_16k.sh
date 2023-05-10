#!/bin/bash
# using：
# 將這個文件copy到對應的wav文件夾下面,用完記得刪除

for file in *.wav; do
    #echo $file
    c=${file}
    #echo $c
    sox $c -c 1 -b 16 -r 16000 new_$c
    rm -f $c
    mv new_$c $c
done
