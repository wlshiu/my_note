u-boot
---

[u-boot source code](ftp://ftp.denx.de/pub/u-boot/)

the version is `201907` or `latest`


## definitions

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


+ `DM` (driver model)
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


# uboot directory

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

+ the layer of directory

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

# uboot commands

+ `dfu`
    > Device Firmware Upgrade

    - host side

        ```bash
        $ sudo apt-get install dfu-util
        $ dfu-util --help
            Usage: dfu-util [options] ...
              -h --help                     Print this help message
              -V --version                  Print the version number
              -v --verbose                  Print verbose debug statements
              -l --list                     List currently attached DFU capable devices
              -e --detach                   Detach currently attached DFU capable devices
              -E --detach-delay seconds     Time to wait before reopening a device after detach
              -d --device <vendor>:<product>[,<vendor_dfu>:<product_dfu>]
                                            Specify Vendor/Product ID(s) of DFU device
              -p --path <bus-port. ... .port>       Specify path to DFU device
              -c --cfg <config_nr>          Specify the Configuration of DFU device
              -i --intf <intf_nr>           Specify the DFU Interface number
              -S --serial <serial_string>[,<serial_string_dfu>]
                                            Specify Serial String of DFU device
              -a --alt <alt>                Specify the Altsetting of the DFU Interface
                                            by name or by number
              -t --transfer-size <size>     Specify the number of bytes per USB Transfer
              -U --upload <file>            Read firmware from device into <file>
              -Z --upload-size <bytes>      Specify the expected upload size in bytes
              -D --download <file>          Write firmware from <file> into device
              -R --reset                    Issue USB Reset signalling once we're finished
              -s --dfuse-address <address>  ST DfuSe mode, specify target address for
                                            raw file download or upload. Not applicable for
                                            DfuSe file (.dfu) downloads
        ```

        1. example

            ```
            $ lsusb     # check usb status
                Bus 001 Device 013: ID 0483:df11 STMicroelectronics STM Device in DFU Mode
            $ sudo dfu-util -d 0483:df11 -a 0 -s 0x08000000 -D stm32_demo.bin

                or

            $ dfu-util -D u-boot.bin
                dfu-util 0.8

                Copyright 2005-2009 Weston Schmidt, Harald Welte and OpenMoko Inc.
                Copyright 2010-2014 Tormod Volden and Stefan Schmidt
                This program is Free Software and has ABSOLUTELY NO WARRANTY
                Please report bugs to dfu-util@lists.gnumonks.org

                dfu-util: Invalid DFU suffix signature
                dfu-util: A valid DFU suffix will be required in a future dfu-util release!!!
                Opening DFU capable USB device...
                ID 18d1:4e30
                Run-time device DFU version 0110
                Claiming USB DFU Interface...
                Setting Alternate Setting #0 ...
                Determining device status: state = dfuIDLE, status = 0
                dfuIDLE, continuing
                DFU mode device DFU version 0110
                Device returned transfer size 4096
                Copying data from PC to DFU device
                Download        [=========================] 100%       419666 bytes
                Download done.
                state(7) = dfuMANIFEST, status(0) = No error condition is present
                state(2) = dfuIDLE, status(0) = No error condition is present
                Done!
            ```

    - target board side

        1. enable option

            ```
            CONFIG_CMD_DFU=y
            # DFU support
            CONFIG_USB_FUNCTION_DFU=y
            # CONFIG_DFU_TFTP is not set
            CONFIG_DFU_MMC=y
            # CONFIG_DFU_NAND is not set
            CONFIG_DFU_RAM=y
            # CONFIG_DFU_SF is not set
            可以使用 MMC 和 RAM 存儲文件

            # e.g. 輸入 setenv dfu_alt_info u-boot.bin ram 0x43E00000 0x100000
            # 表示如果使用 ram 方式, 將接收的數據存儲在 RAM 中以 0x43E00000 開始的位置, 最大為 0x10000
            # 表示如果使用 mmc 方式, 將接收的數據存儲在 MMC 中以 0x10000000 開始的位置, 最大為 0x10000
            ```

        1. example

            ```
            => dfu 0 ram 0
            USB PHY0 Enable
            crq->brequest:0x0

            DOWNLOAD ... OK
            Ctrl+C to exit ...
            ```

# Flow Chart


## boot

u-boot 啟動流程分為兩階段 (stage1 and stage2)

stage1
> 通常將依賴於 CPU 體系結構的部分(e.g CPU configuraion)都放在 stage1, 而且會用 assembly 實做

stage2
> 通常用 C 來實現, 這樣可以實現複雜的功能, 而且有更好的可讀性和移植性


+ enter pointer
    > lookup link-script `arch/arm/cpu/u-boot.lds`

    ```
    ENTRY(_start)
    SECTIONS
    {
        ...
    }
    ```

+ `_start`

    - Cortex-M
        > `arch/arm/lib/vectors_m.S`

        ```nasm
        .section  .vectors
        ENTRY(_start)
            .long   CONFIG_SYS_INIT_SP_ADDR     @ 0 - Reset stack pointer
            .long   reset               @ 1 - Reset
            .long   __invalid_entry         @ 2 - NMI
            .long   __hard_fault_entry      @ 3 - HardFault
            .long   __mm_fault_entry        @ 4 - MemManage
            .long   __bus_fault_entry       @ 5 - BusFault
            .long   __usage_fault_entry     @ 6 - UsageFault
            .long   __invalid_entry         @ 7 - Reserved
            .long   __invalid_entry         @ 8 - Reserved
            .long   __invalid_entry         @ 9 - Reserved
            .long   __invalid_entry         @ 10 - Reserved
            .long   __invalid_entry         @ 11 - SVCall
            .long   __invalid_entry         @ 12 - Debug Monitor
            .long   __invalid_entry         @ 13 - Reserved
            .long   __invalid_entry         @ 14 - PendSV
            .long   __invalid_entry         @ 15 - SysTick
            .rept   255 - 16
            .long   __invalid_entry         @ 16..255 - External Interrupts
            .endr
        ```

    - ARM9, Cortex-A
        > `arch/arm/lib/vectors.S`

        ```nasm
        /*
         * A macro to allow insertion of an ARM exception vector either
         * for the non-boot0 case or by a boot0-header.
         */
            .macro ARM_VECTORS      // macro define 和 .endm 相對應
        #ifdef CONFIG_ARCH_K3
            ldr     pc, _reset
        #else
            b   reset               // 'b' 是不帶返回的跳轉, 'bl' 是帶返回的跳轉
        #endif
            ldr pc, _undefined_instruction
            ldr pc, _software_interrupt
            ldr pc, _prefetch_abort
            ldr pc, _data_abort
            ldr pc, _not_used
            ldr pc, _irq
            ldr pc, _fiq            /* 把 '_irq' 存放的數值存放到 pc register,
                                       下一步執行 pc 就會跳轉過去 */
            .endm                   // macro define end

            .globl _start

            .section ".vectors", "ax"  // 定義 section name and attribute

        _start:
        #ifdef CONFIG_SYS_DV_NOR_BOOT_CFG
            .word   CONFIG_SYS_DV_NOR_BOOT_CFG
        #endif
            ARM_VECTORS

            .globl  _reset      // _reset 是一個 Label, 即一個識別的 tag
            .globl  _undefined_instruction
            .globl  _software_interrupt
            .globl  _prefetch_abort
            .globl  _data_abort
            .globl  _not_used
            .globl  _irq
            .globl  _fiq

        #ifdef CONFIG_ARCH_K3
        _reset:         .word reset
        #endif
        _undefined_instruction: .word undefined_instruction
        _software_interrupt:    .word software_interrupt
        _prefetch_abort:        .word prefetch_abort
        _data_abort:            .word data_abort
        _not_used:              .word not_used
        _irq:                   .word irq
        _fiq:                   .word fiq

            .balignl 16,0xdeadbeef  // 16-alignmen 並用 0xdeadbeef 來補 dummy
        ...
        ```

        1. `ldr`
            > ldr 用於從 memory address 中, 將一個 32-bits data 傳送到目的 general-purpose registers 中, 然後對數據進行處理.
            >> 當程序計數器 PC 作為目的 registers時, ldr 從 memory 中讀取的 data 被當作 destination address,
            從而可以實現程序流程的跳轉

            ```
            ldr{<cond>} <Rd>, <addressing_mode>
            /* Load a word from the memory address calculated by <addressing_mode>
               and write it to register <Rd> */
            ```

        1. `.globl`
            > 當於 C 語言中的 `extern`, 宣告變量是全域的
            >> 同時必須給這個變量實體

            ```
            extern foo;         // .globl foo
            uint32_t  foo = 0;  // foo:  .word 0x0
            ```

        1. `.word`
            > 分配一個 h/w word 大小的空間, 並用 expr 初始化這個空間

            ```
            .word <expr>

            e.g.
            .word reset
            /* 分配了一個 word (32bits)的地址空間, 裡面存放 reset (即一個 address) */
            ```

        1. `.balignl 16,0xdeadbeef`
            > 接下來要 16-byte alignment, 用 `0xdeadbeef`來填充
            >> `0xdeadbeef` 方便識別, `0xbadc0de`表示 **bad code**

+ `start.S`
    > reset function at `arch/arm/cpu/armv7/start.S`
    > target purposes
    > + 設置 CPU 模式
    > + 關閉 watch dog
    > + 關閉中斷
    > + 設置堆棧 sp pointer
    > + 歸零 bss section
    > + 異常中斷處理
    >> set ISR instance

    - main flow
        1. 使 CPU 進入 SVC 模式 (supervisor mode), 停止中斷.
        1. 初始化 cp15 協處理器, 暫時關閉 MMU, ICACHE.
        1. 跳轉到 `lowlevel_init.S`.
        1. 最後跳轉到 `_main`(at arch/arm/lib/crt0.S)

    - source code

        ```nasm
            .globl  reset
            .globl  save_boot_params_ret
            .type   save_boot_params_ret,%function
        #ifdef CONFIG_ARMV7_LPAE
            .global switch_to_hypervisor_ret
        #endif

        reset:
            /* Allow the board to save important registers */
            b   save_boot_params
        save_boot_params_ret:
        #ifdef CONFIG_ARMV7_LPAE
        /*
         * check for Hypervisor support
         */
            mrc p15, 0, r0, c0, c1, 1           @ read ID_PFR1
            and r0, r0, #CPUID_ARM_VIRT_MASK    @ mask virtualization bits
            cmp r0, #(1 << CPUID_ARM_VIRT_SHIFT)
            beq switch_to_hypervisor
        switch_to_hypervisor_ret:
        #endif
            /*
             * disable interrupts (FIQ and IRQ), also set the cpu to SVC32 mode,
             * except if in HYP mode already
             */
            mrs r0, cpsr                            //r0 = cpsr
            and r1, r0, #0x1f   @ mask mode bits    //r1 = r0 & 0x1f
            teq r1, #0x1a       @ test for HYP mode //if(r1 != 0x1a) { //0x1a, HYP模式, 它比超級管理員要稍微低一點,
                                                                        它主要是用來做一些虛擬化的擴展.
            bicne r0, r0, #0x1f @ clear all mode bits //r0 = r0 & ~(0x1f)
            orrne r0, r0, #0x13 @ set SVC mode        //r0 = r0 | 0x13 }  //進入SVC模式
            orr r0, r0, #0xc0   @ disable FIQ and IRQ //r0 |= 0xc0  //禁用 IRQ 和 FIQ 中斷
            msr cpsr,r0                               //cpsr = r0

        /*
         * Setup vector:
         * (OMAP4 spl TEXT_BASE is not 32 byte aligned.
         * Continue to use ROM code vector only in OMAP4 spl)
         */
        #if !(defined(CONFIG_OMAP44XX) && defined(CONFIG_SPL_BUILD))
            /* Set V=0 in CP15 SCTLR register - for VBAR to point to vector */
            mrc p15, 0, r0, c1, c0, 0   @ Read CP15 SCTLR Register // r0 = p15(0, c1, c0)
            bic r0, #CR_V               @ V = 0                    // r0 = r0 & ~(1<<13)
            mcr p15, 0, r0, c1, c0, 0   @ Write CP15 SCTLR Register // p15(0, c1, c0) = r0

        #ifdef CONFIG_HAS_VBAR
            /* Set vector address in CP15 VBAR register */
            ldr r0, =_start                         // r0 = _start
            mcr p15, 0, r0, c12, c0, 0  @Set VBAR   // p15(0, c12, c0) = r0
        #endif
        #endif

            /* the mask ROM code should have PLL and others stable */
        #ifndef CONFIG_SKIP_LOWLEVEL_INIT
        #ifdef CONFIG_CPU_V7A
            bl  cpu_init_cp15   //初始化 cp15
        #endif
        #ifndef CONFIG_SKIP_LOWLEVEL_INIT_ONLY
            bl  cpu_init_crit   //初始化時鐘
        #endif
        #endif

            bl  _main           // at arch/arm/lib/crt0.S
        ...
        ```

        1. `cpu_init_crit`

            ```nasm
            ENTRY(cpu_init_crit)
                /*
                 * Jump to board specific initialization...
                 * The Mask ROM will have already initialized
                 * basic memory. Go here to bump up clock rate and handle
                 * wake up conditions.
                 */
                b   lowlevel_init       @ go setup pll,mux,memory
            ENDPROC(cpu_init_crit)
            ```

+ `crt0.S`
    > stage2 flow
    >> at `arch/arm/lib/crt0.S`

    - `_main`

        ```nasm
        ENTRY(_main)
        /*
         * Set up initial C runtime environment and call board_init_f(0).
         */
        ...

            /**
             * 預設堆棧指針為 CONFIG_SYS_INIT_SP_ADDR
             * 在 tiny210 中初步設置為如下(include/configs/tiny210.h):
             * #define CONFIG_SYS_SDRAM_BASE    0x20000000
             * #define MEMORY_BASE_ADDRESS      CONFIG_SYS_SDRAM_BASE
             * #define PHYS_SDRAM_1             MEMORY_BASE_ADDRESS
             * #define CONFIG_SYS_LOAD_ADDR     (PHYS_SDRAM_1 + 0x1000000)  /* default load address */
             * #define CONFIG_SYS_INIT_SP_ADDR  CONFIG_SYS_LOAD_ADDR
             * 最終可以得到 CONFIG_SYS_INIT_SP_ADDR 是 0x3000_0000, 也就是 uboot relocation 的起始地址
             * 補充一下, DDR 的空間是 0x2000_0000-0x4000_0000
             *
             * 注意!! 這裡只是暫時的堆棧地址, 而不是最終的堆棧地址!
             */
            ldr sp, =(CONFIG_SYS_INIT_SP_ADDR)

            /* 8-byte 對齊*/
            bic sp, sp, #7  /* 8-byte alignment for ABI compliance */

            /**
             * 將 sp 的值放到 r0 中, 也就是作為 board_init_f_alloc_reserve 的參數
             * 返回之後, r0 里面存放的是 global_data 的地址
             * 注意, 同時也是 stack pointer, 因為 stack 是向下增長的 (往 low address),
             * 所以不必擔心和 global_data 衝突的問題
             *
             * 綜上, 此時 r0 存放的, 既是 global_data 的地址, 也是 stack 的地址
             */
            mov r0, sp
            bl  board_init_f_alloc_reserve

            /* 把新的堆棧地址從 r0 存放到 sp 中 */
            mov sp, r0

            /* set up gd here, outside any C code */
            /**
             * 把 global_data 的地址存放在 r9 中
             * 此時 r0 存放的還是 global_data 的地址
             */
            mov r9, r0

            /**
             * 調用 board_init_f_init_reserve 對 global_data 進行初始化
             * r0 也就是其參數
             */
            bl  board_init_f_init_reserve

            mov r0, #0
            bl  board_init_f    /* do init list from 'init_sequence_f' */
        ...
        ```

        1. 設置 **sp 臨時堆棧**.
        1. 分配 global_data 的空間
            > `board_init_f_alloc_reserve()`

            ```c
            /**
             * 這個函數用於對 global_data 區域進行初始化, 也就是清空 global_data 區域
             * 傳入的參數就是 global_data 的基地址
             */
            void board_init_f_init_reserve(ulong base)
            {
                struct global_data *gd_ptr;

                /*
                 * clear GD entirely and set it up.
                 * Use gd_ptr, as gd may not be properly set yet.
                 */

                gd_ptr = (struct global_data *)base;
                /* zero the area */
                memset(gd_ptr, '\0', sizeof(*gd)); // 清零

                /* next alloc will be higher by one GD plus 16-byte alignment */
                /**
                 * 因為 global_data 區域是 16-Byte alignment 的,
                 * 後面的地址就是 early malloc 的 memory pool,
                 * 所以這裡就獲取了 early malloc 的 memory pool 的地址
                 */
                base += roundup(sizeof(struct global_data), 16);

                /*
                 * record early malloc arena start.
                 * Use gd as it is now properly set for all architectures.
                 */
            #if defined(CONFIG_SYS_MALLOC_F)
                /* go down one 'early malloc arena' */
                gd->malloc_base = base;     // 填入 pool start address
                /* next alloc will be higher by one 'early malloc arena' size */
                base += CONFIG_VAL(SYS_MALLOC_F_LEN);
            #endif
            }
            ```

            > early memory layout

            ```
            +-------------+ Low address
            |             |
            |             |  ^
            |             |  | stack push
            +------------------- sp
            | global_data |  | global_data cast
            |             |  v
            +--------------------- CONFIG_SYS_INIT_SP_ADDR
            |             |
            +---------------- gd->malloc_base (early malloc heap)
            |             |
            |early malloc |  SYS_MALLOC_F_LEN
            |   heap      |
            +---------------- gd->malloc_base + SYS_MALLOC_F_LEN
            |             |
            |             |
            ```

        1. uboot 定義了 `DECLARE_GLOBAL_DATA_PTR`, 使我們可以更加簡單地獲取 global_data

            ```c
            // at arch/arm/include/asm/global_data.h
            #define DECLARE_GLOBAL_DATA_PTR     register volatile gd_t *gd asm ("r9")

            // gd 指向 r9 中的值
            ```

        1. board_init_f() at `common/board_f.c`
            > do initial script
            >> the script follow `init_fnc_t init_sequence_f[]`

    - reference
        1. [u-boot啟動流程 2017.03](https://wowothink.com/146db8db/)
        1. [U-BOOT-2016.07移植(第三篇)代碼重定位](https://blog.csdn.net/funkunho/article/details/52474373)
        1. [mcdx:u-boot2020.04移植](https://blog.csdn.net/a1598025967/category_10123105.html)

+ `init_sequence_f[]` at `common/board_f.c`
    > `board_f.c` board init first

    - `setup_mon_len()`
        > 置 `gd->mon_len`的值, 這個值表示 u-boot executable bin 大小
        >> `_start` ~ `__bss_end`

    - `fdtdec_setup()`
        > 設置`gd->fdt_blob`指針(即 device tree binary 所在的存儲位置)的值
        >> `__dtb_dt_begin` at `dts/dt.dtb.S`

    - `initf_malloc()`
        > 設置`gd->malloc_limit` heap 空間限制為 `CONFIG_SYS_MALLOC_F_LEN`

    - `log_init()`
        >  Setup the log system ready for use if necessary

    - `initf_bootstage()`
        > 主要作用就是為`gd->bootstage`分配空間, 並初始化`gd->bootstage`;
        同時增加兩個紀錄, 一條是`reset`, 一條是`board_init_f`
        >> Record the bootstrap flow and the spent time

    - `arch_cpu_init()`
        > 針對特定 CPU 的初始化, 不同 CPU 的初始化也不盡相同,
        因此 u-boot 提供了 `arch_cpu_init`用於CPU初始化.
        這個函數由移植者根據自己的硬件(CPU)的情況來實作

    - `mach_cpu_init()`
        > 針對特定 `SoC`的初始化, 這個函數同樣由移植者根據自己的硬件(SoC)的情況來提供

    - `initf_dm()`
        > 進行 u-boo t的 Driver Model 的初始化,
        在這裡會去解析 fdt 的設備, 並註冊與之匹配的驅動

    - `board_early_init_f()`
        > 由 vendor 提供, 通常定義在 board 目錄下, 用來對開發版做前期配置.
        提供這個函數的同時還需要定義 `CONFIG_BOARD_EARLY_INIT_F`

    - `env_init()`
        > 設置`gd->env_addr`環境變量的 address.
        可由不同 priority 的 storage device 載入.

            ```c
            // at env/env.c
            enum env_location env_locations[] = {};
            ```

        > 使用 `U_BOOT_ENV_LOCATION` 宣告一個相應的 `struct env_driver` 類型的 entry,
        多個 entries 用 link script 將其集中到一個 memory pool.
        >> 利用 macro `ll_entry_start/ll_entry_end` 來定義 pool 開始及結束 address

        ```
        .u_boot_list : { KEEP(*(SORT(.u_boot_list*))); }

        /*
         *  .u_boot_list_2_env_driver_1         => ll_entry_start(struct env_driver, env_driver)
         *  .u_boot_list_2_env_driver_2_eeprom  => U_BOOT_ENV_LOCATION(eeprom)
         *  .u_boot_list_2_env_driver_2_ext4    => U_BOOT_ENV_LOCATION(ext4)
         *  .u_boot_list_2_env_driver_3         => ll_entry_end(struct env_driver, env_driver)
         */
        ```

        1. 預設值存放在 `default_environment[]` at `include/env_default.h`

        1. source code

            ```c
            int env_init(void)
            {
                struct env_driver *drv;
                int ret = -ENOENT;
                int prio;

                /**
                 *  從 env_locations array 的第  1個元素開始遍歷(即從最最優先的位置開始遍歷).
                 *  env_driver_lookup 會遍歷上述的一系列entry,
                 *  若有 entry 的 location 與 env_locations[prio] 匹配, 則返回該 entry 的地址,
                 *  否則返回NULL
                 */
                for (prio = 0; (drv = env_driver_lookup(ENVOP_INIT, prio)); prio++) {
                    /**
                     *  一旦找到匹配的 entry, 嘗試調用該 entry 的初始化成員函數.
                     *  初始化函數通常會設置 gd->env_addr (環境變量地址)和 gd->env_valid
                     */
                    if (!drv->init || !(ret = drv->init()))
                        /**
                         *  如果初始化成員函數存在且調用成功.
                         *  則將 gd->env_has_init 的相應 bit 置 1,
                         *  標誌該位置的環境變量已初始化
                         */
                        env_set_inited(drv->location);

                    debug("%s: Environment %s init done (ret=%d)\n", __func__,
                          drv->name, ret);
                }

                if (!prio)
                    return -ENODEV;

                if (ret == -ENOENT) {
                    /**
                     *  未能匹配到 entry 或匹配到但初始化失敗的話,
                     *  就使用默認的環境變量
                     */
                    gd->env_addr = (ulong)&default_environment[0];
                    gd->env_valid = ENV_VALID;

                    return 0;
                }

                return ret;
            }
            ```

    - `init_baud_rate()`
        > 從環境變量中獲取 baudrate 的值, 並設置`gd->baudrate`(default: CONFIG_BAUDRATE).

    - `serial_init()`
        > at `drivers/serial/serial-uclass.c`

    - `console_init_f()`
    - `display_options()`
        > show version info
    - `display_text_info()`
        > show `.text` and `.bss` section addresses
        >> text_base 由 `CONFIG_SYS_TEXT_BASE`來決定, 即 `_start` 開始的地方

    - `print_cpuinfo()`
        > 需定義 `CONFIG_DISPLAY_CPUINFO`

    - `show_board_info()`
        > 需定義 `CONFIG_DISPLAY_BOARDINFO` 及 `CONFIG_OF_CONTROL`.
        讀取 DTB 的 `cpu-model` 資訊

    - `dram_init()`
        > 初始化系統的 DDR, `dram_init` 應該由平台相關的代碼實現.
        如果 DDR 已經初始化過了, 則不需要重新初始化,
        只需要設置 `gd->ram_size` 的大小
        >> 按照 u-boot 的說明, 調用`dram_init()`之後,
        就要去分配 DDR 的空間以及 relocate u-boot 的代碼

    - reference
        1. [u-boot v2018.01 啟動流程分析](https://www.shangmayuan.com/a/d31b5c1f20d7418186c1675e.html)
            > relocate layout
        1. [uboot 驅動模型- DM](https://blog.csdn.net/ooonebook/article/details/53234020)
        1. [u-boot啟動流程](https://wowothink.com/146db8db/)

+ uboot relocate

    在以前的板子上, u-boot 有可能是運行在 NOR FLASH 或 ROM 上, 空間小執行慢, 而且不支持 write 操作,
    DDR 初始化完畢之後, 需要將其 relocate 到 DDR 去運行, 空間大執行的速度也比較快, 也支持 write 操作.

    同時考慮到後續的 kernel 是在 DDR 的 Low memory 解壓縮並執行的,
    為了避免麻煩,** u-boot 將使用 DRAM 的 top address**, 即 `gd->ram_top`所代表的位置.

    > relocate 會造持執行 address 混亂.
    一般執行地址都是在編譯時由 linker 指定的, 為了確保搬移後可以執行, 有兩種方法.
    > + linker 就直接使用搬移後的 address (link script)
    > + 開啟 PIC (Position independent code) 選項來編譯. linker 會**使用相對位址**來連結

    以下延續 uboot initial flow `init_sequence_f[]` at `common/board_f.c`

    - `setup_dest_addr()`
        > 設置 u-boot 的 relocaddr address, 通過`gd->ram_size`和`CONFIG_SYS_SDRAM_BASE`(DDR的起始地址),
        確定`gd->ram_top`和`gd->relocaddr`, 也就是將 u-boot 重定位到 DDR highest address,
        執行完之後`gd->relocaddr = gd->ram_top`

    - `reserve_round_4k()`
        > 對 `gd->relocaddr` 做 4K-align

    - `reserve_mmu()`
        > 保留 mmu 所需的 memory buffer

        ```c
        __weak int reserve_mmu(void)
        {
        ...
            /* reserve TLB table  */
            gd->arch.tlb_size = PGTABLE_SIZE;   // PGTABLE_SIZE default (4096 * 4) = 16KB
            gd->relocaddr -= gd->arch.tlb_size; // 保留 16KB 的空間
            gd->relocaddr &= ~(0x10000 - 1);    // 64KB 對齊(向 Low address)

            gd->arch.tlb_addr = gd->relocaddr;
        ...
            return 0;
        }
        ```

    - `reserve_uboot()`
        > 保留 uboot `.text` 和 `.data` section 並配置 `gd->start_addr_sp`

        ```
        High address
        +------------------+--> gd->ram_top
        | 4K-align padding |
        +------------------+
        | MMU PGTABLE_SIZE |
        +------------------+
        | reserve memory   |
        | gd->mon_len      |
        +------------------+
        | 4K-align padding |
        +------------------+--> gd->relocaddr = gd->start_addr_sp
        |                  |

        ```

    - `reserve_malloc()`
        > reserve memory for `malloc()` area,
        大小為`TOTAL_MALLOC_LEN` at `include/common.h`

        ```c
        #if defined(CONFIG_ENV_IS_EMBEDDED)
        #define TOTAL_MALLOC_LEN    CONFIG_SYS_MALLOC_LEN
        #elif ( ((CONFIG_ENV_ADDR+CONFIG_ENV_SIZE) < CONFIG_SYS_MONITOR_BASE) || \
            (CONFIG_ENV_ADDR >= (CONFIG_SYS_MONITOR_BASE + CONFIG_SYS_MONITOR_LEN)) ) || \
              defined(CONFIG_ENV_IS_IN_NVRAM)
        #define TOTAL_MALLOC_LEN    (CONFIG_SYS_MALLOC_LEN + CONFIG_ENV_SIZE)
        #else
        #define TOTAL_MALLOC_LEN    CONFIG_SYS_MALLOC_LEN
        #endif
        ```

        > memory layout

        ```
        High address
        +------------------+--> gd->ram_top
        | 4K-align padding |
        +------------------+
        | MMU PGTABLE_SIZE |
        +------------------+
        | reserve memory   |
        | gd->mon_len      |
        +------------------+
        | 4K-align padding |
        +------------------+-->  gd->relocaddr
        | reserve          |
        | TOTAL_MALLOC_LEN |
        +------------------+-->  gd->start_addr_sp
        |                  |
        ```

    - `reserve_board()`
        > 為`struct bd_info`分配空間, 並配置 `gd->bd`

        ```
        High address
        +------------------------+--> gd->ram_top
        | 4K-align padding       |
        +------------------------+
        | MMU PGTABLE_SIZE       |
        +------------------------+
        | reserve memory         |
        | gd->mon_len            |
        +------------------------+
        | 4K-align padding       |
        +------------------------+--> gd->relocaddr
        | reserve                |
        | TOTAL_MALLOC_LEN       |
        +------------------------+-->
        | sizeof(struct bd_info) |
        +------------------------+--> gd->bd = gd->start_addr_sp
        |                        |

        ps. memory cast 往 High address 走, stack 往 Low address 走
        ```

    - `reserve_global_data()`
        > 為`struct global_data`分配空間, 並配置 `gd->new_gd`

        ```
        High address
        +------------------------+--> gd->ram_top
        | 4K-align padding       |
        +------------------------+
        | MMU PGTABLE_SIZE       |
        +------------------------+
        | reserve memory         |
        | gd->mon_len            |
        +------------------------+
        | 4K-align padding       |
        +------------------------+--> gd->relocaddr
        | reserve                |
        | TOTAL_MALLOC_LEN       |
        +------------------------+-->
        | sizeof(struct bd_info) |
        +------------------------+--> gd->bd
        | sizeof(global_data_t)  |
        +------------------------+--> gd->new_gd = gd->start_addr_sp
        |                        |

        ps. memory cast 往 High address 走, stack 往 Low address 走
        ```

    - `reserve_fdt()`
        > 為 fdt 分配空間, 通過`gd->fdt_blob`計算出`gd->fdt_size`的大小, 並配置 `gd->new_fdt`

        ```
        High address
        +------------------------+--> gd->ram_top
        | 4K-align padding       |
        +------------------------+
        | MMU PGTABLE_SIZE       |
        +------------------------+
        | reserve memory         |
        | gd->mon_len            |
        +------------------------+
        | 4K-align padding       |
        +------------------------+--> gd->relocaddr
        | reserve                |
        | TOTAL_MALLOC_LEN       |
        +------------------------+-->
        | sizeof(struct bd_info) |
        +------------------------+--> gd->bd
        | sizeof(global_data_t)  |
        +------------------------+--> gd->new_gd
        | reserve                |
        | gd->fdt_size           |
        +------------------------+--> gd->new_fdt = gd->start_addr_sp
        |                        |

        ps. memory cast 往 High address 走, stack 往 Low address 走
        ```

    - `reserve_bootstage()`
        > 為`struct bootstage_data`分配空間, 並配置 `gd->new_bootstage`

        ```
        High address
        +------------------------+--> gd->ram_top
        | 4K-align padding       |
        +------------------------+
        | MMU PGTABLE_SIZE       |
        +------------------------+
        | reserve memory         |
        | gd->mon_len            |
        +------------------------+
        | 4K-align padding       |
        +------------------------+--> gd->relocaddr
        | reserve                |
        | TOTAL_MALLOC_LEN       |
        +------------------------+-->
        | sizeof(struct bd_info) |
        +------------------------+--> gd->bd
        | sizeof(global_data_t)  |
        +------------------------+--> gd->new_gd
        | reserve                |
        | gd->fdt_size           |
        +------------------------+--> gd->new_fdt
        |sizeof(bootstage_data_t)|
        +------------------------+--> gd->new_bootstage = gd->start_addr_sp
        |                        |

        ps. memory cast 往 High address 走, stack 往 Low address 走
        ```

    - `reserve_stacks()`
        > 保留 16-bytes 的 irq stack, 並配置 `gd->irq_sp`

        ```
        High address
        +------------------------+--> gd->ram_top
        | 4K-align padding       |
        +------------------------+
        | MMU PGTABLE_SIZE       |
        +------------------------+
        | reserve memory         |
        | gd->mon_len            |
        +------------------------+
        | 4K-align padding       |
        +------------------------+--> gd->relocaddr
        | reserve                |
        | TOTAL_MALLOC_LEN       |
        +------------------------+-->
        | sizeof(struct bd_info) |
        +------------------------+--> gd->bd
        | sizeof(global_data_t)  |
        +------------------------+--> gd->new_gd
        | reserve                |
        | gd->fdt_size           |
        +------------------------+--> gd->new_fdt
        |sizeof(bootstage_data_t)|
        +------------------------+--> gd->new_bootstage
        | irq stack, 16-bytes    |
        +------------------------+--> gd->irq_sp = gd->start_addr_sp
        |                        |

        ps. memory cast 往 High address 走, stack 往 Low address 走
        ```

    - `reloc_xxx()`
        > 將 data 搬到上述保留的 memory address

    - `setup_reloc()`
        > + 計算 relocate 後, 與原本位置的 offset, 並配置給 `gd->reloc_off`
        > + copy global_data 到新的 address (gd->new_gd)


    - `relocate_code()` at `arch/arm/lib/relocate.S`

        1. build `.rel.dyn` section
            > ARM 架構, 是在編譯時使用`-mword-relocations`, 生成與位置無關代碼.
            link 時使用`-pie`生成 `.rel.dyn` section
            >> At `arch/arm/config.mk`

            > `.rel.dyn` section 中的每個條目被稱為一個 Label, 用來存儲絕對地址的 symbol_address.


        1. relocation memory layout
            > `.rel.dyn` 與 `.bss` section 起始地址是相同, u-boot 運行 stage1 時, `.bss` section 是不為零的.
            運行 stage1 時的全域變數, 會預先放到別的 memory section, 或是從 heap 使用後再做搬移

            ```
                    High address
                    +---------------+   gd->ram_top
                    | align padding |
                +-- +---------------+   gd->relocaddr + gd->mon_len
                |   | .bss (reloc)  |
            +-> |   +---------------+
            |   |   | .data (reloc) |
            |   |   +---------------+
            |   |   | .text (reloc) |
            |   +-- +---------------+   gd->relocaddr
            |       | ...           |
            |       +---------------+   __image_binary_end = __rel_dyn_end
            |       | .rel.dyn      |
            |   +-- +---------------+   __image_copy_end = __rel_dyn_start = __bss_start
            +---|   | .data         |
                |   +---------------+
                |   | .text         |
                +-- +---------------+   __image_copy_start
                    |               |
            ```

        1. `.rel.dyn` section

            ```
            struct rel_item {
                unsigned long   label_pointer; /* record symbol_address*/
                unsigned long   tag;
            };

            ...
            80008020 <_undefined_instruction>:      /* label_pointer */
            80008020:	80008060 	andhi	r8, r0, r0, rrx
            ...

            80008060 <undefined_instruction>:       /* symbol_address*/
            80008060:	e51fd028 	ldr	sp, [pc, #-40]	; 80008040 <IRQ_STACK_START_IN>
            80008064:	e58de000 	str	lr, [sp]
            80008068:	e14fe000 	mrs	lr, SPSR
            8000806c:	e58de004 	str	lr, [sp, #4]
            ...

            Disassembly of section .rel.dyn:

            80078f04 <__efi_runtime_rel_stop>:
            80078f04:	80008020 	andhi	r8, r0, r0, lsr #32 /* label_pointer */
            80078f08:	00000017 	andeq	r0, r0, r7, lsl r0  /* tag */
            80078f0c:	80008024 	andhi	r8, r0, r4, lsr #32 /* label_pointer */
            80078f10:	00000017 	andeq	r0, r0, r7, lsl r0  /* tag */
            80078f14:	80008028 	andhi	r8, r0, r8, lsr #32 /* label_pointer */
            80078f18:	00000017 	andeq	r0, r0, r7, lsl r0  /* tag */
            ...
            ```

        1. pre-setup

            ```
                ldr sp, [r9, #GD_START_ADDR_SP] /* sp = gd->start_addr_sp */
                bic sp, sp, #7      /* 8-byte alignment for ABI compliance */
                ldr r9, [r9, #GD_BD]        /* r9 = gd->bd */
                sub r9, r9, #GD_SIZE        /* new GD is below bd */

                /**
                 * 上面這一段代碼是將 board_init_f 中,
                 * 設置好的 start_addr_sp 地址值賦給 stack pointer,
                 * 使其指向重定位後的棧頂 8-bytes 對齊後,
                 * 將 r9 設為新的 GD 地址
                 * (對照內存分配圖: gd_new_addr = bd_addr - sizeof(gd_t))
                 */

                adr lr, here                    /* 設置返回地址為下面的 here, 重定位到 sdram 後返回 here 運行
                                                 * adr: 讀取基於 PC 相對偏移的 address 到 register
                                                 */
                ldr r0, [r9, #GD_RELOC_OFF]     /* r0 = gd->reloc_off 取重定位地址偏移值 */
                add lr, lr, r0                  // lr 加偏移地址等於在 sdram 中重定位後的 here 地址
                ldr r0, [r9, #GD_RELOCADDR]     /* r0 = gd->relocaddr 傳入參數為重定位地址 */
                b   relocate_code               //跳到 arch/arm/lib/relocate.S 中執行
            here:                               //返回後跳到 relocated 的 sdram 中運行
            ```

        1. source code

            ```
            ENTRY(relocate_code)
                /* r1 = &__image_copy_start
                 * 其中 __image_copy_start 是 u-boot.bin 起始鏈接地址,
                 * 定義在 u-boot.lds 中 (編譯後在頂層目錄生成)
                 * 原文件是 arch/arm/cpu/u-boot.lds, 大家可以自行分析
                 */
                ldr r1, =__image_copy_start

                /* r4 = r0 - r1 = gd->relocaddr - &__image_copy_start
                 * r0 是 crt0.S 中傳入的 gd->relocaddr,
                 * 這裡是算出偏移值
                 */
                subs    r4, r0, r1

                beq relocate_done           /* skip relocation 如果 r4 == 0, 則認為重定位已完成 */
                ldr r2, =__image_copy_end   /* r2 = &__image_copy_end, __image_copy_end 在 u-boot.lds 中定義 */

            copy_loop:
                /* r1 是源地址 __image_copy_start,
                 * r0 是目的地址 gd->relocaddr,
                 * size = __image_copy_start - __image_copy_end
                 */
                ldmia   r1!, {r10-r11}  /* copy from source address [r1]
                                         * C pseudo code:
                                         *  r10 = *r1, r1 += 4;
                                         *  r11 = *r1, r1 += 4;
                                         */
                stmia   r0!, {r10-r11}  /* copy to   target address [r0]
                                         * C pseudo code:
                                         *  *r0 = r10, r0 += 4;
                                         *  *r0 = r11, r0 += 4;
                                         */
                cmp r1, r2              /* until source end address [r2]
                                         * C pseudo code:
                                         *  (r1 - r2) and mark flags (CF, ZF, OF, SF)
                                         */
                blo copy_loop           /* (unsigned)小於則跳轉 */

                /*
                 * fix .rel.dyn relocations
                 * 定義了"-PIE"選項就會執行下面這段代碼
                 * 目的是為了讓相關資源(代碼/參數/變量)的 address 在重定位後仍然能被尋址到,
                 * 所以讓他們加上偏移地址, 即等於他們重定位後的真正 address
                 * 這些 "存放(資源的地址)的地址" 存放在 .rel.dyn 這個段中, 每個參數後面都會跟著一個起標誌作用的參數,
                 * 如果這個標誌參數為 23 (即 0x17), 則表示這個 (資源的地址) 是位置相關的, 需要加上重定位偏移值
                 * 這一段代碼首先讓 .rel.dyn 這個段中的存放的地址值加上偏移值, 使其在 sdram 中取出(資源的地址)
                 * 然後再讓這些(資源的地址)加上偏移值, 存回 rel.dyn 中存放這些地址的地址中,
                 */
                ldr r2, =__rel_dyn_start  /* r2 = &__rel_dyn_start */
                ldr r3, =__rel_dyn_end    /* r3 = &__rel_dyn_end */
            fixloop:
                ldmia   r2!, {r0-r1}    /* (r0,r1) = (SRC location, fixup)
                                         * r0 為 label_pointer,
                                         * r1 為 tag
                                         */
                and r1, r1, #0xff       /* r1 取低八位 */
                cmp r1, #R_ARM_RELATIVE /* relative fixup? 和 R_ARM_RELATIVE (0x17) 比較,
                                         * 如果相等(代表找到 label)則繼續往下, 否則跳到 fixnext
                                         */
                bne fixnext

                /* relative fix: increase location by offset */
                add r0, r0, r4      /* r4 存放的是重定位偏移值, r0 則是原本的 label_pointer,
                                     * r4 + r0 即為重定位後的 label_pointer,
                                     */
                ldr r1, [r0]        // r1 = *r0, label_pointer 取值, 得到實際的 symbol_address
                add r1, r1, r4      // r1 += r4, 將 symbol_address 加上 offset, 指向 relocate 後的 address
                str r1, [r0]        // *r0 = r1, 寫回 memory
            fixnext:                //跳到下一個繼續檢測是否需要重定位
                cmp r2, r3          /* 確認是否到 .rel.dyn section END */
                blo fixloop

            relocate_done:

                /* ARMv4- don't know bx lr but the assembler fails to see that */

            #ifdef __ARM_ARCH_4__
                mov pc, lr          /* ARM920T 用的彙編指令集是 ARMv4, 所以使用這條返回指令,
                                     * 返回上一層的 here 標誌
                                     */
            #else
                bx  lr              /* 返回上一層的 here 標誌 */
            #endif

            ENDPROC(relocate_code)
            ```

        1. [arch/arm/lib/relocate.S](https://blog.csdn.net/funkunho/article/details/52474373)
        1. [PIC(與位置無關代碼)在u-boot上的實現](http://blog.chinaunix.net/uid-20528014-id-4445271.html)

    - `relocate_vectors`
        > 用於重定位中斷向量表, 將新的中斷向量表 start address 寫到 VBAR register 中.

        ```
        ENTRY(relocate_vectors)

        #ifdef CONFIG_CPU_V7M
            /*
             * On ARMv7-M we only have to write the new vector address
             * to VTOR register.
             */
            ldr    r0, [r9, #GD_RELOCADDR]    /* r0 = gd->relocaddr */
            ldr    r1, =V7M_SCB_BASE
            str    r0, [r1, V7M_SCB_VTOR]     /* 設置新的 vector table 給 SCB->VTOR register */
        #else
        #ifdef CONFIG_HAS_VBAR
            /*
             * If the ARM processor has the security extensions,
             * use VBAR to relocate the exception vectors.
             */
            ldr    r0, [r9, #GD_RELOCADDR]  /* r0 = gd->relocaddr */
            mcr    p15, 0, r0, c12, c0, 0   /* 設置 vector table 到CP15的 VBAR register */
        #else
            /*
             * Copy the relocated exception vectors to the
             * correct address
             * CP15 c1 V bit gives us the location of the vectors:
             * 0x00000000 or 0xFFFF0000.
             */
            ldr    r0, [r9, #GD_RELOCADDR]    /* r0 = gd->relocaddr */
            mrc    p15, 0, r2, c1, c0, 0    /* V bit (bit[13]) in CP15 c1 */
            ands    r2, r2, #(1 << 13)
            ldreq    r1, =0x00000000        /* If V=0 */
            ldrne    r1, =0xFFFF0000        /* If V=1 */
            ldmia    r0!, {r2-r8,r10}
            stmia    r1!, {r2-r8,r10}
            ldmia    r0!, {r2-r8,r10}
            stmia    r1!, {r2-r8,r10}
        #endif
        #endif
            bx    lr

        ENDPROC(relocate_vectors)
        ```

        1. [Uboot啟動流程分析(五)](https://www.cnblogs.com/Cqlismy/p/12152400.html)

    - `.bss` section 清零, 並準備 `new_gd` 及 `gd->relocaddr` 參數, 跳轉到 `board_init_r`
        > `board_init_r` at `common/board_r.c`
        >> `board_r.c` board init relocated

+ System Control Coprocessor Registers `CP15`

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

    - format of instruction
        > + `MRC` (Move from coprocessor register to CPU register)
        >> CP15 到 ARM register 的數據傳送指令 (讀出協處理器寄存器).

        > + `MCR` (Move CPU register to coprocessor register)
        >> ARM register 到 CP15 的數據傳送指令 (寫入協處理器寄存器).

        ```nasm
        MRC{cond} p15,<Opcode_1>,<Rd>,<CRn>,<CRm>,<Opcode_2>
        MCR{cond} p15,<Opcode_1>,<Rd>,<CRn>,<CRm>,<Opcode_2>
        ```

        1. `cond`
            > 為指令執行的條件碼.
            當 cond 忽略時, 指令為無條件執行.

        1. `Opcode_1`
            > 協處理器的特定操作碼. 對於 CP15 register 來說, `opcode1 = 0`

        1. `Rd`
            > 作為 src register 的 ARM寄存器, 其值將被傳送到協處理器寄存器中,
            或者將協處理器寄存器的值, 傳送到該寄存器裡面, 通常為 R0

        1. `CRn`
            > target register ID of CP15, 其編號是 C0 ~ C15.

        1. `CRm`
            > 協處理器中附加的目標寄存器或源運算元暫存器, 用於區分同一個編號的不同物理暫存器.
            **如果不需要設置附加信息, 將 CRm 設置為 c0**, 否則結果未知

        1. `Opcode_2`
            > 可選的協處理器特定操作碼.
            用來區分同一個編號的不同物理寄存器, 當不需要提供附加信息時, 指定為 0

    - example

        1. assembly

            ```nasm
            mrc p15, 0, r0, c1, c0, 0   @ 將 CP15 的寄存器 C1 的值讀到 r0 中
            mcr p15, 0, r0, c7, c7, 0   @ 關閉 ICaches 和 DCaches
            mcr p15, 0, r0, c8, c7, 0   @ 使無效整個數據 TLB 和指令 TLB
            ```

        1. C syntax

            ```c
            __asm__(                            // 使用 __asm__ 可以在C函數中執行彙編語句
                "mrc p15, 0, r1, c1, c0, 0\n"
                "orr r1, r1, #0xc0000000  \n"
                "mcr p15, 0, r1, c1, c0, 0\n"
                :::"r1"                         // 向GCC聲明: 我對 r1 作了改動
            );　
            ```

    - source code of `cpu_init_cp15` (at start.S)

        ```nasm
        ENTRY(cpu_init_cp15)
            /*
             * Invalidate L1 I/D
             */
            mov r0, #0                  @ set up for MCR        //r0 = 0
            mcr p15, 0, r0, c8, c7, 0   @ invalidate TLBs       //p15(0, c8, c7) = r0
            mcr p15, 0, r0, c7, c5, 0   @ invalidate icache     //p15(0, c7, c5) = r0
            mcr p15, 0, r0, c7, c5, 6   @ invalidate BP array   //p15(0, c7, c5) = r0
            mcr p15, 0, r0, c7, c10, 4  @ DSB                   //p15(0, c7, c10) = r0
            mcr p15, 0, r0, c7, c5, 4   @ ISB                   //p15(0, c7, c5) = r0

            /*
             * disable MMU stuff and caches
             */
            mrc p15, 0, r0, c1, c0, 0                           //r0 = p15(0, c1, c0)
            bic r0, r0, #0x00002000 @ clear bits 13 (--V-)      //r0 = r0 & ~(0x00002000)
            bic r0, r0, #0x00000007 @ clear bits 2:0 (-CAM)     //r0 = r0 & ~(0x00000007)
            orr r0, r0, #0x00000002 @ set bit 1 (--A-) Align    //r0 = r0 | (0x00000002)
            orr r0, r0, #0x00000800 @ set bit 11 (Z---) BTB     //r0 = r0 | (0x00000800)
        #if CONFIG_IS_ENABLED(SYS_ICACHE_OFF)
            bic r0, r0, #0x00001000 @ clear bit 12 (I) I-cache  //r0 = r0 & ~(0x00001000)
        #else
            orr r0, r0, #0x00001000 @ set bit 12 (I) I-cache    //r0 = r0 | 0x00001000
        #endif
            mcr p15, 0, r0, c1, c0, 0                           //p15(0, c1, c0) = r0

        ...

            mov r5, lr                  @ Store my Caller               //r5 = lr
            mrc p15, 0, r1, c0, c0, 0   @ r1 has Read Main ID Register (MIDR) //r1 = p15(0, c0, c0)
            mov r3, r1, lsr #20         @ get variant field             //r3 = (r1 >> 20)
            and r3, r3, #0xf            @ r3 has CPU variant            //r3 = r3 & 0xf
            and r4, r1, #0xf            @ r4 has CPU revision           //r4 = r1 & 0xf
            mov r2, r3, lsl #4          @ shift variant field for combined value //r2 = (r3 << 4)
            orr r2, r4, r2              @ r2 has combined CPU variant + revision //r2 = r4 | r2

        /* Early stack for ERRATA that needs into call C code */
        #if defined(CONFIG_SPL_BUILD) && defined(CONFIG_SPL_STACK)
            ldr r0, =(CONFIG_SPL_STACK)
        #else
            ldr r0, =(CONFIG_SYS_INIT_SP_ADDR)
        #endif
            bic r0, r0, #7  /* 8-byte alignment for ABI compliance */
            mov sp, r0

        #ifdef CONFIG_ARM_ERRATA_798870
            cmp r2, #0x30               @ Applies to lower than R3p0    //if(r2 >= 0x30)
            bge skip_errata_798870      @ skip if not affected rev      //  goto skip_errata_798870
            cmp r2, #0x20               @ Applies to including and above R2p0 //if(r2 < 0x20)
            blt skip_errata_798870      @ skip if not affected rev      //  goto skip_errata_798870

            mrc p15, 1, r0, c15, c0, 0  @ read l2 aux ctrl reg          //r0 = p15(1, c15, c0)
            orr r0, r0, #1 << 7         @ Enable hazard-detect timeout  //r0 = r0 | (1 << 7)
            push    {r1-r5}             @ Save the cpu info registers   //sp = {r1-r5}
            bl  v7_arch_cp15_set_l2aux_ctrl                             //v7_arch_cp15_set_l2aux_ctrl();
            isb                         @ Recommended ISB after l2actlr update //指令同步隔離.
                                        @                                      //最嚴格: 它會清洗流水線,
                                        @                                      //以保證所有它前面的指令都執行
            pop {r1-r5}                 @ Restore the cpu info - fall through  //{r1-r5} = sp
        skip_errata_798870:
        #endif

        ...

            mov pc, r5                  @ back to my caller     //pc = r5 返回調用者處
        ENDPROC(cpu_init_cp15)
        ```

+ `lowlevel_init.S`
    > 原則上每塊 board 都有自己的 `lowlevel_init`, 甚至不同 ARCH 的 CPU 也可能會有自己的 instance
    >> e.g. `arch/arm/cpu/armv7/lowlevel_init.S`,
            `arch/arm/cpu/arm926ejs/lpc32xx/lowlevel_init.S`,
            `board/armltd/vexpress/vexpress_common.c`

    - main flow
        1. 做最基礎的 clock 初始化(平台相關).
            > PLL setup
        1. 跳轉回 start.S

## MISC

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


## CP15 中的寄存器介紹

CP15 有寄存器 C0 ~ C15, 操作 CP15的 instructions 如下:

```nasm
MRC{cond} p15,<Opcode_1>,<Rd>,<CRn>,<CRm>,<Opcode_2>
MCR{cond} p15,<Opcode_1>,<Rd>,<CRn>,<CRm>,<Opcode_2>
```

### CP15 的寄存器 C0

C0 對應到兩個標識符寄存器, 由 CP15中的指令來指定要實際要訪問哪個物理寄存器:
> + 主標識符寄存器
> + cache 類型標識符寄存器

+ 主標識符寄存器
    > `Opcode_2 = 0`

    ```nasm
    MRC P15, 0, R0, C0, C0, 0    @# 將主標示符寄存器的內容讀到 AMR寄存器 R0 中
    ```

| 30~24        | 23~20      | 19~16          | 15~4       | 3~0          |
| :-           | :-         | :-             | :-         | :-           |
| 由生產商確定 | 產品子編號 | ARM 體系版本號 | 產品主編號 | 處理器版本號 |


+ cache 類型標識符寄存器
    > `Opcode_2 = 1`

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


bit[28:25]用於定義 `Write back` 和 `Write through`屬性

| binary value | cache 類型     |cache 內容清除方法 | cache 內容鎖定方法
| ---          | ---            | ---               | ---
| 0b0000       | Write through  | 不需要內容清除    | 不支持內容鎖定
| 0b0001       | Write back     | 數據塊讀取        | 不支持內容鎖定
| 0b0010       | Write back     | 由寄存器 C7 定義  | 不支持內容鎖定
| 0b0110       | Write back     | 由寄存器 C7 定義  | 支持格式 A
| 0b0111       | Write back     | 由寄存器 C7 定義  | 支持格式 B


bit[23：12]用於定義 d-cache 的屬性, bit[11: 0]用於定義 i-cache 的屬性, 兩者格式相同

| 11~9  | 8~6        | 5~3            | 2   | 1~0
| ---   | ---        | ---            | --- | ---
| 000   | cache 容量 | cache 相聯特性 | M   | cache 塊大小

bits[1:0]

| binary value | cache 塊大小
| ---          | ---
| 0b00         | 2 * word
| 0b01         | 4 * word
| 0b10         | 8 * word
| 0b11         | 16 * word

bits[5:3]

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

bits[8:6]

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


### CP15 的寄存器 C1
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


## reference
+ [第 3 章 相關知識點詳解](https://www.crifan.com/files/doc/docbook/uboot_starts_analysis/release/htmls/ch03_related_knowledge.html)
+ [uboot初始化中, 為何要設置CPU為SVC模式而不是設置為其他模式](https://www.crifan.com/files/doc/docbook/uboot_starts_analysis/release/htmls/why_svc_not_other.html)

+ [U-Boot啟動過程--詳細版的完全分析](https://blog.csdn.net/yiyeguzhou100/article/details/52160546)
+ [ARM CP15協處理器](https://www.twblogs.net/a/5c6fe485bd9eee7f0733b211)
+ [協處理器CP15介紹—MCR/MRC指令(6)](https://www.cnblogs.com/lifexy/p/7203786.html)

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

+ mmc commands
    > U-Boot provides access to eMMC devices through the `mmc` command and interface
    but adds an additional argument to the mmc interface to describe the hardware partition.

    ```
    # uboot 中首先查看 emmc 的編號
    uboot=> mmc list
    FSL_SDHC: 0
    FSL_SDHC: 1
    FSL_SDHC: 2 (eMMC)

    # 確定 emmc 的序號是2
    # 查看 emmc 命令
    uboot=> mmc
    mmc - MMC sub system
    Usage:
    mmc info - display info of the current MMC device
    mmc read addr blk# cnt
    mmc write addr blk# cnt
    mmc erase blk# cnt
    mmc rescan
    mmc part - lists available partition on current mmc device
    mmc dev [dev] [part] - show or set current mmc device [partition]
    mmc list - lists available devices
    mmc hwpartition [args...] - does hardware partitioning
        arguments (sizes in 512-byte blocks):
            [user [enh start cnt] [wrrel {on|off}]] - sets user data area attributes
            [gp1|gp2|gp3|gp4 cnt [enh] [wrrel {on|off}]] - general purpose partition
            [check|set|complete] - mode, complete set partitioning completed
        WARNING: Partitioning is a write-once setting once it is set to complete.
        Power cycling is required to initialize partitions after set to complete.
    mmc bootbus dev boot_bus_width reset_boot_bus_width boot_mode
        - Set the BOOT_BUS_WIDTH field of the specified device
    mmc bootpart-resize <dev> <boot part size MB> <RPMB part size MB>
        - Change sizes of boot and RPMB partitions of specified device
    mmc partconf dev boot_ack boot_partition partition_access
        - Change the bits of the PARTITION_CONFIG field of the specified device
    mmc rst-function dev value
        - Change the RST_n_FUNCTION field of the specified device
            WARNING: This is a write-once field and 0 / 1 / 2 are the only valid values.
    mmc setdsr <value> - set DSR register value

    # 設置 emmc 的啟動分區, 主要是 partconf 後面的第一個和第三個參數.
    # '2' 是 emmc 的編號, 第三個參數設置啟動的分區, 對應寄存器 BOOT_PARTITION_ENABLE 字段. 設為 0 表示 disable.
    uboot=> mmc partconf 2 0 0 0

    # 或者設置為 '7' 表示從 UDA 啟動, 0 和 7 我都嘗試了, 燒錄原來的鏡像都能夠啟動成功.
    uboot=> mmc partconf 2 0 7 0
    ```

    - `mmc read [addr] [blk#] [cnt]`
        > read `[cnt]` blocks from the `[blk#]-th` in flash to system memory `[addr]`
        > + `[addr]` is system buffer memory (DDR)
        > + `[blk#]` is the block order of flash
        > + `[cnt]`  is the block count of flash

    - `mmc write addr blk# cnt`
        > write `[cnt]` blocks from system memory `[addr]` to the `[blk#]-th` in flash
        > + `[addr]` is system buffer memory (DDR)
        > + `[blk#]` is the block order of flash
        > + `[cnt]`  is the block count of flash

    - `mmc erase blk# cnt`
        > erase `[cnt]` blocks from the `[blk#]-th` in flash

    - `PARTITION_CONFIG`
        > 為了通用, eMMC controller 會有一個 `PARTITION_CONFIG` register,
        用來控制 partitions 切換
        >> 指令 `mmc partconf dev boot_ack boot_partition partition_access`
        直接對應到 H/w register

        ```
        MSB
        +----------+----------+-----------------------+------------------+
        |   bit 7  | bit 6    |  bit 5 ~ 3            |   bit 2 ~ 0      |
        | reserved | BOOT_ACK | BOOT_PARTITION_ENABLE | PARTITION_ACCESS |
        +----------+----------+-----------------------+------------------+

        * BOOT_ACK (R/W/E)
            0x0: No boot acknowledge sent (default)
            0x1: Boot acknowledge sent during boot operation Bit

        * BOOT_PARTITION_ENABLE (R/W/E)
            User select boot data that will be sent to master

                0x0: device not boot enabled (default)
                0x1: boot partition 1 enable for boot
                0x2: boot partition 2 enable for boot
                0x3~6: reserved
                0x7: User area enabled for boot

        * PARTITION_ACCESS
            user select partition to access

                0x0: No access to boot partition (default)
                0x1: R/W boot partition 1
                0x2: R/W boot partition 2
                0x3: R/W Replay protected memory block (RPMB)
                0x4: Access to General purpose partition 1
                0x5: Access to General purpose partition 2
                0x6: Access to General purpose partition 3
                0x7: Access to General purpose partition 4
        ```

    - `mmc dev [dev] [part]`
        > The interface is therefore described as `mmc` where `[dev]` is the mmc device (some boards have more than one)
        and `[part]` is the hardware partition: 0=user, 1=boot0, 2=boot1.

        ```shell
        # Use the mmc dev command to specify the device and partition:
        => mmc dev 0 0     # select user hw partition
        => mmc dev 0 1     # select boot0 hw partition
        => mmc dev 0 2     # select boot1 hw partition
        ```

    - `mmc partconf`
        > The `mmc partconf` command can be used to configure the `PARTITION_CONFIG` specifying
        what hardware partition to boot from:

        ```
        # uboot console
        => mmc partconf 0 0 0 0     # disable boot partition (default unset condition; boots from user partition)
        => mmc partconf 0 1 1 0     # set boot0 partition (with ack)
        => mmc partconf 0 1 2 0     # set boot1 partition (with ack)
        => mmc partconf 0 1 7 0     # set user partition (with ack)
        ```

    - `mmc rpmb`
        > If U-Boot has been built with `CONFIG_SUPPORT_EMMC_RPMB` the mmc rpmb command is available
        for reading, writing and programming the key for the RPMB partition in eMMC.

    - When using U-Boot to write to eMMC (or microSD) it is often useful to use the `gzwrite` command.
    For example if you have a compressed **disk image**,
    you can write it to your eMMC (assuming it is mmc dev 0) with:

    ```
    => tftpboot ${loadaddr} disk-image.gz && gzwrite mmc 0 ${loadaddr} ${filesize}
    ```

        1. The `disk-image.gz` contains a partition table at `offset 0x0` as well as partitions
        at their respective offsets (according to the partition table) and has been compressed with gzip.

        1. If you know the flash offset of a specific partition
        (which you can determine using the part list mmc 0 command)
        you can also use `gzwrite` to flash a compressed partition image.

## tftp in uboot

+ host side

    - TFTP Server

        1. install

            ```bash
            $ sudo apt-get install tftpd-hpa    # tftp server
            $ sudo apt-get install tftp-hpa     # tftp client, for test
            ```

        1. 配置TFTP Server

            ```bash
            $ mkdir -p /home/xxx/tftpboot       # xxx為你的用戶名
            $ chmod 777 /home/xxx/tftpboot
            $ sudo vim /etc/default/tftpd-hpa
                TFTP_USERNAME="tftp"
                TFTP_DIRECTORY="/home/xxx/tftpboot"
                TFTP_ADDRESS="0.0.0.0:69
                TFTP_OPTIONS="-l -c -s"
            ```

            > + 修改 `TFTP_DIRECTORY` 為 TFTP_Server 服務目錄, 該目錄最好具有可讀可寫權限
            > + 修改 `TFTP_ADDRESS` 為 0.0.0.0:69, 表示所有 IP 源都可以訪問
            > + 修改 `TFTP_OPTIONS` 為 `-l -c -s`. 其中
            >> `-l`: 以 standalone/listen 模式啟動 TFTP服務, 而不是從 xinetd 啟動

            >> `-c`: 可創建新文件. 默認情況下 TFTP 只允許覆蓋原有文件而不能創建新文件

            >> `-s`: 改變TFTP啟動的根目錄, 加了`-s`後, 客戶端使用 TFTP 時,
            不再需要輸入指定目錄, 填寫文件的文件路徑, 而是使用配置文件中寫好的目錄.

        1. 重啟 TFTP Server

            ```bash
            $ mkdir /home/xxx/tftpboot
            $ sudo service tftpd-hpd restar

            # enter tftp control
            $ tftp 127.0.0.1
            tftp>
            ```

+ target device side (uboot console)

    - configure uboot

        ```
        => setenv ipaddr 192.168.1.20       # 設置開發板的本地IP
        => setenv serverip 192.168.1.103    # 設置 tftp server 的 IP, 也就是你存放 kernel 之類的文件的 tftp 服務器地址
        ```

    - download file

        ```
        => tftp c0008000 zImage
        => erase 0x680000 +0x120000
        => cp.b c0008000 0x680000 0x120000

        # c0008000 是下載開發板裡 memory 地址,
        # zImage 是需要下載的文件名稱,
        # 0x680000 是 kernel 的起始位置,
        # 0x120000 是 kernel 的分區大小.
        ```

## ext2/3/4 in uboot

+ `ext2load` and`ext4load`
    > load a file to memory with ext2/3/4 file system

    ```
    usage: ext4load <interface> <dev:[partition]> <mem addr> <file name> [bytes]
    e.g.
    => ext4load mmc 0:2 0x40008000 uImage

    從第 0 個存儲設備的第 1 個分區的根目錄讀出 uImage 文件到內存地址 0x40008000
    ```

+ `ext4write`
    > save memory data to device with ext4 file system

    ```
    usage: ext4write <interface> <dev[:part]> <addr> <absolute filename path> [sizebytes]
    e.g.
    => ext4write mmc 2:2 0x30007fc0 /boot/uImage 6183120
    ```

# Build u-boot

```bash
export ARCH=arm
export CROSS_COMPILE=arm-none-eabi-

# time make imx6dl_icore_nand_defconfig     # 紀錄編譯時間
make imx6dl_icore_nand_defconfig
make

make cscope
```

+ dependency

    ```bash
    $ sudo apt-get install git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev libc6-dev lib32ncurses5-dev gcc-multilib libx11-dev lib32z1-dev libgl1-mesa-dev

    $ sudo apt-get install device-tree-compiler
    $ sudo apt-get install u-boot-tools # for mkimage tool
    ```

## target board example

+ load uboot with development mode
    > this development mode is H/w pins control.
    this mode will load executable file to `SRAM` and then run.

    - power on and type `4` to enter XMODEM mode
    - load `boot_spl_dbg.bin` with TaraTerm
        > file -> transfer -> XMODEM -> Send -> select `boot_spl_dbg.bin`
    - type `1` (select UART loading)
    - load `u-boot.bin` to run active u-boot image


# MISC

## Commands

+ 檢查及修復檔案系統指令

    - `dumpe2fs`
        > 查看這個 partition 中, superblock 和 Group Description Table 中的信息

        ```bash
        $ dumpe2fs ./ext4.disk
        dumpe2fs 1.44.1 (24-Mar-2018)
        Filesystem volume name:   <none>
        Last mounted on:          <not available>
        Filesystem UUID:          66737b90-1d24-4f13-8589-9df4edc7b757
        Filesystem magic number:  0xEF53
        Filesystem revision #:    1 (dynamic)
        Filesystem features:      has_journal ext_attr resize_inode dir_index filetype extent 64bit flex_bg sparse_super large_file huge_file dir_nlink extra_isize metadata_csum
        Filesystem flags:         signed_directory_hash
        Default mount options:    user_xattr acl
        Filesystem state:         clean
        Errors behavior:          Continue
        Filesystem OS type:       Linux
        Inode count:              2048
        Block count:              2048
        Reserved block count:     102
        Free blocks:              950
        Free inodes:              2037
        First block:              0
        Block size:               4096
        ...

        Group 0: (Blocks 0-2047) csum 0x7a19
          Primary superblock at 0, Group descriptors at 1-1
          Block bitmap at 2 (+2), csum 0xfbdf5b1e
          Inode bitmap at 18 (+18), csum 0xa4024b9c
          Inode table at 34-97 (+34)
          950 free blocks, 2037 free inodes, 2 directories, 2037 unused inodes
          Free blocks: 1098-2047
          Free inodes: 12-2048
        ```

    - `e2fsck`

        ```bash
        $ e2fsck --help
            e2fsck: invalid option -- '-'
            Usage: e2fsck [-panyrcdfktvDFV] [-b superblock] [-B blocksize]
                            [-l|-L bad_blocks_file] [-C fd] [-j external_journal]
                            [-E extended-options] [-z undo_file] device

            Emergency help:
             -p                   Automatic repair (no questions), 自動修復
             -n                   Make no changes to the filesystem, 以[唯讀]方式開啟
             -y                   Assume "yes" to all questions
             -c                   Check for bad blocks and add them to the badblock list
             -f                   Force checking even if filesystem is marked clean
             -v                   Be verbose, 詳細顯示模式
             -b superblock        Use alternative superblock
             -B blocksize         Force blocksize when looking for superblock
             -j external_journal  Set location of the external journal
             -l bad_blocks_file   Add to badblocks list
             -L bad_blocks_file   Set badblocks list
             -z undo_file         Create an undo file
             -V                   顯示出目前 e2fsck 的版本
             -C file              將檢查的結果存到 file 中以便查看

        $ e2fsck -p -y /dev/hda5
        ```

        1. 大部份使用 e2fsck 來檢查硬盤 partition 的情況時, 通常都是情形特殊,
        因此最好先將該 partition umount, 然後再執行 e2fsck 來做檢查,
        若是要非要檢查 `/` 時, 則請進入 singal user mode 再執行.

    - `od`
        > 用來檢視儲存在二進位制檔案中的值

        ```bash
        $ od -tx1 -Ax fs
            000000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
            *
            000400 80 00 00 00 00 04 00 00 33 00 00 00 da 03 00 00
            000410 75 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00
            ...

        # 其中以'*'開頭的行表示這一段數據全是 0 因此省略了
        ```

    - `hexdump`
        > 用來檢視儲存在二進位制檔案中的值

        ```bash
        $ hexdump -C fs
            000000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
            *
            000400 80 00 00 00 00 04 00 00 33 00 00 00 da 03 00 00
            000410 75 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00
            ...

        # 其中以'*'開頭的行表示這一段數據全是 0 因此省略了
        ```

## environment bootargs of u-boot

設定 default environment variables

```c
// at u-boot/include/configs/xxx.h

#define CONFIG_EXTRA_ENV_SETTINGS   "...."
```

## linux 切換到 boot partition

```bash
$ /dev/mmcblk0boot1
```

# simulation environment

+ 生成一個空的 SD卡 image

    ```bash
    # bs: block size= 512/1024/1M
    $ dd if=/dev/zero of=uboot.disk bs=512 count=1024
        1024+0 records in
        1024+0 records out
        1073741824 bytes (1.1 GB, 1.0 GiB) copied, 1.39208 s, 771 MB/s
    ```

    - 創建 GPT 分區
        > 下面創建了兩個分區, 一個用來存放 kernel 和設備樹, 另一個存放 rootfs

        ```bash
        $ sgdisk -n 0:0:+512k -c 0:kernel uboot.disk
            Creating new GPT entries.
            Setting name!
            partNum is 0
            Warning: The kernel is still using the old partition table.
            The new table will be used at the next reboot or after you
            run partprobe(8) or kpartx(8)
            The operation has completed successfully.
        $ sgdisk -n 0:0:0 -c 0:rootfs uboot.disk
            Setting name!
            partNum is 1
            Warning: The kernel is still using the old partition table.
            The new table will be used at the next reboot or after you
            run partprobe(8) or kpartx(8)
            The operation has completed successfully.
        ```

        1. 查看分區

            ```
            $ sgdisk -p uboot.disk
                Disk uboot.disk: 2097152 sectors, 1024.0 MiB
                Sector size (logical): 512 bytes
                Disk identifier (GUID): F15BD4B6-D624-432B-995B-13E7641A9AEB
                Partition table holds up to 128 entries
                Main partition table begins at sector 2 and ends at sector 33
                First usable sector is 34, last usable sector is 2097118
                Partitions will be aligned on 2048-sector boundaries
                Total free space is 2014 sectors (1007.0 KiB)

                Number  Start (sector)    End (sector)  Size       Code  Name
                   1            2048           22527   10.0 MiB    8300  kernel
                   2           22528         2097118   1013.0 MiB  8300  rootfs
            ```

    - host side 操作 SD image file

        1. 尋找一個空閒的 loop 設備

            ```shell
            $ losetup -f
                /dev/loop0
            ```
        1. 將 SD卡 image 映射到 loop 設備上

            ```
            $ sudo losetup /dev/loop0 uboot.disk
            $ sudo partprobe /dev/loop0
            $ ls /dev/loop*   # 看到 '/dev/loop0p1' 和 '/dev/loop0p2' 兩個 devices
                ...
                /dev/loop0p1
                /dev/loop0p2
                ...
            ```

        1. 格式化

            ```
            $ sudo mkfs.fat /dev/loop0p1
            $ sudo mkfs.vfat -F 32 /dev/loop0p1
            $ sudo mkfs.ext4 /dev/loop0p1
            ```

        1. mount

            ```
            $ sudo mount -t fat /dev/loop0p1 p1/
            ```
        1. 拷貝文件

            ```
            $ sudo cp linux-4.14.13/arch/arm/boot/zImage p1/
            ```

        1. umount

            ```
            $ sudo umount p1
            $ sudo losetup -d /dev/loop0
            ```

    - uboot side

        ```
        => mmc info
            Device: MMC
            Manufacturer ID: aa
            OEM: 5859
            Name: QEMU!
            Bus Speed: 6250000
            Mode: SD Legacy
            Rd Block Len: 512
            SD version 2.0
            High Capacity: No
            Capacity: 1 GiB
            Bus Width: 1-bit
            Erase Group Size: 512 Bytes

        => mmc list
            MMC: 0 (SD)

        => fatinfo mmc 0
            Interface:  MMC
              Device 0: Vendor: Man 0000aa Snr adbeef00 Rev: 13.14 Prod: QEMU!
                        Type: Removable Hard Disk
                        Capacity: 1024.0 MB = 1.0 GB (2097152 x 512)
            Filesystem: FAT16 "NO NAME    "

        => mmc part   # LBA address: block number
            Partition Map for MMC device 0  --   Partition Type: EFI

            Part    Start LBA       End LBA         Name
                    Attributes
                    Type GUID
                    Partition GUID
              1     0x00000800      0x000057ff      "kernel"
                    attrs:  0x0000000000000000
                    type:   0fc63daf-8483-4772-8e79-3d69d8477de4
                    guid:   34d20039-0c02-4c5d-9fd2-7a915fcd1406
              2     0x00005800      0x001fffde      "rootfs"
                    attrs:  0x0000000000000000
                    type:   0fc63daf-8483-4772-8e79-3d69d8477de4
                    guid:   7acaa32b-20a9-487c-ac66-15c12fe34ad5

        => fatinfo mmc 0:1      # partition number from 1 ~ 4
            Interface:  MMC
              Device 0: Vendor: Man 0000aa Snr adbeef00 Rev: 13.14 Prod: QEMU!
                        Type: Removable Hard Disk
                        Capacity: 1024.0 MB = 1.0 GB (2097152 x 512)
            Filesystem: FAT16 "NO NAME    "
        ```

+ build uboot

```
$ vi setting.env
    export ARCH=arm
    export CROSS_COMPILE=arm-linux-gnueabi-
    export PATH=$HOME/gcc-linaro-6.5.0-2018.12-i686_arm-linux-gnueabi/bin:$HOME/.local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

$ source setting.env
$ make vexpress_ca9x4_defconfig
```

+ run qemu

```
$ vi ./z_qemu.sh
    #!/bin/bash
    set -e

    uboot_image=u-boot

    if [ ! -f uboot.disk ]; then
        # 64 MBytes: SD card size has to be a power of 2
        dd if=/dev/zero of=uboot.disk bs=512 count=131072
    fi

    qemu-system-arm \
        -M vexpress-a9 \
        -m 256M \
        -smp 1 \
        -nographic \
        -kernel ${uboot_image} \
        -sd ./uboot.disk

```

# others

+ set bit with asm

    ```nasm
        ldr r0, =0xE010E81C     /* register address */
        ldr r1, [r0]
        ldr r2, =((0x1 << 0) | (0x1 << 8) | (0x1 << 9))
        orr r1, r1, r2          /* r1 = r1 | r2; */
        str r1, [r0]            /* write r1 date to r0 */
    ```

# reference

+ [Zero u-boot編譯和使用指南](https://licheezero.readthedocs.io/zh/latest/%E8%B4%A1%E7%8C%AE/article%204.html)
+ [*** u-boot 說明與安裝 (2020 改)](http://pominglee.blogspot.com/2016/11/u-boot-2016_15.html)
+ [***Linux和Uboot下eMMC boot分區讀寫](https://blog.csdn.net/z1026544682/article/details/99965642)
+ [eMMC 簡介](https://linux.codingbelief.com/zh/storage/flash_memory/emmc/)
+ [eMMC 原理 3:分區管理](http://www.wowotech.net/basic_tech/emmc_partitions.html)
+ [***用QEMU模擬運行uboot從SD卡啟動Linux](https://www.cnblogs.com/pengdonglin137/p/12194548.html)
+ [UBOOT中利用CONFIG_EXTRA_ENV_SETTINGS宏來設置默認ENV](https://blog.csdn.net/weixin_42418557/article/details/89018965)
+ [U-boot中常用參數設定及常用宏的解釋和說明](https://blog.csdn.net/alifrank/article/details/50392431)
+ [常用 U-boot命令詳解](https://blog.csdn.net/willand1981/article/details/5822911)
+ [qemu模擬arm系統vexpress-a9—uboot+uImage](https://www.itread01.com/content/1548783372.html)
+ [ARM板移植Linux系統啟動(二)SPL](http://conanwhf.github.io/2017/06/08/bootup-2-spl/)
+ [uboot初始化中,為何要設置CPU為SVC模式而不是設置為其他模式](https://www.crifan.com/files/doc/docbook/uboot_starts_analysis/release/htmls/why_svc_not_other.html)




+ [三星公司 uboot模式下更改分區(EMMC)大小 fdisk命令](https://topic.alibabacloud.com/tc/a/samsung-company-uboot-mode-change-partition-emmc-size-fdisk-command_8_8_10262641.html)
    - [uboot_tiny4412](https://github.com/friendlyarm/uboot_tiny4412)




+ [Linux MMC原理及框架詳解](https://my.oschina.net/u/4399347/blog/3275069)
+ [eMMC分區詳解](http://blog.sina.com.cn/s/blog_5c401a150101jcos.html)
+ [emmc boot1 boot2 partition](https://www.twblogs.net/a/5d2ca04dbd9eee1e5c84c0e4)
+ [u-boot v2018.01 啓動流程分析](https://www.twblogs.net/a/5b8e6a002b7177188344fddf)



+ [在Linux 下製作一個磁盤文件,  可以給他分區, 以及存儲文件, 然後dd 到SD卡便可啟動系統](https://www.cnblogs.com/chenfulin5/p/6649801.html)


+ [emmc啟動分區設置](https://blog.csdn.net/shalan88/article/details/92774956)

