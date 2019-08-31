#!/bin/bash

set -e

help()
{
    echo -e "usage: [$0] [quality] [url-youtube]"
    echo -e "  [quality]    0: list supported in this video"
    exit;
}

if [ $# != 2 ]; then
    help
fi

url=$2
q=$1

if [ ${q} == 0 ]; then
    ./youtube-dl -F ${url}
elif [ ${q} == -1 ]; then
    # default resolution
    ./youtube-dl ${url}
else
    ./youtube-dl -f ${q} ${url}
fi

