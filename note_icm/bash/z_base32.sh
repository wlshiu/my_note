#!/bin/bash

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
NC='\e[0m'


# set -e

export in_dir=$2
export out_dir=$3

bin_raw=$4

help()
{
    echo -e "usage: $0 <-d/-e> <input-path> <output-path> <bin>"
    exit 1;
}

converter()
{
    name=$(echo $1 | base32 | sed 's:=:@:g')
    cat $1 > $out_dir/${name}
}

converter2()
{
    item=$(basename $1)
    path=$(echo $item | sed 's:@:=:g' | base32 -d)
    out=$(dirname $path)

    if [ ! -d "$out_dir/$out" ]; then
        echo ddd
        mkdir -p $out_dir/$out
    fi

    cp -f $in_dir/$item $out_dir/$path
}

export -f converter
export -f converter2


if [ $# != 4 ]; then
    help
fi

case $1 in
    "-d")
        find ${in_dir} -type f -exec bash -c 'converter2 "{}"' \;

        unzip -q ${bin_raw}
        ;;

    "-e")
        find ${in_dir} -type f -name '*.c' -exec bash -c 'converter "{}"' \;
        find ${in_dir} -type f -name '*.h' -exec bash -c 'converter "{}"' \;
        find ${in_dir} -type f -iname '*.s' -exec bash -c 'converter "{}"' \;
        find ${in_dir} -type f -iname '*.mk' -exec bash -c 'converter "{}"' \;

        zip -r -e ${bin_raw} ${out_dir} -q
        ;;

    *)
        help
        ;;

esac    # --- end of case ---

