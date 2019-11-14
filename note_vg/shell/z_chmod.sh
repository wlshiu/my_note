#!/bin/bash
# Copyright (c) 2019, All Rights Reserved.
# @file    z_chmod.sh
# @author  Wei-Lun Hsu
# @version 0.1

set -e

# you should execute at src-root

file_list_1=___tmp1.lst
file_list_2=___tmp2.lst

ignore_list=(
'.*\.sh'
'.*\.py'
'.*\.log'
'.*\.bin'
'.*\.elf'
'.*\.lst'
'tags'
'cscope*'
'GPATH'
'GRTAGS'
'GTAGS'
)

find . -type f \
    ! -path '*/tools/toolchain/*' \
    ! -path '*/tools/astyle/*' \
    ! -path '*/tools/scripts/kconfig/*' \
    ! -path '*/tools/uncrustify/*' \
    ! -path '*/out/*' \
    ! -path '*/html/*' \
    ! -path '*/.repo/*' \
    ! -path '*/.git/*' > ${file_list_1}

cp ${file_list_1} ${file_list_2}

for pattern in "${ignore_list[@]}"; do
    patt=`echo ${pattern} | sed 's:\/:\\\/:g'`
    sed -i '/'"${patt}"'/d' ${file_list_1}
done

cat ${file_list_1} | xargs chmod -x

# cat ${file_list_2} | grep -i '\.sh' | xargs chmod +x
# cat ${file_list_2} | grep -i '\.py' | xargs chmod +x

find . -name '*.sh' -not -path '*/tools/toolchain/*' -not -path '*/tools/uncrustify/*' -not -path '*/out/*' -not -path '*/.repo/*' -not -path '*/.git/*' -exec chmod +x {} \;

find . -name '*.py' -not -path '*/tools/toolchain/*' -not -path '*/tools/uncrustify/*' -not -path '*/out/*' -not -path '*/.repo/*' -not -path '*/.git/*' -exec chmod +x {} \;


rm -f ${file_list_1}
rm -f ${file_list_2}
