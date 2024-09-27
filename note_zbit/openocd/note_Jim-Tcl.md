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

## `info exists`

檢查變數是否存在

```
if {![info exists counter]} {
    set counter 0
} else {
    incr counter     ;# counter 加 1
}
```


## `incr`

累加變數

```
% incr counter ;# 等同 C-Code 的 'counter++'
```


## `info global`

列出所有全域變數

```
% info global
```

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




# Reference

+ [OpenOCD（二）：Jim-Tcl&運行&OpenOCD項目設定\_jimtcl-CSDN部落格](https://blog.csdn.net/weixin_45264425/article/details/132018892)
+ [Tcl/Tk學習筆記](https://littlechocho.pixnet.net/blog/post/25151843)
+ [TCL 基本語法與指令 - 3. 資料型態](https://angeloeyez.blogspot.com/2019/03/tcl-2.html)


