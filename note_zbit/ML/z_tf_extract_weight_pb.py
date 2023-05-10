#!/usr/bin/env python

#
# get weighting value from *.pb file
#

import argparse

import tensorflow as tf
from tensorflow.python.platform import gfile
from tensorflow.python.framework import tensor_util

parser = argparse.ArgumentParser(description='Extrace tf weighting values from *.pb file')
parser.add_argument("-i", "--Input", type=str, help="Input *.pb (protobuf format)")

args = parser.parse_args()

if not args.Input:
    print('Wrong parameter ...')
    sys.exit(1)

with tf.Session() as sess:
    print("load graph")
    with gfile.FastGFile(args.Input, 'rb') as f:
        graph_def = tf.compat.v1.GraphDef()
        graph_def.ParseFromString(f.read())
        sess.graph.as_default()
        tf.import_graph_def(graph_def, name='')
        graph_nodes=[n for n in graph_def.node]

wts = [n for n in graph_nodes if n.op=='Const']

path = args.Input + ".wts"
with open(path, 'w') as fout:
    for n in wts:
        print("Name of the node - %s" % n.name, file=fout)
        print("Value - ", file=fout)
        print(tensor_util.MakeNdarray(n.attr['value'].tensor), file=fout)
