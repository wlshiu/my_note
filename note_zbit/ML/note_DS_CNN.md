DS-CNN (Depthwise Separable CNN)
---

**Kernel function 即 filter weighting**

## Standard CNN

標準的 CNN 是單一個 sample 的所有 channels 都一併做 convolution, 當**需要輸出 N 個維度, 就使用 N 個 filters**
> 下圖為 N = 3, channel = 2

![standard_cnn](standard_cnn.jpg)

由上圖, 其參數的數量為 `2*2*2*3 = 24` (kernel_x * kernel_y * channels * N 維度)

# Pointwise convolution

# Depthwise convolution

# Reference

+ [摺積神經網路中的Separable Convolution](https://yinguobing.com/separable-convolution/)
+ [PyTorch中的逐深度可分離摺積-Depthwise Separable Convolutions](https://zhuanlan.zhihu.com/p/523641344)
+ [深度可分卷積（MobileNet中的depthwise separable convolutions）](https://www.twblogs.net/a/5ef157de33e47b02063c7f42)

