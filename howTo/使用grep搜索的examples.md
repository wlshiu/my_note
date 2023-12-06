# 使用grep搜尋程式碼的幾個示例

作為基於windows系統工作的攻城獅, 每天必須用`sourceinsight`, 這工具確實好用, 關鍵詞和語法著色, 上下文聯想, 程式碼自動補全, 但是也經常發現有些不太方便的地方.
例如: 操作前需要先建立工程, 這也沒什麼, 但是如果只想臨時在某個程式碼包裡, 尋找符號變數什麼的, 也得需要先建立工程;
對於程式碼量很大的項目, 如Android, 工程的建立和解析都很麻煩;
還有就是對二進制搜尋支援不好, 對搜尋的匹配也很有限.

好吧, 剛發現`sourceinsight`還支援正規表示式搜尋, 這個功能什麼時候出現的 ?

搜尋程式碼, 或者是尋找關鍵詞, 除了`sourceinsight`, 那就應該是`grep`了.
可是度娘一下"`grep`"看看你能收到什麼 ?
大多數都是"`grep命令詳解`", "`grep命令和參數的用法`", 要不就是"`grep和正規表示式`",
然後點進去就是給你羅列一大堆`grep`的選項,
要不就是羅列一大堆正規表示式語法, 是羅列, 羅列啊~我TM不想知道`grep`的一大堆選項,
要你說, 運行`man grep`詳細到十萬八千里去了, 我也不想去研究正規表示式的各種語法, 我只想知道如何解決我我遇到的實際問題.

好吧, 搜尋了半天, 也還是解決不了問題, 最好老老實實`man grep`去找答案吧.

下面, 從碼農讀程式碼的角度, 總結下我最常用的`grep`方式, 也歡迎大家交流下`grep`的一些高級用法.

> 讀程式碼時的尋找, 通常比較簡單, 就是想知道某些符號, 在哪個檔案定義或在哪些地方被引用, 都是一些明確的符號,
很少需要模糊尋找, 所以用到複雜正規表示式的機會很少.

免不了囉嗦一下, `grep”的常用的幾個選項:

- `-r`, 遞迴尋找

- `-n`, 搜尋結果顯示行號

- `-i`, 忽略大小寫

- `-v`, 反向匹配

- `-w`, 匹配整個單詞

- `-E`, 匹配擴展的正規表示式

這裡以`u-boot-2016.09`程式碼為例, 進行`memcpy`尋找操作.

## 1. 遞迴尋找並顯示行號

這個是最基本的尋找了.

```
$ u-boot-2016.09$ grep -rn memcpy
```
在當前目錄尋找可以使用:

- 不指定目錄: "`grep -rn memcpy`"
- 用"`.`"指定當前目錄: "`grep -rn memcpy .`"

其實這兩者尋找結果一樣, 但在輸出格式上是有區別的, 具體留給你去比較好了.

## 2. 尋找不區分大小寫

```
$ u-boot-2016.09$ grep -rni memcpy
```

選項"`-i`"或略大小寫, 這樣除了匹配"`memcpy`"外, 還可以匹配一些宏定義如"`MEMCPY`"和"`Memcpy`"等, 如:
```
...
include/malloc.h:351:#define HAVE_MEMCPY
include/malloc.h:353:#ifndef USE_MEMCPY
include/malloc.h:354:#ifdef HAVE_MEMCPY
include/malloc.h:355:#define USE_MEMCPY 1
include/malloc.h:357:#define USE_MEMCPY 0
include/malloc.h:361:#if (__STD_C || defined(HAVE_MEMCPY))
include/malloc.h:365:void* memcpy(void*, const void*, size_t);
...
board/freescale/t102xrdb/spl.c:63:  /* Memcpy existing GD at CONFIG_SPL_GD_ADDR */
board/freescale/t102xrdb/spl.c:64:  memcpy((void *)CONFIG_SPL_GD_ADDR, (void *)gd, sizeof(gd_t));
board/freescale/t208xqds/spl.c:68:  /* Memcpy existing GD at CONFIG_SPL_GD_ADDR */
...
```

## 3. 排除指定檔案的搜尋結果

搜尋結果的第一列, 會顯示搜尋結果位於哪個檔案中, 所以可以通過對搜尋結果第一列的過濾, 來排除指定檔案.

例如: 編譯時生成的`*.o.cmd`檔案中帶了很多包含`memcpy.h`的行, 如:
```
out/rpi_3_32b/drivers/input/.input.o.cmd:295:    $(wildcard include/config/use/arch/memcpy.h)
```

可以在搜尋結果中用反向匹配"`-v`"排除`*.o.cmd`檔案的匹配:
```
$ grep -rn memcpy | grep -v .o.cmd
```

如果想排除多個生成檔案中的匹配, 包括"`*.o.cmd`", "`*.s.cmd`", "`*.o`", "`*.map`"等, 有兩種方式:

- 使用多個`-v`依次對上一次的結果進行反向匹配:

    ```
    $ grep -rn memcpy | grep -v .o.cmd | grep -v .s.cmd | grep -v .o | grep -v .map
    ```

- 使用`-Ev`一次進行多個反向匹配搜尋:

   ```
    $ grep -rn memcpy | grep -Ev '\.o\.cmd|\.s\.cmd|\.o|\.map'
    ```

> 由於這裡使用了正規表示式"`-E`", 所以需要用"`\`"將"`.`"字元進行轉義

另外, 也可以使用"`--exclude=GLOB`"來指定排除某些格式的檔案, 如不在"`*.cmd`", "`*.o`"和"`*.map`"中搜尋:

```
$ grep -rn --exclude=*.cmd --exclude=*.o --exclude=*.map memcpy
```

> 跟"`--exclude=GLOB`"類似的用法有"`--include=GLOB`", 從指定的檔案中搜尋, 如只在"`*.cmd`", "`*.o`"和"`*.map`"中搜尋:
> ```
> $ grep -rn --include=*.cmd --include=*.o --include=*.map memcpy
> ```
> "`--include=GLOB`"在不確定某些函數, 是否被編譯時特別有用.
> 例如, 不確定函數`rpi_is_serial_active`是否有被編譯, 那就尋找`*.o`檔案是否存在這個函數符號:
> ```
> $ grep -rn --include=*.o rpi_is_serial_active
> Binary file out/rpi_3_32b/board/raspberrypi/rpi/built-in.o matches
> Binary file out/rpi_3_32b/board/raspberrypi/rpi/rpi.o matches
> ```
> 顯然, 從結果看, 這個函數是參與了編譯的, 否則搜尋結果為空.
>
> 如果想知道函數`rpi_is_serial_active`最後有沒有被連結使用, 查詢生成的`u-boot*`檔案就知道了:
> ```
> $ grep -rn --include=u-boot* rpi_is_serial_active
> Binary file out/rpi_3_32b/u-boot matches
> ```
> 可見`u-boot`檔案中找到了這個函數符號.

## 4. 不在某些指定的目錄尋找`memcpy`

如果指定了`u-boot`編譯的輸出目錄, 例如輸出到`out`, 則可以直接忽略對`out`目錄的搜尋, 如:

```
$ grep -rn --exclude-dir=out memcpy
```

> 忽略多個目錄(`out`和`doc`):
> ```
> $ grep -rn --exclude-dir=out --exclude-dir=doc memcpy
> ```

## 5. 尋找精確匹配結果

通常的"`memcpy`"尋找結果中會有一些這樣的匹配: "`MCD_memcpy`", "`zmemcpy`", "`memcpyl`", "`memcpy_16`"等, 如果只想精確匹配整個單詞, 則使用`-w`選項:

```
$ grep -rnw memcpy .
```

## 6. 尋找作為單詞分界的結果

`作為單次分界`這個表述不太準確,
例如, 希望"`memcpy`"的尋找中, 只匹配"`MCD_memcpy`", "`memcpy_16`",
而不用匹配"`zmemcpy`", "`memcpyl`"這樣的結果, 也就是`memcpy`以一個完整單詞的形式出現.

一般這種查詢就需要結合正規表示式了, 用正規表示式去匹配單詞邊界, 例如:

```
$ grep -rn -E "(\b|_)memcpy(\b|_)"
```

> 關於正規表示式"`(\b|_)memcpy(\b|_)`"
>
> - "`\b`"匹配單詞邊界
> - "`_`"匹配單個下滑下
>
> 所以上面的表示式可以匹配: `memcpy`, `memcpy_xxx`, `xxx_memcpy`和`xxx_memcpy_xxx`等模式. (可能匹配的還有函數`memcpy_`, `_memcpy`和`_memcpy_`)

## 7. 查看尋找結果的上下文

想在結果中查看匹配內容的前後幾行資訊, 例如想看宏定義"`MEMCPY`"匹配的前三行和後兩行:

```
$ grep -rn -B 3 -A 2 MEMCPY
```
> 選項`B/A`:
> `-B` 指定顯示匹配前(Before)的行數
> `-A` 指定顯示匹配後(After)的行數

## 8. grep 和 find 配合進行尋找

find 針是對檔案等級的粗粒度尋找, 而 grep 則對檔案內容的細粒度搜尋.
所以 grep 跟 find 命令配合, 用 grep 在 find 的結果中進行搜尋, 能發揮更大的作用, 也更方便.

例如, 我想尋找所有`makefile`類檔案中對`CFLAGS`的設定.
`makefile`類常見檔案包括`makefile`, `*.mk`, `*.inc`等, 而且檔案名稱還可能是大寫的.

可以通過 find 命令先找出`makefile`類檔案, 然後再從結果中搜尋`CFLAGS`:

```
$ find . -iname Makefile -o -iname *.inc -o -iname *.mk | xargs grep -rn CFLAGS
```
> 這裡由於涉及到 find 命令, 所以整個尋找看起來有點複雜了, 也可以只用`grep`的`--include=GLOB`選項來實現:
>
> ```
> $ grep -rn --include=Makefile --include=*.inc --include=*.mk CFLAGS .
> ```
>
> 比較上面的兩個搜尋結果, 是一樣的, 但是有一點要注意:
>
> - `grep`命令的`--include=GLOB`模式下, 檔案名稱是區分大小寫的, 而且沒有方式指定忽略檔案名稱大小寫
>
> 剛好這裡搜尋的`Makefile`只有首字母大寫的形式, 而不存在小寫的`makefile`, 所以這裡碰巧是結果一致而已, 否則需要指定更多的`--include=GLOB`參數.

## 9. 一些練習

1. 在 linux 目錄中尋找所有的`*.h`, 並在這些檔案中尋找"`SYSCALL_VECTOR`"

   ```
   $ find linux -name *.h | xargs grep "SYSCALL_VECTOR"
   linux/arch/x86/include/asm/irq_vectors.h:#define IA32_SYSCALL_VECTOR            0x80
   linux/arch/x86/include/asm/irq_vectors.h:# define SYSCALL_VECTOR                        0x80
   linux/arch/m32r/include/asm/syscall.h:#define SYSCALL_VECTOR          "2"
   linux/arch/m32r/include/asm/syscall.h:#define SYSCALL_VECTOR_ADDRESS  "0xa0"
   ```

2. 在練習1的基礎上, 列印出所有包含"`SYSCALL_VECTOR"`字串的檔案名稱
   ```
   $ find linux -name *.h | xargs grep -l "SYSCALL_VECTOR"
   linux/arch/x86/include/asm/irq_vectors.h
   linux/arch/m32r/include/asm/syscall.h
   ```

   `grep`的選項`-l`只列印匹配的檔案名稱.


以上是我的一些`grep`用法, 歡迎交流, 共同提高讀程式碼的效率.

# Reference

+ [使用grep搜尋程式碼的幾個示例](https://github.com/guyongqiangx/blog/blob/dev/20170413-%E4%BD%BF%E7%94%A8grep%E6%90%9C%E7%B4%A2%E4%BB%A3%E7%A0%81%E7%9A%84%E5%87%A0%E4%B8%AA%E7%A4%BA%E4%BE%8B.md)
