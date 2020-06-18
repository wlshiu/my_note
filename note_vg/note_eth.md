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
    v       +--------------+  <---  MII/RMII/GMII interface
    H/w     |   PHY        |
            +--------------+

```

# MAC

+ CSMA/CD (Carrier Sense Multiple Access/Collision Detection)

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
    >> The clock of RXMAC is from PHY.
    > support Wake-On-LAN
    >> - Link status change
    >> - magic packet
    >> - wake-up frame

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

# PHY

# MII Interface

    MII 標準介面用於連接 Ethernet的 MAC 與 PHY.
    `介質無關(Media Independent)` 表明在不更換 MAC 硬體的情況下, 任何類型的 PHY 設備都可以正常工作.
    在其他速率下工作的與 MII等效的介面有: AUI(10M乙太網), GMII(Gigabit乙太網)和XAUI(10-Gigabit乙太網)

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




