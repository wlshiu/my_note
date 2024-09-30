Nuclei OpenOCD [[Back](n_riscv_intro.md#Nuclei_OpenOCD)]
---

Use pure OpenOCD to access DUT (GD32VF13: EVB= RV-START)

# RV-Start 環境建置

## Windows

> Environment `cmder`
> + SDK: nuclei-sdk-0.6.0
> + EVB: RV-Start

+ Set toolchain

    ```batch
    λ cd ...\nuclei-sdk-0.6.0\
    λ vi setup.bat
        ...
        set NUCLEI_TOOL_ROOT=<your\NucleiStudio\toolchain>
        ...
    λ .\setup.bat
    ```

+ Execute OpenOCD server
    > use cmder

    ```
    λ vi z_run_ocd_server.cmd
        @echo off

        openocd.exe -f ./openocd_gd32vf103.cfg

    λ .\z_run_ocd_server.cmd
        Open On-Chip Debugger 0.11.0+dev-02400-g1dac85c02 (2024-06-26-07:36)
        Licensed under GNU GPL v2
        For bug reports, read
                http://openocd.org/doc/doxygen/bugs.html
        Info : libusb_open() failed with LIBUSB_ERROR_NOT_FOUND
        Info : no device found, trying D2xx driver
        Info : D2xx device count: 2
        Info : Connecting to "(null)" using D2xx mode...
        Info : clock speed 5000 kHz
        Info : JTAG tap: riscv.cpu tap/device found: 0x1000563d (mfg: 0x31e (Andes Technology Corporation), part: 0x0005, ver: 0x1)
        Info : JTAG tap: auto0.tap tap/device found: 0x790007a3 (mfg: 0x3d1 (GigaDevice Semiconductor (Beijing) Inc), part: 0x9000, ver: 0x7)
        Warn : AUTO auto0.tap - use "jtag newtap auto0 tap -irlen 5 -expected-id 0x790007a3"
        Info : [riscv.cpu] datacount=4 progbufsize=2
        Info : coreid=0, nuclei debug map reg 00: 0x0, 16: 0x0, 32: 0x0
        Info : Examined RISC-V core; found 1 harts
        Info :  hart 0: XLEN=32, misa=0x40901105
        [riscv.cpu] Target successfully examined.
        Info : starting gdb server for riscv.cpu on 3333
        Info : Listening on port 3333 for gdb connections
        Info : device id = 0x19060410
        Info : flash size = 128kbytes
        semihosting is enabled

        Info : Listening on port 6666 for tcl connections
        Info : Listening on port 4444 for telnet connections
        Info : accepting 'telnet' connection on tcp/4444    <---- telnet port
    ```


+ Execute OpenOCD Client
    > use putty
    > + Connection type: Other, Telnet
    > + Host Name: localhost
    > + Port     : 4444

    + CLI interface

        ```
        Open On-Chip Debugger
        >
        ```

## OpenOCD Client Commands

### `mdw <address> <word cnt>`

> display memory (SRAM/eFlash) address with word values

```
Open On-Chip Debugger
> mdw 0x0 16
0x00000000: 1800006f 080003f2 080003f2 00000000 080003f2 080003f2 080003f2 00000000
0x00000020: 080003f2 080003f2 080003f2 080003f2 080003f2 080003f2 080003f2 080003f2

> mdw 0x08000000 16
0x08000000: 1800006f 080003f2 080003f2 00000000 080003f2 080003f2 080003f2 00000000
0x08000020: 080003f2 080003f2 080003f2 080003f2 080003f2 080003f2 080003f2 080003f2

```

### `mww <address> <word-value>`

> write memory (SRAM) address as <word-value>
>> 寫 flash 需要使用 Flash-loader

## `flash bank <name> <driver> <base> <size> <chip_width> <bus_width> <target> [driver_options]`

定義一個 Flash controller
> 掛上一個 flash descriptor, 讓 `erase`, `prog` 實例化

```
set _FLASHNAME stm32f1x.flash
set _TARGETNAME stm32f1x.cpu
set _FLASH_BASE_ADDR 0x08000000
set _FLASH_SIZE 0x20000   # size==0 => autodetect size
flash bank $_FLASHNAME stm32f1x $_FLASH_BASE_ADDR $_FLASH_SIZE 0 0 $_TARGETNAME

```

+ `bank` is a sub-command.
+ `<name> (MUST)`
    > 給定義的 flash band 一個 name

+ `<driver> (MUST)`
    > 要使用的 flash driver
    >> 搜尋 OpenOCD 內部支援的 flash control driver `openocd/src/flash/nor/drivers.c`

+ `<base> (MUST)`
    > DUT flash 燒寫的起始位址

+ `<size> (MUST)`
    > DUT flash 的最大 size (bytes)

### `flash write_image [erase] [unlock] filename [offset] [type]`

開始燒錄 Img 到 DUT Flash

```
# stm32f1x
flash write_image erase nuttx.bin 0x08000000

+ offset == 0x08000000 (eFlash Base Address of stm32f1x)
```

+ `write_image` is a sub-command.

+ `[erase] (optional)`
    > 表示在 Program Flash 前, 要先做 Sector Erase
+ `[unlock] (optional)`
    > 表示在 Program Flash 前, 要先做 Sector unlock

+ `filename (MUST)`
    > The path of an Img file

+ `[offset] (optional)`
    > flash 燒寫的起始位址

+ `[type] (optional)`
    > 可省略, OpenOCD 會 parsing img context
    > + `bin`
    > + `elf`
    > + `ihex`
    > + others...



### `flash verify_image filename [offset] [file_type]`

驗證 原檔案 與 燒錄資料 是否一致

+ `verify_image` is a sub-command.

+ `filename  (MUST)`
    > The path of an Img file

+ `[offset] (optional)`
    > flash 燒寫的起始位址

+ `[file_type] (optional)`
    > + `bin`
    > + `elf`
    > + `ihex`
    > + others...

### `program filename [preverify] [verify] [reset] [exit] [offset]`

將 flash 燒錄流程, 做高階整合, 使用 command options 來指定要做哪些步驟

+ `filename (MUST)`
    > The path of an Img-Bin file
    >> 只支援 bin file

+ `[verify] (optional)`
    > 在燒錄完後, 是否需要驗證燒錄的資料

+ `[reset] (optional)`
    > 燒錄完後, 是否將 Target 進行 Reset

+ `[exit] (optional)`
    > 燒錄完後, 是否直接結束 OpenOCD

+ `[offset] (optional)`
    > flash 燒寫的起始位址




