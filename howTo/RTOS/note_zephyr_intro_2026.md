[初識 Zephyr RTOS:從源碼結構到設計哲學](https://openeuler.csdn.net/6a07f815662f9a54cb74e669.html)
---

# Zephyr RTOS 是什麼 ?

Zephyr 是 Linux 基金會旗下的開源即時作業系統(RTOS). 它於 2016 年由 Intel、NXP、Nordic 等廠商共同發起,
目前已成為嵌入式領域中最具活力的 RTOS 專案之一.

## 核心特徵

+ 多架構支援.
    > Zephyr 支援 ARM(Cortex-M/R/A)、x86、RISC-V、ARC、Xtensa、MIPS、SPARC 等十多種 CPU 架構,
    涵蓋了從資源有限的 MCU(如 Cortex-M0+, 約 8KB RAM)到具有 MMU 的 MPU(如 Cortex-A)在內的各種硬體平臺.

+ 完整的平臺體系.
    > Zephyr 不僅僅是一個內核調度器. 它內建了
    > + 驅動模型
    > + 設備樹(Devicetree)
    > + Kconfig 配置系統
    > + 建構系統(CMake + west)
    > + 網路協議棧
    > + 藍牙協議棧
    > + 檔案系統
    > + Shell
    > + 日誌子系統
    > + USB 協議棧
    > + 電源管理
    > + 其他等一整套平臺級組件

    > 這正是它與 FreeRTOS 等純內核 RTOS 最本質的區別 (後文將詳細說明).

+ 模組化與可配置性.
    > 透過 Kconfig 選單系統, 你可以在編譯前精確地調整核心與子系統的組成(不必要的模組不會被編譯進去), 從而避免額外的程式碼開銷.

+ 上游優先.
    > Zephyr 強調**板級代碼**和**驅動程式**應盡量合併到上游主線中, 以減少廠商自行分叉代碼的行為, 避免生態系統的碎片化.

+ 開源治理.
    > 採用 Apache 2.0 授權許可證, 由 Linux 基金會技術指導委員會管理, Intel、NXP、Nordic、ST、TI 等均為白金/銀牌成員.

# Zephyr 源碼目錄結構

以下是 Zephyr 主倉庫的頂層目錄結構及各目錄的職責說明:

```
zephyr/
├── arch/                   # 架構相關代碼
├── boards/                 # 板級支持
├── cmake/                  # CMake 構建腳本
├── doc/                    # 官方文檔(RST/Sphinx)
├── drivers/                # 設備驅動
├── dts/                    # 設備樹源文件和綁定
├── include/                # 公共頭文件
├── kernel/                 # 內核核心實現
├── lib/                    # 通用庫
├── modules/                # 外部模塊(HAL、MCUboot 等)
├── samples/                # 示例程序
├── scripts/                # 工具腳本
├── share/                  # 共享資源
├── soc/                    # SoC 級定義和初始化
├── subsys/                 # 子系統
├── tests/                  # 測試用例
├── CMakeLists.txt          # 頂層 CMake
├── Kconfig                 # 頂層 Kconfig
└── west.yml                # 多倉庫管理清單
```

## 逐目錄說明

### `arch/` (架構層)
包含不同 CPU 架構的底層實現:

|子目錄                   | 說明                                                    |
|:-                      | :-                                                      |
|arch/arm/core/          |  ARM 架構的啟動代碼、異常/中斷向量、上下文切換、堆疊初始化     |
|arch/arm/core/cortex_m/ |  Cortex-M 專項：NVIC 設定、MPU 支持、SysTick、浮點上下文     |
|arch/x86/               |  x86 架構(Intel 處理器), 包含 MMU、IOAPIC 等              |
|arch/riscv/             |  RISC-V 架構, 支援 RV32/RV64, 以及 MMU 和 CLIC 中斷控制器 |

架構層的責任是: 讓內核和驅動程式不必在意 CPU 之間的差異.
> 架構層負責處理
> + 啟動序列 (boot flow)
> + 線程切換的彙編碼 (context switch)
> + 特權級別切換 (privilege mode)
> + MMU/MPU 的配置 (memory mapping)
> + 異常處理等 (exception)

### `boards/` (平臺級支援)

每個板子一個目錄, 包含:

+ Kconfig 板級預設配置
    > 這個板子的預設串口是 UART0, 預設晶振頻率是 32MHz ...

+ 板級設備樹文件
    > 描述板上有哪些外設、它們接在哪些引腳、I2C/SPI 地址是什麼

+ 板級文件
    > 板子照片、引腳圖、跳線說明

例如 `boards/nordic/nrf52840dk_nrf52840/` 就是 Nordic nRF52840-DK 的板級支持.

### `drivers/` (裝置驅動程式)

這是 Zephyr 最大的目錄之一, 按外設類型分層:

```
drivers/
├── gpio/          # GPIO 驅動
├── i2c/           # I2C 控制器驅動
├── spi/           # SPI 控制器驅動
├── uart/          # 串口驅動
├── sensor/        # 傳感器驅動(加速度、溫度、濕度等 100+ 種)
├── pwm/           # PWM 驅動
├── adc/           # ADC 驅動
├── dac/           # DAC 驅動
├── counter/       # 定時器/計數器驅動
├── watchdog/      # 看門狗驅動
├── flash/         # Flash 存儲驅動
├── bluetooth/     # 藍牙 HCI 驅動
├── usb/           # USB 控制器驅動
├── can/           # CAN 控制器驅動
├── ethernet/      # 以太網驅動
├── dma/           # DMA 控制器驅動
├── clock_control/ # 時鐘控制器驅動
├── pinctrl/       # 引腳覆用控制
├── regulator/     # 電源調節器驅動
└── ...
```

Zephyr 的驅動模型是統一的(所有的 GPIO 驅動都遵循相同的 gpio_driver_api 接口).
上層程式碼則透過 `gpio_pin_set()`、 `gpio_pin_get()` 等統一 API 來操作各個廠商的 GPIO.
> 驅動程序正是 Zephyr 平臺價值的核心體現, 它消除了芯片之間的差異, 讓上層的業務邏輯能夠在不同硬體上重複使用.

### `dts/` (設備樹)

包含兩部分:

+ `dts/bindings/`
    > 設備樹綁定(YAML 格式), 用於定義每種設備節點所允許的屬性和類型. 這是編譯期檢驗設備樹正確性的依據.
+ SoC 與板級 `.dts / .dtsi` 檔案
    > 描述了特定芯片的外設基地址、中斷號、引腳分配等硬體相關資訊.

設備樹是 Zephyr 硬體描述的核心機制. 它讓相同的驅動程式碼在不同板子上運行時, 只需更換設備樹, 無需修改驅動程式的原始碼.

### `include/` (公共頭檔案)

include/zephyr/ 下按功能分子目錄:

```
include/zephyr/
├── kernel/        # 內核 API(線程、信號量、互斥鎖、隊列、消息隊列…)
├── drivers/       # 驅動 API 頭文件
├── sys/           # 系統工具(環形緩沖、原子操作、C++ 互操作…)
├── net/           # 網絡 API
├── bluetooth/     # 藍牙 API
├── usb/           # USB API
├── logging/       # 日志宏
├── shell/         # Shell 框架
├── posix/         # POSIX 子集(pthread、信號…)
├── dt-bindings/   # 設備樹宏定義頭文件
└── ...
```

### `kernel/` (內核核心)

Zephyr 核心的實現代碼, 包括:

+ 調度器(多優先級、時間片輪轉、最早截止時間優先 EDF)
+ 線程管理(建立、終止、掛起、恢復、優先級調整)
+ 同步原語(信號量、互斥鎖、條件變數、事件、屏障)
+ 數據傳遞(消息隊列、管道、棧、隊列)
+ 內存管理(內存池、堆分配器、內存域、虛擬地址空間)
+ 中斷管理(ISR 註冊、延遲中斷下半部工作隊列)
+ 時鐘和超時管理
+ SMP 多核支持

### `subsys/` (子系統)

這是 Zephyr 與純內核 RTOS 的差異所在, 也是其關鍵特點之一:

| 子系統              | 說明                                           |
| :-                 | :-                                             |
| subsys/logging/    |日誌系統(支援多後端: 串口、RTT、網路、檔案...)       |
| subsys/shell/      |命令行 Shell(支援 UART、Telnet、USB CDC ACM 後端)  |
| subsys/fs/         |檔案系統(LittleFS、FATFS 等)                      |
| subsys/net/        |網路棧(含 IP/TCP/UDP/HTTP/MQTT/CoAP/TLS/DTLS)    |
| subsys/bluetooth/  |藍牙 Host 協議棧(GAP/GATT/L2CAP/Mesh)            |
| subsys/usb/        |USB 協議棧(CDC/DFU/HID/MSC/Audio)               |
| subsys/storage/    |持久化儲存(Flash Map、NVS、Settings API)          |
| subsys/mgmt/       |設備管理(MCUmgr OTA 固件升級)                    |
| subsys/dfu/        |設備固件升級引導                                 |
| subsys/pm/         |電源管理策略                                     |
| subsys/tracing/    |內核事件追蹤                                     |
| subsys/modbus/     |Modbus 協議棧                                   |
| subsys/canbus/     |CAN 總線高層協議                                 |


### `soc/` (SoC 級定義)

SoC 層級位於`架構`與`板級`之間.
同一個架構(例如 ARM Cortex-M4), 可以由不同的廠商所生產出不同的 SoC(e.g. Nordic nRF52, ST STM32, NXP i.MX RT).

此目錄中儲存了 SoC 特有的初始化代碼、寄存器定義、Flash/RAM 的佈局等資訊.


### `modules/` (外部模組)

Zephyr 透過 `west.yml` 來管理各種外部依附元件(如 HAL 層、MCUboot、LittleFS、mbedTLS、LVGL 等).
> 這些外部程式碼會被下載到 `modules/` 中, 再進行統一編譯.
每個模組都有相應的 `zephyr/module.yml` 說明, 或使用 `zephyr/module.yml` 來說明其整合方式.

### `samples/` (範例程式)

按子系統分類的完整示例, 如:

+ `samples/basic/blinky/`
    > 經典的 LED 閃爍效果(最小範例)
+ `samples/basic/threads/`
    > 線程創建和調度
+ `samples/subsys/shell/shell_module/`
    > Shell 使用範例
+ `samples/net/sockets/echo/`
    > Socket 網路通訊

這是學習 Zephyr 最好的入門方式.

### `tests/` (測試)

Zephyr 的測試基礎設施中, 每個驅動程式/子系統都有相應的測試用例, 這些測試用例都是透過 `twister` 測試框架在 CI 環境中執行的.

### `scripts/` (工具腳本)

包含 **west 命令的實現**、 **twister 測試框架**、 **menuconfig 設定工具**、**設備樹工具鏈(edtlib 、 dtlib)**、 **編譯工具鏈適配腳本**等.

### `cmake/` (構建系統)

Zephyr 是一個基於 CMake 的建構框架. 此目錄包含各種通用的 CMake 函數和巨集, 可供各種應用程式和模組使用, 例如:

+ `cmake/kconfig.cmake`
    > Kconfig 到 C 宏的轉換
+ `cmake/dts.cmake`
    > 裝置樹到 C 指令的處理方式
+ `cmake/toolchain.cmake`
    > 交叉編譯工具鏈配置
+ `cmake/flash.cmake`
    > 燒錄目標


# Zephyr 應用項目與 Zephyr 源碼的關係

## 典型應用項目結構

```
my_zephyr_app/
├── CMakeLists.txt          # CMake 構建入口
├── prj.conf                # Kconfig 項目配置
├── src/
│   ├── main.c              # 主程序
│   └── ...                 # 其他源文件
├── boards/                 # 板級配置(可選)
│   └── nrf52840dk_nrf52840.overlay  # 設備樹 Overlay
├── include/                # 頭文件(可選)
├── lib/                    # 自定義庫(可選)
└── README.md
```

## 核心目錄/檔案說明


### `CMakeLists.txt`

項目的構建入口. 最關鍵的一行是:

```
cmake_minimum_required(VERSION 3.20.0)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(my_app)

target_sources(app PRIVATE src/main.c)
```

find_package(Zephyr) 會載入 Zephyr 源碼中的 CMake 框架,
並將 Zephyr 的 arch、kernel、drivers、subsys 等所有組件都納入同一個 CMake 構建過程中.
你的應用程式會與 Zephyr 系統一起被編譯, 從而共享同一個構建上下文(這是理解 Zephyr 應用程式之間關係的關鍵).


### `prj.conf`

應用層的 Kconfig 設定. 你可以在此處啟用/禁用核心與子系統的功能:

```
CONFIG_GPIO=y
CONFIG_SERIAL=y
CONFIG_SHELL=y
CONFIG_LOG=y
CONFIG_BT=y
```

這些配置會與 Zephyr 源碼中的 Kconfig 檔案自動合併, 最終只編譯你需要的模組.

### `boards/<board>.overlay`

設備樹 Overlay 檔案. 它不會修改 Zephyr 源碼中的板級設備樹, 而是於編譯時被疊加到基礎設備樹上, 用於:

+ 啟用板子上某個外設(Zephyr 預設可能沒有啟用)
+ 修改引腳分配
+ 配置外設參數(如 I2C 頻率)
+ 添加板載外設的感測器節點

    ```
    &i2c0 {
        status = "okay";
        bme280@76 {
            compatible = "bosch,bme280";
            reg = <0x76>;
        };
    };
    ```

## App與 Source code 的關係模型

可以用一張圖來理解:

```
┌─────────────────────────────────────────┐
│           my_zephyr_app                 │
│  ┌─────────┐  ┌─────────┐  ┌──────────┐ │
│  │ main.c  │  │ prj.conf│  │ .overlay │ │
│  └────┬────┘  └────┬────┘  └────┬─────┘ │
│       │            │            │       │
└───────┼────────────┼────────────┼───────┘
        │            │            │
        V            V            V
┌──────────────────────────────────────────┐
│        CMake + Kconfig + Devicetree      │  <- 構建系統層(Zephyr 源碼提供)
│    find_package(Zephyr) 把它們全部串起來  │
└──────────────────────────────────────────┘
        │             │             │
        V             V             v
┌──────────────────────────────────────────┐
│           Zephyr 源碼樹                  │
│  ┌────────┐ ┌──────────┐ ┌────────────┐  │
│  │ kernel │ │ drivers  │ │  subsys    │  │
│  │  arch  │ │ include  │ │  modules   │  │
│  └────────┘ └──────────┘ └────────────┘  │
└──────────────────────────────────────────┘
                    │
                    v
┌──────────────────────────────────────────┐
│           交叉編譯工具鏈                   │
│        arm-none-eabi-gcc / llvm          │
└──────────────────────────────────────────┘
                    │
                    V
              ┌───────────┐
              │  ELF file │
              └───────────┘
```

+ 關鍵結論

    - 應用程式和 Zephyr 並非經過分別編譯再連結而產生的兩個獨立檔案.
        > `find_package(Zephyr)` 將你的 `src/main.c` 與 Zephyr 的 `kernel/`、 `drivers/` 等原始碼, 一起放入同一個 CMake 組建過程中,
        最終會產生一個單一的 ELF(hex/bin) 檔案.

    - Zephyr 是底層的架構, 而應用程式則是建築在這個架構之上的邏輯層.
        > Zephyr 提供了核心、驅動程式、協議堆疊以及建構系統.
        你只需要專注於業務邏輯的開發, 再透過 `prj.conf` 來進行剪裁, 並通過 `.overlay` 來適應硬體環境即可.

    - 應用程式不會自行產生 SDK, 應用程式僅包含一個 CMakeLists.txt 、一些設定檔以及應用程式的原始碼而已.
        > 它所依賴的環境變數 `ZEPHYR_BASE` 會指向 Zephyr 的原始碼樹, 所有的底層功能都是由 Zephyr 的原始碼所提供.


# `Zephyr 不能作為中介層` (從平臺視角理解 Zephyr 的抽象邊界)

許多從 FreeRTOS 轉過來的開發者會問: **能不能把 Zephyr 像 FreeRTOS 一樣, 當作一個 middleware 組件嵌入到我們的 SDK 中呢?**

答案是: 可以, 但通常不應該這樣做.

這不是 Zephyr 的能力問題, 而是兩種不同的設計範式.

## FreeRTOS 的邊界: 內核 + 少量組件

FreeRTOS 的核心交付物是:

+ 一個任務調度器
+ 一組同步原語(信號量、互斥鎖、隊列、事件組)
+ 軟體定時器
+ 可選的內存管理方案(heap_1 ~ heap_5)
+ 可選的 TCP/UDP 協議棧和 CLI

概括一下: FreeRTOS 主要負責線程調度和基本的 RTOS IPC 功能.
它幾乎不涉及驅動程式、外設、板級硬件描述、建構系統或配置框架等相關內容.

因此, 它很容易被作為一個**中介軟件**嵌入到任何 SDK 中, 僅有底層的計時功能以及一個啟動入口而已.
其餘的工作, 就交給製造商的 HAL/SDK 來處理吧.

## Zephyr 的邊界: 完整的 OS 平臺

Zephyr 的抽象邊界完全不同. 它涵蓋了:

| 層面                  | FreeRTOS 覆蓋範圍  |  Zephyr 覆蓋範圍
| :-                    | :-                | :-
| 內核調度             | o                   |   o
| 同步原語和 IPC       |  o                  |   o
| 統一設備驅動模型      |x                    |  o (drivers/ + 標準驅動 API)
| 硬體描述語言         | x                   |   o (Device Tree)
| 配置系統             | x                   |   o (Kconfig)
| 構建系統框架         | x                   |   o (CMake + west)
| 多倉庫依賴管理        | x                  |   o (west.yml)
| 網路/藍牙/USB 協議棧  | 可選+有限           |  o (完整集成)
| 檔案系統             | x                   |   o
| Shell/日誌           | 可選                |   o
| 電源管理             | x                   |   o
| 設備管理/OTA         | x                   |   o


Zephyr 的抽象邊界已經達到了操作系統平臺的層級. 其`建構/配置/設備樹/驅動模型/依賴管理`都是一個緊密結合的整體,
因此很難像 FreeRTOS 那樣, 將其拆分成獨立的核心組件, 再放入另一個建構體系中.


## 不是你技術不行, 是`兩套平臺疊加`的工程現實

假設你要把 Zephyr 塞進一個廠商 SDK——

那個 SDK 大概率已經有:

+ 自己的構建系統 (Make/ IAR/ 自訂腳本)
+ 自己的外設驅動 (HAL/ LL/ stdperiph)
+ 自己的配置方式 (頭文件宏/ CubeMX 代碼生成)
+ 自己的板級管理方式
+ 自己的連結腳本和啟動流程

然後你再加上 Zephyr 的:

+ `CMake + Kconfig + Devicetree` 架構與配置體系
+ 統一驅動模型
+ 板級和 SoC 級設備樹定義

結果是什麼呢? 就是平臺疊加在另一個平臺之上.
在構建過程中, 必須協調兩套構建系統, 在初始化時, 也必須協調兩套啟動流程.

至於驅動程式的選擇, 則需要做出取捨.
> 如果使用 Zephyr, 就必須放棄 SDK 的 HAL 封裝; 如果使用 SDK, 就必須放棄 Zephyr 的跨硬件可移植性.

此外, 各個腳位的配置也必須在兩端保持一致

這就像在 iOS 上再運行一套 Android 框架——兩套完整的平臺系統同時存在, 協調成本遠遠超過收益.

## 抽象層不是問題, 合理的抽象邊界才是重點.

有一種常見的誤解是: **Zephyr 的抽象層太厚了, 因此不適合作為中間層. **

其實恰恰相反:

合理的抽象層, 可以把那些不可避免會發生變化的因素隔離開來
> 比如芯片差異、外設 IP、板級差異.

如此一來, 上層的業務邏輯才能保持穩定.

Zephyr 的驅動模型、設備樹、Kconfig 正是用來實現這一點, 而且做得相當出色.
> 譬如 你在 nRF52840 上編寫的 I2C 感測器驅動, 只要修改設備樹, 就可以直接在 STM32 上使用, 完全不需要修改任何代碼.

真正的問題不是**抽象層太厚**, 而是`抽象邊界應該放在哪一層`:

+ FreeRTOS 的本質在於其`核心模組`, 因此它很容易被嵌入到任何 SDK 中.
    > 但驅動程式和各種外設的整, 則需要另外解決(通常是由各個廠商的 SDK 來處理, 而上層的移植性, 則取決於使用者自己所開發的 HAL 層).

+ Zephyr 的邊界在`OS 平臺`上, 它本身就扮演了基礎平臺的角色.
    > + 優點在於, 驅動程式、配置、建構以及各種依賴關系的處理都可以在其內部完成.
    > + 缺點則是它無法被輕易地嵌入到另一個平臺中, 作為中間層來使用.

## 內核廠商為什麼無法統一驅動 API ?

一個自然的問題是: 為何內核廠商不把驅動程式 API 也統一起來呢? 如此一來, FreeRTOS 不就能像 Zephyr 一樣, 擁有跨硬體的驅動程式可移植性了嗎?

答案在於, 驅動 API 所需要的各種功能, 已經超出了內核的能力範圍:

+ 設備模型
    > 不是簡單的函數指針表, 而是包含
    > + 設備生命週期(init -> power -> suspend-> resume)
    > + 設備依賴關係(SPI 依賴 GPIO 引腳, 感測器依賴 SPI/I2C 總線)
    > + 設備電源域歸屬

+ 配置機制
    > 在沒有 Kconfig 的情況下, UART 驅動要如何讓使用者選擇波特率呢?
    >> 靠 `#define` 宏和 `#ifdef` 條件編譯來解決嗎? 真是麻煩至極.
+ 硬件描述
    > 一個 I2C 裝置位於哪個 I2C 控制器上、其地址是多少、中斷線則連接到哪個 GPIO, 這些資訊應該儲存在哪裡呢?
    >> 是將其硬編碼在 C 檔案中嗎?那如果更換了主板, 要怎麼辦呢?
+ 構建連結
    > 不同芯片的驅動源文件不同, 片選需要系統的支援, 不能僅靠 `#if defined(STM32F4) include "stm32f4_i2c.c"` 來解決.
+ 依賴管理
    > 某些驅動程式依賴於外部的 HAL 函式庫、協議堆疊或算法庫,
    >> 誰來負責管理這些軟體的版本相容性呢?

這些並非`一個調度器 + 一組同步原語`就能解決的問題.
它們需要的是一個操作系統平臺的完整體系, 包括
+ 設備模型
+ 配置機制
+ 硬件描述
+ 構建連接
+ 依賴管理.

這五者缺一不可.

所以結論是: 真正能統一驅動的, 要麼是像 `Zephyr/RT-Thread` 把自己定位成`Platform`的系統, 要麼是某個強勢廠商自己的全棧 SDK(但那會鎖定生態).
> 純 RTOS 內核天然無法解決驅動統一這個問題.

## 總結：選擇平臺還是 Middleware, 本質上就是決定由誰來作為基礎架構.

|            |   FreeRTOS 模式                 | Zephyr 模式
| :-         | :-                              | :-
| 定位       | 內核 + 少量組件                  | 完整的 OS 平臺
| 抽象邊界   | RTOS IPC 層                     | 從硬件到子系統的全棧解決方案
| 整合方式   | 嵌入到廠商 SDK 中                | 它就是底座, 廠商 HAL 會將其作為安裝的基礎.
| 驅動模型   | 依賴廠商 SDK                     | 統一的跨平臺驅動 API
| 硬體描述   | 無標準(頭文件/代碼生成)           | Devicetree 標準化描述
| 可攜行性   | 需要你自己的抽象層                | 換板子改設備樹即可
| 多倉庫管理 |  無(手工管理版本)                 | west.yml 宣告式管理
| 適合場景   | 已有成熟 SDK 平臺, 只需一個調度器  | 從零構建跨硬件產品線, 需要完整 OS 平臺

Zephyr 會讓你覺得**麻煩**, 正是因為它本質上是一個平臺.
你要麼接受它作為基礎架構, 讓上層的業務邏輯能夠享受跨硬體的優勢; 要麼就別把它當作 FreeRTOS 那樣的中介軟體來使用.
這兩種使用方式背後的設計理念不同, 沒有什麼高下之分, 只有是否適合而已.

但如果你今天仍在找`把 Zephyr 塞進 SDK 作為 middleware 的方法`, 那不是 Zephyr 的設計缺陷, 而是你對它的定位預期和它的設計邊界發生了錯位.
理解了這一點, 你才算真正理解了 Zephyr.

# 接下來

本文僅討論了**是什麼**和**為什麼**. 後續計劃將撰寫:

+ Zephyr 的編譯與構建流程: `CMake + Kconfig + Devicetree` 三者的協作機制
+ 在電腦上運行第一個 Zephyr 程式: 環境搭建、編譯、用 QEMU 仿真運行
+ 建立自己的板子設備樹: 從零寫一個板級 Devicetree, 在自己板子上運行通電燈程序



# Reference
+ [初識 Zephyr RTOS：從源碼結構到設計哲學\_arm 開發\_weixin\_71785894-openEuler 社區](https://openeuler.csdn.net/6a07f815662f9a54cb74e669.html)
+ [note_zephyr](../../note_vg/note_zephyr.md)

