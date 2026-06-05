stm32L5 GPIO_TZ Example [[Back](note_stm32L5.md#example-gpio_tz)]
---

Official: `STM32CubeL5/Projects/NUCLEO-L552ZE-Q/Examples/GPIO/GPIO_IOToggle_TrustZone`
> 上電後, 會先從 SPE 啟動, 初始化並配置安全屬性後, 切換到 NSPE 執行, 接著是 SPE 和 NSPE 之間的互動.

```
.
├── MDK-ARM
│   ├── Project.uvmpw
│   ├── Project_ns.uvoptx
│   ├── Project_ns.uvprojx
│   ├── Project_s.uvoptx
│   ├── Project_s.uvprojx
│   ├── startup_stm32l552xx.s
│   ├── stm32l552xe_flash_ns.sct
│   └── stm32l552xe_flash_s.sct
├── NonSecure
│   ├── Inc
│   │   ├── main.h
│   │   ├── stm32l5xx_hal_conf.h
│   │   └── stm32l5xx_it.h
│   └── Src
│       ├── main.c
│       ├── stm32l5xx_hal_msp.c
│       ├── stm32l5xx_it.c
│       └── system_stm32l5xx_ns.c
├── Secure
│   ├── Inc
│   │   ├── main.h
│   │   ├── partition_stm32l552xx.h
│   │   ├── stm32l5xx_hal_conf.h
│   │   └── stm32l5xx_it.h
│   └── Src
│       ├── main.c
│       ├── secure_nsc.c
│       ├── stm32l5xx_hal_msp.c
│       ├── stm32l5xx_it.c
│       └── system_stm32l5xx_s.c
├── Secure_nsclib
│   └── secure_nsc.h
└── STM32CubeIDE
    ├── NonSecure
    │   ├── Application
    │   └── STM32L552ZETXQ_FLASH.ld
    └── Secure
        ├── Application
        └── STM32L552ZETXQ_FLASH.ld

```

Secure/NonSecure 需各自編譯(各自所需的檔案,會分別放在 Secure/NonSecure 目錄下), 一般檔名有後綴字(suffix) `_s` 只能在 SPE 使用,
 而後綴字(suffix) `_ns` 則只能在 NSPE 使用.
> 在此 example 中
> + Vector Table 是可以共用(`MDK-ARM/startup_stm32l552xx.s`)
>> 若需要個別處理, 也可以分開檔案

> + Memory layout 則需要分離 (`stm32l552xe_flash_ns.sct and stm32l552xe_flash_s.sct`)

其中 `Secure/Src/secure_nsc.c` 是 NSC(Non-Secure-Callable) APIs, 由 SPE 提供給 NSPE 呼叫的窗口 (Secure project 必須先編譯).
在 Secure project 編譯後, 會在 `Secure_nsclib` 下生成 obj file `secure_nsclib.o`
> `secure_nsc.h` 和 `secure_nsclib.o` 則提供給 NonSecure project, 在 compiler 的 link 階段使用

# Features of STM32L5

![GTZC_Arch](GTZC_Arch.jpg)

STM32L5 上電時, hardware 先依照 IDAU與SAU 的預設值, 配置 Address Secure Area(User-Manual 2.3.2: `Figure 2. Memory map based on IDAU mapping`).
> + IDAU 除了 `0x0C00_0000 ~ 0x0FFF_FFFF`, `0x3000_000 ~ 0x3FFF_FFFF`, `0x5000_0000 ~ 0x5FFF_FFFF` 是 NSC 外, 其餘都是 NSPE
> + SAU 預設值全部為 SPE

在 IDAU/SAU 設定中, hardware 會取最嚴格的安全模式, 因此在 CPU 重新設定 SAU 前, CPU 對所有區域都會發出 `transation_S` 到 AHBv5.

FMC (TrustZone aware) 會依照 `Option Bytes`所存的設定, 來配置自己的 Secure Area,
GTZC 則會依照預設值, 對 SRAM 及 Peripheral 配置 Secure Area.
> `GTZC->MPCBB` 預設會將 SRAM 都配置為 SPE

## Memory Space of SPE and NSPE

IDAU 是從 hardware 實作的角度, 定義 Mapped-Address Area 的屬性 (會以 Memory Bank 來分割),
藉由 Memory-Alias (偷用 Address 的 1-Bit) 來有效區分 SPE 和 NSPE 的 Memory Space (實際上都是同一個實體)
> + SRAM: `0x2000_0000 (NSPE) vs. 0x3000_0000 (SPE)`
> + Peripheral-Registers: `0x4000_0000(NSPE) vs. 0x5000_0000 (SPE)`
> + Execute Code range: `0x0800_0000 (NSPE) vs. 0x0C00_0000 (SPE)`

在 STM32L5 中, 將 eFlash (512-KBytes) 的`前 256-KBytes 歸給 SPE`, `後 256-KBytes 歸給 NSPE`
> + eFlash SPE Address `0x0C00_0000 ~ 0x0C03_FFFF (256 KBytes)`
>> NSC (Non-Secure-Callable) Address `0x0C03_E000 ~ 0x0C03_FFFF (8 KBytes)`
> + eFlash NSPE Address `0x0800_4000 ~ 0x0807_FFFF (256 KBytes)`

而 SRAM (192 + 64 KBytes) 同樣將 `前 96-KBytes 歸給 SPE`, `後 160-KBytes 歸給 NSPE`
> + SRAM SPE Address `0x3000_0000 ~ 0x3001_7FFF (96 KBytes)`
> + SRAM NSPE Address `0x2001_8000 ~ 0x3002_7FFF (160 KBytes)`


# Development Environment

## ICE Development

+ 使用 Secure Project (CPU 處於 SPE), 用 ICE 燒錄並將程式停在 `Reset_Handler()`, 觀察 memory 內容
    > FMC 設計成 `transation_S 只訪問 SPE`, `transation_NS 只訪問 NSPE`, 不匹配就 block
    >> Memory/Disassembly Window 的資料屬於 **data access**

    - Secure status when `Power On` <br>
        > 此時 `0x0804_0000` 和 `0x0C04_0000` 區域看不到 Memory data (Transation 與 FMC 不匹配)

        | Address                   | IDAU | SAU  | Transation  | FMC (Option-Bytes)                | SRAM (GTZC->MPCBB)            |
        | :-:                       | :-   | :-   | :-:         | :-:                               | :-:                           |
        | 0x0000_0000 ~ 0x07FF_FFFF | NS   | S    |   S         |                                   |                               |
        | 0x0800_0000 ~ 0x0803_FFFF | NS   | S    |   S         | 0x0800_0000 ~ 0x0803_FFFF (S)     |                               |
        | 0x0804_0000 ~ 0x0807_FFFF | NS   | S    |   S         | 0x0804_0000 ~ 0x0807_FFFF (NS)    |                               |
        | 0x0808_0000 ~ 0x0BFF_FFFF | NS   | S    |   S         |                                   |                               |
        | 0x0C00_0000 ~ 0x0C03_FFFF | NSC  | S    |   S         | 0x0C00_0000 ~ 0x0C03_FFFF (S)     |                               |
        | 0x0C04_0000 ~ 0x0C07_FFFF | NSC  | S    |   S         | 0x0C04_0000 ~ 0x0C07_FFFF (NS)    |                               |
        | 0x0C08_0000 ~ 0x0FFF_FFFF | NSC  | S    |   S         |                                   |                               |
        | 0x2000_0000 ~ 0x2001_7FFF | NS   | S    |   S         |                                   | 0x2000_0000 ~ 0x2001_7FFF (S) |
        | 0x2001_8000 ~ 0x2003_FFFF | NS   | S    |   S         |                                   | 0x2001_8000 ~ 0x2003_FFFF (S) |
        | 0x2004_0000 ~ 0x2FFF_FFFF | NS   | S    |   S         |                                   |                               |
        | 0x3000_0000 ~ 0x3001_7FFF | NSC  | S    |   S         |                                   | 0x3000_0000 ~ 0x3001_7FFF (S) |
        | 0x3001_8000 ~ 0x3003_FFFF | NSC  | S    |   S         |                                   | 0x3001_8000 ~ 0x3003_FFFF (S) |
        | 0x3004_0000 ~ 0x3FFF_FFFF | NSC  | S    |   S         |                                   |                               |



+ 往下執行到 `SystemInit() -> TZ_SAU_Setup()` 時, 會重新配置 SAU (NSP: `0x0800_0000 ~ 0x0BFF_FFFF`, `0x2000_0000 ~ 0x2FFF_FFFF`), 如下

    - Secure status after re-configure SAU
        > + `0x0804_0000` 區域, 可獲得 Memory data (Transation 與 FMC 呼應)
        > + `0x0C04_0000` 區域, 無資料 (Transation 與 FMC 不匹配)
        > + `0x2001_8000` 區域, 無資料 (Transation 與 TZC->MPCBB 不匹配)

        | Address                   | IDAU | SAU  | Transation  | FMC (Option-Bytes)                | SRAM (GTZC->MPCBB)            |
        | :-:                       | :-   | :-   | :-:         | :-:                               | :-:                           |
        | 0x0000_0000 ~ 0x07FF_FFFF | NS   | S    |   S         |                                   |                               |
        | 0x0800_0000 ~ 0x0803_FFFF | NS   | S    |   S         | 0x0800_0000 ~ 0x0803_FFFF (S)     |                               |
        | 0x0804_0000 ~ 0x0807_FFFF | NS   | NS   |   NS        | 0x0804_0000 ~ 0x0807_FFFF (NS)    |                               |
        | 0x0808_0000 ~ 0x0BFF_FFFF | NS   | S    |   S         |                                   |                               |
        | 0x0C00_0000 ~ 0x0C03_FFFF | NSC  | S    |   S         | 0x0C00_0000 ~ 0x0C03_FFFF (S)     |                               |
        | 0x0C04_0000 ~ 0x0C07_FFFF | NSC  | S    |   S         | 0x0C04_0000 ~ 0x0C07_FFFF (NS)    |                               |
        | 0x0C08_0000 ~ 0x0FFF_FFFF | NSC  | S    |   S         |                                   |                               |
        | 0x2000_0000 ~ 0x2001_7FFF | NS   | S    |   S         |                                   | 0x2000_0000 ~ 0x2001_7FFF (S) |
        | 0x2001_8000 ~ 0x2003_FFFF | NS   | NS   |   NS        |                                   | 0x2001_8000 ~ 0x2003_FFFF (S) |
        | 0x2004_0000 ~ 0x2FFF_FFFF | NS   | S    |   S         |                                   |                               |
        | 0x3000_0000 ~ 0x3001_7FFF | NSC  | S    |   S         |                                   | 0x3000_0000 ~ 0x3001_7FFF (S) |
        | 0x3001_8000 ~ 0x3003_FFFF | NSC  | S    |   S         |                                   | 0x3001_8000 ~ 0x3003_FFFF (S) |
        | 0x3004_0000 ~ 0x3FFF_FFFF | NSC  | S    |   S         |                                   |                               |

+ 再往下執行到 `main() -> MX_GTZC_S_Init()` 時, 重新配置 `GTZC->MPCBB`, 來限制 SRAM 的存取權限

    - Secure status after re-configure `GTZC->MPCBB`
        > + `0x2000_0000` 區域, 可獲得 Memory data (Transation 與 FMC 呼應)
        > + `0x2001_8000` 區域, 可獲得 Memory data (Transation 與 FMC 呼應)
        > + `0x3000_0000` 區域, 可獲得 Memory data (Transation 與 FMC 呼應)
        > + `0x3001_8000` 區域, 無資料 (Transation 與 TZC->MPCBB 不匹配)

        | Address                   | IDAU | SAU  | Transation  | FMC (Option-Bytes)                | SRAM (GTZC->MPCBB)             |
        | :-:                       | :-   | :-   | :-:         | :-:                               | :-:                            |
        | 0x0000_0000 ~ 0x07FF_FFFF | NS   | S    |   S         |                                   |                                |
        | 0x0800_0000 ~ 0x0803_FFFF | NS   | S    |   S         | 0x0800_0000 ~ 0x0803_FFFF (S)     |                                |
        | 0x0804_0000 ~ 0x0807_FFFF | NS   | NS   |   NS        | 0x0804_0000 ~ 0x0807_FFFF (NS)    |                                |
        | 0x0808_0000 ~ 0x0BFF_FFFF | NS   | S    |   S         |                                   |                                |
        | 0x0C00_0000 ~ 0x0C03_FFFF | NSC  | S    |   S         | 0x0C00_0000 ~ 0x0C03_FFFF (S)     |                                |
        | 0x0C04_0000 ~ 0x0C07_FFFF | NSC  | S    |   S         | 0x0C04_0000 ~ 0x0C07_FFFF (NS)    |                                |
        | 0x0C08_0000 ~ 0x0FFF_FFFF | NSC  | S    |   S         |                                   |                                |
        | 0x2000_0000 ~ 0x2001_7FFF | NS   | S    |   S         |                                   | 0x2000_0000 ~ 0x2001_7FFF (S)  |
        | 0x2001_8000 ~ 0x2003_FFFF | NS   | NS   |   NS        |                                   | 0x2001_8000 ~ 0x2003_FFFF (NS) |
        | 0x2004_0000 ~ 0x2FFF_FFFF | NS   | S    |   S         |                                   |                                |
        | 0x3000_0000 ~ 0x3001_7FFF | NSC  | S    |   S         |                                   | 0x3000_0000 ~ 0x3001_7FFF (S)  |
        | 0x3001_8000 ~ 0x3003_FFFF | NSC  | S    |   S         |                                   | 0x3001_8000 ~ 0x3003_FFFF (NS) |
        | 0x3004_0000 ~ 0x3FFF_FFFF | NSC  | S    |   S         |                                   |                                |











# Create a STM32L5 project with STM32CubeMX






# Reference

+ [RM0438: STM32L5 series Reference manual](https://www.st.com/resource/en/reference_manual/dm00346336-stm32l552xx-and-stm32l562xx-advanced-arm-based-32-bit-mcus-stmicroelectronics.pdf)
+ [STM32L5 入门课程系列（三）TrustZone环境下新的用户编程模型 | STMCU中文官网](https://www.stmcu.com.cn/ecosystem/chip/chipfamily-STM32L5-3)
+ [STM32L5 入门课程系列（四）STM32CubeMX：支撑TZ应用 | STMCU中文官网](https://www.stmcu.com.cn/ecosystem/chip/chipfamily-STM32L5-4)

