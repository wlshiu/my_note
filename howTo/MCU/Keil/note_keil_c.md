keil c
---

# syntax

## Accessing assembly variables from c

```
# in *.s file
                ALIGN   4
                EXPORT  sys_heap_base ; declare at C program
                EXPORT  Heap_Size
sys_heap_base   DCD    Heap_Size

#########
# in *.c file
extern uint32_t     sys_heap_base;
printf("0x%08x\n", sys_heap_base);
```

```
# in *.s file
        ALIGN   4
        EXPORT  foo
foo     DCD     __initial_sp
        DCD     Stack_Size

#########
# in *.c files
extern uint32_t foo[2];
printf("%08x %d\n", foo[0], foo[1]);
```

## Inline Assembly Language in C Code

可自行最佳化 critical 部份的code, 有些想做的事很難用 C 語言來寫, 用 assembly language 卻事半功倍(e.g. delay 幾個 machine cycle)

ASM statement 基本分成4部分, 用冒號`:`來區分
> + The assembler `instruction`
> + `Output operands`
> + `Input operands`
> + `Clobbered` register (類似宣告成 volatile 的效果)
>> 描述哪些 GPRs 或是 memory 會被這段 assembly code 修改, 請 compiler 要特別處理後面的 code

```
__ASM volatile("instruction..." : Output_operands : Input_operands : Clobbered);
```

+ examples

    - one line expression

        ```
        __ASM volatile("mov %0, %1, ror #1" : "=r" (result) : "r" (value));
        ```

        1. `"=r" (result)` 是output operands
            > `"=r"` 代表放到 GPRs 裡, 在將 GPRs 裡的值放到變數 resule

        1. `"r" (value)` 是input operands
            > `"r"` 代表變數 value, 使用 GPRs 來操作

        1. `%0, %1, %2, ..., %n`
            > 流水號對應後面的 Output_operands and Input_operands

        1. 將 `變數 value` 向右 rotate 1 bit, 然後存到 `變數 result`

    - inline function expression

        ```
        __attribute__((always_inline)) __STATIC_INLINE uint32_t __get_LR(void)
        {
            register uint32_t   result;

            __ASM volatile ("MOV %0, LR\n" : "=r" (result) );
            return(result);
        }

        __STATIC_INLINE uint32_t __get_PSP(void)
        {
            register uint32_t __regProcessStackPointer      __ASM("psp");
            return(__regProcessStackPointer);
        }


        __STATIC_INLINE void __set_PSP(uint32_t topOfProcStack)
        {
            register uint32_t __regProcessStackPointer      __ASM("psp");
            __regProcessStackPointer = topOfProcStack;
        }
        ```

+ Reference
    - [ARM GCC Inline Assembler Cookboo](http://www.ethernut.de/en/documents/arm-inline-asm.html)

## Get a section address/length

```
extern unsigned char Load$$xxx$$Base;
extern unsigned char Load$$xxx$$Length;
uint32_t    addr = (uint32_t)&Load$$xxx$$Base;
uint32_t    len  = (uint32_t)&Load$$xxx$$Length;
```

+ example
    > Get `ER_IROM2` section address/length

    ```
    static void
    _Get_ER_IROM2_section_attr(uint32_t *pLR_Base, uint32_t *pLength)
    {
        extern unsigned char Load$$ER_IROM2$$Base;
        extern unsigned char Load$$ER_IROM2$$Length;
        uint32_t    addr = (uint32_t)&Load$$ER_IROM2$$Base;
        uint32_t    len  = (uint32_t)&Load$$ER_IROM2$$Length;
        printf("addr = 0x%x\n", addr);

        if( pLR_Base )      *pLR_Base = addr;
        if( pLength )       *pLength = len;

        return;
    }
    ```

## Place functions and data at specific addresses

+ Use `__attribute__((section("...")))`

    - place `foo()` to address **0x4000**
        > something wrong, it can't be placed target address...

        ```c
        int foo(void) __attribute__((section(".ARM.__at_0x4000")));
        int foo(void)
        {
            return 10;
        }
        ```

    - place a variable to address **0x3000**

        ```
        int g_value __attribute__((section(".ARM.__at_0x3000")));
        ```

+ Use scatter file
    > place `foo_func()` of `main.o` to `ER_IRAM0`

    ```
    LR_IROM1 0x00000000 0x00010000
    {
        ; load address = execution address
        ER_IROM1 0x00000000 0x00010000
        {
            ; *.o (RESET, +First)
            *(InRoot$$Sections)
            .ANY (+RO)
            .ANY (+XO)
        }

        ER_IRAM0 0x20000000 0x00001000
        {
            main.o (i.foo_func)
        }

        ; RW data
        RW_IRAM1 0x20003100 0x00000F00
        {
            .ANY (+RW +ZI)
        }
    }
    ```

    - cmdline

        ```
        LDFLAGS = --map --scatter=scatter.sct --first='boot.o(vectors)'
        ```

# SymdDefs

Link external static libraries
> 將 img 分成 App 及 library 兩部分, 其中 library 被放到 ROM 裡. <br>
藉由 symdefs file, 在 compile 階段就決定要不要使用 ROM-lib

+ Generate symdefs file
    > `Options for Target` -> `Linker`
    >> 先建立一個可以編譯的 `ROM project`, 並加入不公開的 source code

    ```
    Misc controls: --no-remove --symdefs=symbols.obj
    ```

    - `--no-remove`
        > 保留所有 functions

    - `--symdefs`
        > 產生 symbol table

        1. 編輯 symbol table
            > 刪除要隱藏的 symbols

+ Import a Symdef File

    - `symbols.obj` 加入 project
        > 將 `symbols.obj` 當作 lib 加入 Project

    - 修改 `symbols.obj` 屬性為 `Object file`

        1. Right-click on `symbols.obj`
        1. Select Options for File
        1. Set `File type` to `Object file`

+ Reference

    - [ARMLINK: Create and Import a Symdefs File Using Arm Compiler 6](https://developer.arm.com/documentation/ka003195/latest)


## GCC link external symbol

+ Generate symdefs file

    - symbol file

        ```
        $ arm-none-eabi-nm.exe -g ./main.elf | grep -e "[0-9a-fA-F]* [WTD] [a-zA-Z0-9_]*$" | awk -F ' ' '{print $3 " = " $1 ";"}'
        ```


    - binary raw data

        ```
        $ arm-none-eabi-objcopy --wildcard --strip-symbol=main --strip-symbol="_*" core.elf core.symbin
        ```

+ Import a Symdef File

    - include an elf file

        ```
        $ gcc test.c -o test -Wl,-T xxx.ld -Wl,--just-symbols=core.elf
            or
        $ gcc test.c -o test -Wl,-T xxx.ld --Wl,-R core.elf
        ```

    - include a symbol file

        ```
        $ gcc test.c -o test -Wl,-T xxx.ld core.sym
        ```
        1. symbol file format
            > 其中等號旁的空白是必須的, 如果 format 不對的話 ld 會噴 error(file format not recognized;).
            用了這個之後, link 出來的 symbol 就會從 UND 變成 ABS.

            ```
            symbol1 = 0x12345678;
            symbol2 = 0x23456789;
            ...
            ```

    - link 單一 symbol

        ```
        $ gcc test.c -o test -Wl,-T xxx.ld --defsym symbol1=0x12345678
        ```

+ Reference

    - [Linker - Command Line Options](https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_node/ld_3.html)
    - [Building a two-part firmware image using GCC toolchain](https://stackoverflow.com/questions/35183874/building-a-two-part-firmware-image-using-gcc-toolchain?lq=1)

# fromelf

## Keil-MDK 環境變數

+ Target Output
    > 在 axf file 相同目錄下生成 bin file

    ```
    $ fromelf --bin -o "$L@L.bin" "$L@L.axf"
    ```

    > 生成 disassembly

    ```
    $ fromelf -c !L --output $P@L.S
    ```

    - `L` 指 axf 檔案路徑, 包括文件名

        ```
        假設 axf 檔案路徑為 'D:\out\aa.axf'
        'L' 內容為 'D:\out\aa.axf'
        ```

    - `$L` 指 axf 檔案路徑, 但不包括文件名

        ```
        假設 axf 檔案路徑為 'D:\out\aa.axf'
        'L' 內容為 'D:\out\' 包含最後的 '\'
        ```

    - `@L` 指 axf 檔案名, 但不包括副檔名

        ```
        假設 axf 檔案路徑為 'D:\out\aa.axf'
        '@L' 內容為 'aa' 不包含最後的 '.axf'
        ```

    - ` #L` 絕對路徑, 等價 `L`

    - `!L` 和 project file (`*.uvprojx`) 所在目錄的相對路徑

+ Project name (`*.uvprojx`)

    - `P` project file path

        ```
        假設 project file 為 'D:\app_sdk\meterAPP\app.uvprojx'
        'P' 內容為 'D:\app_sdk\meterAPP\app.uvprojx'
        ```

    - `#P` 絕對路徑, 等同於 `P`

        ```
        假設 project file 為 'D:\app_sdk\meterAPP\app.uvprojx'
        '#P' 內容為 'D:\app_sdk\meterAPP\app.uvprojx'
        ```

    - `$P` 指 uvprojx 檔案路徑, 但不包括文件名

        ```
        假設 project file 為 'D:\app_sdk\meterAPP\app.uvprojx'
        '$P' 內容為 'D:\app_sdk\meterAPP\'
        ```

    - `!P` 和 project file 的相對路徑

        ```
        假設 project file 為 'D:\app_sdk\meterAPP\app.uvprojx'
        ```

    - `@P` prject file name (no file extension)

        ```
        假設 project file 為 'D:\app_sdk\meterAPP\app.uvprojx'
        '@P' 內容為 'app'
        ```


# Customize Tools Menu

+ External editor
    > Tools -> Customize Tools Menu

    ```
    Command   : .../notepad++.exe
    Arguments : #F -> open current file
    ```

# Tips
+ [command window](http://www.keil.com/support/man/docs/uv4/uv4_db_dbg_outputwin.htm)
    - [SAVE](http://www.keil.com/support/man/docs/uv4/uv4_cm_save.htm)
        > dump memory to file

        ```
        # Saves a memory range to a file fname located in the directory path.
        SAVE [path\fname] [startAddr] [, endAddr] [, accSize]

        [path\fname]
            saves the output to the file fname located in the directory path.
            If path is omitted, then the file is located in the root directory of the project.

        [startAddr]
            defines the starting address of the memory. startAddr can be an expression that defaults on an address.

        [endAddr]
            defines the end address of the memory range. endAddr can be an expression that defaults on an address.

        [accSize]
            is defined only for Cortex-M processor-based devices and represents the access size to read target memory.
            The following values are defined:
                Defined Number	        Description
                    0x0	                Is the default setting. Debugger decides which access size to use.
                    0x1	                Byte access
                    0x2	                Short (16-bit) access
                    0x4	                Word (32-bit) access

        e.g.
        > SAVE c:\temp\memoutput.hex main, main+0x500      /* Output beginning at main                */
        > SAVE memoutput.hex  0x100,0x1FF                  /* Output memory between 0x100 and 0x1FF   */
        > SAVE memoutput.hex 0x20000000, 0x20020000, 0x4   /* Reads target memory using Word accesses */
        ```

+ Dump memory to file (In Debug mode, HEX386 format)
    > `Start Debug Session` -> `View->Command Window`

    ```
    > save filepath StartAddr, EndAddr

    e.g.
    > save C:\ExportData.ihex 0x08000000,0x08002000
    ```

    - Convert iHex and Bin
        > [srecord-win32](https://sourceforge.net/projects/srecord/files/srecord-win32/)

        1. iHex to Bin

            ```bash
            #!/bin/bash

            #
            # Intel Hex format to Bin
            #

            help()
            {
                echo -e "Intel Hex format to Bin"
                echo -e "usage: $0 <ihex_path> [offset_addr]"
                echo -e "  e.g. $0 ./test.hex 0x0"
                exit -1
            }

            if [ $# -lt 1 ]; then
                help
            fi

            ihex_path=$1
            bin_path=${ihex_path}.bin

            # STM32 offset 0x08000000
            offset_addr=0x00000000

            srec_cat.exe ${ihex_path} -intel -offset ${offset_addr} -o ${bin_path} -binary
            ```

        1. Bin to iHex

            ```bash
            #!/bin/bash

            help()
            {
                echo -e "Bin to Intel Hex format"
                echo -e "usage: $0 <bin_path> [offset_addr]"
                echo -e "  e.g. $0 ./test.bin 0x0"
                exit -1
            }

            if [ $# -lt 1 ]; then
                help
            fi

            bin_path=$1
            ihex_path=${bin_path}.ihex

            # STM32 offset 0x08000000
            offset_addr=0x00000000

            srec_cat.exe ${bin_path} -binary -offset ${offset_addr} -o ${ihex_path} -intel
            ```


+ Link GCC lib (*.a) in Keil-MDK
    > `Options for target` -> `Linker` -> `Misc controls`

    ```
    path of *.a
    ```

+ GCC with keil
    > `File Extension, Books and environment...` -> `Folder/Extensions` -> `Use GCC Compiler (GNU) for ARM project`

    ```
    prefix: arm-none-eabi-
    Folder: C:\gcc-arm-none-eabi-10-2020-q4-major\
    ```

    - Modify assembly file of GCC-ASM

        ```
        .syntax unified
        .cpu cortex-m0

        .eabi_attribute Tag_ABI_align_preserved, 1  <--- add for Keil IDE

        .thumb
        ```


