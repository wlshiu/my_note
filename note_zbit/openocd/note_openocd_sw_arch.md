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


+ Burner Program


# Reference
---
+ [Day 05: OpenOCD 軟體架構](https://ithelp.ithome.com.tw/articles/10193390)
+ [Day 27: 高手不輕易透露的技巧(1/2) - Flash Programming](https://ithelp.ithome.com.tw/articles/10197190)
+ [Day 28: 高手不輕易透露的技巧(2/2) - Flash Driver & Target Burner](https://ithelp.ithome.com.tw/articles/10197309)
+ [OpenOCD代碼結構淺析(基於RISCV)](https://zhuanlan.zhihu.com/p/259494491)


