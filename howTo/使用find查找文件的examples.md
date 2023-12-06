# 使用find尋找程式碼檔案的幾個示例

網上搜尋find命令的用法, 我去, 全是什麼搜尋跟時間, 跟權限相關的用法, 我TM不是維運也不是系統管理員, 不要跟我講find的35種用法, 我不關心這些啊.
花了半天時間, N多篇關於find命令用法的文章看完, 發現還是不能解決問題, 只能說我愚鈍啊.
我只想用find來尋找和查看程式碼, 誰懂我啊...

本篇主要是碼農的日常`find`用法收集, 所以, 如果你是想基於各種時間, 使用者和權限等進行檔案尋找, 抱歉, 本篇並未涉及.

免不了囉嗦一下, `find`的常用的幾個選項:

+ `-name`, 按照指定檔案名稱尋找
+ `-iname`, 按照指定檔案名稱尋找, 並忽略大小寫
+ `-type`, 按照指定檔案類型尋找
+ `-mindepth/maxdepth`, 指定尋找的深度
+ `-size`, 指定尋找檔案大小
+ `-exec`, 對尋找結果進行指定操作
+ `-a/-o`, 多個條件合併尋找
+ `-prune`, 指定排除尋找的條件

## 1. 使用檔案名稱進行尋找

+ 使用檔案名稱尋找檔案

    尋找`u-boot`目錄下包含`rpi`的檔案:

    ```
    $ find . -name *rpi*
    ./configs/rpi_2_defconfig
    ./configs/rpi_defconfig
    ./configs/rpi_3_defconfig
    ./configs/rpi_3_32b_defconfig
    ./board/raspberrypi/rpi
    ./board/raspberrypi/rpi/rpi.c
    ./include/configs/rpi.h
    ```

    這裡沒有指定只尋找檔案, 所以搜尋結果中`./board/raspberrypi/rpi`是目錄.

+ 使用檔案名稱尋找檔案, 並忽略大小寫

    尋找`rootfs`目錄下所有名為`makefile`的檔案, 並忽略大小寫:
    ```
    $ find rootfs -iname makefile
    ...
    rootfs/user/gptfdisk/makefile
    rootfs/user/snmpd/Makefile
    rootfs/user/snmpd/snmplib/Makefile
    rootfs/user/snmpd/modules/Makefile
    rootfs/user/snmpd/snmpd/Makefile
    rootfs/user/fileutils/Makefile
    rootfs/user/stty/Makefile
    rootfs/user/inetd/Makefile
    rootfs/user/cramfs/Makefile
    rootfs/user/cksum/Makefile
    rootfs/user/tftpd/Makefile
    rootfs/user/dhrystone/Makefile
    ...
    ```

+ 使用檔案名稱尋找檔案, 並指定尋找目錄深度

    尋找`rootfs`目錄和其一級子目錄下的`makefile`

    ```
    $ find rootfs -mindepth 1 -maxdepth 2 -iname makefile
    rootfs/host/Makefile
    rootfs/Makefile
    rootfs/lib/Makefile
    rootfs/config/Makefile
    rootfs/user/Makefile
    ```

+ 使用檔案名稱尋找檔案, 並在尋找結果上執行特定操作

    尋找`rootfs`目錄下所有編譯生成的kernel檔案, 並計算其`md5`總和檢查碼

    ```
    $ find rootfs -iname vmlinuz* -exec md5sum {} \;
    928dba467dd79b8b554ff7c3db9eca95  rootfs/images/vmlinuz-7439b0
    c82736b02abe048c633df0923b0ee521  rootfs/images/vmlinuz-initrd-7439b0
    ```

    尋找`rootfs`目錄下所有編譯生成的kernel檔案, 並重新命名備份

    ```
    $ find rootfs -iname vmlinuz* -exec mv {} {}.bak.20170610 \;
    $ find rootfs -iname vmlinuz*
    rootfs/images/vmlinuz-initrd-7439b0.bak.20170610
    rootfs/images/vmlinuz-7439b0.bak.20170610
    ```

+ 尋找名為的`libmediaservice`資料夾

    ```
    $ find . -type d -name libmediaplayerservice
    ./frameworks/av/media/libmediaplayerservice
    ```

## 2. 忽略尋找中的錯誤資訊

將尋找中的錯誤資訊重新導向到`/dev/null`

```
$ find . -type f -name android-6.0.1_*.tgz 2>/dev/null
```

```
$ find /etc -name auto.* -print 2>/dev/null
```

## 3. 按檔案大小進行尋找

尋找當前目錄下所有大於100MB的ISO檔案

```
$ find server -iname *.iso -size +100M
server/ubuntu-14.04.5-desktop-amd64.iso
server/ubuntu-16.04.2-desktop-amd64.iso
```

## 4. 對特定路徑模式的尋找

尋找所有路徑中包含tests的目錄下的`*.dts`檔案:

```
$ find . -name *.dts -path "*/tests/*"
./test/py/tests/vboot/sandbox-kernel.dts
./test/py/tests/vboot/sandbox-u-boot.dts
```

選項`-path "*/tests/*"`指定檔案路徑中包含`tests`的檔案

尋找路徑中包含"tools"或"lib"的`*.py`檔案:

```
$ find . -name *.py \( -path "*/dtoc/*" -o -path "*/lib/*" \)
./lib/libfdt/test_libfdt.py
./lib/libfdt/setup.py
./tools/dtoc/fdt_util.py
./tools/dtoc/fdt.py
./tools/dtoc/dtoc.py
./tools/dtoc/fdt_fallback.py
```

> 使用`-o`連接兩個`-path`選項限定尋找的路徑匹配模式(路徑包含"dtoc"或"lib").

## 5. 在`find`結果中進行`grep`操作

```
$ find linux -name "*.c" | xargs grep functionname
```

## 6. 使用`-prune`進行排除性尋找

選項`-prune`適用於排除性尋找, 最初接觸`find`命令時感覺較難.

之所以難理解, 是因為我們一般習慣語法格式為`-prune xxx`的用法, 即在`-prune`後跟`xxx`來指明排除的條件,
但實際上卻剛好相反, `-prune`的排除條件需要寫在前面, 我曾經為這個用法迷糊了好久.

這裡以Android中檔案`build/envsetup.sh`內對`find`的使用來看`-prune`的用法:

+ 指定檔案中進行`grep`

    ```
    function cgrep()
    {
        find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) \
        -exec grep --color -n "$@" {} +
    }

    ```

    函數`cgrep`僅在當前目錄下C/C++相關的`*.{c, cc, cpp, h, hpp}`後綴的檔案中進行`grep`尋找:

    - 使用`-prune`排除多個目錄, 條件`'-name .repo -prune'`, `'-name .git -prune'`, `'-name out -prune'`;
        分別排除名稱為`.repo`, `.git`和`out`的目錄, 各個排除目錄的條件為"或", 使用`‘-o’`連接

    - 尋找多個後綴的檔案名稱, 條件`-name '*.c'`, `-name '*.cc'`, `-name '*.cpp'`, `-name '*.h'`, `-name '*.hpp'`;
        分別包含後綴為`*.{c, cc, cpp, h, hpp}`的檔案, 各個尋找的檔案名稱的條件為"或", 使用`'-o'`連接

    - 對符合後綴的檔案中進行`grep`操作: `-exec grep --color -n "$@" {} +`

    > 對於`-exec`操作, 有兩種形式:
    > - `-exec command`
    > - `-exec command {} +`
    > 這兩種操作的主要差別在`+`上, 沒搞懂有`+`和沒有`+`的區別, 哪位大神來指導下? 萬分感謝 !

+ 尋找並匯入指定目錄下的`vendorsetup.sh`指令碼

    ```
    # Execute the contents of any vendorsetup.sh files we can find.
    for f in `test -d device && find -L device -maxdepth 4 -name 'vendorsetup.sh' 2> /dev/null | sort` \
        `test -d vendor && find -L vendor -maxdepth 4 -name 'vendorsetup.sh' 2> /dev/null | sort` \
        `test -d product && find -L product -maxdepth 4 -name 'vendorsetup.sh' 2> /dev/null | sort`
    do
        echo "including $f"
        . $f
    done
    ```

    以上操作會先檢查`{device, vendor, product}`目錄是否存在, 如果存在, 在其目錄下尋找`vendorsetup.sh`檔案, 並將其用`.`操作包含到當前的命令列環境中來.

    - `-L`選項表示會進入符號連結內的資料夾下尋找
    - `-maxdepth 4`選項指定尋找深度不超過4層, 所以自訂平台`vendorsetup.sh`指令碼的時候, 存放深度不要太深了啊~~不然找不到哦~

+ `godir`函數中尋找檔案, 但忽略`out`和`.repo`目錄

    ```
    $ find . -wholename ./out -prune -o -wholename ./.repo -prune -o -type f > $FILELIST
    ```
    這裡的`-wholename ./out`和`-wholename ./.repo`等同於`-path ./out`和`-wholename ./.repo`, 由於有`-prune`後綴, 所以相當於排除這兩個目錄


## 7. 一些練習

在linux目錄中尋找所有的`*.h`, 並在這些檔案中尋找"`SYSCALL_VECTOR`", 最後列印出所有包含"`SYSCALL_VECTOR`"的檔案名稱

1. 在標頭檔中尋找"`SYSCALL_VECTOR`"

    ```
    $ find linux -name *.h | xargs grep "SYSCALL_VECTOR"
    linux/arch/x86/include/asm/irq_vectors.h:#define IA32_SYSCALL_VECTOR            0x80
    linux/arch/x86/include/asm/irq_vectors.h:# define SYSCALL_VECTOR                        0x80
    linux/arch/m32r/include/asm/syscall.h:#define SYSCALL_VECTOR          "2"
    linux/arch/m32r/include/asm/syscall.h:#define SYSCALL_VECTOR_ADDRESS  "0xa0"
    ```

2. 只顯示包含"`SYSCALL_VECTOR`"的標頭檔名

    ```
    $ find linux -name *.h | xargs grep -l "SYSCALL_VECTOR"
    linux/arch/x86/include/asm/irq_vectors.h
    linux/arch/m32r/include/asm/syscall.h
    ```

> `grep`的`-l`選項只顯示搜尋的檔案名稱

我會根據讀程式碼時運用的`find`操作, 不定時對本文進行更新, 十分歡迎大神秀出你的絕技, 讓大家能夠受益.

# Reference

+ [使用find尋找程式碼檔案的幾個示例](https://github.com/guyongqiangx/blog/blob/dev/20170610-%E4%BD%BF%E7%94%A8find%E6%9F%A5%E6%89%BE%E4%BB%A3%E7%A0%81%E6%96%87%E4%BB%B6%E7%9A%84%E5%87%A0%E4%B8%AA%E7%A4%BA%E4%BE%8B.md)
