#!/bin/bash

function help()
{
    echo "usage $0 [-p/-u] [file_list] [output_name]"
    echo " -p   pack files to *.cpio.gz"
    echo " -u   un-pack *.cpio.gz to directroy"
    exit 1
}

if [ $# != 3 ]; then
    help
fi

# cmd_cpio=cpio
cmd_cpio=bsdcpio

if [ $1 == "-p" ]; then
    # pack
    cat $2 | $cmd_cpio -o | gzip > $3.cpio.gz
elif [ $1 == "-u" ]; then
    # un-pack
    $cmd_cpio -id < $3
fi

## actually it should use cpio 'Copy-pass mode', like below:
# $ find . -depth -print0 | cpio --null -pvd new-dir
## The example shows copying the files of the present directory, and sub-directories to a new directory called new-dir.
## Some new options are the '-print0' available with GNU find, combined with the '--null' option of cpio.
## These two options act together to send file names between find and cpio, even if special characters are embedded in the file names.
## Another is '-p', which tells cpio to pass the files it finds to the directory 'new-dir'.