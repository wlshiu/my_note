ARM MCU
---

# bootstrap
    > [ref] (http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dai0241b/index.html)
    ```
    startup.s -> Reset_Handler (CMSIS) -> __main() -> __scatterload() -> __rt_entry() -> app main()
    ```

+ startup code (boot code)
    > In embedded applications, an initialization sequence before the user-defined main() function starts.

    - `__main()`
        > the entry point to the C library
        >> Unless you change it, `__main()` is the default entry point
        >> to the ELF image that the ARM linker (armlink) uses when creating the image.

    - `__scatterload()`
        > follow the region table (sct file) to copy the executable data from *load region* to *executable region*
        >> `__main()` always calls this function during startup before calling `__rt_entry()`.

        1. Initializes the Zero Initialized (ZI) regions to zero
        2. Copies or decompresses the non-root code and data region from their load-time locations to the execute-time regions.

    - `__rt_entry()`
        > initialize the stack, heap and other C library sub systems.

        1. `_platform_pre_stackheap_init()` (optional, app need to define the instance by self)
        2. `__user_setup_stackheap()` or setup the Stack Pointer (SP) by another method (optional, app need to define the instance by self)
            > normally, it will be defined by application

            ```
            // the extension direction

                                        |       |
            __initial_sp  0x20010cf8    +-------+
                                        |   |   |
                                        |   v   |
                                        |       |
            __heap_limit  0x200108f8    +-------+
                                        |       |
                                        |   ^   |
                                        |   |   |
            __heap_base  0x200106f8     +-------+
                                        |       |

            ```

        3. `__platform_post_stackheap_init()` (optional, app need to define the instance by self)
        4. `__rt_lib_init()`
            > init necessary functions in C library
        5. `__platform_post_lib_init()` (optional, app need to define the instance by self)
        6. `main()` (Application level)
        7. `exit()`

# linker

+ scartter loader
+ gnu ld
