Putty
---

+ 開NumLock時按小鍵盤上的數字鍵並不能輸入數字, 而是出現一個字母然後換行(實際上是命令模式上對應上下左右的鍵).


    ```
    putty -> Terminal -> Features 裡, 找到 Disable application keypad mode, 選上就可以了
    ```


+ 無法使用 home end 鍵

    - putty版本 > 0.6

        ```
        putty -> Connection -> Data -> Terminal type string 從 xterm 改成 putty or Linux
        ```

    - putty版本 <= 0.6

        ```
        putty->Terminal -> Keyboard -> The home and End keys 改成 Standard

        putty->Terminal -> Keyboard -> The function keys and keypad 改成 SCO
        ```

+ Copy/Paste

    + Paste something from Windows clipboard into Vim
        > Use `Shift + Insert`.

    + Copy something from Vim into the Windows clipboard
        > hold `Shift + Select with Left Mouse`.


+ menuconfig 亂碼
    > 兩種方法, 改 putty 或是 Linux OS 的設定

    - Putty
        > 兩種方法

        > +  Terminal type

        ```
        Window -> Translation -> "Enable VT100 line drawing even in UTF-8 mode".
        ```

        > +  Terminal type

        ```
        putty -> Connection -> Data -> Terminal type string 從 xterm 改成 Linux
        ```

    -  `~/.bashrc` 中新增環境變數

        ```
        export NCURSES_NO_UTF8_ACS=1
        ```


