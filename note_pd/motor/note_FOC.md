Motor FOC
---

# 常用參數

[國際單位制導出單位 SI derived units](https://zh.wikipedia.org/zh-tw/%E5%9B%BD%E9%99%85%E5%8D%95%E4%BD%8D%E5%88%B6%E5%AF%BC%E5%87%BA%E5%8D%95%E4%BD%8D)

+ Js (轉動慣量)
    > moment of Inertia of the rotor, `unit: Kg*m^2`

    - 在力學上, 實際的轉動摩擦力 (需實際量測估算)
        > 會因掛載不同機構裝置而改變
        >> 不同機構裝置(e.g. 扇葉), 其重量, 力矩, 摩擦係數等, 都會有不同的影響

+ Kt (轉矩常數)
    > Torque Constant, `unit: N·m/A, 牛頓米/安培`

    - 轉矩常數(Kt)方程式中可知, 其包括了磁場(B), 馬達積厚(L), 馬達轉子外徑(D), 馬達繞線匝數(N), 以及電場與磁場間的角度(δ)
        > 這些參數, 都是馬達生產後就確認固定的數值, 不會有變化

        ```
        Kt = B * L * (D^2) * N * sin(δ)
        ```

# Components of Algorithm

## PID Controller

由比例單元(Proportional), 積分單元(Integral)和微分單元(Derivative)組成, 且將輸出的結果 feedback 回輸入端

> 將誤差 (error) 經由 **比例-積分-微分** 的操作, 來達到 `快速穩定` 的目的
>> 大多數情況下, PI 控制就已夠用, D 則適用在高頻震盪的情況下

![pid_cotrl_arch](./pid_cotrl_arch.jpg)



+ 比例單元(Proportional), 使用 `Kp` 權重來調節
    > 單純線性增減數值 (粗調), 會發生太慢穩定, 或是抖動(增減一個量化級數, 永遠都存在誤差)

+ 積分單元(Integral), 使用 `Ki` 權重來調節
    > 導入時間資訊的**增幅器**, 藉由過去時間 (0~t) 的`誤差總和(積分)`, 來判定是否幫助 P 增減數值量級

    - 如果在目標附近震盪(有增有減), 則誤差總和趨近 0, I 則無作用(平均過去的誤差, 達到微調誤差的效果)
    - 須做 clamping 來避免數值爆表(過大或過小), 而造成系統崩潰
        > 剛啟動未穩定狀態下, 最容易發生


+ 微分單元(Derivative), 使用 `Kd` 權重來調節
    > 導入時間資訊的**抑制器**, 預測未來誤差趨勢, 進而提前抑制數值增減的量級

    - 將目前時間軸 `t 時刻`的誤差, 減去`(t - 1)時刻`的誤差後, 做一階微分得到斜率, 由**斜率可未來趨勢**
        > 由過去及現在的資訊來預估

## SMO (Sliding mode observer)

經典 `ref. Microchip AN1078 2010`



