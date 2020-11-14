SVN
---

# Install

+ ubuntu

    ```bash
    $ sudo apt-get install subversion
    $ svn --version
    ```

+ windows

    - [SlikSVN](https://sliksvn.com/download/)
        > A standalone command-line Subversion client for Windows

    - [TortoiseSVN](https://tortoisesvn.net/downloads.html)
        > windows 的一套 SVN-Client 軟體

# Commands

## Help

```
$ svn　help              # list all commands
$ svn　help　<command>    # list detail of this command
```

## Status

```
$ svn status                # filter ignore list
$ svn status --no-ignore    # no filter
```

## Add

```base
$ svn add --force .  # add files and filter with ignore list
$ svn add *          # add all files without filtering
```

## Delete

```
# 只從svn中忽略, 而不刪除文件
$ svn delete --keep-local [path]
```

## Update

## Commit

## Branch

## Merge

## Revert

恢復到原來的狀態, 不受 SVN 控制

```
$ svn revert [file-path]
```

+ revert all folder

    ```
    $ svn revert --depth=infinity .
    ```

## Tag


## Log

## Blam

# MISC

+ ignore file

    - 使用`-F`通過配置文件來忽略

        ```bash
        $ vi .svnignore
            build
            bin
            gen
            proguard
            .classpath
            .project
            local.properties
            Thumbs.db
            *.apk
            *.ap_
            *.class
            *.dex

        $ svn propset svn:ignore -R -F .svnignore .

        # 每個文件夾內的 bin, gen 等目錄都會被忽略. 所以起名字的時候不要起和忽略的名字相同的文件.
        ```

    - property ignore
        > 使用 `svn propset` 來設置 `svn：ignore`在單獨的目錄, 也可以設置一個值, 文件名或者是表達式.

        ```bash
        $ svn propset svn:ignore *.class .      # ignore class 文件
        ```

        1. ignore folder
            > 不要加斜槓

            ```bash
            $ svn propset svn:ignore bin .  # OK
            $ svn propset svn:ignore /bin . # NG
            $ svn propset svn:ignore bin/ . # NG
            ```

        1. set recursive ignore `-R`

            ```bash
            $ svn propset svn:ignore -R *.class .
            ```

# reference

+ [在linux下，SVN基本的指令](http://dannysun-unknown.blogspot.com/2017/03/linuxsvn.html)
+ [linux下svn命令使用大全](https://pxnet2768.pixnet.net/blog/post/66987519)
+ [使用svn進行文件和文件夾的忽略](https://www.jianshu.com/p/c02d8b335495)

