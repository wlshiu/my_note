#!/usr/bin/env python

import sys
import argparse
import re

parser = argparse.ArgumentParser()
parser.add_argument("-p", "--pattern", type=str, help="pattern file")
parser.add_argument("-i", "--input", type=str, help="input log file")
parser.add_argument("-o", "--output", type=str, help="output file", default='z_result.txt')
args = parser.parse_args()

# print "%s, %s\n" % (args.pattern, args.input)

keyword_list = (["change_state",
                "set_property",
                "async-start",
                "async-done",
                "first-frame",
                "flush",
                "done",
                "finalize",
                ])

pattern_file = open(args.pattern, 'r')
out_file = open(args.output, 'w')



for log_line in open(args.input):
    # for keyword in keyword_list:
    for keyword in open(args.pattern):
        if keyword[0] == '#':
            continue

        keyword = keyword.strip('\n')
        keyword = keyword.strip('\r')
        # print keyword
        if keyword in log_line:
            out_file.write(log_line)
            break

print "done~"



# =============================

# for line in pattern_file.readlines():
#     line = line.strip('\n')
#     # print line
#     is_exit = 0
#     for log_line in open(args.input):
#         if line in log_line:
#             time_stamp = log_line.split("[")[1].split("]")[0]
#             # print '%-80s %d' % (line, int(time_stamp, 10))
#             tmp_buf = '%-80s %d\n' % (line, int(time_stamp, 10))
#             out_file.write(tmp_buf)
#             is_exit = 1
#             break
#
#     if is_exit == 0:
#         tmp_buf = '%-80s **N/A**\n' % (line)
#         out_file.write(tmp_buf)
#
# pattern_file.close()
# print "done~"