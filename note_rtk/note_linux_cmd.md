Linux cmd
---

+ printenv
    ```
    會顯示所有現行環境變數
    ```

+ find
    1. `-exec`

        ```
        $ find . -type f -name '*.c' -exec grep 'init' --color -nH {} \;
        ```

        a. `{}` means the output of find cmd
        a. `\;` means the end of `-exec`

+ mkdir
    ```
    -p:     可以是一個路徑名稱。此時若路徑中的某些目錄尚不存在,加上此選項後,系統將自動建立好那些尚不存在的目錄
    ```
+ grep
    1. `-n` means line number
    1. `-H` means show the file path
    1. `-r` means recursively search
    1. `-A5` means show the context of 5 lines *after* the current line.
    1. `-B5` means show the context of 5 lines *before* the current line.

+ wget
    ```
    $ wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.39.tar.bz2
    ```

+ curl
    1. download
        ```
        -o      save as customer name
        -O      save with orginal name

        $ curl -o 1.jpg http://cgi2.tky.3web.ne.jp/~zzh/screen1.JPG
        $ curl -O http://cgi2.tky.3web.ne.jp/~zzh/screen1.JPG

        ## advance use

        $ curl -O http://cgi2.tky.3web.ne.jp/~zzh/screen[1-10].JPG  # 連續檔名下載


        $ curl -o #2_#1.jpg http://cgi2.tky.3web.ne.jp/~{ zzh,nick }/[001-201].JPG

        自定義文件名的下載:
        #1 是變量，指的是{ zzh,nick }這部分，第一次取值zzh，第二次取值nick
        #2 代表的變量，則是第二段可變部分---[001-201]，取值從001逐一加到201
        這樣，自定義出來下載下來的文件名，就變成了這樣：
        原來： ~zzh/001.JPG ---> 下載後： 001-zzh.JPG
        原來： ~nick/001.JPG ---> 下載後： 001-nick.JPG
        ```
    1. username/password
        ```
        curl -u name:passwd ftp://ip:port/path/file
            or
        curl ftp://name:passwd@ip:port/path/file
        ```

+ du

    ```
    -a  顯示目錄中個別檔案的大小
    -b  以bytes為單位顯示
    -c  顯示個別檔案大小與總和
    -D  顯示符號鏈結的來源檔大小
    -h  Human readable
    -H  與-h類似, 但是以1000為k的單位而非1024 bytes為區塊的單位
    -l  重複計算鏈結黨所佔空間
    -L  符號鏈結  指定符號鏈結檔的大小
    -m  以 MB 為顯示單位
    -s  只顯示總和
    -S  顯示目錄內容時, 不包含子目錄大小.
    -x  若目錄中有不同的檔案系統, 不顯示相異的檔案系統
    --exclude  忽略指定的檔案或目錄
    --max-depth  僅搜尋指定的目錄層級

    # show current folder data size
    $ du -sm .
    ```

+ df
    > 查詢硬碟空間
    ```
    $ df -h
    ```

+ dpkg
    > ubuntu 套件管理
    ```
    -l              list all installed packages
    -L [name]       the package installed path
    ```

+ locate
    > 可以很快速的搜尋檔案系統內是否有指定的檔案

    ```
    -i  ：忽略大小寫的差異；
    -c  ：不輸出檔名，僅計算找到的檔案數量
    -l  ：僅輸出幾行的意思，例如輸出五行則是 -l 5
    -S  ：輸出 locate 所使用的資料庫檔案的相關資訊，包括該資料庫紀錄的檔案/目錄數量等
    -r  ：後面可接正規表示法的顯示方式

    # 搜索etc目錄下，所有以m開頭的檔案
    $ locate /etc/m
    ```

+ which
    > 根據 "PATH"這個環境變數所規範的路徑，去搜尋 "執行檔"的檔名

    ```
    $ which ifconfig
    ```
+ whereis
    > 由系統特定的某些目錄中尋找檔案檔名

    ```
    -l    :可以列出 whereis 會去查詢的幾個主要目錄而已
    -b    :只找 binary 格式的檔案
    -m    :只找在說明檔 manual 路徑下的檔案
    -s    :只找 source 來源檔案
    -u    :搜尋不在上述三個項目當中的其他特殊檔案
    ```

+ make
    > automake

    ```
    -f：指定"makefile"文件；
    -i：忽略命令執行返回的出錯信息；
    -s：沉默模式，在執行之前不輸出相應的命令行信息；
    -r：禁止使用build-in規則；
    -n：非執行模式，輸出所有執行命令，但並不執行；
    -t：更新目標文件；
    -q：make操作將根據目標文件是否已經更新返回"0"或非"0"的狀態信息；
    -p：輸出所有宏定義和目標文件描述；
    -d：Debug模式，輸出有關文件和檢測時間的詳細信息。


    # Linux 下選項

    -c dir：在讀取 makefile 之前改變到指定的目錄dir；
    -I dir：當包含其他 makefile文件時，利用該選項指定搜索目錄；
    -h：help文擋，顯示所有的make選項；
    -w：在處理 makefile 之前和之後，都顯示工作目錄。

    ```

+ cgdb (need to install)
    - bind cross gdb in toolchain
        ```
        $ cgdb -d xxx/arm-linux-gdb PROGRAM
        ```

    - trace share library
        > *so* file need use `CFLAGS="-g -O0"`

        1. shared or sharedlibrary
            > list so libs which included

            ```
            (gdb) info sharedlibrary
            ```

        1. `LD_LIBRARY_PATH`
            > define the search path for *so* files

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

    - `esc` key
        > move to source code window, it only support *Pure VI* normal mode
        1. move with `j`, `k`, `h`, `l`, `C-f`(forward), `C-b`((backward), `C-d`, `C-u`

        1. search with `/` key
            > jump to searching match `n`, `N`

        1. `space` key
            > toggle brackpoint

        1. `o` key
            > select source file
            >> `q` key to leave file list

    - `i` key
        > move to gdb window, and use gdb cmd to operate

    - `_` (on source window)
        > Shrink source window 25%

    - `+` (on source window)
        > Grow source window 25%

    - set progream args
        ```
        $ cgdb --args [your progream] [args...]
        ```
    - hot key
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

    - multi-thread
        1. thread list
            ```
            (gdb) info threads
            ```

+ strace
    ```
    $ strace -e TARGET_FUNC_NAME -f PROGRAM

      # get open so info
    $ strace -e open -f PROGRAM | grep '\.so'


      # 看 /proc/PID/maps 可方便看各別 process、thread 載入的函式庫, 也不會拖慢觀察目標的執行程式, 需配合 gdb 停在該停的地方。
    $ cat /proc/PID/maps
    ```

+ diff
    ```
    -a :    將所有檔案都視為文字檔
    -r :    遞歸。設置後diff會將兩個不同版本源代碼目錄中的所有對應文件全部都進行一次比較，包括子目錄文件。
    -N :    選項確保補丁文件將正確地處理已經創建或刪除文件的情況。
    -u :    輸出每個修改前後的3行，也可以用-u5等指定輸出更多上下文。
    --exclude=".svn":       skip directory
    -E, -b, -w, -B, --strip-trailing-cr :   忽略各種空白，可參見文檔，按需選用。


      # In root dir
    $ diff -Nur ./test0 ./test1 > test.patch
    ```


+ patch
    ```
    -p Num: 忽略幾層文件夾。
                以 /usr/src/linux 為例, 若
                    -p0 就是不取消任何路經
                    -p1 則將 / 取消, 得 usr/src/linux
                    -p2 則是將 /usr/ 取消, 得 src/linux
                再以 src/linux 為例:
                    -p0 依然為 src/linux
                    -p1 則為 linux
    -E:     選項說明如果發現了空文件，那麼就刪除它
    -R:     取消打過的補丁。
    --dry-run:      pre-verify

      # In root dir
    $ patch -p0 < test.patch
        or
    $ patch -i test.patch


    if show message:
    can't find file to patch at input line 1
    Perhaps you should have used the -p or --strip option?
    The text leading up to this was:
    --------------------------
    |--- a/CPP/7zip/UI/Agent/Agent.cpp
    |+++ b/CPP/7zip/UI/Agent/Agent.cpp
    --------------------------
    File to patch:

    因為patch 檔是用兩個目錄比較的方式產生的，可以看到原始碼分別放在 a 和 b 兩個目錄下做比較，
    但我們的原始碼並沒有 a 和 b 目錄，所以 patch 就搞不懂狀況了...

    這時要多加一個 -p1 的參數，代表要跳過一層目錄結構，
    如果 patch 檔產生時是在更深層的目錄結構的話，可能就會用到 -p2, -p3, ...

    $ patch -p1 -i test.patch
    ```

+ pushd/popd
    ```
    pushd  [directory] # cd to directory and push directory name to stack

    $ pushd ./tt  # cd 到./tt 並將 ./tt 放到 directory stack裡

    popd    # cd to popped directory


    $ pushd ~/a
    $ pushd ~/b
    $ pushd ~/c
    $ cd ~

    | a |  First In Last Out
    +---+
    | b |
    +---+
    | c |
    +---+

    $ popd
    $ pwd
    ~/c

    ```

+ ulimit
    > 控制系統資源
    ```
    -a          | 顯示當前資源限制設定
    -c 區塊數   | 核心資料轉存core 檔案的上限, 單位為區塊
    -d 區塊數   | 程式資料區段大小 (data segment) 的上限, 單位為 KB.
    -f 檔案大小 | 設定 shell 建立檔案大小的上限
    -H          | 設定硬性限制 (hard limit)
    -l 記憶體大小 | 設定可鎖定記憶體的上限
    -m 記憶體大小 | 設定常駐程式上限
    -n 檔案數     | 檔案數的上限
    -p 緩衝區大小 | 設定管道緩衝區 (pipe buffer) 的大小
    -s 堆疊大小   | 設定堆疊的上限
    -S          | 設定軟性限制
    -t CPU 時間 | 佔用CPU 時間的上限 (單位 : 秒)
    -u 程序數目 | 單一使用者可執行程數的最大數目
    -v 虛擬記憶體 | shell 可使用的虛擬記憶體最大上限


    $ ulimit -a
    core file size (blocks, -c) 0
    data seg size (kbytes, -d) unlimited
    file size (blocks, -f) unlimited
    pending signals (-i) 4096
    max locked memory (kbytes, -l) 32
    max memory size (kbytes, -m) unlimited
    open files (-n) 1024
    pipe size (512 bytes, -p) 8
    POSIX message queues (bytes, -q) 819200
    stack size (kbytes, -s) 8192
    cpu time (seconds, -t) unlimited
    max user processes (-u) 4096 <使用者最大可使用程序數量>
    virtual memory (kbytes, -v) unlimited
    file locks (-x) unlimited

    $ ulimit -c unlimited # 不限制 core.xxx 大小
    ```
+ core dump
    > 當某 program 崩潰的瞬間，內核會拋出當時該程序進程的內存詳細情況，</br>
    > 存儲在一個名叫core.xxx(xxx為一個數字，比如core.699)的文件中. </br>
    > 因為core文件是內核生成的，那某一個 process因為段錯誤而崩潰的時候的內存 image很大，</br>
    > 會生成一個很大的core文件, 用 ulimit來改變大小限制

    ```
    compile PROGRAM with CFLAGS="-g"

      # 不限制 core.xxx 大小
    $ ulimit -c unlimited
      # exec PROGRAM
    $ ./a.out
    Segmentation fault (core dumped)

      # 用gdb調試core文件
    $ gdb ./a.out ./core.7369

      # include debug symbols
    (gdb) file ./a.out

      # Segmentation fault 的位置
    (gdb) where
    #0  0x080483b8 in do_it () at ./test.c:10
    #1  0x0804839f in main () at ./test.c:4
    ```




