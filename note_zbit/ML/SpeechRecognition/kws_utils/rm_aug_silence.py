# coding=utf-8
'''
@ Summary: 最終的效果是用腳本分離出1s和超過1s的，然後超過1s的手動進行剪輯，
           音頻文件名不改，在同一個音頻文件夾路徑下會生成兩個音頻文件夾，分別存放
           超過1s和1s的音頻

@ file:    rm_aug_silence.py
@ version: 1.0.0

@ Update:  增加pathlib.Path() 這個庫，可以無視平台差異
@ Version: 1.0.1

@ Author:  Lebhoryi@gmail.com
@ Date:    2020/3/26 下午4:41
'''
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os
import glob
import shutil
from pathlib import Path
from pydub import AudioSegment


def detect_leading_silence(sound, silence_threshold=-35.0, chunk_size=20):
    '''
    sound is a pydub.AudioSegment
    silence_threshold in dB
    chunk_size in ms

    iterate over chunks until you find the first one with sound
    '''
    trim_ms = 0 # ms

    assert chunk_size > 0 # to avoid infinite loop

    # for i in range(1 , len(sound)+1, chunk_size):
    #     print(sound[i:i+chunk_size].dBFS)
    while sound[trim_ms:trim_ms+chunk_size].dBFS < silence_threshold and trim_ms < len(sound):
        trim_ms += chunk_size

    return trim_ms


def remove_aug_silence2(dir_path):
    if not os.path.exists(dir_path):
        raise Exception("No " + dir_path + "!")

    # x, y, z, w = 0, 0, 0, 0  # 統計超過1s語音的個數
    x = 1

    # 新的剪輯之後，1s長度的語音存放的文件夾
    new_path = os.path.join(dir_path, "1s")
    if not os.path.isdir(new_path):
        os.mkdir(new_path)

    # 長度超過一秒需要手動剪輯的語音存放路徑
    long_path = os.path.join(dir_path, "long")
    if not os.path.isdir(long_path):
        os.mkdir(long_path)

    # 獲取所有的.wav 文件路徑列表
    # 格式['0.wav', '1.wav', ...]
    wav_files = glob.glob(os.path.join(dir_path, "*.wav"))
    for i in range(len(wav_files)):
        # 讀取文件
        sound = AudioSegment.from_file(wav_files[i], format="wav")

        # 減去了兩個數值是為了增加前後的靜音區
        start_trim = detect_leading_silence(sound, -40)
        # start_trim 不能為負，否則會生成空白的語音
        start_trim = start_trim - 50 if start_trim >= 50 else start_trim
        end_trim = detect_leading_silence(sound.reverse(), -40)
        end_trim = end_trim - 100 if end_trim >= 100 else end_trim

        # durtion 單位 ms 1s=1000ms
        duration = len(sound) - end_trim - start_trim

        # 儲存的wav文件名字
        # file_name = os.path.basename(wav_files[i])
        if int(x) < 10:
            x = "00" + str(x)
        elif int(x) < 100:
            x = "0" + str(x)
        else:
            x = str(x)
        file_name = "001" + x + ".wav"
        x = int(x) + 1
        # 如果剪了  頭尾靜音區之後的語音時長小於1s,時長限定為1s
        if duration <= 1000:
            new_sound = sound[start_trim: start_trim+1000]
            new_sound.export(os.path.join(new_path, file_name), format="wav")
        elif duration <= 1050:
            start_trim2 = start_trim - 25 if start_trim >= 25 else start_trim
            new_sound2 = sound[start_trim2: start_trim2+1000]
            new_sound2.export(os.path.join(new_path, file_name), format="wav")
        else:    # 大於1s的, 需要手動剪輯
            newsound = sound[start_trim: len(sound)-end_trim]
            newsound.export(os.path.join(long_path, file_name), format="wav")
            print("{} 的時長為： {}s...".format(file_name, duration/1000))
        # print("正在剪輯第{}條語音...".format(i))
    # print("有{}條語音小於1050ms...".format(x))  # 20
    # print("有{}條語音小於1100ms...".format(y))  # 23
    # print("有{}條語音小於1150ms...".format(z))  # 9
    # print("有{}條語音大於1150ms...".format(w))  # 25

def remove_wav(wav, wav_1s, wav_long):
    """ 單個音頻剪掉靜音區 """
    assert wav, print("No audio file exists!")

    if not wav_1s.exists():  wav_1s.mkdir()

    # 讀取文件
    sound = AudioSegment.from_file(wav, format="wav")

    # 減去了兩個數值是為了增加前後的靜音區 -35
    start_trim = detect_leading_silence(sound, -30)
    # start_trim 不能為負，否則會生成空白的語音
    start_trim = start_trim - 50 if start_trim >= 50 else start_trim
    end_trim = detect_leading_silence(sound.reverse(), -30)
    end_trim = end_trim - 100 if end_trim >= 100 else end_trim

    # durtion 單位 ms 1s=1000ms
    duration = len(sound) - end_trim - start_trim

    # 如果剪了頭尾靜音區之後的語音時長小於1s,時長限定為1s
    start_trim2 = len(sound) - end_trim - 1000
    if start_trim2 < 0:
        start_trim2 = 0
    if start_trim > 400:
        start_trim2 = start_trim

    if duration <= 1050:
        new_sound = sound[start_trim2: start_trim2+1000]
        new_sound.export(wav_1s/wav.name, format="wav")
        print(f"{wav.name} 1s 音頻剪輯成功...")
    # elif duration <= 1050:
    #     start_trim2 = start_trim - 25 if start_trim >= 25 else start_trim
    #     new_sound2 = sound[start_trim2: start_trim2+1000]
    #     new_sound2.export(wav_1s/wav.name, format="wav")
    #     print(f"{wav.name} 1s 音頻剪輯成功...")
    else:    # 大於1s的, 需要手動剪輯
        newsound = sound[start_trim: len(sound)-end_trim]
        # newsound = sound[start_trim: start_trim+1000]
        newsound.export(wav_long/wav.name, format="wav")
        print("{} 的時長為： {}s...".format(wav.name, duration/1000))


def remove_aug_silence(dir_path):

    assert dir_path.exists(), Exception("No " + str(dir_path) + "!")

    # 新的剪輯之後，1s長度的語音存放的文件夾
    new_path = dir_path / "1s"
    if not new_path.exists():  new_path.mkdir()

    # 長度超過一秒需要手動剪輯的語音存放路徑
    long_path = dir_path / "long"
    if not long_path.exists(): long_path.mkdir()

    # 獲取所有的.wav 文件路徑列表
    wav_files = dir_path.glob('*.wav')
    for wav in wav_files:
        remove_wav(wav, new_path, long_path)
    print("剪輯完成, 剩下的需要手工剪輯啦...")


def merge_wavs(root, new_path):
    """ 將所有的音頻整合到一個文件夾中 """
    assert root.exists(), Exception("No files path exists!")
    i = 0

    if not new_path.exists():  new_path.mkdir()

    for dir in root.iterdir():
        print(dir)
        wav_paths = dir.glob('*.wav')
        for wav in wav_paths:
            i += 1
            shutil.copy(wav, new_path / (str(i)+'.wav'))
        print(i)
    print(f"共有{len(list(new_path.iterdir()))}條音頻文件...")
    return new_path


if __name__ == "__main__":
    root_path = "../../local_data/web_data_train/20200722/long"
    root_path = Path(root_path)
    wavs_path = root_path.parent / 'aug_xrxr'

    remove_aug_silence(root_path)

    # 合併所有音頻文件
    # wavs_path = merge_wavs(root_path, wavs_path)

    # 單個音頻
    # file_path = '/home/lebhoryi/RT-Thread/WakeUp-Xiaorui/local_data/' \
    #             '328_data/audio2/60.wav'
    # tmp = Path('/home/lebhoryi/RT-Thread/WakeUp-Xiaorui/local_data/'
    #            '328_data/tmp')
    # file_path = Path(file_path)
    # remove_wav(file_path, tmp, tmp)


