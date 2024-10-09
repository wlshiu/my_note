jLink
---

The `VTref` pin is input mode in Official jLink
> `VTref` pin should link to VSS of DUT
>> 盜版反而用 `VTref` 來供電給 DUT

[SEGGER j-Link Pack](https://www.segger.com/downloads/jlink/#J-LinkSoftwareAndDocumentationPack)



# Setup Environment

## Windows

### jLink connet to DUT

```
> JLink.exe

SEGGER J-Link Commander V7.98g (Compiled Sep  5 2024 11:51:10)
DLL version V7.98g, compiled Sep  5 2024 11:50:17

Connecting to J-Link via USB...Updating firmware:  J-Link V11 compiled Sep  3 2024 10:40:48
Replacing firmware: J-Link V11 compiled May 28 2024 15:36:02
Waiting for new firmware to boot
New firmware booted successfully
O.K.
Firmware: J-Link V11 compiled Sep  3 2024 10:40:48
Hardware version: V11.00
J-Link uptime (since boot): 0d 00h 00m 00s
S/N: 601003134
License(s): RDI, FlashBP, FlashDL, JFlash, GDB
USB speed mode: High speed (480 MBit/s)
VTref=3.290V


Type "connect" to establish a target connection, '?' for help
J-Link>connect      <---- User type

Please specify device / core. <Default>: STM32F103RB
Type '?' for selection dialog
Device>STM32F103RB  <---- User type
Please specify target interface:
  J) JTAG (Default)
  S) SWD
  T) cJTAG
TIF>S               <---- User type
Specify target interface speed [kHz]. <Default>: 4000 kHz
Speed>
Device "STM32F103RB" selected.


Connecting to target via SWD
InitTarget() start
SWD selected. Executing JTAG -> SWD switching sequence.
DAP initialized successfully.
InitTarget() end - Took 9.24ms
Found SW-DP with ID 0x1BA01477
DPIDR: 0x1BA01477
CoreSight SoC-400 or earlier
Scanning AP map to find all available APs
AP[1]: Stopped AP scan as end of AP map has been reached
AP[0]: AHB-AP (IDR: 0x14770011, ADDR: 0x00000000)
Iterating through AP map to find AHB-AP to use
AP[0]: Core found
AP[0]: AHB-AP ROM base: 0xE00FF000
CPUID register: 0x411FC231. Implementer code: 0x41 (ARM)
Found Cortex-M3 r1p1, Little endian.
FPUnit: 6 code (BP) slots and 2 literal slots
CoreSight components:
ROMTbl[0] @ E00FF000
[0][0]: E000E000 CID B105E00D PID 001BB000 SCS
[0][1]: E0001000 CID B105E00D PID 001BB002 DWT
[0][2]: E0002000 CID B105E00D PID 000BB003 FPB
[0][3]: E0000000 CID B105E00D PID 001BB001 ITM
[0][4]: E0040000 CID B105900D PID 001BB923 TPIU-Lite
Memory zones:
  Zone: "Default" Description: Default access mode
Cortex-M3 identified.
J-Link>
```

## Ubuntu

### dependency

如果有缺 dependency lib

+ 查看 installed libs

    ```
    $ dpkg -l | grep libusb
    ```

+ libusb

    - apt install

        ```
        $ sudo apt install libusb
        ```

    - source code install

        ```
        $ tar jxvf libusb-1.0.21.tar.bz2
        $ cd libusb-1.0.21/
        $ ./configure  # ./configure --disable-udev
        $ make
        $ sudo make install
        ```

+ libreadline

    ```
    $ sudo apt-get install libreadline6-dev
    ```

### Install jlink deb

```
$ sudo dpkg -i xxxx.deb
```

+ 安裝在 `/opt/SEGGER/`
+ Run jlink

    ```
    $ JLinkExe
        SEGGER J-Link Commander V7. 0 (Compiled Apr  8 2021 14:33:59)
        DLL version V7.00, compiled Apr  8 2021 14:33:43

        Connecting to J-Link via USB...JLinkGUIServerExe: cannot connect to X server
        FAILED: Cannot connect to J-Link.
        J-Link>
    ```

# Reference

+ [RT-Thread-Ubuntu 18.04 JLink 下載韌體RT-Thread問答社區 - RT-Thread](https://club.rt-thread.org/ask/article/e9b65fc6241bc83b.html)

