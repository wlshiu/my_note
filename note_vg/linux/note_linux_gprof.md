GCC toolchain
---

# gprof

gprof 可以為 Linux 平台上 `user space` 且 CPU 密集型的程序, 精確分析性能瓶頸.
同時精確地給出函數被調用的時間和次數, 給出函數調用關係

+ 原理

> 通過在編譯和鏈接程序的時候(CFLAG 及 LDFLAG 加入'-pg'),
gcc 在你應用程序的**每個函數中**,
都加入了一個名為 `mcount()` or  `_mcount()` or  `__mcount()` (依賴於編譯器或操作系統)的函數,
也就是說你的應用程序裡的每一個函數都會調用 mcount(), 而 mcount() 會在內存中保存一張函數調用表,
並通過函數調用堆棧的形式查找子函數和父函數的地址.
這張調用表也保存了所有與函數相關的調用時間, 調用次數等等的所有信息.

    - 執行時間
        > 在分時作業系統中, 用函式開始時間和結束時間的差作為執行時間不準確, 因為這段時間內該函式並不獨佔 CPU.
        為了解決這個問題, prof 和 gprof 都採用了取樣的方法,
        即每隔一段時間就對程式計數器(PC)進行取樣,
        根據多少個取樣點落入該函式的 PC 範圍來估算實際執行時間

    - 呼叫關係
        > 函式呼叫關係包括**動態呼叫關係**和**靜態呼叫關係**,
        前者是執行時決定, 後者是由原始碼決定的.
        gprof 主要使用動態呼叫關係, 輔以靜態關係.
        在取得了動態函式呼叫關係圖之後, 在分析函式執行時間時,
        將子函式的執行時間加入到父函式中.

+ share object

若要查看庫函數的 profiling,
> + share object 需要開啟 `-pg` 並重新編譯
> + 在編譯是再加入`-lc_p` 編譯參數代替 `-lc` 編譯參數,
這樣程序會鏈接 libc_p.a 庫, 才可以產生庫函數的 profiling 信息

+ 使用流程
    - 在編譯和鏈接時, 加上 `-pg` 選項
        > 一般我們可以加在 makefile 中

    - 執行編譯的 executable program
    - 在程序運行目錄下, 生成 `gmon.out` 文件
        > 如果原來有 `gmon.out` 文件, 將會被覆寫。
    - 結束進程
        > 這時 `gmon.out` 會再次被刷新

    - 用 gprof 工具分析 `gmon.out` 文件

+ example

    ```
    $ vi ./hello.c
        #include "stdio.h"
        #include "stdlib.h"
        void a()
        {
          printf("\t\t+---call a() function\n");
        }
        void c()
        {
          printf("\t\t+---call c() function\n");
        }
        int b()
        {
          printf("\t+--- call b() function\n");
          a();
          c();
          return 0;
        }

        int main()
        {
          printf(" main() function()\n");
          b();
        }

    $ gcc -pg hello.c
    $ a.out     # generate gmon.out
        main() function()
            +--- call b() function
                +---call a() function
                +---call c() function
    $ gprof -b a.out gmon.out
        Flat profile:

        Each sample counts as 0.01 seconds.
         no time accumulated

          %   cumulative   self              self     total
         time   seconds   seconds    calls  Ts/call  Ts/call  name
          0.00      0.00     0.00        1     0.00     0.00  a
          0.00      0.00     0.00        1     0.00     0.00  b
          0.00      0.00     0.00        1     0.00     0.00  c

                                Call graph


        granularity: each sample hit covers 2 byte(s) no time propagated

        index % time    self  children    called     name
                        0.00    0.00       1/1           b [2]
        [1]      0.0    0.00    0.00       1         a [1]
        -----------------------------------------------
                        0.00    0.00       1/1           main [9]
        [2]      0.0    0.00    0.00       1         b [2]
                        0.00    0.00       1/1           a [1]
                        0.00    0.00       1/1           c [3]
        -----------------------------------------------
                        0.00    0.00       1/1           b [2]
        [3]      0.0    0.00    0.00       1         c [3]
        -----------------------------------------------

        Index by function name

           [1] a                       [2] b                       [3] c
    ```

    - `$ gprof -b a.out gmon.out -p`
        > 得到每個函式佔用的執行時間

    - `$ gprof -b a.out gmon.out -q`
        > 得到 call graph, 包含了每個函式的呼叫關係, 呼叫次數, 執行時間等資訊

    - `$ gprof -b a.out gmon.out -A`
        > 得到一個帶註釋的'原始碼清單', 它會註釋原始碼, 指出每個函式的執行次數.
        這需要在編譯的時候增加 `-g` 選項.


+ 報告說明

    - Gprof 產生的信息
        1. `%time`
            > 該函數消耗時間佔程序所有時間百分比
        1. `Cumulative seconds`
            > 程序的累積執行時間 (只包括 gprof 能夠監控到的函數)
            >> 工作在 `kernel space` 和 `沒有加-pg編譯的第三方庫函數`,
            是無法被 gprof 監控到的, e.g. sleep(), 等
        1. `Self Seconds`
            > 該函數本身執行時間 (所有被調用次數的時間總和)
        1. `Calls`
            > 函數被調用次數
        1. `Self TS/call`
            > 函數平均執行時間 (不包括被調用時間, 函數的單次執行時間)
        1. `Total TS/call`
            > 函數平均執行時間 (包括被調用時間, 函數的單次執行時間)
        1. `name`
            > 函數名


    - Call Graph 的字段含義
        1. `Index`
            > 索引值
        1. `%time`
            > 函數消耗時間佔所有時間百分比
        1. `Self`
            > 函數本身執行時間
        1. `Children`
            > 執行子函數所用時間
        1. `Called`
            > 被調用次數
        1. `Name`
            > 函數名

+ 限制

    - 只能分析應用程序(user space), 在運行過程中所消耗掉的用戶時間.
    對於 kernel space 的程序, 或外部因素(例如操作系統的 I/O 子系統過載)而運行得非常慢的程序,
    是無法偵測到.

    - 函式執行時間是估計值
        > 函式執行時間是通過取樣估算的.
        這個不是什麼大的問題, 一般估算值與實際值相差不大,
        何況任何測量都不可能 100% 準確

        1. gprof 假設一個函式的每次執行時間是相同的, 這個假設在實際中可能並不成立.
        例如, 如果函式B執行100次, 總執行時間時間10毫秒, 被A呼叫20次, 被C呼叫80次,
        那麼B的10毫秒中有2毫秒加入到A的執行時間, 8毫秒加入到C的執行時間中.
        實際上, 很可能B被A呼叫時的每次執行時間和被C呼叫時的每次執行時間相差很大,
        所以以上分攤並不準確, 但 gprof 無法做出區分.

    - 不適合存在大量遞迴呼叫的程式
        > 如果存在遞迴呼叫時, 函式動態呼叫關係圖中將存在有向環,
        這樣明顯不能將子函式的執行時間加到其父函式中, 否則環將導致這個累加過程無限迴圈下去.
        gprof 對此的解決辦法是用強連通分量(strongly-connected components),
        將這些遞迴呼叫的函式在呼叫關係圖中坍縮成一個節點來處理,
        但在顯示最終結果時仍然分別顯示各個函式的執行時間.
        缺點是, 對於這些遞迴呼叫的函式, 其執行時間不包括其子函式的執行時間, 如 prof一樣.
        所以當程式中存在大量遞迴呼叫時, gprof 退化為老的 prof 工具

    - gprof 不支持 multi-thread, 多線程下只能採集主線程性能數據.
        > `gprof` 採用 ITIMER_PROF 信號, 在多線程內只有主線程才能響應該信號.
        因此只要能讓各個線程都響應 ITIMER_PROF 信號, 就可以實現支援.

        > 重寫 pthread_create()

        ```c
        #define _GNU_SOURCE
        #include <sys/time.h>
        #include <stdio.h>
        #include <stdlib.h>
        #include <dlfcn.h>
        #include <pthread.h>

        static void *wrapper_routine(void *);

        /* Original pthread function */
        static int (*pthread_create_orig)(pthread_t *__restrict,
                                          __const pthread_attr_t *__restrict,
                                          void *(*)(void *),
                                          void *__restrict) = NULL;

        /* Library initialization function */
        void wooinit(void) __attribute__((constructor));

        void wooinit(void)
        {
            pthread_create_orig = dlsym(RTLD_NEXT, "pthread_create");
            fprintf(stderr, "pthreads: using profiling hooks for gprof/n");
            if(pthread_create_orig == NULL)
            {
                char *error = dlerror();
                if(error == NULL)
                {
                    error = "pthread_create is NULL";
                }
                fprintf(stderr, "%s/n", error);
                exit(EXIT_FAILURE);
            }
        }

        /* Our data structure passed to the wrapper */
        typedef struct wrapper_s
        {
            void *(*start_routine)(void *);
            void *arg;
            pthread_mutex_t lock;
            pthread_cond_t  wait;
            struct itimerval itimer;
        } wrapper_t;

        /* The wrapper function in charge for setting the itimer value */
        static void *wrapper_routine(void *data)
        {
            /* Put user data in thread-local variables */
            void *(*start_routine)(void *) = ((wrapper_t *)data)->start_routine;
            void *arg = ((wrapper_t *)data)->arg;

            /* Set the profile timer value */
            setitimer(ITIMER_PROF, &((wrapper_t *)data)->itimer, NULL);

            /* Tell the calling thread that we don't need its data anymore */
            pthread_mutex_lock(&((wrapper_t *)data)->lock);
            pthread_cond_signal(&((wrapper_t *)data)->wait);
            pthread_mutex_unlock(&((wrapper_t *)data)->lock);

            /* Call the real function */
            return start_routine(arg);
        }

        /* Our wrapper function for the real pthread_create() */
        int pthread_create(pthread_t *__restrict thread,
                           __const pthread_attr_t *__restrict attr,
                           void *(*start_routine)(void *),
                           void *__restrict arg)
        {
            wrapper_t wrapper_data;
            int i_return;

            /* Initialize the wrapper structure */
            wrapper_data.start_routine = start_routine;
            wrapper_data.arg = arg;
            getitimer(ITIMER_PROF, &wrapper_data.itimer);
            pthread_cond_init(&wrapper_data.wait, NULL);
            pthread_mutex_init(&wrapper_data.lock, NULL);
            pthread_mutex_lock(&wrapper_data.lock);

            /* The real pthread_create call */
            i_return = pthread_create_orig(thread,
                                           attr,
                                           &wrapper_routine,
                                           &wrapper_data);

            /* If the thread was successfully spawned, wait for the data
             * to be released */
            if(i_return == 0)
            {
                pthread_cond_wait(&wrapper_data.wait, &wrapper_data.lock);
            }

            pthread_mutex_unlock(&wrapper_data.lock);
            pthread_mutex_destroy(&wrapper_data.lock);
            pthread_cond_destroy(&wrapper_data.wait);

            return i_return;
        }
        ```

+ other tool

    - `oprofiled`
        > 可使用在 kernel space

        > 它使用硬體除錯暫存器來統計資訊, 進行 profiling 的開銷比較小, 而且可以對核心進行 profiling.
        它統計的資訊非常的多, 可以得到 cache 的缺失率, memory的訪存資訊, 分支預測錯誤率等等,
        這些資訊 gprof 是得不到的, 但是對於函式呼叫次數, 它是不能夠得到的.

    - `sysprof`
    - `perf`
        > kernel 自帶工具

    - `Kprof`


# gcov

GCC Coverage 測試程式碼覆蓋率的工具, 統計每一行程式碼的執行頻率
ps. 必須執行到 `exit()` 才能產生統計結果

+ concept
    > source code at `gcc/libgcc/libgcov-driver.c`

    - `-ftest-coverage` 編譯選項
        > + 輸出目標檔案中留出一段儲存區, 用於儲存統計資料
        > + 在 source code 中, 每一行可執行的程式碼之後,
        加入一段更新覆蓋率統計結果的程式碼

    - 進入 `main()` 之前呼叫 `gcov_init()` 初始化統計資料區,
    並將 `gcov_exit()` 註冊為 exit handlers

    - 當呼叫 `exit()` 時, 將呼叫 `gcov_exit()`,
    其繼續呼叫`__gcov_flush()` 輸出統計資料到 `*.gcda`檔案中
        > 從 gcov 實現原理可知, 若使用者程序並未呼叫 exit() 退出,
        就得不到覆蓋率統計資料, 也就無從生成報告了.
        而後臺服務程式一旦啟動很少主動退出, 為了解決這個問題,
        我們可以給待測程式註冊一個 signal handler,
        處理 SIGINT/SIGQUIT/SIGTERM 等常見強制退出訊號,
        並在 signal handler 中主動呼叫 `exit()` 或 `__gcov_flush()`,
        以便輸出統計結果

+ compiling options for GCC

    - `-fprofile-arcs`
        > 用來在**執行應用程序**時, 生成 `*.gcda`

    - `-ftest-coverage`
        > 用以生成 `*.gcno`

    - 如有子目錄, 則每個目錄下的 source files 都需要生成 `*.gcov`

+ example

    ```shell
    $ vi hello.c
        #include<stdio.h>
        int main(int argc,char* argv[])
        {
            if(argc>1)
               printf("AAAA\n");
            else
               printf("BBB\n");
            return 0;
        }

    $ gcc -fprofile-arcs -ftest-coverage hello.c -o hello # 生成 'hello.gcno'
    $ ./hello # 生成 'hello.gcda'
    $ gcov hello.c # 依照 hello.gcno 和hello.gcda, 生成 hello.c.gcov
    $ cat hello.c.gcov
            -:    0:Source:hello.c
            -:    0:Graph:hello.gcno
            -:    0:Data:hello.gcda
            -:    0:Runs:1
            -:    0:Programs:1
            -:    1:#include<stdio.h>
            -:    2:
            1:    3:int main(int argc,char* argv[])
            -:    4:{
            1:    5:    if(argc>1)
        #####:    6:       printf("AAAA\n");
            -:    7:    else
            1:    8:       printf("BBB\n");
            1:    9:    return 0;
            -:   10:}
    ```

+ [LCOV](http://ltp.sourceforge.net/coverage/lcov.php)
    > 生成圖形化的覆蓋率數據展示

    - source code

        ```
        $ git clone https://github.com/linux-test-project/lcov.git
        ```

    - install

        ```shell
        # ubuntu 18.04
        $ sudo apt install lcov
        ```

    - convert

        ```
        # 轉換 hello.c.gcov 成 hello_test.info
        $ lcov -d . -t 'Hello test' -o 'hello_test.info' -b . -c

        # 生成了result文件夾, 可用 browser 觀看
        $ genhtml -o result hello_test.info
        ```

# reference

+ [Using GNU Profiling (gprof) With ARM Cortex-M](https://dzone.com/articles/using-gnu-profiling-gprof-with-arm-cortex-m)

