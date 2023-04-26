MFCC [[Back](note_kws.md)]
---

梅爾倒頻譜(MFC, Mel-Frequency Cepstrum)是一個可用來代表**短期音訊**的頻譜,
梅爾倒譜係數 (MFCC, Mel-scaleFrequency Cepstral Coefficients) 則是一組用來建立梅爾倒頻譜的關鍵係數

根據人耳聽覺模型的研究發現, 人耳對不同頻率的聲波有不同的聽覺敏感度.
> 從 `200 ~ 5000 Hz`的訊號, 對 Speech 的清晰度影響對大

兩個音量(響度)不等的聲音作用於人耳時, 則音量較大的音頻成分, 會影響到對音量較小的音頻成分的感受, 使其變得不易察覺, 這種現象稱為**掩蔽效應**
> 由於低頻的聲音在內耳蝸基底膜上, 傳遞的速度, 大於高頻的聲音, 故一般來說, 低音容易掩蔽高音, 而高音掩蔽低音較困難

因此人們從低頻到高頻這一段頻帶內, 按臨界頻寬的大小, 由密到疏安排一組濾波器, 對輸入訊號進行濾波.
> MFCC 的在低頻部分的解析度高, 跟人耳的聽覺特性是相符的

將每個濾波器輸出的訊號能量, 作為訊號的基本特徵, 對此特徵經過進一步處理後, 就可以作為語音的輸入特徵.
由於這種特徵不依賴於訊號的性質, 對輸入訊號不做任何的假設和限制, 又利用了聽覺模型的研究成果。

因此, MFCC 參數比基於聲道模型的 LPCC 相比, 具有更好的 robost, 更符合人耳的聽覺特性, 而且**當訊號雜訊比降低時, 仍然具有較好的識別性能**

+ 

    ```python
    # MFCC curve
    import numpy as np
    import matplotlib.pyplot as plt

    x = np.arange(8001)
    y = 2595 * np.log10(1+x/700)

    plt.plot(x, y, color='blue', linewidth=3)

    plt.xlabel("f", fontsize=17)
    plt.ylabel("Mel(f)", fontsize=17)
    plt.xlim(0,x[-1])
    plt.ylim(0,y[-1])

    plt.savefig('mel_f.png', dpi=500)    
    ```


# MFCC flow

```
    input fram --> Pre-emphasis --> Framing --> Hamming windowing --> FFT
                                                                        |
                                                                        v
                Delta cepstrum <-- Log energy <-- DCT <-- Triangular Bandpass Filters
```

+ 預強調 (Pre-emphasis)
    > 目的是為了消除發聲過程中, 聲帶和嘴唇的效應, 來補償語音信號受到發音系統所壓抑的高頻部分
    >> 另一種說法則是要突顯在高頻的共振峰

    > 經過了預強調之後, 聲音變的比較尖銳清脆, 但是音量會變小

+ 音框化(Framing)

+ 漢明窗 (Hamming windowing)

+ 快速傅利葉轉換 (FFT)

+ 三角帶通濾波器 (Triangular Bandpass Filters)

+ 離散餘弦轉換 (DCT)

+ 對數能量 (Log energy)

+ 差量倒頻譜參數 (Delta cepstrum)

# Reference

+ [語音識別第4講：語音特徵參數MFCC](https://zhuanlan.zhihu.com/p/88625876)
+ [MFCC 梅爾倒頻譜係數](https://blog.maxkit.com.tw/2019/12/mfcc.html)


