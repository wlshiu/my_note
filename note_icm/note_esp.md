ESP
---

# SDK ESP-IDF

## Build System

提供 linux/windows/MacOs 三種平台開發

+ kconfiglib (kconfig python version)
    > 參數配置的前端, 使用

    - 藉由 defconfig 檔案, 可快速完成參數配置
    - 產生 `config.h`, 直接連結 compile options 和 source codes;
    不需額外撰寫 makefile (e.g. -Dxxx), 也便於 trace code
    - 使用 python 版本, 便於跨平台使用

+ CMake
    > 產生 makefile 的前端

    - 便於跨平台 (linux/windows)
    - 易於產生多種 IDE 的專案檔

        1. Unix makefile
        1. Eclipse
        1. Visual studio
        1. Ninja
    - 避免 user 直接接觸 makefile (magic symbols)

+ `idf.py`
    > ESP 自行研發的工具, 用來控制編譯流程, 並在不當使用時, 提供協助訊息

## Operating System

+ Non-OS (ESP8266)
    > 自 2019.12 起，將停止為 ESP8266 NonOS 新增任何功能.
    僅修復 ESP8266 NonOS 的關鍵 bug.
    所有更新僅在 master 分支進行，即基於 v3.0.0 的持續 bug 修復版本.

+ FreeRTOS
    > directly use FreeRTOS API
    
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

