Per-unit (標么(ㄧㄠ)化) [[Back](./note_FOC.md#常用參數)]
---

將物理量的實際值, 除以一選定的同單位數值, 這一被選定的同單位數值稱為基準值，這個過程就叫做**標么(ㄧㄠ)化**
> 經過 Per-unit 後, 所有的物理量的值都限定在 `[-1, 1]`之間
>
> ```
> PU-Value (Per-Unit) =  Real-Value / Base_Value
> ```
>> 在程式碼中經常會看到多少`pu`, 這裡的`pu`就是`per-unit`的縮寫 <br>
而 **么(ㄧㄠ)** 在中文就是排行最小的意思, 數字中最小的即是 1, 即 PU-Value 就是以標準`1`為基準比較的結果

+ 在數值分析中, 兩種實際數據的量級差異很大時, 很難分析其關聯性, 因此藉由正規化(Pre-Unit 為正規化的一種) 來**等效(非等於)**分析結果
    > 假設實際中的電壓 V = 310V, 電流 I = 0.3 A, 如果直接計算功率 P = UI, 就是一個很大的數乘以一個很小的數, <br>
    但如果我們定義 `電壓基準值 (V_base) = 500V`, `電流基準值 (I_base) = 1A`,
    在程式碼中計算公式, 就變成 PU-Value 的相乘, 即 `V_pu * I_pu = 0.62 * 0.3` (等效關係). <br>
    使用這種方式表示, 即使真實世界差別很大的物理量, 在程式碼世界中差別也不大

+ 電機控制中一般會對 `頻率 f(Hz)/電流 I(A)/電壓 V(V)` 做 Per-unit
    > 這三個最基本的物理量, 可推演出電機數學模型中, 所有其他的間接物理量

    ![Elec_Physical_Quantity](./Elec_Physical_Quantity.jpg)

    - 電阻 ( R)
        > 阻抗 (Z) 包含電阻和電抗

        ```
        V = IR
        R_base = V_base / I_base
        Z_base = V_base / I_base
        ```

    - 電角頻率 (ω)

        ```
        ω = 2π * f_base
        ```

    - 電感 (L)
        > `Z_l`為電桿阻抗

        ```
        V = L * (dI(t)/dt)
        T * V(t) = L * I(t)

        L = T * V(t) / I(t)
          = T * Z_l
          = Z_l / 2π * f_base
          = Z_l / ω

        L_base = Z_base / ω_base
               = (V_base / I_base) / 2π * f_base
        ```

    - 週期

        ```
        T = 1 / freq

        圓周運動週期:
        T_base = 1 / ω_base
               = L_base / Z_base
        ```



# Reference

+ [電機控制中的數學模型標么化計算 - 知乎](https://zhuanlan.zhihu.com/p/469634745)
+ [揭秘隱藏的標么化基準值——AN1078原始碼解讀 - 知乎](https://zhuanlan.zhihu.com/p/615229940)

