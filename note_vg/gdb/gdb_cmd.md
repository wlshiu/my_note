GDB_CMD
---

+ help (h)
    > 顯示指令簡短說明.例:help breakpoint

+ file
    > 開啟執行檔案.等同於 gdb filename

+ run (r)
    > 執行程式，或是從頭再執行程式.

+ kill
    > 中止程式的執行.

+ backtrace (bt)
    > 堆疊追蹤.會顯示出上層所有的 frame 的簡略資訊.

+ print (p)
    > 印出變數內容.例:print i，印出變數 i 的內容.

+ list (l)
    > 印出程式碼.若在編譯時沒有加上 -g 參數，list 指令將無作用.

+ whatis
    > 印出變數的型態.例: whatis i，印出變數 i 的型態.

+ breakpoint (b, bre, break)
    > 設定中斷點
    >> - 使用 `info breakpoint (info b)` 來查看已設定了哪些中斷點.
    >> - 在程式被中斷後，使用 `info line` 來查看正停在哪一行.

    -  `line`
        > breakpoint at 目前檔案的行數

        ```shell
        (gdb) b 11
        ```

    - `filename:line`

        ```shell
        (gdb) b test.c:11
        ```

    - `function name`

        ```shell
        (gdb) b main
        ```

        ```shell
        (gdb) b foo::test
        ```

    -  `filename:function `

        ```shell
        (gdb) b test.c:run
        ```

    + `memory-address`

        ```shell
        (gdb) b *0x08048123
        ```

    - 條件式中斷點, 當 `CONDITION` 滿足時才中斷.
        >　`break [LOCATION] [if CONDITION]`

        ```shell
        (gdb) b main.c:10 if var > 10
        ```

        ```shell
        (gdb) info break
        1   xxxx
        2   yyyy
        (gdb) condition 2 (var > 3) # 設置中斷條件, 條件成立時 2 號中斷
        (gdb) condition 2           #　取消 2 號中斷條件
        ```

+ continue (c, cont)
    > 繼續執行.和 breakpoint 搭配使用.

+ frame (memory stack)
    > 顯示正在執行的行數、副程式名稱、及其所傳送的參數等等 frame 資訊.
    >> - `frame 2`
    >>      > 看到 #2，也就是上上一層的 frame 的資訊.

+ next (n)
    > 單步執行，但遇到 frame 時不會進入 frame 中單步執行.

+ step (s)
    > 單步執行.但遇到 frame 時則會進入 frame 中單步執行.

+ until
    > 直接跑完一個 while 迴圈.

+ return
    > 中止執行該 frame(視同該 frame 已執行完畢)，並返回上個 frame 的呼叫點.功用類似 C 裡的 return 指令.

+ finish
    > 執行完這個 frame.當進入一個過深的 frame 時，如:C 函式庫，可能必須下達多個 finish 才能回到原來的進入點.

+ up
    > 直接回到上一層的 frame，並顯示其 stack 資訊，如進入點及傳入的參數等.

+ up 2
    > 直接回到上三層的 frame，並顯示其 stack 資訊.

+ down
    > 直接跳到下一層的 frame，並顯示其 stack 資訊. 必須使用 up 回到上層的 frame 後，才能用 down 回到該層來.

+ display
    > 在遇到中斷點時，自動顯示某變數的內容.

+ undisplay
    > 取消 display，取消自動顯示某變數功能.

+ commands
    > 在遇到中斷點時要自動執行的指令.

+ info
    > 顯示一些特定的資訊.如: info break，顯示中斷點，
    > - `info share`
    >> 顯示共享函式庫資訊.

+ disable
    > 暫時關閉某個 breakpoint 或 display 之功能.

    ```shell
    (gdb) info break
    1   xxxx
    2   yyyy
    (gdb) disable 2  # default is 'all'
    ```

+ enable
    > 將被 disable 暫時關閉的功能再啟用.

    ```shell
    (gdb) info break
    1   xxxx
    2   yyyy
    (gdb) enable 2
    ```

+ delete
    > 刪除某個 breakpoint.

    ```shell
    (gdb) info break
    1   xxxx
    2   yyyy
    (gdb) delete 2
    ```

+ clear
    > 清除所有中斷

+ set
    > 設定特定參數.如:set env，設定環境變數.也可以拿來修改變數的值.

+ unset
    > 取消特定參數.如:unset env，刪除環境變數.

+ show
    > 顯示特定參數.如:show environment，顯示環境變數.

+ attach PID
    > 載入已執行中的程式以進行除錯.其中的 PID 可由 ps 指令取得.

+ detach PID
    > 釋放已 attach 的程式.

+ shell
    > 執行 Shell 指令.如:shell ls，呼叫 sh 以執行 ls 指令.

+ quit
    > 離開 gdb.或是按下 <Ctrl + C> 也行.

+ `Enter`
    > 直接執行上個指令


# debug tips

+ `.gdbinit`
    > GDB user configuration

    - alias cmd
    ```shell
    define [command]
        # scenario
    end
    document [command]
        # help description
    end
    ```

    ```shell
    # example
    define save-bt
        if $argc != 1
            help save-bt
        else
            set logging file $arg0
            set logging on
            set logging off
        end
    end
    document save-bt
    Usage: save-bt ~/bt.rec
    end
    ```

+ disassembly code maps to source code

    ```
    $ objdump -D test.o # check disassembly code ln.65 in main()
    $ gdb test.o
    gdb) list *(main+65)
    0x79 is in main(test.c:27)

    ```

+ modify source path
    > `directory` [dir]

    ```shell
    (gdb) list
    6   ./Programs/python.c: No such file or directory.
    (gdb) directory /usr/src/python
    Source directories searched: /usr/src/python:$cdir:$cwd
    ```

+ change source path prefix
    > set `substitute-path` [old_path] [new_path]

    ```shell
    (gdb) list
    6   ./Programs/python.c: No such file or directory.
    (gdb) set substitute-path /home/avd/dev/cpython /usr/src/python
    ```

+ add path prefix during compiler
    > gcc option: `-fdebug-prefix-map = old_path = new_path`

    ```shell
    $ make distclean    # start clean
    $ ./configure CFLAGS="-fdebug-prefix-map=$(pwd)=/usr/src/python" --with-pydebug
    $ make -j
    ```

+ save/load breakpoints

    ```shell
    # save
    (gdb) save breakpoints ~/.breakpoints.rec

    # re-load
    (gdb) source ~/.breakpoints.rec
    ```

+ save backtrace log

    ```shell
    (gdb) set logging file gdb_bt.log
    (gdb) set logging on
    Copying output to gdb_bt.log
    (gdb) bt
    #0  0x0000003000eb7472 in __select_nocancel () from /lib/libc.so.6
    ...
    (gdb) set logging off
    Done logging to backtrace.log.
    ```

# cgdb (need to install)

+ bind cross gdb in toolchain
    ```
    $ cgdb -d xxx/arm-linux-gdb PROGRAM
    ```

+ trace share library
    > *so* file need use `CFLAGS="-g -O0"`

    1. shared or sharedlibrary
        > list so libs which included

        ```
        (gdb) info sharedlibrary
        ```

    1. `LD_LIBRARY_PATH`
        > define the search path for *so* files

        ```shell
        $ LD_LIBRARY_PATH=$HOME/my_so_libs:${LD_LIBRARY_PATH} gdb ./a.out
        ```

    1. `LD_PRELOAD`
        > define the soruce code path

    1. pre-set brackpoint for un-loading *so*
        > when gdb run-time load *so*, it will check the brackpoint after loading *so*

        ```
        (gdb) break xxx.cpp:123
        ```

    1. set *so* search path
        > set solib-search-path SO_PATH

        ```
        (gdb) set solib-search-path /home/nfs/arm/lib:/home/nfs/arm/usr/lib
        ```

+ `esc` key
    > move to source code window, it only support *Pure VI* normal mode
    1. move with `j`, `k`, `h`, `l`, `C-f`(forward), `C-b`((backward), `C-d`, `C-u`

    1. search with `/` key
        > jump to searching match `n`, `N`

    1. `space` key
        > toggle brackpoint

    1. `o` key
        > select source file
        >> `q` key to leave file list

+ `i` key
    > move to gdb window, and use gdb cmd to operate

+ `_` (on source window)
    > Shrink source window 25%

+ `+` (on source window)
    > Grow source window 25%

+ set progream args
    ```
    $ cgdb --args [your progream] [args...]
    ```
+ hot key
    1. `F5`
        > gdb run
    1. `F6`
        > gdb continue
    1. `F7`
        > gdb finish (leave sub-function)
    1. `F8`
        > gdb next (next line)
    1. `F10`
        > gdb step (enter sub-function)

+ multi-thread
    1. thread list
        ```
        (gdb) info threads
        ```
    1. switch thread
        ```
        (gdb) thread Id # Id from gdb cmd (info thread)
        ```

    1. brackpoint
        ```
        (gdb) b file:line thread id
        ```
+ backtrace
    1. show stack frame size
        ```
        (gdb) bt 10     # print backtrace stack frame #0 ~ #9
        (gdb) bt -10    # print backtrace stack frame #(latest-9) ~ #(latest)
        ```

+ re-direct tty
    ```
    # an other terminal
    $ tty
    /dev/pts/11

    # in gdb
    (gdb) tty /dev/pts/11
    (gdb) show inferior-tty
    Terminal for future runs of program being debugged is "/dev/pts/11".
    ```

+ attach pid
    ```
    $ gdb -p [PID]
    ```

