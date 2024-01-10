ARM CortexM Fault Exceptions
---

# Abstract

Cortex-M 實現了一個高效異常處理模組, 可以捕獲非法記憶體訪問和數個程序錯誤條件.

本文從程式設計師角度, 描述 Cortex-M Fault 異常, 並且講述在軟體開發週期中的 Fault 用法

# Summary

Cortex-M3/M4 的 Fault Exceptions 可以捕獲非法記憶體 method 和 非法程式設計行為. Fault Exceptions 能夠檢測到以下情況:

+ Bus Fault
    > 在 Addressing, Data Read/Write, Enter/Leave ISR, 及 stack push/pop 時, 檢測到記憶體訪問錯誤

+ MemManage Fault
    > 檢測到 memory access 到 MPU 定義的區域

+ Usage Fault
    > + 檢測到未定義的 Instruction 異常
    > + 未對齊的記憶體訪問 (多重載入/儲存)

    > 如果 enable 相應 flags,  還可以檢測出除 0, 以及其他未對齊的記憶體訪問

+ Hard Fault
    > 如果上面的 Bus Fault, MemManage Fault, Usage Fault 的 handles 不被執行, 則 re-direct 到 Hard Fault
    >> 如果 disable Bus/MemManage/Usage Fault, 則在這些異常處理執行過程中, 又會出現 Fault, 則觸發 Hard Fault


本文描述 CM3/CM4 的 Fault Exceptions 用法. 而 SCB registers 可以控制 Fault Exceptions, 也能提供引發 Exception 的原因及資訊
> 更深入的文件
> 完整的異常描述見 `Cortex-M3 Technical Reference Manual` 或者 `Cortex-M4 Technical Reference Manual`, <br>
這兩本參考手冊都可以在 [ARM Official](https://www.arm.com/) 中找到 <br>
> 另一個很好的參考書是由 **Joseph Yiu**編寫的`The Definitive Guide to the ARM Cortex-M3`
>> 這本書有中文版: 宋岩譯的`ARM Cortex-M3權威指南`

# Cortex-M Fault Exceptions and Registers

每個符合 CMSIS 的編譯器, 所提供的 `startup_device.s`, 都會定義好 Device 所有的 Exceptions 和 Interrupt Vector
> 這些 Vector Table 定義了異常或 ISR 的入口 Addrersses

下表給出了一個典型的Vector Table

```asm
    ...
    __Vectors DCD __initial_sp ; stack top
    DCD Reset_Handler          ; Reset Handle
    DCD NMI_Handler            ; NMI Handle
    DCD HardFault_Handler      ; Hard Fault
    DCD MemManage_Handler      ; MemManage Handler
    DCD BusFault_Handler       ; Bus Fault Handler
    DCD UsageFault_Handler     ; Usage Fault Handler
    DCD 0                      ; reserved
    ...
```

通常都會 Enable HardFault Exception, HardFault 具有固定的優先順序 (只低於 NMI), 且優先順序高於其它 Fault Exceptions 及 Interrupt
> HardFault Exception handle 在以下情況下會被執行:
> + 其它 `非 HardFault Exception`(e.g. Bus/MemManage/Usage Fault) 被 Disable, 並且這些 Fault Exceptions 被觸發
> + 在執行一個 `非 HardFault Exception` 中, 又產生`非 HardFault Exception`.

> 所有 `非 HardFault Exception` 可藉由設定 `SCB->SHCSR` 來開關 `非 HardFault Exception`

## Fault Exception 的 CSRs

SCB 定義在 `core_cm3.h`檔案中, 屬於 CMSIS Cortex-M3 核心外設介面抽象層的一部分, 其定義如下:

```c
/** @brief System Control Block (SCB) register structure definition */
typedef struct
{
    __I uint32_t CPUID;   /*!< Offset: 0x00 CPU ID Base Register*/
    __IO uint32_t ICSR;   /*!< Offset: 0x04 Interrupt Control State Register*/
    __IO uint32_t VTOR;   /*!< Offset: 0x08 Vector Table Offset Register*/
    __IO uint32_t AIRCR;  /*!< Offset: 0x0C Application Interrupt / Reset Control Register*/
    __IO uint32_t SCR;    /*!< Offset: 0x10 System Control Register*/
    __IO uint32_t CCR;    /*!< Offset: 0x14 Configuration Control Register*/
    __IO uint8_t SHP[12]; /*!< Offset: 0x18 System Handlers Priority Registers (4-7, 8-11, 12-15) */
    __IO uint32_t SHCSR;  /*!< Offset: 0x24 System Handler Control and State Register */
    __IO uint32_t CFSR;   /*!< Offset: 0x28 Configurable Fault Status Register*/
    __IO uint32_t HFSR;   /*!< Offset: 0x2C Hard Fault Status Register*/
    __IO uint32_t DFSR;   /*!< Offset: 0x30 Debug Fault Status Register */
    __IO uint32_t MMFAR;  /*!< Offset: 0x34 Mem Manage Address Register*/
    __IO uint32_t BFAR;   /*!< Offset: 0x38 Bus Fault Address Register*/
    __IO uint32_t AFSR;   /*!< Offset: 0x3C Auxiliary Fault Status Register*/
    __I uint32_t PFR[2];  /*!< Offset: 0x40 Processor Feature Register*/
    __I uint32_t DFR;     /*!< Offset: 0x48 Debug Feature Register*/
    __I uint32_t ADR;     /*!< Offset: 0x4C Auxiliary Feature Register*/
    __I uint32_t MMFR[4]; /*!< Offset: 0x50 Memory Model Feature Register*/
    __I uint32_t ISAR[5]; /*!< Offset: 0x60 ISA Feature Register*/
} SCB_Type;

#define SCS_BASE    (0xE000E000)            /*!< System Control Space Base Address */
#define SCB         ((SCB_Type *)SCB_BASE)  /*!< SCB configuration struct * /
```

> + `SCB->CCR` 控制 **除數為 0**和 **Non-align 記憶體訪問** 是否觸發 UsageFault
> + `SCB->SHCSR` 用來 enable `非 HardFault Exceptions`
>> 如果一個 `非 HardFault Exceptions` 被 Disable 並且發生相關的 Fault 時, Exception 會升級為 HardFault
> + `SCB->SHP` 控制 Exceptions 的優先順序


### Fault Exceptions 控制 Registers 列表

| Address                    | Register     | Default    | Description
| :-:                        | :-:          | :-:        | :-
| 0xE000ED14 <br> RW 特權級  | SCB->CCR     | 0x00000000 | 組態和控制暫存器: 包含控制 **除數為零** 和 **未對齊記憶體訪問** 是否觸發 UsageFault 的 Enable flag
| 0xE000ED18 <br> RW 特權級  | SCB->SHP[12] | 0x00       | 系統處理程序優先順序暫存器：控制異常處理程序的優先順序
| 0xE000ED24 <br> RW 特權級  | SCB->SHCSR   | 0x00000000 | 系統處理程序控制和狀態暫存器


+ `SCB->CCR` Register

    bit[3] ~ bit[4] 部分控制是否使能相應的用法Fault

    | Bits    | Name             | Description
    | :-:     | :-:              | :-
    | [31:10] | -                | 保留
    | [9]     | STKALIGN         | 表示進入異常時的堆疊對齊<br>0: 4-bytes 對齊 <br>1: 8-bytes 對齊<br>進入異常時, 處理器使用壓入堆疊的 PSR bit[9] 來指示堆疊對齊. <br>從異常返回時, 這個堆疊 bit 被用來恢復正確的堆疊對齊<br>
    | [8]     | BFHFNMIGN        | Enable 時, 使優先順序為 `-1`或`-2`運行的處理程序, 忽略載入和儲存指令引起的 BusFault <br>它用於 H/w fail, NMI 和 FAULTMASK 升級處理程序中: <br>0: 載入和儲存指令引起的資料匯流排故障會引起鎖定<br>1: 以優先順序-1或-2運行的處理程序忽略載入和儲存指令引起的資料匯流排故障<br>僅在處理程序和其資料, 處於絕對安全的 Register 時, 將該 bit 設為 1. <br>一般將該位用於探測系統裝置和橋接器以檢測並糾正控制路徑問題<br>
    | [7:5]   | -                | 保留
    | [4]     | DIV_0_TRP        | 當處理器進行除 0 操作 (`SDIV`或`UDIV`指令)時, 會導致故障或停止. <br>0: 不捕獲除以零故障<br>1: 捕獲除以零故障<br>當該 bit 設為 0 時, 除以 0 返回的商數為 0
    | [3]     | UNALIGN_TRP      | 使能非對齊訪問捕獲 <br>0: 不捕獲非對齊半字和字訪問<br>1: 捕獲非對齊半字和字訪問<br>如果該 bit 設為 1, 非對齊訪問產生一個使用故障. <br>無論UNALIGN_TRP是否設為1, 非對齊的LDM、STM、LDRD和STRD指令總是出錯。
    | [2]     | -                | 保留
    | [1]     | USERSETM PEND    | Enable 對 STIR 的無特權軟體訪問<br>0: 禁能<br>1: 使能
    | [0]     | NONEBASE THRDENA | 指示處理器如何進入執行緒模式<br>0: 處理器僅在沒有有效異常時, 才能夠進入執行緒模式<br>1: 處理器可以從 EXC_RETURN 值控制下的任何等級, 進入執行緒模式<br>


+ `SCB->SHP` Register
    > 以下 `SCB->SHP`用來設定異常處理程序的優先順序:
    > + SCB->SHP[0]: MemManage 的優先順序
    > + SCB->SHP[1]: BusFault的優先順序
    > + SCB->SHP[2]: UsageFault 的優先順序

    - 為了程式設計中斷和異常的優先順序, CMSIS 提供了`NVIC_SetPrioriity()`和`NVIC_GetPriority()`
        > 這兩個函數, 也位於 `core_cm3.h`中

        ```c

        /** \brief Set Interrupt Priority
         *
         *  This function sets the priority for the specified interrupt. The interrupt number can be positive
         *    to specify an external (device specific) interrupt, or negative to specify an internal (core)
         *    interrupt.
         *  Note: The priority cannot be set for every core interrupt.
         *
         * \param [in] IRQn Number of the interrupt for set priority
         * \param [in] priority Priority to set
         */
        static __INLINE void NVIC_SetPriority(IRQn_Type IRQn, uint32_t priority)
        {
            if(IRQn < 0) {
                /* set Priority for Cortex-M System Interrupts */
                SCB->SHP[((uint32_t)(IRQn) & 0xF)-4] = ((priority << (8 - __NVIC_PRIO_BITS)) & 0xff);
            }
            else {
                /* set Priority for device specific Interrupts */
                NVIC->IP[(uint32_t)(IRQn)] = ((priority << (8 - __NVIC_PRIO_BITS)) & 0xff);
            }
        }

        /** \brief Get Interrupt Priority
         *
         *  This function reads the priority for the specified interrupt. The interrupt number can be positive
         *     to specify an external (device specific) interrupt, or negative to specify an internal (core)
         *     interrupt.
         *  The returned priority value is automatically aligned to the implemented priority bits of the
         *     microcontroller.
         *
         * \param [in] IRQn Number of the interrupt for get priority
         * \return Interrupt Priority
         */
        static __INLINE uint32_t NVIC_GetPriority(IRQn_Type IRQn)
        {
            if(IRQn < 0) {
                /* get priority for Cortex-M system interrupts */
                return((uint32_t)(SCB->SHP[((uint32_t)(IRQn) & 0xF)-4] >> (8 - __NVIC_PRIO_BITS)));
            }
            else {
                /* get priority for device specific interrupts */
                return((uint32_t)(NVIC->IP[(uint32_t)(IRQn)] >> (8 - __NVIC_PRIO_BITS)));
            }
        }
        ```


    - 可由下面 c-cpde 更改異常優先順序

        ```c
        ...
        NVIC_SetPriority(MemManage_IRQn, 0xF0);
        NVIC_SetPriority(BusFault_IRQn, 0x80);
        NVIC_SetPriority(UsageFault_IRQn, 0x10);
        ...
        UsageFault_prio = NVIC_GetPriority(UsageFault_IRQn);
        ```


+ `SCB->SHCSR` Register

    與Fault異常相關位見下表的 bit[0, 1, 3 12, 13, 14, 16, 17, 18] 部分

    | Bit       | Name              | Description
    | :-:       | :-:               | :-
    | [31:19]   | -                 | 保留
    | [18]      | USGFAULTENA       | UsageFault enable bit, 設為 1 時 enable
    | [17]      | BUSFAULTENA       | BusFault enable bit, 設為 1 時 enable
    | [16]      | MEMFAULTENA       | MemManage enable bit, 設為 1 時 enable
    | [15]      | SVCALLPENDED      | SVC call pending bit, 如果異常掛起, 該 bit 讀為 1
    | [14]      | BUSFAULTPENDED    | BusFault pending bit, 如果異常掛起, 該 bit 讀為 1
    | [13]      | MEMFAULTPENDED    | MemManage Fault pending bit, 如果異常掛起, 該 bit 讀為 1
    | [12]      | USGFAULTPENDED    | UsageFault pending bit, 如果異常掛起, 該 bit 讀為 1
    | [11]      | SYSTICKACT        | SysTick 異常有效位, 如果異常有效, 該 bit 讀為 1
    | [10]      | PENDSVACT         | PendSV 異常有效 bit, 如果異常有效, 該 bit 讀為 1
    | [9]       | -                 | 保留
    | [8]       | MONITORACT        | 偵錯監控有效位, 如果偵錯監控有效, 該 bit 讀為 1
    | [7]       | SVCALLACT         | SVC 呼叫有效位, 如果 SVC 呼叫有效, 該 bit 讀為 1
    | [6:4]     | -                 | 保留
    | [3]       | USGFAULTACT       | UsageFault 有效位, 如果異常有效, 該 bit 讀為 1
    | [2]       | -                 | 保留
    | [1]       | BUSFAULTACT       | BusFault 異常有效位, 如果異常有效, 該 bit 讀為 1
    | [0]       | MEMFAULTACT       | MemManageFault 異常有效位, 如果異常有效, 該 bit 讀為 1

    - 下面的例子, 用於 enable 所有 非 HardFault(MemManage/Bus/Usage Fault)

        ```c
        // at core_cm3.h
        SCB - >SHCSR |= 0x00007000; /*enable Usage Fault, Bus Fault, and MMU Fault*/
        ```


### Fault Exceptions 的 Status Registers

Fault Status Register (SCB->CFSR and SCB->HFSR) 和 Fault Address Register(SCB->MMAR and SCB->BFAR),
包含 Fault 的詳細資訊, 以及異常發生時, 訪問的記憶體地址

| Address                    | Register     | Default    | Description
| :-:                        | :-:          | :-:        | :-
| 0xE000ED28 <br> RW 特權級  | SCB->CFSR    | 0x00000000 | 可組態 Fault Status Register: 包含 MemManage, BusFault, 或 UsageFault 的原因 bit
| 0xE000ED2C <br> RW 特權級  | SCB->HFSR    | 0x00000000 | HardFault Status Register: 包含用於指示 HardFault 原因 bit
| 0xE000ED34 <br> RW 特權級  | SCB->MMFAR   | 不可知     | MemManageFault AddrRegister: 包括產生 Fault 的 Address
| 0xE000ED38 <br> RW 特權級  | SCB->BFAR    | 不可知     | BusFault AddrRegiste: 包括產生 BusFault 的 Address

+ `SCB->CFSR` Register
    > `SCB->CFSR` bit fields
    > + bit[31 ~ 16]
    >> UsageFault 狀態暫存器 (UFSR)

    > + bit[15 ~ 8]
    >> BusFault 狀態暫存器 (BFSR)

    > + bit[7 ~ 0]
    >> MemManageFault 狀態暫存器 (MMFSR)


    - MMFSR: 指示 MemManageFault 的原因

        | Bits  | Name          | Description
        | :-:   | :-:           | :-
        | [7]   | MMARVALID     | MemManageFault AddrReg(MMAR) 有效標誌 <br>0: MMAR 中的值不是一個有效 Fault Address <br>1: MMAR 中保留一個有效 Fault Address <br>如果發生了一個 MemManageFault, 並由於優先順序的原因, 升級成一個 HardFault, 那麼 HardFault handle 必須將該 bit 設為 0
        | [6:5] | -             | 保留
        | [4]   | MSTKERR       | 進入異常時, Push stack 的操作, 引起的 MemManageFault <br>0: 無 Push stack Fault <br>1: 進入異常時, Push stack 操作引起了一個或一個以上的訪問違犯 <br>當該 bit 設為 1 時, 依然要對 SP 進行調節, 並且 stack 上下文區域的值, 可能不正確,<br>處理器沒有向 MMAR 中寫入 Fault Address
        | [3]   | MUNSTKERR     | 異常返回時, Pop stack 的操作, 引起的 MemManageFault<br>0: 無 Pop stack Fault<br>1: 異常返回時, Pop stack 操作已引起一個或一個以上的訪問違犯.<br>該 Fault 與處理程序相連, 這意味著當該 bit 為 1時, 原始的返回堆疊仍然存在. <br>處理器不能對返回失敗的 SP 進行調節, 並且不會執行新的儲存操作. <br> 處理器沒有向 MMAR 中寫入 Fault Address
        | [2]   | -             | 保留
        | [1]   | DACCVIOL      | Data 訪問違犯標誌 <br>0: 無資料訪問違犯 Fault<br>1: 處理器試圖在不允許執行操作的位置上, 進行載入和儲存<br>當該 bit 為 1 時, 異常返回 Pop Stack 的 `$PC` 指向出錯 Instruction.<br>處理器已在 MMAR 中, 載入了目標訪問的 Address
        | [0]   | IACCVIOL      | Instruction 訪問違犯標誌:<br>0: 無指令訪問違犯錯誤<br>1: 處理器試圖從不允許執行操作的位置上, 進行指令獲取<br>即使 MPU 被 Disable, 這一 Fault 也會在 XN(CM3 的 0xE0000000 ~ 0xFFFFFFFF 區域) 區定址時發生.<br>當該 bit 為 1 時, 異常返回的 Push stack 的 `$PC` 指向出錯指令<br>處理器沒有向 MMAR 中寫入 Fault Address

    - BFSR: 指示 BusFault 的原因

        | Bits  | Name          | Description
        | :-:   | :-:           | :-
        | [7]   | BFARVALID     | BusFault AddrReg(BFAR)有效標誌<br>0: BFAR 中的值, 不是有效 Fault Address<br>1: BFAR 中保留一個有效 Fault Address<br>在 Address 已知的 BusFault 發生後, 處理器將該 bit 設為 1. 該位可以被其他 Fault 清 0, 例如之後發生的 MemManageFault<br>如果發生 BusFault, 並由於優先順序原因升級為一個 HardFault, 那麼 HardFaul t處理程序必須將該 bit 設為 0
        | [6:5] | -             | 保留
        | [4]   | STKERR        | 進入異常時, Push stack 操作引起的 BusFault <br>0: 無 Push stack Fault<br>1: 進入異常時, Push stack 操作已引起一個或一個以上的 BusFault<br>當處理器將該 bit 設為 1 時, 依然要對 SP 進行調節, 並且 stack 上下文區域的值可能不正確.<br>處理器沒有向 BFAR 中寫入 Fault Address
        | [3]   | UNSTKERR      | 異常返回時, Pop Stack 操作引起的 BusFault <br>0: 無 Pop Stack Fault<br>1: 異常返回時, Pop Stack 操作已引起一個或一個以上的 BusFault<br>該 Fault 與處理程序相連, 這意味著當處理器將該 bit 設為 1 時, 原始的返回 stack 仍然存在.<br>處理器不能對返回失敗的 SP 進行調節, 並且不會執行新的儲存操作, 也未向 BFAR 中寫入 Fault Address
        | [2]   | IMPRECISERR   | 非精確 Data Bus 錯誤<br>0: 無非精確 Data Bus 錯誤<br>1: 已發生一個 Data Bus 錯誤, 但是 Stack Frame 中的返回地址, 與引起錯誤的 Instruction 無關.<br>當處理器將該 bit 設為 1 時, 不向 BFAR 中寫入 Fault Address, 這是一個非同步 Fault.<br><br>如果在當前程序的優先順序, 高於 BusFault 優先順序時, 檢測到該 Fault,<br>BusFault 會被 pending, 並只在 CPU 從所有更高優先順序 handles 中返回時, 才變為有效<br><br>如果在 CPU 進入非精確 BusFault 的 handle 前, 發生一個精確 Fault, 那麼 handle 同時對`IMPRECISERR` 和其中一個精確 Fault Staus bit 進行檢測,並判斷它們是否為 1
        | [1]   | PRECISERR     | 精確 DataBus 錯誤<br>0: 非精確 DataBus 錯誤<br>1: 已發生一個 DataBus 錯誤, 且異常返回的 Push Stack的 `$PC` 指向引起 Fault 的 Instruction <br>當處理器將該 bit 設為 1 時, 向 BFAR 中寫入 Fault Address
        | [0]   | IBUSERR       | InstructionBus 錯誤<br>0: 無 InstructionBus 錯誤<br>1: InstructionBus 錯誤<br>CPU 檢測到 pre-fetch Instruction 時的 InstructionBus 錯誤, 但只在其試圖簽發 Fault 指令時, 才將 IBUSERR 標誌設為 1.<br>當 CPU 將該 bit 設為 1 時, 不向 BFAR 中寫入 Fault Address

    - UFSR: UsageFault 的原因

        | Bits      | Name                  | Description
        | :-:       | :-:                   | :-
        | [15:10]   | -                     | 保留
        | [9]       | DIVBYZERO             | 0: 無除 0 Fault 或 Disable 除 0 偵測 <br>1: 處理器已執行 SDIV 或 UDIV 指令(除 0) <br>當 CPU 將該 bit 設為 1 時, 異常返回 Push Stack 的 `$PC` 指向執行 除 0 的 Instruction.<br>ps. 通過將 `bit[CCR->DIV_0_TRP]` 設為 1, 來 enable 除 0 捕獲, 默認是 Disable
        | [8]       | UNALIGNED             | 0: 無 Non-align 訪問 Fault, 或 Disable Non-align 訪問捕獲 <br>1: CPU 已進行了一次 Non-align 的儲存器訪問.<br>ps. 通過將 `bit[CCR->UNALIGN_TRP]` 設為 1, 來 enable Non-align 訪問捕獲, 默認是 Disable. <br>Non-align 的 LDM, STM, LDRD 和 STRD 指令總是出錯, 與 UNALIGN_TRP 的設定無關
        | [7:4]     | -                     | 保留
        | [3]       | NOCP                  | 無 Co-processor UsageFault, 處理器不支援 co-processor 指令<br>0: 試圖訪問一個 Co-processor 未引起 UsageFault <br>1: CPU 已試圖訪問一個  Co-processor
        | [2]       | INVPC (Invalid $PC)   | EXC_RETURN 的無效 `$PC`載入, 引起的 UsageFault: <br>0: 沒有發生無效 `$PC`載入 UsageFault<br>1: CPU 已試圖將 EXC_RETURN 非法載入`$PC`, 作為一個無效的上下文或一個無效的 EXC_RETURN 值 <br>當該 bit 被設為 1 時, 異常返回 Push stack 的 `$PC`,  指向嘗試執行非法 `$PC` 載入的 Instruction
        | [1]       | INVSTATE (Invalid State) | 無效狀態 UsageFault<br>0: 未發生無效狀態 UsageFault<br>1: CPU 已試圖執行一個非法使用 EPSR 的 Instruction<br>當該 bit 設為 1 時, 異常返回 Push stack 的 `$PC` 指向一個嘗試非法使用 EPSR 的 Instruction.<br>如果一個未定義的 Instruction 使用了 EPSR, 則該 bit 不被設為 1
        | [0]       | UNDEFINSTR            | 未定義的 Instruction UsageFault<br>0: 無未定義的 Instruction UsageFault <br>1: CPU 已試圖執行一個未定義的 Instruction.<br>當該 bit 設為 1 時, 異常返回 Push stack 的 `$PC` 指向未定義的 Instruction.<br>未定義的 Instruction, 是一條不能被處理器譯碼的 Instruction

## SCB->HSFR Register

`SCB->HSFR` 提供關於啟動 HardFault handle 的事件的資訊, 寫入 1 清零相應 bit

| Bits      | Name                  | Description
| :-:       | :-:                   | :-
| [31]      | DEBUGEVT              | HardFault 因偵錯事件產生, 保留供 debug 使用. <br>對 register 執行 write 操作時, 必須向該 bit 寫入 0, 否則該行為不可預知.
| [30]      | FORCED                | 指示 HardFault 是否由 Re-direct 產生, `非 HardFault` 的處理程序無法執行時, 會 Re-direct 成 HardFault <br>0: HardFault 不是因為`非 HardFault` Re-direct 產生的<br>1: HardFault 是通過`非 HardFault` Re-direct 產生的<br>當該 bit 設為 1時, HardFault handle 必須讀其他 Fault State Register, 以找出 Fault 原因
| [29:2]    | -                     | 保留
| [1]       | VECTTBL               | 指示一個在 Exception 處理過程中, 讀 Vector Table 而引起的 BusFault<br>0: 讀 Vector Table 未引起 BusFault<br>1: 讀 Vector Table 引起了 BusFault<br>這一錯誤通常情況下, 都由 HardFault handle 來處理
| [0]       | -                     | 保留


## SCB->MMFAR 和 SCB->BFAR Registers

為了確定發生了哪個 Fault Exceptions, 以及什麼原因引起的 Fault Exceptions, 需要檢測 Fault Status Register

+ 如果`SCB->CFSR` 的 `bit[BFARVALID]` 有效(為 1), 則`SCB->BFAR`的值, 表示引起 BusFault 的 Memory Address.

+ 如果`SCB->CFSR` 的 `bit[MMFARVALID]` 有效(為 1), 則`SCB->MMFAR`的值, 表示引起 MemManageFault 的 Memory Address.


# Reference

+ [Cortex-M3和Cortex-M4 Fault異常應用之一 ----- 基礎知識](https://blog.csdn.net/zhzht19861011/article/details/8645661)
