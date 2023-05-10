kws utils
---
lebhoryi 寫的文件腳本存放處, 文件中有使用說明
> mail: `lebhoryi@rt-thread.mail`

```
./
├── data_aug.py         # 語音增強
├── data_clips.py       # 將數據隨機分 10% 到驗證和測試的txt中, tx t在 data 目錄下
├── get_wav.py          # 從網頁爬取語音數據
├── get_mfcc.py         # tf1 獲取單個 audio 的 mfcc 值
├── get_output_from_network.py      # 獲取網絡結構中的中間輸出結果
├── get_variable_name_from_ckpt.py  # 從 ckpt 文件中獲取變量的名字
├── librosa_mfcc.py     # 用 librosa 實現 mfcc 提取
├── model.py            # 重構網絡結構, 獲取中間層的輸出結果用
├── readme.md           # readme
├── rm_aug_silence.py   # 移除 audio 的開頭和結尾的靜音區
├── test_model.py       # 用自己的數據集對模型進行測試, 獲取 acc/precision/recall 等
├── tf2_mfccs.py        # tf2 分步驟獲取 mfcc, 包括 windowing/FFT 等
└── wav8_16k.sh         # 強制將語音數據改為 16k 採樣率, 16 bits, 1 channel
```
