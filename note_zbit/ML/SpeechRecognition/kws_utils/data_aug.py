# coding=utf-8
"""
@ Summary: data augmentation
@ Using:   更改class_dir 和 replaced_dir 兩個參數
           增強的文件夾分別有三個，在語音同文件夾下面，分別為
                aug_$NAME/1; aug_$NAME/2; aug_$NAME/3

@ file:    data_aug.py
@ Update:  新增噪音增強
@ version: 1.0.2

@ Update:  在生成的音頻的基礎上,做增強,x 為原始音頻數量
           第一次增強: (6 * x + x) = 7x;
           第二次增強: 6 * (7 * x) + 7x = 49x;
           第三次增強: 5 * (49 * x) + 49x = 294x
           增強後的音頻為原來的額294倍
@ version: 1.0.3

@ Author:  Lebhoryi@gmail.com
@ Date:    2020/3/23 下午7:58
"""
import shutil
from pathlib import Path

import librosa
import numpy as np
from scipy.io import wavfile


def aug_pitch_shift(input_audio, outdir):
    # 通過移動音調變聲
    if not outdir.exists():   # 判斷目標路徑是否存在，不存在則創建
        outdir.mkdir(parents=True)

    y, sr = librosa.load(input_audio, sr=16000)
    # step = [-1.5, -1, -0.5, 0.5, 1, 1.5]
    step = [-1, 1]
    for i in range(len(step)):
        y_shift = librosa.effects.pitch_shift(y, sr, n_steps=step[i])   # 使用PS生成新數據
        wavfile.write(outdir / (input_audio.stem + f'_ps{i}.wav'), sr, y_shift)

    # 複製原始音頻文件到新文件夾
    shutil.copy(input_audio, outdir)
    # print(f"正在增強{input_audio.name}的音調...")


def aug_time_stretch(input_audio, outdir, flag=False):
    # 時移增強
    if not outdir.exists():   # 判斷目標路徑是否存在，不存在則創建
        outdir.mkdir(parents=True)

    y, sr = librosa.load(input_audio, sr=16000)
    # rate = [0.8, 0.95, 0.9, 1.1, 1.15, 1.2]
    rate = [0.9, 1.1]
    for i in range(len(rate)):
        y_shift = librosa.effects.time_stretch(y, rate=rate[i])   # 使用TS生成新數據
        wavfile.write(outdir / (input_audio.stem + f'_ts{i}.wav'), sr, y_shift)
    # 複製原始音頻文件到新文件夾
    if flag:  shutil.copy(input_audio, outdir)


def aug_add_noise(input_audio, outdir, flag=False):
    # 增加隨機噪聲
    if not outdir.exists():   # 判斷目標路徑是否存在，不存在則創建
        outdir.mkdir(parents=True)

    y, sr = librosa.load(input_audio, sr=16000)
    wn = [np.random.randn(len(y)) for _ in range(6)]
    for i in range(len(wn)):
        y_shift = np.where(y != 0.0, y + 0.02 * wn[i], 0.0)
        wavfile.write(outdir / (input_audio.stem + f'_{i}.wav'), sr, y_shift)
    # 複製原始音頻文件到新文件夾
    if flag:  shutil.copy(input_audio, outdir)


if __name__ == "__main__":
    class_dir = Path("../../local_data/web_data_train/xrxr_1s")

    assert class_dir.exists(), Exception("No " + str(class_dir) + "!")

    # # 獲取目標路徑和增強文件夾,list
    # replaced_dir = [class_dir] + \
    #                [class_dir.parent/("aug_"+class_dir.name)/str(i) for i in range(1, 4)]
    #
    # aug_func = [aug_pitch_shift, aug_time_stretch, aug_add_noise]
    #
    # # 對原有音頻做迭代增強
    # print(f"原始音頻有{len(list(replaced_dir[0].iterdir()))}條")
    #
    # for i in range(3):
    #     wav_paths = replaced_dir[i].glob("*.wav")
    #     for wav in wav_paths:
    #         aug_func[i](wav, replaced_dir[i+1])
    #
    #     print(f"第{i+1}階段增強完成, (aug + raw) 共有{len(list(replaced_dir[i+1].iterdir()))}條音頻")


    # 僅對原音頻文件做各自增強
    # 獲取.wav 文件路徑
    wav_paths = class_dir.glob("*.wav")
    replaced_dir = class_dir.parent / 'aug_unknown'

    for i, wav in enumerate(wav_paths):
        aug_pitch_shift(wav, replaced_dir)
        aug_time_stretch(wav, replaced_dir)
        # aug_add_noise(wav, replaced_dir)
        if i % 50 == 0:
            print("正在增強第{}條語音....".format(i))

    print("完成數據增強工作～")
