#!/bin/bash
# Author: abu
# filename: dasm
# Description: puts disassembled objectfile to std-out

OBJDUMP=objdump

if [ $# = 2 ]; then
    sstrg="^[[:xdigit:]]{2,}+.*<$2>:$"
    ${OBJDUMP} -d $1 | awk -F"\n" -v RS="\n\n" '$1 ~ /'"$sstrg"'/'
elif [ $# = 1 ]; then
    ${OBJDUMP} -d $1 | awk -F"\n" -v RS="\n\n" '{ print $1 }'
else
    echo "You have to add argument(s)"
    echo "Usage:   "$0 " arg1 arg2"
    echo "Description: print disassembled label to std-out"
    echo "             arg1: name of object file"
    echo "             arg2: name of function to be disassembled"
    echo ""
    echo "         "$0 " arg1       print labels and their rel. addresses"
fi



#####################################
## By typing dasm test and then pressing 'Tab' + 'Tab', you will get a list of all functions.
## By typing dasm test m and then pressing 'Tab' + 'Tab' all functions starting with m will be shown,
##   or in case only one function exists, it will be autocompleted.
#
# $ cat /etc/bash_completion.d/dasm.bash
# $ sudo vi /etc/bash_completion.d/dasm.bash
#    _dasm()
#    {
#        local cur=${COMP_WORDS[COMP_CWORD]}
#
#        if [[ $COMP_CWORD -eq 1 ]] ; then
#        # files
#        COMPREPLY=( $( command ls *.o -F 2>/dev/null | grep "^$cur" ) )
#
#        elif [[ $COMP_CWORD -eq 2 ]] ; then
#        # functions
#        OBJFILE=${COMP_WORDS[COMP_CWORD-1]}
#
#        COMPREPLY=( $( command nm --demangle=dlang $OBJFILE | grep " W " | cut -d " " -f 3 | tr "()" "  " | grep "$cur" ) )
#
#        else
#        COMPREPLY=($(compgen -W "" -- "$cur"));
#        fi
#    }
#
#    complete -F _dasm dasm
#
# $ chmod +x /etc/bash_completion.d/dasm.bash
# $ source /etc/bash_completion.d/dasm.bash
#







