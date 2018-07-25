#!/bin/bash -

set -e

help()
{
    echo -e "usage: $0 [keil map]"
    exit 1
}

if [ $# != 1 ];then
    help
fi

cat $1 | grep -E '^[ ]+[ExecutionLad]+[ ]Region' | sed 's:^[ ]*::g' > sct.tmp

cat > t.py << EOF
#!/bin/env python

import sys

file = open('sct.tmp', 'r')
for line in file.readlines():
    d = line.split(" (")
    sub_data = line.split("(")[1].split(")")[0]
    base = sub_data.split("0x")[1].split(",")[0]
    size = sub_data.split("0x")[2].split(",")[0]
    max = sub_data.split("0x")[3].split(",")[0]
    if (d[0].find("LR") != -1):
        print ''

    print '%s base: 0x%s, remain = %d KB' % (d[0], base, (int(max, 16) - int(size, 16)) / 1024)

file.close()
EOF

chmod +x t.py
./t.py

rm -f ./sct.tmp
rm -f ./t.py

