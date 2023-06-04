Python
---

[Download](https://www.python.org/downloads/)


# MSYS2

+ Environment

```
$ vim ~/.bashrc
    ...
    Python27=/C/Python27
    PATH="$Python27:$PATH"
```

# libraries

+ numpy
    ```
    $ python -m pip install -U pip numpy
    ```

    - test

    ```
    $ vi ./test_numpy.sh
        #!/usr/bin/env python

        import numpy as np

        x = np.array([1, 2, 3])
        print(x)

        y = np.arange(10)
        print(y)

    $ ./test_numpy.sh
    ```

+ graph

    ```
    $ python -m pip install -U pip setuptools
    $ python -m pip install matplotlib

    # read image file, e.g jpeg, bmp, tiff
    $ python -m pip install pillow
    ```

+ networkx

    ```
    $ python -m pip install networkx
    ```

+ pandas

    ```
    $ python -m pip install pandas
    ```

+ virtualenv

    - install

        ```
        $ pip install virtualenv
            or
        $ sudo apt-get install python3-venv
        ```

    - create virtual environment

        ```
        $ python -m venv test-env
        (test-env) $
        ```

    - 建立虛擬環境並指定 Python 版本
        > 必須先安裝好不同版本的 python

        ```
        $ virtualenv test-env --python=python3.8
        ```

    - 啟動虛擬環境

        ```
        $ source  test-env/bin/activate
        ```

+ distutils

    ```
    $ sudo apt-get install pythonX.Y-distutils
    ```

# configure

+ Python 3.7

    ```
    # add the deadsnakes PPA to sources list
    $ sudo add-apt-repository ppa:deadsnakes/ppa
    $ sudo apt install python3.7

    ```

    1. swithc python3 version

        ```
        $ sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
        $ sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 2
        $ sudo update-alternatives --config python3
            There are 2 choices for the alternative python3 (providing /usr/bin/python3).

              Selection    Path                Priority   Status
            ------------------------------------------------------------
            * 0            /usr/bin/python3.6   2         auto mode
              1            /usr/bin/python3.6   1         manual mode
              2            /usr/bin/python3.7   2         manual mode

            Press <enter> to keep the current choice[*], or type selection number:

        $ sudo rm /usr/bin/python3
        $ sudo ln -s python3.7 /usr/bin/python3
        ```

+ 設置 Python 3 為默認 Python 版本

    ```
    $ sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && alias pip=pip3
    ```

# Debug python

## Python Standard Debugger （pdb）

pdb 是相對簡單的 debug 工具, 適用於中小型的專案. pdb 是一種命令列(command-line)工具, 可以在程式碼中插入斷點, 然後使用 pdb 運作 python 程式.
> 目前所有版本的 Python 都有附加 pdb, 所以可以直接用, 不需要另外安裝, 也能加入擴充, 例如 rpdb 或 pdb++, 增加它的功能

```
$ python -m pdb <target.py>
```


+ 常用命令如下

    - `b 數字`
        > 設置中斷點

    - `r`
        > 繼續執行，直到當前函式返回

    - `c`
        > 繼續執行程式

    - `n`
        > 執行下一行程式

    - `s`
        > 進入函式

    - `p` 變數名稱
        > 印出變數

    - `l` or `ll`
        > 列出目前的程式片段

    - `q`
        > 離開

+ example

    ```
    C:\Users\CecilYang\Desktop>python -m pdb def.py
    > c:\users\cecilyang\desktop\def.py(2)<module>()
    -> def  max(*a):
    (Pdb) b 9
    Breakpoint 1 at c:\users\cecilyang\desktop\def.py:9
    (Pdb) c
    > c:\users\cecilyang\desktop\def.py(9)<module>()
    -> print(max(10,20,11,21,50,40,100,30))
    (Pdb) s
    --Call--
    > c:\users\cecilyang\desktop\def.py(2)max()
    -> def  max(*a):
    (Pdb) n
    > c:\users\cecilyang\desktop\def.py(3)max()
    -> num=0
    (Pdb) n
    > c:\users\cecilyang\desktop\def.py(4)max()
    -> for n in a:
    (Pdb) l
      1     #def.py
      2     def  max(*a):
      3         num=0
      4  ->     for n in a:
      5             if(n>num):
      6                 num=n
      7         return num
      8
      9 B   print(max(10,20,11,21,50,40,100,30))
    [EOF]
    (Pdb) n
    > c:\users\cecilyang\desktop\def.py(5)max()
    -> if(n>num):
    (Pdb) p n
    10
    (Pdb) r
    --Return--
    > c:\users\cecilyang\desktop\def.py(7)max()->100
    -> return num
    (Pdb) n
    100
    --Return--
    > c:\users\cecilyang\desktop\def.py(9)<module>()->None
    -> print(max(10,20,11,21,50,40,100,30))
    (Pdb) n
    --Return--
    > <string>(1)<module>()->None
    (Pdb) n
    The program finished and will be restarted
    > c:\users\cecilyang\desktop\def.py(2)<module>()
    -> def  max(*a):
    (Pdb) q
    ```

## ipdb

improve pdb

```
python -m ipdb <target.py>
```

+ install

    ```
    $ pip install ipdb
    ```

+ 常用命令如下
    > 同 `pdb`

## pudb (linux only)

在 windoes 上會有相容性問題

```
NameError: name 'fcntl' is not defined
```

+ install

    ```
    $ sudo pip install pudb
    $ pip list | grep pudb
    ```

+ prepare in python code
    > 為了支援 pudb, 需要在程式碼中插入

    ```python
    from pudb import set_trace; set_trace()
        or
    import pudb; pu.db
    ```

+ Start Debug

    ```
    $ pudb test.py
        or
    $ python -m pudb.run test.py
    ```

+ 常用命令如下

    - `Ctrl + P`
        > 打開屬性介面

    - `n` next
        > 執行下一步

    - `s` step into
        > 進入函數內部

    - `c` continue
        > 循環中跳出本次循環

    - `t`
        > 運行到 cursor 位置

    - `b` break point
        > 斷點

    - `!` python command line
        > python 控制台

    - `?` help
        > 幫助資訊

    - `o` output screen
        > 打開輸出窗口/控制台


    - `m` module
        > 打開模組

    - `q` quit
        > 退出 PUDB

    - `/`
        > 搜尋

    - `,/.`
        > 搜尋下一個/上一個

# Reference

+ [[Python初學起步走-Day30] - 除錯(使用pdb)](https://ithelp.ithome.com.tw/articles/10161849)
+ pudb
    - [pudb使用指南](http://legendtkl.com/2015/10/31/pudb-howto/)
    - [inducer/pudb -Github](https://github.com/inducer/pudb)
