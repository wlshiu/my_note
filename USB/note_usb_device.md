USB Device [[Back]](note_usb.md#Device)
---

# USB Device States

+ Attached
    > USB Device 連接上 Host 的狀態

+ Powered
    > Device 通過配置 Descriptor 報告其電源功能, 根據 Device 供電選項上游端口進行對應供電策略

    - USB  Device 可以從外部或自身獲取電源, 當自身已經有電源的情況下, 如果 USB Device 沒有連接, 則不認為 USB 處於上電狀態

+ Default
    > 上電後不進行任何響應, 直至 reset 信號到來; 接到 reset 信號後, 使用默認地址對 Device 進行尋址
    >> 此狀態完成後 Device 在正確的速度下進行操作, 該速度是 Low-Speed 還是 Full-Speed 的由 Device 的終端電阻所決定

+ Address
    > 所有 USB Device 在上電 reset 後, 都使用 default 地址, 當連接或 reset 後, 由 Host 分配一個唯一的 address.

    - USB Device 只對 default pipe (endpoint0)的請求發生響應
        > 不管 Device 是否已經分配地址或者使用默認地址

    - USB Device 處於 Suspended 後, 保持地址不變

+ Configured
    > 在 USB Device 被使用之前, 都需要經過配置;
    改變 USB Device 的配置, 會使得跟 Endpoint 綁定的所有狀態和配置值, 都被設置為 default

+ Suspended
    > 為了節省功耗, USB Device 在檢測不到 Bus 傳輸時, 自動進入 Suspended 狀態
    >> 在 Suspended 狀態, USB Device 保持其內部的狀態不變, 包括地址和配置


## [Bus-Enumeration](note_usb_enumeration.md) (列舉, Ch 9.1.2 Bus Enumeration)

當 USB Device 接入 USB Host 時, Host 從 Device 中獲取 Device 的相關信息, 包括 USB Device 的 Device type, 通信速率, Device Vendor 等信息;
然後 Host 根據這些信息加載對應的 USB Driver 來實現跟 Device 的通信
> 主要進行的操作, 就是獲取 Configuration Descriptor, parsing Configuration Descriptor, parsing Endpoint Descriptor
>> 簡而言之就是從 Device 端獲取其性能和配置

Enumeration 過程中使用了控制傳輸, 這種傳輸保證數據傳輸的正確性.

# Standard Device Requests

Host 會經由 Endpoint0 的 Control Pipe 與 Device 溝通, 依 `Standard Device Requests` 格式, 對 Device 發出各種 Requests.

+ Standard Device Requests format (Ref. Table 9-2. Format of Setup Data in USB 2.0 Spec)

    | Offset  | Field          | Size   | Value             |Description                                           |
    | :-:     | :-:            | :-:    | :-:               | :-                                                   |
    | 0       | bmRequestType  | 1      | Bit-Map           | Bit[7] Data Phase Transfer Direction<br/>&ensp; 0 = Host to Device <br/>&ensp; 1 = Device to Host |
    |         |                |        |                   | Bit[6:5] Type <br/>&ensp; 0 = Standard <br/>&ensp; 1 = Class <br/>&ensp; 2 = Vendor <br/>&ensp; 3 = Reserved <br/> |
    |         |                |        |                   | Bit[4:0] Recipient <br/>&ensp; 0 = Device <br/>&ensp; 1 = Interface <br/>&ensp; 2 = Endpoint <br/>&ensp; 3 = Other<br/>&ensp; 4~31 = Reserved <br/> |
    | 1       | bRequest       | 1      | Value             | Request                                              |
    | 2       | wValue         | 2      | Value             | Value                                                |
    | 4       | wIndex         | 2      | Index or Offset   | Index                                                |
    | 6       | wLength        | 2      | Count             | Number of bytes to transfer if there is a data phase |

## Requests type (Ref. 9.4 Standard Device Requests in USB 2.0 Spec)

+ GET_DESCRIPTOR (Ref. Ch 9.4.3 Get Descriptor in USB 2.0 Spec)
    > 要求 Device 返回存在的 Descriptor.

    ```
    +---------------+----------------+----------------------------------+-------------+------------+------------+
    | bmRequestType |    bRequest    |          wValue                  | wIndex      | wLength    | Data       |
    +---------------+----------------+----------------------------------+-------------+------------+------------+
    | 10000000B     | GET_DESCRIPTOR | Descriptor Type (Bit[15:8]) and  | Zero or     | Descriptor | Descriptor |
    |               |                | Descriptor Index (Bit[7:0])      | Language ID | Length     |            |
    +---------------+----------------+----------------------------------+-------------+------------+------------+
    ```

    - `bmRequestType`

        ```
        typedef struct
        {
            union {
                uint8_t        RequestType;
                struct {
                    /**
                     *  D4...0: Recipient
                     *      0 = Device
                     *      1 = Interface
                     *      2 = Endpoint
                     *      3 = Other
                     *      4 ~ 31 = Reserved
                     */
                    uint8_t     recipient : 5;

                    /**
                     *  D6...5: Type
                     *      0 = Standard
                     *      1 = Class
                     *      2 = Vendor
                     *      3 = Reserved
                     */
                    uint8_t         type  : 2;

                    /**
                     *  D7: Data transfer direction
                     *      0 = Host-to-device
                     *      1 = Device-to-host
                     */
                    uint8_t     direction : 1;
                } RequestType_b;
            };
        };
        ```

    - `GET_DESCRIPTOR`
        > Ref. Table 9-4. Standard Request Codes in USB 2.0 Spec

    - `Descriptor Type`
        > Ref. Table 9-5. Descriptor Types in USB 2.0 Spec

    - `wLength`
        > 表示要接收或發送多少 bytes (bmRequestType->RequestType_b.direction 決定方向)

        > + Descriptor 長度大於 wLength, 那麼只有 Descriptor 的前半部被返回
        > + Descriptor 長度小於 wLength, 則傳送一個短包來標誌傳輸的結束
        >> 一個短包被定義成一個長度短於最大負載長度或一個空(NULL)包

# Standard Descriptor

USB Device 經由 Endpoint0 的 Control Pipe, 依 `Standard Descriptor` 格式, 將自己的資訊回報給 Host

Standard Descriptor 有 5種, USB 為這些 Descriptor 定義了編號 (Table 9-5. Descriptor Types in USB 2.0 Spec)
> + 1 == Device Descriptor
> + 2 == Configuration Descriptor
> + 3 == String Descriptor
> + 4 == Interface Descriptor
> + 5 == Endpoint Descriptor

上面的 Descriptor 之間有一定的關系,
> + 一個 Device 只有一個 Device Descriptor
> + 一個 Device Descriptor 可以包含多個 Configuration Descriptors
> + 一個 Configuration Descriptors 可以包含多個 Interface Descriptors
> + 一個 Interface Descriptors 使用了 n個 Endpoints, 就有 n 個 Endpoint Descriptors

## Device Descriptor

Ref. Table 9-8. Standard Device Descriptor in USB 2.0 Spec

```
struct _DEVICE_Descriptor
{
    uint8_t    bLength;           //  Device 描述符的字節數大小, 為 0x12
    uint8_t    bDescriptorType;   // 描述符類型編號, 為0x01
    uint16_t   bcdUSB;            // USB 版本號 (BCD coding)
    uint8_t    bDeviceClass;      // USB 分配的 Device 類代碼, 0x01~0xfe 為標准 Device 類, 0xff 為廠商自定義類型
                                  // 0x00 不是在 Device 描述符中定義的, 如 HID
    uint8_t    bDeviceSubClass;   // usb 分配的子類代碼, 同上, 值由 USB 規定和分配的
    uint8_t    bDeviceProtocl;    // USB 分配的 Device 協議代碼, 同上
    uint8_t    bMaxPacketSize0;   // 端點 0 的最大包的大小
    uint16_t   idVendor;          // 廠商編號
    uint16_t   idProduct;         // 產品編號
    uint16_t   bcdDevice;         //  Device 出廠編號
    uint8_t    iManufacturer;     // 描述廠商字符串的索引
    uint8_t    iProduct;          // 描述產品字符串的索引
    uint8_t    iSerialNumber;     // 描述 Device 序列號字符串的索引
    uint8_t    bNumConfiguration; // 可能的配置數量
}
```

## Configuration Descriptor

Ref. Table 9-10. Standard Configuration Descriptor in USB 2.0 Spec

```
struct _CONFIGURATION_Descriptor
{
    uint8_t    bLength;              //  Device 描述符的字節數大小, 為0x12
    uint8_t    bDescriptorType;      // 描述符類型編號, 為0x01
    uint16_t   wTotalLength;         // 配置所返回的所有數量的大小
    uint8_t    bNumInterface;        // 此配置所支持的接口數量
    uint8_t    bConfigurationVale;   // Set_Configuration命令需要的參數值
    uint8_t    iConfiguration;       // 描述該配置的字符串的索引值
    uint8_t    bmAttribute;          // 供電模式的選擇
    uint8_t    bMaxPower;            //  Device 從總線提取的最大電流
}
```

+ `bmAttribute`

    - Bit[4:0]
        > Reserved (reset to zero)
    - Bit[5]
        > Remote Wakeup

    - Bit[6]
        > Self-powered

    - Bit[7]
        > Reserved (set to one)

## String Descriptor

Ref. Table 9-16. UNICODE String Descriptorin USB 2.0 Spec

```
struct _STRING_Descriptor
{
    uint8_t    bLength;             //  Device 描述符的字節數大小, 為 0x12
    uint8_t    bDescriptorType;     // 描述符類型編號, 為 0x01
    uint8_t    bString[N];          // UNICODE 編碼的字符串
}
```


## Interface Descriptor

Ref. Table 9-12. Standard Interface Descriptor in USB 2.0 Spec

```
struct _INTERFACE_Descriptor
{
    uint8_t    bLength;            //  Device 描述符的字節數大小, 為0x12
    uint8_t    bDescriptorType;    // 描述符類型編號, 為0x01
    uint8_t    bInterfaceNunber;   // 接口的編號
    uint8_t    bAlternateSetting;  // 備用的接口描述符編號
    uint8_t    bNumEndpoints;      // 該接口使用端點數, 不包括端點0
    uint8_t    bInterfaceClass;    // 接口類型
    uint8_t    bInterfaceSubClass; // 接口子類型
    uint8_t    bInterfaceProtocol; // 接口所遵循的協議
    uint8_t    iInterface;         // 描述該接口的字符串索引值
}
```


## Endpoint Descriptor

Ref. Table 9-13. Standard Endpoint Descriptor in USB 2.0 Spec

```
struct _ENDPOIN_Descriptor
{
    uint8_t    bLength;          //  Device 描述符的字節數大小, 為 0x12
    uint8_t    bDescriptorType;  // 描述符類型編號, 為 0x01
    uint8_t    bEndpointAddress; // 端點地址及輸入輸出屬性
    uint8_t    bmAttribute;      // 端點的傳輸類型屬性
    uint16_t   wMaxPacketSize;   // 端點收、發最大包的大小
    uint8_t    bInterval;        // Host 查詢端點的時間間隔
}
```

+ `bEndpointAddress`

    - Bit[3:0]: The endpoint number
    - Bit[6:4]: Reserved, reset to zero
    - Bit[7]: Direction (ignored if control endpoints)
        > + `0` = OUT endpoint
        > + `1` = IN endpoint

+ `bmAttributes`

    - Bit[1:0]: Transfer Type
        > + `00` = Control
        > + `01` = Isochronous
        > + `10` = Bulk
        > + `11` = Interrupt

    - Bit[3:2]: Synchronization Type
        > + `00` = No Synchronization
        > + `01` = Asynchronous
        > + `10` = Adaptive
        > + `11` = Synchronous

    - Bit[5:4]: Usage Type
        > + `00` = Data endpoint
        > + `01` = Feedback endpoint
        > + `10` = Implicit feedback Data endpoint
        > + `11` = Reserved

# Device Classes

## CDC (Communications Device Class)

CDC 是 USB 通信 Device 類的簡稱, 由 USB 組織定義專門給各種通信 Device (電信通信 Device 和中速網絡通信 Device )使用的 USB Class. <br>
大部分的作業系統都帶有支持 CDC Class 的 Device Driver, 可以自動識識 CDC 類的裝置, 這樣不僅免去了寫專用驅動裝置的負擔, 同時簡化了驅動裝置的安裝

## HID (Human Interface Device )

HID Device 屬於人性化介面的 Device , 用於操作電腦, e.g. USB Mouse, USB Keyboard, USB Touchpad, USB 軌跡球 ...等 Device. <br>
HID Device 不一定非要是這些人性化介面裝置, 只要符合 HID Device 的規範要求, 都可以認為是 HID Device.

使用 HID Device 的一個好處就是, 作業系統擁有 HID Class 的驅動程式, 而用戶無需去開發很麻煩的驅動程式, 只要直接使用 API 即可完成傳輸.
> 所以很多簡單的 USB Device, 喜歡定義成 HID Class, 這樣就可以不用安裝驅動而直接使用

## MSC (Mass Storage device Class)

MSC 是大容量存儲裝置 Class, 也是一種 PC 和 Mobile 之間的傳輸協議, 它允許透過 USB 來連接Host , 使兩者之間進行檔案傳輸.
> MSC 支援目前大多數的 OS, 許多舊版本的 OS 經過版本升級, 或者 System patch 也能支援 MSC.

MSC的通用性和操作簡單, 使它成為行動裝置上最常見的檔案系統,
> USB MSC 並不需要任何特定的 File System, 它提供了一個簡單的介面來讀寫插入的硬碟裝置

## [UAC (USB Audio Class)](note_usb_audio_class.md)

`UAC`(USB Audio Class) 有時也叫 `UAD`(USB Audio Device)

