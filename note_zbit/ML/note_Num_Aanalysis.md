Numerical analysis
----

兩個隨機變數可能互相獨立也可能不獨立。
> 所謂獨立, 是隨機式的獨立, 改變其中一個變數的值, 對另一變數的值毫無影響

如果二隨機變數不獨立, 則二變數間便有關係.
> 此關係可能強可能弱,

利用統計學及數值分析方法, 就可以度量兩隨機變數關係的強弱.
> 如果是互相獨立, 則關係是最弱的

以水為例子, 假設 $X$ 表示體積, $Y$ 表示重量, 顯然 $X$ 與 $Y$ 之關係很強.
如果多次取樣, 將所得的 $(X,Y)$ 數據畫在座標平面上, 則所有的點很可能落在一直線上或直線的附近.
> 這是因為水的重量與體積有線性關係. 而有些數據不在直線上, 可能是因量測的誤差, 或水質不純所致

若假設 $X$ 表示某人的身高, $Y$ 表示其體重, $X$ 與 $Y$ 同樣也會有關係, 但可能不會那麼強.
> 量測一些不同的人, 所得的 $(X,Y)$, 通常不會形成一直線,
但我們仍然可以預期圖形是向上增長, 即 $X$ 變大 $Y$ 也會跟著變大的趨勢

## 變異數 (Variance, 又稱**方差**)

Variance 描述的是**一個隨機變數的離散程度**, 即一組數字與其平均值(Mean)之間距離的度量
> 離散程度表示數值間的緊密程度 (在座標空間中分布狀況, 也就是距離)

假設取 $m$ 個樣本
$$
Variance = \sigma^2 = \frac{1}{m - 1}\sum_{i=1}^{m}(RealValue_i - Mean)^2
$$

## 標準差(Standard Deviation)

將變異數(Variance)開根號即可得到標準差(Standard Deviation), 用於表示資料之離散程度 (與平均值的差異)
> 除上(m-1)而不是 m 的原因是, 只用少部分樣本在推論母體時, 因為偏量(bias)的關係, 在推論時樣本推估會少一個自由度
>> [統計學: 常態分佈平均數估計與變異量估計以及為什麼樣本變異量分母要減1](https://medium.com/@chih.sheng.huang821/%E7%B5%B1%E8%A8%88%E5%AD%B8-%E5%B8%B8%E6%85%8B%E5%88%86%E5%B8%83%E5%B9%B3%E5%9D%87%E6%95%B8%E4%BC%B0%E8%A8%88%E8%88%87%E8%AE%8A%E7%95%B0%E9%87%8F%E4%BC%B0%E8%A8%88%E4%BB%A5%E5%8F%8A%E7%82%BA%E4%BB%80%E9%BA%BC%E6%A8%A3%E6%9C%AC%E8%AE%8A%E7%95%B0%E9%87%8F%E5%88%86%E6%AF%8D%E8%A6%81%E6%B8%9B1-bfff53b02b95)

假設取 $m$ 個樣本
$$
\sigma = \sqrt{\frac{1}{m - 1}\sum_{i=1}^{m}(RealValue_i - Mean)^2}
$$

## 共變異數(Covariance, 又稱**協方差**)

Covariance 在機率論和統計學中, 用於衡量**兩個隨機變數**的總體誤差
> 而 Variance 是 Covariance 的一種特殊情況, 即當兩個隨機變數都相同的情況
> + 當 `Covariance > 0` 表示兩個變數的變化趨勢一致
> + 當 `Covariance < 0` 表示兩個變數的變化趨勢相反
> + 當 `Covariance == 0` 表示至少有一個變數為固定值


假設取 $m$ 個樣本
$$
Covariance(X, Y) = \frac{1}{m - 1}\sum_{i=1}^{m - 1}((x_i - mean_x)×(y_i - mean_y))
$$

## 相關係數(Correlation coefficient, 或 Correlation)

Correlation 很常用在機器學習或是統計分析上使用, 主要衡量兩隨機變數間, **線性關聯性**的高低程度, 會落在`-1 ~ 1`之間
> 兩個隨機變數(或多變數)間, 是否存在**線性關係**
> + `Correlation > 0` 兩變數正相關
>> **正相關**表示, 當其中一變數變大(或變小), 另一變數也會跟著變大(或變小)
> + `Correlation < 0` 兩變數負相關
>> **負相關**表示, 當其中一變數變大(或變小), 另一變數會跟著變小(或變大)
> + `Correlation == 1` 兩變數完全線性相關, 即為函數關係
> + `Correlation == 0` 兩變數無線性相關


$$
Correlation(X, Y) = \rho = \frac{Covariance(X, Y)}{\sigma_x×\sigma_y}
=\frac{\frac{1}{m - 1}\sum_{i=1}^{m - 1}((x_i - mean_x)×(y_i - mean_y))}{\sqrt{\frac{1}{m - 1}\sum_{i=1}^{m}(x_i - Mean_x)^2}×\sqrt{\frac{1}{m - 1}\sum_{i=1}^{m}(y_i - Mean_y)^2}}
$$

+ 為何相關係數可以在不同單位間做比較
    > 假設 $X$ 是身高(單位:cm), $Y$ 變數是體重(單位:kilo), $Z$ 變數是年齡(單位:year)
    > - $\sigma_x$ 標準差的單位是**cm**
    > - $\sigma_y$ 標準差計的單位是**kilo**
    > - $\sigma_z$ 標準差計的單位是**year**
    > - $Covariance(X, Y)$ 的單位則是`cm*kilo`
    > - $Covariance(X, Z)$ 的單位則是`cm*year`

    > **Correlation 將 Covariance 除上兩個隨機變數的 Standard Deviation, 將單位抵銷掉**
    >> 相關係數將隨機變數都拉到同一個基準線上, 值會落在 `-1 ~ 1` 之間

    $$
    Correlation(X, Y) = \frac{Correlation(X, Y)}{\sigma_x×\sigma_y} = \frac{cm×kilo}{cm×kilo}
    $$

    $$
    Correlation(X, Z) = \frac{Correlation(X, Z)}{\sigma_x×\sigma_z} = \frac{cm×year}{cm×year}
    $$

## 均方根誤差(Root Mean Squared Error, RMSE)

用來衡量預測值(PredictionValue)與實際值(RealValue)之間的偏差, 對一組測量中的特大或特小誤差(異常值)反應非常敏感

假設取 $m$ 個樣本
$$
RMSE = \sqrt{\frac{1}{m}\sum_{i=1}^{m}(PredictionValue_i - RealValue_i)^2}
$$



# Reference
+ [共變異數及相關係數](https://www.stat.nuk.edu.tw/cbme/math/statistic/sta2/s3_5/node1.html)
+ [相關係數與共變異數(Correlation Coefficient and Covariance)](https://chih-sheng-huang821.medium.com/%E7%9B%B8%E9%97%9C%E4%BF%82%E6%95%B8%E8%88%87%E5%85%B1%E8%AE%8A%E7%95%B0%E6%95%B8-correlation-coefficient-and-covariance-c9324c5cf679)


