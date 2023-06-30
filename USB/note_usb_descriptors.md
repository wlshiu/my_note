USB Descriptors [[Back]](note_usb.md#USB-Descriptors)
---

# Standard USB Descriptor

## Device Descriptor

```c
/** Standard Device Descriptor */
struct usb_device_descriptor
{
    uint8_t     bLength;            /* Descriptor size in bytes = 18 */
    uint8_t     bDescriptorType;    /* DEVICE descriptor type = 1 */
    uint16_t    bcdUSB;             /* USB spec in BCD, e.g. 0x0200 */
    uint8_t     bDeviceClass;       /* Class code, if 0 see interface */
    uint8_t     bDeviceSubClass;    /* Sub-Class code, 0 if class = 0 */
    uint8_t     bDeviceProtocol;    /* Protocol, if 0 see interface */
    uint8_t     bMaxPacketSize0;    /* Endpoint 0 max. size */
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

```c
/** Standard Configuration Descriptor */
struct usb_configuration_descriptor
{
    uint8_t     bLength;             /* Descriptor size in bytes = 9 */
    uint8_t     bDescriptorType;     /* CONFIGURATION type = 2 or 7 */
    uint16_t    wTotalLength;        /* Length of concatenated descriptors */
    uint8_t     bNumInterfaces;      /* Number of interfaces, this config. */
    uint8_t     bConfigurationValue; /* Value to set this config. */
    uint8_t     iConfiguration;      /* Index to configuration string */
    uint8_t     bmAttributes;        /* Config. characteristics */
    uint8_t     bMaxPower;           /* Max.power from bus, 2mA units */
} __attribute__((packed));
```

## Interface Descriptor

```c
/** Standard Interface Descriptor */
struct usb_interface_descriptor
{
    uint8_t     bLength;            /* Descriptor size in bytes = 9 */
    uint8_t     bDescriptorType;    /* INTERFACE descriptor type = 4 */
    uint8_t     bInterfaceNumber;   /* Interface no.*/
    uint8_t     bAlternateSetting;  /* Value to select this IF */
    uint8_t     bNumEndpoints;      /* Number of endpoints excluding 0 */
    uint8_t     bInterfaceClass;    /* Class code, 0xFF = vendor */
    uint8_t     bInterfaceSubClass; /* Sub-Class code, 0 if class = 0 */
    uint8_t     bInterfaceProtocol; /* Protocol, 0xFF = vendor */
    uint8_t     iInterface;         /* Index to interface string */
} __attribute__((packed));
```


## Endpoint Descriptor

```c
/** Standard Endpoint Descriptor */
struct usb_endpoint_descriptor
{
    uint8_t     bLength;          /* Descriptor size in bytes = 7 */
    uint8_t     bDescriptorType;  /* ENDPOINT descriptor type = 5 */
    uint8_t     bEndpointAddress; /* Endpoint # 0 - 15 | IN/OUT */
    uint8_t     bmAttributes;     /* Transfer type */
    uint16_t    wMaxPacketSize;   /* Bits 10:0 = max. packet size */
    uint8_t     bInterval;        /* Polling interval in (micro) frames */
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



