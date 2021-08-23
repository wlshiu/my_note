#!/bin/bash

TO="UTF-8"
FILE=$1
FROM=$(file -i $FILE | cut -d'=' -f2)

if [[ $FROM = "binary" ]]; then
    echo "Skipping binary $FILE..."
    exit 0
fi

if [[ $FROM = $TO ]]; then
    echo "no change $FILE..."
    exit 0
fi

mv -f $FILE $FILE.bak

iconv -f $FROM -t $TO $FILE.bak > $FILE
ERROR=$?

if [[ $ERROR -eq 0 ]]; then
    echo -e "Converting $FILE..."
else
    echo -e "Error on $FILE"
fi
