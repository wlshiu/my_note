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
