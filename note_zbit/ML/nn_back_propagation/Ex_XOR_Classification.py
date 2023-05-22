#!/usr/bin/env python
# encoding: utf-8 

from neuralnetwork import *
import numpy as np
import matplotlib.pyplot as plt

dataset = [
((1, 1), [1]),
((-1, -1), [1]),
((1, -1), [0]),
((-1, 1), [0])]

ps = [v[0] for v in dataset]
fig = plt.figure()
ax1 = fig.add_subplot(111)
ax1.scatter([v[0] for v in ps[:2]], [v[1] for v in ps[:2]], s=10, c='b', marker="o", label='O')
ax1.scatter([v[0] for v in ps[2:]], [v[1] for v in ps[2:]], s=10, c='r', marker="x", label='X')
plt.show()

xor_nn = NeuralNetwork(learning_rate=0.95)
xor_nn.add_layer(NeuronLayer(input_num=2, neuron_num=3))
xor_nn.add_layer(NeuronLayer(input_num=3, neuron_num=1))
for i in range(3000):
    xor_nn.train(dataset)

x_dataset =[]
o_dataset = []
line = np.linspace(-1,1)
for x in line:
    for y in line:
        res = xor_nn.get_output([x, y])[0]
        if res > 0.5:
            o_dataset.append([x, y])
        else:
            x_dataset.append([x, y])

fig = plt.figure()
ax1 = fig.add_subplot(111)
ax1.scatter([v[0] for v in o_dataset], [v[1] for v in o_dataset], s=10, c='b', marker="o", label='O')
ax1.scatter([v[0] for v in x_dataset], [v[1] for v in x_dataset], s=10, c='r', marker="x", label='X')
plt.show()
