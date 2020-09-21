uboot quick start
---

[u-boot (Universal Boot Loader) source code](ftp://ftp.denx.de/pub/u-boot/)

the version is `201907` or `latest`

# Defiitions

+ `IPL` (Initial Program Loader)
    > 是專門用於作業系統啟動引導的程式, 主要功能包括載入和運行啟動時必須的檔案,
    提供可配置的啟動引導功能表和設置, 支援多系統並存環境下的選擇和引導功能.
    可當作 ROM code

    ```
    # bring-up flow
    (ROM)     (SRAM)       (DDR)
     IPL --> uboot_SPL --> uboot --> kernel
    ```

+ `TLB` (Translation Lookaside Buffer)
    > 是一塊高速 cache buffer, 主要存放將 virtual address 映射至 physical address 的標籤頁表條目.
    >> 系統用虛擬地址首先發往 TLB 確認是否命中cache, 如果 cache hit 直接可以得到物理地址.
    否則, 一級一級查找頁表獲取物理地址.
    並將虛擬地址和物理地址的映射關係緩存到 TLB 中

+ `MMU` (Memory Management Unit)
    > 內存管理單元, 是 CPU 用來管理 virtual/physical memory 的控制線路.
    同時也負責 virtual address 映射到 physical address,
    以及提供硬件機制的內存訪問授權.


+ `DM` ([U-boot Driver Model](note_uboot_dm.md))
    > 為驅動的定義和訪問接口提供了統一的方法. 提高了驅動之間的兼容性以及訪問的標準型.
    uboot driver model 和 kernel device driver 類似, 但是又有所區別.

    > uclass 和 udevice 都是動態生成的. 在解析 fdt 中的設備的時候, 會動態生成 udevice.
    然後找到 device 對應的 driver, 通過 driver 中的 uclass id 得到 uclass_driver id.
    從 uclass list 中查找對應的 uclass 是否已經生成, 沒有生成的話則動態生成 uclass.

    ```
            user
              |
            uclass ------- uclass_driver
              |
        +-----+-----+
        |           |
    udevice       udevice
        |           |
     driver       driver
        |           |
      H/w          H/w
    ```

    - `udevice` (uboot device)
        > 設備對象, 可以理解為kernel中的device

    - `driver`
        > udevice 的驅動, 可以理解為 kernel 中的 device_driver.
        和底層硬件設備通信, 並且為設備提供面向上層的接口

    - `uclass` (uboot class)
        > 使用相同 interface 的 device group.
        e.g. GPIO uclass 提供了get/set接口.
             一個 I2C uclass 下可能有 10 個 I2C 端口,
             4 個使用一個 driver, 另外 6 個使用另外一個 driver.

    - `uclass_driver`
        > 對應 uclass 的驅動程序.
        主要提供 uclass 操作時, 如綁定 udevice 時的一些操作


# Concepts

u-boot 啟動流程分為兩階段

## [stage1](note_uboot_stage_1.md)

通常將依賴於 CPU 體系結構的部分(e.g CPU configuraion)都放在 stage1, 而且會用 assembly 實做

+ enter pointer
    > 從 `arch/arm/cpu/u-boot.lds`, 可以確定 uboot 的入口為 `_start`, 該定義在`arch/arm/lib/vectors.S`中

    ```lds
    OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
    OUTPUT_ARCH(arm)
    ENTRY(_start)
    SECTIONS
    {
        . = 0x00000000;
        . = ALIGN(4);
        .text : {
            *(.__image_copy_start)
            *(.vectors)
            arch/arm/cpu/armv7/start.o (.text*)
        }
        .__efi_runtime_start : {
            *(.__efi_runtime_start)
        }
        .efi_runtime : {
            *(.text.efi_runtime*)
            *(.rodata.efi_runtime*)
            *(.data.efi_runtime*)
        }
        .__efi_runtime_stop : {
            *(.__efi_runtime_stop)
        }
        .text_rest : {
            *(.text*)
        }
        . = ALIGN(4);
        .rodata :   { *(SORT_BY_ALIGNMENT(SORT_BY_NAME(.rodata*))) }
        . = ALIGN(4);

        .data : {
            *(.data*)
        }
        . = ALIGN(4);
        . = .;
        . = ALIGN(4);

        .u_boot_list : {
            KEEP(*(SORT(.u_boot_list*)));
        }
        . = ALIGN(4);
        .efi_runtime_rel_start : {
            *(.__efi_runtime_rel_start)
        }
        .efi_runtime_rel : {
            *(.rel * .efi_runtime)
            *(.rel*.efi_runtime.*)
        }
        .efi_runtime_rel_stop : {
            *(.__efi_runtime_rel_stop)
        }
        . = ALIGN(4);
        .image_copy_end : {
            *(.__image_copy_end)
        }
        .rel_dyn_start : {
            *(.__rel_dyn_start)
        }
        .rel.dyn : {
            *(.rel*)
        }
        .rel_dyn_end : {
            *(.__rel_dyn_end)
        }
        .end : {
            *(.__end)
        }
        _image_binary_end = .;
        . = ALIGN(4096);

        .mmutable : {
            *(.mmutable)
        }
        .bss_start __rel_dyn_start (OVERLAY) : {
            KEEP(*(.__bss_start));
            __bss_base = .;
        }
        .bss __bss_base (OVERLAY) : {
            *(.bss*)
            . = ALIGN(4);
            __bss_limit = .;
        }
        .bss_end __bss_limit (OVERLAY) : {
            KEEP(*(.__bss_end));
        }
        .dynsym _image_binary_end : { *(.dynsym) }
        .dynbss :   { *(.dynbss) }
        .dynstr :   { *(.dynstr*) }
        .dynamic :  { *(.dynamic*) }
        .plt :      { *(.plt*) }
        .interp :   { *(.interp*) }
        .gnu.hash : { *(.gnu.hash) }
        .gnu :      { *(.gnu*) }
        .ARM.exidx : { *(.ARM.exidx*) }
        .gnu.linkonce.armexidx : { *(.gnu.linkonce.armexidx.*) }
    }
    ```

+ 進入到`_start`後, 會再跳轉到 `reset` 中運行, 而`reset`的實作, 對於不同架構的 CPU 有不一樣
    > armv7 定義在 `arch/arm/cpu/armv7/start.S`

    - 在 `reset`後面, 會跟著中斷向量表

        ```nasm
        b    reset      /* 中斷向量表, 跳轉到reset */
        ldr    pc, _undefined_instruction
        ldr    pc, _software_interrupt
        ldr    pc, _prefetch_abort
        ldr    pc, _data_abort
        ldr    pc, _not_used
        ldr    pc, _irq
        ldr    pc, _fiq
        ```

+ `reset` 主要的工作

    - 設置 CPU 模式, 使 CPU 進入 SVC 模式 (supervisor mode)
    - 停止 IRQ/FIQ 中斷
    - 初始化 `cp15` 協處理器, 暫時關閉 MMU, I-Cache, D-Cache.
        >　`cpu_init_cp15`

    - 配置 CPU clock 相關設定
        > `cpu_init_crit` 再跳轉到 `lowlevel_init.S`.

    - 最後跳轉到 `_main` (at arch/arm/lib/crt0.S)

        - 設置 stack pointer (sp)
        - 進入 `board_init_f()`, 設置初期 board 設定, 並計算 relocation 的相關參數
            > + disable watch dog
            > + initial serial port

        - 進行 `relocate_code`, 將執行的位置搬移到 High address, 並跳轉過去, 以方便後續 kernel 運行在 Low address
        - `relocate_vectors` 重設 vector table address
        - 歸零 `.bss` section
        - 跳轉到 stage2 `board_init_r()`

### 為何要設置 CPU 為 supervisor mode

| 處理器模式     | 說明    | 備註        |
| :-             | :-      | :-          |
| 用戶(usr)      | 正常程序工作模式                | 此模式下程序不能夠訪問一些受操作系統保護的系統資源, |
|                |                                 | 應用程序也不能直接進行處理器模式的切換 |
| 系統(sys)      | 用於支持操作系統的特權任務等    | 與用戶模式類似,但具有可以直接切換到其它模式等特權 |
| 快中斷(fiq)    | 支持高速數據傳輸及通道處理      | FIQ 異常響應時進入此模式    |
| 中斷(irq)      | 用於通用中斷處理                | IRQ 異常響應時進入此模式    |
| 管理(svc)      | 操作系統保護代碼                | 系統復位和軟件中斷響應時進入此模式 |
| 中止(abt)      | 用於支持虛擬內存和/或存儲器保護 | 在 ARM7TDMI 沒有大用處 |
| 未定義(und)    | 支持硬件協處理器的軟件仿真      | 未定義指令異常響應時進入此模式 |

+ ARM CPU mode
   > 7 種模式中, 除用戶 usr 模式外, 其它模式均為特權模式

    - 中止(abt)和未定義(und)模式
        > 首先可以排除的是, 中止abt和未定義und模式, 那都是不太正常的模式,
        此處程序是正常運行的, 所以不應該設置 CPU 為其中任何一種模式, 所以可以排除.

    - 快中斷(fiq)和中斷(irq)模式
        > 對於快中斷(fiq)和中斷(irq)來說, 此處 uboot 初始化的時候, 也還沒啥中斷要處理和能夠處理,
        而且即使是註冊了終端服務程序後, 能夠處理中斷, 那麼這兩種模式, 也是自動切換過去的,
        所以, 此處也不應該設置為其中任何一種模式.

    - 用戶(usr)模式
        > 雖然從理論上來說, 可以設置 CPU 為用戶 usr 模式,
        但是由於此模式無法直接訪問很多的硬件資源, 而 uboot 初始化, 就必須要去訪問這類資源,
        所以此處可以排除, 不能設置為用戶(usr)模式.

    - 系統(sys)模式 vs 管理(svc)模式
        > **sys 模式和 usr 模式所用的寄存器組都是一樣的**,
        但是 sys 模式增加了一些在 usr 模式下不能訪問的資源權限.

        > 而 svc 模式本身就屬於特權模式, 可以訪問那些受控資源, 而且, 比 sys 模式還多了一些自己模式下的影子寄存器,
        所以, 相對 sys 模式來說, 可以訪問資源的能力相同, 但是擁有更多的硬件資源.

        > 從理論上來說, 雖然可以設置為 sys 和 svc 模式的任一種,
        但是從 uboot 方面考慮, 其要做的事情是初始化系統相關硬件資源,
        需要獲取儘量多的權限, 以方便操作並初始化硬件.
        >> uboot 最終目的是為了啟動 Linux kernel, 在做好準備工作跳轉到kernel之前
        (即初始化硬件, 準備好 kernel 和 rootfs 等),
        本身就要滿足一些條件, 其中一個條件, 就是要求 CPU 處於 SVC 模式的

### 為什麼要關 watch dog

運行的程序如果超出 watch dog timeout, 就會導致重啟 CPU, 這樣程序永遠也運行不完.

### 為什麼要關中斷

在 vector table 尚未設定給 CPU, 或是 ISR list 還未設給 interrupt controller 時,
外部產生不預期的中斷, 就會跳轉到未知的地方去

### 為什麼要設置 clock

上電後, 振盪器啟動, CPU 就可以工作.
設置 clock 是為了周邊裝置 (PCLK) 或是其他 H/w modules 的 clock 頻率

### 為什麼要關閉 catch 和 MMU

+ i-catch (instruction catch)
    > 上電就會更新

+ d-cache (data catch)
    > 剛上電時, 有可能 RAM 的 data 還沒有 catch 過來.
    此時就就可能從 d-catch 取到錯誤資料

+ MMU
    > 設定 H/w register 是用 physical address.
    在前期為了方便, 先將 MMU 關閉

### 為什麼要做 relocation

在以前的板子上, u-boot 有可能是運行在 NOR FLASH 或 ROM 上, 空間小執行慢, 而且不支持 write 操作,
DDR 初始化完畢之後, 需要將其 relocate 到 DDR 去運行, 空間大執行的速度也比較快, 也支持 write 操作.

同時考慮到後續的 kernel 是在 DDR 的 Low memory 解壓縮並執行的,
為了避免麻煩, **u-boot 將使用 DRAM 的 top address**, 即 `gd->ram_top`所代表的位置.

+ relocate 會造持執行 address 混亂.
一般執行地址都是在編譯時由 linker 指定的, 為了確保搬移後可以執行, 有兩種方法.

    - linker 就直接使用搬移後的 address (link script)
    - 開啟 PIC (Position independent code) 選項來編譯. linker 會**使用相對位址**來連結
        > [PIC(與位置無關代碼)在u-boot上的實現](http://blog.chinaunix.net/uid-20528014-id-4445271.html)

## [stage2](note_uboot_stage_2.md)

通常用 C 來實現, 這樣可以實現複雜的功能, 而且有更好的可讀性和移植性

# Source code

## uboot directory

```
├── api             # 存放 uboot 提供的 API 接口函數
├── arch            # 與 CPU 結構相關的程式碼
│   ├── arm/
│   │   ├── cpu/
│   │   │   ├── armv7/
│   │   │   │   ├── start.S
│
├── board           # 根據不同開發板定製的程式碼
├── cmd             # 顧名思義, 大部分的命令的實現都在這個文件夾下面
├── common          # 通用的程式碼, 涵蓋各個方面
│   ├── spl/        # Second Program Loader, 即相當於二級 uboot 啟動
│   ├── main.c
│
├── configs         # 各個板子的對應的配置文件都在裡面
├── disk            # 對 disk 一些操作相關的程式碼(e.g. disk partition), 都在這個文件夾裡面
├── doc             # 文件, 一堆README開頭的檔案
├── Documentation
├── drivers         # 各式各樣的 device drivers 都在這裡面
├── dts             # device tree 配置
├── env
├── examples
├── fs              # 檔案系統, 支援嵌入式開發板常見的檔案系統
├── include         # 標頭檔案, 已通用的標頭檔案為主
├── lib             # 通用庫檔案
├── net             # 與網路有關的代碼, BOOTP 協議, TFTP, RARP 協議和 NFS檔案系統的實現.
├── post            # Power On Self Test
├── scripts
├── test
├── tmp
├── tools           # 輔助程式, 用於編譯和檢查uboot目標檔案

```

+ The layer of directory

    ```
                    arch
                      |
                      v
                board/include
                      |
                      v
            common/cmd/lib/api
                      |
                      v
        drivers/fs/disk/net/dts/post

    _______ support class __________

            doc/tools/examples

    ```

## [實務範例操作](note_uboot_practice.md)

## [Legacy uImage vs. FIT uImage](note_uboot_img_type.md)

# eMMC

## Normal partitions

大部分 eMMC 都有類似如下的分區, 其中 BOOT, RPMB 和 UDA 一般是默認存在的, gpp 分區需要手動創建.

```
    eMMC
    +--------------------------------+
    | Boot Area partition 1          |  \
    +--------------------------------+   BOOT
    | Boot Area partition 2          |  /
    +--------------------------------+
    | Replay Protected Memory Block  |   RPMB
    +--------------------------------+
    | General Purpose partition 1    |  \
    +--------------------------------+   |
    | General Purpose partition 2    |   |
    +--------------------------------+   GPP
    | General Purpose partition 3    |   |
    +--------------------------------+   |
    | General Purpose partition 4    |  /
    +--------------------------------+
    | User Data area                 |   UDA
    +--------------------------------+

```

+ BOOT
    > 支持從 eMMC 啟動系統

    - BOOT 區中一般存放的是 bootloader 或者相關配置參數,
    這些參數一般是不允許修改的, 所以 kernel 默認情況下是 read-only

        1. 從 kerel 開關 `rd/wr`

            ```bash
            $ echo 0 > /sys/block/mmcblk0boot1/force_ro # enable write (force read-only)
            $ echo 1 > /sys/block/mmcblk0boot1/force_ro # disable write
            ```

+ RPMB
    > 通過 HMAC SHA-256 和 Write Counter 來保證保存在 RPMB 內部的數據不被非法篡改.
    在實際應用中, RPMB 分區通常用來保存安全相關的數據, 例如指紋數據, 安全支付相關的密鑰等.

+ GPP
    > 主要用於存儲系統或者用戶數據.
    General Purpose Partition 在出廠時, 通常是不存在的,
    需要主動進行配置後, 才會存在.

+ UDA
    > 通常會進行再分區, 然後根據不同目的存放相關數據, 或者格式化成不同 file system.
    例如 Android 系統中, 通常在此區域分出 boot、system、userdata 等分區.

## Manually partition

uboot 下操作 boot 分區需要打開 `CONFIG_SUPPORT_EMMC_BOOT`

```
Device Drivers > MMC Host controller Support > Support some additional features of the eMMC boot partitions
Symbol: SUPPORT_EMMC_BOOT
```

If U-Boot has been built with `CONFIG_SUPPORT_EMMC_BOOT` some additional mmc commands are available:

```
mmc bootbus <boot_bus_width> <reset_boot_bus_width> <boot_mode>
mmc bootpart-resize
mmc partconf <boot_ack>     # set PARTITION_CONFIG field
mmc rst-function            # change RST_n_FUNCTION field between 0|1|2 (write-once)
```

+ `CONFIG_BOOTARGS`
    > 是 u-boot 向 Linux kernel 傳遞的參數, 實際上這個宏值就是環境變量中的 bootargs 的值

    1. 使用 nfs 文件系統

        ```
        #define CONFIG_BOOTARGS     "console=ttySAC0,115200 noinitrd" \
                                    "root=/dev/nfs rw nfsroot=192.168.1.2:/home/yanghao/nfs/rootfs" \
                                    "ip=192.168.1.4:192.168.1.2:192.168.1.1:255.255.255.0::eth0:off"

        相當於執行
        => setenv bootargs=...
        ```

+ `CONFIG_BOOTCOMMAND`
    > 是系統在上電自動執行時, 所執行的命令對應環境變量中 bootcmd 的值
    >> 可從 kconfig 設定: `Enable a default value for bootcmd` -> type your commonds

    - example

        1. auto partition when power on

            ```
            # kconfig set
            env set partitions \"name=aa,size=16MB,type=data;name=bb,size=32M,type=data;\"; gpt write mmc 0 $partitions
            ```

        1. 利用 NFS 傳輸 kernel image 並完成啟動

            ```
            #define CONFIG_BOOTCOMMAND  "nfs 0x30008000 192.168.1.2:/home/xxx/nfs/zImage; bootm 0x30008000"
            /* 系統啟動時會執行這個命令, 將 host (IP=192.168.1.2) 的檔案 "/home/xxx/nfs/zImage"
            copy 到內存 0x30008000, 然後再跳轉到該地址去執行 */

            相當於
            set bootcmd=...
            ```

        1. 如果檔案在 NAND Flash

            ```
            #define CONFIG_BOOTCOMMAND  "nand read 0x30008000 0x600000 0x210000; bootm 0x30008000"
            /* u-boot 先從 NAND Flash 中讀取檔案到內存, 然後去執行檔案 */

            相當於
            set bootcmd=...
            ```

+ switch partition of eMMC
    > 默認分區是 UDA, 而 eMMC 每個分區都是獨立編址的.
    所以要使用 boot 分區需要 switch partition


# System Control Coprocessor Registers `CP15`

| 寄存器編號 | 基本作用         | 在 MMU中的作用       | 在PU中的作用 |
| :-         | :-               | :-                   | :-           |
| C0         | ID 編碼(只讀)    | ID 編碼和 cache 類型 |              |
| C1         | 控制位(可讀寫)   | 各種控制位           |              |
| C2         | 存儲保護和控制   | 地址轉換表基地址     | Cachability 的控制位 |
| C3         | 存儲保護和控制   | 域訪問控制位         | Bufferablity 控制位  |
| C4         | 存儲保護和控制   | 保留                 | 保留           |
| C5         | 存儲保護和控制   | 內存失效狀態         | 訪問權限控制位 |
| C6         | 存儲保護和控制   | 內存失效地址         | 保護區域控制   |
| C7         | 高速緩存和寫緩存 | 高速緩存和寫緩存控制 |                |
| C8         | 存儲保護和控制   | TLB 控制             | 保留           |
| C9         | 高速緩存和寫緩存 | 高速緩存鎖定         |                |
| C10        | 存儲保護和控制   | TLB 鎖定             | 保留           |
| C11        | 保留             |                      |                |
| C12        | 保留             |                      |                |
| C13        | 進程標識符       | 進程標識符           |                |
| C14        | 保留             |                      |                |
| C15        | 因不同設計而異   | 因不同設計而異       | 因不同設計而異 |

此 controller 包含 16 個 registers, 編號從 C0 ~ C15

## CP15 中的寄存器介紹

CP15 有寄存器 C0 ~ C15, 操作 CP15的 instructions 如下:

```nasm
MRC{cond} p15,<Opcode_1>,<Rd>,<CRn>,<CRm>,<Opcode_2>
MCR{cond} p15,<Opcode_1>,<Rd>,<CRn>,<CRm>,<Opcode_2>
```

+ `MRC` (Move from coprocessor register to CPU register)
    > CP15 到 ARM register 的數據傳送指令 (讀出協處理器寄存器).

+ `MCR` (Move CPU register to coprocessor register)
    > ARM register 到 CP15 的數據傳送指令 (寫入協處理器寄存器).

+ `cond`
    > 為指令執行的條件碼.
    當 cond 忽略時, 指令為無條件執行.

+ `Opcode_1`
    > 協處理器的特定操作碼. 對於 CP15 register 來說, `opcode1 = 0`

+ `Rd`
    > 作為 src register 的 ARM寄存器, 其值將被傳送到協處理器寄存器中,
    或者將協處理器寄存器的值, 傳送到該寄存器裡面, 通常為 R0

+ `CRn`
    > target register ID of CP15, 其編號是 C0 ~ C15.

+ `CRm`
    > 協處理器中附加的目標寄存器或源運算元暫存器, 用於區分同一個編號的不同物理暫存器.
    **如果不需要設置附加信息, 將 CRm 設置為 c0**, 否則結果未知

+ `Opcode_2`
    > 可選的協處理器特定操作碼.
    用來區分同一個編號的不同物理寄存器, 當不需要提供附加信息時, 指定為 0


+ example

    - assembly

        ```nasm
        mrc p15, 0, r0, c1, c0, 0   @ 將 CP15 的寄存器 C1 的值讀到 r0 中
        mcr p15, 0, r0, c7, c7, 0   @ 關閉 ICaches 和 DCaches
        mcr p15, 0, r0, c8, c7, 0   @ 使無效整個數據 TLB 和指令 TLB
        ```

    - C syntax

        ```c
        __asm__(                            // 使用 __asm__ 可以在C函數中執行彙編語句
            "mrc p15, 0, r1, c1, c0, 0\n"
            "orr r1, r1, #0xc0000000  \n"
            "mcr p15, 0, r1, c1, c0, 0\n"
            :::"r1"                         // 向GCC聲明: 我對 r1 作了改動
        );　
        ```

## CP15 的寄存器 C0

C0 對應到兩個標識符寄存器, 由 CP15中的指令來指定要實際要訪問哪個物理寄存器:
> + 主標識符寄存器
> + cache 類型標識符寄存器

### 主標識符寄存器 `Opcode_2 = 0`

```nasm
MRC P15, 0, R0, C0, C0, 0    @# 將主標示符寄存器的內容讀到 AMR寄存器 R0 中
```

| 30~24        | 23~20      | 19~16          | 15~4       | 3~0          |
| :-           | :-         | :-             | :-         | :-           |
| 由生產商確定 | 產品子編號 | ARM 體系版本號 | 產品主編號 | 處理器版本號 |


### cache 類型標識符寄存器 `Opcode_2 = 1`

```nasm
MRC P15, 0, R0, C0, C0, 1   @# 將 cache 類型標識符寄存器的內容讀到 AMR寄存器 R0中
```

| 30~29 | 28~25      | 24  | 23~12            | 11~0
| ---   | ---        | --- | ---              | ---
| 000   | 屬性字段   | S   | d-cache 相關屬性 | i-cache 相關屬性

各部分的定義如下所示:

| bit field  | description
| ---        | ---
| bit[28:25] | 主要用於定義對於寫回類型的 cache 的一些屬性
| bit[24]    | 定義系統中的 d-cache 和 i-cache 是分開的還是統一的：
|            |     0: 系統的 d-cache 和 i-cache 是統一的
|            |     1: 系統的 d-cache 和 i-cache 是分開的
| bit[23:12] | 定義 d-cache 的相關屬性,
|            |     如果 bit[24] 為 0, 本字段定義整個 cache 的屬性
|            |
| bit[11:0]  | 定義 i-cache 的相關屬性,
|            |     如果 bit[24] 為 0, 本字段定義整個 cache 的屬性


+ bit[28:25]用於定義 `Write back` 和 `Write through`屬性

    | binary value | cache 類型     |cache 內容清除方法 | cache 內容鎖定方法
    | ---          | ---            | ---               | ---
    | 0b0000       | Write through  | 不需要內容清除    | 不支持內容鎖定
    | 0b0001       | Write back     | 數據塊讀取        | 不支持內容鎖定
    | 0b0010       | Write back     | 由寄存器 C7 定義  | 不支持內容鎖定
    | 0b0110       | Write back     | 由寄存器 C7 定義  | 支持格式 A
    | 0b0111       | Write back     | 由寄存器 C7 定義  | 支持格式 B


+ bit[23：12]用於定義 d-cache 的屬性, bit[11: 0]用於定義 i-cache 的屬性, 兩者格式相同

    | 11~9  | 8~6        | 5~3            | 2   | 1~0
    | ---   | ---        | ---            | --- | ---
    | 000   | cache 容量 | cache 相聯特性 | M   | cache 塊大小

+ bits[1:0]

    | binary value | cache 塊大小
    | ---          | ---
    | 0b00         | 2 * word
    | 0b01         | 4 * word
    | 0b10         | 8 * word
    | 0b11         | 16 * word

+ bits[5:3]

    | binary value | M=0                 | M=1
    | ---          | ---                 | ---
    | 0b000        | 1 路 相聯(直接映射) | 沒有 cache
    | 0b001        | 2 路 相聯           | 3 路 相聯
    | 0b010        | 4 路 相聯           | 6 路 相聯
    | 0b011        | 8 路 相聯           | 12 路 相聯
    | 0b100        | 16 路 相聯          | 24 路 相聯
    | 0b101        | 32 路 相聯          | 48 路 相聯
    | 0b110        | 64 路 相聯          | 96 路 相聯
    | 0b111        | 128 路 相聯         | 192 路 相聯

+ bits[8:6]

    | binary value | M=0    | M=1
    | ---          | ---    | ---
    | 0b000        | 0.5KB  | 0.75 KB
    | 0b001        | 1 KB   | 1.5 KB
    | 0b010        | 2 KB   | 3 KB
    | 0b011        | 4 KB   | 6 KB
    | 0b100        | 8 KB   | 12 KB
    | 0b101        | 16 KB  | 24 KB
    | 0b110        | 32 KB  | 48 KB
    | 0b111        | 64 KB  | 96 KB

## CP15 的寄存器 C1
C1 是一個控制寄存器, 它包括以下控制功能:
> + 禁止或使能 MMU 以及其他與存儲系統相關的功能
> + 配置存儲系統以及 ARM 處理器中的相關部分的工作

```nasm
mrc p15, 0, r0, c1, c0{, 0}     @// 將 CP15 的寄存器 C1 的值讀到 r0 中
mcr p15, 0, r0, c1, c0{, 0}     @// 將 r0 的值寫到 CP15 的寄存器 C1 中
```

| bit order       | description
| ---             | ---
| M (bit[0])      | 0:禁止MMU或者PU;
|                 | 1:使能MMU或者PU
|                 | 如果系統中沒有MMU及PU, 讀取時該位返回0, 寫入時忽略該位
| A (bit[1])      |     0:禁止地址對齊檢查;
|                 |     1:使能地址對齊檢查
| C (bit[2])      | 當 d-cache 和 i-cache 分開時, 本控制位禁止/使能 d-cache.
|                 | 當 d-cache和 i-cache 統一時, 該控制位禁止/使能整個 cache
|                 |     0:禁止 data/整個 cache;
|                 |     1:使能 data/整個 cache
|                 | 如果系統中不含 cache, 讀取時該位返回0.寫入時忽略
|                 | 當系統中不能禁止 cache 時, 讀取時返回1.寫入時忽略
| W (bit[3])      |     0:禁止寫緩衝;
|                 |     1:使能寫緩衝
|                 | 如果系統中不含寫緩衝時, 讀取時該位返回 0. 寫入時忽略.
|                 | 當系統中不能禁止寫緩衝時, 讀取時返回1. 寫入時忽略.
| P (bit[4])      | 對於向前兼容 26 位地址的 ARM處理器, 本控制位控制 PROG32 控制信號
|                 |     0:異常中斷處理程序進入 32 位地址模式;
|                 |     1:異常中斷處理程序進入 26 位地址模式
|                 | 如果本系統中不支持向前兼容 26 位地址, 讀取該位時返回1, 寫入時忽略
| D (bit[5])      | 對於向前兼容 26 位地址的 ARM 處理器, 本控制位控制 DATA32 控制信號
|                 |     0:禁止26位地址異常檢查;
|                 |     1:使能26位地址異常檢查
| L (bit[6])      | 對於 ARMv3 及以前的版本, 本控制位可以控制處理器的中止模型
|                 |     0:選擇早期中止模型;
|                 |     1:選擇後期中止模型
| B (bit[7])      | 對於存儲系統同時支持 big-endian 和 little-endian 的ARM系統, 本控制位配置系統的存儲模式
|                 |     0:little endian;
|                 |     1:big endian
|                 | 對於只支持 little-endian 的系統, 讀取時該位返回0, 寫入時忽略
|                 | 對於只支持 big-endian 的系統, 讀取時該位返回1, 寫入時忽略
| S (bit[8])      | 在基於MMU的存儲系統中, 本位用作系統保護
| R (bit[9])      | 在基於MMU的存儲系統中, 本位用作ROM保護
| F (bit[10])     | 0:由生產商定義
| Z (bit[11])     | 0:禁止跳轉預測功能;
|                 | 1:使能跳轉預測指令
| I (bit[12])     | 當 d-cache和 i-cache是分開的, 本控制位禁止/使能 i-cache
|                 |     0:禁止 i-cache;
|                 |     1:使能 i-cache
|                 | 如果系統中使用統一的 i-cache 和 d-cache 或者係統中不含cache, 讀取該位時返回0, 寫入時忽略.
|                 | 當系統中的 i-cache 不能禁止時, 讀取時該位返回1, 寫入時忽略
| V (bit[13])     | 對於支持高端異常向量表的系統, 本控制位控制向量表的位置
|                 |     0:選擇低端異常中斷向量0x0~0x1c;
|                 |     1:選擇高端異常中斷向量0xffff0000 ~ 0xffff001c
|                 | 對於不支持高端異常向量表的系統, 讀取時該位返回 0, 寫入時忽略
| RR (bit[14])    | 如果系統中的 cache 的淘汰算法可以選擇的話, 本控制位選擇淘汰算法
|                 |     0:常規的 cache 淘汰算法, 如隨機淘汰;
|                 |     1:預測性淘汰算法, 如 round-robin 淘汰算法
|                 | 如果系統中 cache 的淘汰算法不可選擇, 寫入該位時忽略.
|                 | 讀取該位時, 根據其淘汰算法是否可以比較簡單地預測最壞情況返回 0 或者 1
| L4 (bit[15])    | 對於 ARMv5 及以上的版本, 本控制位可以提供兼容以前的 ARM版本的功能
|                 |     0:保持ARMv5以上版本的正常功能;
|                 |     1:將ARMv5以上版本與以前版本處理器兼容, 不根據跳轉地址的 bit[0] 進行 ARM/Thumb 狀態切換:
|                 |         bit[0] = 0 表示 ARM 指令,
|                 |         bit[0] = 1 表示 Thumb 指令
| bit[31:16]      | 這些位保留將來使用, 應為 UNP/SBZP


# MISC

## Set bit with asm

    ```nasm
        ldr r0, =0xE010E81C     /* r0 = 0xE010E81C; register address */
        ldr r1, [r0]            /* r1 = (*r0); */
        ldr r2, =((0x1 << 0) | (0x1 << 8) | (0x1 << 9))
        orr r1, r1, r2          /* r1 = r1 | r2; */
        str r1, [r0]            /* (*r0) = r1; write r1 data to r0 */
    ```

## 循環右移

先將數值拓展成 word 大小, 往右移時, LSB 則被循環到 MSB, 如此類推

```
循環右移 0x53

先拓展成 32-bits
0x0000_0053

右移 1 位 (LSB 循環跑到 MSB)
0x8000_0029
```

# reference

+ [Uboot啟動流程分析(一)](https://www.cnblogs.com/Cqlismy/p/12000889.html)
+ [ARM CP15協處理器](https://www.twblogs.net/a/5c6fe485bd9eee7f0733b211)
+ [協處理器CP15介紹—MCR/MRC指令(6)](https://www.cnblogs.com/lifexy/p/7203786.html)

+ [第 3 章 相關知識點詳解](https://www.crifan.com/files/doc/docbook/uboot_starts_analysis/release/htmls/ch03_related_knowledge.html)
