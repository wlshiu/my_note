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

## Ubuntu

### Setup environment

+ add toolchain path to `.bashrc`

+ `lsusb` 檢查是否有偵測到 USB ICE (base on FTDI chip)

    ```
    $ lsusb
        Bus 002 Device 002: ID 0403:6010 Future Technology Devices International, Ltd FT2232C/D/H Dual UART/FIFO IC
        Bus 002 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
        Bus 001 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
    ```

+ 檢查驅動程式是否安裝

    ```
    $ lsmod | grep 'ftdi'
        ftdi_sio               69632  0
        usbserial              69632  1 ftdi_sio
    ```

+ Set udev rules
    > 讓 USB 能被當作 plugdev group 存取

    ```
    $ sudo vi /etc/udev/rules.d/99-openocd.rules
        // Use vi command to edit the file, and add the following lines
        SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE="666", GROUP="plugdev"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="666", GROUP="plugdev"
    ```

    - 確認 udev 是否為 `plugdev group`

        ```
        $ ls -l /dev/ttyUSB1    # check udev is 'plugdev' group
            crw-rw-r-- 1 root plugdev 188, 1 Nov 28 12:53 /dev/ttyUSB1
        ```

    - 執行 udev rules

        ```
        $ sudo /etc/init.d/udev restart
        ```

+ user account 加入 `plugdev group`

    ```
    $ sudo usermod -a -G plugdev <your_user_name>
    ```

    - 確認是否在 group 中

        ```
        $ grep '^<group_name>:' /etc/group
        ```


+ Com-port log

    - `picocom`
        > `$ sudo apt install picocom`

        1. execute
            > leader key: `C-a`

            ```
            $ picocom -b 115200 /dev/ttyUSB1
                picocom v3.1

                port is        : /dev/ttyUSB1
                flowcontrol    : none
                baudrate is    : 115200
                parity is      : none
                databits are   : 8
                stopbits are   : 1
                escape is      : C-a
                local echo is  : no
                noinit is      : no
                noreset is     : no
                hangup is      : no
                nolock is      : no
                send_cmd is    : sz -vv
                receive_cmd is : rz -vv -E
                imap is        :
                omap is        :
                emap is        : crcrlf,delbs,
                logfile is     : none
                initstring     : none
                exit_after is  : not set
                exit is        : no

                Type [C-a] [C-h] to see available commands
                Terminal ready

            ```

    - `minicom`
        > `$ sudo apt install minicom`

        1. execute
            > leader key: `C-a`

            ```
            $ minicom -s    <---- 進入 configuraion 介面 (第一次執行時使用)
            $ minicom       <---- 直接執行
            ```

        1. 非正常關閉 minicom, 會在`/var/lock`下建立幾個檔案`LCK*`, 這幾個檔案阻止了 minicom 的運行, 將它們刪除後即可恢復

        1. hot key
            > + `exit`: <C-a> x
            > + `re-configurate`: <C-a> o
            > + `help`: <C-a> z
            >> 每個操作都需要加上 `leader key`

### Build/Run/Debug on DUT

+ Build SDK

    ```
    $ cd nuclei-sdk-0.6.0
    $ vi z_build_gd32vf103.sh
        #!/bin/bash

        help()
        {
            echo "usage: $0 <op-target>"
            echo "<op-target>:"
            echo "  all   : build all"
            echo "  debug : gdb debug"
            echo "  upload: download img to flash"
            echo "  clean : build clean"
            exit -1;
        }

        if [ $# -lt 1 ]; then
            help
        fi

        #
        # example:
        # make SOC=gd32vf103 BOARD=gd32vf103v_rvstar PROGRAM=application/baremetal/helloworld clean all
        #
        make SOC=gd32vf103 BOARD=gd32vf103v_rvstar $*

    $ chmod +x ./z_build_gd32vf103.sh
    $ ./z_build_gd32vf103.sh clean all
    ```

+ Run program

    ```
    $ ./z_build_gd32vf103.sh upload
        or
    $ ./z_build_gd32vf103.sh debug   <---- run GDB
    ```

+ com-port log

    ```
    $ minicom -s
        ...

        | A -    Serial Device      : /dev/ttyUSB1        |
        | B - Lockfile Location     : /var/lock           |
        | C -   Callin Program      :                     |
        | D -  Callout Program      :                     |
        | E -    Bps/Par/Bits       : 115200 8N1          |

        ....
    ```

    ```
    Welcome to minicom 2.8

    OPTIONS: I18n
    Port /dev/ttyUSB1, 16:23:20

    Press CTRL-A Z for help on special keys

    Nuclei SDK Build Time: Oct  8 2024, 15:28:32
    Download Mode: FLASHXIP
    CPU Frequency 108000000 Hz
    ClustNuclei SDK Build Time: Oct  8 2024, 16:21:15
    Download Mode: FLASHXIP
    CPU Frequency 108000000 Hz
    Cluste
    Nuclei SDK Build Time: Oct  8 2024, 16:21:15
    Download Mode: FLASHXIP
    CPU Frequency 108000000 Hz
    Cluster 0, Hart 0, MISA: 0x40901105
    MISA: RV32IMACUX
    Got rand integer 4194299 using seed 1371103357.
    0: Hello World From Nuclei RISC-V Processor!
    1: Hello World From Nuclei RISC-V Processor!
    2: Hello World From Nuclei RISC-V Processor!
    3: Hello World From Nuclei RISC-V Processor!
    4: Hello World From Nuclei RISC-V Processor!
    5: Hello World From Nuclei RISC-V Processor!
    6: Hello World From Nuclei RISC-V Processor!
    7: Hello World From Nuclei RISC-V Processor!
    8: Hello World From Nuclei RISC-V Processor!
    9: Hello World From Nuclei RISC-V Processor!
    10: Hello World From Nuclei RISC-V Processor!
    11: Hello World From Nuclei RISC-V Processor!
    12: Hello World From Nuclei RISC-V Processor!
    13: Hello World From Nuclei RISC-V Processor!
    14: Hello World From Nuclei RISC-V Processor!
    15: Hello World From Nuclei RISC-V Processor!
    16: Hello World From Nuclei RISC-V Processor!
    17: Hello World From Nuclei RISC-V Processor!
    18: Hello World From Nuclei RISC-V Processor!
    19: Hello World From Nuclei RISC-V Processor!
    ```


### Pure OpenOCD CLI

+ OpenOCD Server

    ```
    $ openocd -d2 -f ./openocd_gd32vf103.cfg
        Open On-Chip Debugger 0.11.0+dev-02400-g1dac85c02 (2024-06-26-07:32)
        Licensed under GNU GPL v2
        For bug reports, read
                http://openocd.org/doc/doxygen/bugs.html
        debug_level: 2

        Info : Using libusb driver
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
        Info : accepting 'telnet' connection on tcp/4444
        Info : dropped 'telnet' connection
    ```

    - bash script

        ```
        $ vi ./z_ocd_server.sh
            #!/bin/bash

            help()
            {
                echo "usage: $0 <cfg file>"
                exit -1;
            }

            if [ $# != 1 ]; then
                help
            fi

            cfg_file=$1

            openocd -d2 -s ./script/ -f ${cfg_file}
        ```

+ OpenOCD Client

    - putty

        ```
        Host Name: localhost
        Port: 4444
        Connection type: Other -> Telnet
        ```

    - ubuntu terminal

        ```
        $ vi ./z_ocd_client.sh
            #!/bin/bash

            telnet localhost 4444

        $ chmod +x ./z_ocd_client.sh
        $ ./z_ocd_client.sh
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

### `flash bank <name> <driver> <base> <size> <chip_width> <bus_width> <target> [driver_options]`

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


    - `driver == custom` type 是由 Nuclei OpenOCD 自行實作
        > 當不想 re-build openocd, 但是想增加自己的 flash loader

        ```
        # openocd flash bank configure command(only parameters in parentheses can be modified)
        # For detail flash bank explaination, see openocd/doc/pdf/openocd.pdf
        #
        # flash bank  <name>    <driver>  <base>    <size> <chip_width> <bus_width>  <target>    <spi_base>  <flashloader_path> [simulation] [sectorsize=]
        > flash bank $FLASHNAME  custom  <xip_base>   0        0            0       $TARGETNAME  <spi_base>  <loader_path>      [simulation]


        # openocd flash bank configure example
        # Please change 0x20000000
        #   - the spiflash xip address to the real address of your spiflash xip address
        # please change 0x10014000
        #   - the spi base to access the spiflash to the real spi base to access your spiflash or some other value required by you
        #
        # please change </path/to/loader.bin> to the real path of your flash loader binary
        > flash bank $FLASHNAME custom 0x20000000 0 0 0 $TARGETNAME 0x10014000 </path/to/loader.bin>

        # while [simulation] exist, the loader's timeout=0xFFFFFFFF
        > flash bank $FLASHNAME custom 0x20000000 0 0 0 $TARGETNAME 0x10014000 /path/to/loader.bin simulation
        ```

        1. `<flashloader_path>`
            > 執行程式的最初 directory 為 `srcroot`, e.g. 執行 make 的最初目錄為 `srcroot`, `<flashloader_path>` 為從 `srcroot` 開始的相對路徑


+ `<base> (MUST)`
    > DUT flash 燒寫的起始位址

    ```c
    flash_err_t flash_erase(uint32_t *fmc_base, uint32_t start_addr, uint32_t end_addr)
    {
        uint32_t   dut_addr_start = <base> + start_addr;
        uint32_t   dut_addr_end   = <base> + end_addr;
        ...
    }
    ```

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

    ```c
    flash_err_t flash_write(uint32_t *fmc_base, uint8_t *pBuffer, uint32_t offset, uint32_t nbytes)
    {
        /* flash bank <name> <driver> <base> <size> <chip_width> <bus_width> <target> [driver_options] */
        uint32_t   dut_addr_start = <base> + offset;
        ...
    }
    ```


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

    ```c
    flash_err_t flash_write(uint32_t *fmc_base, uint8_t *pBuffer, uint32_t offset, uint32_t nbytes)
    {
        /* flash bank <name> <driver> <base> <size> <chip_width> <bus_width> <target> [driver_options] */
        uint32_t   dut_addr_start = <base> + offset;
        ...
    }
    ```

+ `[file_type] (optional)`
    > + `bin`
    > + `elf`
    > + `ihex`
    > + others...

### `program filename [preverify] [verify] [reset] [exit] [offset]`

將 flash 燒錄流程, 做高階整合, 使用 command options 來指定要做哪些步驟

```
# program and verify using elf/hex/s19. verify and reset
# are optional parameters
openocd -f board/stm32f3discovery.cfg \
	-c "program filename.elf verify reset exit"

# binary files need the flash address passing
openocd -f board/stm32f3discovery.cfg \
	-c "program filename.bin exit 0x08000000"
```

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

    ```c
    flash_err_t flash_write(uint32_t *fmc_base, uint8_t *pBuffer, uint32_t offset, uint32_t nbytes)
    {
        /* flash bank <name> <driver> <base> <size> <chip_width> <bus_width> <target> [driver_options] */
        uint32_t   dut_addr_start = <base> + offset;
        ...
    }
    ```

## Tips

### 找 cfg 檔案路徑

```
$ openocd
    Open On-Chip Debugger 0.10.0-dev-00250-g9c37747 (2016-04-07-22:20)
    Licensed under GNU GPL v2
    For bug reports, read
      http://openocd.org/doc/doxygen/bugs.html
    embedded:startup.tcl:60: Error: Can't find openocd.cfg
    in procedure 'script'
    ...
```

利用 `strace` 來 Debug

```
$ strace -f openocd 2>&1  | grep cfg
    open("openocd.cfg", O_RDONLY)           = -1 ENOENT (No such file or directory)
    open("~/.openocd/openocd.cfg", O_RDONLY) = -1 ENOENT (No such file or directory)
    open("/usr/local/share/openocd/site/openocd.cfg", O_RDONLY) = -1 ENOENT (No such file or directory)
    open("/usr/local/share/openocd/scripts/openocd.cfg", O_RDONLY) = -1 ENOENT (No such file or directory)
    write(2, "embedded:startup.tcl:60: Error: "..., 118embedded:startup.tcl:60: Error: Can't find openocd.cfg
```

從輸出訊息可以知道, openocd 會依下面的順序讀取`openocd.cfg`
> + `./openocd.cfg`
> + `~/.openocd/openocd.cfg`
> + `/usr/local/share/openocd/site/openocd.cfg`
> + `/usr/local/share/openocd/scripts/openocd.cfg`


# Reference

+ [Install the Debugger Driver in Linux PC](https://doc.nucleisys.com/nuclei_board_labs/hw/hw.html#on-board-debugger-driver)
+ [使用strace找出程式缺少的檔案路徑 - My code works, I don’t know why.](https://wen00072.github.io/blog/2016/04/10/use-strace-to-trace-missing-files/)
