Link Script
---

    + 用 `;` 結尾
    + 用 `/* */` 註解
    + 可使用 Regular Expression, 支援 wildcard `*`

# Definitions

+ Section memory address
    - `LMA` (Load Memory Address)
        > loading time memory address

    - `VMA` (Virtual Memory Address)
        > run-time memory address

    - 通常 VMA = LMA.
        > 不同情況有東西要**燒到ROM** 時參考 `LMA`.

        > 從**ROM載入** 到記憶體執行的時候參考 `VMA`

    - VMA/LMA info
        > `objdump -h`

        ```shell
        $ arm-none-eabi-objdump -h hello.elf

        hello.elf:     file format elf32-littlearm

        Sections:
        Idx Name             Size      VMA       LMA       File off  Algn
          0 .foo            00000014  00080000  00080000  00020000  2**2    CONTENTS, ALLOC, LOAD, DATA
          1 .text           000000d8  00000000  00000000  00010000  2**2    CONTENTS, ALLOC, LOAD, READONLY, CODE
          2 .rodata         00000016  000000d8  000000d8  000100d8  2**2    CONTENTS, ALLOC, LOAD, READONLY, DATA
          3 .comment        0000001d  00000000  00000000  00020014  2**0    CONTENTS, READONLY
          4 .ARM.attributes 00000033  00000000  00000000  00020031  2**0    CONTENTS, READONLY
        ```

+ Symbol

    所有程式內用到的 veriables, functions都通稱為 symbol

    - defined symbol
        > 為該檔案內的global variable, static varible and funciton

    - undefined symbol
        > 為該檔案內的 extern variables and external funcitons

    - symbol info

        ```shell
        $ objdump -t
            or
        $ nm [object file]
        ```

+ operator
    >  基本與C語言一致
    
    - priority (數字小越高)
        1. `!` `–` `~` (0)
        1. `*` `/` `%`
        1. `+` `-`
        1. `>>`  `=`
        1. `&`
        1. `|`
        1. `&&`
        1. `||`
        1. `? :`
        1. `&=` `+=` `-=` `*=` `/=`(10)

# Commands

+ `MEMORY`

    ```ld
    MEMORY
    {
        REGION_1 [(ATTR)] : ORIGIN = start_addr_1, LENGTH = len1
        REGION_2 [(ATTR)] : ORIGIN = start_addr_2, LENGTH = len2
        ...
    }
    ```
    > 定義 memory region
    >> + `ORIGIN` 區域的開始地址, 可簡寫成 `org` 或 `o`
    >> + `LENGTH` 區域的大小, 可簡寫成 `len` 或 `l`
    >> + `ATTR` 屬性內可以出現以下 7 個 types，
    >>> 1. `R` 只讀section
    >>> 1. `W` 讀/寫section
    >>> 1. `X` 可執行section
    >>> 1. `A` 可分配的section
    >>> 1. `I` 初始化了的section
    >>> 1. `L` 同I
    >>> 1. `!` 不滿足該字符之後的任何一個屬性的section

    - example

        ```ld
        MEMORY
        {
            rom (rx)        : ORIGIN = 0, LENGTH = 256K
            ram (!rx)       : org = 0×40000000, l = 4M
            IRAM_STACK (rw) : ORIGIN = 0x00007d00, LENGTH = 0x00300
        }
        ```


+ `ENTRY(symbol)`
    > 程式第一個執行的 symbol

    - `ld` 預設 priority (數字小越高)
        1. ld 命令行的`-e` 選項 (1)
        1. 連接腳本的 `ENTRY(SYMBOL)` 命令 (2)
        1. 如果定義了 `start`符號, 使用`start` symbol (3)
        1. 如果存在.text section, 使用 `.text section 的第一個 symbol` (4)
        1. 使用值0 (5)
            > memory address 0x0 ???


+ `SECTIONS`

    ```ld
    SECTIONS
    {
        sections-discription
        sections-discription
        ...
    }
    ```

+ section discription

    ```ld
    section_name [address] [(type)] :
        [AT(lma)]
        [ALIGN(section_align) | ALIGN_WITH_INPUT]
        [SUBALIGN(subsection_align)]
        [constraint]
    {
        output-section-command
        output-section-command
        ...
    } [> VMA_region] [AT>LMA_region] [:phdr :phdr ...] [=fillexp]
    ```
    > + `[]`內的內容為可選選項, 一般不需要.
    > + section_name `左右的空白`, `{}`, `:` 是必須的
    > + 換行符和其他空格是可選的.
    > + `=fillexp` value of dummy data if necessary

    - example

        ```ld
        .text :
        {
            KEEP(*(.isr_vector))
            *(.text)
        } >FLASH AT>IMG_INIT
        ```

        > 將 `.text section` 儲存在 LMA 即 `IMG_INIT` 區間 (syntax: AT>IMG_INIT).
        Run-time時, 則 load 到 VMA 即 `FLASH` 區間執行 (syntax: >FLASH)

        >> 當 `FLASH == IMG_INIT`, 則表示儲存跟執行都在相同 memroy region (在 flash 上直接執行)

+ `KEEP`
    > ld 使用 `--gc-sections`後, linker 可能將某些它認為沒用的 section 過濾掉,
    因此用 `KEEP()` 強制 linker 保留一些特定的 section

    ```
    KEEP(*(.text))
        or
    KEEP(SORT(*)(.text))
    ```

+ `OVERLAY`

+ `ALIGN`

+ `ADDR(section_name)`
    > 返回某 section 的 `VMA`值

+ `SIZEOF(section_name)`
    > 返回 section 的大小. 當 section 沒有被分配時, 即此時 section 的大小還不能確定時, 連接器會報錯


# Reference

+ [GNU Linker Scripts](https://sourceware.org/binutils/docs/ld/Scripts.html#Scripts)
+ [Linker Script](http://wen00072.github.io/blog/categories/linker-script/)
+ [Linux下的lds鏈接腳本詳解](https://www.cnblogs.com/li-hao/p/4107964.html)
