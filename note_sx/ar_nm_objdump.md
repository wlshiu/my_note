絕對強大的三個linux指令： ar, nm, objdump
---

## 前言

如果普通編程不需要瞭解這些東西，如果想精確控制你的對象文件的格式, 或者你想查看一下文件對象裡的內容, 以便作出某種判斷，剛你可以看一下下面的工具： objdump, nm, ar。
當然，本文不可能非常詳細的說明它們的使用方法和功能。如果你覺得本文不夠清楚，你可以使用 `:man`. 我的計畫只是想讓更多的人瞭解這些工具，以後在今後 的編程過程中能有所幫助。


操作系統： Linux

## 開始


### ar 經常用法：

庫文件操作命令：`ar`
> 非常好的東東。 讓你能查看函數庫裡的詳細情況和用多個對象文件生成一個庫文件。

+ `ar -t libname.a`
    > 顯示所有對象文件(.o文件)的列表.

    ```
    $ ar t libtest.a
    libtest1.o
    libtest2.o
    ```

+ `ar -rv libname.a  objfile1.o objfile2.o ... objfilen.o`
    > 把 `objfile1.o ~ objfilen.o` 打包成一個庫文件

    - ar 選項
        > + `d`: 從庫中刪除模塊。按模塊原來的文件名指定要刪除的模塊。如果使用了任選項v則列出被刪除的每個模塊。
        > + `m`: 該操作是在一個庫中移動成員。當庫中如果有若干模塊有相同的符號定義(如函數定義)，則成員的位置順序很重要。如果沒有指定任選項，任何指定的成員將移到庫的最後。也可以使用'a'，'b'，或'I'任選項移動到指定的位置。
        > + `p`: 顯示庫中指定的成員到標準輸出。如果指定任選項v，則在輸出成員的內容前，將顯示成員的名字。如果沒有指定成員的名字，所有庫中的文件將顯示出來。
        > + `q`: 快速追加。增加新模塊到庫的結尾處。並不檢查是否需要替換。'a'，'b'，或'I'任選項對此操作沒有影響，模塊總是追加的庫的結尾處。如果使用了任選項v則列出每個模塊。 這時，庫的符號表沒有更新，可以用'ar s'或ranlib來更新庫的符號表索引。
        > + `r`: 在庫中插入模塊(替換)。當插入的模塊名已經在庫中存在，則替換同名的模塊。如果若干模塊中有一個模塊在庫中不存在，ar顯示一個錯誤消息，並不替換其他同名模塊。默認的情況下，新的成員增加在庫的結尾處，可以使用其他任選項來改變增加的位置。
        > + `t`: 顯示庫的模塊表清單。一般只顯示模塊名。
        > + `x`: 從庫中提取一個成員。如果不指定要提取的模塊，則提取庫中所有的模塊。
    　
        下面在看看可與操作選項結合使用的任選項：

        > + `a`: 在庫的一個已經存在的成員後面增加一個新的文件。如果使用任選項a，則應該為命令行中membername參數指定一個已經存在的成員名。
        > + `b`: 在庫的一個已經存在的成員前面增加一個新的文件。如果使用任選項b，則應該為命令行中membername參數指定一個已經存在的成員名。
        > + `c`: 創建一個庫。不管庫是否存在，都將創建。
        > + `f`: 在庫中截短指定的名字。缺省情況下，文件名的長度是不受限制的，可以使用此參數將文件名截短，以保證與其它系統的兼容。
        > + `i`: 在庫的一個已經存在的成員前面增加一個新的文件。如果使用任選項i，則應該為命令行中membername參數指定一個已經存在的成員名(類似任選項b)。
        > + `l`: 暫未使用
        > + `N`: 與count參數一起使用，在庫中有多個相同的文件名時指定提取或輸出的個數。
        > + `o`: 當提取成員時，保留成員的原始數據。如果不指定該任選項，則提取出的模塊的時間將標為提取出的時間。
        > + `P`: 進行文件名匹配時使用全路徑名。ar在創建庫時不能使用全路徑名（這樣的庫文件不符合POSIX標準），但是有些工具可以。
        > + `s`: 寫入一個目標文件索引到庫中，或者更新一個存在的目標文件索引。甚至對於沒有任何變化的庫也作該動作。對一個庫做ar s等同於對該庫做ranlib。
        > + `S`: 不創建目標文件索引，這在創建較大的庫時能加快時間。
        > + `u`: 一般說來，命令ar r...插入所有列出的文件到庫中，如果你只想插入列出文件中那些比庫中同名文件新的文件，就可以使用該任選項。該任選項只用於r操作選項。
        > + `v`: 該選項用來顯示執行操作選項的附加信息。
        > + `V`: 顯示ar的版本.


### nm 列出目標文件(.o)的符號清單。

+ `nm -s filename.a/filename.o/a.out`
    > 裡邊所有的符號列表一清二楚。例：

    ```
    $ nm -s a.out
        080495b8 A __bss_start
        08048334 t call_gmon_start
        080495b8 b completed.5751
        080494b8 d __CTOR_END__
        080494b4 d __CTOR_LIST__
        080495ac D __data_start
        080495ac W data_start
        08048450 t __do_global_ctors_aux
        08048360 t __do_global_dtors_aux
        080495b0 D __dso_handle
        080494c0 d __DTOR_END__
        080494bc d __DTOR_LIST__
        080494c8 d _DYNAMIC
        080495b8 A _edata
        080495bc A _end
        0804847c T _fini
        08048498 R _fp_hw
        08048390 t frame_dummy
        080484b0 r __FRAME_END__
        08049594 d _GLOBAL_OFFSET_TABLE_
                 w __gmon_start__
        0804844c T __i686.get_pc_thunk.bx
        080482b8 T _init
        080494b4 a __init_array_end
        080494b4 a __init_array_start
        0804849c R _IO_stdin_used
        080494c4 d __JCR_END__
        080494c4 d __JCR_LIST__
                 w _Jv_RegisterClasses
        080483e0 T __libc_csu_fini
        080483f0 T __libc_csu_init
                 U __libc_start_main@@GLIBC_2.0
        080483b4 T main
        080495b4 d p.5749
                 U puts@@GLIBC_2.0
        08048310 T _start
    ```

    - 選項/屬性:
        > + `-a`或`--debug-syms`：顯示調試符號。
        > + `-B`：等同於`--format=bsd`，用來兼容MIPS的nm。
        > + `-C`或`--demangle`：將低級符號名解碼(demangle)成用戶級名字。這樣可以使得C++函數名具有可讀性。
        > + `-D`或`--dynamic`：顯示動態符號。該任選項僅對於動態目標(例如特定類型的共享庫)有意義。
        > + `-f format`：使用format格式輸出。format可以選取bsd、sysv或posix，該選項在GNU的nm中有用。默認為bsd。
        > + `-g`或`--extern-only`：僅顯示外部符號。
        > + `-n、-v`或`--numeric-sort`：按符號對應地址的順序排序，而非按符號名的字符順序。
        > + `-p`或`--no-sort`：按目標文件中遇到的符號順序顯示，不排序。
        > + `-P`或`--portability`：使用POSIX.2標準輸出格式代替默認的輸出格式。等同於使用任選項-f posix。
        > + `-s`或`--print-armap`：當列出庫中成員的符號時，包含索引。索引的內容包含：哪些模塊包含哪些名字的映射。
        > + `-r`或`--reverse-sort`：反轉排序的順序(例如，升序變為降序)。
        > + `--size-sort`：按大小排列符號順序。該大小是按照一個符號的值與它下一個符號的值進行計算的。
        > + `-t radix`或`--radix=radix`：使用radix進制顯示符號值。radix只能為"d"表示十進制、"o"表示八進制或"x"表示十六進制。
        > + `--target=bfdname`：指定一個目標代碼的格式，而非使用系統的默認格式。
        > + `-u`或`--undefined-only`：僅顯示沒有定義的符號(那些外部符號)。
        > + `-l`或`--line-numbers`：對每個符號，使用調試信息來試圖找到文件名和行號。對於已定義的符號，查找符號地址的行號。對於未定義符號，查找指向符號重定位入口的行號。如果可以找到行號信息，顯示在符號信息之後。
        > + `-V`或`--version`：顯示nm的版本號。
        > + `--help`：顯示nm的任選項。


### objdump 文件命令功能強的驚人。能實現上述兩個命令(ar,nm)的很多功能。它主要是查看對象文件的內容信息。

+ `objdump -h file<.o,.a,.out>`
    > 查看對象文件所有的節sections.例如：

    ```
    $ objdump -h libtest1.o
    libtest1.o:     file format elf32-i386
    Sections:
    Idx Name          Size      VMA       LMA       File off  Algn
      0 .text         00000014  00000000  00000000  00000034  2**2
                      CONTENTS, ALLOC, LOAD, RELOC, READONLY, CODE
      1 .data         00000000  00000000  00000000  00000048  2**2
                      CONTENTS, ALLOC, LOAD, DATA
      2 .bss          00000000  00000000  00000000  00000048  2**2
                      ALLOC
      3 .rodata       0000000e  00000000  00000000  00000048  2**0
                      CONTENTS, ALLOC, LOAD, READONLY, DATA
      4 .comment      0000001f  00000000  00000000  00000056  2**0
                      CONTENTS, READONLY
      5 .note.GNU-stack 00000000  00000000  00000000  00000075  2**0
                      CONTENTS, READONLY
    ```

+ `objdump -t`
    > 查看對象文件所有的符號列表，相當於 `nm -s objfilename`, 如：

    ```
    $ objdump -t libtest1.o

    libtest1.o:     file format elf32-i386

    SYMBOL TABLE:
    00000000 l    df *ABS*  00000000 libtest1.c
    00000000 l    d  .text  00000000 .text
    00000000 l    d  .data  00000000 .data
    00000000 l    d  .bss   00000000 .bss
    00000000 l    d  .rodata        00000000 .rodata
    00000000 l    d  .note.GNU-stack        00000000 .note.GNU-stack
    00000000 l    d  .comment       00000000 .comment
    00000000 g     F .text  00000014 print_test1
    00000000         *UND*  00000000 puts
    ```

    - 更多信息請查看選項：

        > + `--archive-headers`
        > + `-a` 顯示檔案庫的成員信息，與 ar tv 類似

           ```
            objdump -a libpcap.a
            和 ar -tv libpcap.a 顯示結果比較比較
            顯然這個選項沒有什麼意思。
            ```

        > + `--adjust-vma=offset`
        >>When  dumping  information, first add offset to all
        the section addresses.  This is useful if the  sec-
        tion  addresses  do  not correspond  to the symbol
        table, which can happen when  putting  sections  at
        particular  addresses when using a format which can
        not represent section addresses, such as a.out.

        > + `-b bfdname`
        > + `--target=bfdname`
        >> 指定目標碼格式。這不是必須的，objdump能自動識別許多格式，
        比如：objdump -b oasys -m vax -h fu.o
        顯示fu.o的頭部摘要信息，明確指出該文件是Vax系統下用Oasys
        編譯器生成的目標文件。objdump -i將給出這裡可以指定的
        目標碼格式列表

        > + `--demangle`
        > + `-C` 將底層的符號名解碼成用戶級名字，除了去掉所有開頭的下劃線之外，還使得C++函數名以可理解的方式顯示出來。

        > + `--debugging`
        >> 顯示調試信息。企圖解析保存在文件中的調試信息並以C語言的語法顯示出來。僅僅支持某些類型的調試信息。

        > + `--disassemble`
        > + `-d` 反彙編那些應該還有指令機器碼的section

        > + `--disassemble-all`
        > + `-D` 與 `-d` 類似，但反彙編所有section

        > + `--prefix-addresses`
        >> 反彙編的時候，顯示每一行的完整地址。這是一種比較老的反彙編格式。
        顯示效果並不理想，但可能會用到其中的某些顯示，自己可以對比。

        > + `--disassemble-zeroes`
        >> 一般反彙編輸出將省略大塊的零，該選項使得這些零塊也被反彙編。

        > + `-EB`
        > + `-EL`
        > + `--endian={big|little}`
        >> 這個選項將影響反彙編出來的指令。
        little-endian就是我們當年在dos下玩彙編的時候常說的高位在高地址，
        x86都是這種。

        > + `--file-headers`
        > + `-f` 顯示 objfile 中每個文件的整體頭部摘要信息。

        > + `--section-headers`
        > + `--headers`
        > + `-h` 顯示目標文件各個section的頭部摘要信息。

        > + `--help` 簡短的幫助信息。

        > + `--info`
        > + `-i` 顯示對於 `-b` 或者 `-m` 選項可用的架構和目標格式列表。

        > + `--section=name`
        > + `-j name` 僅僅顯示指定section的信息

        > + `--line-numbers`
        > + `-l` 用文件名和行號標註相應的目標代碼，僅僅和`-d`、`-D`或者`-r`一起使用
        >> 使用`-ld`和使用`-d`的區別不是很大，在源碼級調試的時候有用，要求編譯時使用了-g之類的調試編譯選項。

        > + `--architecture=machine`
        > + `-m machine`
        >> 指定反彙編目標文件時使用的架構，當待反彙編文件本身沒有描述架構信息的時候(比如S-records)，
        這個選項很有用。可以用`-i`選項列出這裡能夠指定的架構

        > + `--reloc`
        > + `-r` 顯示文件的重定位入口。如果和`-d`或者`-D`一起使用，重定位部分以反匯編後的格式顯示出來。

        > + `--dynamic-reloc`
        > + `-R` 顯示文件的動態重定位入口，僅僅對於動態目標文件有意義，比如某些共享庫。

        > + `--full-contents`
        > + `-s` 顯示指定section的完整內容。

            ```
            $ objdump --section=.text -s inet.o | more
            ```

        > + `--source`
        > + `-S` 儘可能反彙編出源代碼，尤其當編譯的時候指定了`-g`這種調試參數時，效果比較明顯。隱含了-d參數。

        > + `--show-raw-insn`
        >> 反彙編的時候，顯示每條彙編指令對應的機器碼，除非指定了`--prefix-addresses`，這將是缺省選項。

        > + `--no-show-raw-insn`
        >> 反彙編時，不顯示彙編指令的機器碼，這是指定 `--prefix-addresses` 選項時的缺省設置。

        > + `--stabs`
        >> Display the contents of the .stab, .stab.index, and
        .stab.excl sections from an ELF file.  This is only
        useful  on  systems  (such as Solaris 2.0) in which
        .stab debugging symbol-table entries are carried in
        an ELF section.  In most other file formats, debug-
        ging  symbol-table  entries  are interleaved  with
        linkage symbols, and are visible in the --syms output.

        > + `--start-address=address`
        >> 從指定地址開始顯示數據，該選項影響`-d`、`-r`和`-s`選項的輸出。

        > + `--stop-address=address`
        >> 顯示數據直到指定地址為止，該選項影響-d、-r和-s選項的輸出。

        > + `--syms`
        > + `-t` 顯示文件的符號表入口。類似於`nm -s`提供的信息

        > + `--dynamic-syms`
        > + `-T` 顯示文件的動態符號表入口，僅僅對動態目標文件有意義，比如某些共享庫。
        它顯示的信息類似於 `nm -D|--dynamic` 顯示的信息。

        > + `--version` 版本信息

            ```
            $objdump --version
            ```

        > + `--all-headers`
        > + `-x` 顯示所有可用的頭信息，包括符號表、重定位入口。
        >> `-x` 等價於`-a/-f/-h/-r/-t` 同時指定。

            ```
            $ objdump -x inet.o
            ```

http://www.webgamei.com/club/thread-3331-1-1.html