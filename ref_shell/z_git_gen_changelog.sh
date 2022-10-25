#!/bin/bash


help()
{
    echo -e "usage: $0 <start tag> <end tag> <out file>"
    echo -e "  e.g. $0 v1.0.0 v2.0.0 CHANGELOG.md"
    exit -1;
}

if [ $# != 3 ]; then
    help
fi

start_tag=$1
end_tag=$2

log_file=tmp.log
out_file=$3

git log --decorate --oneline ${start_tag}..${end_tag} > ${log_file}

cat > t.py << EOF
#!/usr/bin/env python

import sys
import argparse
import re

parser = argparse.ArgumentParser(description='Parse log from git')
parser.add_argument("-i", "--Input", type=str, help="Input file")
parser.add_argument("-o", "--Output", type=str, help="Output Change Log")
parser.add_argument("-s", "--Start", type=str, help="Start tag")
parser.add_argument("-e", "--End", type=str, help="End tag")

args = parser.parse_args()

fix_msg = []
feat_msg = []

if not args.Start:
    print("No Start tag")
    sys.exit()

if not args.End:
    print("No End tag")
    sys.exit()

with open(args.Input, 'r') as fin:
    with open(args.Output, 'w') as f:
        sys.stdout = f  # Change the standard output to the file we created.

        for line in fin:
            '''
            be97595e fix: xxxxxxx
            5a8fcf25 feat: aaaaaaa
            71bd23cd docs: ccccccc
            '''
            patt = '([0-9a-fA-F]+) ([fixeatdocs]+):(.+)$'
            matchObj = re.search(patt, line)
            if matchObj:
                sha_id = matchObj.group(1)
                cmt_type = matchObj.group(2)
                cmt_str = matchObj.group(3)
                cmt_str = cmt_str.strip()
                if 'fix' in cmt_type:
                    fix_msg.append(cmt_str)
                elif 'feat' in cmt_type:
                    feat_msg.append(cmt_str)


        print("## %s\n" % (args.End))
        print("### Bug Fixes\n")
        for msg in fix_msg:
            print("+ %s" % (msg))

        print("\n### Features\n")
        for msg in feat_msg:
            print("+ %s" % (msg))

        print("\n## %s\n" % (args.Start))
EOF

chmod +x t.py

./t.py -i ${log_file} -o ${out_file} -s ${start_tag} -e ${end_tag}

rm -f ${log_file}
rm -f t.py