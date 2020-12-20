GDB
---

# Compile

## ubuntu

+ ubunut apt update fail

    ```
    $ sudo sed -i -- 's/us.archive/old-releases/g' /etc/apt/source.list
    $ sudo sed -i -- 's/security/old-releases/g' /etc/apt/source.list
    $ sudo apt update
    $ sudo apt install curl

    # 更換公鑰
    $ curl -L https://debian.datastax.com/debian/repo_key | sudo apt-key add

    # 更換 DNS
    $ sudo vi /etc/resolv.conf
        nameserver 8.8.8.8

    ```

+ dependency

    ```
    $ sudo apt install texinfo expat bison flex python python-pip libisl-dev
    $ sudo apt install libiconv-devel zlib-devel ncurses-devel liblzma-devel libexpat-devel libreadline-dev
    ```

+ build `gdb-8.2`

    ```
    $ which python
        /usr/bin/python

    $ cd gdb-8.2
    $ ./configure --enable-targets=all --with-python="/usr/bin/python" --enable-tui --with-system-readline LDFLAGS="-static-libstdc++" --prefix=$HOME/gdb-8.2/out
    ```

    - `--target=arm-linux`
        > 表示生成的 gdb 調試的目標是在 arm 核心 Linux 系統中運行的程序

    - `--enable-targets=all`
        > gdb 可以用同一個版本支持 x86, ppc 等多種體系結構.

        >> 比較新的 bfd 中, 當設置的 target 是 64-bits 或者打開`--enable-targets=all`的時候,
        不需要設置會自動打開這個選項, 不過保險起見還是打開.
        這樣編譯出的 GDB 就能支持 GDB 支持的全部體系結構了.

    - `--enable-64-bit-bfd`

+ 指定使用 arm 硬體
    > 編譯時, 如果使用 `--enable-targets=all`, 需要指定 target 的 arch

    ```
    (gdb) set architecture
        Display all 204 possibilities? (y or n)
        alpha                          m68k:isa-c:nodiv:mac
        alpha:ev4                      m88k:88100
        alpha:ev5                      mep
        alpha:ev6                      mips
        am33                           mips:10000
        am33-2                         mips:12000
        arm                            mips:16
        armv2                          mips:3000
        armv2a                         mips:3900
        armv3                          mips:4000
        armv3m                         mips:4010
        armv4                          mips:4100
        armv4t                         mips:4111
        armv5                          mips:4120
        armv5t                         mips:4300
        ...

    (gdb) set architecture arm
    ```



# reference

+ [gdb 編譯](https://cntofu.com/book/46/gdb/189.md)
+ [windows下編譯gdb源碼](https://blog.csdn.net/pfysw/article/details/105451883)
+ [MSYS2下gdb-8.2編譯安裝](https://www.itread01.com/content/1543864628.html)

