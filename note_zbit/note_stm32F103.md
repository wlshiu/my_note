STM32F103
---

# SOC

## STM32的三種Boot模式

以 STM32F103 為例, STM32的三種Boot模式如下:

| BOOT1 |  BOOT0  | STM32的啟動方式 |
| :-:   | :-:     | :-:             |
| x     | 0       | 內部 FLASH      |
| 1     | 1       | 內部 SRAM       |
| 0     | 1       | 系統儲存器(也稱ISP啟動方式) |

使用者可以通過設定`BOOT0`和`BOOT1`的三種狀態, 來選擇復位後的啟動方式:

+ 內部 FLASH 啟動方式
    > 當晶片上電後取樣到 BOOT0 引腳為低電平時, `0x00000000` 和 `0x00000004` 地址被對映到內部 FLASH 的首地`0x08000000` 和 `0x08000004`.
    因此, 核心離開復位狀態後, 讀取內部 FLASH 的 `0x08000000` 地址空間儲存的內容, 賦值給棧指標 MSP, 作為棧頂地址,
    再讀取內部 FLASH 的 `0x08000004` 地址空間儲存的內容, 賦值給程式指標 `PC`, 作為將要執行的第一條指令所在的地址.
    具備這兩個條件後, 核心就可以開始從PC 指向的地址中讀取指令執行了.

+ 內部 SRAM 啟動方式
    > 當晶片上電後取樣到 BOOT0 和 BOOT1 引腳均為高電平時, `0x00000000` 和 `0x00000004` 地址被對映到內部 SRAM 的首地址 `0x20000000` 和 `0x20000004`,
    核心從 SRAM 空間獲取內容進行自舉.
    在實際應用中, 由啟動文件`startup_stm32f103xe.s` 決定了 `0x00000000` 和`0x00000004` 地址儲存什麼內容,
    連結時, 由分散載入檔案(sct)決定這些內容的絕對地址, 即分配到內部 FLASH 還是內部 SRAM.

+ 系統儲存器啟動方式
    > 當晶片上電後取樣到 BOOT0 引腳為高電平, BOOT1 為低電平時, 核心將從系統儲存器的 `0x1FFFF000` 及 `0x1FFFF004` 獲取 MSP 及 PC 值進行自舉.
    系統儲存器是一段特殊的空間, 使用者不能訪問, ST 公司在晶片出廠前就在系統儲存器中固化了一段程式碼.
    因而使用系統儲存器啟動方式時, 核心會執行該程式碼, 該程式碼執行時, 會為 ISP 提供支援(In System Program),
    如檢測USART1/2、CAN2 及 USB 通訊介面傳輸過來的資訊, 並根據這些資訊更新自己內部 FLASH 的內容, 達到升級產品應用程式的目的,
    因此這種啟動方式也稱為 ISP 啟動方式.


> 在內部 SRAM 中除錯程式碼, 以野火官方給的例程來實現, 程式碼名為`RAM 除錯—多彩流水燈`
> 硬體設計:<br>
> 在SRAM 上除錯程式, 需要修改 STM32 晶片的啟動方式, 在我們的板子上有引出 STM32 晶片的 BOOT0 和 BOOT1 引腳,
可使用跳線帽設定它們的電平從而控制晶片的啟動方式, 它支援從內部 FLASH 啟動、系統儲存器啟動以及內部 SRAM 啟動方式.
我們現在是在 SRAM 中除錯程式碼, 因此把 BOOT0 和 BOOT1 引腳都使用跳線帽連線到 3.3V, 使晶片從 SRAM 中啟動

## Timer

+ Prescaler
    > 對 PCLK 除頻

    ```
    TIMER_clk = PCLK / (Prescaler + 1)  # H/w 自動 +1

    假設 PCLK = 72MHz, Prescaler = (72 - 1)

    TIMER_clk = 72MHz / 72 = 1 MHz => 1us / sample
    ```

+ ARR (Auto-Reload Reg)
    > 設定多少個 samples (基於 TIMER_clk) 為一個週期 (Period)

    ```
    假設 TIMER_clk = 1MHz (1us/sample), ARR = (65536 - 1)

    65536 個 samples 為一個週期, 則一個周期的時間為 65536 us

    Period_us = ARR * (1000000 usec / (PCLK / Prescaler)) = 65536 us
    ```

+ Channel
    > 會綁定 Pin

    - Input Channel x (ICx, x= 1 ~ 4)

    - Output Channel x (OCx, x= 1 ~ 4)

+ CCRx (Capture/Compare Reg, channel x= 1 ~ 4)

+ Overflow
    > 已經過了一個週期 (Period)

### PWM

+ Prescaler 對 PCLK 除頻 (Get TIMER_clk)

+ ARR 決定 PWM 的週期

    ```
    FREQ_pwm = TIMER_clk / (ARR + 1)
             = PCLK / ((Prescaler + 1) * (ARR + 1))

    Period_us = 1000000 us / FREQ_pwm
              = (1000000 us * (Prescaler + 1) * (ARR + 1)) / PCLK
    ```

+ CCRx 決定了輸出有效信號的時間
    > 在一個週期 `(ARR + 1) 個 samples` 中, 連續幾個 samples 輸出有效信號

    ```
    // 設置 duty cycle (1 ~ 99%)
    pulse_width = (ARR + 1) * duty_cycle
    __HAL_TIM_SET_COMPARE(&htim1, TIM_CHANNEL_1, pulse_width);
    ```

+ PWM mode

    - mode 1
        > 不管是向上還是向下計數, 當計數值小於 ARR 時, 輸出 `HIGH`

    - mode 2
        > 不管是向上還是向下計數, 當計數值小於 ARR 時, 輸出 `LOW`


### Input capture

+ Prescaler 相當於設定 Sample Rate (TIMER_clk)

+ ARR 相當於 Capturing Duration time

+ CCRx 紀錄 counter value (channel x= 1 ~ 4)





# Windows

## CMSIS-DAP CDC

Windows 10 automatically install

+ Windows 7

    - Keil-MDK trigger automatically downloading Software Packs `Keil.STM32F1xx_DFP.2.3.0`

    - set output path
        > + `Options for target ` -> tab `Output` -> `Select Folder for Objects`
        > + `Options for target ` -> tab `Listing` -> `Select Folder for Listings ...`

    - set ICE protocol
        > `Options for target ` -> tab `Debug` -> use `CMSIS-DAP debugger`

    - set FLM
        > `Options for target ` -> tab `Utilities` -> `Settings` -> tab `Flash Download` -> Add

    - USB driver
        > `C:\Keil_v5\ARM\STLink\USBDriver`

        1. CMSIS_DAP_v2.inf
            > inf file (It may not be necessary)

            ```
            [Version]
            Signature = "$Windows NT$"
            Class     = USBDevice
            ClassGUID = {88BAE032-5A81-49f0-BC3D-A4FF138216D6}
            Provider  = %ManufacturerName%
            DriverVer = 04/13/2016, 1.0.0.0
            CatalogFile.nt      = CMSIS_DAP_v2_x86.cat
            CatalogFile.ntx86   = CMSIS_DAP_v2_x86.cat
            CatalogFile.ntamd64 = CMSIS_DAP_v2_amd64.cat

            ; ========== Manufacturer/Models sections ===========

            [Manufacturer]
            %ManufacturerName% = Devices, NTx86, NTamd64

            [Devices.NTx86]
            %DeviceName% = USB_Install, USB\VID_c251&PID_f000

            [Devices.NTamd64]
            %DeviceName% = USB_Install, USB\VID_c251&PID_f000

            ; ========== Class definition ===========

            [ClassInstall32]
            AddReg = ClassInstall_AddReg

            [ClassInstall_AddReg]
            HKR,,,,%ClassName%
            HKR,,NoInstallClass,,1
            HKR,,IconPath,0x10000,"%%SystemRoot%%\System32\setupapi.dll,-20"
            HKR,,LowerLogoVersion,,5.2

            ; =================== Installation ===================

            [USB_Install]
            Include = winusb.inf
            Needs   = WINUSB.NT

            [USB_Install.Services]
            Include = winusb.inf
            Needs   = WINUSB.NT.Services

            [USB_Install.HW]
            AddReg  = Dev_AddReg

            [Dev_AddReg]
            HKR,,DeviceInterfaceGUIDs,0x10000,"{CDB3B5AD-293B-4663-AA36-1AAE46463776}"

            ; =================== Strings ===================

            [Strings]
            ClassName        = "Universal Serial Bus devices"
            ManufacturerName = "KEIL - Tools By ARM"
            DeviceName       = "CMSIS-DAP v2"
            ```



# 故障排除

## STM32 不小心把 SWD/JTAG 都給關了

+ 建立開啟 SWD/JTAG 的 project, 並 compile project
+ CMSIS-DAP Cortex-M Target Driver Setup
    > `Options for Target` -> `Debug` -> `CMSIS-DAP Debugger` Settings
    > + `Max Clock`: 10MHz

    - tab `Debug`
        > `Connect & Reset Options`
        > + `Connect`: under Reset
        > + `Reset`: HW Reset
        > + `Reset after Connect` : enable
        > + `Stop after Reset`: enable

    - tab `Flash Download`
        > `Erase Full Chip`: enable

+ Hold `Reset key` on 魔女開發版
+ press `Download code to flash memory` in Keil-MDK
    > wait the first message in `Build Output`

+ Release `Reset key`
    > start erase flash

