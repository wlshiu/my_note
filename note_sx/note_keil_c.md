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

+
