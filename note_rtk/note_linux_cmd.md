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



