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
