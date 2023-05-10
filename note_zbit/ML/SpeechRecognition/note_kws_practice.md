KWS Practice [[Back](note_kws.md#ML-KWS-for-MCU)]
---

Base on TensorFlow v1.15, use [ML-KWS-for-MCU](https://github.com/ARM-software/ML-KWS-for-MCU)  <br>
> TensorFlow 將所有 components 物件化, 並將其流程化
>> + `models.py` 負責實例化 CNN 的 core algorithm
>> + `input_data.py` 負責處理 input data

`ML-KWS-for-MCU` 提供幾個工具 (python 實作)
> + `train.py` 是訓練模型的進入點
>> `models.py` 是模型的實作, `input_data.py` 則預處理輸入 data
> + `freeze.py` 將訓練結果轉換為 `*.pb` 發佈
> + `quant_test.py` 將 `*.ckpt-xxx.*` 做非線性量化 (Float-Pointer to Fix-Pointer), 並輸出 weights
>> `quant_models.py` 是量化的實作
> + `label_wav.py` 用來測試訓練結果
> + `fold_batchnorm.py` 最佳化運算流程
>> 在 Convolution 或 Fully-Connected layers 之後, batch normalization layer 的參數(i.e. mean, variance, scale factor and offset factors)
可以整合到對應 convn/fc layer 的 weigths 和 bias 中, 進而最佳化流程


## Training

基於 tensorflow framework, `ML-KWS-for-MCU` 改寫 `train.py`

+ Options
    > 介紹`train.py`的命令行參數, 可以通過類似`–data_url=xxxx`來修改

    + `data_url`
        > dataset 的下載 url
        >> default: `http://download.tensorflow.org/data/speech_commands_v0.02.tar.gz`

    + `data_dir`
        > 下載存放的目錄, (如果下載過了, 第二次就不會再下載)
        >> dataset 須放在這個目錄下

    + `background_volume`
        > 背景噪聲的音量 (def: 0.1)
        >> 這是一種 Data Augmentation 的技術, 通過給語音增加噪聲, 來提高模型的泛化(Generalization)能力.

        - 泛化 (Generalization)
            > 可以當作是對 data 的適應性或容忍性

    + `background_frequency`
        > 多少比例的訓練數據會增加噪聲 `def: 0.8 (代表 80%)`

    + `silence_percentage`
        > 訓練數據中 silence 的比例 `def: 10 (代表 10%)`
        >> silence 模擬的是沒有輸入的情況

    + `unknown_percentage`
        > 除了需要識別的 `yes` and `no`等詞, 還需要加入一些其它詞, 否則只要有人說話(非silence), classifier 就一定會識別成 10 個詞中的某一個
        >> `def: 10 (代表 10%)`, 表示會隨機加入 10% 的其它詞 (e.g. one, two, three, ...etc)

    + `time_shift_ms`
        > 錄音都是長度 1 秒的文件, 但是在實際預測的時候, user 開始的時間是不固定的,
        為了模擬這種情況, 會隨機的把錄音文件**往前**或**往後**平移一段時間, 這個參數就是指定平移的範圍
        >> `def: 100 (ms)`, 說明會隨機的在 [-100, 100] 之間平移數據

    + `testing_percentage`
        > 用於測試的數據比例 `def: 10 (10%)`

    + `validation_percentage`
        > 驗證集合的比例 `def: 10(10%)`

    + `sample_rate`
        > 錄音的取樣率 `def: 16000`
        >> 需要和 wav 中的取樣率匹配

    + `clip_duration_ms`
        > 錄音文件的時長 `def: 1000 (ms)`

    + `window_size_ms`
        > hamming windeow legnth `def: 30 (ms)`
        >> 含義請參考 MFCC 特徵提取部分

    + `window_stride_ms`
        > stride of window `def: 10 (ms)`

    + `feature_bin_count`
        > DCT 後, 保留的係數個數 `def: 40`
        >> MFCC 是 10 ~ 12

    + `how_many_training_steps`
        > `def: 15000,3000`, 因為需要調整 learning_rate, 所以用逗號分成多段

    + `learning_rate`
        > `def: 0.001,0.0001`, 結合 `how_many_training_steps` 參數, 它的意思是
        > + 用 `learning_rate 0.001`訓練 15000 個 minibatch,
        > + 然後再用 `learning_rate 0.0001`訓練 3000 個 minibatch

    + `batch_size`
        > batch_size 的作用, 是設定每次訓練時, 在 dataset 中取 batch_size 個 samples 訓練,
        >> 設定小批次梯度下降, 每次梯度更新的 samples 數量

        - 變數 `iteration` (in train.py)
            > 1 個 iteration 等於使用 batch_size 個 samples 訓練一次

        - 變數 `epoch` (in train.py)
            > 1 個 epoch 等於使用 dataset 中的全部 samples 訓練一次
            >> 通俗的講, epoch 的值, 就是 全部 dataset 被輪幾次

    + `eval_step_interval`
        > 訓練多少個 batch_size 就評估一次 `def: 400`

    + `summaries_dir`
        > `def: /tmp/retrain_logs`
        >> 保存用於 TensorBoard 可視化的 Summary(Event) 文件

    + `wanted_words`
        > 哪些詞是我們需要識別的,
        >> `def: yes,no,up,down,left,right,on,off,stop,go`, 這些詞之外的都是 unknown_words

    + `train_dir`
        > Model 的 checkpoint (*.ckpt) 存放目錄 `def: /tmp/speech_commands_train`

    + `save_step_interval`
        > `def: 100`, 每隔 100 次迭代, 就保存一份 checkpoint 文件 (*.ckpt)

    + `start_checkpoint`
        > `def: 空字符串`, 如果非空, 則從這裡恢復 checkpoint 繼續訓練

    + `model_architecture`
        > Model 結構 `def: conv`,
        >> `train.py`還支援其它模型結構

    + `--model_size_info 144 144 144`
        > Model dimensions
        >> `def: 128, 128, 128`,  DNN 模型結構 全連接層 神經元數量 128 共 3 層.

    + `check_nans`
        > 是否檢查 NAN `def: False`

    + `quantize`
        > 是否量化參數, 以便降低模型大小 `def: False`

    + `preprocess`
        > 語音數據預處理(特徵提取)方法 `def: mfcc`


+ Training result
    > TensorFlow 訓練的過程, 會記錄在 checkpoint (*.ckpt), 一般會有以下檔案
    > + checkpoint
    >> 列出保存的所有模型, 以及最近模型的相關資訊
    > + model.ckpt.data-xxx
    >> 保存訓練變數的值
    > + model.ckpt.index
    >> 保存 variable 中 key 和 value 的對應關係
    > + model.ckpt.meta
    >> 中繼資料圖, 保存了 tensorflow 完整的網路圖結構


    - `*.pb` (Protocol Buffers)
        > TensorFlow 模型訓練完成後, 通常會通過 frozen 過程(freeze.py), 轉換成最終的 pb 模型, 以供發佈使用
        >> pb 模型是以 GraphDef format 保存的, 可以序列化保存為 **Binary PB 模型** 或者 **文字 pbtxt 模型**

    - ONNX (開放神經網路交換, Open Neural Network Exchange)
        > 是 Microsoft 和 Facebook 提出, 用來表示深度學習模型的開放格式.
        >> ONNX定義了一組, 和環境平台都無關的標準格式, 來增強各種 AI 模型的可互動性
        換句話說, 無論你使用何種訓練框架訓練模型(e.g. TensorFlow/Pytorch/OneFlow/Paddle),
        在訓練完畢後, 你都可以將這些框架的模型, 統一轉換為 ONNX 這種統一的格式進行儲存.

        >> 注意 ONNX 檔案不僅僅儲存了神經網路模型的權重, 同時也儲存了模型的結構資訊,
        以及網路中每一層的輸入輸出,和一些其它的輔助資訊

+ Bash

    ```bash
    #!/bin/bash

    python train.py --model_architecture ds_cnn \
        --data_dir ~/working/KWS/mini_speech_commands/  \
        --model_size_info 5 64 10 4 2 2 64 3 3 1 1 64 3 3 1 1 64 3 3 1 1 64 3 3 1 1 \
        --dct_coefficient_count 10 \
        --window_size_ms 40 \
        --window_stride_ms 20 \
        --learning_rate 0.0005,0.0001,0.00002 \
        --how_many_training_steps 10000,10000,10000 \
        --summaries_dir ./Result/log/  \
        --train_dir ./Result/speech_cmds_train/ \

    # '*.ckpt' to '*.pb'
    python freeze.py --model_architecture ds_cnn \
        --data_dir $HOME/../data_1/working/KWS/speech_commands_v0.02 \
        --model_size_info 5 64 10 4 2 2 64 3 3 1 1 64 3 3 1 1 64 3 3 1 1 64 3 3 1 1 \
        --dct_coefficient_count 10 \
        --window_size_ms 40 \
        --window_stride_ms 20 \
        --checkpoint=./Result/speech_cmd_train/best/ds_cnn_9291.ckpt-25200 \
        --output_file=./Result/ds_cnn_9291.pb

    # verify pb model with the other *.wav file (not in training dataset)
    python label_wav.py --wav ../mini_speech_commands/yes/b00dff7e_nohash_0.wav \
        --graph ./Result/ds_cnn_9291.pb \
        --labels ./Result/speech_cmd_train/ds_cnn_labels.txt \
        --how_many_labels 1


    # 生成一個 FLAGS.checkpoint+'_bnfused'的文件, 僅保留 W 和 b
    python ./fold_batchnorm.py --model_architecture ds_cnn \
        --data_url= \
        --data_dir $HOME/../data_1/working/KWS/speech_commands_v0.02 \
        --dct_coefficient_count 10 \
        --window_size_ms 40 \
        --window_stride_ms 20 \
        --model_size_info 5 64 10 4 2 2 64 3 3 1 1 64 3 3 1 1 64 3 3 1 1 64 3 3 1 1 \
        --checkpoint=./Result/speech_cmd_train/best/ds_cnn_9291.ckpt-25200
    ```


## Quant weights

量化並將 Float-Pointer 轉成 Fix-Pointer (Q7)

```bash
#!/bin/bash

python quant_test.py --model_architecture=ds_cnn\
    --data_url= \
    --data_dir $HOME/../data_1/working/KWS/speech_commands_v0.02 \
    --model_size_info 5 64 10 4 2 2 64 3 3 1 1 64 3 3 1 1 64 3 3 1 1 64 3 3 1 1 \
    --dct_coefficient_count 10 \
    --window_size_ms 40 \
    --window_stride_ms 20 \
    --batch_size 100 \
    --checkpoint=./Result/speech_cmd_train/best/ds_cnn_9291.ckpt-25200 \
    --output=./Result/weights_h/

```

# Reference

+ [Lebhoryi/ML-KWS-for-MCU](https://github.com/Lebhoryi/ML-KWS-for-MCU/tree/main)

