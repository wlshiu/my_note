USB Enumeration [[Back]](note_usb_device.md#Bus-Enumeration)
---

列舉就是從 Device 讀取一些資訊, 知道 Device 是什麼樣的 Device , 如何進行通訊, 這樣 Host 就可以根據這些資訊來載入合適的驅動程式.
> Debug USB Device, 很重要的一點就是 USB 的列舉過程, 只要列舉成功了, 那麼就已經成功大半了

USB 架構中, hub 負責檢測 Device 的連線和斷開, 利用其中斷 `IN Endpoint` 來向 Host 報告.

在系統啟動時, Host 輪詢它的 `Root Hub`的狀態, 看是否有 Device (包括 sub-hub 和 sub-hub 上的 Device)連線

一旦獲悉有新 Device 連線上來,  Host 就會發送一系列的 Resqusts 給 Device 所掛載到的 hub, 再由 hub 建立起一條 Host 和 Device 之間的通訊通道. <br>
然後 Host 以控制傳輸(Control Transfer)的方式, 通過 Endpoint0 對 Device 傳送各種請求, Device 收到 Host 發來的請求後, 回覆相應的資訊, 並進行列舉(Enumerate)操作
> 所有的 USB Device 必須支援
> + Standard Requests (ref. Table 9-3. Standard Device Requests)
> + 控制傳輸方式(Control Transfer)
> + Endpoint0

在解釋列舉之前, 先大概說說 USB 的一種傳輸模式: 控制傳輸
> 這種傳輸在 USB 中是非常重要的, 它要保證資料的正確性, 在 Device 的列舉過程中都是使用控制傳輸的, 而控制傳輸分為三個階段:
> + 建立階段
> + 資料階段
> + 確認階段

+ 建立(SETUP Token)階段:
    > 都是由USB Host 發起, 它是一個setup資料包, 裡面包含一些資料請求的命令以及一些資料。

+ 資料傳輸階段
    > + 如果建立階段是 IN 請求, 那麼資料階段就要輸入資料;
    > + 如果建立階段是 OUT 請求, 那麼資料階段就要輸出資料。
    > + 在資料階段, 即便不需要傳送資料, 也要發一個 `0 長度`的資料包

+ 確認階段
    > 確認階段是用來確認資料的正確傳輸, 資料方向剛好跟資料階段相反
    > + 如果是 Data IN 請求, 則確認階段是一個輸出資料包
    > + 如果是 Data OUT 請求, 則確認階段是一個輸入資料包


# USB Enumeration 過程

USB 協議定義了 Device 的6種狀態, 僅在列舉過程中, Device 就經歷了4 個狀態的遷移
> + 上電狀態(Powered)
> + 預設狀態(Default)
> + 地址狀態(Address)
> + 配置狀態(Configured)
>> 其他兩種是連線狀態(Attached)和掛起狀態(Suspended)

以下是依過程順序說明

## 使用者把 USB Device 插入 USB Port 或系統啟動時給 Device 上電

這裡指的 USB Port 指的是 Host 下的 Root Hub 或 Host 下行 Ports 的 Hub Port. <br>
Hub 給 Ports 供電, 連線著的 Device 處於上電狀態
> 此時雖然 USB Device 處於上電狀態, 但它所連線的 Port 是無效的

## Hub 監測它各個 Ports 資料線上(D+/D-)的電壓

在 Hub 端, 資料線`D+`和`D-`都有一個阻值在 **14.25 ~ 24.8k**的下拉電阻Rpd, 而在 Device 端, `D+`(Full/High Speed)和 `D-`(Low-Speed)上, 有一個**1.5k**的上拉電阻Rpu.

當 Device 插入到 Hub Port 時, 有上拉電阻的一根資料線被拉高到幅值的 90% 的電壓(大致是3V).
Hub 偵測到`D+`和`D-`中的一根資料線是高電平, 就認為是有 Device 插入, 並能根據是`D+`還是`D-`被拉高來判斷 Device 的速度.

偵測到 Device 後, Hub 繼續給 Device 供電, 但並不急於與 Device 進行 USB 傳輸

## Host 確認連線的 Device

每個 Hub 利用它自己的中斷 endpoint, 向 Host 報告它的各個 Port 的狀態(對於這個過程, Device 是看不到的, 也不必關心),
報告的內容只是 Hub Ports 的 Device Connection/Disconnection 的 event.
> 如果有 Connection/Disconnection 事件發生, 那麼 Host 會發送一個 `Get_Port_Status` Request 給 Hub, 以瞭解此次狀態改變的確切含義
>> `Get_Port_Status`等 Request, 屬於所有 Hub 都要求支援 Standard Hub-class requests

## Hub 檢測所插入的 Device 是高速還是低速 Device

Hub 通過偵測 USB Bus Idle 時, `D+`和 `D-`的高低電壓, 來判斷所連線 Device 的速度型別. <br>
當 Host 發來`Get_Port_Status` Request 時, Hub 就可以回覆此 Device 的速度型別資訊給 Host
> USB 2.0 規範要求速度檢測, 要先於復位(Reset)操作

## Hub 復位 Device

Host 一旦得知新 Device 已連上以後, 它至少**等待 100ms**, 使得 Plug-In 操作完成及 Device 電源穩定工作. <br>
然後 Host 控制器就向 Hub發出一個 `Set_Port_Feature` Request, 讓 Hub reset 其管理的 Port(剛才 Device 插上的 Port).

Hub 通過驅動資料線到復位狀態(`D+`和`D-`全為低電平), 並**持續至少 10ms**.
> Hub 不會把這樣的復位訊號, 傳送給其他已有 Device 連線的 Port, 所以其他連在該 Hub 上的 Devices 不受影響

## Host 檢測所連線的全速 Device 是否是支援高速模式

因為根據 USB 2.0 協議, High Speed Device 在初始時, 是預設為 Full Speed 狀態執行,
所以對於一個支援 USB 2.0 的 High Speed Hub, 當它發現 Port 連線的是一個 Full Speed Device 時, 會進行高速檢測, 看看目前這個 Device 是否還支援高速傳輸.
> 如果支援就切到 High Speed 模式, 否則就一直在 Full Speed 狀態下工作

同樣的, 從 Device 的角度來看, 如果是一個高速 Device, 在剛連線 Hub 或上電時, 只能用 Full Speed 模式執行
> 根據 USB 2.0 協議, High Speed Device 必須向下相容 USB 1.1 的全速模式

隨後 Hub 會進行高速檢測, 之後這個 Device 才會切換到 High Speed 模式下工作.
> 假如連線的 Hub 本身不支援 USB 2.0, Device 將一直以 Full Speed 工作(無法進行高速檢測)

## Hub 建立 Device 和 Host 之間的資訊通道

Host 不停地向 Hub 傳送`Get_Port_Status` Request, 以查詢 Device 是否 reset 成功.
> Hub 返回的報告資訊中, 有專門的欄位用來標誌 Device 的復位狀態

當 Hub 撤銷了復位訊號, Device 就處於預設/空閒狀態(Default state), 並準備接收 Host 發來的請求.
> Device 和 Host 之間的通訊通過控制傳輸, 以 Endpoint0 且 `Default Address = 0x0` 來進行控制傳輸. 此時 Device 能從 Bus 上得到的最大電流是 **100mA**.
>> 所有的 USB Device 在 Bus reset 後, 其 default address 都為 0x0, 這樣 Host 就可以跟那些剛剛插入的 Device, 通過 `Address = 0x0` 來通訊

## Host 發送 Get_Descriptor 請求獲取預設管道的最大包長度

`Default Pipe` 在 Device 端來看就是 Endpoint0, 而 Host 此時傳送的 Request, 是對 Endpoint0 且 `Default Address = 0` 的 Device 發送.

雖然所有未分配地址的 Device, 都是通過 `Address = 0` 來獲取 Host 發來的請求,
但由於列舉過程不是多個 Device 並行處理, 而是一次列舉一個 Device 的方式進行,
所以不會發生多個 Device 同時響應 Host 發來的請求.

Device Descriptor 的 `8-th Bytes` 代表 Device Endpoint0 的最大 packet size.

雖然說 Device 所返回的 Device Descriptor 長度只有 `18-bytes`, 但此時 Host 只關心 Descriptor 的長度資訊, 其他的基本忽略.
當完成第一次的控制傳輸後, 也就是完成控制傳輸的狀態階段, Host 會要求 Hub 對 Device 進行再一次的 reset 操作(USB規範裡面可沒這要求).
> 再次 reset 的目的是使 Device 進入一個確定的狀態

##  Host 給 Device 分配一個唯一的地址

Host 控制器通過`Set_Address` Request, 向 Device 分配一個唯一的地址. <br>
在完成這次傳輸之後, Device 進入 Address state, 之後就啟用新地址繼續與 Host 通訊.
> 這個地址對於 Device 來說是終生制的, 只要 Device 存在, 地址就不會回收 <br>
當 Device 消失(被拔出, 復位, 系統重啟..), 地址就會被收回
>> 同一個 Device 當再次被列舉後, 得到的地址不一定是原本的地址

##  Host 獲取 Device 的資訊

主機發送 Get_Descriptor請求到新地址讀取裝置描述符,這次主機發送Get_Descriptor請求可算是誠心,它會認真解析裝置描述符的內容。裝置描述符內資訊包括端點0的最大包長度,裝置所支援的配置(Configuration)個數,裝置型別,VID(Vendor ID,由USB-IF分配), PID(Product ID,由廠商自己定製)等資訊。Get_Descriptor請求(Device type)和裝置描述符(已抹去VID,PID等資訊)

之後主機發送Get_Descriptor請求,讀取配置描述符(Configuration Descriptor),字串等,逐一瞭解裝置更詳細的資訊。事實上,對於配置描述符的標準請求中,有時wLength一項會大於實際配置描述符的長度(9位元組),比如255。這樣的效果便是:主機發送了一個Get_Descriptor_Configuration 的請求,裝置會把介面描述符,端點描述符等後續描述符一併回給主機,主機則根據描述符頭部的標誌判斷送上來的具體是何種描述符。
      接下來,主機就會獲取配置描述符。配置描述符總共為9位元組。主機在獲取到配置描述符後,根據裡面的配置集合總長度,再獲取配置集合。配置集合包括配置描述符,介面描述符,端點描符等等。
     如果有字串描述符的話,還要獲取字串描述符。另外HID裝置還有HID描述符等

##  Host 給 Device 掛載驅動(複合 Device 除外)

主機通過解析描述符後對裝置有了足夠的瞭解,會選擇一個最合適的驅動給裝置。  然後tell the world(announce_device)說明裝置已經找到了,最後呼叫裝置模型提供的介面device_add將裝置新增到 usb 匯流排的裝置列表裡,然後 usb匯流排會遍歷驅動列表裡的每個驅動,呼叫自己的 match(usb_device_match) 函式看它們和你的裝置或介面是否匹配,匹配的話呼叫device_bind_driver函式,現在就將控制權交到裝置驅動了。

     對於複合裝置,通常應該是不同的介面(Interface)配置給不同的驅動,因此,需要等到當裝置被配置並把介面使能後才可以把驅動掛載上去。

實際情況沒有上述關係複雜。一般來說,一個裝置就一個配置,一個介面,如果裝置是多功能符合裝置,則有多個介面。端點一般都有好幾個,比如Mass Storage裝置一般就有兩個端點(控制端點0除外)。


##  Device 驅動選擇一個配置

驅動(注意,這裡是驅動,之後的事情都是有驅動來接管負責與裝置的通訊)根據前面裝置回覆的資訊,傳送Set_Configuration請求來正式確定選擇裝置的哪個配置(Configuration)作為工作配置(對於大多數裝置來說,一般只有一個配置被定義)。至此,裝置處於配置狀態(Configured),當然,裝置也應該使能它的各個介面(Interface)。
    對於複合裝置,主機會在這個時候根據裝置介面資訊,給它們掛載驅動

# Reference
+ [USB 列舉教學，詳解](https://wwssllabcd.github.io/2012/11/28/usb-emulation/)
+ [USB列舉過程](https://www.796t.com/p/123921.html)


