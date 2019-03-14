#!/bin/bash

F=output/out/amba_ssp_app.map
S=`grep -n _bss_start ${F} | awk -F ":" '{print $1}'`
E=`grep -n _bss_end ${F} | awk -F ":" '{print $1}'`

sed -n ${S},${E}p ${F} > tmp.map


echo "Maximum *fill* in Bytes"
grep "*fill" tmp.map | awk '{print $3}' | xargs printf "%d\n" | sort -un | tail -1
echo -e "\nBig tail"
grep "o)$" tmp.map | awk '{print $(NF-1), $(NF)}' | xargs printf "%d %s\n" | sort -n | tail

(grep '^[ ][.]bss[.].*o)$' tmp.map | awk '{print $1",", $3",", $4}') > tmp.csv
(grep -A 1 '^[ ][.]bss[.][a-zA-Z0-9_]*$' tmp.map | grep -v '^[-][-]' | sed ':a;N;$!ba;s/\( [.]bss[.a-zA-Z0-9_]*\)\n/\1 /g' | awk '{print $1",", $3",", $4}') >> tmp.csv

cat > t.py << EOF
#!/usr/bin/env python

import sys

for line in sys.stdin:
    d = line.split(', ')
    print '%s, %s, %d, %s' % (d[0], d[1], int(d[1], 0), d[2]),
EOF

chmod +x t.py
./t.py < tmp.csv > tmp2.csv
sort -k 3 -n tmp2.csv > map.csv
rm -f tmp*.csv

rm -f t.py
#rm -f tmp.map


