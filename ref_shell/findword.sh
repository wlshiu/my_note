#!/bin/bash

## Color Define
## ---------------------------------------------------------------------------
	red='\e[0;31m';     RED='\e[1;31m';     green='\e[0;32m';       GREEN='\e[1;32m';
	yellow='\e[0;33m';  YELLOW='\e[1;33m';  blue='\e[0;34m';        BLUE='\e[1;34m';
	magenta='\e[0;35m'; MAGENTA='\e[1;35m'; cyan='\e[0;36m';    CYAN='\e[1;36m';
	NCOL='\e[0m';
	export red RED green GREEN yellow YELLOW blue BLUE magenta MAGENTA cyan CYAN NCOL
## Stress Define
## ---------------------------------------------------------------------------
	BOLD='\033[1m'; NBOLD='\033[0m'
	ULINE='\033[4m'; NULINE='\033[0m'
	HL='\e[42m'; NHL='\e[m'
## ---------------------------------------------------------------------------

# WORKDIR=`pwd`
WORKDIR=./

function help()
{
	echo "USAGE: findword [find_pattern] [grep_word]"
	echo "       e.g.  findword '*amba*' amba_port"
	echo "             ps. '' is necessary in arg_1."
    exit 1
}

if [ $# != 2 ];then
   help
fi

echo -e "find "${magenta}"$1"${NCOL}", grep "${RED}"$2"${NCOL}

find $WORKDIR -type f -iname $1 -exec grep --color -E -niH "$2" {} \;

echo -e ${green}"seach done !"${NCOL}
