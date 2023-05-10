#!/usr/bin/env python

import sys
import argparse
import os

from os import walk
from os.path import join
from tensorflow.python import pywrap_tensorflow

parser = argparse.ArgumentParser(description='Extrace tf weighting values')
parser.add_argument("-i", "--Input", type=str, help="Input directory")

args = parser.parse_args()

if not args.Input:
    print('Wrong parameter ...')
    sys.exit(1)

#
# The data which output training results from ML-KWS-for-MCU
#   ds_cnn_9621.ckpt-400.data-00000-of-00001
#   ds_cnn_9621.ckpt-400.index
#   ds_cnn_9621.ckpt-400.meta
#
for root_dir, dirs, files in walk(args.Input):
    for f in files:
        if ".index" in f:
            os.path.splitext(f)
            # print(os.path.splitext(f)[0])
            path = join(root_dir, os.path.splitext(f)[0])
            # print(path)

            # Read data from checkpoint file
            reader = pywrap_tensorflow.NewCheckpointReader(os.path.splitext(f)[0])
            var_to_shape_map = reader.get_variable_to_shape_map()

            # Print tensor name and values
            # for key in var_to_shape_map:
            #     print("name: ", key)
            #     print(reader.get_tensor(key))
                
            path = path + '.log'
            with open(path, 'w') as fout:
                for key in var_to_shape_map:
                    print("name: ", key, file=fout)
                    print(reader.get_tensor(key), file=fout)
                
                


