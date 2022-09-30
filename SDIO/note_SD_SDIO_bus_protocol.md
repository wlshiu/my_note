SD/SDIO Bus Protocol [[Back](note_SD_SDIO.md#SD-Bus-Protocol)]
---

SD Bus 上的通訊是基於 `Command` 和 `Data` 傳輸的, 由一個 **開始位('0')** 發起, 由一個 **停止位('1')** 終止.

SD 每次通訊操作, 都是由 Host 在 CMD-Signal 傳送一個 `Command`, Card 在接收到 `Command` 後, 在 CMD-Signal 回應 `Response`, 如果有需要, 則會有 Data 傳輸參與
> + **Command** (在 CMD-Pin 上 Serially Half-duplex xfer)
>> Command 是啟動操作的 token. Command 從 Host 傳送到單個 Card(定址命令) 或所有連接的 Card(廣播命令).
> + **Response** (在 CMD-Pin 上 Serially Half-duplex xfer)
>> Response 是一個 token, 它從一個有地址的 Card 或從所有連接的 Card 傳送到 Host, 作為對先前接收到 Command 的回應.
> + **Data** (在 DATx-Pin Half-duplex xfer)
>> Data 可以在 Card 和 Host 間雙向傳輸

## SD Transaction

SD data 是以 `Black` 形式傳輸的 (SDHC data block 長度一般為 512-bytes), data 可以從 Host 到 Card, 也可以是從 Card 到 Host.
> Data Block 需要 CRC 來保證資料傳輸成功. CRC 由 SD Card 系統 H/w 生成

### Basic Transaction

![SD_basic_communication](SD_basic_communication.jpg)

### Block Read/Write

SD data 傳輸支援 Single/Multiple block Read/Write (各自對應不同的 `Command`)
> + 當使用 Multiple block transmission 時, 需要使用 `Command` 來停止操作.
> + Data 傳輸時, 由 Host 設置使用 `1-bits` or `4-bits mode`
> + SD Card 會藉由 **拉低 DAT[0] Signal 來表示目前 BUSY**
> + Data 寫入前, 需要檢測 SD Card 狀態(Busy or not),
>>因為 SD Card 在接收到資料後, 寫入到儲存區的過程, 需要占用一定的時間


+ **Read**
    > 對於 Read Command, 首先 Host 會向 Card 傳送 `Command`, 緊接著 Card 會先回應一個 `Response`,
    接著 Card 開始傳送 data block 給 Host, 所有 data block 都帶有 CRC(由H/w 自動處理)
    > + Single Block Read 時, Card 發送 1 個 data block 後, 即可以停止, 不需要傳送 STOP Command (CMD12).
    > + Multiple Block Read 時, Card 會一直發送 data block 給 Host (Card 不可占用 CMD-Signal), 直到接到 Host 傳送的 STOP Command (CMD12).

    ![Block Read Operation](SD_Block_Read.jpg)

+ **Write**
    > + 對於 Write Command, 首先 Host 會向 Card 傳送命令, 緊接著 Card 會返回一個 `Response`.
    當 Host 收到 Card 的 `Response`後, 會將 data 放在 1-bit or 4-bits 的 DATx 上, 在傳送資料的同時會跟隨著 CRC(由H/w 自動處理).
    > + Card 收到 data block 後, 將 `DAT[0] Signal` 拉 low (H/w 自動處理), 表示 Card 目前處於 BUSY, 並開始執行寫入流程;
    寫入完成後, 則將 `DAT[0] Signal` 拉 high (H/w 自動處理), 表示 Card 目前處於 IDLE, Host 可以繼續傳送 data block.
    > + 當整個寫傳送完畢後, Host 會再次傳送一個命令, 通知 Card 操作完畢, Card 同時會返回一個響應.

    ![Block Write Operation](SD_Block_Write.jpg)

## Command and Response data formate


## Reference

+ [【SDIO】SD2.0協議分析總結（一）](https://www.cxyzjd.com/article/ZHONGCAI0901/113190393)
