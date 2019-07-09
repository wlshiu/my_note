#!/bin/bash

set -e

Yellow='\e[1;33m'
NC='\e[0m'

help()
{
    echo -e "${Yellow}usage: $0 [src_tree_path]"
    echo -e "    $0 ./${NC}"
    exit 1
}

if [ $# != 1 ]; then 
    help
fi


file_ext='*.[chS]'
srctree=$1

RCS_FIND_IGNORE="( -name SCCS -o -name BitKeeper -o -name .svn -o \
			  -name CVS -o -name .pc -o -name .hg -o -name .git \) \
			  -prune -o"

ignore="$(echo "$RCS_FIND_IGNORE" | sed 's|\\||g' )"
# tags and cscope files should also ignore MODVERSION *.mod.c files
ignore="$ignore ( -name *.mod.c ) -prune -o"
ignore="$ignore ( -path ${srctree}tools ) -prune -o"

find ${srctree} $ignore -name config -prune -o -name "$file_ext" -not -type l -print > cscope.files
find ${srctree} $ignore -name '*.ld' -not -type l -print >> cscope.files
