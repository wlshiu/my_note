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

# Reference
---
+ [Day 05: OpenOCD 軟體架構](https://ithelp.ithome.com.tw/articles/10193390)
+ [Day 27: 高手不輕易透露的技巧(1/2) - Flash Programming](https://ithelp.ithome.com.tw/articles/10197190)
+ [Day 28: 高手不輕易透露的技巧(2/2) - Flash Driver & Target Burner](https://ithelp.ithome.com.tw/articles/10197309)
+ [OpenOCD代碼結構淺析(基於RISCV)](https://zhuanlan.zhihu.com/p/259494491)


