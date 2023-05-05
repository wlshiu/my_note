Machine Learning (ML)
---

# Inference (推論) v.s. Training

+ Training
    > 深度學習一開始並不知到要用什麼 kernel-Convolution (Weighting is unknown), 經由 `training` 反推出 Weighting values

+ Inference
    > 使用訓練過的 kernel-Convolution (已知的 Weighting values), `infer` 出資料走向, 並判定結果

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

# ONNX (Open Neural Network Exchange)

是 Microsoft 和 Facebook 提出, 用來表示深度學習模型的 open-format
>> 所謂開放就是 ONNX 定義了一組, 和`environment`, `platform` 均無關的標準格式, 用來增強各種 AI module 的互動性

換句話說, 無論你使用何種訓練框架訓練模型(e.g. TensorFlow/Pytorch/OneFlow/Paddle), 在訓練完畢後,
你都可以將這些框架的模型, 轉換為 ONNX 這種統一的格式進行儲存
> ONNX file 不僅僅儲存了神經網路模型的 Weighting values, 同時也儲存了模型的結構資訊, 以及網路中每一層的輸入輸出和一些其它的輔助資訊

# **Kernel Convolution (kernel function)** v.s. **filter weighting**

`Kernel Convolution` 由 Width/Hight 來指定, 是二維的觀念.
而 `filter` 是由 Width/Hight 及 Depth (RGB channels) 來指定, 是三維的觀念
> 因此 filter 可以看做是 Kernel Convolution 的集合 (在 spatial domain 上, 同時對 RGB channels 處理)


# Performance

通常評估一個模型時, 首先看的是精確度, 當精確度未達門檻時, 基本就不需後續的評估. <br>

當模型已達到一定的精確度後, 就需要進一步的指標來評估模型
> + 前向傳播時, 所需的計算力,
>> 反應了對 H/w (e.g. GPU) 性能要求的高低
> + 參數(weighting)個數
>> 反應所 memory 大小

+ `FLOPS (Floating-point Operations Per-Second)`
    > 注意全大寫, 指每秒浮點運算次數, 理解為計算速度, 是一個**衡量 H/w 性能**的指標

+ `FLOPs (Floating-point Operations)`
    > 注意 `s` 是小寫(s 為 Operation 的複數), 指浮點運算數, 可理解為計算量, 用來**衡量演算法/模型的複雜度**

+ FLOPs of Convolution

    ```
    假設單一 Channel = 1 的 Kernel Convolution = K_w * K_h

    單點特徵輸出的運算量 = 乘法數量 + 加法數量

    operator multiply: K_w * K_h
    operator add     : K_w * K_h - 1 (如果有 Bias, 則為 K_w * K_h)

    假設單一維度 N = 1 的 Output features = O_w * O_h

    總運算量 = (OP-Multiply + OP-Add + OP-Add_Bias) * Channels * Output-Resolution * N-Dimensions
             = ((K_w * K_h) + (K_w * K_h - 1) + 1) * Channel * O_w * O_h * N

    參數量   = 所有 Kernel Convolution weightings
             = (K_w * K_h) * Channel * N
    ```

    - Example

        ![Conv](Conv.gif)

        ```
        Kernel Convolution = 3*3
        Output features = 3*3
        Input Channel = 2
        Output N-Dimensions = 4

        總運算量 = (3*3 + 3*3) * 2 * 3*3 * 4 = 1296
        參數量   = 3*3 * 2 * 4 = 72
        ```

# Reference

+ [CNN 模型所需的計算力flops是什麼？怎麼計算？](https://zhuanlan.zhihu.com/p/137719986)
