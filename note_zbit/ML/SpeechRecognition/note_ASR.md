ASR (Automatic Speech Recognition)
---

語音辨識(Speech Recognition)技術, 其目標是嘗試以電腦自動識別人類的語音中所包含的詞彙內容
> 也被稱為
> + 自動語音辨識(Automatic Speech Recognition, ASR)
> + 電腦語音識別(Computer Speech Recognition)
> + 語音轉文字識別(Speech To Text, STT)

# OpenSource

## [CMU Sphinx (C/Java)](https://cmusphinx.github.io/)
是美國卡內基梅隆大學開發的一系列語音識別系統的總稱.
> 在 2000 年, 卡內基梅隆的 Sphinx 小組致力於開源幾個語音識別器元件, 包括 `Sphinx 2`和後來的`Sphinx 3`(2001年). <br>
其語音解碼器帶有`聲學模型`和`示例應用程式`. 而可用資源包括`聲學模型訓練軟體`, `語言模型編輯軟體`和`語音詞典cmudict`

+ CMU Sphinx包含許多用於不同任務和應用程式的開發包。主要包括：
    - `Pocketsphinx`
        > Lightweight recognizer library written in C language (C 語言開發的輕量級語音識別引擎)

    - `Sphinxtrain`
        > Acoustic model training tools (聲學模型訓練工具)

    - `Sphinxbase`
        > Support library required by Pocketsphinx andSphinxtrain (Pocketsphinx 和 Sphinxtrain 的基礎類庫)

    - `Sphinx4`
        > Adjustable, modifiable recognizer written in Java (Java語言開發的可調節, 可修改的語音識別引擎)


+ CMU Sphinx包含`聲學模型 (Acoustic model)`, `語言模型 (Language model)`, `發音字典 (Phonetic dictionary)`
    - `聲學模型`
        > 主要用於計算`語音特徵`和**每個發音範本之間**的`似然度(likelihood)`;
        目的是為每個聲學單元, 建立一套模型引數, 並通過不斷地學習和改進, 得到機率最大的一組 HMM 模型引數.

        > CMU Sphinx 的聲學模型包含每個句子的聲學特性, 存在與上下文相關的模型, 其包含
        > + 屬性 (每個音素的最可能的特徵向量)
        > + 依賴於上下文的(從具有上下文的語音建立的)屬性

    - `語言模型`
        > 定義了哪些單詞可以遵循以前識別的單詞, 並通過剝離不可能的單詞來幫助限制匹配過程. <br>
        最常用的語言模型是 `N-gram 語言模型`, 它包含
        > + 單詞序列的統計數據
        > + 有限狀態語言模型,

        > 通過有限狀態自動化(有時具有權重)來定義語音序列

    - `發音字典`
        > 包含了從`單詞(words)`到`音素(phones)`之間的對應, 作用是用來連線聲學模型和語言模型. <br>
        發音字典包含**系統所能處理的單詞的集合**, 並標明瞭其發音. <br>
        通過發音字典, 得到`聲學模型`和`語言模型`之間建模單元的對應關係,
        從而把聲學模型和語言模型連線起來, 並組成一個搜尋的狀態空間, 讓解碼器用於解碼工作

## [Eesen (C++)](https://github.com/srvk/eesen)

Eesen 框架極大地簡化了建構最優 ASR 系統的流程.
> 聲學建模包括使用 RNN 學習預測上下文無關目標(音素或字元), 為了消除預先生成的 frame 標籤的需求, 採用了 CTC 目標函數來推斷語音和標籤序列之前的對齊方式
>> Eesen 一個顯著特徵是, 基於加權有限狀態轉換機 (WFST) 解碼方式, 該方法可將詞典和語言模型有效地合併到 CTC 中. <br>
實驗表明, 與標準的混合 DNN 系統相比, Eesen 可以達到可比的誤位元率(WER), 同時可以顯著加快解碼速度

傳統上, 自動語音識別(ASR)利用隱馬爾可夫模型/高斯混合模型(HMM / GMM)範例進行聲學建模.
> + `HMM` 用于歸一化時間變異性
> + `GMM` 用於計算 HMM 狀態的發射機率

近年來, 通過引入深層神經網路(DNN)作為聲學模型, ASR 的性能得到了顯著提高.
> 在各種 ASR 任務上, 與 GMM 模型相比, DNN 模型顯示出顯著的進步

儘管取得了這些進步, 但建立最先進的 ASR 系統仍然是一項複雜且需要大量專業知識的任務
1. 聲學建模通常需要各種資源, 例如詞典和語音問題
1. 在混合方法中, DNN 的訓練仍然依賴於 GMM 模型來獲取(初始) frame 級標籤.
    > 建立 GMM 模型通常會經歷多個階段(e.g CI phone, CD 狀態等), 並且每個階段都涉及不同的特徵處理技術(e.g. LDA, fMLLR, ... etc)
1. ASR 系統的開發, 高度依賴於 ASR 專家來確定多個超參數的最佳組態, e.g. GMM 模型中的 senone 和高斯數

列舉了 CTC 的出現, 但解碼仍是個問題, 藉由 Eesen 模型來解決這個問題
> + 以 RNN 作為聲學模型
> + 以 LSTM 作為模型組成塊
> + 以 CTC 作為目標函數
> + 將聲音建模簡化為, 通過語音和上下文無關(CI)標籤序列對學習單個 RNN

Eesen 的一個顯著特徵, 是基於加權有限狀態換能器(WFST)的通用解碼方法
> 用這種方法, 將各個組成部分 (CTC標籤, 詞典和語言模型) 編碼為 WFST(TLG), 然後組成一個全面的搜尋圖
>> WFST 提供了一種方便的方式, 來處理 CTC 空白標籤, 並在解碼期間啟用波束搜尋

我們使用《華爾街日報》(WSJ)基準進行的實驗表明, 與現有的端到端ASR管道相比, Eesen的性能更高.

Eesen 的 WER 與強大的 HMM/DNN 混合基準相當, 而且 CI 建模目標的應用, 允許 Eesen 加快解碼速度並減少解碼記憶體使用量

+ [paper eesenasru](http://www.cs.cmu.edu/~fmetze/interACT/Publications_files/publications/eesenasru.pdf)

## [Julius (C)](https://github.com/julius-speech/julius)

京都大學在 1991 年使用 `C language` 開發的, 然後於 2005 年移交給一個獨立的專案團隊. <br>
主要為學術和研究所設計, 其優點為
+ Real-Time STT 的能力
+ Low memory usage (20000 單詞少於 64 MB)
+ 能夠輸出最優詞 (N-best word) 和詞圖 (Word-graph)
+ 日語支援度高


## [DeepSpeech (Python)](https://github.com/mozilla/DeepSpeech)

由 Mozilla 開發 (`Python`), 這是一個語音轉文字庫, 它使用了 `TensorFlow` 機器學習框架實現去功能

## [Kaldi, C++](https://github.com/kaldi-asr/kaldi)
Kaldi 是一個用`C ++` (Apache LICENSE) 編寫的語音識別工具包, 項目其宗旨就是為了給語音識別研究人員使用,
因為 kaldi 擁有大多數標準技術的程式碼和指令碼, 大部分語音識別領域的專家學者, 其語音研究結果都是基於 kaldi 來進行. <br>
其特色包括
+ 所有標準線性變換
+ MMI, 增強 MMI 和 MCE 判別訓練
+ 特徵空間判別訓練(e.g. fMPE, 但基於提升的 MMI)


## [Whisper (Python)](https://github.com/openai/whisper)

`Python` and from OpenAI

## [PaddleSpeech](https://github.com/PaddlePaddle/PaddleSpeech)

百度開發 (`Python`)

## [ASRT (Python)](https://github.com/nl8590687/ASRT_SpeechRecognition)

一個基於深度學習的中文語音識別系統 (Python)

# Dataset
---

+ [LibriSpeech](https://www.openslr.org/resources.php)
+ [AISHELL-2 中文語音資料庫](https://www.aishelltech.com/aishell_2)

+ TensorFlow web
    - [TensorFlow Datasets](https://github.com/tensorflow/datasets)
        > Use python lib to download
    - [Speech Commands Dataset v0.01 (1.38GB)](http://download.tensorflow.org/data/speech_commands_v0.01.tar.gz)
    - [Speech Commands Dataset v0.02 (2.3GB)](http://download.tensorflow.org/data/speech_commands_v0.02.tar.gz)

+ [Open-source Audio Datasets](https://github.com/DAGsHub/audio-datasets)
+ [Speech_Commands_Dataset](https://dagshub.com/kingabzpro/Speech_Commands_Dataset/src/master)


## Digital Audio Signal Data

Audio raw data 一般會使用 PCM (Pulse-Code Modulation), 每個 sample 大小可以用 8-bits or 16-bits 來記錄

+ 有號或無號 PCM
    > 使用 16-bits 紀錄時, 可分為`有號(s16)` 跟 `無號(u16)`

    - s16 convert to u16
        > 調整基準值 `offset = MAX_UINT16 / 2`

        ```c
        audio_sample_u16 = audio_sample_s16 + 0x8000
        ```

+ 使用 ADC 取樣
    > 一般 ADC 為 12-bits 精準度, 將 ADC 取樣值轉換為 u16

    ```c
    // LSB 補 0
    PCM = ADC_value << 4;
    ```

+ 分貝(Decibel) 標度
    > 分貝是量度兩個相同單位之數量比例的單位, 主要用於度量聲音強度, 常用 `dB`表示
    >> 聲學中, 聲音的強度定義為聲壓, 計算分貝值時, 採用 20 µPa 為參考值

    - PCM 轉換為 分貝標度

        ```c
        int16_t     pcm[1024] = {...};
        int32_t     val;
        int         db = 48;
        float       multiplier = pow(10, db/20);

        for(int i = 0; i < 1024; i++)
        {
            val = pcm[i] * multiplier;

            if( val < 32767 && val > -32768)
                pcm[ctr] = val
            else if( val > 32767 )
                pcm[ctr] = 32767;
            else if( val < -32768 )
                pcm[ctr] = -32768;
        }
        ```

# Benchmark
---



# Reference
---
+ [語音辨識 wiki](https://zh.wikipedia.org/zh-tw/%E8%AF%AD%E9%9F%B3%E8%AF%86%E5%88%AB)
+ [CMUSphinx](https://cmusphinx.github.io/)
    - [聲學模型/語言模型/拼音字典](https://sourceforge.net/projects/cmusphinx/files/Acoustic%20and%20Language%20Models/)
    - [CMU Sphinx- old web](https://web.archive.org/web/20070929201050/http://cmusphinx.sourceforge.net/html/cmusphinx.php)

+ [臺灣言語工具](https://github.com/i3thuan5/tai5-uan5_gian5-gi2_kang1-ku7)
+ [現在有什麼開放原始碼的語音識別嗎？](https://www.zhihu.com/question/23473262)