#!/bin/bash


Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
Cyan='\e[0;36m'
NC='\e[0m' # No Color

help ()
{
    echo -e "$0 -c directory"
    echo -e "$0 -d pack.cpio.gz"
    echo -e "$0 -xcp src_dir dest_dir"
    echo -e "\tpack/unpack files and skip .git/.svn/.repo/.a/.o/.so"
    echo -e "\t-c       pack"
    echo -e "\t-d       unpack"
    echo -e "\t-xcp     xcopy to an other directory"
    exit 1;
}

if [ $# != 2 -a $# != 3 ]; then
    help
fi

which cpio
if [ $? == 0 ]; then
    cmd_cpio=cpio
else
    which bsdcpio
    if [ $? == 0 ]; then
        cmd_cpio=bsdcpio
    else
        echo "No cpio cmd in current system !!"
        exit 1;
    fi
fi

set -e

output_file=${PWD##*/}.cpio.gz
target_dir=$2


case $1 in
    "-c")
        find $target_dir -type d -iname '.git*' -prune -o \
                         -type d -iname '.svn*' -prune -o \
                         -type d -iname '.repo*' -prune -o \
                         -type f -iname '*.cpio.gz' -prune -o \
                         -type f -iname '*.o' -prune -o \
                         -type f -iname '*.so' -prune -o \
                         -type f -iname '*.a' -prune -o \
                         -print | $cmd_cpio -Bo | gzip -6 > $output_file
        ;;

    "-d")
        gzip -dc $target_dir | $cmd_cpio -idm
        ;;

    "-xcp")
        find $target_dir -type d -iname '.git*' -prune -o \
                         -type d -iname '.svn*' -prune -o \
                         -type d -iname '.repo*' -prune -o \
                         -type f -iname '*.cpio.gz' -prune -o \
                         -type f -iname '*.o' -prune -o \
                         -type f -iname '*.so' -prune -o \
                         -type f -iname '*.a' -prune -o \
                         -print | $cmd_cpio -pd $3
        ;;

    *)
        help
    ;;

esac    # --- end of case ---

echo -e "${Yellow} process done... ${NC}"
