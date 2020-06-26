Ethernet (IEEE 802.3)
---

Ethernet使用方式為廣播模式, 傳出的資料`每一節點皆會接收並判斷是否為 destination node`.
提供給 network layer 是一種 connectionless service(無連線服務), 即在傳送和接收端的adapter間no handshaking.
也是一種unreliable service(不可靠服務), 接收端CRC check時, 不會送出確認訊息,
就算失敗, 傳送端也不知道, 可能會使要傳送的datagram出現間斷


```
            +--------------+
            | Application  |
            |              |
            |              |
            +--------------+
    S/w     | Transport    |
            |  (TCP/UDP)   |
    ^       +--------------+
    |       | Network      |
    |       |   (IP)       |
  ----------+--------------+
    |       | Data link    |
    |       |  (MAC)       |
    v       +--------------+  <---  MII/RMII/GMII interface + MDIO interface
    H/w     |   PHY        |
            +--------------+

```

# MAC

+ CSMA/CD (Carrier Sense Multiple Access/Collision Detection)

    - algorithm
        1. Adapter(MAC) 從 Network layer 取得 datagram(資料封包), 建立 frame.
        1. 如果 adapter(MAC) sences(感測) channel(通道) is idle(閒置的), 便傳送frame.
        若是 busy, 則等到 channel 為 idle 後再傳送.
        1. 當沒有 collision 時: 如果該 adapter(MAC) 正在傳送 frame 時,
        沒有其他 adapter 在傳送(即也在使用channel), 則該 adapter 便完成該 frame 的傳送.
        1. 當有 collision 時: 有其他 adapter(MAC) 在傳送, 該 adapter 便會 aborts (停止傳送frame),
        並且送出一個 jam signal(擁擠訊號, 48 bits).
        1. 送出 jam signal 後, 該 adapter 便會進入exponential backoff.
        第 n 次 collision, adapter(MAC) 便從 0 ~ 2^(n-1) 中隨機選一k值, 並 wait `K*512` 個 bit times,
        然後再去重新 sences channel.
        e.g. 第3次 collision, 從0,1,2,3,4,5,6,7中隨機選一值

    - efficiency

    ```
    d_prop = 在 TX 和 RX 的 adapters(MAC) 之間的最大傳播delay
    d_trans = 傳送最大的 frame 所需的時間

    efficiency = 1 / ((1 + 5*d_prop) / d_trans)
    當 d_prop 趨近於 0 或當 d_trans 非常大時, Efficiency(效率)趨近於 1
    ```


+ Ethernet II frame (packet)

```
    +-----------+----------+-------------+-------------+-----------+----------+-----------+
    | Preamble  |    SFD   | Destination | Source      | Ether     | Payload/ |   FCS     |
    | (7-bytes) | (1-byte) | MAC Address | MAC Address |  type     | Padding  | (4-bytes) |
    |           |          |  (6-bytes)  |  (6-bytes)  | (2-bytes) |          |           |
    +-----------+----------+-------------+-------------+-----------+----------+-----------+

    - Preamble: 一連串的 0xAA (bits:1010...10), 用來同步
    - SFD(Start of Frame Delimiter): 0xAB (bits:10101011), 用來表示經同步之後, 資料的起始
    - Destination MAC Address: 目標的MAC位址, MAC為 6-bytes的硬體碼, 前3碼為製造廠商碼, 後3碼為廠商自訂的流水號
    - Source MAC Address: 來源的MAC位址, 6-bytes
    - Ether type: 長度或者類別, e.g. IP為0x0800, ARP為0x0806
    - Padding: Ethernet 封包長度介於 46 ~ 1500bytes 之間, 因此假設IP封包長度沒有符合就必須做補滿的動作.
    - FCS(Frame check sequence, CRC32): Checksum, 用來確認傳送資料是否有錯誤
```

+ GMAC of Faraday (FTGMAC030)
    > + support 10/100 Mbps and 1Gbps Ethernet
    > + support MII/GMII/RMII/RGMII interfaces
    > + use S/w command queue (tx/rx descriptor, link-list implementation)
    and locate at system memory area
    > + TXMAC and RXMAC are indepandent.
    >> The clock of RXMAC is from PHY. (TBD)
    > support Wake-On-LAN
    >> - Link status change
    >> - magic packet
    >> - wake-up frame
    > + support IEEE-1588 PTP (Precision Time Protocol)

    - Transmission
        1. TXDMA fetchs the tx_desc info and move the packet data to TXFIFO
        1. TXDMA handshakes with TXMAC to sends packet data to PHY
            a. TXMAC detects the ethernet is free or not
            a. if ethernet is active, halt the trasmission.
            a. if ethernet is inactive, TXMAC adds preamble/CRC to this packet
                and sends the packet to Ethernet.
            a. TXMAC follows CSMA/CD algorithm to avoid collision
        1. TXMAC responses the status to TXDMA
        1. TXMAC writes the finial status back to the tx_desc

    - Receive
        1. RXMAC receives the packet data to RXFIFO
            a. RXMAC recognizes address and check CRC of the packet (IP/TCP/UDP)
            a. if address or CRC are fail, RXDMA discards this packet data.
            a. if address and CRC are right, RXDMA passes the packet data to RXFIFO.
        1. RXDMA fetchs the rx_desc info
        1. RXMAC handshakes with RXDMA and
            trigger RXDMA to move packet data from RXFIFO to the buffer of rx_desc
        1. RXDMA writes the status to rx_desc

    - Registers

        1. `Normal Priority Transmit Ring Base Address`
            > the S/w command queue base address (tx_np_desc) with Normal Priority.

        1. `Receive Ring Base Address`
            > the S/w command queue base address (rx_desc).

        1. `High Priority Transmit Ring Base Address`
            > the S/w command queue base address (tx_hp_desc) with High Priority.

        1. `High Priority Transmit Poll Demand`
            > manually trigger TXDMA

        1. `Normal Priority Transmit Poll Demand`
            > manually trigger TXDMA

        1. `TX Interrupt Timer Control`
            > tune the TX IRQ times (include waiting time, packets count) for performance
            >> allows the S/w to pend the number of TX IRQ (ISR[4], TxPKT2Ethernet).
            This lowers the CPU utilization for handling a large number of IRQs
            > + TXINT_THR and TXINT_THR_UNIT
            >> if tx packet conut == (TXINT_THR * TXINT_THR_UNIT), trigger IRQ
            > + TXINT_CYC and TXINT_TIME_SEL
            >> after transmit a packate, delay time to trigger IRQ (waiting time = TXINT_CYC * TXINT_TIME_SEL)

        1. `RX Interrupt Timer Control`
            > tune the RX IRQ times (include waiting time, packets count) for performance
            >> allows the S/w to pend the number of TX IRQ (ISR[0],RxPKT2Buf).
            This lowers the CPU utilization for handling a large number of IRQs
            > + RXINT_THR and RXINT_THR_UNIT
            >> if rx packet conut == (RXINT_THR * RXINT_THR_UNIT), trigger IRQ
            > + TXINT_CYC and TXINT_TIME_SEL
            >> after received a packate, delay time to trigger IRQ (waiting time = RXINT_CYC * RXINT_TIME_SEL)

        1. `Automatic Polling Timer Control`
            > automatic trigger TXDMA/RXDMA with S/w command queue (tx/rx descriptors)

        1. `DMA Burst Length and Arbitration Control`
            > + configure priorities of TXDMA/RXDMA accessing FIFO
            >> if **RXFIFO >= RXFIFO_HTHR**, priority `RXDMA > TXDMA` until **RXFIFO <= RXFIFO_LTHR**
            > + DMA configuration of burst
            > + IFG (Inter Frame Gap) setting

            a. Inter Frame Gap (IFG)
                > 在 PYH 所傳輸的單位稱為 Ethernet frame, frame 與 frame 間,
                必須要有間隔, 否則會無法分辨 Ethernet frame 的結束,
                這個間隔稱為 Inter Frame Gap (IFG) or Inter Packet Gap (IPG),
                長度最小為 `12 bytes`的傳輸時間.
                依不同的 SPEED, 而有不同的 delay time (10Mbps: 9.6ms, 100Mbps: 960ns, 1Gbps: 96ns)

            ```
            Data-link layer throughput:

            the min Ethernet fram = 72 bytes
            PHY layer frame = 72 + 7 + 1 + 12 = 92 bytes
            ps. Preamble (7 bytes), Start of frame delimiter(SFD, 1 byte)

            In 10Mbps case:
            10,000,000 / (92 * 8) = 13586 frames ---> PHY layer
            13586 * 72 * 8 = 7,825,536 bps       ---> Data-link layer
            ```

        1. `MAC Control`
            > the master functions configuration

        1. `PHY Control`
            > communicate PHY with MII/RMII/GMII
            >> support to change MDC cycle (MDC period = MDC_CYCTHR * 400ns)

    - Registers to report information

        1. `Normal Priority Transmit Ring Pointer`
            > current active tx S/w cmdq (tx_np_desc)

        1. `High Priority Transmit Ring Pointer`
            > current active tx S/w cmdq (tx_hp_desc)

        1. `Receive Ring Pointer`
            > current active rx S/w cmdq (rx_hp_desc)

        1. `TPKT_CNT Counter`
            > Counter for counting packets `transmitted` successfully
        1. `RPKT_CNT Counter`
            > Counter for counting the packets `received` successfully
        1. `BROPKT_CNT Counter`
            > Counter for counting the received `broadcast` packets
        1. `MULPKT_CNT Counter`
            > Counter for counting the received `multicast` packets
        1. `Feature`
            > H/w feature configuration

        1. `GMAC Interface Selection`
            > select MII/RMII/RGMII interface



# PHY

# MII Interface (Data handle)

    MII 標準介面用於連接 Ethernet的 MAC 與 PHY.
    `介質無關(Media Independent)` 表明在不更換 MAC 硬體的情況下, 任何類型的 PHY 設備都可以正常工作.
    在其他速率下工作的與 MII等效的介面有: AUI(10M乙太網), GMII(Gigabit乙太網) 和 XAUI(10-Gigabit乙太網)

    ps. the role is like RTP

+ RMII (Reduced Media Independent Interface)
    > 簡化媒體獨立介面, 是標準的乙太網介面之一, 比MII有更少的I/O傳輸.
    其中含有 `2-bits data pins`

    - 10Mbps
        > clock 5MHz
    - 100Mbps
        > clock 50MHz

+ MII (Media Independent Interface)
    > `4-bits data pins`

    - 10Mbps
        > clock 2.5MHz
    - 100Mbps
        > clock 25MHz

+ GMII (Gigabit Media Independent Interface)
    > GMII 是 `8-bit data pins` 並行同步收發介面, `clock = 125MHz`, 因此傳輸速率可達 1000Mbps.
    同時相容 MII所規定的 `10/100 Mbps`工作方式.
    GMII 介面資料結構符合 `IEEE 802.3-2000`

+ PINs

    - transmitter
        1. GTXCLK
            > Giga bit TX.信號的 clock (125MHz)
        1. TXCLK
            > 10/100M clock
        1. TXD[7..0]
            > 被發送資料
        1. TXEN
            > 發送器使能信號
        1. TXER
            > 發送器錯誤(用於破壞一個資料包)

    - receiver
        1. RXCLK
            > 接收 clock (從收到的資料中提取, 因此與 GTXCLK/TXCLK 無關聯)
        1. RXD[7..0]
            > 接收資料
        1. RXDV
            > 接收資料有效指示
        1. RXER
            > 接收資料出錯指示
        1. COL
            > 衝突檢測(僅用於半雙工狀態)

# Serial Management Interface (SMI, control handle)

    通常直接被稱為 MDIO接口(Management Data I/O Interface),
    主要被應用於 ethernet 的 MAC 和 PHY 層之間,
    MAC device 通過讀寫 registers 來實現對 PHY device 的操作與管理.

    ps. the role is like RTCP

+ Concept
    > MDIO主機(即產生 MDC clock 的設備)通常被稱為STA(Station Management Entity),
    而 MDIO從機通常被稱為 MMD(MDIO Management Device).
    通常 STA 都是 `MAC device` 的一部分, 而 MMD 則是 `PHY device` 的一部分.
    MDIO接口包括兩條線, `MDIO`和`MDC`, 其中MDIO是雙向數據線, 而 MDC 是由 STA驅動的時鐘線.
    MDC時鐘的最高速率一般為 `2.5MHz`, MDC 也可以是非固定頻率

    - IEEE 802.3 clause 22
        > MDIO接口最多支持連接 `32`個MMD(PHY層設備), 每個設備最多支持 `32 個 registers`

        ```
        typedef struct mdio22_frame
        {
            uitn32_t    ST      : 2; // start of frame
            uitn32_t    OP      : 2; // opcode, b10 = read, b01 = write
            uitn32_t    PHY_addr: 5;
            uitn32_t    reg_addr: 5; // registers of PPHY
            uitn32_t    ta      : 2; // turn-around time for slave to start driving read data if read opcode
            uitn32_t    data    : 16;
        } mdio22_frame_t;
        ```

    - IEEE 802.3 clause 45
        > MDIO接口最多支持連接 `32`個MMD, 32個設備類型, 每個設備最多支持 `64K 個registers`

+ PINs

    - MDC
        > the clock signal of SMI
    - MDIO
        > I/O signal for read/write registers of PHY


# Simplex vs Duplex

+ Simplex
    > 單工傳輸就是單向的傳輸, 一邊固定為發出訊號, 另一邊固定只有接收信號
+ Half Duplex
    > 半雙工則是有來有往的, 不過`同一時間只能有一個方向的傳輸發生`
+ Full Duplex
    > 全雙工則是支援同一時間收發

# 電纜(cabling)

`IEEE 802.3` 規定的 ethernet cabling 以 `X-Y-Z` 三個值來作描述, 其中
`X` 代表頻寬(Mbps, Mbits/sec),
`Y` 代表訊號傳輸方式(Base 或 Broad; Base 代表以基頻方式傳輸, Broad 則是以寬頻來傳輸),
`Z` 代表傳輸媒介的類型 (T:表示是以雙絞線為傳輸媒介, F:則是以光纖電纜骨幹為傳輸媒介)

像是 `10BASE-5`, `10BASE-2`, `10BASE-T`以及`10BASE-F`.
其中 `10` 表示資料傳輸速度是 `10Mbps`, `Base`是 Baseband 的縮寫, 是指同時只能使用一個頻道傳輸資料.

+ `10Base-5`
    > 粗的同軸電纜網路, 為最早出現的產品, 因此被稱為標準乙太網路,但已被汰換不再使用.
    使用 RG-11 纜線與 AUI 接頭, 傳輸距離為 `500公尺` (加上 repeater 之後可達 2,500 公尺), 連接成匯流排狀網路, 最多可以支援 100 個節點.

    - 缺點
        > + 速度只能達到10Mbps
        > + 使用同軸電纜接線, 若網路的任一處斷線, 會導致整個網路停擺, 且追查斷線點不易.
        > + 若有電腦要調動位置, 佈線路徑可能要大幅修正或整體新佈線, 因此在維護管理上非常困難.

+ `10Base-2`
    > 細的同軸電纜網路.
    使用 RG-58 A/U 纜線與 BNC 接頭, 一區段最長可以傳輸 `185m`並連接 30 部電腦
    (加上 repeater 之後可達 925 公尺, 可連接五個區段.), 連接成匯流排狀網路.
    RG-11 一區段距離為500公尺可連接一百台電腦, 透過Repeater架設也是可連接五個區段, 兩者皆為匯流排型(Bus)拓撲方式.

    - 缺點
        > + 速度只能達到10Mbps
        > + 使用同軸電纜接線, 若網路的任一處斷線, 會導致整個網路停擺, 且追查斷線點不易.
        > + 若有電腦要調動位置, 佈線路徑可能要大幅修正或整體新佈線, 因此在維護管理上非常困難.

+ `10Base-T`
    > 雙絞線網路, 使用 `UTP-3` (無遮蔽式雙絞線)纜線與 `RJ-45 Connector`,
    以集線器(Hub)來連接所有的電腦, 最長傳輸距離可達 100 公尺,
    連接匯流排型(Bus)與星狀(Star)拓撲方式架設.

    - 優點
        > + 每台電腦皆獨立連接至集線器, 因此如果有某台電腦或某個線段有問題,
        只會影響到本身的線段, 而不至於影響其他電腦的運作.
       > + 哪一段的線路發生故障可從集線器的燈號判斷出, 容易維護.
       > + 調動電腦時, 只需改變局部的佈線路徑即可.

+ `10Base-F`
    > 光纖網路, 使用光纖纜線 (Fiber Optic) 作為傳輸媒介, 傳輸距離最長可達 2,000 公尺, 一般連接成星狀網路.

+ `100BASE-T` (Fast Ethernet, IEEE 802.3u)

    - `100BaseTX`
        > 使用第 5 類(Category 5)(含)以上等級的無遮蔽雙絞線 UTP, 傳輸訊號的頻率較高,
        是市場上最早推出的 100Mbps 乙太網路規格也是目前家庭或企業使用最普遍的網路類型.
    - `100BaseT4`
        > 採用雙絞線為傳輸介質, 可以使用 Cat 3~Cat6 等級的線材,
        但因為是半雙工傳輸模式, 非主流產品, 因此在市場上很少見到相關的產品.

+ `100BaseFX`
    > 在點對點的連接方式下, 使用多模光纖, 其傳輸距離可達 2 公里, 而以單模光纖則更可高達 10 公里



# reference

+ [Ethernet(乙太網路): Frame, CSMA/CD](https://sls.weco.net/node/10698)
+ [乙太網路](https://zh.wikipedia.org/wiki/%E4%BB%A5%E5%A4%AA%E7%BD%91)
+ [ethernet-mac-phy](http://blog.gitdns.org/2016/06/17/ethernet-mac-phy/)
+ [IEEE 802.3 CSMA/CD網路](http://www.cs.nthu.edu.tw/~nfhuang/chap04.htm)
+ [Linux網絡子系統學習筆記](http://docs.ifjy.me/contents/linux/003/linux%E5%86%85%E6%A0%B8%E7%BD%91%E7%BB%9C%E5%AD%90%E7%B3%BB%E7%BB%9F%E5%88%86%E6%9E%90.html)
+ [linux- Enabling and Disabling Transmissions](http://www.embeddedlinux.org.cn/linux_net/0596002556/understandlni-CHP-11-SECT-1.html)
+ [netif_start_queue/netif_wake_queue/netif_stop_queue](https://www.cnblogs.com/zxc2man/p/4105652.html)

