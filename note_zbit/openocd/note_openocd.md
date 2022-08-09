OpenOCD
---
OpenOCD, 原名為`Open On-Chip Debugger`, 為 **Dominic Rath** 在奧格斯堡應用技術大學的[畢業論文](https://openocd.org/files/thesis.pdf) 所做.

OpenOCD 目前所使用的授權為 **GNU General Public License version 2.0 (GPLv2)**, 其他詳細授權內容可以參考原始碼中的 README 中的說明

[OpenOCD - official](https://openocd.org/)
> 常用的參考文件
>> + [OpenOCD User's Guide](https://openocd.org/doc/html/index.html)
>> + [OpenOCD Developer's Guide](http://openocd.org/doc-release/doxygen/index.html)

# 簡易使用
---
先將 `.../tcl/target`, `.../tcl/interface`, 及 `openocd.exe`, 放入同一目錄中

## OpenOCD Server routine

> 連接到 Remote IC

```

$ openocd.exe -f interface/cmsis-dap.cfg -f target/stm32f1x.cfg
xPack OpenOCD, x86_64 Open On-Chip Debugger 0.11.0-00155-ge392e485e (2021-03-15-16:44)
Licensed under GNU GPL v2
For bug reports, read
        http://openocd.org/doc/doxygen/bugs.html
Info : auto-selecting first available session transport "swd". To override use 'transport select <transport>'.
Info : Listening on port 6666 for tcl connections
Info : Listening on port 4444 for telnet connections            <-------- Telent 的 Port
Info : CMSIS-DAP: SWD  Supported
Info : CMSIS-DAP: JTAG Supported
Info : CMSIS-DAP: FW Version = 2.0.0
Info : CMSIS-DAP: Interface Initialised (SWD)
Info : SWCLK/TCK = 1 SWDIO/TMS = 1 TDI = 1 TDO = 1 nTRST = 1 nRESET = 1
Info : CMSIS-DAP: Interface ready
Info : clock speed 1000 kHz
Info : SWD DPIDR 0x1ba01477
Info : stm32f1x.cpu: hardware has 6 breakpoints, 4 watchpoints
Info : starting gdb server for stm32f1x.cpu on 3333
Info : Listening on port 3333 for gdb connections               <-------- GDB 的 Port
```

+ Options

    + `-f, --file`
        > 指定 config file 的路徑, 如果沒有設定的話, **OpenOCD 預設會開啟 openocd.cfg**

    + `-d, --debug`
        > Level 數字 `-3 ~ 3`, 從 LOG_LVL_SILENT(-3) ~ LOG_LVL_DEBUG(3)
        >> 現在多了一個 LOG_LVL_DEBUG_IO(4) 的 Level 用來底層 I/O 除錯用

    + `-l, --log_output`
        > Log file 的路徑, 預設會直接打印在 OpenOCD 的 console 上, 加上這個可以把 log 導向檔案中

    + `-s, --search`
        > the directory to search config files and scripts

    + `-c, --command`
        > 執行 <command>

        ```
        $ openocd.exe -f interface/cmsis-dap.cfg -f target/stm32f1x.cfg -c -c "verify reset exit;"
        ```

## Telnet Connect to OpenOCD Server

```
# telnet <host> <port>
$ telnet localhost 4444
Trying ::1...
Connection failed: Connection refused
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
Open On-Chip Debugger
>
```

經由 telnet 來進行操作

+ Commands
    > OpenOCD 提供許多 commands 來與 Remote 溝通, 可參考 `OpenOCD User’s Guide`
    > + `12 Flash Commands`
    > + `15 General Commands`

    - Commands 可經由 `Jim-TCL` 語法撰寫成 script, 藉 telnet 來傳送執行


# 名詞解釋

+ target
    > 指 Remote IC; multi-core 等於多重 targets
    >> 一個 target 就會配上一個 GDB Server, 也就是說一個 target 就會有一個對應的 GDB Port

    - [target list](https://openocd.org/doc/html/CPU-Configuration.html#CPU-Configuration)
        > `11.2 Target CPU Types`

+ [Jim-Tcl](https://link.zhihu.com/?target=http%3A//jim.tcl.tk)
    > OpenOCD 使用了一種名為 Jim-TCL 的小型 TCL 解析器, 提供了簡單和可擴展的命令解析器.
    >> Jim-Tcl 是著名的 Tcl 語言的精簡版本 (Jim-Tcl 的功能要少得多)

# Command Overview

## Setup (Server & Debug Adapter Configuration)

+ Server Configuration
    > 這邊主要是設定一些 TCP/IP port number 相關的Command, 為了跟 GDB 溝通

    - `gdb_port [number]`
        > 設定 OpenOCD 連接 GDB 的 Port number, 不指定的話, 預設號碼為`3333`

    - `telnet_port [number]`
        > 一個 OpenOCD 只會有一個 Telnet Server, 但不同於 GDB 一個 Port 僅能容許一個 connetion,
        Telent 可同時接受多個 Connection (Multi-Ports control)

+ Debug Adapter Configuration
    > 主要是針對 Debug Adapter (e.g. GDB)去做設定

    - `interface <name>`
        > 與 remote 溝通的 protocol, e.g cmsis-dap, jlink, stlink-v2, ...etc.

    - `adapter_khz <kHz>`
        > 設定 Adapter 連結 Target (IC)的時候, 所使用的最高(快)速度, 以 `KHz`為單位,
        >> 設定 `adapter_khz 3000`, 就表示目前 JTAG Clock 為 3MHz

        1. `adapter_khz 0` 表示啟動 RTCK
            > [FAQ RTCK](http://openocd.org/doc/html/FAQ.html#faqrtck)




## TAP Declaration

TAPs 全名為`Test Access Ports`, 為 JTAG 中的核心部分, 而 OpenOCD 在連結 Target 的時候, 必須要知道相關的設定才能夠正確的連接

## CPU Configuration

針對連接 Target 所需要設定的部分

+ `target create <target_name> <type> [configparams]`

    ```jim-tcl
    set _CHIPNAME riscv
    set _TARGETNAME $_CHIPNAME.cpu
    target create $_TARGETNAME riscv -chain-position $_TARGETNAME
    ```

    - `<target_name>`
        >

    - `<type>`
        > type 名稱是由 Source Code 中所定義的, 參考 [Target CPU Types](https://openocd.org/doc/html/CPU-Configuration.html#CPU-Configuration)
        >> stm32f4x 在 OpenOCD 要使用 `cortex_m`

        1. 查詢 target list

            ```
            # Telent
            > target types
                arm7tdmi arm9tdmi arm920t arm720t arm966e arm946e arm926ejs fa526 feroceon dragonite xscale cortex_m cortex_a cortex_r4
                arm11 ls1_sap mips_m4k avr dsp563xx dsp5680xx testee avr32_ap7k hla_target nds32_v2 nds32_v3 nds32_v3m or1k quark_x10xx
                quark_d20xx stm8 riscv mem_ap esirisc arcv2 aarch64 mips_mips64
            >

            ```

+ `<$target_name> configure [config params]`

    ```jim-tcl
    set _CHIPNAME riscv
    set _TARGETNAME $_CHIPNAME.cpu
    $_TARGETNAME configure -work-area-phys 0 -work-area-size 0x10000 -work-area-backup 1
    ```

    - [config params]

        1. `-endian (big|little)`

        1. work-area
            > OpenOCD 在進階使用的時候, 可以利用 target 上一小部分的空間, 運作小小的 program, 來加速 debug 或是其他功能
            > + `-work-area-size`: 標明可以使用的空間大小 (unit: bytes)
            > + `-work-area-phys <address>`: 當沒有 MMU 時, 空間的實體位置(physical address)
            > + `-work-area-backup (0|1)`: 由於 OpenOCD 使用到這空間的時候, 會覆蓋掉原本上面的 Data, 這邊可選擇是否需要先備份起來(會拖慢速度)

+ `-event`, Hook Target Event
    > OpenOCD 允許在某些事件發生後, 執行預先 Hook 好的那些指令, 例如以下的情況:
    > + 當 GDB 連線上時, 先設定好一些 Server 相關的設定
    > + Target Reset 前/後, 執行預先定義好的設定
    > + others...

    - 常用的 Events
        > + `debug-halted`: 當 Target 進入 Debug Mode 時候, 比方說踩到 breakpoint 時
        > + `debug-resumed`: 當 GDB 將 Target 進入 Resume 時
        > + `gdb-attach`: GDB 連線時
        > + `gdb-detach`: GDB 斷線後
        > + `halted`: Target 進入 halted 後
        > + `reset-assert`: 假如需要特別方式來做 SRST 時
        > + `reset-deassert-post`: SRST 釋放後
        > + others...

        ```jim-tcl
        ## hook event 'reset-start'
        $_TARGETNAME configure -event reset-start {
            # Reduce speed since CPU speed will slow down to 16MHz with the reset
            # 在 Reset 之前, 先將 Adapter 的速度降至 2 MHz
            adapter_khz 2000
        }
        ```


## Gernal Commands

+ `interface_list`
    > 查看目前 OpenOCD 所支援的 Adapter 清單

    ```
    # Telent
    > interface_list
    The following debug interfaces are available:
    1: ftdi
    2: hla
    ```

+ `poll [on|off]`
    > OpenOCD 會定期去 Polling(輪詢) Target 的狀況, 這邊可以開或關閉這項功能

+ `targets [name]`

+ `sleep msec [busy]`
    > 等待一定時間後, 再繼續做下去; 通常用在 `Target Event`中使用, 用來控制時序
    >> 如果使用 `busy`的話, OpenOCD 會使用 busy-waiting (blocking)的方式

+ `halt [ms]`
    > 讓 Target 進入 halt 的狀態, OpenOCD 會等待 `ms` 或是預設的 5 秒
    > 如果設定 **0ms** 的話, OpenOCD 則不會進行等待

+ `resume [address]`
    > 讓 Target 在指定的 address 做 Resume, 並從那個 address 開始繼續執行下去
    > 如果不指定 Address 的話, 則從 Halt 當下的位置開始執行下去

+ `reset run`
    > 先 Reset 後, 再讓 Target 進入 Free-Run 的狀態

+ `reset halt`
    > 先 Reset 後再讓 Target 進入 Halt 的狀態

+ `debug_level [n]`
    > 設定 debug log level, `-3 ~ 4`

+ `log_output [filename]`
    > redirect log message to **filename**

+ `exit`
    > leave telnet connetion

+ `help`
    > list all commands

    - `help  [command]`
        > display the specific command description

## Flash Commands

+ `flash bank <name> <driver> <base> <size> <chip_width> <bus_width> <target> [driver_options]`
    > 主要用在定義一個 Flash 內的 Bank

    ```jim-tcl
    set _CHIPNAME riscv
    set _TARGETNAME $_CHIPNAME.cpu

    #
    # 這邊標示出, 有個 Bank 叫 'spi0', 需要使用 fespi 來驅動, Bank 的 base address 在 0x40000000
    # 最後面的 0x20004000 則是 fespi 需要的參數
    #
    flash bank spi0 fespi 0x40000000 0 0 0 $_TARGETNAME 0x20004000
    ```

    - `name`
        > 給的方便使用的名稱

    - `driver`
        > 需要使用哪套 Flash Driver (driver name) 來操作這塊 Bank

    - `base`
        > Bank 的 Based Address

    - `size`
        > Bank 的大小 (可以不指定, 但要補上 0)

    - `chip_width`
        > 用來標示這個 Chip 的 bandwidth, **目前大部分的 Driver 都不需要指定**
    - `bus_width`
        > 用來標示 Data bus 的頻寬, **目前大部分的 Driver 都不需要指定**
    - `target`
        > 用來標示這個 Bank 屬於哪個 Target

    - `driver_options`
        > 如果 Flash Driver 的需要其他參數, 可以接在後面這邊

+ `flash write_image [erase] [unlock] filename [offset] [type]`
    > 主要用在燒錄 Flash 上

    ```
    # Telent
    > flash write_image erase hello.elf
    ```

    - `erase`
        > 表示在 Program 這個 Flash 之前, 要先將 Sector 做 Erase

    - `unlock`
        > 表示在 Program 這個 Flash 之前, 要先將 Sector unlock

    - `filename`
        > Image 的檔名
    - `offset`
        > 燒錄的偏移量
        >> 從定義的 Based Address 開始

    - `type`
        > Image的檔案類型
        > + `bin`: Binary 檔案
        > + `elf`: ELF 檔案
        > + others...

+ `program filename [verify] [reset] [exit] [offset]`
    > 用來燒錄 Flash 的 Command; 基本上他把燒錄的動作簡化, 並可以在燒錄完畢後, 執行其他指定的動作

    ```
    # Telent
    > program hello.bin 0x08000000 verify reset exit
    > program hello.elf verify reset exit   <---- LMA 紀錄在 ELF file

    ```

    - `filename`
        指定 Image 的檔案名稱

    - `verify`
        > 在燒錄完畢後, 是否需要驗證燒錄的資料

    - `reset`
        > 燒錄完畢後, 將 Target 進行 Reset

    - `exit`
        > 燒錄完畢後, 直接結束 OpenOCD

    - `offset`
        > 燒錄的偏移量


# [OpenOCD-Software-Architecture](note_openocd_sw_arch.md)

# [實務範例操作](note_openocd_practice.md)
---
+ [OpenOCD- github](https://github.com/openocd-org/openocd)
+ [README.Windows](http://openocd.org/doc-release/README.Windows)
+ [RISC-V OpenOCD](https://github.com/riscv/riscv-openocd.git)

# Reference
---
+ [系統架構秘辛：瞭解RISC-V 架構底層除錯器的秘密！ 系列](https://ithelp.ithome.com.tw/users/20107327/ironman/1359)
+ [*OpenOCD添加第三方設備支持:HT32F52352 Cortex-M0+](https://chowdera.com/2022/02/202202181344586473.html)

