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
    - 在執行 `main()` 前, 先 call 有 ` __attribute__((constructor))` 修飾的 function
    - 在結束 `main()` 後, 再 call 有 `__attribute__((destructor))` 修飾的 function

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

+ aligned

    ```c
    int x   __attribute__ ((aligned (16))) = 0;

    struct foo
    {
        int x[2]    __attribute__ ((aligned (8)));
    };

    struct __attribute__ ((aligned (8)))  S
    {
        short f[3];
    };

    typedef int more_aligned_int  __attribute__ ((aligned (8)));

    typedef struct
    {
         char           Data1;
         int            Data2;
         unsigned short Data3;
         char           Data4;

    } __attribute__((aligned(1))) SampleStruct;
    ```

+ packed
    > alignment 1-byte

    ```c
    struct foo
    {
        char a;
        int x[2] __attribute__ ((packed));
    };
    ```

+ section

    ```
    struct duart bb     __attribute__ ((section ("DUART_B"))) = { 0 };

    char stack[10000]   __attribute__ ((section ("STACK"))) = { 0 };

    int init_data __attribute__ ((section ("INITDATA"))) = 0;
    int init_data()
    {
        ...
        return 0;
    }
    ```

+ `warn_if_not_aligned (alignment)`
    > Issue an warning on `struct foo`, like **warning: alignment 4 of 'struct foo' is less than 8**

    ```c
    typedef unsigned long long __u64   __attribute__((aligned (4), warn_if_not_aligned (8)));

    struct foo
    {
        int     i1;
        int     i2;
        __u64   x;
    };
    ```

+ `vector_size(bytes)`

    ```
    typedef __attribute__ ((vector_size (32)))  int int_vec32_t ;
    typedef __attribute__ ((vector_size (32)))  int *int_vec32_ptr_t;
    typedef __attribute__ ((vector_size (32)))  int int_vec32_arr3_t[3];
    ```

+ Reference
    - [GCC Attributes](https://gcc.gnu.org/onlinedocs/gcc/Common-Type-Attributes.html#index-aligned-type-attribute)

# finstrument-functions

該參數可以使程序在編譯時, 在所有 function 的 enter 和 exit 處生成 instrumentation 調用

```
void  __cyg_profile_func_enter(void *this_fn, void *call_site)
{
    return;
}

void  __cyg_profile_func_exit(void *this_fn, void *call_site)
{
    return;
}

this_fn   (callee): 是當前函數的起始地址 (可在符號表中找到)
call_site (caller): 是調用處地址
```


# Linker

+ force linking symbols (always include symbols)

    - `--whole-archive` and `--no-whole-archive`
        > 在這兩個option之間, 會把靜態庫的symbol提前link進來, 平常只有被call到在會link進去

    ```Makefile
    LDFLAGS = -Wl,--whole-archive -lfoo.a -Wl,--no-whole-archive
    LDFLAGS += -Wl,--whole-archive $(OUT)/foo.o -Wl,--no-whole-archive
    ```

    - `-u [symbol_name]` or `--undefined [symbol_name]`
        > 強制保留該 symbol

    ```
    LDFLAGS += -u foo
    ```



