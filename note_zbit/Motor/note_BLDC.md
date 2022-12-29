BLDC (Brushless DC Motor) [[Back](note_BLDC.md)]
---

要控制 Brushless DC Motor, 首先要知道轉子角度位置 ([相位角](note_Phase.md)), Controller 利用相位角來協調與磁場相關的轉子線圈之供電, 以確保 Motor 提供所需的回應
> 回應包括如下, 具體取決於應用和操作條件
> + 保持速度, 加速, 減速
> + 改變方向
> + 減小或增加扭矩
> + 緊急停止
> + 其他回應,


偵測轉子角度, 可以分為 sensor 及 sensorless

+ Sensor
    > Sensor 類型豐富, 大致分為偵測相對和絕對位置兩種.
    >> 通常有**線圈旋轉變壓器**, **霍爾感測器**, **光學或電容感測器**. 可根據解析度, 耐用程度, 或成本等要求來挑選

+ Sensorless
    > 透過測量每個轉子繞組中的反電動勢, 來計算轉子位置.
    同時使用磁場導向控制(FOC), 將轉子電流分解為 D-軸 和 Q-軸分量, 因為 DC 變化緩慢, 可以簡化控制方式
    >> 適合低成本, 精準度需求較低的應用


## 反電動勢 (Back Electromotive Force, Back-EMF)

馬達在送電的運轉過程中, 在啟動的當下, Motor 從靜態(靜平衡)進入到動態(動平衡)的過程, 電流會持續上升, 再隨著轉速上升而逐漸下降;
當馬達達到穩速(達到動態平衡)運轉時, 電流值會下降到最低點

![motor_rotating_current](motor_rotating_current.jpg)

但依照電壓電流公式 `V = IR`, 馬達內部的電阻值 R 為恆定值.
而馬達隨著轉速變化, 電流值會逐漸下降, 表示有一個**反電動勢**在降低電壓值.

+ 反電動勢發生的原因
    > 馬達運作是送電給了線圈, 產生電磁場後與磁鐵作用, 最後轉化為動能旋轉輸出.
    但**沒送電的線圈**也會感受到磁場的變化, 依照法拉第定律在線圈上生成**渦電流**, 這就是反電動勢的來源.
    >> 事實上不僅是空的線圈會受到旋轉磁場變化的影響, 正在送電的線圈也會有反應

    > 所以反電動勢是個一體兩面的存在
    > + 當輸入電壓 12V, 馬達穩態轉速為 1200轉(RPM)
    > + 若用外部力量(水力, 火力)帶動馬達旋轉達到 1200轉時, 就會產生 12V 的反電動勢


反電動勢對馬達造成的影響
> + 抑制工作電流
> + 限制最高轉速(RPM)






# Reference
+ [*相位角、頻率](https://www.geogebra.org/m/wthz4bhr)
+ [【自制FOC驅動器】深入淺出講解FOC演算法與SVPWM技術](https://zhuanlan.zhihu.com/p/147659820)
+ [ZhuYanzhen1/miniFOC](https://github.com/ZhuYanzhen1/miniFOC)
+ [FOC發展與原理概論](https://blog.udn.com/hal9678/6714149)
+ [FOC演算法穩定EV動力傳動性能](https://www.edntaiwan.com/20210825ta31-foc-algorithm-enhances-ev-powertrain-performance/)
+ [變頻器- Wiki](https://zh.m.wikipedia.org/zh-hant/%E5%8F%98%E9%A2%91%E5%99%A8)
+ [向量控制- Wiki](https://zh.m.wikipedia.org/zh-hant/%E5%90%91%E9%87%8F%E6%8E%A7%E5%88%B6)


