#!/usr/bin/env python

import wave
import numpy as np
import math
import matplotlib.pyplot as plt
from scipy.fftpack import dct

def square(x) :     # 計算平方數
    return x ** 2

def read(data_path):
    '''讀取語音訊號
    '''
    wavepath = data_path
    f = wave.open(wavepath,'rb')
    params = f.getparams()
    nchannels, sampwidth, framerate, nframes = params[:4] #聲道數、量化位數、採樣頻率、採樣點數
    str_data = f.readframes(nframes) #讀取音訊，字串格式
    f.close()

    wavedata = np.frombuffer(str_data, dtype='int16')

    wavedata = wavedata * 1.0 / (max(abs(wavedata))) #wave 幅值 normalization
    return wavedata, nframes, framerate

def enframe(data, win_width, stride):
    '''對語音資料進行分幀處理
    input: data(一維array):語音訊號
           win_width(int):滑動窗長
           stride(int):窗口每次移動的長度
    output:f(二維array)每次滑動窗內的資料, 組成的二維array
    '''
    nx = len(data) #語音訊號的長度
    try:
        nwin = len(win_width)
    except Exception as err:
        nwin = 1
    if nwin == 1:
        wlen = win_width
    else:
        wlen = nwin

    nf = int(np.fix((nx - wlen) / stride) + 1) # 窗口移動的次數
    f = np.zeros((nf, wlen))                # 初始化二維陣列
    indf = [stride * j for j in range(nf)]
    indf = (np.mat(indf)).T
    inds = np.mat(range(wlen))
    indf_tile = np.tile(indf, wlen)
    inds_tile = np.tile(inds, (nf, 1))
    mix_tile = indf_tile + inds_tile
    f = np.zeros((nf, wlen))
    for i in range(nf):
        for j in range(wlen):
            f[i, j] = data[mix_tile[i, j]]
    return f

def point_check(wavedata, win_width, stride):
    '''語音訊號端點檢測(截出 Cmd 部分)
    input : wavedata(一維array)
            win_width: filter width
            stride: stride length
    output: StartPoint(int)
            EndPoint(int)
    '''

    #1.計算短時過零率
    FrameTemp1 = enframe(wavedata[0:-1], win_width, stride)
    FrameTemp2 = enframe(wavedata[1:], win_width, stride)

    signs = np.sign(np.multiply(FrameTemp1, FrameTemp2)) # 計算每一位與其相鄰的資料是否異號, 異號則過零
    signs = list(map(lambda x:[[i, 0] [i > 0] for i in x], signs))
    signs = list(map(lambda x:[[i, 1] [i < 0] for i in x], signs))
    diffs = np.sign(abs(FrameTemp1 - FrameTemp2) - 0.01)
    diffs = list(map(lambda x:[[i, 0] [i < 0] for i in x], diffs))
    zcr = list((np.multiply(signs, diffs)).sum(axis = 1))  # Zero Crossing Rate

    #2.計算短時能量
    amp = list((abs(enframe(wavedata, win_width, stride))).sum(axis = 1))

    # 設定門限
    print('\nSet Threshold\n')
    ZcrLow = max([round(np.mean(zcr)*0.1), 3])  # 過零率低門限
    ZcrHigh = max([round(max(zcr)*0.1), 5])     # 過零率高門限
    AmpLow = min([min(amp)*10, np.mean(amp)*0.2, max(amp)*0.1])  # 能量低門限
    AmpHigh = max([min(amp)*10, np.mean(amp)*0.2, max(amp)*0.1]) # 能量高門限

    # 端點檢測 (VAD)
    MaxSilence = 8  # 最長語音間隙時間
    MinAudio = 16   # 最短語音時間
    Status = 0      # 狀態0:靜音段,1:過渡段,2:語音段,3:結束段
    HoldTime = 0    # 語音持續時間
    SilenceTime = 0 # 語音間隙時間

    print('\nStart End-ponter Dection (VAD)\n')
    StartPoint = 0

    for n in range(len(zcr)):
        if Status == 0 or Status == 1:
            if amp[n] > AmpHigh or zcr[n] > ZcrHigh:
                StartPoint = n - HoldTime
                Status = 2
                HoldTime = HoldTime + 1
                SilenceTime = 0
            elif amp[n] > AmpLow or zcr[n] > ZcrLow:
                Status = 1
                HoldTime = HoldTime + 1
            else:
                Status = 0
                HoldTime = 0
        elif Status == 2:
            if amp[n] > AmpLow or zcr[n] > ZcrLow:
                HoldTime = HoldTime + 1
            else:
                SilenceTime = SilenceTime + 1
                if SilenceTime < MaxSilence:
                    HoldTime = HoldTime + 1
                elif (HoldTime - SilenceTime) < MinAudio:
                    Status = 0
                    HoldTime = 0
                    SilenceTime = 0
                else:
                    Status = 3
        elif Status == 3:
            break
        if Status == 3:
            break

    HoldTime = HoldTime - SilenceTime
    EndPoint = StartPoint + HoldTime
    return FrameTemp1[StartPoint:EndPoint]



def mel_filter(M, N, fs, l, h):
    '''mel濾波器
    input:M(int): 濾波器個數
          N(int): FFT點數
          fs(int): 採樣頻率
          l(float): 低頻係數
          h(float): 高頻係數
    output:melbank(二維array):mel濾波器
    '''
    fl = fs * l #濾波器範圍的最低頻率
    fh = fs * h #濾波器範圍的最高頻率
    bl = 1125 * np.log(1 + fl / 700) #將頻率轉換為mel頻率
    bh = 1125 * np.log(1 + fh /700)
    B = bh - bl #頻頻寬度
    y = np.linspace(0, B, M+2) #將mel刻度等間距
    print('\nmel gap\n',y)
    Fb = 700 * (np.exp(y / 1125) - 1) #將mel變為HZ

    print("\nFBank\n")
    print(Fb)
    w2 = int(N / 2 + 1)
    df = fs / N
    freq = [] #採樣頻率值
    for n in range(0, w2):
        freqs = int(n * df)
        freq.append(freqs)
    melbank = np.zeros((M, w2))
    print("\nFrequency\n")
    print(freq)

    for k in range(1, M+1):
        f1 = Fb[k - 1]
        f2 = Fb[k + 1]
        f0 = Fb[k]
        n1 = np.floor(f1/df)
        n2 = np.floor(f2/df)
        n0 = np.floor(f0/df)

        for i in range(1, w2):
            if i >= n1 and i <= n0:
                melbank[k-1, i] = (i-n1)/(n0-n1)
            if i >= n0 and i <= n2:
                melbank[k-1, i] = (n2-i)/(n2-n0)

        plt.plot(freq, melbank[k-1, :])
    plt.show()
    return melbank, w2


def mfcc(FrameK, framerate, win_width):
    '''提取mfcc參數
    input:FrameK (二維array): 二維分幀語音訊號
          framerate         : 語音採樣頻率
          win_width         : 分幀窗長(FFT點數)
    output:
    '''

    #mel濾波器
    mel_bank,w2 = mel_filter(24, win_width, framerate, 0, 0.5)
    FrameK = FrameK.T
    #計算功率譜
    # S = abs(np.fft.fft(FrameK, axis = 0)) ** 2 # '** 2' 平方數
    S = square(abs(np.fft.fft(FrameK, axis = 0)))
    #將功率譜通過濾波器
    P = np.dot(mel_bank, S[0:w2, :])
    #取對數
    logP = np.log(P)
    #計算DCT係數
#    rDCT = 12
#    cDCT = 24
#    dctcoef = []
#    for i in range(1,rDCT+1):
#        tmp = [np.cos((2*j+1)*i*math.pi*1.0/(2.0*cDCT)) for j in range(cDCT)]
#        dctcoef.append(tmp)
#    #取對數後做餘弦變換
#    D = np.dot(dctcoef,logP)
    num_ceps = 12
    D = dct(logP, type = 2, axis = 0, norm = 'ortho')[1:(num_ceps + 1), :]
    return S, mel_bank, P, logP, D


if __name__ == '__main__':
    data_path = 'right.wav'
    win_width = 256  # samples
    stride = 80      # move samples
    wavedata, nframes, sample_rate = read(data_path)
    FrameK = point_check(wavedata, win_width, stride)

    print("\n=====")
    print(FrameK)
    print("\n")

    S, mel_bank, P, logP, D = mfcc(FrameK, sample_rate, win_width)



