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

+ code

    ```
    typedef struct pid_t
    {
    #define CONIFG_PID_UPPER_BOUND      5.0f
    #define CONIFG_PID_LOW_BOUND        0.0f

    #define CONIFG_PID_KP       1.0f
    #define CONIFG_PID_KI       1.0f
    #define CONIFG_PID_KD       1.0f

        float   time_delta;
        float   err_integral;   // Sum of integral error over time
        float   err_prev;

        float   val_out;

    } pid_param_t;

    int pid_ctrl(pid_param_t *pParam, float val_target, float val_act)
    {
        float   error = 0.0f;
        float   derivative = 0.0f;
        float   val_out = 0;

        error = val_target - val_act;

        /* integral part */
        pParam->err_integral += (error * pParam->time_delta);

        /* derivative  part */
        derivative =  (error - pParam->err_prev) / pParam->time_delta;

        pParam->err_prev = error;

        val_out = CONIFG_PID_KP * error +
                  CONIFG_PID_KI * pParam->err_integral +
                  CONIFG_PID_KD * derivative;

        /* clamping output */
        pParam->val_out = (val_out > CONIFG_PID_UPPER_BOUND) ? CONIFG_PID_UPPER_BOUND :
                          (val_out < CONIFG_PID_LOW_BOUND)   ? CONIFG_PID_LOW_BOUND :
                          val_out;
        return 0;
    }

    ```

## SMO (Sliding mode observer)

經典 `ref. Microchip AN1078 2010`

## SVPWM

將實際 `Motor 3-Phase invertor output Voltages (output Va/Vb/Vc)` 轉換到 SV-Space domain (SV-basis: v0 ~ v7)
> **Vref** 為 SV-Space domain (基底 V0 ~ V7) 上理想的輸出電壓, **Vref** 可由 SV-basis 合成, 每個 SV-Space 的基底亦可用 Va/Vb/Vc 來表示
>> v0/v7 為 0 向量 (因數學式產生), 實際可忽略

**Figure. SV-Space vs. Alpha/Beta Space** <br>
![FOC_Space-Vector_Sectors](./FOC_Space-Vector_Sectors.jpg)

在不同的 Sector 區域時, **Vref** 會由該 sector 的 SV-basis 來合成
> 當 theta 從 `0° => 60°` 時, 會依**時間變數 t 調整 v1/v2 分量比例**, 來合成時間 t 的 **Vref**
> + 若 **Vref** 的軌跡越接近圓形, 則 Va/Vb/Vc 的輸出就越接近 sine wave
> + 其中 `0° => 30°`和 `30° => 60°` 的 v1/v2 比例是對稱, 因此將移動 `30°` 的時間定為 `T`


```
Tx 為 Sector-s (s: 1 ~ 6) 中, SV-basis v_x 的持續作用時間 (PWM duty)
Ty 為 Sector-s (s: 1 ~ 6) 中, SV-basis v_y 的持續作用時間 (PWM duty)

integral{ sector_s(Vref(t), t=0~T }
    = integral{ sector_s(v_x(t), t=0~Tx) } + integral{ sector_s(v_y(t), t=0~Ty) }
    = sector_s( v_x(0) + v_x(1) + ... + v_x(Tx) ) + sector_s( v_y(0) + v_y(1) + ... + v_y(Ty) )

```

+ Example of Sector

    - Sector-I

        ```
        T1 為 v1 持續作用時間, T2 為 v2 持續作用時間,

        integral{ Vref(t), t=0~T } = integral{ v1(t), t=0~T1 } + integral{ v2(t), t=0~T2 }
        ```

    - Sector-VI

        ```
        T6 為 v6 作用時間, T1 為 v1 作用時間,

        integral{ Vref(t), t=0~T } = integral{ v6(t), t=0~T6 } + integral{ v1(t), t=0~T1 }
        ```

### SV-Space domain 其 SV-basis 轉換係數

+ `Sx (x = a,b,c)` 為 `3-Phase inverter 上下臂開關` 狀態
    > + `Sx == 1`: 上臂 on, 下臂 off
    > + `Sx == 0`: 上臂 off, 下臂 on

+ `Vdc`: the voltage of inverter

+ 從 **Figure. SV-Space vs. Alpha/Beta Space**, 可獲得 SV-Space Domain 轉換到 Alpha/Beta Space 的關係
+ `basis_alpha/basis_beta domain` 經 Inv_Clarke 轉換, 可再轉換到  `Va/Vb/Vc` (???)

**Table. SV-basis v.s. Va/Vb/Vc 關係** <br>

| SV-basis name | Sa,Sb,Sc  | `Vdc * Va` |  `Vdc * Vb`| `Vdc * Vc` | `Vdc * basis_alpha` | `Vdc * basis_beta`
|    :-:        |    :-:    |    :-:     |    :-:     |    :-:     |      :-:            |     :-:
|     v1 (  0°) | (1, 0, 0) |    2/3     |     -1/3   |    -1/3    |        2/3          |      0
|     v2 ( 60°) | (1, 1, 0) |    1/3     |      1/3   |    -2/3    |        1/3          |    1/sqrt(3)
|     v3 (120°) | (0, 1, 0) |   -1/3     |      2/3   |    -1/3    |       -1/3          |    1/sqrt(3)
|     v4 (180°) | (0, 1, 1) |   -2/3     |      1/3   |     1/3    |       -2/3          |      0
|     v5 (240°) | (0, 0, 1) |   -1/3     |     -1/3   |     2/3    |       -1/3          |   -1/sqrt(3)
|     v6 (300°) | (1, 0, 1) |    1/3     |     -2/3   |     1/3    |        1/3          |   -1/sqrt(3)
|     v7 (360°) | (1, 1, 1) |     0      |       0    |      0     |         0           |      0
|     v0 ( -0°) | (0, 0, 0) |     0      |       0    |      0     |         0           |      0



### 各 SV-Sector 中, PWM 持續時間推導

> ```
> Vref * T = v_x * T_x + v_y * T_y, x = 1~6, y = 1~6
> ```

+ SV-Sector-I
    > 依照 `Table. SV-basis v.s. Va/Vb/Vc 關係`

    - alpha/beta

        ```
        Vref * T = v1 * T1 + v2 * T2

        SV-basis v1/v2 用 basis_alpha/basis_beta 分量來表示
        =>  v1 = Vdc * 2/3 * basis_alpha
            v2 = (Vdc * 1/3 * basis_alpha) + (Vdc * 1/sqrt(3) * basis_beta)

        Vref = (T1/T) * v1 + (T2/T) * v2
             = (T1/T) * (Vdc * V_alpha * 2/3) +
               (T2/T) * (Vdc * V_alpha * 1/3 + Vdc * V_beta * 1/sqrt(3))

             = ( ((T1/T) * Vdc * 2/3) + ((T2/T) * Vdc * 1/3) ) * basis_alpha +
               ( (T2/T) * Vdc * 1/sqrt(3) ) * basis_beta

             = V_alpha * basis_alpha + V_beta * basis_beta

        V_alpha = ((T1/T) * Vdc * 2/3) + ((T2/T) * Vdc * 1/3)
        V_beta  = (T2/T) * Vdc * 1/sqrt(3)

        T2 = T * (V_beta * sqrt(3)) / Vdc
        T1 = T * (3*V_alpha - sqrt(3)*V_beta) / (2*Vdc)
        ```

    - Va/Vb/Vc

        ```
        d1 = T1/T, d2 = T2/T

        dc = (1 - d1 - d2)/2
        db = dc + d2
        da = db + d1
        ```


+ SV-Sector-II

    - Va/Vb/Vc

        ```
        d1 = T3/T, d2 = T2/T

        dc = (1 - d1 - d2)/2
        da = dc + d2
        db = da + d1
        ```



+ SV-Sector-III

    - Va/Vb/Vc

        ```
        d1 = T3/T, d2 = T4/T

        da = (1 - d1 - d2)/2
        dc = da + d2
        db = dc + d1
        ```

+ SV-Sector-IV

    - Va/Vb/Vc

        ```
        d1 = T5/T, d2 = T4/T

        da = (1 - d1 - d2)/2
        db = da + d2
        dc = db + d1
        ```


+ SV-Sector-V

    - Va/Vb/Vc

        ```
        d1 = T5/T, d2 = T6/T

        db = (1 - d1 - d2)/2
        da = db + d2
        dc = da + d1
        ```


+ SV-Sector-VI

    - Va/Vb/Vc

        ```
        d1 = T6/T, d2 = T1/T

        db = (1 - d1 - d2)/2
        dc = db + d2
        da = dc + d1
        ```



