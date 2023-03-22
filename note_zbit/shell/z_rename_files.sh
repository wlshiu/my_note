#!/bin/bash


help()
{
    echo -e "usage: $0 <pattern> <target>"
    echo -e "   $0 ttt ccc"
    echo -e "       rename file: aa/k/ttt_foo.c -> aa/k/ccc_foo.c"
    exit -1
}

if [ $# != 2 ]; then
    help
fi

patt=$1
new_patt=$2


#
# rename file: ttt_foo.c -> ccc_foo.c
#

find . -type f -name "${patt}*" | while read FILE ; do
    newfile="$(echo ${FILE} | sed -e 's/'$patt'/'$new_patt'/')" ;
    echo -e "${FILE}"
    echo -e "  => ${newfile}"
    mv "${FILE}" "${newfile}" ;

done
