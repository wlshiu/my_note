Machine Learning
---
+ 在多維度(features)空間中,將各個 feature投影(內積: inner product)到某維度/區域,並判斷此維度/區域上的量級(純量)


## Type of learning
---

# Input side

+ supervised learning
    > every X comes with corresponding Y

    > 從給定的訓練數據集中學習出一個模式(函數/learning model),當新的數據到來時,可以根據這個模式預測結果。

    > raining set 中的目標是由人標註的。常見的監督學習算法包括回歸分析(regression)和統計分類(classification),
    > 比如在訓練投飲機辨識錢幣的時候,我們很完整個告訴他什麼大小,什麼重量就是什麼幣值的錢幣,這樣就是一種監督式學習方法。

+ un-supervised learning
    > refers to the problem of trying to find hidden structure in unlabeled data

    > Training set 沒有人為標註的結果。常見的無監督學習算法有聚類(clustering)。
    > 比如在訓練投飲機辨識錢幣的時候,我們只告訴投飲機錢幣的大小及重量,但不告訴他什麼大小及重量個錢幣是哪個幣值的錢幣,
        讓機器自己去觀察特徵將這些錢幣分成一群一群,這又叫做分群

+ Semi-supervised learning
    > leverage unlabeled data to avoid 'expensive' labeling

    > 介於監督學習與無監督學習之間。
    > 有些資料較難取得的狀況下,我們會使用到半監度式學習,
        比如在預測藥物是否對病人有效時,由於做人體實驗成本高且可能要等一段時間來看藥效,
        這樣的情況下標示藥物有效或沒效的成本很高,所以就可能需要用到半監度式學習。

+ reinforcement learning
    > one most powerful approach in solving sequential decision making problems

    > learning with 'partial/implicit information' (often sequentially)

    > 過觀察來學習做成如何的動作。每個動作都會對環境有所影響,學習對象根據觀察到的周圍環境的反饋來做出判斷。
    > 比較像自然界生物的學習方式,就像你要教一隻狗坐下,你很難直接告訴他怎麼做,而是用獎勵或處罰的方式讓狗狗漸漸知道坐下是什麼。
        增強式學習也就是這樣的機器學習方法,透過一次一次經驗的累積讓機器能夠學習到一個技能。
        比如像是教機器學習下棋,我們也可以透過勝負讓機器漸漸學習到如何下棋會下得更好。

    - Concept:
        > 即一個連續決策的過程(Markov decision process, MDP)。目前的狀態(state),尋找最好的行為(action),得到最大的回報(reward)

# Output side

+ Regression
    > the output variable takes continuous values.

    > 像是要預估病人再過幾天病會好

+ Multiclass Classification
    > the output variable takes class labels.

    > 像是使用投飲機辨識錢幣的問題,是否核發信用卡問題

    - Support Vector Machines (SVM - binary classifier)
        > 具有較完備的統計學習理論基礎。在解決小樣本、非線性及高維模式識別問題中表現出許多特有的優勢。
            已經應用於手寫體識別、三維目標識別、人臉識別、文本圖像分類等實際問題中

        > 基本上 SVM 是一個二元的分類器(binary classifier)。
            將data set對應到線性空間中,並找出一個平面(hyperplane),使之將兩個不同的集合分開。

        - margin: The region bounded by these two hyperplanes.
        - support hyperplane (. line): 一個集合的邊界平面稱
        - support vector: 落在 support hyperplane的 training data
        - separating hyperplane (\ line): 在兩個 support hyperplane之間的平面
        - optimal separating hyperplane: 距離兩邊邊界最大的平面 (idealy)

            ```
            +-----------------+
            |     . \   .   + |
            |  o   . \   . + +|
            |       . \   . + |
            |      o . \   .+ |
            |         . \   . |
            |      o  o. \    |
            |           . \   |
            |   o          \  |
            |               \ |
            +-----------------+
            ```

        - 非線性 data set, 使用某 kernel method 將 data set轉換到高維度空間或是 `eigen space`
            > kernel method (Kernel trick): Be served as a bridge from linearity to non-linearity.
                commonly use Gaussian radial basis function (RBF), it approximates the eigendecomposition

            > gamma value (in RBF): 資料轉換到 eigen space 的分散程度(呈反比)
                - large gamma => small variance of Gaussian RBF
                >> 越集中,影響越小,越不易分類

                - small gamma => large variance of Gaussian RBF
                >> 越分散,影響越大,越容易誤判

            > 用內積(dot product)形式去描述轉換, 使kernel method 可簡化轉換難度

        - 為提高彈性(handle unlabeled or extremely un-usual),使用 `soft margin`來獲得較好的效果,同時因容忍誤差而加入 `C` (cost wight)參數

            > soft margin: allows some samples to be `ignored` or placed on the wrong side of the margin
                - 適度模糊 one sample 到 hyperplane的距離(容忍誤差值, 超過就 ignore)

            > `C` is the parameter (cost weight) for the soft margin cost function, which controls the cost of misclassification on the training data.

                - 越大的 C(權重越大), 對誤差的反應劇烈,也越容易造成 overfitting
                - 較佳的 C,適度反映誤差,可獲得較大彈性的預測

        - The goal is to find the balance between **not too strict** and **not too loose**.
            Cross-validation and resampling, along with `grid search`, are good ways to finding the best C and gamma.


+ Structured
    > the output variable takes a hyperclass without 'explicit' class definition

    > 比如一個句子的詞性分析,會需要考慮到句子中的前後文,而句子的組合可能有無限多種,因此不能單純用 Multiclass Classification 來做到

# Definition

+ Over-fitting
    > 對資料過度解釋,即 hyperplane 過度貼近(e.g. 參數過多, 算法過於複雜) Training Data,而導致預測 Testing Data 的時候, Error 變得更大

+ Orthogonal (正交)
    > 兩個 vectors,內積為 0(投影的純量 = 0),即兩 vectors 互不影響

+ Sparse coding (稀疏編碼)
    > 稀疏編碼的概念來自於神經生物學。生物學家提出,哺乳類動物在長期的進化中,生成了能夠快速,準確,低代價地表示自然圖像的視覺神經方面的能力。
        我們直觀地可以想像,我們的眼睛每看到的一副畫面都是上億像素的,而每一副圖像我們都只用很少的代價重建與存儲。
        我們把它叫做稀疏編碼，即 Sparse Coding.

    - Sparse coding 的目的: 在大量的數據集中,找到一組能描述 input的基礎向量(basic element)。
        > 自然數據中通常纏繞著高度密集的 feature。原因是這些 feature vectors是相互關聯的,一個小小的關鍵因子可能牽擾著一堆特徵,有點像蝴蝶效應。
            因此如果能夠解開特徵間纏繞的複雜關係,轉換為稀疏特徵,那麼特徵就有了 robustness。

        > 一般來說,大部分底層取出的 features和最高層輸出的 feature,沒有關係或者不提供任何信息的。
            在最小化目標函數的時候,考慮所有的特徵，雖然可以獲得更小的訓練誤差;
            但在預測新的樣本時,這些無用的信息反而會干擾對最高層 feature的預測。
            稀疏規則化算子的引入,就是為了完成特徵自動選擇的光榮使命,它會學習地去掉這些沒有信息的特徵,也就是把這些特徵對應的權重置為0。

        > 用圖片來說,就是找到最微小的圖片片段來組合 input,然後這堆微小的圖片片段集合(D0 ~ Dn),稱為字典(dictionary);
            而從 input任意抽一個小區域(patch)出來(比最微小圖片要大),那麼這個小區域可以用字典來描述

            ```
            patch = 0*D0 + 0*D1 + 0.8*D2 + 0*D3 + 0.5*D4 + 0.5*D5 + ... + 0*Dn

            因為 pitch比最微小的圖片大,所以加起來會超過100%
            ```

        > Training: 給定一系列的樣本圖片{img_1, img_2, ...},我們需要學習得到一組基 {D1, D2, ...},也就是字典。
            

    - Sparse coding 難點: 其最優化目標函數的求解(需反覆計算逼近)

+ Deep learning (un-supervised)
    > 複雜的圖形,通常都是由基本結構組成。Deep learning = 生物神經系統的概念(neural network分層, base -> complex) + 特徵學習

    > `Deep`意指分層(多深),從基本的線(edges),組成物件的基礎外型(e.g. face and car),再由基礎外型組成 modele(e.g. 男/女, 轎車/卡車),
        從 modules組成意義(e.g. 爸/媽, BMW/Benz)

    - Deep learning 與一般 Machine Learning差異
        1. 強調了模型結構的深度,通常有 5層. 6層,甚至 10多層的隱層節點
        2. 明確突顯出特徵學習的重要性,即通過逐層特徵變換,將樣本在原空間的特徵轉換到一個新特徵空間,從而使分類或預測更加容易

    - training flow
        1. feature learning (un-supervised)
            > 類似初始化,deep learning 效果好壞,很大程度上歸功於第一步的 feature learning過程

            >> 傳統類神經網路使用隨機初始值,再逐一修正 (有可能會有盲點 e.g. 向右走後, 左邊的情況只能用猜測)

            a. 每次只訓練一個單層網絡,以得到這一層的參數。
            b. 由最底層,一層一層往上 training (將第 n-1層的輸出作為第 n層的輸入,訓練第 n層)
            c. 期望每一層輸出,盡可能的減少訊息誤差(失真)。
                > input -> encode -> decode -> output, 重複調整 encode/decode 直到 `diff(input, output)`在誤差範圍內。
                    此過程為 Auto Encoder

                > 相當於 noise與 denoise的過程,多次變換後,保留下來能識別到 original input的就是顯著的 feature。

                c1. Sparse AutoEncoder(稀疏自動編碼器)
                    > input -> encode -> sparsity penalty -> decode -> output

                    > sparsity penalty: 做較極端的特徵強化(大部分節點都要為 0,只有少數不為 0)

                    - 稀疏的表達往往比其他的表達要有效(人腦也是這樣的,某個輸入只是刺激某些神經元,其他的大部分的神經元是受到抑制的)。

                c2. Denoising AutoEncoder(降噪自動編碼器)
                    > input with noise -> encode -> add noise -> decode -> output

                    > encoder必須學習去除 noise而獲得真正 pure input,因此較 robustness,通用性也較佳

        2. optimal (supervised)
            a. 使用已標註的資料(labeled trainign data)
            b. 由上而下依序傳遞誤差,並微調(fine-tune)各層參數
            c. 最上層加入一個 classifier,藉由 verification info調整 classifier的 input,並將調整的差值依序向下傳遞,達到微調各層參數

                ```
                                                                     {->
                labeled input ---> edges ---> modele ---> classifier {-> compare()
                                                                             |
                verification info -------------------------------------->----+
                ```

    - Convolutional Neural Network, CNN (卷積神經網絡)
        > 目前語音分析和圖像識別領域的研究熱點

        > 包含 2種神經元,經 convolution(filter)強化特徵, 再 down-sample來降低運算複雜度

        ```
        input -> Convolutional 0 -> Pooling 0/ReLU -> Convolutional 1 -> Pooling 1 -> Convolutional 2 -> Pooling 2 -> ... -> fully connected(classifier)
        ```

        - Definition
            1. 2D Convolution:
                把 NxN filter放在image上(filter的中心對準image中要處理的元素),用filter的每個元素去乘image中被覆蓋的對應元素,總和等於convolution後該位置的值。

                ```
                {255, 255, 255, 235, 55, ...}         {-1, 0, 1}    {x,   x,    x, ...}
                {135, 234,  54,  56, 44, ...}  conv   {-1, 0, 1}  = {x, -38, -176, ...}
                {  0,  12,  43,  43, 67, ...}         {-1, 0, 1}    {x,  83,    o, ...}
                {  0, 121, 121,  12, 99, ...}                       {x,   o,    o, ...}
                ...
                ```

            1. 神經元(neuron): the filter to extract feature
            1. 感受野(receptive field): the area mapping to the filter size
            1. 激活映射(activation map)或特徵映射(feature map): the set of filtered result
            1. 激活函數(activation function): 用來做 sparsity, 通常是 sigmoid function 或 Hyperbolic function
            1. 步幅(stride): the unit of filter moveing every time
            1. 填充(padding): for keeping the same spatial size of output, pad the input with zeros on the border of the input


            ```
            ex: a 32x32 gray image, 5x5 filter(neuron) to extract features, move 1 pixel from left to right, up to down
                => generate 28x28 set (feature map), the 5x5 area (receptive field) on gray image will sequentially move 1 pixel (stride) every time.
            ```

        - Convolutional layer (filter feature)
            > Convolution at time domain = Multiplication at frequency domain (時域中的 convolution等於頻域中相乘)。可用 FFT/Inverse FFT來加速運算

            > 強化特徵

        - ReLU(Rectified Linear Units) layer
            > 增加模型乃至整個神經網絡的非線性特徵,達到在準確度不發生明顯改變的情況下,提高訓練速度

            > Non-linearly scale the feature map.
                特徵強化後,藉 sigmoid function來判定是否激活(activative),來減少資料量,同時非線性可以避免 overfitting

            ```
            sigmoid function = 1 / (1 + exp(-t))
            越接近 1表示 activative, 越接近 0則被抑制
            ```

        - Pooling Layer (dowm sample)
            > Partition the input into a set of non-overlapping rectangles
                and get a representative value to describe this area(e.g. maximum, avaerage, L2-norm, ..., etc)

            > feature 的相對位置就可表達特性

            1. 大幅減小空間維度,因此降低了計算成本
            1. 可以控制過擬合(overfitting)

        - fully connected


# Model Assessments

+ 是否符合實際狀況 (true/false) and Prediction (positive/negative)
    - 實際值是 A, 預估值(prediction)是 A
        > TP, 預測和實際相符合 (True), 預測輸出是正向

    - 實際值是 A, 預估值(prediction)不是 A
        > FN, 預測和實際相不符 (False), 預測輸出是反向

    - 實際值不是 A, 預估值(prediction)是 A
        > FP, 預測和實際相不符 (False), 預測輸出是正向

    - 實際值不是 A, 預估值(prediction)不是 A
        > TN, 預測和實際相符 (True), 預測輸出是反向


+ Accuracy(ACC)
    > (TP + TN)/(TP + TN + FP + FN)









