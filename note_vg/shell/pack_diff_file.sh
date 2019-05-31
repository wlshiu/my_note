#!/bin/bash

output_file=${PWD##*/}.cpio.gz

# cmd_cpio=cpio
cmd_cpio=bsdcpio.exe
diff_list=___diff.lst

# target_node=master
target_node=official_ns3-3.28

git diff --stat --name-only ${target_node}..HEAD  > ${diff_list}
cat ${diff_list} | ${cmd_cpio} -Bo | gzip -6 > ${output_file}

rm -f ${diff_list}
