Machine Learning (ML)
---


# Tensor (張量)

Tensor 在物理上是指 Vector-Space 及其 Dual-Space (對偶空間) 上的多重線性對應(線性轉換), 目的是能夠創造更高維度的矩陣, 向量
> 在不同的向量基底, 可以描述相同的向量, e.g. Spatial v.s. frequency domain (空間域 轉換到 頻域)

而 Tensor 在工程上, 其實是描述一個多維陣列(multidimensional array)
> 多維度的 dataset 可當作是一個 tensor, e.g. 圖像(image)可以當作是一個 tensor (width * hight * RGB)
>> 通常會將 3-D 的 Tensor 用一個正方體表示

>> ![Tensor_dimensions](Tensor_dimensions.jpg)


# Bias (偏移值)

為尋找最佳相關係數(Correlation Coefficient)時, 可調整的偏移值

```
y = WX + b

b: Bias offset
```
