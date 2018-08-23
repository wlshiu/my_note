#!/bin/bash

find ./system/include ./system/src ./system/project -type f -name '*.o' > tmp.file

cat tmp.file | sed 's/\.o$/\.cpp/' | xargs file | awk -F":" '{print ($2 != " ERROR") ? $1:""}' > list.file
cat tmp.file | sed 's/\.o$/\.c/' | xargs file | awk -F":" '{print ($2 != " ERROR") ? $1:""}' >> list.file

find ./system/include ./system/src/Application/AppClass \
    ./system/src/Filters ./system/src/Flows ./system/src/Include \
    ./system/src/Application/Win32/RSSClient \
    ./system/project/PanEuroDVB \
    -type f -name '*.h' >> list.file

rm -f tmp.file

cat list.file | cpio -o | gzip > pack.gz

# un-pack
# gzip -dc pack.gz | cpio -id -
