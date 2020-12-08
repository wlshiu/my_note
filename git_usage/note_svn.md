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


# Git and SVN

## compare

| git           | svn
| :-:           | :-:
| git add       | svn add
| git commit    | svn commit
| git log       | svn log
| git status    | svn status
| git diff      | svn diff
| git clone     | svn co

# `git-svn`

**使用 git 來操作 svn repository**
> 如果打 `git svn` 報錯, 可能需要 `sudo apt install git-svn` 之類的方式安裝

## Clone

`git svn clone` 等同於 `git svn init` + `git svn fetch`
> 假設呼叫 clone 過程不知道什麼原因停掉了, 可以呼叫 `git svn fetch` 讓它會從上次中斷的地方繼續往下做

+ 從 svn 建立git repo
    > 把 svn 所有commit抓下來, 這個如果 svn repo 很大的話, 需要一些時間, 因此要做好放著讓他跑的準備

    ```
    $ git svn clone https://svnserver/svn/TestGitSvn test  # 建立 test 資料夾, 並將 source code 下載至 test
        or
    $ git svn clone svn://localhost svn -A author.txt --stdlayout --prefix=svn/
    ```

    - `-A`
        > 這個傳入的是那個帳號名稱對應檔 - 在 準備工作 - svn使用者對照表 篇的到的結果檔案

    - `--stdlayout`
        > 表示 svn 使用的是標準方式建立出來, 如果今天不是標準方式建立, 那麼需要自己設定
        > + trunk名稱: `--trunk=`
        > + branch 名稱: `--branches=`
        > + tag 名稱: `--tags=`

    - `--prefix=svn/`
        > 建立出來的 svn 遠端 branch 用 `svn/`作為前戳, 方便區分哪些是 svn 那邊的 remote branch.


## Ignore rule

由於 svn 可能有自定一些 ignore 的規則, 因此當clone完之後, 建議先把 ignore 加進來。

```
$ git svn show-ignore >> .gitignore
$ git add .gitignore
$ git commit -m "add svn ignore list"
```

## Update from SVN repository

同步 local 和 remote 的版本是一致, 類似於 git 裡面的`git pull --rebase`

從 svn 抓取最新的時候, 會自動把 `master` 對最新的做 rebase

```
$ git svn rebase
```

## Commit to SVN repository

等同於 `git push origin master`

```
$ git svn dcommit
```

如果有開 branch, 那麼這個時候應該要用rebase+merge來達到master和branch 合併的時候會是 Fast Forward Merge：

```
$ git checkout branch1
$ git rebase master
$ git checkout master
$ git merge branch1

$ git svn dcommit
```

## Info of SVN repository

```
$ git svn info
```

## 轉存成 git repository mirror

```
$ git remote add origin <git repo url>
$ git push -u origin master
```



# SVN Commands

## Help

```
$ svn　help              # list all commands
$ svn　help　<command>    # list detail of this command
```

## Copy

複製遠端倉儲

```
$ svn co svn+ssh://noob@yourdomain.com/path/foo/repository1
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

## Commit

因為 svn 沒有本地/遠端的概念, 所以你每次 commit 都會丟到遠端

```
$ svn commit -m "initial commit"
```

## Delete

```
# 只從svn中忽略, 而不刪除文件
$ svn delete --keep-local [path]
```

## Branch

創建 branch, 並提交到 remote SVN repository

```
$ svn copy [remote_branch] [new_remote_branch] -m [message]
```

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

+ [在linux下, SVN基本的指令](http://dannysun-unknown.blogspot.com/2017/03/linuxsvn.html)
+ [linux下svn命令使用大全](https://pxnet2768.pixnet.net/blog/post/66987519)
+ [使用svn進行文件和文件夾的忽略](https://www.jianshu.com/p/c02d8b335495)
