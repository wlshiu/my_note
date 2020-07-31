[Bluetooth SIG](https://www.bluetooth.com)
---

```
                    bt Classic          |        LE
                                        |
                    application         |     application
    APP             profiles            |      profiles
    ____________________________________|________________________________
                                        |
                +-------------------+   |    +----------+
                |  GAP              |   |    |   GATT   |
                +-------------------+   |    +----------+
                  |          |          |          |
                  |  +-------------+    |    +----------+
                  |  |  Security   |    |    |   ATT    |
                  |  |   Manager   |    |    +----------+
                  |  +-------------+    |          |
                  |    |     |          |          v
                  |    |  +-----------------------------------------------+
                  |    |  | Logical Link Control and Adaptation Protocol  |
                  |    |  |                (L2CAP)                        |
                  v    v  +-----------------------------------------------+
                +---------------------------------------------+
                |           Host Controller Interface (HCI)     |
                +-----------------------------------------------+
    Host          +-------------------------------+       ^
    ______________|     communication interface   |_______|______________
                  |   (hci_uart/hci_usb/hci_spi)  |       |
                  +-------------------------------+       v
                +-----------------------------------------------+
                |           Host Controller Interface (HCI)     |
                +-----------------------------------------------+
                +---------------+       |    +---------------+
                | link manager  |       |    |   link layer  |
                +---------------+       |    +---------------+
                +---------------+       |
                |   baseband    |       |
                |   controller  |       |
                +---------------+       |
    Controller  +---------------+       |    +---------------+
    ____________|   BR/EDR RF   |_______|____| Low Energy RF |________
                +---------------+       |    +---------------+

                        RF H/w (PHY) or Direct Test mode
```


# Bluetooth LE (Low Energy)

Bluetooth v4.2 第一次出現 LE
ps. this note is follow v4.2

## Definition

+ `Byte`
    > 表示的是 CPU 可以獨立尋址的最小內存單位
+ `octet`
    > 8 bits
+ `nibble`
    > 4 bits
+ `PDU`
    > Packet Data Unit

+ Clock Accuracy (ppm)
    > `ppm` 為和系統 clock 相對比例

    ```
    system clock = 32.768 KHz. Frequency Tolerance= 20 ppm

    Tolerance = 32.768kHz * 20/1000000 = 32.768kHz * 0.000002 = 0.065536Hz

    32.768 KHz - 0.065536Hz < Frequency < 32.768 KHz + 0.065536Hz
    ```

+ Duty Cycle
    > 表示在一個周期內, **工作時間**與**總時間**的比值
    > + `Low Duty Cycle`: long duration **sleep** state and short **active** states
    > + `High Duty Cycle`: long duration **active** state and short **sleep** states

## PHY

+ GFSK 信號調變
+ `2402 ~ 2480 MHz`
+ `40` 個 channels,
    > 每兩個 channel 間隔 `2MHz`(經典藍牙協議是 1MHz)
    >> + advertising x 3
    >> + data x 37

    ```
      |                       |                                       |
      |-----*-------------*---|------*----------------------------*---|
    37ch    |             |  38ch    |                            |  39ch
    2402MHz |             |  2426MHz |                            |  2480MHz
            |             |          |                            |
           0ch           10ch       11ch                         36ch
          2404MHz       2424MHz     2428MHz                      2478MHz

    ```

+ 數據傳輸速率是 `1Mbps`, `BT v5.0` 可達 `2Mbps`
+ Bit order
    > `The LSB is the first bit sent over the air.`

## Controller
> 完成最基本的數據發送和接收, 通常包含
> + 物理層 PHY(physicallayer)
>> 直接對接天線,為抗干擾通常會獨立一顆 chip
> + 鏈路層 LL(linker layer)
> + 直接測試模式 DTM(Direct Test mode)
> + HCI 控制器接口(和 Host 溝通)

+ link layer (LL)
    > 基於物理層PHY之上, 實現數據通道分發, 狀態切換, 數據包校驗, 加密等.
    鏈路層LL分2種通道, 廣播通道 (advertising channels) 和 數據通道 (data channels).

    - advertising channels
        > 廣播通道有 3 個, `37ch(2402MHz)`, `38ch(2426MHz)`, `39ch(2480MHz)`,
        每次廣播都會往這 **3 個通道同時發送**(並不會在這 3個通道之間跳頻),
        為防止某個 channel 被其它設備阻塞, 以至於設備無法配對或廣播數據,
        所以定 3個廣播通道是一種權衡, 少了可能會被阻塞, 多了加大功耗,
        還有一個有意思的事情是, 三個廣播通道剛好避開了 wifi 的 `1ch`, `6ch`, `11ch`,
        所以在 BLE 廣播的時候, 不至於被 wifi 影響.
        (如果要干擾 BLE 廣播數據, 最簡單的辦法, 同時阻塞 3個廣播通道)

    - data channels
        > 當 BLE 匹配之後, 鏈路層LL由廣播通道切換到數據通道,
        數據通道 37個, 數據傳輸的時候會在這 37個通道間切換, **切換規則在設備間匹配時候 (connection) 約定**.
        為了增加容量, 增大抗干擾能力, 連接不會長期使用一個固定的 Physical Channel,
        而是在多個 Channels(如37個)之間隨機但有規律的切換, 這就是BLE的跳頻(Hopping)技術.
        master 和 slave 建立連接之後, 會生成一個 channel map, 這個 channel map 就是主從商量好的調頻通道.

+ HCI (Host Controller Interface)
    > 統一 Host 跟 Controller 之間溝通的介面, 邏輯上定義一系列的 commands 跟 events
    >> 一般 Host 跟 Controller 是各自獨立, 因此需要 HCI 來增加相容性.
    為提高彈性, 也可以將 HCI 的資料經由 peripheral communication interface (uart/usb/spi)來傳輸

## Host

host 是藍牙協議棧的核心部分, GAP 層負責制定設備工作的角色, Security Manager 層負責指定安全連接,
Logic Link 層功能非常強大, 官方作用為協議/通道的多路復用,
負責上層應用數據 (L2CAP Service Data Units, SDUs)的分割和重組,
生成協議數據單元(L2CAP Packet Data Units, PDUs), 以滿足用戶數據傳輸對延時的要求,
並便於後續的重傳及 flow control 等機制的實現

+ L2CAP (Logical Link Control and Adaptation Protocol)
    > 數據經過 Link Layer 的抽象之後, 兩個 BLE 設備之間可存在兩條邏輯上的數據通道;
    一條是無連接的廣播通道, 另一條是基於連接的數據通道, 是一個點對點(Master 對 Slave)的邏輯通道.
    `BT 4.2` 最大傳輸的數據包長度為 `251字節`, 那麼應用層要傳輸的數據包長度超過了 251 個字節,
    這個時候就靠 L2CAP 層進行分包處理, 送到 LL層進行數據發送.
    Physical Layer 負責提供一系列的 Physical Channel.
    基於這些 Physical Channel, Link Layer 可在兩個設備之間建立, 用於點對點通信的 Logical Channel.
    而 L2CAP 則將這個 Logical Channel 換分為一個個的 L2CAP Channel, 以便提供應用程式級別的通道復用.
    到此之後, 基本協議棧已經構建完畢, 應用程式已經可以基於 L2CAP 跑起來了

+ ATT (Attribute Protocol)
    > Attribute Protocol 定義了一套數據傳輸機制, 採用 Client-Server 的形式, 為數據傳輸提供一個通道.
    提供信息(以後都稱作 Attribute)的一方稱作 `ATT Server`(一般是那些傳感器節點), 訪問信息的一方稱作 `ATT Client`.
    一個Attribute由Attribute Type、Attribute Handle和Attribute Value組成.
    ATT 層相當於數據傳輸通道, 所有的數據都會通過該通道上傳或者下發.

+ GATT (Generic Attribute Profile)
    > Attribute Protocol 之所以稱作'protocol', 是因為它還比較抽象,
    僅僅定義了一套機制, 允許 client 和 server 通過 Attribute 的形式共享信息.
    而具體共享哪些信息, ATT 並不關心, 這是 GATT(Generic Attribute Profile)的主場.
    GATT 相對 ATT 只多了一個'G', 但含義卻大不同,
    因為 GATT 是一個 profile, 定義了在不同情境下, 其具體共享的資訊

+ GAP (Generic AccessProfile)
    > 定義 GAP層的藍牙設備角色(role)
    > + Broadcaster Role, 設備正在發送 advertising events
    > + Observer Role, 設備正在接收 advertising events
    > + Peripheral Role, 設備接受 Link Layer 連接(對應 Link Layer 的 slave 角色)
    > + Central Role, 設備發起 Link Layer 連接(對應 Link Layer 的 master 角色)

    > GAP 層定義了用於實現各種通信的操作模式(Operational Mode)和過程(Procedures),
    實現單向的, 無連接的通信方式, 配對, 連接操作等.
    同時 GAP 層也定義了 User Interface 相關的藍牙參數, 比如藍牙地址, 名稱, 類型等.

+ SM (Security Manager)
    > Security Manager 負責 BLE 通信中有關安全的內容,
    包括配對(pairing), 認證(authentication)和加密(encryption)等過程

## Roles switch on Link Layer

在 Standby 狀態, 雙方設備都處於未連接狀態,
Advertiser 嘗試廣播數據, Scanner 接收到廣播數據後嘗試進行掃描請求, 並且得到掃描回復.
此時 Scanner 產生連接意圖, 轉變成 Initiator 發送連接請求(為了建立連線),
成功連接後(Connection State)發送廣播的 Advertiser 作為 Slave,
進行連接請求的 Initiator 成為 Master

```
            standby (Standby State)
                |       |
        +-------+       +------+
        |                      |
        |                      |
    Advertiser              Scanner
    (Advertising            (Scanning
       State)                 State)
        |                      |
        | advertising packets  |
        |--------------------->|
        |                      v
        |                   Initiator (Initiating State)
        |                      |
    ____|______________________|____________
        |                      |        Connection State
        v                      v
      Slave                  Master
     (Server)               (Client)
```

+ master role
    > 有絕對的權力, 來決定所有的 configurations
    >> 需要分配 timings (time slots) of transmissions

+ slave role
    > 只能建議 (notification), master 沒發訊息, slave 就只能等
    >> master 需要發 `empty packet` (只有 header 沒有 data), 來讓 slave 回傳資料

+ Client role
    > 發出 REQ(request)

+ Server role
    > 發出 RSP(response) 來回應 request


## Packet Format at Link Layer

Advertising channel packets and data channel packets use the same packet format.
ps. LSB 會先傳出到 Air

```
LSB                                                                   MSB
+-------------+------------------+-----------------------+-------------+
| Preamble    | Access Address   | Packet Data Unit, PDU |     CRC     |
| (1 octet)   |   (4 octets)     |  (2 to 257 octets)    | (3 octets)  |
+-------------+------------------+-----------------------+-------------+

* The shortest packet length is 80 bits
    8 * (1 + 4 + 2 + 3)
* The longest packet length is 2120 bits
    8 * (1 + 4 + 257 + 3)
```

+ Preamble
    > The preamble is used in the receiver to perform frequency synchronization,
    symbol timing estimation, and Automatic Gain Control (AGC) training.

    ```
    if (Access Address) & 0x1
        preamble = 01010101b
    else
        preamble = 10101010b
    ```

+ Access Address
    > A specific random `32-bit` value.
    一個 connection 的 UID, 用來識別是哪一個連線.
    在建立連線時, 由 initiator 來產生.
    (有特殊條件產生, 詳見 Access Address of spec)

    - Access Address of advertising packet
        > fix at `0x8E89BED6` (broadcast)

### PDU

+ Advertising channel
    > 在 Advertising state 時, 同一個 Advertising packet 會照 Advertising channel 的順序發送
    `37Ch -> 38Ch -> 39Ch`

    ```
    LSB                               MSB
    +------------+---------------------+
    |   header   |       Payload       |
    | (16 bits)  |  (length in header) |
    +------------+---------------------+

    header
    LSB                                                             MSB
    +-----------+----------+---------+---------+----------+---------+
    | PDU Type  |    RFU   |  TxAdd  |  RxAdd  |  Length  |  RFU    |
    | (4 bits)  | (2 bits) | (1 bit) | (1 bit) | (6 bits) |(2 bits) |
    +-----------+----------+---------+---------+----------+---------+

    * RFU is reserved for future use.
    ```

    - PDU Type

        1. ADV_IND (0000b)
            > connectable undirected advertising event,
            用於常規的廣播, 可攜帶不超過 31-bytes 的廣播數據,
            可被連接(rx SCAN_REQ), 可被掃瞄(rx CONNECT_REQ)

            ```
            PDU格式
            AdvA(6 octets) + AdvData(0~31 octets)

            * AdvA   : 6bytes的廣播者地址, 並由 PDU Header 的 TxAdd bit決定地址的類型(0 public, 1 random)
            * AdvData: 廣播數據
            ```

        1. ADV_DIRECT_IND (0001b)
            > connectable directed advertising event,
            專門用於點對點連接, 且已經知道雙方的藍牙地址,
            不可攜帶廣播數據, 可被指定的設備連接(rx CONNECT_REQ), 不可被掃瞄

            ```
            PDU格式
            AdvA(6 octets) + InitA(6 octets)

            * AdvA : 6-bytes的廣播者地址, 並由 PDU Header 的 TxAdd bit 決定地址的類型(0 public, 1 random)
            * InitA: 6-bytes的接收者(也是連接發起者)地址, 並由 PDU Header 的 RxAdd bit 決定地址的類型(0 public, 1 random)
            ```

        1. ADV_NONCONN_IND (0010b)
            > 和 ADV_IND 類似,
            但不可以被連接, 不可以被掃瞄

            ```
            PDU格式
            AdvA(6 octets) + AdvData(0~31 octets)
            ```

        1. SCAN_REQ (0011b)
            > 當接收到 ADV_IND 或者 ADV_SCAN_IND 類型的廣播數據的時候,
            可以通過該 PDU, 請求廣播者廣播更多的信息

            ```
            PDU格式
            ScanA(6 octets) + AdvA(6 octets)

            * ScanA: 6-bytes的本機地址, 並由 PDU Header 的 TxAdd  決定地址的類型(0 public, 1 random)
            * AdvA : 6-bytes的廣播者地址, 並由 PDU Header 的 RxAdd 決定地址的類型(0 public, 1 random)
            ```

        1. SCAN_RSP (0100b)
            > 廣播者收到 SCAN_REQ 請求後,
            通過 SCAN_RSP 響應, 把更多的數據傳送給接受者

            ```
            PDU格式
            AdvA(6 octets) + ScanRspData(0~31 octets)

            * AdvA       : 6-bytes的本機地址, 並由 PDU Header 的 TxAdd  決定地址的類型(0 public, 1 random)
            * ScanRspData: scan 的應答數據
            ```

        1. CONNECT_REQ (0101b)
            > 當接收到 ADV_IND 或者 ADV_DIRECT_IND 類型的廣播數據的時候,
            可以通過 CONNECT_REQ, 請求和對方建立連接

            ```
            PDU格式
            InitA (6 octets) + AdvA (6 octets) + LLData (22 octets)

            * InitA : 6-bytes的本機地址, 並由 PDU Header 的 TxAdd 決定地址的類型(0 public, 1 random)
            * AdvA  : 6-bytes的廣播者地址, 並由 PDU Header 的 RxAdd 決定地址的類型(0 public, 1 random)
            * LLData: BLE 連接有關的參數信息
            ```

        1. ADV_SCAN_IND (0110b)
            > 和 ADV_IND 類似,
            但不可以被連接, 可以被掃瞄(rx SCAN_REQ)

            ```
            PDU格式
            AdvA(6 octets) + AdvData(0~31 octets)
            ```

    - CONNECT_REQ
        > Initiator send to Advertiser.
        >> LLData descripts the rule of transmission

        ```
        Payload = InitA (6 octets) + AdvA (6 octets) + LLData (22 octets)

        unit: octets
        +------+----------+---------+-----------+----------+---------+---------+-----+----------+----------+
        |  AA  | CRCInit  | WinSize | WinOffset | Interval | Latency | Timeout | ChM | Hop      | SCA      |
        | (4 ) |  (3)     |  (1)    | (2)       | (2)      | (2)     | (2)     | (5) | (5 bits) | (3 bits) |
        +------+----------+---------+-----------+----------+---------+---------+-----+----------+----------+
        ```

        1. `AA (Access Address)`
        1. `CRCInit` is initialization value for the CRC
        1. `WinSize` is the transmitWindowSize value

            ```
            transmitWindowSize = WinSize * 1.25 ms
            ```

        1. `WinOffset` is the transmitWindowOffset value

            ```
            transmitWindowOffset = WinOffset * 1.25 ms
            ```

        1. `Interval` is the connInterval value

            ```
            connInterval = Interval * 1.25 ms
            ```
        1. `Latency` is the connSlaveLatency value

            ```
            connSlaveLatency = Latency
            ```

        1. `Timeout` is the connSupervisionTimeout value

            ```
            connSupervisionTimeout = Timeout * 10 ms
            ```

        1. `ChM` contains the channel bit map indicating `Used` and `Unused` data channels.
        1. `Hop` is the the hopIncrement
            > used in the data channel selection algorithm.
            It shall have a **random value** in the range of **5 to 16**.

        1. `SCA` is the masterSCA
            > determine the worst case Master's sleep clock accuracy

    - 使用情境
        1. 如果只需要定時傳輸一些簡單的數據(如某一個溫度節點的溫度信息),
        後續不需要建立連接, 則可以使用 `ADV_NONCONN_IND`.
        廣播者只需要週期性的廣播該類型的 PDU 即可, 接收者按照自己的策略掃瞄/接收,
        二者不需要任何額外的數據交互.

        1. 如果除了廣播數據之外, 還有一些額外的數據需要傳輸,
        由於種種原因, 如廣播數據的長度限制, 私密要求等, 可以使用`ADV_SCAN_IND`.
        廣播者在週期性廣播的同時, 會監聽 `SCAN_REQ`請求.
        接收者在接收到廣播數據之後, 可以通過 `SCAN_REQ PDU`, 請求更多的數據.

        1. 如果後續需要建立點對點的連接, 則可使用 `ADV_IND`.
        廣播者在週期性廣播的同時, 會監聽 `CONNECT_REQ` 請求.
        接收者在接收到廣播數據之後, 可以通過 `CONNECT_REQ PDU`, 請求建立連接.

        1. 通過 `ADV_IND/CONNECT_REQ`的組合建立連接, 花費的時間比較長.
        如果雙方不關心廣播數據, 而只是想快速建立連接,
        恰好如果連接發起者又知道對方(廣播者)的藍牙地址(如通過掃碼的方式獲取),
        則可以通過 `ADV_DIRECT_IND/CONNECT_REQ`的方式


+ Data channel

    ```
    LSB                                             MSB
    +------------+---------------------+ +-----------+
    |   header   |       Payload       | |    MIC    |
    | (16 bits)  |  (length in header) | | (32 bits) |
    +------------+---------------------+ +-----------+
                                           (optional)

    header
    LSB                                                             MSB
    +-----------+----------+---------+---------+----------+---------+
    | LLID      |   NESN   |  SN     |  MD     |  RFU     | Length  |
    | (2 bits)  | (1 bits) | (1 bit) | (1 bit) | (3 bits) |(8 bits) |
    +-----------+----------+---------+---------+----------+---------+

    * RFU is reserved for future use.
    ```

    - header
        1. LLID
            > The LLID indicates whether the packet isan LL Data PDU or an LL Control PDU.
            > + `00b` = Reserved
            > + `01b` = LL Data PDU: Continuation fragment of an L2CAP message, or an Empty PDU.
            > + `10b` = LL Data PDU: Start of an L2CAP message or a complete L2CAP message with no fragmentation.
            > + `11b` = LL Control PDU

        1. NESN
            > Next Expected Sequence Number
        1. SN
            > Sequence Number
        1. MD
            > More Data
        1. Length
            > The Length field indicates the size, in octets, of the Payload and MIC, if included.

    - Payload

        ```
        +-----------+-----------------+
        |   Opcode  |     CtrData     |
        | (1 octet) | (0 – 26 octets) |
        +-----------+-----------------+
        ```

        1. Opcode
            > + `0x00` = LL_CONNECTION_UPDATE_REQ
            > + `0x01` = LL_CHANNEL_MAP_REQ
            > + `0x02` = LL_TERMINATE_IND
            > + `0x03` = LL_ENC_REQ
            > + `0x04` = LL_ENC_RSP
            > + `0x05` = LL_START_ENC_REQ
            > + `0x06` = LL_START_ENC_RSP
            > + `0x07` = LL_UNKNOWN_RSP
            > + `0x08` = LL_FEATURE_REQ
            > + `0x09` = LL_FEATURE_RSP
            > + `0x0A` = LL_PAUSE_ENC_REQ
            > + `0x0B` = LL_PAUSE_ENC_RSP
            > + `0x0C` = LL_VERSION_IND
            > + `0x0D` = LL_REJECT_IND
            > + `0x0E` = LL_SLAVE_FEATURE_REQ
            > + `0x0F` = LL_CONNECTION_PARAM_REQ
            > + `0x10` = LL_CONNECTION_PARAM_RSP
            > + `0x11` = LL_REJECT_IND_EXT
            > + `0x12` = LL_PING_REQ
            > + `0x13` = LL_PING_RSP
            > + `0x14` = LL_LENGTH_REQ
            > + `0x15` = LL_LENGTH_RSP


## bitstream processing schemes

```
Tx payload (LSB first) -> encryption -> CRC generation -> whitening
                                                                |
                                                            RF interface
Rx payload <- ecryption <- CRC checking <- dewhitening    <-----+
```

## Air interface protocol

+ The `Inter Frame Space` (T_IFS) shall be `150 µs`.
    > The time interval between two consecutive packets
    on the same channel index is called the Inter Frame Space

### Advertising state

+ Advertising Event
    > Each advertising event is composed of
    one or more advertising PDUs sent on used advertising channel indices.
    >> BLE 廣播的過程中, 根據使用場景的不同,
    會在被使用的每一個物理 Channel 上, 發送(或接收)多種 PDU types.
    而 `Advertising Event` 是指在所有被使用的物理Channel上, 發送的 Advertising PDU 的組合.
    一個 `Advertising Event` type 相當於一種場景.

    - BLE 設備處於 Advertising 狀態的目的, 就是要廣播數據.
        > 根據應用場景的不同, 可廣播 4種類型的 Advertising Event type
        > + Connectable Undirected Event (with ADV_IND PDU)
        > + Connectable Directed Event (with ADV_DIRECT_IND PDU)
        >> Low/High Duty Cycle
        > + Non-connectable Undirected Event (with ADV_NONCONN_IND PDU)
        > + Scannable Undirected Event (with ADV_SCAN_IND PDU)

        > 另外, BLE 設備最多可以在 3 個物理 Channel 上廣播數據.
        也就是說, 同一種數據 (4種類型中的一種), 需要在多個 Channel 上**依序廣播**.
        因此, 這樣依序在多個 Channel 上廣播的過程, 就叫做一個 `Advertising Event`.

    - 有些 Advertising Event (如可連接, 可掃瞄)發送出去之後,
    允許接收端在對應的 Channel 上, 回應一些請求(如連接請求, 掃瞄請求).
    並且, 廣播者接收到掃瞄請求後, **需要在同樣的 Adv Channel 上回應**.
    這些過程, 也會計算在一個 Advertising Event 中.

    - 一個 `Advertising Event` 通常開始於發送 PDU 到第一個 Channel(37Ch), 結束於發送到最後一個 Channel(39Ch).
        > 也可能結束在**同一個 Adv Channel上, 完成一對 REQ(request) 和 RSP (response)的發送**
        >>


+ Advertising Event Interval

    ```
    T_advEvent = advInterval + advDelay

    Advertising State entered
    ^
    |                          |
    |   Advertising Events 0   |   Advertising Events 1   |
    |--------------------------|--------------------------|--------
    |<------- T_advEvent ----->|<------- T_advEvent ----->|
    |<--- advInterval --->     |                          |
    |                     <--->|                          |
                       advDelay

     _________________________ Advertising Events 0 _____________________________
    /                                                                            \
    |-------------------------|-------------------------|-------------------------|
    |<- ADV_IND PDU ->        |<- ADV_IND PDU ->        |<- ADV_IND PDU ->        |
    |<--- 37Ch ----------->   |<--- 38Ch ----------->   |<--- 38Ch ----------->   |
    |<--- less than 10 ms --->|<--- less than 10 ms --->|<--- less than 10 ms --->|
    |                                                                             |
    v                                                                             v
    advertising                                                              advertising
    event Start                                                               event End

    ```

    - `advInterval`
        > It should be `20 ms < (n * 0.625 ms) < 10.24 s`
        >> advInterval 是一個可由 Host 設定的參數:
        >> + 對於 `Scannable Undirected` 和 `Non-connectable Undirected`兩種 Advertising Event,
        該值**不能小於 100ms** (從功耗的角度考慮的, 也決定了廣播數據的速率)
        >> + 對於 `Connectable Undirected` 和 `Low Duty Cycle Connectable Directed` 兩種 Advertising Event,
        該值**不能小於 20ms** (建立連接嘛, 要快點)

        1. `High Duty Cycle Connectable Directed Event`則是一個比較狂暴的傢伙,
        其 Advertising 週期不受上面的參數控制, 可以小到 `3.75ms`.
        不過, BLE 協議也同時規定, Link Layer 必須在 `1.28s` 內退出這種狂暴狀態.

    - `advDelay`
        > It is a pseudo-random value with a range of `0 ~ 10 ms`
        generated by the Link Layer for **each advertising event**


+ 我們可以從上面的時間信息推斷出, BLE 協議對廣播通信的期望, 是非常明確的(不在乎速率、只在乎功耗).
一般的廣播通信(不以連接為目的), 最高速率也就是 `31-bytes / 100 ms = 2.48kbps`.
如果再算上可掃瞄的那段數據, 也就是double, 4.96kbps.

+ 對於連接來說, 如果事先不知道連接發起者的設備地址, 則最快的連接速度可能是 `20ms`.
如果事先知道地址, 使用 High Duty Cycle Connectable Directed Event 的話, 則可能在`3.75ms`內建立連接.
由此可以看出, BLE 的連接建立時間, 比傳統藍牙少了很多, 這也是 BLE 設備之間不需要保持連接的原因.


### Scanning State

Scanning State 是掃瞄和接收廣播數據的狀態,
該狀態的掃瞄行為是由 `scanWindow`和 `scanInterval`兩個參數決定的

```
|----------------------------------|-------------------------
|<- scanWindow ->                  |<- scanWindow ->
|                <- scanInterval ->|                <- scanInterval ->

condition:
1. scanWindow < scanInterval
2. (scanWindow <= 10.24 sec) and (scanInterval <= 10.24 sec)
3. if (scanWindow == scanInterval) => Never stop scanning
```

+ Parameters

    - `scanWindow`
        > the duration of the scan window
        >> 一次掃瞄的時間(即可以理解為 RF-RX 打開的時間)

    - `scanInterval`
        > the interval between the start of two consecutive scan windows
        >> 兩次掃瞄之間的間隔


+ Scanning type

不管哪個type, 目的都是把接收到的數據(包括Advertiser地址, Advertiser數據等), 往上報給 Host

    - Passive Scanning
        > the Link Layer will only receive packets, it shall not send any packets.
        >> 只接收 `ADV_DIRECT_IND`, `ADV_IND`, `ADV_SCAN_IND`, `ADV_NONCONN_IND`等類型的 PDU,
        並不發送 SCAN_REQ

    - Active Scanning
        > the Link Layer shall listen for advertising PDUs and
        depending on the advertising PDU type it may request an advertiser
        to send additional information
        >> 依照收到的 PDU, 發出 SCAN_REQ, 並接收後續的 SCAN_RSP

### Initiating State
### Connection State

# Bluetooth Classic  (BR/EDR)

# zephyr directory

```
                    Application
    ____________________________________________________
                    +----------+
                    |   Host   |
                    | +------+ |
                    | |  HCI | |
                    | +------+ |
                    +----------+
    ____________________________________________________
            +-------------------------------+      controller
            |               HCI             |
            +-------------------------------+
            +-------------------------------+
            |    +------------------------+ |
            | LL | Upper Link Layer (ULL) | |
            | SW +------------------------+ |
            |    | Vendor                 | |
            |    | Lower Link Layer (LLL) -----+
            |    +------------------------+ |  |
            +-------------------------------+  |
                |   +---------------+          |
                |   | Ticker/ Util  |          |
                |   +---------------+          |
                v       |                      v
        +-------------------+   +------------------+
        |         HAL       |   |  Vendor BLE HAL  |
        +-------------------+   +------------------+
```

+ `zephyr/drivers/bluetooth/hci`
    > the medium of HCI, e.g. uart, usb, rpmsg, ...etc.

+ `zephyr/subsys/bluetooth/controller`
    > the source code of controller

    - `hci`
        > the hci driver of controller

    - `hal`
        > hal of vendor specific (Replace with Zephyr Driver)

    - `ticker`
        > Soft real time radio/resource scheduling

    - `util`
        > + Bare metal memory management
        > + Queues of variable count, lockless
        > + FIFO, fixed count, lockless, ISR-ISR-Thread

    - `ll_sw`
        > Software-based Link Layer
        >> States and Roles, control procedures, packet controller

        1. `ull API`
            > Common Upper Link Layer

        1. `lll`
            > Vendor Specific Lower Link Layer

        1. `ll_sw/[vendor]/hal`
            > specific hal api of link layer from vendor

        1. `ll_sw/[vendor]/lll`
            > the instances of the lower link layer of vendor


+ `zephyr/subsys/bluetooth/host`
    > the source code of host, invole gatt, att, hci, ...etc.





# reference

+ [Bluetooth Stack Architecture](https://developer.nordicsemi.com/nRF_Connect_SDK/doc/latest/zephyr/guides/bluetooth/bluetooth-arch.html)
+ [Bluetooth Specification](https://www.bluetooth.com/specifications/archived-specifications/)
+ [淺顯易懂講解藍牙協議棧軟體框架](https://kknews.cc/tech/zaxoplq.html)
+ [藍牙協議分析(5)_BLE廣播通信相關的技術分析](http://www.wowotech.net/bluetooth/ble_broadcast.html)

## Open source
+ [zephyr](https://github.com/zephyrproject-rtos/zephyr)
+ [NimBLE](https://github.com/apache/mynewt-nimble)
+ Host side
    - [BTstack](https://github.com/bluekitchen/btstack/)
    - [BlueZ](http://www.bluez.org/download/)


