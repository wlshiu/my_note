LSTM (Long Short-Term Memory networks) [[Back](note_RNN.md#LSTM)]
---

LSTM 為了解決 RNN 無法建立長期記憶的依賴關係(梯度消失或爆炸), 加入一個 cell state $C(t)$ 來保存長期記憶, 以達到長距離依賴的目的
> LSTM 和 GRU 都是 RNN 中常見的模型, 都可以用於處理序列資料.
> > + LSTM 相對 GRU 有更長的記憶能力, 可以更好的處理長序列資料, 但計算量比較大訓練時間長.
> > + GRU 計算量小訓練速度快, 但記憶相對較弱, 可能出項梯度消失的問題.

![LSTM_Core_Arch](LSTM_core_arch.jpg) <br>
Fig. LSTM_Core_Arch
> + 黃色  ：表示一個 `全連接` 的 Neural Network Layer (並非啟動函數, 只是剛好使用相同的數學式)
>> $\sigma$ 為 sigmoid function, 用來將 input 轉換為 `0 ~ 1` 之間的數值, 進而描述有多少量的 input 可以通過
> + 粉色  ：表示按位操作或逐點操作(pointwise operation),
>> e.g. 向量相加 (Vector Addition), 向量乘積 (Hadamard production), ...etc.
> + 粗黑點：表示兩個訊號的連接(向量拼接)
>> $[h(t-1), X(t)]$ 表示將向量 $h(t-1)$ 和 $X(t)$ 拼接起來
> + $W_f$: forget_gate 的輸入權重
> + $W_i$: input_gate 的輸入權重
> + $W_c$: 輸入門 Cell state 輸入權重
> + $W_o$: output_gate 的輸入權重


## forget gate (遺忘門)

決定了上一時刻的 $C(t-1)$ (單元狀態), 保留多少到當前時刻 $C(t)$, 也就是會對 input 進行選擇性忘記
> 因為使用 sigmoid function, 則越遠的資料權重越大, 保留較多長期記憶

$f(t) = \sigma(W_f \cdot \left[h(t-1), X(t) \right] + Bais) = sigmoid(W_f \cdot \left[h(t-1), X(t) \right] + Bais)$

其中權重矩陣 $W_f$ 由兩個矩陣 $W_fh$ 和 $W_fx$ 拼接而成, 分別對應 $h(t-1)$ 及 $X(t)$

```math
f(t)=\sigma\left(
\begin{bmatrix}{l}
W_f
\end{bmatrix}
\begin{bmatrix}
    h(t-1)\\
    X(t)
\end{bmatrix}=
\begin{bmatrix}
    W_{fh}& W_{fx}
\end{bmatrix}
\begin{bmatrix}
    h(t-1)\\
    X(t)
\end{bmatrix}\\
= W_{fh}h(t-1) + W_{fx}X(t)
\right)
```

## input gate (輸入門)

決定了當前時刻的輸入 $X(t)$, 有多少保存到 $C(t)$
> sigmoid layer 決定要更新哪些資訊, 而 tanh layer 則創造了一個新的候選值, 來更新資訊到 $C(t)$
>> 避免當前無關緊要的內容進入長期記憶 $C(t)$

$i(t) = \sigma \left(W_i \cdot [h(t-1), X(t)] + Bais\right)$

$\hat{C(t)} = tanh(W_c \cdot [h(t-1), X(t)] + Bais)$

則經過 input gate 後的 $C(t)$

$C(t) = f(t) \cdot C(t-1) + i(t) \cdot \hat{C(t)})$


## output gate (輸出門)

用來控制當前的 $C(t)$ 有多少被過濾掉, 並輸出到當前的輸出值 $h(t)$


$O(t) = \sigma \left(W_o \cdot [h(t-1), X(t)] + Bais\right)$

$h(t) = O(t) \cdot tanh(C(t))$

# LSTM 的缺點分析

不管是 RNN 還是 LSTM 及其衍生模型, 主要是隨著**時間推移**進行順序處理, 長期資訊需在進入當前處理單元前, **依序遍歷所有單元**.
這代表著梯度問題並未完全解決
> LSTM 可以處理 100 個量級的序列, 而對於 1000 個量級, 或者更長的序列則依然會顯得很棘手

另外線性層遍歷所有單元, 需要大量的儲存空間及計算效能, 同時也造成訓練時間過長


# Reference


+ [【個人整理】長短是記憶網路LSTM的原理以及缺點](https://blog.csdn.net/qq_27825451/article/details/89015513)
+ [動手學深度學習](https://zh.d2l.ai/index.html)

+ [長短期記憶網路(LSTM)](https://zh.d2l.ai/chapter_recurrent-modern/lstm.html)

+ [深入淺出LSTM及其Python程式碼實現](https://zhuanlan.zhihu.com/p/104475016)
+ [C語言實現LSTM演算法](https://zhuanlan.zhihu.com/p/262132576)
+ [Github-C-LSTM](https://github.com/az13js-org/C-LSTM)
+ [RNN學習筆記（六）-GRU，LSTM 程式碼實現](https://blog.csdn.net/rtygbwwwerr/article/details/51056140)
+ [LSTM/GRU詳細程式碼解析+完整程式碼實現](https://blog.csdn.net/m0_53961910/article/details/127965475)

+ [Understanding LSTM Networks](http://colah.github.io/posts/2015-08-Understanding-LSTMs/)
+ [Day 15：『長短期記憶網路』(Long Short Term Memory Network, LSTM)](https://ithelp.ithome.com.tw/articles/10193678)

+ [CS224d筆記4續——RNN隱藏層計算之GRU和LSTM](https://wugh.github.io/posts/2016/03/cs224d-notes4-recurrent-neural-networks-continue/)
+ [*Evolution: from vanilla RNN to GRU & LSTMs](https://docs.google.com/presentation/d/1UHXrKL1oTdgMLoAHHPfMM_srDO0BCyJXPmhe4DNh_G8/pub?start=false&loop=false&delayms=3000&slide=id.g24de73a70b_0_0)


+ [CS224N(1.29)Vanishing Gradients, Fancy RNNs](http://bitjoy.net/2019/08/01/cs224n%ef%bc%881-29%ef%bc%89vanishing-gradients-fancy-rnns/)

