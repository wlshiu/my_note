#!/bin/bash -
#===============================================================================
# COPYRIGHT:Copyright (c) 2017, Wei-Lun Hsu
#
#          FILE: gst_instrument.sh
#
#         USAGE: ./gst_instrument.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Wei-Lun Hsu (WL), 
#       CREATED: 10/04/2017
#       LICENSE: GNU General Public License
#      REVISION:  ---
#===============================================================================

set -e

LD_PRELOAD=$HOME/local/lib/libgstintercept.so GST_DEBUG_DUMP_TRACE_DIR=. gst-launch-1.0 -v playbin3 uri=file:///home/wl/work/gstreamer/splitvideo01.ogg

#gst-report-1.0 --dot playbin.gsttrace | dot -Tsvg > perf.svg

