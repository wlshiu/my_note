#!/bin/bash

help()
{
    echo -e "usage: $0 [options] [c file]"
    echo -e "$0 -I../inc ./main.c"
    exit -1
}

if [ $# == 0 ]; then
    help
fi

echo -e "$#"

echo -e "$@"
echo -e "$*"

#####
# http://www.real-world-systems.com/docs/gpp.1.html
# '-E -dD': where the definitions (#define xxxx) are included 
# '-E -dM': list all included definitions
# '-E'    : Only do C-Macro expansion (NO compile)
# '-M'    : list included header files
# '-MM'   : list included header files except system header

gcc -E $*
