#!/usr/bin/env python

# import matplotlib.animation as animation
import matplotlib.pyplot as plt
import numpy as np

fig = plt.figure()

ax = plt.gca()

# [ax.spines[i].set_visible(True) for i in ["bottom", "right"]]
# ax.spines['bottom'].set_position(('data', 0))
# ax.spines['left'].set_position(('data', 0))

"""
"left"/"right"/"top"/"bottom"/"circle"
"""
def gatt(y, x):

    """甘特圖
    y-axis
    x-axis
    """

    for j in range(len(y)): #工序j
        i = y[j] - 1  #機器編號i

        """
        plt.barh()
        barh()表示繪制水平方向的條形圖, 基本使用方法為:

        barh(y, width, left＝0, height＝0.8, edgecolor)

        各個參數解析如下:
        - y         : 在 y軸上的位置
        - width     : 條形圖的寬度(從左到右的哦)
        - left      : 開始繪制的 x坐標
        - edgecolor : 圖形邊緣的顏色
        """

        # scaling
        if j == 0:
            plt.barh(i, x[j])
            plt.text(np.sum(x[:j + 1]) / 8, i, 'J%sT%s' % ((j+1), x[j]), color="white", size=8)
        else:
            plt.barh(i, x[j], left=(np.sum(x[:j])))
            plt.text(np.sum(x[:j]) + x[j]/8, i, 'J%sT%s' % ((j+1), x[j]), color="white", size=8)


def on_press(event):
    print("posistion: ", event.button, event.xdata, event.ydata)

if __name__ == "__main__":

    # generate 35 symbols in range = [1, 7)
    m = np.random.randint(1, 7, 35)

    # generate 35 symbols in range = [15, 25)
    t = np.random.randint(15, 25, 35)

    gatt(m, t)

    plt.yticks(np.arange(max(m)), np.arange(1, max(m)+1))
    fig.tight_layout()
    fig.canvas.mpl_connect('button_press_event', on_press)
    plt.show()
