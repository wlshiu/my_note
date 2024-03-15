Bash Script 語法解析
---


# Curly Brackets {}

+ `{}` 用法1: 操作變數
    > 建議所有的變數都要用 {} 標好，避免混淆。

    ```
    # 調用變數 ${}
    $ foo=123         # 等號前後不能有空白
    $ echo "${foo}"

    # 取得部分字串/字元數 ${var:index:length} ${#var}
    $ a=123456789
    $ echo ${a:1:3}
    234

    # 字串長度
    $ echo ${#a}
    9

    # 取代部分字串 ${var/source/destination}
    $ greet="Hello World"
    $ echo ${greet/World/$(whoami)}
    Hello vince

    # 根據變數是否存在輸出 ${:-} ${:+} ${:=} ${:?}
    $ unset name
    $ echo ${name:-undefined}
    undefined

    # 錦上添花 ${:+}
    $ echo ${name:+Hello ${name}} // empty
    $ name=Vince
    $ echo ${name:+Hello ${name}}
    Hello Vince

    $ echo ${name:=vince} # 同時將 name 填入 vince
    $ echo ${name}
    vince

    # 直接終止程式，把"a is undefined"丟到stderr
    $ echo ${a:?"a is undefined"}
    ```

+ `{}` 用法2: 迴圈
    > 建議把`; do` 或`; then` 和 for, while, if 放在同一行!

    ```
    # 遞增 1~10
    for i in {1..10}; do
        if (( i % 2 == 0)); then
            continue
        fi
        if (( i == 7 )); then
            break
        fi
        echo "${i}" # print 1, 3, 5
    done

    # 改變 step
    for i in {0..10..2}     # 0 2 4 6 8 10

    # inline loop
    $ while true; do echo $(whoami); sleep 1; done;

    $ a=1
    $ while [[ $a -le 5 ]]; do echo $a; ((a++)); sleep 1; done;
    ```


# Square Brackets []

+ `[]` 用法1: Test (不建議使用)
    - bash 的內部命令，等效於 test，注意空白！不能用 `&&`, `||`, `<,>`
    - 抓取 Test 後的結果，`$?`, `&&`, `IF`

    ```
    # 用 $? 取得上一次執行的結果，0代表true，1代表false (程式的回傳值)
    $ a=100
    $ b=100
    $ test $a -eq $b
    $ echo $?
    0

    # 用 && 代表前面是 true 才執行，用 || 表示是 false 才執行
    test $a -eq $b && echo "Match" || echo "Not Match"
    Match

    [ $a -eq $b ] && echo "Match" || echo "Not Match"
    Match

    # 反向 ! (注意空格)
    if ! [ $a -eq $b ]; then

    # 多重判斷 -a -o
    if ! [ $a -eq $b -a $a -lt $b ]; then

    # 多重判斷 多個 test 用 && 串起來
    if ! [ $a -eq $b ] && [ $a -lt $b ]; then
    ```

    - Test 如何解析，[Stack Overflow](https://stackoverflow.com/questions/19670061/bash-if-false-returns-true)

        ```
        # 不管是在[]或[[]]，裡面的東西會被轉成 string 而不是 command，所以只要 string 長度不為空，就會被當作 true
        $[ 1 ] && echo true || echo false
        true
        $ [ 0 ] && echo true || echo false
        true
        $ a=100; [ $a ] && echo true || echo false
        true
        $ unset a; [ $a ] && echo true || echo false
        false

        # 下面的 true 和 false 會被當成 cmd，且有不同的回傳結果，所以可以被 bash 當成 bool 來用
        $ true && echo true || echo false
        true
        $ false && echo true || echo false
        false

        # 同理
        $ [[ $((1 > 100)) ]] && echo true || echo false
        true
        ```

    - 字串比較才可以用 `==` 和 `!=` 和 `-z/-n`

        ```
        # 字串比較 [] = !=
        if [ "$a" != "$b" ]; then  # 加雙引號避免沒宣告, 也可不加
            echo true
        else
            echo false
        fi

        # 字串長度是否為0, -n(true) -z(false)
        $ test -n $foo && echo true || echo false
        false
        $ foo=123
        $ test -n $foo && echo true || echo false
        true

        # 多用 -n 判斷，少用 if [[ "${foo}" ]] 避免混淆
        if [[ -n "${foo}" ]]; then
            do_something
        fi
        ```

    - 整數比較要用 `-eq` `-ne` `-gt` `-ge` `-lt` `-le` (不建議使用)

        ```
        # 整數比較 [] -eq -ne -gt -ge -lt -le
        if [ $a -eq $b ]; then
        ```


    - 檢查檔案

        ```
        [ -e /path/filename ] && echo "Exist"

        -e: 檔名是否存在
        -f: 檔名存在 && 是否是檔案
        -d: 檔名存在 && 是否是資料夾
        ```

    - 裡面的變數儘量用雙引號括住 `((...))`，因為空白會被切分成下一個指令

        ```
        # 用 test 如果字串有空白會被切成不同指令
        $ foo="123 456"
        $ [ -n $foo ] && echo true || echo false
        bash: [: 123: binary operator expected

        $ [ -n "$foo" ] && echo true || echo false
        true
        ```

+ `[]` 用法2: 描述陣列 index

    ```
    # 矩陣宣告/調用
    $ array=("123" "456" "789")
    $ echo "$array"       # "123"
    $ echo "${array[0]}"  # "123"
    $ echo "${array[1]}"  # "456"
    $ echo "${array[@]}"  # "123 456 789"
    $ echo "${!array[@]}" # 0 1 2
    $ echo "${#array[@]}" # 3

    for i in "${!array[@]}"; then # 0 1 2

    for i in "${array[@]}"; then # 123 456 789
    ```


+ `[[]]` 用法1: 比較通用安全的 test
    - bash 的關鍵字，並不是一個命令
    - 字串: 支援字串模式匹配和空白
    - 儘量使用 `[[ ... ]]` 而不是 `[ ... ]`
    - 在 `[[ ... ]]` 的 `<,>` 會被當作 **lexicographical comparison**，用 `((...))` 或是 `-gt` `-lt`
    - 建議數字比較一律用 `((...))`，字串比較再用 `[[ ... ]]`

    ```
    # 支援字串模式 * ?
    $ [[ a123b == *123* ]] && echo "match" || echo "not match"
    Match

    # 用 =~ 可以直接用 regexp
    re='^[0-9]+$'
    [[ 5566 =~ $re ]] && echo "number" || echo "not number"

    # 字串中的空白會不會像[]被切開
    $ foo="123 456"
    $ [[ -n $foo ]] && echo true || echo false
    true
    ```

    - 可以用 `&&`, `||`，還可以解析算術擴充套件(混著用可讀性有點低)

        ```
        a=101
        b=99

        # 雙引號給它加上去
        if [[ "$a" -gt "$b" ]]; then
            echo 'True'
        else
            echo 'False'
        fi

        # 用$(())，可以有空白
        [[ "$a" -gt "$b" && "$a" -eq $((b + 2)) ]] && echo 'true' || echo 'false'
        true

        # 可以直接在擴充式子用<>比大小，但要判斷 -eq 1，因為$(())的輸出會被[[]]當成字串被處理
        [[ $((100 > 99 + 2 )) -eq 1 ]]  && echo true || echo false
        false

        # 其實可以直接不要用[[]] 直接走(())
        ((100 > 99 + 2 ))  && echo true || echo false
        ```

# Parentheses ()

+ `()` 用法1:命令替換
    > `$(cmd)`: 將小括號裡面的指令執行並返回

    ```
    # 執行指令 $()
    $ name=$(whoami)  # 要跑指令就加上 $()
    $ echo ${name}
    vince

    # 倒單引號也可以
    $ echo My name is `whoami`
    My name is vince
    ```

+ `()` 用法2:Array 宣告

    ```
    # 矩陣宣告/調用
    $ array=("123" "456" "789")
    $ echo $array       # 第0個
    $ echo ${array[0]}  # 第0個
    $ echo ${array[1]}  # 第1個

    # 取得總數 ${#array[@]}
    $ echo ${array[@]}  # 全部
    123 456 789
    $ echo ${#array[@]} # 元素總數
    3

    # Append
    $ a=(1 2)
    $ b=(3 4)
    $ a=("${a[@]}" "${b[@]}")
    $ echo ${a[3]}
    4

    # 轉 string 變成 array, (${string})
    $ string="This is a book"
    $ array=(${string})
    $ echo ${array[2]}
    book

    # Array複製 (沒加括號123 456會被當成兩個元素)
    a=('123 456' '789')
    b=("${a[@]}")
    b=(${a[@]})

    # 走訪陣列 for i in ${!a[@]}
    a=()
    a+=('123')
    a+=('456')
    a+=('678' '999')
    for i in ${!a[@]}; do
        echo "${i}: ${a[i]}"
    done
    ```

+ `)` 用法3: Case

    ```
    case "${name}" in
        Vince)
            echo "Vince"
            ;;
        Ethan)
            echo "Ethan"
            ;;
        *)
            echo "Unknown name" >&2
            ;;
    esac
    ```

+ `(())` 用法1: 算術擴充套件 (arithmetic expansion)

    - `$((expansion))`
    - 可以使用空白，空白會被忽略。

    ```
    # 簡單運算
    $ echo $((1+100))
    101

    #轉進位
    $ echo $((2#111)) # 把2進位的111轉成10進位
    7

    # 比大小用符號 >, <, ==
    $ a=99
    $ b=101
    $ echo $(($a+2 == $b))
    1

    # 變數累加
    $ a=5
    $ ((a++))
    $ echo $a
    6

    # 整數運算
    $ a=7 && b=8
    $ echo $((a*b))   # 或是 $(($a*$b))
    56

    # 用在判斷式
    a=99
    b=100
    if (( $a + 2 > $b )); then
    fi

    # 多個判斷式
    if (( a > b )) || [[ ! -f '/tmp/test.txt' ]]; then
    fi

    # 條件式輸出
    $ a=100
    $ b=50
    $ echo $((a > b ? a : b))
    100
    ```

+ `(())` 用法2: 迴圈

    ```
    # 變數控制迴圈 $(seq) 或 ((;;))
    BEGIN=1
    END=5
    for ((i=$BEGIN; i<=$END; i++))
    do
        echo -n "$i "
    done

    for i in $(seq $BEGIN $END)
    do
        echo -n "$i "
    done

    # 改變 step
    for i in $(seq 1 2 10)  # 1 3 5 7 9
    ```

# 浮點數的 Workaround (awk, bc)

```
# 浮點運算
$ a=123
$ echo $(awk "BEGIN{print $a / 100 * 2}")
2.46

# 浮點數比較
pi=3.14
if [ `echo "$pi < 3.15" | bc` -eq 1 ]; then
```

# readonly, local 變數

+ 養成習慣，變數標 readonly 和 local，global 全大寫。

    ```
    # readonly 宣告
    $ a=123
    $ readonly a
    $ a=456
    bash: a: readonly variable

    # local 宣告 in function
    #!/bin/bash
    function hi {
      a="Hello"
      local b="World"
      echo "$a $b"
    }
    hi # Hello World
    echo $a # Hello
    echo $b # (empty)

    # 解除宣告 (不能unset readonly)
    $ unset name      # 用 unset 解除變數宣告
    $ echo ${name}
    ```

# 引號 Quotation Marks

+ 單引號: 標示內容物沒有需要額外處理的字串
+ 雙引號: 標示內容物可能含有變數、子指令等等
+ 養成把變數或指令用雙引號標起來的習慣，除了 integer/bool 變數除外。

```
echo 'Vince'
echo "${name}"

# 注意巢狀雙引號不用跳脫
echo "$(ls -al /home/"$(whoami)")"

# 雙引號會吃變數
$ echo "My name is ${name}"
My name is vince

# 單引號會當作純字串
$ echo 'My name is ${name}'
My name is ${name}
```

# 特殊變數

## 取得單一 arguments `$n`

```
$ ./test.sh a b c
#!/bin/bash
echo $0 # ./test.sh
echo $1 # a
echo $2 # b
echo $# # 3
```

## 取得全部 arguments `$@` `$*`

```
$ ./test.sh a b c
```

+ `$@` 會把參數根據IFS(空格)切開，所以 a, b, c 會各自分開

    ```
    for var in "$@"
    do
        echo $var
    done
    echo ${#@} # 3
    ```

+ `"$*"` 會把參數連空白當作一體，不會進行任何 parse
    > 注意 `$*` 如果不加雙引號，效力等同於 `$@`, 通常用在要把變數往下一層 script 導
    >> 習慣上盡量使用`$@`，除非有特殊原因，例如打log

    ```
    for var in "$*"
    do
        echo $var  # "a b c"
    done
    ```

## 其他特殊指令


+ `$_` 取得前個 cmd 的最後一個參數

    ```
    $ ./test.sh fist second third
    $ echo $_
    third
    ```

+ `$$` 取得當前 cmd 的 pid

    ```
    $ ps
    4440 pts/0    00:00:00 bash
    $ echo $$
    4440
    ```

+ `$?` 上一個指令是否成功，成功回傳0，失敗回傳1

    ```
    $ true; echo $?
    0
    $ false; echo $?
    1
    ```

# Standard Streams (stdin/stdout/stderr)

+ 將 `stdout` 導到 `/dev/null`

    ```
    $ ./test.sh > /dev/null
    stderr
    ```

+ 將 `stderr` 導到 `/dev/null`，注意 `2>` 中間不能有空白

    ```
    $ ./test.sh 2> /dev/null
    stdout
    ```

+ 將 `stdin/stderr` 都導到 `/dev/null`

    - 先把 `1` 指定成 `/dev/null`, 再把 `2` 指定成 `1 (/dev/null)`

        ```
        $ ./test.sh > /dev/null 2>&1
        ```

    - 等效上面的用法

        ```
        $ ./test.sh &> /dev/null
        ```

    - 錯誤用法，同一份檔案不能被兩個 descriptors 開啟

        ```
        $ ./test.sh 1> result.txt 2> result.txt
        ```

    - 在 bash script 裡面可以寫

        ```
        $ exec > output.log
        $ exec 2>&1
        ```

    - 把 bash 的 `xtrace` 導到 `stderr`

        ```
        $ set -x
        ```

    - 將 `stdout` 同時顯示在螢幕與檔案，**result.txt** 只有 `stdout`

        ```
        $ ./test.sh | tee result.txt
        stderr
        stdout
        ```


    - 將 `stdout` 同時顯示在螢幕與檔案，**result.txt** 全都有

        ```
        $ ./test.sh 2>&1 | tee result.txt
        stderr
        stdout
        ```

    - 有錯誤就要倒到 `stdout`

        ```
        error() {
            echo "[$(date)]: $*" >&2
        }
        ```

    - 把當下 process 的 `stderr` 導到 file

        ```
        exec 2>${file}
        ```

# declare/local

```
local -a 宣告變數為陣列
local -A 宣告變數為 Associative array (key-value)
local -r 代表 readonly
local -n 把另外一個變數內容也指到這個變數
local -p 把變數內容打出來，配合 eval 可以玩很多東西
local -i 把變數當作整數(個人比較少用到)
```
+ example

    ```
    function1() {
        local -A output
        output['a']='123()'
        output['b']='456'
        declare -p output
    }
    ```

# Library/Package

```
## greet.sh
#!/bin/bash
# include guard
[ -n "$_GREET_LIB" ] && return || readonly _GREET_LIB=1
greet::hi() {
  echo Hello ${1:-Stranger}
}

## main.sh
#!/bin/bash
source greet.sh
greet::hi Vince
```

# Function

+ Comment
    >建議不省略 `function` 或是用 `utils::`

    ```
    #################################
    # Descritpion of this function
    # Globals:
    #   DEVICE_DIR
    # Arguments:
    #   Message
    # Output:
    #   Stdout or Stderr
    ##################################
    function hi() {
        echo Hello ${1:-Stranger}
    }
    hi            // Hello Stranger
    hi Vince      // Hello Vince
    ```


+ Return multi-value (不建議使用)

+ Return Array

```
utils::get_array() {
  array=(123 456 789)
  declare -p array
}

eval $(utils::get_array)
echo ${array[0]} # 123
```

+ Return multi-value (Associative array)

    - Way1: Associative array + declare -p

        ```
        function1() {
            local -A output
            output['a']='123()'
            output['b']='456'
            declare -p output
        }
        eval $(function1)
        echo "${output['a']}"
        echo "${output['b']}"
        ```

    - Way2: Create declare string (not recommend)

        ```
        # pitfall: a='123()' will fail, need to escape ()
        function1() {
          a='123'
          b='456'
          echo "a="${a}"; b="${b}""
        }
        eval $(function1)
        echo "${a}" # 123
        echo "${b}" # 456
        ```

+ Pass Array

    ```
    utils::print_array() {
        local -n array="$1"

        for item in "${array[@]}"; do
            echo "${item}"
        done
    }

    declare -a ARRAY=(123 456 789)
    util::print_array ARRAY # without "${}"
    ```

+ Pass Argument w/ w/o quotes

    - 取決於是否當要當成一個或多個參數

        ```
        # Example: arg1:1 arg2:2 arg3:3
        function1() {
            function2 ${1} ${2} ${3} # key point
        }
        function2() {
            echo "arg1:${1}"
            echo "arg2:${2}"
            echo "arg3:${3}"
        }
        a="1"
        b="2 3"
        function1 ${a} ${b} # or
        function1 "${a}" "${b}"

        # Example: arg1:1 arg2:2 arg3:3
        function1() {
            function2 "${1}" "${2}" "${3}"
        }
        function2() {
            echo "arg1:${1}"
            echo "arg2:${2}"
            echo "arg3:${3}"
        }
        a="1"
        b="2 3"
        function1 ${a} ${b} # key point

        # Example: arg1:1 arg2:2 arg3:3
        function1() {
            function2 $@ # key point
        }
        function2() {
            echo "arg1:${1}"
            echo "arg2:${2}"
            echo "arg3:${3}"
        }
        a="1"
        b="2 3"
        function1 "${a}" "${b}"

        # Example: arg1:1 arg2:2 3 arg3:
        function1() {
            function2 "$@" # key point
        }
        function2() {
            echo "arg1:${1}"
            echo "arg2:${2}"
            echo "arg3:${3}"
        }
        a="1"
        b="2 3"
        function1 "${a}" "${b}"
        ```

+ Scope

    - `local/declare -n`: asigned a variable to another by name

        ```
        # Example: global
        function1() {
            echo "${a}" # 123
            a=456
        }
        a=123
        function1
        echo "${a}" # 456

        # Eample: copy global in local
        function1() {
            local b="${a}"
            echo "${b}" # 123
            b=456
        }
        a=123
        function1
        echo "${a}" # 123

        # Example: take global as argument
        function1() {
            local b="${1}"
            echo "${b}" # 123
            b=456
        }
        a=123
        function1 "${a}"
        echo "${a}" # 123

        # Example: asigned a variable to another by name
        function1() {
            local -n b="${1}"
            echo "${b}" # 123
            b=456
        }
        a=123
        function1 a
        echo "${a}" # 456
        ```

# Coding Style (optional)

+ file name: `file_name.sh`

+ function name: `my_function()`

+ local variable: `local my_var`

+ global variable: `DEVICE_DIR`


# 讀 Command 或檔案

+ 從 command pipes 倒到 `stdin`，注意`< <` 中間有空白

    - 寫法一 `readarray` (`-t` 刪除換行符號)

        ```
        readarray -t lines < <(cat source.csv)
        readarray -t lines < source.csv
        for i in ${!lines[@]}; do
            echo "${lines[i]}"
        done
        ```

    - 寫法二 `while read`

        ```
        while read item; do
            if [[ -n "${item}" ]]; then
                echo "${item}"
            fi
        done < <(ls)
        ```

+ 常用取代 (substitue) 和刪除

    - [AWK: a powerful tool for data extraction](https://medium.com/vswe/awk-data-parsing-tool-9408aa13f58)
    - [Regular Expression Example](https://medium.com/vswe/regular-expression-example-51a80c4fdde)

        1. 加頭，(s 代表 substitue)

            ```
            $ echo "Hello" | sed 's/^/~/'
            ~Hello
            ```

        1. 加尾

            ```
            $ echo "Hello" | sed 's/$/~/'
            Hello~
            ```

        1. 加頭又加尾，用分號隔開也行

            ```
            $ echo "Hello" | sed 's/^/~/;s/$/~/'
            ~Hello~
            ```

        1. 同一行中的所有match都替換 (g 代表 global)

            ```
            $ echo "1,2,3" | sed 's/,/|/g'
            1|2|3
            ```

        1. 除了`|`其他都變成`*`
            > + `[]`代表裡面任一個字元成立都可,
            > + `^`在`[]`裡面不代表開頭，而是not的意思

            ```
            $ echo "|asdf|weerwe|qweqw|" | sed 's/[^|]/*/g'
            |****|******|*****|
            ```

        1. `+`代表重複出現 1~n 次
            > `-E` 或 `-r` 代表用extended regexp (預設是basic不支援`+`)

            ```
            echo "|asdf|weerwe|qweqw|" | sed -E 's/[^|]+/*/g'
            |*|*|*|
            ```

        1. 得到 match 的個數
            > 刪除只要把取代的字元變成空即可

            ```
            echo "|asdf|weerwe|qweqw|" \   # |asdf|weerwe|qweqw|
            | sed -E 's/[^|]//g' \         # ||||
            | awk '{print length}' \       # 4
            | wc -c \                      # bytes 5 會把 echo default 換行算進去
            | wc -b                        # chars 5 用 echo -n 就不會有換行
            ```

# Reference

+ [Bash Script 語法解析. 各種單雙括弧、特殊符號語法](https://medium.com/vswe/bash-shell-script-cheat-sheet-15ce3cb1b2c7)
