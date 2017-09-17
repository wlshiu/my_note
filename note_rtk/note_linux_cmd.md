Linux cmd
---

+ find
    1. `-exec`

        ```
        $ find . -type f -name '*.c' -exec grep 'init' --color -nH {} \;
        ```

        a. `{}` means the output of find cmd
        a. `\;` means the end of `-exec`

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





