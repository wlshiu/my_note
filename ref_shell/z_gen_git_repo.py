#!/usr/bin/env python3

import os
import sys
import argparse

parser = argparse.ArgumentParser(description='Copyright (c) 2023 Wei-Lun Hsu. All Rights Reserved.\n Gen git repository with share folder')
parser.add_argument("-p", "--Proj", type=str, help="Project name")

args = parser.parse_args()

if not args.Proj:
    print('No project name ...')
    sys.exit(1)

cmd_str = ""
os.system('echo \"\nCopyright (c) 2023 Wei-Lun Hsu. All Rights Reserved.\n\"')

#  cmd_str = "echo %s" % (str(args.Proj))
#  os.system(cmd_str)


cmd_str = "mkdir %s" % (str(args.Proj))
os.system(cmd_str)
cmd_str = "cd %s && git init --bare --shared=group" % (str(args.Proj))
os.system(cmd_str)

#  os.system('git init --bare --shared=group')
#  os.system('cd ..')

cmd_str = "chmod -R 770 %s" % (str(args.Proj))
os.system(cmd_str)
