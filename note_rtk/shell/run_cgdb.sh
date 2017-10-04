#!/bin/bash -
#===============================================================================
# COPYRIGHT:Copyright (c) 2017, Wei-Lun Hsu
#
#          FILE: run_dbg.sh
#
#         USAGE: ./run_dbg.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Wei-Lun Hsu (WL), 
#       CREATED: 10/02/2017
#       LICENSE: GNU General Public License
#      REVISION:  ---
#===============================================================================

set -e

help ()
{
    echo -e "$0 [cmd options]"
    echo -e "    ex. $0 --args PROGRAM ARG1 ARG2..."
    exit 1;
}   # ----------  end of function help  ----------

if [ $# == 0 ]; then
    help
fi

export LD_LIBRARY_PATH=$HOME/local/lib/:/home/wl/local/lib/gstreamer-1.0/
#export LD_PRELOAD=./

cgdb $*

