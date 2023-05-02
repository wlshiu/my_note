#!/usr/bin/env python

#
# Voice Activity Detection
#

import numpy as np
import wave
import os
import matplotlib.pyplot as plt

def read(data_path):
    '''讀取語音訊號
    '''
    wavepath = data_path
    f = wave.open(wavepath,'rb')
    params = f.getparams()
    nchannels,sampwidth,framerate,nframes = params[:4] #聲道數、量化位數、採樣頻率、採樣點數
    str_data = f.readframes(nframes) #讀取音訊, 字串格式
    f.close()
    wave_data = np.frombuffer(str_data, dtype='int16')
    wave_data = wave_data * 1.0 / (max(abs(wave_data))) #wave幅值歸一化
    time = np.arange(0, nframes) * (1.0 / framerate)
    # 最後通過採樣點數和取樣頻率計算出每個取樣的時間
    return wave_data,nframes,framerate,time

def plot(data,time):#波形圖
    plt.figure(figsize=(10,4))
    plt.plot(time, data,c="b")
    plt.xlabel('time (seconds)')
    plt.ylabel('Amplitude')
    plt.grid('on')
    # plt.show()

def enframe(data,wlen,inc):
    '''對語音資料進行分幀處理
    '''
    signal_length=len(wave_data) #訊號總長度
    if signal_length<=wlen: #若訊號長度小於一個幀的長度, 則幀數定義為1
        nf=1
    else: #否則, 計算幀的總個數
        nf=int(np.ceil((1.0*signal_length-wlen+inc)/inc))
    print("total frames："+str(nf))
    pad_length=int((nf-1)*inc+wlen) #所有幀加起來總的鋪平後的長度
    zeros=np.zeros((pad_length-signal_length,)) #不夠的長度使用0填補, 類似於FFT中的擴充陣列操作
    pad_signal=np.concatenate((wave_data,zeros)) #填補後的訊號記為pad_signal
    indices=np.tile(np.arange(0,wlen),(nf,1))+np.tile(np.arange(0,nf*inc,inc),(wlen,1)).T
    # 相當於對所有幀的時間點進行抽取, 得到nf*wlen長度的矩陣
    # print(indices[:2])
    indices=np.array(indices,dtype=np.int32) #將indices轉化為矩陣
    frames=pad_signal[indices] #得到幀訊號
    # win = np.tile(np.hamming(wlen), (nf, 1))#加窗
    win=np.hamming(wlen)#加窗
    frames1=frames*win
    return frames1,nf

# 計算每一幀的能量
def calEnergy(nf,frames1) :
    energy =np.zeros(nf)# 語音短時能量列表
    for i in range(0,nf) :#計算每一幀的資料和
        a=frames1[i:i+1]
        b=np.square(a)
        energy[i]=np.sum(b)
    return energy

# 利用短時能量, 使用雙門限法進行端點檢測
def endPointDetect(wave_data, energy) :
    sum = 0
    energyAverage = 0
    for en in energy :
        sum = sum + en
    energyAverage = sum / len(energy)   # 求全部幀的短時能量均值

    sum = 0
    for en in energy[:5] :
        sum = sum + en
    ML = sum / 5
    MH = energyAverage / 4    # 能量均值的4分之一作為能量高閾值
    ML = (ML + MH) / 5   # 前5幀能量均值+能量高閾值的5分之一作為能量低閾值
    print(MH)
    print(ML)

    silence = 0    #靜音段
    transition = 1 #過渡段
    speech = 2     #語音段
    max_transition_frame_length = 3 #最大過渡幀長度
    min_speech_frame_length = 2 #最小語音幀長度

    state = silence
    speech_counter = 0
    transition_counter = 0

    B = [];
    E = [];

    k_speech = 0  #語音段序號

    for k in range(len(energy)):
        if state == silence or state == transition: # 從靜音、過渡來的
            if energy[k] > MH :# 當前已經進入語音段的閾值
                state = speech
                speech_counter = speech_counter + 1
                transition_counter = 0
                k_speech = k_speech + 1
                # B[k_speech] = k
                B.append(k)
            elif energy[k] > ML: # 僅在過渡段, 語音還沒有開始
                state = transition
                speech_counter = 0
                transition_counter = transition_counter + 1
            elif energy[k] < ML: # 還是靜音段
                state = silence
                speech_counter = 0
                transition_counter = 0
        elif state == speech: #從語音段來的
            # [注意] 原來寫的是>T2, 但效果不是很好. T2要求太高了.
            # 通常要比T1小, 語音才會真正結束. 觀察一下短時能量的圖就知道了.
            if energy[k] > MH:  # 比低的門限高, 就認為還在語音段.
                state = speech
                speech_counter = speech_counter + 1 # 語音段繼續計數
                transition_counter = 0
            elif energy[k] < MH:# 低於較低的T1門限, “似乎”進入靜音段.
                transition_counter = transition_counter + 1
                # 有可能是語音結束, 可能是語音間停頓, 有可能是突發噪聲. 下面驗證.
                if transition_counter < max_transition_frame_length: # 小於預定的語音中最長間隔、停頓
                    state = speech; # 就還認為是語音段 --> 起到 “延音” 的作用
                    speech_counter = speech_counter + 1
                    # 如果停頓很長了, 就可能是語音結束了. 可不可能是“突發的噪聲”呢？
                elif transition_counter > max_transition_frame_length:
                    if speech_counter < min_speech_frame_length:# 判斷是語音結束還是噪聲
                        state = silence # 噪聲
                        speech_counter = 0
                        transition_counter = 0
                        if k_speech > 0: # 剛剛如果把噪聲錯誤地當做起點了,
                            k_speech = k_speech - 1
                            B.remove(k)  # 發現是突發的噪聲, 就把剛剛記錄的起點從起點陣列中去掉
                    elif speech_counter > min_speech_frame_length:# 確實是語音, 不是噪聲
                        state = silence # 語音結束
                        speech_counter = 0
                        transition_counter = 0
                        E.append(k)

    if len(B)>len(E): # 好像, 起點總會要麼跟終點個數一樣多, 要麼多一個
        # 最後一個終點沒有找到, 就把最後一幀當做終點.
        # E[len(E)+1] = len(energy)
        E.append(len(energy))
    return B,E

if __name__ == '__main__':
    data_path = 'right.wav'
    wlen = 400  #幀長取25ms
    inc = 160   #幀移取10ms

    wave_data,nframes,framerate,time = read(data_path)

    # plot(wave_data, time)

    plt.figure(figsize=(8, 6), dpi=150)
    plt.subplot(3, 1, 1)

    plt.plot(time, wave_data, c="b")
    plt.xlabel('time (seconds)')
    plt.ylabel('Amplitude')
    plt.grid('on')
    # plt.savefig('Time_Domain_Waveform.png')

    frames1, nf=enframe(wave_data,wlen,inc)
    energy = calEnergy(nf,frames1)
    print(energy)
    time1 = np.arange(0,nf) * (inc*1.0/framerate)

    # plt.figure(figsize=(10,4))  # new a figure
    plt.subplot(3, 1, 2)

    plt.plot(time1, energy)
    plt.grid()
    plt.ylabel('short energy')
    plt.xlabel('time (seconds)')
    # plt.show()
    # plt.savefig('Short-term_Energy.png')

    B,E = endPointDetect(wave_data, energy)
    print("Start:"+str(B))
    print("End:"+str(E))

    #只用紅線畫出語音端點
    C = []
    D = []
    POINT = []
    for i in range(1,len(B)):
        if 0 < (B[i]-E[i-1]) < 6:
            C.append(B[i])
    print("\nRemove data set"+str(C))
    D = B+E
    print("Start and End set"+str(D))
    POINT = np.setdiff1d(D, C)
    print("The finial End-Pointer detection set: "+str(POINT))

    # plt.figure(figsize=(10,4))
    plt.subplot(3, 1, 3)

    plt.plot(time, wave_data)
    plt.grid()
    for k in range(len(POINT)):#畫出起止點位置
        nx1=POINT[k]
        time_nx1=nx1*(inc*1.0/framerate)
        plt.vlines(time_nx1, -1, 1,color="r",linestyles="--")#豎線

    plt.tight_layout()
    plt.show()
    # plt.savefig('End-Pointer_Detection.png')
