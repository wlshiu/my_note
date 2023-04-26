KeyWord Spotting, KWS
---

# CMU Sphinx

CMU Sphinx(簡稱 Sphinx) 是美國卡內基梅隆大學開發的一系列語音識別工具包以及相關工具
> e.g. 聲學模型訓練軟體, 語言模型編輯軟體, 和語音詞典 CMUDICT 等的總稱

在 2000 年, 卡內基梅隆的 Sphinx 小組致力於開源幾個語音識別器元件, 包括 Sphinx 2 和後來的 Sphinx 3(2001 年).
> Sphinx 包括許多工具包, 可以用於搭建具有不同需求的應用.
> + Pocketsphinx
>> 用 C 語言編寫的輕量級的語音識別庫
> + Sphinxbase
>> 提供了公共的函數功能, 為 Pocketsphinx 依賴的函式庫
> + Sphinx4
>> 用 Java 編寫的自適應的, 可修改的語音識別庫
> + Sphinxtrain
>> 聲學模型訓練軟體

Sphinx 除了是 open source 之外, 還可以自己定製聲音模型, 語言模型, 語音學字典, 用於多個不同的場景
> e.g. 語音搜尋, 語義分析, 翻譯, 智能助手等

+ 如何選擇需要的工具包呢
    > 由於 Sphinx 有用不同的程式語言開發的工具包, 所以開發者可以根據自己的習慣, 選擇相應的語言識別包
    > + 如果想要 lite 和 portable, 那麼選擇 `pocketsphinx`
    > + 如果你想要靈活和可管理, 那麼可以選擇 `sphinx4`

## [CMUSphinx-Practice](note_CMUSphinx_practice.md)


# Reference

+ [開源語音識別工具包 - CMUSphinx](https://blog.csdn.net/muxiue/article/details/90292977?spm=1001.2101.3001.6650.5&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-5-90292977-blog-53729304.235%5Ev30%5Epc_relevant_default_base3&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-5-90292977-blog-53729304.235%5Ev30%5Epc_relevant_default_base3&utm_relevant_index=6)
+ [利用PocketSphinx在Windows上搭建一個語言識別應用](https://blog.csdn.net/muxiue/article/details/90294594)

