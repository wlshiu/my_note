Note STM32L5
---




+ `OTFDEC (On-The-Fly Decryption)` hardware module
    > 對 external NOR flash 上的加密數據或加密代碼, 進行即時解密與執行

    - 透過外部工具, 先產生 secret key, 用此 key 加密 Bin file, 再將 Key 和 Encrypted-Bin 寫入 DUT


## GTZC (Global TrustZone Controller)

當 ARM Cortex-M33 TrustZone 處理 Secure/Non-Secure 時, 會先經過 SA
經過審查後的 transation, 會發出 `HNONSEC` signal 給 `AHB v5`

![STM32L5_Global_TrustZone_arch](STM32L5_Global_TrustZone_arch.jpg)

STM32L5 的 Peripheral 有兩種
> + `TrustZone aware` Peripheral
>> 能夠自行處理 trustzone signal (HNONSEC on AHB v5)
> + 傳統 Peripheral
>> 需要藉助外力(GTZC) 來協助處理 trustzone signal


STM32L5 使用 GTZC 來實現 Secure system
> + ARM TF-M 是 Core Layer 的實作
> + GTZC 則是 System Layer 的實作, 負責處理**接在 BUS (AHB v5) 裝置**的安全審查

![STM32L5 Bus Matrix](STM32L5_bus_matrix.jpg)

GTZC 包含了三個 sub-blocks

![GTZC in Armv8-M subsystem block diagram](GTZC_subsystem.jpg)

+ `TZSC`: TrustZone Security Controller
+ `MPCBB`: Block-Based Memory Protection Controller
+ `TZIC`: TrustZone Illegal access Controller




# Reference

+ [STM32L5 入門課程（二）STM32L5 的系統新架構 | STMCU 中文官網 --- STM32L5 入门课程（二）STM32L5的系统新架构 | STMCU中文官网](https://www.stmcu.com.cn/ecosystem/chip/chipfamily-STM32L5-2)
+ [AN5281- How to use OTFDEC to encrypt/decrypt in trusted environment on STM32H7](https://www.st.com/resource/en/application_note/an5281-how-to-use-otfdec-to-encryptdecrypt-in-trusted-environment-on-stm32h7bxxx-and-stm32h73xxx-mcus-stmicroelectronics.pdf)


