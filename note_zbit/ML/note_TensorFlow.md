TensorFlow
---

TensorFlow 是 Google 用 Python 開發的一款神經網路 Framework, 也是一個採用資料流圖來進行數值計算的開放原始碼軟體庫.

TensorFlow 是一個採用資料流程圖(data flow graphs), 用於**數值計算**的開源軟體庫
> + 節點(Nodes)
>> 在流程圖中表示數學操作, 資料輸出和輸入, 或是讀寫變數
> + 線(edges)
>> 表示在節點間相互聯繫的多維資料陣列, 即 Tensor (張量)

TensorFlow 最初由 Google brain 小組的研究員和工程師們開發出來,
用於機器學習和深度神經網路方面的研究, 但這個系統的通用性使其也可廣泛用於其他計算領域
> 一旦輸入端的所有 Tensor 準備好, 節點將被分配到各種計算設備, 完成非同步平行地執行運算

Tensor 從圖中流過的直觀圖就是這個工具取名為 Tensorflow 的原因

![tensors_flowing](tensors_flowing.gif)



TensorFlow 讓我們可以先繪製計算結構圖, 也可以稱是一系列可人機互動的計算操作,
然後把編輯好的 Python 檔案轉換成更高效的 C++, 並在後端進行計算

TensorFlow 是目前神經網路中最好用的 lib 之一, 它擅長的任務就是**訓練深度神經網路**.
通過使用 TensorFlow 我們就可以快速的入門神經網路, 大大降低了深度學習的開發成本和開發難度

# Environment Setup

lib 版本問題需要 try and error

+ [Python 3.9-amd64](https://www.python.org/downloads/windows/)
    > ubuntu 下,使用 `sudo pip install ...` 就將 lib 加入到 `/usr` 下給所有人使用

    - pip of python

        ```bash
        $ python -m pip install --upgrade pip
        ```

        1. install lib with `*.whl`

            ```
            $ pip install xxx.whl
            ```

    - `matplotlib`
        > draw figure lib

        ```bash
        $ pip install matplotlib
        ```

    - `librosa`
        > 是一個專門用來分析聲音訊號的模組

        ```
        $ pip install librosa
        ```

+ [TensorFlow](https://www.tensorflow.org/install/pip?hl=zh-tw)
    > only support 64-bits platform

    - tf-slim
        > 該 lib 在 TensorFlow v2.0 中被刪除, 可手動加入

        ```
        $ pip install tf-slim
        ```

    - protobuf

        ```
        $ pip uninstall protobuf
        $ pip install protobuf==3.20
        ```

    - 測試 Tensorflow

        ```bash
        $ python

        >>> import tensorflow as tf     # 如果沒有Error就代表安裝成功
        >>> print(tf.add(1, 2))
        ```

    - TensorFlow v1.x 移植到 2.x
        > 修改使用的模組

        ```python
        #  from tensorflow.contrib.framework.python.ops import audio_ops as contrib_audio
        import tensorflow.audio as contrib_audio
        ```

        ```python
        #  import tensorflow.contrib.slim as slim
        #  from tensorflow.contrib.layers.python.layers import layers
        import tf_slim as slim
        import tf_slim as layers
        ```

        ```python
        #  from tensorflow.contrib import slim as slim
        import tf_slim as slim
        ```

## Other machine learning lib

+ [numpy-1.22.4+mkl](https://www.lfd.uci.edu/~gohlke/pythonlibs/#numpy)
+ [SciPy](https://www.lfd.uci.edu/~gohlke/pythonlibs/#scipy)
+ [Scikit-learn](https://www.lfd.uci.edu/~gohlke/pythonlibs/#scikit-learn)
+ [statsmodels](https://www.lfd.uci.edu/~gohlke/pythonlibs/#statsmodels)


## Reference


# Reference

+ [Tensorflow 教學](https://www.tensorflow.org/tutorials/customization/custom_training_walkthrough?hl=zh-cn)
+ [Tensorflow 指南](https://www.tensorflow.org/guide/basic_training_loops?hl=zh-cn)
+ [簡單粗暴 TensorFlow 2](https://tf.wiki/zh_hant/)
+ [【Python】TensorFlow學習筆記(一)：TensorBoard 的浪漫](https://dotblogs.com.tw/shaynling/2017/11/14/173025)