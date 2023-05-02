#!/usr/bin/env python

#
# MFCCs程式碼實現
# https://cloud.tencent.com/developer/article/1831454
#


import numpy as np
import scipy
from scipy.fftpack import dct
from scipy.io import wavfile

# 分幀窗口長度
WIN_LEN = 255
# 採樣間隔
HOP_LEN = 125
# FFT個數
N_FFT = 255
# mel濾波器個數
N_FILT = 40
# 倒譜係數個數
NUM_CEPS = 13
# 音訊採樣率
sample_rate = 16000


def read_audio(wave_path):
    """讀取音訊
    :param wave_path:
    :return:
    """
    rate, data = wavfile.read(wave_path)
    data = np.round(32767 * data)
    return data


def pre_emphasised(data):
    """預加重
    :rtype: object
    """
    pre_emphasis = 0.96
    data = np.append(
        [data[0]],
        [(data[i + 1] - pre_emphasis * data[i]) for i in range(len(data) - 1)],
    )
    return data


def get_hann_window(length=255):
    """hanning窗"""
    window = np.hanning(length)
    window.shape = [1, -1]
    return window.astype(np.float32)


def get_frames(pcm, frame_len, hop_len):
    """分幀
    :rtype: [幀個數，幀長度]
    """
    pcm_len = len(pcm)

    frames_num = 1 + (pcm_len - frame_len) // hop_len
    frames_num = int(frames_num)
    frames = []
    for i in range(frames_num):
        s = i * hop_len
        e = s + frame_len
        if e > pcm_len:
            e = pcm_len
        frame = pcm[s:e]
        frame = np.pad(frame, (0, frame_len - len(frame)), "constant")
        frame.shape = [1, -1]
        frames.append(frame)
    frames = np.concatenate(frames, axis=0)
    return frames


def stft(frames):
    """計算短時傅立葉變換和功率譜
    Short-term FFT
    :param frames: 分幀後資料
    :return: 功率譜
    """
    # fft後的振幅
    mag_frames = np.absolute(np.fft.rfft(frames, N_FFT))
    # 功率譜
    pow_frames = (1.0 / N_FFT) * ((mag_frames) ** 2)
    print("pow_frames", pow_frames.shape)
    return pow_frames


def get_filter_bank(pow_frames):
    """提取mel刻度和各頻段對數能量值"""
    low_freq_mel = 0
    # 頻率轉換為Mel尺度
    high_freq_mel = 2595 * np.log10(1 + (sample_rate / 2) / 700)
    # 對mel線性分區
    mel_points = np.linspace(low_freq_mel, high_freq_mel, N_FILT + 2)
    # Mel尺度上point轉頻率
    hz_points = 700 * (10 ** (mel_points / 2595) - 1)
    bin = np.floor((N_FFT + 1) * hz_points / sample_rate)
    fbank = np.zeros((N_FILT, int(np.floor(N_FFT / 2 + 1))))

    for m in range(1, N_FILT + 1):
        # left
        f_m_minus = int(bin[m - 1])
        # center
        f_m = int(bin[m])
        # right
        f_m_plus = int(bin[m + 1])
        for k in range(f_m_minus, f_m):
            fbank[m - 1, k] = (k - bin[m - 1]) / (bin[m] - bin[m - 1])
        for k in range(f_m, f_m_plus):
            fbank[m - 1, k] = (bin[m + 1] - k) / (bin[m + 1] - bin[m])

    print("pow_frames,fbank", pow_frames.shape, fbank.shape)
    # [num_frame,pow_frame] dot [num_filter, num_pow]
    # 每幀對數能量值在對應濾波器頻段相乘累加
    filter_banks = np.dot(pow_frames, fbank.T)
    filter_banks = np.where(filter_banks == 0, np.finfo(float).eps, filter_banks)
    # 能量取對數
    filter_banks = 20 * np.log10(filter_banks)
    print("filter_banks", filter_banks.shape)
    return filter_banks


def get_MFCCs(filter_banks):
    """獲取最終MFCC係數
    :param filter_banks: 經過Mel濾波器的對數能量
    """
    # 對數能量帶入離散餘弦變換公式
    mfcc = dct(filter_banks, type=2, axis=1, norm="ortho")[:, 1 : (NUM_CEPS + 1)]
    (nframes, ncoeff) = mfcc.shape
    print("mfcc.shape", mfcc.shape)
    print(mfcc)


if __name__ == "__main__":
    file = "right.wav"

    # 讀取音訊
    data = read_audio(file)

    # 預加重
    data = pre_emphasised(data)

    # 獲取漢寧窗
    _han = get_hann_window()

    # 分幀
    frames = get_frames(data, WIN_LEN, HOP_LEN)

    # 加窗
    frames = frames * _han

    # 傅立葉變換+得到功率譜
    pow_frames = stft(frames)

    # mel濾波器獲取mel對數功率譜
    filter_banks = get_filter_bank(pow_frames)

    # 離散餘弦變換，獲取mel頻譜倒譜係數
    get_MFCCs(filter_banks)
