C99
---

+ structure alignment

    ```c
    #pragma pack(1)
    typedef struct sSampleStruct
    {
         char Data1;
         int Data2;
         unsigned short Data3;
         char Data4;
    }__attribute__((packed)) sSampleStruct_t;
    #pragma pack()
    ```

+ flexible array member

    ```c
    struct test
    {
        int a;    // It MUST exist a member in this structure.
        char c[]; // flexible array, it MUST put at the last member.
                  // Some compiler support 'char c[0]'
    };
    struct test *p = (struct test*)malloc(sizeof(struct test) + 100*sizeof(char));
    ```

    - It not occupies the size when sizeof().
    - It must be the last member of a structure.

+ function point

    ```c
    int foo(int a, int b)
    { return a + b; }

    int main()
    {
        int (*fp_func)(int, int);
        fp_func = foo;
        fp_func(3, 5);
    }
    ```

+ local declare struct

    ```c
    int foo()
    {
        struct info_ {
            uint32_t    uid;
        } info;

        info.uid = 0x1234;

        return 0;
    }
    ```

+ macro return

    ```c
    #include <stdio.h>

    #define DBG(s, b...)                                                   \
        {                                                                  \
            printf(__FILE__ "@%d, %s(): " s, __LINE__, __FUNCTION__, ##b); \
            fflush(stdout);                                                \
        }

    #define round_down(f)      \
        ({                     \
            int __ret = 0;     \
            __ret = (int)f;    \
            __ret;             \
        })

    int main(int argc, char *argv[])
    {
        DBG("This is a debug message\n");
        printf("round_down(%f) = %d\n", 4.5, round_down(4.5));
        printf("round_down(%f) = %d\n", 9.5, round_down(9.5));
        return 0;
    }
    ```

# Linking symbols to fixed addresses

+ GNU
    - use symbol file
        > `--just-symbols=symbolfile`

        1. format of symbol file
            > The spaces seem to be required, as otherwise 'ld' reports
            'file format not recognized; treating as linker script.'

            ```
            symbolname1 = address;
            symbolname2 = address;
            ...
            ```

    - single symbol link
        > `--defsym symbol=address`

        ```
        -Wl,--defsym=bar=0x00400481 -Wl,--defsym=foo=0x00400476 -Wl,--defsym=main=0x0040048
        ```

        ```
        $ gcc -Wl,--defsym,foobar=0x76543210 file.c

        // in file.c
        extern int foobar;
        ```

        1. pre-generate symbol file

            ```
            $ readelf -sW a.out | grep GLOBAL | awk '{print $8 " " $2 }' | grep -v '^_' > symdef.lst
            $ LDFLAGS=$(cat symdef.lst | awk '{print "-Wl,--defsym=" $1 "=" $2}' | tr '\n' ' ')
            ```

+ Keil
    > `--symdefs=symbolfile`

    - This example shows a typical symdefs file format

        ```
        #<SYMDEFS># ARM Linker, 5050169: Last Updated: Date
        ;value type name, this is an added comment
        0x00008000 A __main
        0x00008004 A __scatterload
        0x000080E0 T main
        0x0000814D T _main_arg
        0x0000814D T __argv_alloc
        0x00008199 T __rt_get_argv
        ...

           # This is also a comment, blank lines are ignored
        ...
        0x0000A4FC D __stdin
        0x0000A540 D __stdout
        0x0000A584 D __stderr
        0xFFFFFFFD N __SIG_IGN
        ```

    - [Creating a symdefs file](http://www.keil.com/support/man/docs/armlink/armlink_pge1362065959198.htm)
    - [Symdefs file format](http://www.keil.com/support/man/docs/armlink/armlink_pge1362065960682.htm)
