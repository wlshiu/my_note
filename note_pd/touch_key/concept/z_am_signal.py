#!/usr/bin/env python

import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import hilbert

# ---- 1. 參數設定 ----
fs = 5000           # 取樣頻率 (Hz)
t = np.arange(0, 0.02, 1/fs) # 時間向量 (觀測 50 毫秒)

f_m = 100           # 訊息訊號頻率 (Hz)
f_c = 800           # 載波訊號頻率 (Hz)
Amp_carrier = 7.0   # 載波振幅
# m = 0.7             # 調變指數 (Modulation Index, 0 < m <= 1)
m = 0.8             # 調變指數 (Modulation Index, 0 < m <= 1)
'''
Modulation-Index m = sideband_amplitude / carrier_amplitude
'''


# ---- 2. 振幅調變 (AM Modulation) ----
# 原始訊息訊號 m(t)
message = np.cos(2 * np.pi * f_m * t)

# 載波訊號 c(t)
carrier = np.cos(2 * np.pi * f_c * t)

# AM 調變訊號 s(t) = Amp_carrier * [1 + m * m(t)] * cos(2 * pi * f_c * t)
modulated = Amp_carrier * (1 + m * message) * carrier

# ---- 3. 解調變 (AM Demodulation) ----
# 使用希爾伯特轉換模擬包絡線檢波 (Envelope Detection)
analytic_signal = hilbert(modulated)
amplitude_envelope = np.abs(analytic_signal)

# 減去直流分量 (DC Offset) 並還原振幅大小
demodulated = (amplitude_envelope / Amp_carrier) - 1
demodulated = demodulated / m

# ---- 4. 繪製波形圖 ----
# plt.figure(figsize=(10, 8))

# 原始訊息訊號
# plt.subplot(3, 1, 1)
# plt.plot(t * 1000, message, 'b', linewidth=1.5)
# plt.title('1. Message Signal (m(t) - 100 Hz)')
# plt.xlabel('Time (ms)')
# plt.ylabel('Amplitude')
# plt.grid(True)

# 調變後的 AM 訊號
# plt.subplot(3, 1, 2)
plt.plot(t * 1000, modulated, 'g', linewidth=1)
plt.plot(t * 1000, amplitude_envelope, 'r--', label='Envelope', linewidth=1.5)
plt.axhline(y=0, color='blue', linestyle='--', linewidth=1.2, label='Amplitude = 0') # 振幅=0 橫線
plt.title('2. AM Modulated Signal (s(t) - 800 Hz Carrier)')
plt.xlabel('Time (ms)')
plt.ylabel('Amplitude')
plt.legend(loc='upper right')
plt.grid(True)

# 解調變後的訊號
# plt.subplot(3, 1, 3)
# plt.plot(t * 1000, demodulated, 'm', linewidth=1.5)
# plt.title('3. Demodulated Signal (Recovered)')
# plt.xlabel('Time (ms)')
# plt.ylabel('Amplitude')
# plt.grid(True)

plt.tight_layout()
plt.show()
