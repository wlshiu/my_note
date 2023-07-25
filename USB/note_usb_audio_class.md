UAC (USB Audio Class) [[Back](note_usb_device.md#UAC)]
---

`UAC`(USB Audio Class) 有時也叫 `UAD`(USB Audio Device)
> UAC 目前的發展已經經歷了 `1.0`, `2.0`(Win10 目前只支援到 UAC2.0) 到現在的 `3.0`.

通過 UAC 可以實現即時獲取音訊裝置的音訊資料(Isochronous Transfers), 並且也可藉 UAC 實現操控裝置的 `Volume`, `Sample Rate`, 等參數.
> 從使用功能來說, 主要包括 USB 麥克風, USB 音效卡和其它音訊裝置的功能控制和介面標準

![USB_UAC_Arch](USB_UAC_Arch.jpg)

UAC 定義在 Interface layer, 而 UAC 又分為不同的 SubClass, 以便於進一步的細節 enumeration 和設定.
所有 USB 音訊的功能, 都被包括在 UAC 的 SubClass 中
> USB 定義了 3 種不同的 Audio SubClass
> + AudioControl Interface Subclass (音訊控制介面子類, AC Interface Subclass)
>> 控制特定 Audio 的功能行為, Host 可以操縱 Clock 實體, 單元以及音訊功能內部的終端
> + AudioStreaming Interface Subclass (音訊流介面子類, AS Interface Subclass)
>> 傳輸 Audio streaming 資料. 一個 UAC 裝置可以有多個 Audio Stream 介面, 每個 Audio Stream 介面可以傳輸不同的音訊資料格式
> + MIDIStreaming Interface Subclass (MIDI流介面子類)

UAC 使用 Isochronous Transfers, 有錯誤檢測機制, 但不會重傳(發生錯誤時, 無法通知 Host)
> + Isochronous Transfers 為低延遲 (沒有 Handshaking 過程)
> + Audio/Video 對 real-time 要求較高 (否則會造成 AV 不同步), 重傳會打亂 AV 同步

> Host 處理 Endpoint 的順序是不可知的, 因此當 Device 發生錯誤時, 無法保證可以及時回傳給 Host

## Throughput of UAC

目前 UAC 1.0 spec 規定每隔 1ms 可以傳送一筆資料, High-Speed 下單筆資料是 `1024-Bytes/ms`, 因此最大為 (1024 * 8 * 1000) bits/sec
理論上 UAC1.0 可支援 `2-Ch * 32-bits * 96000 Hz = 6144000 bit/sec` 或者` 768-Bytes/ms` 這也符合 1024-Bytes 的限制

UAC2.0 spec 是可以每隔 125us 傳送一筆資料, High-Speed 下標準為單筆資料是 1024-Bytes/125us, 因此最大為(1024 * 8 * 8 * 1000) bits/sec
最大情況: 單次可以傳送 3 筆資料, 所以為(1024 * 8 * 8 * 1000 * 3) bits/sec

# Reference

+ [UAC介紹及實現](https://blog.csdn.net/xyzahaha/article/details/123813609)
