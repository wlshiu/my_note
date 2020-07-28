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

## Definition

+ `Byte`
    > 表示的是 CPU 可以獨立尋址的最小內存單位
+ `octet`
    > 8 bits
+ `nibble`
    > 4 bits
+ `PDU`
    > Packet Data Unit

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
    > 發出 request

+ Server role
    > 發出 response 來回應 request


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

+ PDU

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


## zephyr directory

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


# Bluetooth Classic  (BR/EDR)


# reference

+ [Bluetooth Stack Architecture](https://developer.nordicsemi.com/nRF_Connect_SDK/doc/latest/zephyr/guides/bluetooth/bluetooth-arch.html)
+ [Bluetooth Specification](https://www.bluetooth.com/specifications/archived-specifications/)
+ [淺顯易懂講解藍牙協議棧軟體框架](https://kknews.cc/tech/zaxoplq.html)

## Open source
+ [zephyr](https://github.com/zephyrproject-rtos/zephyr)
+ [NimBLE](https://github.com/apache/mynewt-nimble)
+ Host side
    - [BTstack](https://github.com/bluekitchen/btstack/)
    - [BlueZ](http://www.bluez.org/download/)


