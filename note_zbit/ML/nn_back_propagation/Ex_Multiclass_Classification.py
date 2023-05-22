#!/usr/bin/env python
# encoding: utf-8 

from neuralnetwork import *
import numpy as np
import matplotlib.pyplot as plt

class_1 = [1, 0, 0 ,0]
class_2 = [0, 1, 0 ,0]
class_3 = [0, 0, 1 ,0]
class_4 = [0, 0, 0 ,1]

dataset = [
((1, 1),   class_1),
((-1, -1), class_2),
((1, -1),  class_3),
((-1, 1),  class_4)]

ps = [v[0] for v in dataset]
fig = plt.figure()
ax1 = fig.add_subplot(111)
ax1.scatter(ps[0][0], ps[0][1], s=10, c='b', marker="o")
ax1.scatter(ps[1][0], ps[1][1], s=10, c='r', marker="x")
ax1.scatter(ps[2][0], ps[2][1], s=10, c='g', marker="+")
ax1.scatter(ps[3][0], ps[3][1], s=10, c='k', marker=">")
plt.show()

nn = NeuralNetwork(learning_rate=0.95)
nn.add_layer(NeuronLayer(input_num=2, neuron_num=5))
nn.add_layer(NeuronLayer(input_num=5, neuron_num=4))
for i in range(3000):
    nn.train(dataset)

c1_dataset =[]
c2_dataset = []
c3_dataset = []
c4_dataset = []
line = np.linspace(-1,1)
for x in line:
    for y in line:
        # Transfer  [0.9822128352432817, 1.6591006309811044e-06, 0.014045853594642057, 0.014602293506500592] to [1,0,0,0]
        res = [round(v) for v in nn.get_output([x, y])]
        if res == class_1: c1_dataset.append([x, y])
        elif res == class_2: c2_dataset.append([x, y])
        elif res == class_3: c3_dataset.append([x, y])
        elif res == class_4: c4_dataset.append([x, y])
        else: pass

fig = plt.figure()
ax1 = fig.add_subplot(111)
ax1.scatter([v[0] for v in c1_dataset], [v[1] for v in c1_dataset], s=10, c='b', marker="o")
ax1.scatter([v[0] for v in c2_dataset], [v[1] for v in c2_dataset], s=10, c='r', marker="x")
ax1.scatter([v[0] for v in c3_dataset], [v[1] for v in c3_dataset], s=10, c='g', marker="+")
ax1.scatter([v[0] for v in c4_dataset], [v[1] for v in c4_dataset], s=10, c='k', marker=">")
plt.show()
