GCC
---

# C99

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

# __attribute__

+ constructor/destructor
    - 在執行 main()前, 先 call 有 __attribute__((constructor))修飾的 function
    - 在結束 main()後, 再 call 有 __attribute__((destructor))修飾的 function

    ```c
    static  __attribute__((constructor)) void before()
    {
        printf("before...\n");
    }

    static  __attribute__((destructor)) void after()
    {
        printf("after...\n");
    }
    ```

    - constructor(PRIORITY)/destructor(PRIORITY)
        > In constructor, PRIORITY小的先執行. In destructor, PRIORITY大的先執行
        >> constructor 和 destructor 的 PRIORITY順序相反


+ replace function

    - `__attribute__ (alias)`

        ```c
        /* 所有調用到 malloc() 的地方都將調用 my_malloc(), 即使是 gcc 內建的 malloc() 也不再可用 */

        void *malloc(size_t) __attribute__((alias("my_malloc")));
        void *my_malloc(size_t size)
        {
            printf("Try to malloc %ld bytes\n", size);
            return __libc_malloc(size);
        }
        ```

    - `-Wl,--wrap=[symbol]`

        ```makefile
        # linker 會將 malloc() 替換為 __wrap_malloc()
        LDFLAGS += -Wl,--wrap=malloc
        ```

        ```c
        extern void *__real_malloc(size_t size); // 真正的 funciton
        void *__wrap_malloc(size_t size)
        {
            fprintf(stdout, "===> malloc %d\n", size);
            return __real_malloc(size);
        }

        int main(void)
        {
            char    *pbuf = 0;
            pbuf = malloc(10);
            if( pbuf )  free(pbuf);
            return 0;
        }
        ```
