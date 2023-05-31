Deep Learning
----

Deep Learning 是機器學習的一種類別, 也是多層 Neural-Networks 或多層感知器的另一種稱呼.
> Deep 指的是多層 Neural

根據神經網路的根基以及運作準則, 可分為
> + 前饋神經網路(feed-forward neural)
> + 卷積網路(Convolutional Neural Networks, CNN)
>> 常用於影像處裡, 也就是 Filter
> + 遞歸神經網路(Recurrent Neural Networks, RNN)
>> 主要用於文字語意處理, 可以用來判斷前後文, 而使機器能理解一句話的意思
> + 自動編碼器(autoencoders)

一個多層感知器至少包含三種不同的layers
> + 輸入層(input layer)
> + 隱藏層(hidden layer)
> + 輸出層(output layer)

![NerualNet_Base_Arch](NerualNet_Base_Arch.jpg)<br>
Fig. NerualNet_Base_Arch

+ 輸入層(input layer)
    > 在神經網路的第一層被稱作輸入層,  這層取得在外部的資源, 像是由感測機器傳來的圖片
    >> 在輸入層的節點不會做任何的運算, 只是單純傳送輸入至下一層

    - 輸入層 Neurons 的數量和傳入特徵值的數量相同
        > 假如輸入 `28*28` 的圖片, `Neurons 數量 = 28 * 28 = 784`

    - 有時會額外增加一個偏差節點(bias node)
        > 這個 bias node 是用來控制這一層的輸出, 在深度學習中 bias node 不一定會需要

+ 隱藏層(hidden layer)
    > 可以有多個隱藏層, 每層可以包含一個或多個 Neuron. 而上一層 Neurons 的輸出, 會是下一層 Neurons 的輸入
    >> `Fig. NerualNet_Base_Arch` 中, hidden layer 代表**上一層的特徵乘上權重後的結果**

    ![Neuron](Neuron.jpg)<br>
    Fig. One_Neuron_Arch

    - 當隱藏層數越多, 計算的複雜度與計算時間也會隨之增加

    - 無法真正確定需要多少隱藏層, 也沒有相應的實際策略存在, 只能靠經驗
        > 通常會使用上一層 2/3 neuron 的總數 (約 66%)
        >> e.g. 1-st layer = 100, 2-nd layer = 66, 3-th layer = 43

+ 輸出層(output layer)
    > 輸出層的 Neurons 數量, 由使用者想要做多少類別的分類器來決定
    >> e.g. 分類 `0 ~ 9` 的數字, 輸入層就需要 10 個 Neurons

+ 權重Weight
    > 權重(weight)也被稱作係數或者輸入係數, Neuron 的每個輸入特徵都會乘上 weight, 然後輸出到下一層 Neuron.
    從輸入到 Neuron 的每個連接, 都有權重線(weighted line)所連接.
    >> 權重線代表著模型預測輸出特徵值的貢獻度

    > + 當 weight 越高, 他對特徵值的貢獻越大
    > + 當 weight 是負值, 那特徵就有負面的影響
    > + 當 weight 是 0, 那麼代表這個輸入特徵不重要且可以從訓練集中移除

    - **訓練神經網路的目標, 是為了能計算出, 每個輸入特徵(每個連結線)的最優化權重值**
        > 藉由 Back-Propagation(反向傳播演算法)及梯度下降法, 去逼近最優化的權重值. 通常會經過幾個步驟
        > + 前向傳播
        > + 反向傳播
        > + 權重更新

+ 簡易描述 NN 規模

    - `<input nodes>-<hidden 1 nodes>-<hidden 2-nodes>-...-<output nodes>` NN
        > + `2-2-2 NN` 代表 input/hidden/output 都各有 2 nodes, hidden 只有 1 層
        > + `2-5-5-2 NN` 代表 input/output 各有兩個 nodes, hidden 有 2 層都各自有 5 個 nodes

+ 為何 NN 模型被稱為黑箱的原因之一

    -  影響 NN 表現能力的主要因素有
        > + 神經網路的 layers
        > + 神經元的個數
        > + 神經元之間的連接方式
        > + 神經元採用的 Activation Function

    - 神經元之間以不同的連接方式(全連接, 部分連接)組合, 可以構成不同神經網路, 對於不同的訊號處理效果也不一樣
        > **但目前依舊沒有一種通用的方法, 可以根據訊號輸入的特徵, 來決定神經網路的結構**

+ NN 優點
    > 大可不用顧及模型本身是如何作用的, 只需要按照規則建構網路 (e.g. 隱藏層個數, 每層的 Neuron 個數, 前後層 Neuron 連接方式, 選擇啟動函數),
    然後使用訓練資料集不斷調整參數, 在許多問題上都能得到一個**相對能接受**的結果
    >> 然而我們對其中發生了什麼, 是未可知的

# Input data format

不同平台為了提高效能, 會遷就 H/w 特性(e.g. GPU, TPU, Multi-Cores, ...etc), 或是演算法特性, 對於讀資料會有特定格式
> 資料在 memory 中是連續位置存放, 格式會以簡稱來表示

| N              | C                      | H          | W          |
| :-:            | :-:                    | :-:        | :-:        |
| batch 批次大小 | channels, 特徵圖通道數 | 特徵圖的高 | 特徵圖的寬 |


![ml_data_format](ml_data_format.jpg) <br>
Fig. ml_data_format

![ml_data_order](ml_data_order.jpg) <br>
Fig. ml_data_order, RGB data with plane mode and packed(interleaved) mode


+ NCHW
    > NCHW 是先取 W 方向資料, 然後 H 方向, 再 C 方向, 最後 N 方向
    >> 取 data 的順序, 是名稱的倒敘

    ```
    1D data from Fig. ml_data_format:

    W 方向           H 方向           C 方向           N 方向
    000 001 002 003, 004 005 ... 019, 020 ... 318 319, 320 321 ...
    ```

+ NHWC
    > NHWC 是先取 C 方向資料, 然後 W 方向, 再 H 方向, 最後 N 方向
    >> 取 data 的順序, 是名稱的倒敘

    ```
    1D data from Fig. ml_data_format:

    C 方向           W 方向           H 方向       N 方向
    000 020 ... 300, 001 021 ... 303, 004 ... 319, 320 340 ...
    ```

一般來說, NHWC 更適合多核 CPU 運算,
> CPU 的 memory 頻寬相對較小, 每個像素計算的時延較低, 臨時空間也很小,
有時電腦採取非同步的方式, 邊讀邊算來減小訪存時間, 計算控制靈活且複雜

NCHW 適合 GPU 運算
> GPU 的 memory 頻寬較大, 並且平行處理強, 在計算時會使用較大的儲存空間

## Format Convertor

```c
// Convert HWC to CHW and Normalize
void Convert_HWC_2_CHW(int height, int width, int channels, uint8_t *fileData, float *nnDataBuf)
{
    for(int c = 0; c < channels; ++c)       // C
    {
        for(int h = 0; h < height; ++h)     // H
        {
            for(int w = 0; w < width; ++w)  // W
            {
                int     dstIdx = c * height * width + h * width + w;
                int     srcIdx = h * width * channels + w * channels + c;

                nnDataBuf[dstIdx] =  fileData[srcIdx];
            }
        }
    }
    return;
}
```

```c
// Convert CHW to HWC and Normalize
void Convert_CHW_2_HWC(int height, int width, int channels, uint8_t *fileData, float *nnDataBuf)
{
    for(int h = 0; h < height; ++h)             // H
    {
        for(int w = 0; w < width; ++w)          // W
        {
            for(int c = 0; c < channels; ++c)   // C
            {
                int     dstIdx = h * width * channels + w * channels + c;
                int     srcIdx = c * height * width + h * width + w;

                nnDataBuf[dstIdx] =  fileData[srcIdx];
            }
        }
    }
    return;
}
```

# Activation Function (啟動函數, 激勵函數)

在神經網路中, 每一層輸出都是上層輸入的線性函數, 無論神經網路有多少層, 輸出都是輸入的線性組合
當使用 Activation Function 時, 給神經元引入了非線性因素, 使得神經網路**可以任意逼近任何非線性函數**,
這樣神經網路就可以應用到眾多的非線性模型中

常見的啟動函數
+ `sigmoid()`
    > 也叫 Logistic 函數, 取值範圍為(0, 1), 在特徵相差比較複雜, 或是相差不是特別大時, 效果比較好
    >> 啟動函數計算量大, 反向傳播求誤差梯度時, 很容易就會出現梯度消失的情況(求導數涉及除法), 從而無法完成深層網路的訓練

求導涉及除法

+ `Tanh()`
    > 也稱為雙切正切函數, 取值範圍為 [-1,1], 在特徵相差明顯時, 效果會很好, 在循環過程中會不斷擴大特徵效果
    >> `tanh` 平均值是 0, 因此實際應用中 tanh 會比 sigmoid 更好

+ `ReLU()`
    > ReLU (Rectified Linear Unit) 得到的 SGD 的收斂速度, 會比 sigmoid/tanh 快很多
    >> 訓練的時候很**脆弱**, 當遇到一個非常大的梯度時, 更新過參數之後, 這個神經元很容易就再也不會對任何資料有啟動現象

+ `softmax()`
    > 用於多分類神經網路輸出
    >> clases 之間是互斥的, 即一個輸入只能被歸為一類, e.g. Apple 只能是`水果` 或是`科技公司`擇一

# Fully-Connected Layer(全連接層)

FC Layer 原則上就是最後的分類器, 將上一層所擷取出來的所有特徵,
經過權重的計算後, 來辨識出這個所輸入的圖像到底屬於哪一個分類
> 也叫 `Densely-connected`

# [Back-Propagation(反向傳播演算法)](note_BackPropagation.md)

# [RNN(循環神經網路)](note_RNN.md)

# [DS-CNN (Depthwise Separable CNN)](note_DS_CNN.md)

# Attention Model (注意力模型)


# Reference

+ [常用啟動函數比較](https://www.cnblogs.com/codehome/p/9729349.html)



