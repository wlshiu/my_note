#!/usr/bin/env python
# encoding: utf-8

from neuralnetwork import *
# import neuralnetwork

# [(inputs, outputs)]
dataset = [((0.3, 0.5), (0, 1))]

nn = NeuralNetwork()
hidden_layer = NeuronLayer(input_num=2, neuron_num=2, init_weights=[0.5, 0.3, 0.25, 0.6], bias=0.6)
output_layer = NeuronLayer(input_num=2, neuron_num=2, init_weights=[0.1, 0.25, 0.2, 0.7], bias=0.5)
nn.add_layer(hidden_layer)
nn.add_layer(output_layer)
nn.dump()

tracking = []
for i in range(2000):
    nn.train(dataset)
    tracking.append(nn.calculate_total_error(dataset))

#for (i, e) in enumerate(tracking):
# print "%sth square total error: %s" % (i+1, e)
print("NeuralNetwork 2-2-2, Except output:[0, 1], Real output:%s" % (nn.get_output([0.3, 0.5])))

nn2 = NeuralNetwork()
nn2.add_layer(NeuronLayer(input_num=2, neuron_num=5))
nn2.add_layer(NeuronLayer(input_num=5, neuron_num=5))
nn2.add_layer(NeuronLayer(input_num=5, neuron_num=2))
for i in range(2000):
    nn2.train(dataset)
print("NeuralNetwork 2-5-5-2, Except output:[0, 1], Real output:%s" % (nn2.get_output([0.3, 0.5])))

# When model is too complex, it need more iterations to train
#nn3 = NeuralNetwork()
#nn3.add_layer(NeuronLayer(input_num=2, neuron_num=30))
#nn3.add_layer(NeuronLayer(input_num=30, neuron_num=2))
#for i in range(200000):
#    nn3.train(dataset)
#print "NeuralNetwork 2-30-2, Except output:[0, 1], Real output:%s" % nn3.get_output([0.3, 0.5])
