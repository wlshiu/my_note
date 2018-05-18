keil c
---

# syntax

+ accessing assembly variables from c

    ```
    # in *.s
                    ALIGN   4
                    EXPORT  sys_heap_base ; declare at C program
                    EXPORT  Heap_Size
    sys_heap_base   DCD    Heap_Size


    # in *.c
    extern uint32_t     sys_heap_base;
    printf("0x%08x\n", sys_heap_base);
    ```

    ```
    # in *.s
            ALIGN   4
            EXPORT  foo
    foo     DCD     __initial_sp
            DCD     Stack_Size

    # in *.c
    extern uint32_t foo[2];
    printf("%08x %d\n", foo[0], foo[1]);
    ```

# Tips
+ [command window](http://www.keil.com/support/man/docs/uv4/uv4_db_dbg_outputwin.htm)
    - [SAVE] (http://www.keil.com/support/man/docs/uv4/uv4_cm_save.htm)
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
