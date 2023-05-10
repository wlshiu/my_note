# coding=utf-8
'''
@ Summary: 使用libarosa 獲取音頻的mfcc
@ Html:  https://zhuanlan.zhihu.com/p/94439062

@ file:    librosa_mfcc.py
@ version: 1.0.0

@ Author:  Lebhoryi@gmail.com
@ Date:    2020/5/7 下午3:15
'''

import os
import librosa
import scipy
import numpy as np


wav_path = "../../data/nihaoxr/2.wav"
n_fft, hop_length, n_mfcc = 640, 640, 10
win_length = 640

##### 1.源語音信號， shape = wav.length
wav, sr = librosa.load(wav_path, sr=16000)


##### 2.填充及分幀(無預加重處理)，分幀後所有幀的shape = n_ftt * n_frames

# 默認，n_fft 為傅裡葉變換維度
y = np.pad(wav, (0, 0), mode='constant')
# hop_length為幀移，librosa中默認取窗長的四分之一
y_frames = librosa.util.frame(y, frame_length=n_fft, hop_length=hop_length)


##### 3.對所有幀進行加窗，shape = n_frames * n_ftt
# shape = n_ftt * n_frames。librosa中window.shape = n_ftt * 1

# 窗長一般等於傅裡葉變換維度，短則填充長則截斷
fft_window = librosa.filters.get_window('hann', win_length, fftbins=True)
# 不能直接相乘，需要轉換一下維度
fft_window = fft_window.reshape((win_length, 1))

# 原信號乘以漢寧窗函數
# y_frames *= 0.5 - 0.5 * np.cos((2 * np.pi * n) / (win_length - 1))
y_frames *= fft_window

####### 4.STFT處理得到spectrum(頻譜，實際是多幀的)
# shape = n_frames * (n_ftt // 2 +1)
fft = librosa.core.fft.get_fftlib()
stft_matrix = fft.rfft(y_frames, n=1024, axis=0)


####### 5.取絕對值得到magnitude spectrum/spectrogram(聲譜，包含時間維度，即多幀)
# shape = (n_ftt // 2 +1) * n_frames
magnitude_spectrum = np.abs(stft_matrix)    # 承接上一步的STFT


####### 6.取平方得到power spectrum/spectrogram(聲譜，包含時間維度，即多幀)
# shape = (n_ftt // 2 +1) * n_frames
power_spectrum = np.square(magnitude_spectrum)



####### 7.構造梅爾濾波器組，shape = n_mels * (n_ftt // 2 +1)
mel_basis = librosa.filters.mel(sr, n_fft=1024, n_mels=40, fmin=20., fmax=4000,
                    htk=True, norm=None, dtype=np.float32)


####### 8.矩陣乘法得到mel_spectrogram，shape = n_mels * n_frames
# [ n_mels ，(n_ftt // 2 +1) ] * [ (n_ftt // 2 +1) ，n_frames ] =
# [ n_mels，n_frames]
power_spectrum = np.sqrt(power_spectrum)
mel_spectrogram = np.dot(mel_basis, power_spectrum)


####### 9.對mel_spectrogram進行log變換，shape = n_mels * n_frames
log_mel_spectrogram = librosa.core.spectrum.power_to_db(mel_spectrogram,
                    ref=1.0, amin=1e-12, top_db=40.0)


####### 10.IFFT變換，實際採用DCT得到MFCC，shape = n_mels * n_frames
# n表示計算維度，需與log_mel_spectrogram.shape[axis]相同, 否則作填充或者截斷處理。
# axis=0表示沿著自上而下的方向，分別選取每一行所在同一列的元素進行運算。
mfcc = scipy.fftpack.dct(log_mel_spectrogram, type=2,
            n=None, axis=0, norm=None, overwrite_x=False)


####### 11.取MFCC矩陣的低維(低頻)部分，shape = n_mfcc * n_frames
# 取低頻維度上的部分值輸出，語音能量大多集中在低頻域，數值一般取13
mfcc = mfcc[:10]


# print(mfcc.dtype)
# print(np.array(mfcc, dtype=np.int32))
print("{} 的mfcc 為：\n{}".format(os.path.basename(wav_path), mfcc[0]))
