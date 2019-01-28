tutorial
---

# `.gdbinit`

    ```
    $ cat stl-views-1.0.3.gdb >> ~/.gdbinit
    ```

    + 自動加載

    ```
    13        vector<string> vstr;
    (gdb) n
    14        vstr.push_back("Hello");
    (gdb) n
    15        vstr.push_back("World");
    (gdb) n
    16        vstr.push_back("!");
    (gdb) p<TAB><TAB>
    passcount     plist_member  print         pstring       python
    path          pmap          print-object  ptype
    pbitset       pmap_member   printf        pvector
    pdequeue      ppqueue       pset          pwd
    plist         pqueue        pstack        pwstring
    ```

    + 分析

    ```
    define pvector
        if $argc == 0
            # 如果沒有帶參數，那麼就打印幫助提示信息
            help pvector
        else
            # 如果有參數，那麼接下來準備一下size, capacity, size_max 這三個重要的參數。
            set $size = $arg0._M_impl._M_finish - $arg0._M_impl._M_start

            # arg0 就是第一個參數，也就是vstr數組對象。注重 size 是怎麼計算的。
            set $capacity = $arg0._M_impl._M_end_of_storage - $arg0._M_impl._M_start
            set $size_max = $size - 1
        end
        if $argc == 1
            # 如果只有一個參數，說明要求打印出vector中所有的元素
            set $i = 0
            while $i < $size
                # 用一個 while 循環，用printf與p，打印出列表中的所有元素
                printf "elem[%u]: ", $i
                p *($arg0._M_impl._M_start + $i)     # 注意看哦！！！！
                set $i++
            end
        end
    ```
