USB Descriptors [[Back]](note_usb.md#USB-Descriptors)
---

# USB Device Requests

```
/* Table 9-2. Format of Setup Data */
struct usb_setup_packet
{
    /**
     *  Request type.
     *      + Bits[0:4] determine recipient,
     *          0 = Device
     *          1 = Interface
     *          2 = Endpoint
     *          3 = Other
     *          4...31 = Reserved.
     *      + Bits[5:6] determine type,
     *          0 = Standard
     *          1 = Class
     *          2 = Vendor
     *          3 = Reserved
     *      Bit 7 determines data transfer direction,
     *          0 = Host-to-device
     *          1 = Device-to-host
     */
    uint8_t bmRequestType;

    /**
     *  Request. If the type bits of bmRequestType are equal to
     *  Table 9-4. Standard Request Codes, then this field refers to below
     *        bRequest          Value
     *      - GET_STATUS          0
     *      - CLEAR_FEATURE       1
     *      - Reserved            2
     *      - SET_FEATURE         3
     *      - Reserved            4
     *      - SET_ADDRESS         5
     *      - GET_DESCRIPTOR      6
     *      - SET_DESCRIPTOR      7
     *      - GET_CONFIGURATION   8
     *      - SET_CONFIGURATION   9
     *      - GET_INTERFACE       10
     *      - SET_INTERFACE       11
     *      - SYNCH_FRAME         12
     *  For other cases, use of this field is application-specific. */
    uint8_t bRequest;

    /**
     *  Value. Varies according to request
     *  case 1: Descriptor Type and Descriptor Index
     *          the high byte is descriptor type (Table 9-5. Descriptor Types)
     *          and the descriptor index in the low byte.
     *              Table 9-5
     *              Descriptor Types           Value
     *              DEVICE                      1
     *              CONFIGURATION               2
     *              STRING                      3
     *              INTERFACE                   4
     *              ENDPOINT                    5
     *              DEVICE_QUALIFIER            6
     *              OTHER_SPEED_CONFIGURATION   7
     *              INTERFACE_POWER1            8
     */
    uint16_t wValue;

    /** Index. Varies according to request, typically used to pass an index or offset */
    uint16_t wIndex;

    /** Number of bytes to transfer */
    uint16_t wLength;
};
```

# Standard USB Descriptor

USB 定義了 Standard Descriptors, 包含了4 個層次
> + devices
> + configuration
> + interface
> + endpoint

```
├── Device Descriptor
│   ├── idVendor
│   ├── idProduct
│
├── Configuration Descriptor
│   ├── Interface Descriptor 1      <---- interface
│   │   ├── bInterfaceClass
│   │   ├── bInterfaceSubClass
│   │   ├── bInterfaceProtocol
│   │   ├── bNumEndpoints == 2
│   │   ├── ....
│   │   ├── Endpoint Descriptor 1   <---- EP
│   │   │   ├── bEndpointAddress
│   │   │
│   │   └── Endpoint Descriptor 2   <---- EP
│   │       ├── bEndpointAddress
│   │
│   ├── Interface Descriptor 2      <---- interface
│   │   ├── bInterfaceClass
│   │   ├── bInterfaceSubClass
│   │   ├── bInterfaceProtocol
│   │   ├── bNumEndpoints == 1
│   │   ├── ....
│   │   └── Endpoint Descriptor 3   <---- EP
│   │       ├── bEndpointAddress
│   │
│   ├── ...
│ 
```

每個 USB Device 都只會有一個 Device Descriptor, 主要是用來識別 USB 裝置 (idVendor/idProduct).

而 Configuration Descriptor 則會描述目前的 device 有多少個 interfaces
> 根據 Interface Descriptor 的 `class`和`subclass`, 可以區分 interface 類型,
比如 `video class == 14`, `audio class == 1` 等, 根據這些可以識別**復合裝置的 interface**

每個 Interface Descriptor 可以包含多個 `endpoints`, 每個 `endpoint` 有設定其特定的 address, `endpoint` 也是資料傳輸的通道
> 每個 endpoint 可以存在不同的資料格式, 比如使用多個 usb microphone, 有的 MIC 各自的 endpoint 對應一種格式(e.g. Mono/Stereo, 8/16 bits, 44.1/48 KHZ, ...etc),
但也有一個 endpoint 對應多種格式

+ Descriptor type (**bDescriptorType**)

    | Type                  | Descriptor                | Value |
    | :-                    | :-                        | :-    |
    | Standard Descriptor   | Device Descriptor         | 0x01  |
    | Standard Descriptor   | Configuration Descriptor  | 0x02  |
    | Standard Descriptor   | String Descriptor         | 0x03  |
    | Standard Descriptor   | Interface Descriptor      | 0x04  |
    | Standard Descriptor   | EndPont Descriptor        | 0x05  |
    | Class Descriptor      | Hub Descriptor            | 0x29  |
    | Class Descriptor      | HID Descriptor            | 0x21  |
    | Vendor Descriptor     |                           | 0xFF  |

+ Class Codes (**bDeviceClass**, **bInterfaceClass**)
    > 當 `bDeviceClass == 0x00`, 則 `bDeviceSubClass = bDeviceProtocol = 0`

    | Descriptor Usage    | Base Class Codes | Description
    | :-                  | :-               | :-
    | Device              | 00h              | Use class information in the Interface Descriptors
    | Interface           | 01h              | Audio
    | Device/Interface    | 02h              | Communications and CDC Control
    | Interface           | 03h              | HID (Human Interface Device)
    | Interface           | 05h              | Physical
    | Interface           | 06h              | Image
    | Interface           | 07h              | Printer
    | Interface           | 08h              | Mass Storage
    | Device              | 09h              | Hub
    | Interface           | 0Ah              | CDC-Data
    | Interface           | 0Bh              | Smart Card
    | Interface           | 0Dh              | Content Security
    | Interface           | 0Eh              | Video
    | Interface           | 0Fh              | Personal Healthcare
    | Interface           | 10h              | Audio/Video Devices
    | Device              | 11h              | Billboard Device Class
    | Interface           | 12h              | USB Type-C Bridge Class
    | Interface           | 13h              | USB Bulk Display Protocol Device Class
    | Interface           | 3Ch              | I3C Device Class
    | Device/Interface    | DCh              | Diagnostic Device
    | Interface           | E0h              | Wireless Controller
    | Device/Interface    | EFh              | Miscellaneous
    | Interface           | FEh              | Application Specific
    | Device/Interface    | FFh              | Vendor Specific

## Device Descriptor

Device Descriptor 是 USB Device 的第一個描述符, 每個 USB Devuce 都只有一個 Device Descriptor.
> 在 Device Descriptor 中, 包含了該 Device 的 `idVendor`, `idProduct`, `iSerialNumber`.
當使用多個 USB Device時, 可通過這些參數找到指定裝置.

```c
/** Standard Device Descriptor */
struct usb_device_descriptor
{
    uint8_t     bLength;            /* Descriptor size in bytes = 18 */
    uint8_t     bDescriptorType;    /* DEVICE descriptor type = 1 */
    uint16_t    bcdUSB;             /* USB spec in BCD, e.g. 0x0200 (USB 規範版號) */
    uint8_t     bDeviceClass;       /* Class code, if 0 see interface
                                     *  - if bDeviceClass == 0
                                     *      由每個 interface 定義自己的 Class 並各自獨立工作
                                     *  - if bDeviceClass == 0xFF
                                     *      則此裝置的 Class 由廠商自定義
                                     *  - if bDeviceClass == 0x1~0xFE
                                     *      為 USB-IF 定義的 DeviceClas, e.g. HID Devicd == 0x03, HUB Device == 0x09.
                                     *      在不同的 interface 上支援不同的 Class,
                                     *      並這些 interface 可能不能獨立工作
                                     */
    uint8_t     bDeviceSubClass;    /* Sub-Class code, 0 if class = 0 */
    uint8_t     bDeviceProtocol;    /* Protocol, if 0 see interface */
    uint8_t     bMaxPacketSize0;    /* Max packet size of EP_0 (only 8,16,32,64)*/
    uint16_t    idVendor;           /* Vendor ID per USB-IF */
    uint16_t    idProduct;          /* Product ID per manufacturer */
    uint16_t    bcdDevice;          /* Device release # in BCD */
    uint8_t     iManufacturer;      /* Index to manufacturer string */
    uint8_t     iProduct;           /* Index to product string */
    uint8_t     iSerialNumber;      /* Index to serial number string */
    uint8_t     bNumConfigurations; /* Number of possible configurations */
} __attribute__((packed));
```

## Device_Qualifier descriptor

```c
/** USB device_qualifier descriptor */
struct usb_device_qualifier_descriptor
{
    uint8_t     bLength;            /* Descriptor size in bytes = 10 */
    uint8_t     bDescriptorType;    /* DEVICE QUALIFIER type = 6 */
    uint16_t    bcdUSB;             /* USB spec in BCD, e.g. 0x0200 */
    uint8_t     bDeviceClass;       /* Class code, if 0 see interface */
    uint8_t     bDeviceSubClass;    /* Sub-Class code, 0 if class = 0 */
    uint8_t     bDeviceProtocol;    /* Protocol, if 0 see interface */
    uint8_t     bMaxPacketSize;     /* Endpoint 0 max. size */
    uint8_t     bNumConfigurations; /* Number of possible configurations */
    uint8_t     bReserved;          /* Reserved = 0 */
} __attribute__((packed));
```

## Configuration Descriptor

Configuration Descriptor 說明了一個特定組態的相關資訊.
取得 Device Descriptor 後, Host 就可以繼續去獲取 Device 的 **Configuration**, **Interface** 和 **Endpoint** Descriptor.
> 當 Host 請求 Configuration Descriptor 時, 返回的是所有相關的 Interface 和 Endpoint Descriptors

```c
/** Standard Configuration Descriptor */
struct usb_configuration_descriptor
{
    uint8_t     bLength;             /* Descriptor size in bytes = 9 */
    uint8_t     bDescriptorType;     /* CONFIGURATION type = 2 or 7 */
    uint16_t    wTotalLength;        /* Length of concatenated descriptors (資料總長度) */
    uint8_t     bNumInterfaces;      /* Number of interfaces of this config. (組態支援的介面數量)*/
    uint8_t     bConfigurationValue; /* Value to set this config. */
    uint8_t     iConfiguration;      /* Index to configuration string */
    uint8_t     bmAttributes;        /* Config. characteristics
                                      *     Bit[7]      保留, 必須置1
                                      *     Bit[6]      自供電模式
                                      *     Bit[5]      遠端喚醒
                                      *     Bit[4:0]    保留
                                      */
    uint8_t     bMaxPower;           /* Max power from bus(unit:2mA),
                                      *     Device 從 Bus 獲取的最大功耗 = bMaxPower * 2mA
                                      */
} __attribute__((packed));
```

## Interface Descriptor

Interface Descriptor 描述了組態中一個特定的介面資訊
> Configuration Descriptor 提供了一個或多個 Interface, 每個 Interface 都含有 **Class**, **SubClass**和 **Protocol** 的資訊,
以及 Interface 所使用的 Endpoint 數目

```c
/** Standard Interface Descriptor */
struct usb_interface_descriptor
{
    uint8_t     bLength;            /* Descriptor size in bytes = 9 */
    uint8_t     bDescriptorType;    /* INTERFACE descriptor type = 4 */
    uint8_t     bInterfaceNumber;   /* Interface No. (介面的編號)*/
    uint8_t     bAlternateSetting;  /* Value to select this IF (用來確認 bInterfaceNumber 的替代設定的編號)*/
    uint8_t     bNumEndpoints;      /* Number of endpoints excluding 0 */
    uint8_t     bInterfaceClass;    /* Class code, 0xFF = vendor */
    uint8_t     bInterfaceSubClass; /* Sub-Class code,
                                     *  if bInterfaceClass == 0
                                     *      bInterfaceSubClass = 0
                                     */
    uint8_t     bInterfaceProtocol; /* Protocol, 0xFF = vendor */
    uint8_t     iInterface;         /* Index to interface string (介面字串描述符的 index) */
} __attribute__((packed));
```


## Endpoint Descriptor

Endpoint Descriptor 描述了 USB 規範定義的端點資訊, 包含有 EP 的頻寬等資訊, 每一個 EP 都有自己的 Endpoint Descriptor.
Host 獲取 Endpoint Descriptor, 只能透過 Configuration Descriptor 的一部分返回, 不能直接用 `Get Descriptor`或者`Set Descriptor`請求訪問

```c
/** Standard Endpoint Descriptor */
struct usb_endpoint_descriptor
{
    uint8_t     bLength;          /* Descriptor size in bytes = 7 */
    uint8_t     bDescriptorType;  /* ENDPOINT descriptor type = 5 */
    uint8_t     bEndpointAddress; /* Endpoint # 0 - 15 | IN/OUT
                                   *    Bit[7]  : 0= H2D (OUT), 1= D2H (IN)
                                   *    Bit[3:0]: Address number
                                   */
    uint8_t     bmAttributes;     /* Transfer type
                                   * - Bit[1:0]
                                   *    0= Control 傳送
                                   *    1= Isochronous 傳送
                                   *    2= Bulk 傳送
                                   *    3= Interrupt 傳送
                                   */
    uint16_t    wMaxPacketSize;   /* Bits 10:0 = max. packet size */
    uint8_t     bInterval;        /* Polling interval in (msec) frames (查詢 EP 進行資料傳輸的間隔)
                                   *    unit: 1 msec or 125 us
                                   */
} __attribute__((packed));
```

## String Descriptor

```c
/** Unicode (UTF16LE) String Descriptor */
struct usb_string_descriptor
{
    uint8_t     bLength;
    uint8_t     bDescriptorType;
    uint16_t    bString;
} __attribute__((packed));
```



# Reference

+ [USB描述符【整理】](https://www.cnblogs.com/Daniel-G/p/3993904.html)
+ [USB開發基礎－－USB命令(請求)和USB描述符](http://www.baiheee.com/Documents/090518/090518112619.htm)
+ [USB-IF - Defined Class Codes](https://www.usb.org/defined-class-codes)


