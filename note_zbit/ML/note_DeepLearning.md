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

## Fully-Connected Layer(全連接層)

FC Layer 原則上就是最後的分類器, 將上一層所擷取出來的所有特徵,
經過權重的計算後, 來辨識出這個所輸入的圖像到底屬於哪一個分類

## [Back-Propagation(反向傳播演算法)](note_BackPropagation.md)

# Reference




