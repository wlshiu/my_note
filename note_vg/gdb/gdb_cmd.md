GDB_CMD
---

[GDB Command Reference](https://visualgdb.com/gdbreference/commands/)

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

+ `printf`
    > 格式化輸出

    ```
    (gdb) print "%d,%d\n",x,y
    5,2
    ```

+ list (l)
    > 印出程式碼.若在編譯時沒有加上 -g 參數，list 指令將無作用.

+ disassemble (disas)
    > 看 assembly code

    - `disassemble <Function> [,+<Length>]`
        > 從 function 秀 Length bytes 的 assembly code

        ```
        (gdb) disassemble main,+30
        ```

    - `disassemble <Address> [,+<Length>]`
        > 從 address 秀  Length bytes 的 assembly code

        ```
        (gdb) disassemble $pc,+50
        ```

    - `disassemble <Start>,<End>`
        > 秀出在 start address 到 end addresse 間的 assembly code

    - disassemble /m [...]
        > 混合秀 source code 和 disassembled instructions.

    - disassemble /r [...]
        > 秀 raw byte values of all disassembled instructions.


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
        > 需要加 `*`

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
+ H/w break pointer
    > 如果遇到`b start_kernel`停不下來, 可以使用硬體斷點

    ```
    (gdb) hb start_kernel  // 設定硬體斷點
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

+ nexti (ni)
    > 單步執行下一個 assembly code

+ stepi (si)
    > 單步執行 assembly code, 但遇到可跳轉赴程式時, 則跳轉過去

+ until
    > 直接跑完一個 while 迴圈.

+ return
    > 中止執行該 frame(視同該 frame 已執行完畢)，並返回上個 frame 的呼叫點.功用類似 C 裡的 return 指令.

+ finish
    > 直接退出當前函數(執行完這個 frame).
    當進入一個過深的 frame 時，如:C 函式庫，可能必須下達多個 finish 才能回到原來的進入點.

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

+ info (i)
    > 顯示一些特定的資訊.如: info break，顯示中斷點，
    > - `info share`
    >> 顯示共享函式庫資訊.

    - 列出所有的 symbols

        ```
        (gdb) info functions
            or
        (gdb) info functions Task   # 列出含有 'Task' 的 symbol name
        ```

    - print GPRs (General Purpose Registers)

        ```
        (gdb) info register
            or
        (gdb) i r
        ```

        1. print the structure of specific system register

            ```
            (gdb) info register $ir3
            ```
    - `info frame`

        ```
        (gdb) info frame
            Stack level 0, frame at 0xbffd0cd0:
             eip = 0x80483ca in show3 (main.c:4); saved eip 0x80483ef
             called by frame at 0xbffd0ce0
             source language c.
             Arglist at 0xbffd0cc8, args:
             Locals at 0xbffd0cc8, Previous frame's sp is 0xbffd0cd0
             Saved registers:
              ebp at 0xbffd0cc8, eip at 0xbffd0ccc
        ```

        1. 解讀info frame命令產生的信息

            > `Stack level 0, frame at 0xbffd0cd0`
            >> 當前棧的起始地址 0xbffd0cd0

            > `eip = 0x80483ca in show3 (main.c:4); saved eip 0x80483ef`
            >> + `0x80483ca` 表示當前的 eip 寄存器的值(main.c:4)
            >> + `0x80483ef` 表示調用本函數(當前調用函數為 show3)的指令的地址,
            即`0x80483ef`應該表示的是源程序第 10 行翻譯成彙編後的地址

            > `called by frame at 0xbffd0ce0`
            >> 這個表示上一個棧幀的地址, 因為當前函數是 show3, 所以這個地址表示 show2 的棧的地址, 可以用命令查看一下 show2 的棧地址

            > `source language c`
            >> 源程序是c語言

            > `Arglist at 0xbffd0cc8, args:`
            >> 存放函數參數的地址從`0xbffd0cc8`開始

            > `Locals at 0xbffd0cc8, Previous frame's sp is 0xbffd0cd0`
            >> 存放函數局部變量的地址從`0xbffd0cd8`開始


            > `Saved registers:`
              `ebp at 0xbffd0cc8, eip at 0xbffd0ccc`
            >> 調用函數的過程中, 壓棧時保存的相關寄存器的值

    - `info stack`
        > like backtrace

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

+ delete (d)
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

    - 設定 input arguments of a program

        ```
        (gdb) set args -type f
        ```

    - 修改 memory value

        ```
        (gdb) set {int}0x8048667=32
        ```

    - 修改當前的 program counter, 可以在 call xxx 時使用.

        ```
        (gdb) set $pc=0x0804852b
        ```

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

    - 用 nm 查詢 function 在哪一個 shared object 裡

        ```
        nm -C -A *.so | grep xxx_function
        ```

+ quit
    > 離開 gdb.或是按下 <Ctrl + C> 也行.

+ `Enter`
    > 直接執行上個指令

+ watch
    > 觀察到變量變化時,停止程序
    >> watchpoint 和 breakpoint 類似,但是斷點是 **program 執行前**設置,觀察點是**program 執行中**設置,只能是變量

+ rwatch
    > 觀察到變量被讀時,停止程序

+ awatch
    > 觀察到變量被讀或者被寫時,停止程序

+ 直接看到 console 訊息 (stdout)

    - re-direct output

        1. 開啟兩個 telnet session

        ```
        # who
        root    pts/0   00:00   Oct  7 08:49:55  [::ffff:192.168.0.101]:31109
        root    pts/1   00:01   Oct  7 08:53:55  [::ffff:192.168.0.101]:31133
        ```
        1. 在 pts/0 畫面輸入指令，接著便可以在 pts/1 畫面看到與 console 相同的除錯訊息

        ```
        # pts/0  side
        $ tail -f /var/adm/messages > /dev/pts/1 &"
        ```

    - gdbserver

        1. open a telnet session and execute `gdbserver`

        ```
        $ gdbserver localhost:55555 [executable file]
        ```

        1. open the other telnet session

        ```
        $ gdb [executable file]
        gdb) target remote localhost:55555
        Remote debugging using localhost:55555
        ...
        gdb) b main()
        gdb) c
        ```

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

+ show 目前執行的 assembly code

    - auto
        ```
        set disassemble-next-line on
        show disassemble-next-line
        ```

        ```
        (gdb) stepi
        0x000002ce in ResetISR () at startup_gcc.c:245
        245 {
           0x000002cc <ResetISR+0>: 80 b5   push    {r7, lr}
        => 0x000002ce <ResetISR+2>: 82 b0   sub sp, #8
           0x000002d0 <ResetISR+4>: 00 af   add r7, sp, #0
        (gdb) stepi
        0x000002d0  245 {
           0x000002cc <ResetISR+0>: 80 b5   push    {r7, lr}
           0x000002ce <ResetISR+2>: 82 b0   sub sp, #8
        => 0x000002d0 <ResetISR+4>: 00 af   add r7, sp, #0
        ```

    - view the next n instructions
        > `x/ni $pc`

        ```
        (gdb) x/3i $pc
        0x401175 <main+37>:     call   0x4103f0 <__main>
        0x40117a <main+42>:     lea    0xffffffe8(%ebp),%eax
        0x40117d <main+45>:     mov    %eax,(%esp)
        (gdb)
        ```

        ```
        # auto display
        (gdb) display /3i $pc
        0x401175 <main+37>:     call   0x4103f0 <__main>
        0x40117a <main+42>:     lea    0xffffffe8(%ebp),%eax
        0x40117d <main+45>:     mov    %eax,(%esp)
        (gdb)
        ```

+ disassembly code maps to source code

    ```
    $ objdump -D test.o # check disassembly code ln.65 in main()
    $ gdb test.o
    gdb) list *(main+65)
    0x79 is in main(test.c:27)

    ```

+ 修改 source path
    > `directory` [dir]

    ```shell
    (gdb) list
    6   ./Programs/python.c: No such file or directory.
    (gdb) directory /usr/src/python
    Source directories searched: /usr/src/python:$cdir:$cwd
    ```

+ 改變部分 source path prefix
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

+ 重跑 progtam

    - `jump`

        ```
        (gdb) jump _start
        ```

    - `set remote exec-file`
        > 使用 `target extended-remote` 取代 `target remote`

        ```bash
        $　gdb -ex "target extended-remote 192.168.0.1:1234" \
            -ex "set remote exec-file ./myexec" \
            --args ./myexec arg1 arg2
        (gdb) r
        [Inferior 1 (process 1234) exited normally]
        ```


+ 友善的 print structure

    ```
    (gdb) set print pretty on
    (gdb) p *my_struct_pointer
        $3 = {
          path = {
            mnt = 0xffff8800070ce1a0,
            dentry = 0xffff880006850600
          },
          last = {
            {
              {
                hash = 3537271320,
                len = 2
              },
              hash_len = 12127205912
            },
            name = 0xffff88000659501c "../b.out"
          },
        }
    ```

# gdb tui

GDB Terminal User Interface

+ enter GDB TUI mode
    - start gdb wiht option `--tui`
    - enter gdb and enable/disabe tui mode
        > press `Ctrl+x, a` or `Ctrl+x, Ctrl+a`

+ cursor moving in GDB console
    - `Ctrl+p` : 上一命令行
    - `Ctrl+n` : 下一命令行
    - `Ctrl+b` : 命令行光標前移
    - `Ctrl+f` : 命令行光標後移

+ reflash layout
    > `Ctrl+L`

+ window layout
    > GDB console alwsys exist

    - only one window
        > `Ctrl+1`

    - two windows layout
        > `Ctrl+2`
        >> 使TUI顯示兩個窗口,連接使用此快捷鍵可在三種窗口組合(source/disassembly/register window只能同時顯示兩個,共3種組合)中不斷切換

+ Single Key mode
    > `Ctrl+x, s`
    >> 不需要 press enter, 即可執行快捷鍵, e.g. c(continue), r(run), v(infolocal), ...etc.

    - `c` : continue
    - `u` : up
    - `d` : down
    - `f` : finish
    - `n` : next
    - `o` : nexti. The shortcut letter 'o' stands for "step Over".
    - `q` : 退出單鍵模式
    - `r` : run
    - `s` : step
    - `i` : stepi. The shortcut letter 'i' stands for "step Into".
    - `v` : info locals
    - `w` : where
    + switch active window
        > `Ctrl+x, o`

+ active window moving in TUI mode
    > 只在 TUI mode 有效

    - `PgUp` : 激活窗口的內容向上滾動一頁
        > Scroll the active window one page up. 
    - `PgDn` : 激活窗口的內容向下滾動一頁
        > Scroll the active window one page down. 
    - `Up` : 激活窗口的內容向上滾動一行
        > Scroll the active window one line up. 
    - `Down` : 激動窗口的內容向下滾動一行
        > Scroll the active window one line down. 
    - `Left` : 激活窗口的內容向左移動一列
        > Scroll the active window one column left. 
    - `Right` : 激活窗口的內容向右移動一列
        > Scroll the active window one column right. 
    - `C-L` : 更新屏幕
        > Refresh the screen. 

+ TUI-specific Commands
    > 當處理GDB console mode時,下列的大多數命令會自動切換到 TUI mode

    - info win：顯示正在顯示的窗口大小信息
        > Listand give the size of all displayed windows. 
    - layout next：顯示下一個窗口
        > Displaythe next layout. 
    - layout prev：顯示上一個窗口
        > Displaythe previous layout. 
    - layout src：顯示源代碼窗口
        > Displaythe source window only. 
    - layout asm：顯示彙編窗口
        > Displaythe assembly window only. 
    - layout split：顯示源代碼和彙編窗口
        > Displaythe source and assembly window. 
    - layout regs：顯示寄存器窗口
        > Displaythe register window together with the source or assembly window. 
    - focus next：將一個窗口置為激活狀態
        > Make the next window active for scrolling. 
    - focus prev：將上一個窗口置為激活狀態
        > Make the previous window active for scrolling. 
    - focus src：將源代碼窗口置為激活狀態
        > Make the source window active for scrolling. 
    - focus asm：將彙編窗口置為激活狀態
        > Make the assembly window active for scrolling. 
    - focus regs：將寄存器窗口置為激活狀態
        > Make the register window active for scrolling. 
    - focus cmd：將命令行窗口置為激活狀態
        > Make the command window active for scrolling. 
    - refresh：更新窗口，與C-L快捷鍵同
        > Refresh the screen. This is similar to typing C-L.
    - tuireg float：寄存器窗口顯示內容為浮點寄存器
        > Showthe floating point registers in the register window. 
    - tuireg general：寄存器窗口顯示內容為普通寄存器
        > Show the general registers in the register window. 
    - tuireg next：顯示下一組寄存器
        > Show the next register group. 
        The list of register groups as well astheir order is target specific. 
        The predefined register groups are the following:
        **general**, **float,system**, **vector**, **all**, **save**, **restore**. 

    - tuireg system ：顯示上一組寄存器
        > Show the system registers in the register window. 
    - update ：更新源代碼窗口到當前運行點
        > Update the source window and the current execution point. 
    - winheight winname `+count`：增加指定窗口的高度
    - winheight winname `-count`：減小指定窗口的高度
        > Changethe height of the window name by count lines.Positive counts increase the height, while negative counts decreaseit. 
    - tabset nchars
        > Set the width of tab stops to be nchars characters. 

# cgdb (need to install)

[CGDB中文手冊](https://leeyiw.gitbooks.io/cgdb-manual-in-chinese/content/index.html)

+ MSYS2 build

    - `makeinfo` not found

    ```shell
    $ pacman -S texinfo
    ```

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


# Vim plugin

+ [NeoDebug](https://github.com/cpiger/NeoDebug)
    > vim 8.0 or laster

    - start debug (in VIM editor)

    ```vim
    :NeoDebug
    ```

    - commands

    ```vim
    :NeoDebug         "start gdb and open a gdb console buffer in vim

    :DBGOpenConsole       "open neodebug console window
    :DBGCloseConsole      "close neodebug console window
    :DBGToggleConsole     "toggle neodebug console window

    :DBGOpenLocals        "open  [info locals] window
    :DBGOpenRegisters     "open  [info registers] window
    :DBGOpenStacks        "open  [backtrace] window
    :DBGOpenThreads       "open  [info threads] window
    :DBGOpenBreaks        "open  [info breakpoints] window
    :DBGOpenDisas         "open  [disassemble] window
    :DBGOpenExpressions   "open  [Exressions] window
    :DBGOpenWatchs        "open  [info watchpoints] window
    ```

    - hot key

    ```
    <F5>    - run or continue
    <S-F5>  - stop debugging (kill)
    <F6>    - toggle console window
    <F10>   - next
    <F11>   - step into
    <S-F11> - step out (finish)
    <C-F10> - run to cursor (tb and c)
    <F9>    - toggle breakpoint on current line
    <C-S-F10> - set next statement (tb and jump)
    <C-P>   - view variable under the cursor
    <TAB>   - trigger complete
    ```

    ```vim
    ; keymaps
    let g:neodbg_keymap_toggle_breakpoint  = '<F9>'         " toggle breakpoint on current line
    let g:neodbg_keymap_next               = '<F10>'        " next
    let g:neodbg_keymap_run_to_cursor      = '<C-F10>'      " run to cursor (tb and c)
    let g:neodbg_keymap_jump               = '<C-S-F10>'    " set next statement (tb and jump)
    let g:neodbg_keymap_step_into          = '<F11>'        " step into
    let g:neodbg_keymap_step_out           = '<S-F11>'      " setp out
    let g:neodbg_keymap_continue           = '<F5>'         " run or continue
    let g:neodbg_keymap_print_variable     = '<C-P>'        " view variable under the cursor
    let g:neodbg_keymap_stop_debugging     = '<S-F5>'       " stop debugging (kill)
    let g:neodbg_keymap_toggle_console_win = '<F6>'         " toggle console window
    let g:neodbg_keymap_terminate_debugger = '<C-C>'        " terminate debugger
    ```

# build GDB and GDB server

+ dependency

    ```
    $ sudo apt install texinfo
    ```

