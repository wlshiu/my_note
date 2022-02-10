#!/usr/bin/python3
# -*- coding: utf-8 -*-

import argparse

from os import walk
from os.path import join
from os import listdir
from os.path import isfile, isdir

parser = argparse.ArgumentParser(description = 'search directory recursively')

parser.add_argument("-i", "--Input", type = str, help = "target directory")

args = parser.parse_args()

# set target directory
mypath = args.Input

#################################
# recursively list all files with absolute path
#################################

### Example 1
# for root, dirs, files in walk(mypath):
#     for d in dirs:
#         fullpath = join(root, d)
#         print(fullpath)
#
#     for f in files:
#         fullpath = join(root, f)
#         print(fullpath)


### Example 2
def search_dir(root_path):
    # Get all the names of files and sub-directories
    items = listdir(root_path)

    for t in items:
      # generate absolute path of items
      fullpath = join(root_path, t)

      # check fullpath is file or directy type
      if isfile(fullpath):
        # print("file：", t)
        continue

      elif isdir(fullpath):
        print("dir：", join(root_path, t))
        search_dir(fullpath)

search_dir(mypath)
