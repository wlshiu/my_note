# coding=utf-8
'''
@ Summary: 僅在tensorlfow2 下面運行
           tf1.14 兩行代碼實現mfcc提取，現用tf2 分佈實現 提取mfcc
@ Update:  tf2 官網例程 梅爾濾波計算過程中少了一步對spectrograms 的根號


@ file:    tf2_mfccs.py
@ version: 1.0.0

@ Author:  Lebhoryi@gmail.com
@ Date:    2020/5/9 下午5:22
'''
import tensorflow as tf
import numpy as np
from tensorflow.python.ops import io_ops
from tensorflow import audio


def load_wav(wav_path, sample_rate=16000):
    '''
        load one wav file

    Args:
        wav_path: the wav file path, str
        sample_rate: wav's sample rate, int8

    Returns:
        wav: wav文件信息, 有經過歸一化操作, float32
        rate: wav's sample rate, int8

    '''
    wav_loader = io_ops.read_file(wav_path)
    (wav, rate) = audio.decode_wav(wav_loader,
                                   desired_channels=1,
                                   desired_samples=sample_rate)
    # shape (16000,)
    wav = np.array(wav).flatten()
    return wav, rate


def stft(wav, win_length=640, win_step=640, n_fft=1024):
    '''
        stft 快速傅裡葉變換

    Args:
        wav: *.wav的文件信息, float32, shape (16000,)
        win_length: 每一幀窗口的樣本點數, int8
        win_step: 幀移的樣本點數, int8
        n_fft: fft 係數, int8

    Returns:
        spectrograms: 快速傅裡葉變換計算之後的語譜圖
                shape: (1 + (wav-win_length)/win_step, n_fft//2 + 1)
        num_spectrogram_bins: spectrograms[-1], int8

    '''
    # if fft_length not given
    # fft_length = 2**N for integer N such that 2**N >= frame_length.
    # shape (25, 513)
    stfts = tf.signal.stft(wav, frame_length=win_length,
                           frame_step=win_step, fft_length=n_fft)
    spectrograms = tf.abs(stfts)

    spectrograms = tf.square(spectrograms)


    # Warp the linear scale spectrograms into the mel-scale.
    num_spectrogram_bins = stfts.shape.as_list()[-1]  # 513
    return spectrograms, num_spectrogram_bins


def build_mel(spectrograms, num_mel_bins, num_spectrogram_bins,
              sample_rate, lower_edge_hertz, upper_edge_hertz):
    '''
        構建梅爾濾波器

    Args:
        spectrograms: 語譜圖 (1 + (wav-win_length)/win_step, n_fft//2 + 1)
        num_mel_bins: How many bands in the resulting mel spectrum.
        num_spectrogram_bins：
            An integer `Tensor`. How many bins there are in the
            source spectrogram data, which is understood to be `fft_size // 2 + 1`,
            i.e. the spectrogram only contains the nonredundant FFT bins.
            sample_rate: An integer or float `Tensor`. Samples per second of the input
            signal used to create the spectrogram. Used to figure out the frequencies
            corresponding to each spectrogram bin, which dictates how they are mapped
            into the mel scale.
        sample_rate: 採樣率
        lower_edge_hertz:
            Python float. Lower bound on the frequencies to be
            included in the mel spectrum. This corresponds to the lower edge of the
            lowest triangular band.
        upper_edge_hertz:梅爾濾波器的最高頻率，梅爾濾波器的最高頻率



    Returns:
        mel_spectrograms: 梅爾濾波器與語譜圖做矩陣相乘之後的語譜圖
                shape: (1 + (wav-win_length)/win_step, n_mels)

    '''
    linear_to_mel_weight_matrix = tf.signal.linear_to_mel_weight_matrix(
        num_mel_bins=num_mel_bins,
        num_spectrogram_bins=num_spectrogram_bins,
        sample_rate=sample_rate,
        lower_edge_hertz=lower_edge_hertz,
        upper_edge_hertz=upper_edge_hertz)
    # tf.print('linear_to_mel_weight_matrix : {}'.format(
    #     tf.transpose(linear_to_mel_weight_matrix, [1,0])[0]))

    tf.print(spectrograms.shape)
    tf.print(linear_to_mel_weight_matrix.shape)

    ################ 官網教程中, 少了sqrt #############
    spectrograms = tf.sqrt(spectrograms)
    mel_spectrograms = tf.tensordot(spectrograms,
                        linear_to_mel_weight_matrix, 1)

    # 兩條等價
    # mel_spectrograms = tf.matmul(spectrograms, linear_to_mel_weight_matrix)

    # shape (25, 40)
    mel_spectrograms.set_shape(spectrograms.shape[:-1].concatenate(
        linear_to_mel_weight_matrix.shape[-1:]))

    return mel_spectrograms


def log(mel_spectrograms):
    # Compute a stabilized log to get log-magnitude mel-scale spectrograms.
    # shape: (1 + (wav-win_length)/win_step, n_mels)
    log_mel_spectrograms = tf.math.log(mel_spectrograms + 1e-12)
    return log_mel_spectrograms


def dct(log_mel_spectrograms, dct_counts):
    # Compute MFCCs from log_mel_spectrograms and take the first 13.
    # shape (1 + (wav-win_length)/win_step, dct)
    mfccs = tf.signal.mfccs_from_log_mel_spectrograms(
        log_mel_spectrograms)
    # 取低頻維度上的部分值輸出，語音能量大多集中在低頻域，數值一般取13。
    mfcc = mfccs[..., :dct_counts]
    return mfcc


if __name__ == '__main__':
    path = '/home/lebhoryi/Music/0.wav'
    lower_edge_hertz, upper_edge_hertz, num_mel_bins = 20, 4000, 40
    n_fft = 1024
    win_length, win_step = 640, 640
    dct_counts = 10

    wav, rate = load_wav(path)
    # tf.print('wav : {}'.format(wav))

    spec, num_spec_bins = stft(wav, win_length=640, win_step=640, n_fft=n_fft)

    mel_spectrograms = build_mel(spec, num_mel_bins=num_mel_bins,
                                 num_spectrogram_bins=num_spec_bins,
                                 sample_rate=rate,
                                 lower_edge_hertz=lower_edge_hertz,
                                 upper_edge_hertz=upper_edge_hertz)


    log_mel_spectrograms = log(mel_spectrograms)

    mfccs = dct(log_mel_spectrograms, dct_counts)

    # mfccs_2 = mfccs * 2
    # mfccs_2 = mfccs_2.numpy()
    # mfccs_2 = mfccs_2.flatten()
    # tf.print(mfccs_2[39:45])

