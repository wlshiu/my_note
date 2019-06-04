# Link Script
---

+ 用 `;` 結尾
+ 用 `/* */` 註解

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

# Commands

+ `MEMORY`

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
    } [>region] [AT>LMA_region] [:phdr :phdr ...] [=fillexp]
    ```
    > + `[]`內的內容為可選選項, 一般不需要.
    > + section_name `左右的空白`, `{}`, `:` 是必須的
    > + 換行符和其他空格是可選的.

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





# Reference

+ [GNU Linker Scripts](https://sourceware.org/binutils/docs/ld/Scripts.html#Scripts)
+ [Linker Script](http://wen00072.github.io/blog/categories/linker-script/)
