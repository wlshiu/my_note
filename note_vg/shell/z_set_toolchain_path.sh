#!/bin/bash -

set -e

toolchain_list="Exit $(which -a arm-none-eabi-gcc | xargs dirname)"
toolchain_path=''

select option in ${toolchain_list}
do
    if [ "$option" = "Exit" ]; then
        # if user selects Exit, then exit the program
        exit 0
    elif [ -n "$option" ]; then
        toolchain_path="$option"
        break
    else
        # if the number of the choice given by user is wrong, exit
        echo "Invalid choice ($REPLY)!"
    fi
done

echo -e "@@ ${toolchain_path}"

