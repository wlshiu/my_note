ESP
---

+ open source of SDK
    > 380 contrubuters on github


# Development Environment (ESP-IDF)

support Ubuntu/Windows/macOS

## ubuntu

+ dependency

    ```
    $ sudo apt install git wget flex bison gperf python3 python3-pip python3-setuptools cmake ninja-build ccache libffi-dev libssl-dev dfu-util
    $ cd esp-idf
    $ ./install.sh  # download toolchain
    ```

    - Python 3.7

        ```
        # add the deadsnakes PPA to sources list
        $ sudo add-apt-repository ppa:deadsnakes/ppa
        $ sudo apt install python3.7

        ```

        1. swithc python3 version

            ```
            $ sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
            $ sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 2
            $ sudo update-alternatives --config python3
                There are 2 choices for the alternative python3 (providing /usr/bin/python3).

                  Selection    Path                Priority   Status
                ------------------------------------------------------------
                * 0            /usr/bin/python3.6   2         auto mode
                  1            /usr/bin/python3.6   1         manual mode
                  2            /usr/bin/python3.7   2         manual mode

                Press <enter> to keep the current choice[*], or type selection number:

            $ sudo rm /usr/bin/python3
            $ sudo ln -s python3.7 /usr/bin/python3
            ```

    - 設置 Python 3 為默認 Python 版本

        ```
        $ sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && alias pip=pip3
        ```

## IDE plug-in

    - Eclipse
    - VS Code


## Build system

+ CMake
    - 連接不同的 build tool

        1. eclipse
        1. microsoft visual studio
        1. unix makefile
        1. ninja

    - 便於跨平台 (linux/windows)
    - 避免 user 直接接觸 makefile (magic symbols)

    - log

        ```
        $ cd esp-idf
        $ source ./export.sh
        $ cd esp-idf/examples/get-started/hello_world
        $ idf.py set-target esp32s2     # set target SoC
        $ idf.py build

        ...
        esptool.py v3.1-dev
        Generated /home/[user-name]/working/test/ESP/esp-idf/examples/get-started/hello_world/build/bootloader/bootloader.bin
        [675/983] Generating x509_crt_bundle
        /home/[user-name]/working/test/ESP/esp-idf/components/mbedtls/esp_crt_bundle/gen_crt_bundle.py:36: CryptographyDeprecationWarning: Python 2 is no longer supported by the Python core team. Support for it is now deprecated in cryptography, and will be removed in the next release.
          from cryptography import x509
        [983/983] Generating binary image from built executable
        esptool.py v3.1-dev
        Generated /home/[user-name]/working/test/ESP/esp-idf/examples/get-started/hello_world/build/hello-world.bin

        Project build complete. To flash, run this command:
        /home/[user-name]/.espressif/python_env/idf4.3_py3.7_env/bin/python ../../../components/esptool_py/esptool/esptool.py -p (PORT) -b 460800 --before default_reset --after hard_reset --chip esp32  write_flash --flash_mode dio --flash_size detect --flash_freq 40m 0x1000 build/bootloader/bootloader.bin 0x8000 build/partition_table/partition-table.bin 0x10000 build/hello-world.bin
        or run 'idf.py -p (PORT) flash'
        ```

        1. Selecting the Targe Chip

            > + `esp32 `
            >> SP32-D0WD, ESP32-D2WD, ESP32-S0WD (ESP-SOLO), ESP32-U4WDH, ESP32-PICO-D4

            > + `esp32s2`
            >> ESP32-S2

+ kconfig

    ```
    $ idf.py menuconfig
    ```

    - 藉由 defconfig 檔案, 可快速完成參數配置
    - 產生 `config.h`, 直接連結 compile options 和 source codes;
    不需額外撰寫 makefile (e.g. -Dxxx), 也便於 trace code

    - 使用 python 版本, 便於跨平台使用

+ `idf.py`
    > ESP 自行研發的工具, 用來控制編譯流程, 並在不當使用時, 提供協助訊息

+ Adding user to dialout
    > 讓 user 也能存取 `/dev/ttyUSB0`

    ```
    $ sudo usermod -a -G dialout $USER
    $ sudo reboot
    ```

## Operating System

+ Non-OS (ESP8266)
    > 自 2019.12 起, 將停止為 ESP8266 NonOS 新增任何功能.
    僅修復 ESP8266 NonOS 的關鍵 bug.
    所有更新僅在 master 分支進行, 即基於 v3.0.0 的持續 bug 修復版本.

+ FreeRTOS
    > directly use FreeRTOSv10 API

    - Dual Core

## Debug

+ app_trace
    > 使得用戶可以在程序運行開銷很小的前提下, 通過 JTAG 接口在主機和 ESP32 之間傳輸任意數據.
    `app_trace`可以將應用程序的運行狀態發送給主機, 在運行時接收來自主機的命令或者其他類型的信息.

    ![app_trace-overview](https://docs.espressif.com/projects/esp-idf/zh_CN/latest/esp32/_images/app_trace-overview.jpg)

    - 收集應用程序特定的數據
        > 基於 OpenOCD interface

    - 輕量級的日誌 (log)記錄
        > debug port 需要做字串解析, 不僅耗時還有可能改變了應用程序的行為, 使得問題無法復現.
        `app_trace`不完全解析字串, 而僅僅計算傳遞的參數的數, 並將相關 data 發送給主機.
        主機端會通過一個特殊的 Python 腳本來處理並打印接收到的日誌數據


    - 系統行為分析
        > 生成與 SEGGER SystemView 工具相兼容的跟蹤信息 (基於 OpenOCD interface)
        >> 目前僅能生成與 SystemView 格式兼容的文件, 無法使用該工具控制跟蹤的過程

        1. [SEGGER SystemView](https://www.segger.com/products/development-tools/systemview/) 是一種實時記錄和可視化工具, 用來分析應用程序運行時的行為
            > + [Time Line](https://www.segger.com/fileadmin/_processed_/5/8/csm_systemview-v3-timeline_9facf5fbd8.png)
            > + [CPU load](https://www.segger.com/fileadmin/images/products/SystemView/systemview-v3-cpuload.png)
            > + [Demo](https://www.segger.com/fileadmin/videos/SystemView.mp4)

+ [GDB Stub](https://github.com/mborgerson/gdbstub)
    > This is a simple GDB stub that can be easily dropped in to your project to allow you to debug a target platform using GDB.
    Communication between the stub and the debugger takes place via the
    [GDB Remote Serial Protocol](https://sourceware.org/gdb/onlinedocs/gdb/Remote-Protocol.html).

+ [Core Dump](https://docs.espressif.com/projects/esp-idf/zh_CN/latest/esp32/api-guides/core_dump.html)

    - Save core dump to flash
        > Core dumps are saved to special partition on flash

    - Print core dump to UART
        > Base64-encoded core dumps are printed on UART upon system panic.
        User should save core dump text body to some file manually (use tool espcoredump.py)

## Components

+ heap
    > Heap algorithm bases on [TLSF memory allocator  v3.1](https://github.com/jserv/tlsf-bsd)

+ Virtual file-system (VFS)

    ```
    // file description
    typedef struct esp_vfs {
        int     flags;
        int     (*open)(const char * path, int flags, int mode);
        int     (*close)(int fd);
        ssize_t (*read)(int fd, void * dst, size_t size);
        ssize_t (*write)(int fd, const void * data, size_t size);

        off_t   (*lseek)(int fd, off_t size, int mode);

        int     (*fstat)(int fd, struct stat * st);
        int     (*fsync)(int fd);

        int     (*mkdir)(const char* name, mode_t mode);
        int     (*rmdir)(const char* name);

        int     (*fcntl)(int fd, int cmd, int arg);
        int     (*ioctl)(int fd, int cmd, va_list args);
        ...
    } esp_vfs_t;
    ```

+ Partition Tables

    - 可創建自定義分區表
        > 以 CSV file 編寫分區表, 再藉由 `gen_esp32part.py` 實現 CSV 和二進制文件之間的轉換

        ```
        $ python gen_esp32part.py input_partitions.csv binary_partitions.bin
        $ python gen_esp32part.py binary_partitions.bin input_partitions.csv
        ```

    - 參數
        1. Name
            > partition name (< 16 char)
        1. Type
            > partition type (0x00 ~ 0xFE), `0x00 ~ 0x3F` 保留給 esp-idf 的核心功能

        1. SubType
            > 當 `Type == app`, SubType 可以指定為 factory (0), ota_0 (0x10) … ota_15 (0x1F) 或者 test (0x20)

            > 當 `Type == data`, SubType 可以指定為 ota (0), phy (1), nvs (2) 或者 nvs_keys (4)

        1. Offset
            > partition offset (64KB alignment), 偏移地址為空, 則會緊跟著前一個分區之後開始
            若為首個分區, 則將緊跟著分區表開始

        1. Size
            > partition size

        1. Flags
            > encrypted or not

+ ptherad

    - pthread_create/pthread_exit/pthread_cancel
    - pthread_join/pthread_detach
    - pthread_mutex_init/pthread_mutex_destroy
    - pthread_mutex_lock/pthread_mutex_unlock
    - pthread_mutex_timedlock/pthread_mutex_trylock
    - pthread_cond_init/pthread_cond_destroy
    - pthread_cond_signal/pthread_cond_broadcast
    - pthread_cond_wait/pthread_cond_timedwait

+ Wear Levelling


## 線上文件

+ [快速入門](https://docs.espressif.com/projects/esp-idf/zh_CN/latest/esp32/get-started/index.html#)
+ [與 ESP32 創建串口連接](https://docs.espressif.com/projects/esp-idf/zh_CN/latest/esp32/get-started/establish-serial-connection.html)


# ESP32-LyraT-Mini

+ source code

    ```
    $ mkdir -p $HOME/ESP && cd $HOME/ESP
    $ git clone --recursive https://github.com/espressif/esp-adf.git
    $ cd esp-adf
    $ echo 'source $HOME/ESP/esp-adf/esp-idf/export.sh' > setup.env
    $ echo 'export ADF_PATH=$HOME/ESP/esp-adf' >> setup.env
    $ source setup.env
    $ cd ./examples/get-started/play_mp3
    ```

+ Set config

    ```
    $ idf.py menuconfig
        Audio HAL
            -> Audio board
                -> ESP32-Lyrat-Mini V1.1
    ```

+ build project

    ```
    $ cd esp-adf/examples/get-started/play_mp3
    $ idf.py build
    ...
        [985/985] Generating play_mp3.bin
        esptool.py v2.8

        Project build complete. To flash, run this command:
        ../../../esp-idf/components/esptool_py/esptool/esptool.py -p (PORT) -b 460800 --after hard_reset write_flash --flash_mode dio --flash_size detect --flash_freq 40m 0x1000 build/bootloader/bootloader.bin 0x8000 build/partition_table/partition-table.bin 0x10000 build/play_mp3.bin
        or run 'idf.py -p (PORT) flash'
    ```

+ burn to flash

    ```
    $ idf.py -p /dev/ttyUSB0 flash    # default baud rate 460800, ubuntu don't enable minicom
        ...
        esptool.py v2.8
        Serial port /dev/ttyUSB0
        Connecting........_____....._____....._____....._____....._____....._____.
        Detecting chip type... ESP32
        Chip is ESP32D0WDQ5 (revision 1)
        Features: WiFi, BT, Dual Core, 240MHz, VRef calibration in efuse, Coding Scheme None
        Crystal is 40MHz
        MAC: bc:dd:c2:d1:f9:c0
        Uploading stub...
        Running stub...
        Stub running...
        Changing baud rate to 460800
        Changed.
        Configuring flash size...
        Compressed 25728 bytes to 15284...
        Wrote 25728 bytes (15284 compressed) at 0x00001000 in 0.3 seconds (effective 592.0 kbit/s)...
        Hash of data verified.
        Compressed 3072 bytes to 82...
        Wrote 3072 bytes (82 compressed) at 0x00008000 in 0.0 seconds (effective 2759.4 kbit/s)...
        Hash of data verified.
        Compressed 346176 bytes to 216638...
        Wrote 346176 bytes (216638 compressed) at 0x00010000 in 5.0 seconds (effective 556.2 kbit/s)...
        Hash of data verified.

        Leaving...
        Hard resetting via RTS pin...
        Done
    ```

## 線上文件

+ [ESP32-LyraT-Mini V1.2 入門指南](https://docs.espressif.com/projects/esp-adf/zh_CN/latest/get-started/get-started-esp32-lyrat-mini.html)


# reference

+ [快速入門](https://docs.espressif.com/projects/esp-idf/zh_CN/latest/esp32/get-started/index.html#)

