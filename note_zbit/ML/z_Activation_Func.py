#!/usr/bin/env  python


import math
import numpy as np
import matplotlib.pyplot as plt


def sigmoid(x):
    return 1/(1+math.exp(-x))

def relu(x):
    if x < 0: return 0
    else: return x

def leaky_relu(x, a):
    '''
    負值乘上一個大於 0 的斜率 a
    '''
    if x < 0: return a*x
    else: return x

def softmax(x):
    """Compute softmax values for each sets of scores in x."""
    exp_x = np.exp(x)
    return exp_x / exp_x.sum(axis=0)


def plot(title, px, py):
    plt.plot(px, py)
    ax = plt.gca()
    ax.set_title(title)
    ax.spines['right'].set_color('none')
    ax.spines['top'].set_color('none')
    ax.xaxis.set_ticks_position('bottom')
    ax.spines['bottom'].set_position(('data',0))
    ax.yaxis.set_ticks_position('left')
    ax.spines['left'].set_position(('data',0))
    plt.show()


def main():
    # Init
    X = []
    dx = -10
    while dx <= 10:
        X.append(dx)
        dx += 0.1

    px = [x for x in X]

    # # Use sigmoid() function
    py = [sigmoid(x) for x in X]
    plot('sigmoid', px, py)

    # # Use relu() function
    py = [relu(x) for x in X]
    plot('relu', px, py)

    # # Use leaky_relu() function
    a = 0.07
    py = [leaky_relu(x, a) for x in X]
    plot('leaky_relu', px, py)

    # Use softmax() function
    py = softmax(X)
    plot('softmax', px, py)

    # Use softmax() function
    py = [math.tanh(x) for x in X]
    plot('tanh', px, py)

if __name__ == "__main__":
    main()