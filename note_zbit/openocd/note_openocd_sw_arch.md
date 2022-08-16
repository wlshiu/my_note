OpenOCD Software Architecture [[Back]](note_openocd.md#OpenOCD-Software-Architecture)
---

# 目錄結構
---

```
<openocd/
~ contrib/
  + libdcc/
  ~ loaders/
    + checksum/
    + debug/
    + erase_check/
    + flash/    <---- like FLM of Keil
    + watchdog/
  + remote_bitbang/
  + rpc_examples/
  + rtos-helpers/
  + xsvf_tools/
+ doc/
+ jimtcl/
~ src/
  ~ flash/      <----
    + nand/
    + nor/
  + helper/     <----
  + jtag/
  + pld/
  + rtos/
  + rtt/
  + server/     <----
  + svf/
  + target/     <----
  + transport/
  + xsvf/
~ tcl/
  + board/
  + chip/
  + cpld/
  + cpu/
  + fpga/
  + interface/  <----
  + target/     <----
  + test/
  + tools/
+ testing/
+ tools/

```

+ `flash`
    > 分成 Nor/Nand Flash 的支援

+ `helper`
    > 裡面放一堆 OpenOCD 所提供常用的APIs

+ `jtag`
    > OpenOCD 最底層, JTAG 控制的支援

+ `server`
    > GDB/Telnet 等各種 Server 的支援

+ `target`
    > OpenOCD 最核心的部分, 對每個 Target (CPU)支援的程式都會分類放在這邊

+ `tcl`
    > script

    - `tcl/interface`
        > 用 script 配置 interface

    - `tcl/target`
        > 用 script 配置 target

# Helper APIs
---
## Types

`src/helper/types.h` 定義 OpenOCD 的資料型態

+ uint8_t 的 buffer 轉成 value

    - `le_to_h_u64()`
        > Little Endian 的 uint8_t Buffer 轉成 uint64_t

    - `be_to_h_u64()`
        > Big Endian 的 uint8_t Buffer 轉成 uint64_t

    - `le_to_h_u32()`
        > Little Endian 的 uint8_t Buffer 轉成 uint32_t

    - `be_to_h_u32()`
        > Big Endian 的 uint8_t Buffer 轉成 uint32_t

    - `le_to_h_u16()`
        > Little Endian 的 uint8_t Buffer 轉成 uint16_t

    - `be_to_h_u16()`
        > Big Endian的 uint8_t Buffer 轉成 uint16_t

+ value 轉成 uint8_t 的 buffer

    + `h_u64_to_le()`
    + `h_u64_to_be()`
    + `h_u32_to_le()`
    + `h_u32_to_be()`
    + `h_u16_to_le()`
    + `h_u16_to_be()`

## Command APIs

+ Command Registration (註冊 command)
    > 對應 Telnet Interface

    ```c
    const struct command_registration   hello_command_handlers[] = {
        {
            .name = "hello",
            .handler = handle_hello_command,
            .mode = COMMAND_ANY,
            .help = "prints a warm welcome",
            .usage = "[name]",
        },
        {
            .name = "foo",
            .mode = COMMAND_ANY,
            .help = "example command handler skeleton",
        },
        COMMAND_REGISTRATION_DONE
    };
    ```

    從上可以知道, 一個 Command 主要可以分成以下幾個部分所構成

    - `name`
        > Command 的名稱, 如範例中 **hello**, 表示 user 可以在 GDB 中使用 `monitor hello` 來呼叫 OpenOCD 使用這個 Command

    - `handler`
        > 負責處理這個 Command 的處理函式的名稱

    - `mode`
        > 主要分成 EXEC/CONFIG/ANY 這三種 type, 代表一個 Command 可以在以下這三種情況中使用
        > + `EXEC`: 表示這個 Command 在 OpenOCD init 好之後才能夠使用
        > + `CONFIG`: 表示這個 Command 主要使用在 Config 的階段
        > + `ANY`: 顧名思義, 就是在 EXEC 和 CONFIG 中, 皆可以使用

    - `help`
        > 顯示說明的地方, 當使用者使用 help 的時候, 會印出對應的訊息

    - `usage`
        > 通常放可接受的參數, 一樣是用在 help 的時候



    - `COMMAND_REGISTRATION_DONE` 的定義如下

        ```
        #define COMMAND_REGISTRATION_DONE { .name = NULL, .chain = NULL }
        ```

+ Command Chaining (串接多個 commands/arguments)
    > 利用`.chain`的設定, 將不同的 Commands 及其 arguments 串接起來

    ```c
    /* 串接 'bar', 'baz', 'flag' 三個 commands 及各自的 usages */

    static const struct command_registration    foo_command_handlers[] = {
        {
            .name = "bar",
            .handler = &handle_foo_command,
            .mode = COMMAND_ANY,
            .usage = "address ['enable'|'disable']",
            .help = "an example command",
        },
        {
            .name = "baz",
            .handler = &handle_foo_command,
            .mode = COMMAND_ANY,
            .usage = "address ['enable'|'disable']",
            .help = "a sample command",
        },
        {
            .name = "flag",
            .handler = &handle_flag_command,
            .mode = COMMAND_ANY,
            .usage = "[on|off]",
            .help = "set a flag",
        },
        COMMAND_REGISTRATION_DONE
    };

    const struct command_registration   hello_command_handlers[] =
    {
        {
            .name = "foo",
            .mode = COMMAND_ANY,
            .help = "example command handler skeleton",

            .chain = foo_command_handlers,   <------
        },
        COMMAND_REGISTRATION_DONE
    };
    ```

+ Command Handler
    > Command 的 instance

    - Syntax
        > `<Handler的名稱>` 必須與 Command Registration 時, 所指定的 `.handler` 相同

        ```
        COMMAND_HANDLER(<Handler的名稱>)
        {
            // Do something!!

            return ERROR_OK or ERROR_FAILED;
        }
        ```

    - Specific definition

        ```c
        COMMAND_HANDLER(handle_hello_command)
        {
            if (CMD_ARGC > 1)
                return ERROR_COMMAND_SYNTAX_ERROR;

            if (1 == CMD_ARGC)
            {
                printf("Hello %s\n", CMD_ARGV[0]);
            }

            return ERROR_OK;
        }
        ```

        1. `CMD_ARGC`: 就是 argc
        1. `CMD_ARGV`: 就是 argv

    - `COMMAND_HELPER()` and `CALL_COMMAND_HANDLER()`
        > `COMMAND_HELPER()` 用來將特定 Function 定位為輔助的函式, 也可藉由調用 `CALL_COMMAND_HANDLER()` 來呼叫這個輔助函式

        ```c
        static COMMAND_HELPER(handle_hello_args, const char **sep, const char **name)
        {
            if (CMD_ARGC > 1)
                return ERROR_COMMAND_SYNTAX_ERROR;

            if (1 == CMD_ARGC)
            {
                *sep = " ";
                *name = CMD_ARGV[0];
            }
            else
                *sep = *name = "";

            return ERROR_OK;
        }

        COMMAND_HANDLER(handle_hello_command)
        {
            const char *sep, *name;
            int retval = CALL_COMMAND_HANDLER(handle_hello_args, &sep, &name);
            if (ERROR_OK == retval)
                printf("sep= %s, name= %s\n", sep, name);
            return retval;
        }
        ```

## Logger

+ Logging Level

    ```c
    // src/helper/log.c
    enum log_levels {
        LOG_LVL_SILENT = -3,
        LOG_LVL_OUTPUT = -2,
        LOG_LVL_USER = -1,
        LOG_LVL_ERROR = 0,
        LOG_LVL_WARNING = 1,
        LOG_LVL_INFO = 2,
        LOG_LVL_DEBUG = 3,
        LOG_LVL_DEBUG_IO = 4,
    };
    ```

+ Logger APIs
    > 如同 `printf()` 一般使用, 但 OpenOCD 會自動在後面加上換行符號

    - LOG_INFO(...)
    - LOG_WARNING(...)
    - LOG_ERROR(...)
    - LOG_USER(...)
    - LOG_DEBUG(...)
    - LOG_DEBUG_IO(...)

# Flash Support
---

Nor Flash 是 block-base 的結構 (方便於快速建立 mapping table 或定位)
```
# 層級名稱可能會隨製造商設計不同而不同
Nor flash
    -> Block
        -> Bank
            -> Sector
                -> Page
```

由於 Flash 的特殊性 (non-volatile), 而會需要做 Erase/Program 的操作,
因此 OpenOCD 針對 `Bank` 提供一個 `struct flash_driver`, 來抽象化不同的 flash bank 操作;


## Bank

> 大部分的情況, 可以將 bank 視為一個 Nor Flash

OpenOCD 的流程, 是以抽象化的 Bank 視角出發;
當要對 Bank 操作時, 再去找到對應的 **Flash Driver**, 進行 low level 設定

```c
// src/flash/nor/core.h

struct flash_bank {
    char *name;

    struct target *target;      /**< Target to which this bank belongs. */

    const struct flash_driver *driver;  /**< Driver for this bank. */

    void *driver_priv;          /**< Private driver storage pointer */

    unsigned int bank_number;   /**< The 'bank' (or chip number) of this instance. */
    target_addr_t base;         /**< The base address of this bank */
    uint32_t size;              /**< The size of this chip bank, in bytes */

    unsigned int chip_width;    /**< Width of the chip in bytes (1,2,4 bytes) */
    unsigned int bus_width;     /**< Maximum bus width, in bytes (1,2,4 bytes) */

    /** Erased value. Defaults to 0xFF. */
    uint8_t erased_value;

    /** Default padded value used, normally this matches the  flash
     * erased value. Defaults to 0xFF. */
    uint8_t default_padded_value;

    /** Required alignment of flash write start address.
     * Default 0, no alignment. Can be any power of two or FLASH_WRITE_ALIGN_SECTOR */
    uint32_t write_start_alignment;

    /** Required alignment of flash write end address.
     * Default 0, no alignment. Can be any power of two or FLASH_WRITE_ALIGN_SECTOR */
    uint32_t write_end_alignment;

    /** Minimal gap between sections to discontinue flash write
     * Default FLASH_WRITE_GAP_SECTOR splits the write if one or more untouched
     * sectors in between.
     * Can be size in bytes or FLASH_WRITE_CONTINUOUS */
    uint32_t minimal_write_gap;

    /**
     * The number of sectors on this chip.  This value will
     * be set initially to 0, and the flash driver must set this to
     * some non-zero value during "probe()" or "auto_probe()".
     */
    unsigned int num_sectors;

    /** Array of sectors, allocated and initialized by the flash driver */
    struct flash_sector *sectors;

    /**
     * The number of protection blocks in this bank. This value
     * is set initially to 0 and sectors are used as protection blocks.
     * Driver probe can set protection blocks array to work with
     * protection granularity different than sector size.
     */
    unsigned int num_prot_blocks;

    /** Array of protection blocks, allocated and initialized by the flash driver */
    struct flash_sector *prot_blocks;

    struct flash_bank *next;        /**< The next flash bank on this chip */
};
```

+ `name`
    > 基本上就是幫這個 Bank 給個名稱, 方變之後用 name 找 bank

+ `driver`
    > 這邊放 `struct flash_driver`, **OpenOCD 操作都是從 Bank 找到 Flash Driver** 後, 再到底層去處理

+ `base/size`
    > 就是放這個 Bank 的 Base-Address and Size

+ `num_sectors`
    > 這個 Bank 的 Sectors 總數

+ `sectors`
    > 每個 Sector 都有自己的狀態, 這邊用一個 Array 存放指向這些 Sector 的 pointer


## Sector

```c
// src/flash/nor/core.h
struct flash_sector {
    /** Bus offset from start of the flash chip (in bytes). */
    uint32_t offset;

    /** Number of bytes in this flash sector. */
    uint32_t size;

    /**
     * Indication of erasure status: 0 = not erased, 1 = erased,
     * other = unknown.  Set by @c flash_driver_s::erase_check only.
     *
     * This information must be considered stale immediately.
     * Don't set it in flash_driver_s::erase or a device mass_erase
     * Don't clear it in flash_driver_s::write
     * The flag is not used in a protection block
     */
    int is_erased;

    /**
     * Indication of protection status: 0 = unprotected/unlocked,
     * 1 = protected/locked, other = unknown.  Set by
     * @c flash_driver_s::protect_check.
     *
     * This information must be considered stale immediately.
     * A million things could make it stale: power cycle,
     * reset of target, code running on target, etc.
     *
     * If a flash_bank uses an extra array of protection blocks,
     * protection flag is not valid in sector array
     */
    int is_protected;
};
```

+ `offset`
    > 跟 Flash 起始位置間的偏移量

+ `size`
    > 這個 Sector 的大小 (ps. Sector 大小可能不同, 請參照文件)

+ `is_erased`
    > Flash 在寫入之前, 要先進行 Erase, 這邊用來記錄這個 Sector 有沒有被清理過

+ `is_protected`
    > 用來保護這個 Sector, 防止被Erase/Program


## Flash Driver

```c
// src/flash/nor/driver.h

struct flash_driver {
    const char *name;
    const char *usage;

    const struct command_registration *commands;

    __FLASH_BANK_COMMAND((*flash_bank_command));

    int (*erase)(struct flash_bank *bank,
                    unsigned int first, unsigned int last);

    int (*protect)(struct flash_bank *bank,
                    int set, unsigned int first, unsigned int last);

    int (*write)(struct flash_bank *bank,
                    const uint8_t *buffer, uint32_t offset, uint32_t count);

     int (*read)(struct flash_bank *bank,
                    uint8_t *buffer, uint32_t offset, uint32_t count);

    int (*verify)(struct flash_bank *bank,
                    const uint8_t *buffer, uint32_t offset, uint32_t count);

    int (*probe)(struct flash_bank *bank);

    int (*erase_check)(struct flash_bank *bank);

    int (*protect_check)(struct flash_bank *bank);

    int (*info)(struct flash_bank *bank, char *buf, int buf_size);

    int (*auto_probe)(struct flash_bank *bank);

    /**
     * Deallocates private driver structures.
     * Use default_flash_free_driver_priv() to simply free(bank->driver_priv)
     *
     * @param bank - the bank being destroyed
     */
    void (*free_driver_priv)(struct flash_bank *bank);
};
```

+ `name`
    > 提供一個對應的名稱

+ `commmands
    > 如果有針對這個 Flash Driver, **提供特別的 Commmands**, 可在這邊註冊

+ `flash_bank_command`
    > 主要在初始化過程中, 去處理 Config 中的設定, 並初始化內部的資料

+ `erase`
    > 以 Sector 為單位, 將 Flash 指定的 Sectors 做 Erase

+ `protect`
    > 以 Sector 為單位, 將 Flash unlock

+ `write`
    > 就是將 buffer 的內容, program 到指定的 Address

+ `probe`
    > 初始化 Sectors 用, 查詢每個 Sector 的狀態

+ `info`
    > 將 Flash 相關的資料轉成 String

+ `auto_probe`
    > 提供上層呼叫使用(e.g. GDB), 在每次 Flash 進行 Program 前, GDB 都會要求呼叫這個函式


### method `auto_probe` and `probe`

主要負責初始化這個 Bank 中, 內部的 Setors 資料內容


### method `erase`

將 Flash 進行 Erase

### method `write`

Flash Program 的實作

## Target Burner (contrib/loaders/flash/)

OpenOCD 每做一次的 Tx/Rx 就是多筆 `USB + JTAG + FlashCtrl` 傳輸, 中間 protocol 的 overhead 相當高.

若一次性將 data 搬到 Target 的 SRAM, 然後透過一個預先設計好並載入到 Target 上面的 **Burner Program (like FLM of Keil-C)**,
負責將 data 透過 Flash Controller 寫入到 Flash 上, 如此就能加速燒錄效率
> overhead of protocol 就只有 **傳輸到 SRAM** 的部分


+ Burner Program (Burner Routine)
    > reference **stm32f1x**

    - build bin

        ```
        openocd/contrib/loaders/flash/stm32/Makefile
        ```
    - communicate to burner routine of target

        ```c
        static int stm32x_write_block(struct flash_bank *bank, const uint8_t *buffer, uint32_t address, uint32_t count)
        {
            struct stm32x_flash_bank *stm32x_info = bank->driver_priv;
            struct target *target = bank->target;
            uint32_t buffer_size = 16384;
            struct working_area *write_algorithm;
            struct working_area *source;
            struct reg_param reg_params[5];
            struct armv7m_algorithm armv7m_info;
            int retval = ERROR_OK;

            /**
             *  burner routine bin data, it will load to SRAM of target
             */
            static const uint8_t stm32x_flash_write_code[] = {
        #include "../../../contrib/loaders/flash/stm32/stm32f1x.inc"
            };

            /**
             *  flash write code
             *  ps. 經由 '-work-area-phys' and '-work-area-size' 來配置 burner routine 運行區域
             *
             *  - target_alloc_working_area()       Allocate SRAM of target for burner routine (RO-code)
             *  - target_write_buffer()             load data to SRAM of target
             */
            if (target_alloc_working_area(target, sizeof(stm32x_flash_write_code),
                    &write_algorithm) != ERROR_OK) {
                LOG_WARNING("no working area available, can't do block memory writes");
                return ERROR_TARGET_RESOURCE_NOT_AVAILABLE;
            }

            retval = target_write_buffer(target, write_algorithm->address,
                    sizeof(stm32x_flash_write_code), stm32x_flash_write_code);
            if (retval != ERROR_OK) {
                target_free_working_area(target, write_algorithm);
                return retval;
            }

            /**
             *  memory buffer
             *  ps. openocd 資料傳輸存放 Data buffer, 之後 burner routine 再 program 到 flash
             */
            while (target_alloc_working_area_try(target, buffer_size, &source) != ERROR_OK) {
                buffer_size /= 2;
                buffer_size &= ~3UL; /* Make sure it's 4 byte aligned */
                if (buffer_size <= 256) {
                    /* we already allocated the writing code, but failed to get a
                     * buffer, free the algorithm */
                    target_free_working_area(target, write_algorithm);

                    LOG_WARNING("no large enough working area available, can't do block memory writes");
                    return ERROR_TARGET_RESOURCE_NOT_AVAILABLE;
                }
            }

            /**
             *  設定 arguments 到 General-Purpose Registers (GPRs) of ARM
             */
            init_reg_param(&reg_params[0], "r0", 32, PARAM_IN_OUT); /* flash base (in), status (out) */
            init_reg_param(&reg_params[1], "r1", 32, PARAM_OUT);    /* count (halfword-16bit) */
            init_reg_param(&reg_params[2], "r2", 32, PARAM_OUT);    /* buffer start */
            init_reg_param(&reg_params[3], "r3", 32, PARAM_OUT);    /* buffer end */
            init_reg_param(&reg_params[4], "r4", 32, PARAM_IN_OUT); /* target address */

            buf_set_u32(reg_params[0].value, 0, 32, stm32x_info->register_base);
            buf_set_u32(reg_params[1].value, 0, 32, count);
            buf_set_u32(reg_params[2].value, 0, 32, source->address);
            buf_set_u32(reg_params[3].value, 0, 32, source->address + source->size);
            buf_set_u32(reg_params[4].value, 0, 32, address);

            armv7m_info.common_magic = ARMV7M_COMMON_MAGIC;
            armv7m_info.core_mode = ARM_MODE_THREAD;

            /**
             *  Trigger target to execute burner routine
             */
            retval = target_run_flash_async_algorithm(target, buffer, count, 2,
                    0, NULL,
                    5, reg_params,
                    source->address, source->size,
                    write_algorithm->address, 0,
                    &armv7m_info);

            if (retval == ERROR_FLASH_OPERATION_FAILED) {
                LOG_ERROR("flash write failed at address 0x%"PRIx32,
                        buf_get_u32(reg_params[4].value, 0, 32));

                if (buf_get_u32(reg_params[0].value, 0, 32) & FLASH_PGERR) {
                    LOG_ERROR("flash memory not erased before writing");
                    /* Clear but report errors */
                    target_write_u32(target, stm32x_get_flash_reg(bank, STM32_FLASH_SR), FLASH_PGERR);
                }

                if (buf_get_u32(reg_params[0].value, 0, 32) & FLASH_WRPRTERR) {
                    LOG_ERROR("flash memory write protected");
                    /* Clear but report errors */
                    target_write_u32(target, stm32x_get_flash_reg(bank, STM32_FLASH_SR), FLASH_WRPRTERR);
                }
            }

            /**
             *   釋放 work-area of target
             */
            target_free_working_area(target, source);
            target_free_working_area(target, write_algorithm);

            destroy_reg_param(&reg_params[0]);
            destroy_reg_param(&reg_params[1]);
            destroy_reg_param(&reg_params[2]);
            destroy_reg_param(&reg_params[3]);
            destroy_reg_param(&reg_params[4]);

            return retval;
        }
        ```

    - burner gun assembly code
        > compiler output **stm32f1x.inc**

        1. `stm32f1x.S`

            ```asm
                .text
                .syntax unified
                .cpu cortex-m0
                .thumb

                /* Params:
                 * r0 - flash base (in), status (out)
                 * r1 - count (halfword-16bit)
                 * r2 - workarea start
                 * r3 - workarea end
                 * r4 - target address
                 * Clobbered:
                 * r5 - rp
                 * r6 - wp, tmp
                 * r7 - tmp
                 */

            #define STM32_FLASH_SR_OFFSET   0x0c /* offset of SR register from flash reg base */

                .thumb_func
                .global _start
            _start:
            wait_fifo:
                ldr     r6, [r2, #0]    /* read wp */
                cmp     r6, #0          /* abort if wp == 0 */
                beq     exit
                ldr     r5, [r2, #4]    /* read rp */
                cmp     r5, r6          /* wait until rp != wp */
                beq     wait_fifo
                ldrh    r6, [r5]        /* "*target_address++ = *rp++" */
                strh    r6, [r4]
                adds    r5, #2
                adds    r4, #2
            busy:
                ldr     r6, [r0, #STM32_FLASH_SR_OFFSET]    /* wait until BSY flag is reset */
                movs    r7, #1
                tst     r6, r7
                bne     busy
                movs    r7, #0x14       /* check the error bits */
                tst     r6, r7
                bne     error
                cmp     r5, r3          /* wrap rp at end of buffer */
                bcc no_wrap
                mov r5, r2
                adds    r5, #8
            no_wrap:
                str     r5, [r2, #4]    /* store rp */
                subs    r1, r1, #1      /* decrement halfword count */
                cmp     r1, #0
                beq     exit            /* loop if not done */
                b   wait_fifo
            error:
                movs    r0, #0
                str     r0, [r2, #4]    /* set rp = 0 on error */
            exit:
                mov     r0, r6          /* return status in r0 */
                bkpt    #0
            ```

        1. Pseudo code of C

            ```
            /* convert ....\openocd_zbit\contrib\loaders\flash\stm32\stm32f1x.S to C code */

            typedef struct xfer_data
            {
                uint32_t    *pWrite;
                uint32_t    *pRead;
                uint8_t     data[];
            } xfer_data_t;

            static uint8_t      workarea[16 <<10];    // for streaming
            static xfer_data_t  *pXfer_data = (xfer_data_t*)&workarea;

            pXfer_data->wr_pos = (uint32_t)&workarea[sizeof(xfer_data_t)];  // &workarea[8]
            pXfer_data->rd_pos = (uint32_t)&workarea[sizeof(xfer_data_t)];


            /**
             *  @brief  Target device (remote) routine for programming to flash
             *
             *  @param [in] flash_reg_base      r0 - flash base (in), status (out)
             *  @param [in] hword_cnt           r1 - count (halfword-16bit)
             *  @param [in] workarea_start      r2 - workarea start => FIFO start
             *  @param [in] workarea_end        r3 - workarea end   => FIFO end
             *  @param [in] flash_addr          r4 - target address
             *  @return
             *      none
             */
            void burner_routine(uint32_t flash_reg_base, uint32_t hword_cnt,
                                uint32_t workarea_start, uint32_t workarea_end,
                                uint32_t flash_addr)
            {
                register uint32_t r0 = flash_reg_base;
                register uint32_t r2 = workarea_start;
                register uint32_t r3 = workarea_end;
                register uint32_t r4 = flash_addr;

                /* In OpenOCD side, configure flash to program mode */

            wait_fifo:
                register uint32_t r6;
                register uint32_t r5;

                r6 = *(r2 + 0);     // @ r6 = pXfer_data->pWrite;
                if( r6 == 0 )
                    goto exit;

                r5 = *(r2 + 4);     // @ r5 = pXfer_data->pRead;
                if( r6 == r5 )
                    goto wait_fifo;

                r6 = *r5;
                *r4 = r6;   // trigger bus event to write flash address

                r5 += 2;    // program half-word
                r4 += 2;

            busy:
                r6 = *((uint32_t*)(r0 + STM32_FLASH_SR_OFFSET));
                r7 = 1;
                if( (r6 & r7) != 0 )
                    goto busy;

                r7 = 0x14;
                if( (r6 & r7) != 0 )
                    goto error;

                if( r5 < r3 )  // @ pRead < FIFO_End
                    goto no_wrap;

                r5 = r2;
                r5 += 8;    // @ r5 = FIFO_Start

            no_wrap:
                *(r2 + 4) = r5;  // @ pXfer_data->pRead = r5
                r1--;
                if( r1 < 0)
                    goto exit;

                goto wait_fifo;

            error:
                r0 = 0;
                *(r2 + 4) = r0; // @ pXfer_data->pRead = 0

            exit:
                r0 = r6;
                __BKPT(0);
                return;
            }
            ```

# Add self nor flash
---
+ Create your `struct flash_driver` with c file
    > implement the methods of flash driver

    ```c
    // src/flash/nor/my_nor_flash.c
    const struct flash_driver   my_nor_flash =
    {
        .name               = "my flash",
        .commands           = my_flash_command_handlers,
        .flash_bank_command = my_flash_flash_bank_command,
        .erase              = my_flash_erase,
        .protect            = my_flash_protect,
        .write              = my_flash_write,
        .read               = default_flash_read,
        .probe              = my_flash_probe,
        .auto_probe         = my_flash_auto_probe,
        .erase_check        = default_flash_blank_check,
        .protect_check      = my_flash_protect_check,
        .info               = my_flash_info,
        .free_driver_priv   = default_flash_free_driver_priv,
    };
    ```

+ Add to compile list

    ```makefile
    # src/flash/nor/Makefile.am
    NOR_DRIVERS = \
        ...
        %D%/my_nor_flash.c

    NORHEADERS = \
        ...
    ```

+ Add to device list of openocd

    ```c
    // src/flash/nor/drivers.c

    ...
    extern const struct flash_driver my_nor_flash;

    static const struct flash_driver * const flash_drivers[] = {
        ...
        &my_nor_flash,
        NULL,
    };
    ```

+ Add tcl script to configure openocd

    ```
    # tcl/target/my_nor_flash.cfg
    ```

# Source code trace

## main

```c
//===============================================
//  the main entry
//===============================================
openocd_main()
    setup_command_handler()
        command_init()                              // "startup_tcl.inc' initialization"
        (*command_registrants[i]) (cmd_ctx) ----+   // "register all commands below in the table"
                                                |
                                                v
                                static const command registrant_t   command registrants[] = {
                                    &openocd_register_commands,
                                    &server_register_commands,
                                    &gdb_register_commands,
                                    &log_register_commands,
                                    &transport register_commands,
                                    &interface_register_commands,
                                    &target_register_commands,
                                    &flash register_commands,
                                    &nand_register_commands,
                                    &pld_register_commands,
                                    &mflash_register_commands,
                                    &cti_register_commands,
                                    &dap_register_commands,
                                    NULL
                                };


    util_init ()            // "register the command 'util command_handlers'"
    openocd_thread()        // "*** start the execute ***
        server_loop()
    flash_free_all_banks()  // "free all bank"
    gdb_service_free()
    server_free()
    unregister_all_commands()
```

+ `command_registrants[]` 中存放的是, 所有需要進行注冊的 command handler, 當 configure 文件在解析處理的過程中, 會最終調用這些 handler 進行處理

+ 以注冊 trace handler 為例, 以下是 trace handler 的結構
    > 注意其中的 name 與 handler 是對應的, `Jim module` 在查找特定 handler 的時候, 就是通過 name 來定位的

    - `.mode = COMMAND_EXEC`
        > 表示該 handler 是在 CLI 中, 通過輸入命令才會觸發的預注冊函數.

    - `.mode = COMMAND_CONFIG`
        > 表示該 handler 是在 OpenOCD 啟動階段, 並解析 cfg 文件的時候, 才會觸發的預注冊函數.

    - `.mode = COMMAND_ANY`
        > 表示該以上兩種情況下, 都會觸發的預注冊 handler.

        ```
        // the trace command list below
        static const struct command_registration trace_exec_command_handlers[] =
        {
            {
                .name    = "history",
                .handler = handle_trace_history_command,
                .mode    = COMMAND_EXEC,
                .help    = "display trace history, clear history or set size",
                .usage   = "['clear'|size]",
            },
            {
                .name    = "point",
                .handler = handle trace_point_command,
                .mode    = COMMAND_EXEC,
                .help    = "display trace points, clear list of trace points,"
                            "or add new tracepoint at address",
                .usage   = "['clear's address]",
            },
            COMMAND_REGISTRATION_DONE
        };

        static const struct command_registration trace_command_handlers[] =
        {
            {
                .name  = "trace",
                .mode  = COMMAND_EXEC,
                .help  = "trace command group",
                .usage = "",
                .chain = trace exec command_handlers,
            },
            COMMAND_REGISTRATION_DONE
        };
        ```

    - Command link list
        > 先找到對應的 `Cmd Root handler`, 在往 `children` 找

        ```
                                    Cmd Root
                                +----------------------+  *children   +-----------------+  *next   +---------------+
          command_context   --> |     "trace" cmd      | -----------> |   "point" cmd   | -------> | "history" cmd |
                                +----------------------+              +-----------------+          +---------------+
                                  |
                                  | *next
                                  v
                                +----------------------+  *children   +-----------------+
                                | "target_request" cmd | -----------> | "debugmsgs" cmd |
                                +----------------------+              +-----------------+
                                  |
                                  | *next
                                  v
                                +----------------------+  *children   +-----------------+  *next   +---------------+
                                |     "mflash" cmd     | -----------> |   "bank " cmd   | -------> |  "init " cmd  |
                                +----------------------+              +-----------------+          +---------------+
                                  |
                                  | *next
                                  v
                                +----------------------+  *children   +-----------------+  *next   +---------------+  *next   +-------------+  *next   +------------+
                                |     "flash" cmd      | -----------> |   "bank" cmd    | -------> |  "init" cmd   | -------> | "banks" cmd | -------> | "list" cmd |
                                +----------------------+              +-----------------+          +---------------+          +-------------+          +------------+
                                  |
                                  | *next
                                  v
                                +----------------------+  *children   +-----------------+
                                |   "transport" cmd    | -----------> |    "xx" cmd     | -------> ...
                                +----------------------+              +-----------------+
                                  |
                                  | *next
                                  v
                                  ....
        ```

## OpenOCD link to GDB

+ `server_loop()`
    > `server_loop()` 本身是一個大循環, 接收來自 GDB 或 Telnet 等, 通過 socket 傳過來的數據. <br>
    呼叫 `server->input()` 對接收到的數據進行解析, 然後再調用特定的函數進行處理

    ```

    socket_loop()
        service->input(c)               // "register the handler by add_service() function, such as: gdb_input()"
            gdb_input()                 // "the command coming from GDB will be received in gdb_packet_buffer[] buffer"
                gdb_input_inner()
                    gdb_get_packet()
                    gdb_thread_packet()
                    gdb_get_registers_packet()
                    gdb_set_registers_packet()
    ```



+ GDB 命令執行 flow

    - **Add S/w Break-point flow**
        > 其中 `Z0,100310,4` 是來自 GDB 發送過來的命令字符串,
        > + `Z0`表示設置軟斷點,
        >> `0`表示 S/w Break-point, `1`則表示 H/w Break-point
        > + `100310`為 16 進制值, 表示斷點設置的 address,
        > + `4` 表示該地址處的機器碼長度為 4 個 bytes.
        > + `$OK#9a` 表示 OpenOCD 處理完該命令後, 要反饋給 GDB 的訊息

        ```
        "Z0,100310,4"   // add the software breakpoint, command from GDB
        --> "$OK#9a"    // feedback to GDB

        gdb_input()
            gdb_input_inner()
                gdb_breakpoint_watchpoint_packet()
                    breakpoint_add()
                        breakpoint_add_internal()
                            target_add_breakpoint()
                                target->type->add_breakpoint()
                                    riscv_add_breakpoint()

                                        target_read_memory()
                                            target->type->read_memory()
                                                riscv_read_memory()

                                        target_write_memory()   // 'ebreak()/ebreak_c()' write into target memory
                                            target->type->write_memory ()
                                                riscv_write_memory ()

                    gdb_put_packet()    // feedback response to GDB

        ```

        1. 上例子是基於 RISC-V 平台, 通過 backtrace 可以看到, 對於 S/w Break-point 的設置, OpenOCD 會做兩個步驟
            > + 先將 Break-point Address 中的 machine code, 讀取到 OpenOCD 中, 並保存起來
            >> 通過 `riscv_read_memory()`
            > + 再將 Break-point 的 machine code, 寫入到 Target 的內存中
            >> 通過 `riscv_write_memory()` <br>
            在 RISC-V 中, 是將 ebreak(4-byte) 或 c.ebreak(2-bytes) 的 machine code, 寫入到 Target 內存中.

        1. 當 Target (Core) 運行程序的時, 執行到替換後的 break 指令, 就會觸發 exception 並 halt 住;
            > 此時 Target(Core) 就進入 debug 狀態停止下來, 等待來自 OpenOCD 的 polling.

        1. OpenOCD 在處理完來自 GDB 的命令後, 一般都會呼叫 `gdb_put_packet()`, 將結果反饋給 GDB
            > 反饋的 message 必需滿足 GDB 的命令格式


    - **Delete S/w Break-point flow**
        > OpenOCD 收到來自 GDB 的命令 `z0,100310,4`, 其中 `z0` 表示要刪除 S/w Break-point
        >> 刪除 S/w Break-point 的處理, 與新增 S/w Break-point 的處理邏輯相反. <br>
        需要將保存在 OpenOCD 中, 原地址處的機器碼, 寫回到 Target 的原位置(通過 `riscv_remove_breakpoint`).

        ```
        "z0,100310,4"   // delete the software breakpoint
        --> "$OK#9a"    // feedback to GDB

        gdb_input()
            gdb_input_inner()
                gdb_breakpoint_watchpoint_packet()
                    breakpoint_remove()
                        breakpoint_remove_internal()
                            breakpoint_free()
                                target_remove_breakpoint()
                                    target->type->remove_breakpoint()
                                        riscv_remove_breakpoint())

                                            target_write_memory ()  // for software breakpoint delete
                                                target->type->write_memory()
                                                    riscv_write_memory()
                                                        target->type->virt2phys()
                                                        tt->write_memory()

                                            remove_trigger()        // for hardware breakpoint delete

        gdb_put_packet()    // feedback response to GDB
        ```

    - **Step by Step flow**
        > 在處理程序的最底層, 實際調用的是 `dmi_write()/dmi_read()`
        此 APIs 涉及到 OpenOCD 對 Target 中 Debug Module 的 registers 訪問.

        ```
        "vCont;s:0;c:0"                                         // single step
        --> "$05b305d20466f756e6420312074726967676572730a#cf"   // feedback response to GDB
        --> "$T05#b9"

        gdb_input()
            gdb_input_inner()
                gdb_v_packet()
                    gdb_handle_vcont_packet()
                        target_step()   // execute step command
                            target->type->step()
                                old_or_new_riscv_step()
                                    riscv_openocd_step()
                                        riscv_step_rtos_hart()
                                            r->step_current_hart()
                                                riscv013_step_current_hart()
                                                    riscv013_step_or_resume_current_hart()
                                                        dmi_write() / dmi_read()    // send the command to Debug Module in MCU target through JLINK
                                                                                    // poll target MCU state
                            target_poll()
                                target->type->poll()
                                    old_or_new_riscv_poll()
                                        riscv_openocd_poll()
                            gdb_signal_reply()      // send response to GDB
                                gdb_put_packet()
        ```

    - ** Read Vector register of RISC-V**
        > 通過建構兩條 instructions 的方式, 將結果暫時讀到 CPU 的 s0 Reg 中, 最終通過 DATAn Reg 將數據獲取出來

        ```
        "p1043" // 讀取 vector register (v1), 1043 是 v1 reg 的號碼

        gdb_input())
            gdb_input_inner()
                gdb_get_register_packet()
                    target_get_gdb_reg_list()   // 獲取所有 register list
                        target->type->get_gdb_reg_list()
                            riscv_get_gdb_reg_list_internal()
                                /* 分配空間容納所有 registers */
                                target->reg_cache->reg_list[i].type->get()
                                    register_get()
                                        r->get_register_buf) // 讀取 vector reg
                                            riscv013_get_register_buf()
                                                register_read()             // 讀取 CPU Reg 's0'並保存
                                                prep_for_register_access()  // 讀 Reg 前, 設定 'mstatus.VS= 1', 允許訪問 vector

                                                    /* 判斷是否為 FPU 或 WEC Reg */
                                                    register_read()         // 讀取 CPU中 mstatus Reg
                                                    /* 若訪問 FPU Reg, 且 'mstatus.FS= 0', 則 register_write_direct() 設定 'mstatus.FS= 1' */
                                                    /* 若訪問 VEC Reg, 且 'mstatus.VS= 0', 則 register_write_direct() 設定 'mstatus.VS= 1' */
                                                prep_for_vector_access()
                                                    register_read()         // 讀取 CPU 中的 VTYPE Reg, 並保存
                                                    register_read()         // 讀取 CPU 中的 VL Reg, 並保存
                                                    register_write_direct() // 變更 CPU 的 vtype.VSEW: element-size 32/64 bits
                                                    register_write_direct() // 更改 CPU 中的 vl, 當前 vector Reg 最大 elements 的數量
                                                riscv_program_init()        // 建構指令的準備工作
                                                riscv_program_insert()      // 建構指令: vmx.x.s s0, vnum [0] 將 vector Reg 中 index= 0 的 elements 複製到 s0 Reg中
                                                riscv_program_insert()      /* 建構指令: vslide1down.vx vnum, vnum, s0 和上一條指令構成一個循環 slide操作;
                                                                               每次把 High index 的 element 移入 Low index 中 */

                                                /* 循環開始, 共 element size 的次數 */
                                                riscv_program_exec()        // 執行上述建構好的 instructions, 將 v Reg中的 data 按 element大小順序讀出並放到 s0 Reg 中
                                                register_read_direct()      // 從 s0 Reg 中讀出並放入 DATA0/DATA1 Reg 中, 然後再通過 DMI 讀取出來
                                                buf_set_u64()               // 進行 data 拼接
                                                /* 循環結束 */

                                                cleanup_after_vector_access()   // 恢復原來的 vtype 和 vl Reg 的值
                                                    register_write_direct()     // 恢復原來的 vtype
                                                    register_write_direct()     // 恢復原來的 v

                                                cleanup_after_register_access() // 恢復原來 mstatus Reg 的狀態
                                                    register_write_direct()
                                                register_write_direct()         // 恢復 CPU Reg s0 原來的值
        ```


# Reference
---
+ [Day 05: OpenOCD 軟體架構](https://ithelp.ithome.com.tw/articles/10193390)
+ [Day 27: 高手不輕易透露的技巧(1/2) - Flash Programming](https://ithelp.ithome.com.tw/articles/10197190)
+ [Day 28: 高手不輕易透露的技巧(2/2) - Flash Driver & Target Burner](https://ithelp.ithome.com.tw/articles/10197309)
+ [OpenOCD代碼結構淺析(基於RISCV)](https://zhuanlan.zhihu.com/p/259494491)


