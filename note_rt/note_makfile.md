Makefile
---
+ toolchain
    - `arm-none-eabi`
        > 這個是沒有 OS的，不支援那些跟 OS關係密切的函數，比如fork(2)。他使用的是`newlib`這個專用於嵌入式系統的C庫。

        1. 用於編譯 ARM 架構的裸機系統, 包括 ARM Linux 的 boot、kernel，*不適用編譯 Linux 應用 Application*，
            一般適合 ARM7、Cortex-M 和 Cortex-R 內核的芯片使用，所以不支持那些跟操作系統關係密切的函數，
            比如fork(2)，他使用的是 `newlib` 這個專用於嵌入式系統的C庫。

            ```
            e.g. arm-none-eabi-xxx
            ```

        1. ubuntu
            ```
            $ sudo apt-get install libnewlib-arm-none-eabi
            ```

    - `arm-none-linux-eabi`
        > 用於Linux的，使用`Glibc`

        1. 主要用於基於ARM架構的Linux系統，可用於編譯 ARM 架構的 u-boot、Linux內核、linux應用等。
            arm-none-linux-gnueabi基於GCC，使用Glibc庫，經過 Codesourcery 公司優化過推出的編譯器。
            arm-none-linux-gnueabi-xxx 交叉編譯工具的浮點運算非常優秀。
            一般ARM9、ARM11、Cortex-A 內核，*帶有 Linux OS的會用到*。

            ```
            e.g. arm-none-linux-gnueabi-xxx
            ```

        1. ubuntu
            ```
            $ sudo apt-get install gcc-arm-linux-gnueabi
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

+ show message
    - with TARGET (cmd, e.g XXX:)
        ```
        # with a Tab prefix
        log:
            @echo "start the compilexxxxxxxxxxxxxxxxxxxxxxx"

        ```
    - with normal
        ```
        $(info TARGET_DEVICE=$(TARGET_DEVICE) )

        $(info "here add the debug info")

        $(warning "here add the debug info")

        # exit makefile
        $(error "error: this will stop the compile")

        ```

+ pause script
    ```
    read -p "Press enter to continue"
    ```
+ 特別字元


    - `@`
        > 不要顯示執行的指令

    - `-`
        > 表示即使該行指令出錯, 也不會中斷執行
        ```
        -include config/auto.conf
        ```

+ function
    - `patsubst`
        > define: `$(patsubst <pattern>,<replacement>,<text>)`
        ```
        $(patsubst %.c，%.o，$(SOURCES))
        # 所有 SOURCES 中的字(file list), 如果它的結尾是 '.c', 就用'.o' 取代.
        # '%' 為萬用字元
        ```

    - `subst`
        > define: `$(subst from,to,text)`
        ```
        $(subst a, the, There is a big tree)
        # 將 text 中的 from 取帶為 to
        # output: There is 'the' big tree
        ```

    - `wildcard`
        > define: `$(wildcard pattern...)`
        ```
        $(wildcard *.c)
        # 列出目前工作目錄下(./), 所有的.c文件列表, 並以空格為分隔

        SRC = $(wildcard *.c) $(wildcard inc/*.c)
        # 取得 ./*.c 和 ./inc/*.c 文件列表
        ```

    - `strip`
        > define: `$(strip <string> )`
        ```
        去掉<string>字串中開頭和結尾的空字元
        ```

    - `if_changed` (in scripts/Kbuild.include)
        > 在當發現規則的依賴有更新, 或者是對應目標的命令行參數發生改變時, 執行後面的語句

+ 自動變數
    ```
    [target]: [dependency list]
    e.g.
        main: main.o a.o b.o
    ```

    - `$@`
        > makefile 中, target 所對應的檔案名.

    - `$<`
        > makefile 中, target 所需要的第一個 dependency 檔案名

    - `$^`
        > makefile 中, target 所需要檔案的列表, 以空格分割. (這份清單已經拿掉重複的檔名)

    - `$%`
        > 當目標是函數庫檔案時, 表示其中的 target檔案名

+ 賦值

    ```
    =       是最基本的賦值
    :=      會覆蓋變數之前的值
    ?=      變數為空時才給值, 不然則維持之前的值
    +=      將值附加到變數的後面
    ```

    - `=`

        make會將整個makefile展開後,才決定變數的值. 也就是說,變數的值會是整個Makefile中最後被指定的值. 看例子:
        ```
        x = hello
        y = $(x) world!
        x = hi

        all:
            @echo $(y)
        ```

        在上例中,輸出結果將會是 hi world! ,而不是 hello world!


    - `:=`

        變數的值在Makefile展開途中就會被給定, 而不是整個Makefile展開後的最終值.
        ```
        x := hello
        y := $(x) world!
        x := hi

        all:
            @echo $(y)
        ```
        輸出結果 ====> hello world!



