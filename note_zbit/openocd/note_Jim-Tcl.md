Jim-TCL [[Back](note_openocd.md#Note_Jim-Tcl)]
---

Jim-Tcl 為小型**TCL直譯器**, 這種程式語言提供了一個簡單且可擴展的 Script 直譯器
> 類似 bash script

此 note 主要針對 OpenOCD 使用 Jim-Tcl 的情況

# Sytax

+ 每條命令句以 `\n`或是分號 `;` 分隔
+ **大小寫有區別**
+ 每⾏如果⻑度過⻑, 可⽤反斜線 `\` 斷成兩⾏書寫
+  `#` 用來註解
    > 行尾註解需先加上 `;`, 代表前面指令結束
    > ```tcl
    > % puts hello ;# here is comment
    > ```


+ 空格用來區隔兩個敘述單詞
+ `[]` ⽅括號用於描述句中, 需先執行的子命令
    > 與 C-Code 中的 `()` 小括號相同

+ `{}` ⼤括號⽤於部份函式和陣列
+ `$` 表⽰變數

+ OpenOCD 約定**臨時變數**命名使用 `_` 開頭

+ String

    - `"..."` 雙引號中的字串, 會將變數做置換處理, 但加上 `{...}` 則保留原始字串

        ```tcl
        $ vi demo.tcl
            #!/bin/tclsh

            puts stdout one; puts stdout two

            set x 4
            set y 6
            puts "$x + $y = [expr $x + $y]"
            puts {$x + $y = [expr $x + $y]}

            puts "Hello\n\nTCL!"
        ```

        ```
        $ demo.tcl
            one
            two
            4 + 6 = 10
            $x + $y = [expr $x + $y]
            Hello

            TCL!
        ```

# Commands

`tclsh` 會使用 `%` 作為 prompt

## 運算子

+ `-`, `~`, `!`
    > + 減號(Unary minus)
    > + NOT 位元運算(Bit-wise not)
    > + NOT布林邏輯運算(Logical not)

    這些運算不可以用來操作字串(string)運算元, 而且 `~` 只限於整數的操作


+ `*`, `/`, `%`
    > + 乘(Multiply)
    > + 除(divide)
    > + 餘數(remainder)

    這些運算不可以用來操作字串(string)運算元, 而且 `%` 運算只限於整數的操作

+ `+`, `-`
    > + 加(Add)
    > + 減(subtract)

    限用於數值運算元

+ `<<`, `>>`
    > 左右移位運算 (Shift Left/Right)

    運算只限於整數的操作

+ `<`, `>`, `<=`, `>=`
    > 布林運算
    > + 小於(less)
    > + 大於(greater)
    > + 小於等於(less than or equal)
    > + 大於等於(greater than or equal)

    如果條件成立這些運算子會產生`1`的結果, 否則產生`0`


+ `==`, `!=`
    > 布林運算
    > + 等於(equal)
    > + 不等於(not equal)

    每個運算會產生 0/1 的結果, 可適用於任何運算元

+ `&`, `^`, `|`
    > + AND 位元運算(Bit-wise and), 限於整數的操作
    > + XOR 位元運算(Bit-wise exclusive or), 限於整數的操作
    > + OR 位元運算(Bit-wise or), 限於整數的操作

+ `&&`, `||`
    > + AND 布林邏輯運算(Logical and), 限用於數值運算元(不限整數或小數)
    > + OR 布林邏輯運算(Logical or), 限用於數值運算元(不限整數或小數)

+ `x ? y : z`
    > 如果 x 為真時, 傳回 y 否則傳回 z



## `set` and `unset`

set/unset 變數時, 不需使用 `$`, 但對變數操作時, 要加上 `$`
> 和 Bash 相同

```
% set x 5 ;# 宣告變數
% unset x ;# 刪除變數釋放空間
```

## `puts`

輸出內容到 Console

```
set x 5
puts stdout $x
```

## `incr`

累加變數

```
% incr counter ;# 等同 C-Code 的 'counter++'
```

## `info`

info 能夠獲取關於當前環境的資訊, 如命令名, 變數名, 呼叫stack等

```
puts [info commands]    ;# 獲取所有可用命令
puts [info vars]        ;# 獲取所有變數
puts [info level]       ;# 獲取當前呼叫棧深度
```

### `info exists`

檢查變數是否存在

```
if {![info exists counter]} {
    set counter 0
} else {
    incr counter     ;# counter 加 1
}
```

### `info global`

列出所有全域變數

```
% info global
```

## `eval`

eval 這個指令, 主要是用於去執行一段 tcl script

```tcl
set foo "puts hi"
eval $foo

# output: hi
```

## `expr`

使用 expr 這個指令, 去**判斷表示式的 true/false** 或 **數學計算表示式的值**

```tcl
set value [expr 2>=1]
puts $value

# output: 1
```

```tcl
set value [expr 2+3]
puts $value

# output: 5
```

## `if-elseif-else`

```tcl
set my_planet "earth"

if {$my_planet == "earth"} {
    puts "I feel right at home."
} elseif {$my_planet == "venus"} {
    puts "This is not my home."
} else {
    puts "I am neither from Earth， nor from Venus."
}

set temp 95

if {$temp < 80} {
    puts "It's a little chilly."
} else {
    puts "Warm enough for me."
}

# output:
#   I feel right at home
#   Warm enough for me.
```


## `switch`

```tcl
set num_legs 4

switch $num_legs {

    2 {puts "It could be a human."}

    4 {puts "It could be a cow."}

    6 {puts "It could be an ant."}

    8 {puts "It could be a spider."}

    default {puts "It could be anything."}

}

# output: It could be a cow.
```

## `for loop`

支援 `break/continue`

```tcl
for {set i 0} {$i < 5} {incr i 1} {
    puts "In the for loop， and i == $i"
}

# outupt:
#   In the for loop， and i == 0
#   In the for loop， and i == 1
#   In the for loop， and i == 2
#   In the for loop， and i == 3
#   In the for loop， and i == 4
```

## `while loop`

支援 `break/continue`

```tcl
set i 0

while {$i < 5} {
    puts "In the while loop， and i == $i"
    incr i 1
}

# outupt:
#   In the while loop， and i == 0
#   In the while loop， and i == 1
#   In the while loop， and i == 2
#   In the while loop， and i == 3
#   In the while loop， and i == 4
```

## `foreach`

```tcl
foreach vowel {a e i o u} {
    puts "$vowel is a vowel"
}

# outupt:
#   a is a vowel
#   e is a vowel
#   i is a vowel
#   o is a vowel
#   u is a vowel
```

## `proc`

自訂 function, `proc name {params} { body }`

```tcl
proc sum_proc {a b} {
    return [expr $a + $b]
}

proc magnitude {num} {
    if {$num > 0} {
        return $num
    }

    set num [expr $num * (-1)]
    return $num
}

set num1 12
set num2 14
set sum [sum_proc $num1 $num2]

puts "The sum is $sum"
puts "The magnitude of 3 is [magnitude 3]"
puts "The magnitude of -2 is [magnitude -2]"

# output:
#   The sum is 26
#   The magnitude of 3 is 3
#   The magnitude of -2 is 2
```


## global/local variable

使用 global 這個保留字做宣告, 才能存取程序外已經定義好的變數

```tcl
proc dumb_proc {} {
    set myvar 4
    puts "The value of the local variable is $myvar"
    global myglobalvar
    puts "The value of the global variable is $myglobalvar"
}

set myglobalvar 79
dumb_proc

# output:
#   The value of the local variable is 4
#   The value of the global variable is 79
```

## arrays

tcl 的 array 使用 key-value pair 的對應方式

```tcl
set myarray(0) "Zero"
set myarray(1) "One"
set myarray(2) "Two"

for {set i 0} {$i < 3} {incr i 1} {
    puts $myarray($i)
}

# output:
#   Zero
#   One
#   Two
```

```tcl
set person_info(name) "Fred Smith"
set person_info(age) "25"
set person_info(occupation) "Plumber"

# '{name age occupation}' 自行將所有 items 加入集合中
foreach thing {name age occupation} {
    puts "$thing == $person_info($thing)"
}

# '[array names person_info]' 使用宣告的變數
foreach thing [array names person_info] {
    puts "$thing == $person_info($thing)"
}

# outupt:
#   name == Fred Smith
#   age == 25
#   occupation == Plumber
```


## output file

```tcl
set f [open "/tmp/myfile" "w"]

puts $f "We live in Texas. It's already 110 degrees out here."
puts $f "456"

close $f

# output:
#   create file at '/tmp/myfile'
```

## `source`

與 bash 的 source 同樣功能


## `exec`

exec 執行系統命令並捕獲輸出

```tcl
# exec與 bash 中的 result=`ls` 相同

set result [exec ls]
puts $result
```

## `open`, `close`, and `gets`

```tcl
set INFILE [open /tmp/test.txt r]

while {[gets $INFILE line] >= 0} {
    puts "$line"
}

close $INFILE
```

+ `open` syntax
    > 開檔案

    ```
    open <file-path> <access>

    # <access>
    #   r/r+/w/w+/a/a+
    ```

+ `gets` syntax
    > 從檔案讀一行資料

    ```
    gets <file-handle> variable
    ```


## pipe `|`

```tcl
set pipe [open "| ls -l" r]

while {[gets $pipe line] >= 0} {
    puts $line
}
close $pipe
```

## `pwd`

回傳當前目錄完整路徑

## `cd`

切換當前目錄

## `glob`

搜尋檔案 (支援萬用字元)

```
# 找到所有 '*.c' 及 '*.h' 的檔案
% glob *.c *.h
```

## `file`

檔案系統操作 (不支援萬用字元, 會搭配 `glob`)

### 1. 獲取檔案的最後訪問時間

```
set atime [file atime /path/to/file.txt]
puts "Last access time: $atime"
```

### 2. 獲取或設定檔案屬性

```
# 獲取檔案屬性
set attrs [file attributes /path/to/file.txt]
puts $attrs

# 設定檔案為唯讀
file attributes /path/to/file.txt -readonly true
```

### 3. 返回當前打開的所有檔案通道的列表

```
set channels [file channels]
puts "Open channels: $channels"
```

### 4. 複製檔案或目錄

```
# 複製檔案
file copy /path/to/source.txt /path/to/destination.txt

# 強制複製檔案（覆蓋目標檔案）
file copy -force /path/to/source.txt /path/to/destination.txt

# 建立永久連結
file copy -link /path/to/source.txt /path/to/link.txt
```

### 5. 刪除檔案或目錄

```
# 刪除檔案
file delete /path/to/file.txt

# 強制刪除目錄及其內容
file delete -force /path/to/directory

# 批次刪除檔案
eval file delete [glob *.tmp]
```

### 6. 返回檔案的目錄部分

```
set dir [file dirname /path/to/file.txt]
puts "Directory: $dir"
```

### 7. 檢查檔案是否可執行

```
if {[file executable /path/to/file.sh]} {
    puts "File is executable"
} else {
    puts "File is not executable"
}
```

### 8. 檢查檔案或目錄是否存在

```
if {[file exists /path/to/file.txt]} {
    puts "File exists"
} else {
    puts "File does not exist"
}
```

### 9. 返回檔案的擴展名部分

```
set ext [file extension /path/to/file.txt]
puts "Extension: $ext"
```

### 10. 檢查是否為目錄

```
if {[file isdirectory /path/to/directory]} {
    puts "It is a directory"
} else {
    puts "It is not a directory"
}
```

### 11. 檢查是否為檔案

```
if {[file isfile /path/to/file.txt]} {
    puts "It is a file"
} else {
    puts "It is not a file"
}
```

### 12. 將多個檔案名稱組合成一個路徑

```
set path [file join /path/to directory file.txt]
puts "Path: $path"
```

### 13. 獲取符號連結的資訊

```
file lstat /path/to/symlink info
puts "Symlink info: $info"
```

### 14. 建立目錄

```
file mkdir /path/to/newdir
puts "Directory created"
```

### 15. 獲取或設定檔案的最後修改時間

```
# 獲取最後修改時間
set mtime [file mtime /path/to/file.txt]
puts "Last modification time: $mtime"

# 設定最後修改時間
file mtime /path/to/file.txt 1625580000
```

### 16. 返回檔案的本地表示形式

```
set native [file nativename /path/to/file.txt]
puts "Native name: $native"
```

### 17. 返回檔案的規範化路徑

```
set norm [file normalize /path/to/../to/file.txt]
puts "Normalized path: $norm"
```

### 18. 檢查當前使用者是否擁有檔案

```
if {[file owned /path/to/file.txt]} {
    puts "File is owned by the current user"
} else {
    puts "File is not owned by the current user"
}
```

### 19. 返回路徑的類型

```
set type [file pathtype /path/to/file.txt]
puts "Path type: $type"
```

### 20. 返回符號連結指向的檔案或目錄

```
set target [file readlink /path/to/symlink]
puts "Symlink points to: $target"
```

### 21. 重新命名檔案或目錄

```
# 重新命名檔案
file rename /path/to/oldname.txt /path/to/newname.txt

# 強制重新命名檔案(覆蓋目標檔案)
file rename -force /path/to/oldname.txt /path/to/newname.txt
```

### 22. 返回檔案的根名部分(去掉擴展名)

```
set root [file rootname /path/to/file.txt]
puts "Root name: $root"
```

### 23. 返回當前平台的路徑分隔符

```
set sep [file separator]
puts "Path separator: $sep"
```

### 24. 返回檔案的大小（以位元組為單位）

```
set size [file size /path/to/file.txt]
puts "File size: $size bytes"
```

### 25. 將路徑分割成各個組成部分的列表

```
set parts [file split /path/to/file.txt]
puts "Path parts: $parts"
```

### 26. 獲取檔案的資訊

```
file stat /path/to/file.txt info
puts "File info: $info"
```

### 27. 返回檔案系統類型

```
set fstype [file system /path/to/file.txt]
puts "File system type: $fstype"
```

### 28. 返回檔案的尾部部分(去掉目錄路徑)

```
set tail [file tail /path/to/file.txt]
puts "Tail: $tail"
```

### 29. 返回檔案的類型

```
set type [file type /path/to/file.txt]
puts "File type: $type"
```


# Reference

+ [OpenOCD（二）：Jim-Tcl&運行&OpenOCD項目設定\_jimtcl-CSDN部落格](https://blog.csdn.net/weixin_45264425/article/details/132018892)
+ [Tcl/Tk學習筆記](https://littlechocho.pixnet.net/blog/post/25151843)
+ [TCL 基本語法與指令 - 3. 資料型態](https://angeloeyez.blogspot.com/2019/03/tcl-2.html)
+ [十二、TCL指令碼-CSDN部落格](https://blog.csdn.net/baidu_38317135/article/details/126241823?spm=1001.2101.3001.6650.15&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-15-126241823-blog-141962715.235%5Ev43%5Epc_blog_bottom_relevance_base7&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-15-126241823-blog-141962715.235%5Ev43%5Epc_blog_bottom_relevance_base7&utm_relevant_index=24#gets_305)
+ [Tcl指令碼：高級技巧和擴展用法-CSDN部落格](https://blog.csdn.net/qq_43167806/article/details/141962715?spm=1001.2101.3001.6650.2&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EYuanLiJiHua%7EPosition-2-141962715-blog-129037513.235%5Ev43%5Epc_blog_bottom_relevance_base7&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EYuanLiJiHua%7EPosition-2-141962715-blog-129037513.235%5Ev43%5Epc_blog_bottom_relevance_base7&utm_relevant_index=5)
