GDB_CMD
---

+ help (h)
    > 顯示指令簡短說明.例:help breakpoint

+ file
    > 開啟檔案.等同於 gdb filename

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

+ continue (c, cont)
    > 繼續執行.和 breakpoint 搭配使用.

+ frame
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
    >> - `info share`
    >>      > 顯示共享函式庫資訊.

+ disable
    > 暫時關閉某個 breakpoint 或 display 之功能.

+ enable
    > 將被 disable 暫時關閉的功能再啟用.

+ clear/delete
    > 刪除某個 breakpoint.

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

+ <Enter>
    > 直接執行上個指令


# debug tips

+ disassembly code maps to source code
    ```
    $ objdump -D test.o # check disassembly code ln.65 in main()
    $ gdb test.o
    gdb) list *(main+65)
    0x79 is in main(test.c:27)
    
    ```
