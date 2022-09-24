# trace C/C++ function call
---

+ 了解特定模組或類別的使用方式.
+ 找出執行時間過長的函式

## 使用 gcc 參數 `-finstrument-functions`

實作兩個 function, 就可以自己 DIY profiling tools.
> + `void __attribute__((__no_instrument_function__)) __cyg_profile_func_enter(void *this_func, void *call_site);`
> + `void __attribute__((__no_instrument_function__)) __cyg_profile_func_exit(void *this_func, void *call_site);`

> 優點:
> + 自動含蓋所有函式

> 缺點
> + 可能增加太多執行負擔, 雖然可以配合 `-finstrument-functions-exclude-file-list` 去除不想觀察的 function, 對於大專案來說有些不方便

+ **Jserv's** 提供簡單的 sample code
    > 若把計算 tick 的功能加入, 如此就可以知道每個 function 所使用的 tick 數.

    ```c
    #include <sys/time.h>
    #include <stdio.h>

    #define DUMP(func, call)            printf("%s: func = %p, called by = %p\n", __FUNCTION__, func, call)

    #define DUMP2(func, call, tick)     printf("%s: func = %p, called by = %p %f\n", __FUNCTION__, func, call,tick)

    struct perf
    {
        unsigned long tick ;
        long fun_addr ;
    };

    static struct perf      perf_entry;

    void __attribute__((__no_instrument_function__))
    __cyg_profile_func_enter (void *this_fn, void *call_site)
    {
        int i,flag = 0 ;
        struct timeval tv;
        gettimeofday(&tv, NULL);
            DUMP(this_fn, call_site);
        perf_entry.tick = (tv.tv_sec * 1000 + tv.tv_usec / 1000);
        perf_entry.fun_addr = (long)this_fn;
        return;
    }

    void __attribute__((__no_instrument_function__))
    __cyg_profile_func_exit (void *this_fn, void *call_site)
    {
        int i;
        unsigned long tick;
        struct timeval tv;

        gettimeofday(&tv, NULL);
        tick = (tv.tv_sec * 1000 + tv.tv_usec / 1000) - perf_entry.tick1;

        DUMP2(this_fn, call_site, tick );
        return;
    }

    main()
    {
        puts("Hello World!");
        return 0;
    }
    ```

+ cyg-profile example

    - Example for plain C:

        ```
        $ gcc -finstrument-functions -o test test.c cyg-profile.c
        $ ./test
        Logfile: cyglog.1234
        $ ./cyg-resolve.pl test cyglog.1234
        Loading symbols from test ... OK
        Seen 65 symbols, stored 22 function offsets
        Level correction set to 0
                +  0 0x80486a9 (from 0x804872f)  function3()
                +  1 0x804866d (from 0x80486c8)   function2()
                +  2 0x8048634 (from 0x804868c)    function1()
        done
        ```

        1. As you can see - function3() called function2() which then called function1(). Function main() isn't in the list, 
            because the profiling was not yet enabled at the time it was called.

    - Example for C++:
        ```c
        gcc -c cyg-profile.c
        $ g++ -finstrument-functions -c test.cxx
        $ g++ -o test test.o cyg-profile.o
        $ ./test
        Logfile: cyglog.1234
        $ ./cyg-resolve.pl test cyglog.1234
        Loading symbols from test ... OK
        Seen 78 symbols, stored 25 function offsets
        Level correction set to 1
                +  1 0x400d1c (from 0x400dcb)   _ZN4test9function3Ec()
                +  2 0x400cd4 (from 0x400d48)    _ZN4test9function2Ei()
                +  3 0x400c98 (from 0x400d01)     _ZN4test9function1El()
                +  0 0x400e3e (from 0x2a95ae2c8b)  __tcf_0()
        done
        ```

        1. The usage is similar to the plain C case. Unfortunately you'll only see the mangled function names,
            e.g. `_ZN4test9function3Ec` instead of int test::function3(char c).

+ reference
    - [CygProfiler suite](https://www.logix.cz/michal/devel/CygProfiler/)
    - [trace C/C++ function call 的方法](http://fcamel-life.blogspot.com/2013/07/trace-cc-function-call.html)
    - [Code Gen Options - Using the GNU Compiler Collection (GCC)](http://gcc.gnu.org/onlinedocs/gcc/Code-Gen-Options.html#index-finstrument_002dfunctions-2112)



## 自己寫 logger

使用 C/C++ 或 gcc 提供的語法, 自己寫 logger 沒有想像中的麻煩:

+ GCC definitions
    > + 可用 GCC 的 `__PRETTY_FUNCTION__` (c++) 或標準的 `__func__` 取得函式名稱
    > + 用 `__LINE__` 取得行數
    > + 用 `__FILE__` 取得檔名


    - 定義 macro

        ```c
        #define LOG_IT()    MyFunctionLogger logger(__FILE__, __LINE__, __PRETTY_FUNCTION__)
        ```

    - 用 vim 的全域取代

        ```vim
        :% s/^{/&\r  LOG_IT();\r\r/c
        ```

        這會逐個詢問是否取代下列字串:

        ```
        void foo()
        {
            // blah blah
        ```
        為

        ```
        void foo()
        {
            LOG_IT();
            // blah blah
        ```

        Btw, 由此可知, 函式的左大括號放在行首比放在行尾來得方便.


+ MyFunctionLogger 只是個 wrapper, 目的是利用 [RAII](http://en.wikipedia.org/wiki/Resource_Acquisition_Is_Initialization) 記錄進入和離開函式, 這樣即使函式中間有任何 return, 都不會漏記離開函式

    ```
    class MyFunctionLogger
    {
    public:
        MyFunctionLogger(const char *file, int line, const char *func)
            : m_file(file), m_line(line), m_func(func)
        {
            MyLogger::Instance()->EnterFunctionCall(m_file, m_line, m_func);
        }

        ~MyFunctionLogger()
        {
            MyLogger::Instance()->LeaveFunctionCall(m_file, m_line, m_func);
        }
    private:
        const char *m_file;
        int m_line;
        const char *m_func;
    };
    ```

    - MyLogger 可以做的事很多, 比方說:
        1. 用 file 做為 tag 分類輸出.
        1. 在 EnterFunctionCall() 和 LeaveFunctionCall() 記錄層級, 輸出 function call 時, 視 function call 的深度做對應的縮排.
        1. 在 EnterFunctionCall() 和 LeaveFunctionCall() 記錄目前時間, 可在 LeaveFunctionCall() 時計算執行時間, 協助 profiling.

    - 若 MyLogger 會被多個 thread 使用, 別忘了將 MyLogger 寫成 thread-safe, 不過以觀察或除錯的角度來說, 偷懶不作應該也OK吧.
    - 若目標模組是純 C 的程式, 可用 gcc 的 `cleanup attribute` 做出 [RAII 的效果](https://stackoverflow.com/questions/368385/implementing-raii-in-pure-c), 達到和 MyFunctionLogger 一樣的效果.