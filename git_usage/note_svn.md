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

command line 使用 `--username` 自動帶上 user name

```
$ git svn clone svn://your/svn/repo/ --username=xxx
```

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
        or

    # git svn clone -T [指定 SVN trunk 目錄] -b [指定 SVN branches 根目錄] -t [指定 SVN tags 根目錄] <svn repository> [local dir]
    $ git svn clone -T trunk -b branches -t tags https://github.com/xetorthio/jedis.git /develop/code/jedis
    ```

    - `-A`
        > 這個傳入的是那個帳號名稱對應檔 - 在 準備工作 - svn使用者對照表 篇的到的結果檔案

    - `--stdlayout`
        > 表示 svn 使用的是標準方式建立出來, 如果今天不是標準方式建立, 那麼需要自己設定
        > + trunk名稱: `--trunk=`
        > + branch 名稱: `--branches=`
        > + tag 名稱: `--tags=`

        1. svn 標準建立時, 會在 repository 目錄下, 同時建立 trunk/branches/tags 目錄.
            > URL 規則 `svn://<IP>/<svn_project>/<dir_name_1>/<dir_name_2>/...`

            ```
            svn_project/
                ├── trunk
                ├── branches
                └── tags
                    ├── v1.0
                    └── v2.0
            ```

            ```
            # assess tag v1.0
            url= svn://192.168.30.1/svn_project/tags/v1.0

            ```

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
$ git svn dcommit --username=admin
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

## Get remote branch of SVN (not work)

```
$ git svn fetch --all
```

```
$ git config --add svn-remote.newbranch.url https://svn/path_to_newbranch/
$ git config --add svn-remote.newbranch.fetch :refs/remotes/newbranch
$ git svn fetch newbranch [-r<rev>]
$ git checkout -b local-newbranch -t newbranch
$ git svn rebase newbranch
```

+ [git-svn] Change svn repo URL

    不幸遇到需要改變 svn remote repository 的 url. 好不容易找到別人提供的方法, 記錄如下:

    1. 先把專案中的 `.git/config` 裡面的 svn-remote 的 url 改成新的連結.
    1. 執行 `git svn fetch`, 拉取最新的內容.
    1. 換回原先的 url.
    1. 執行 `git svn rebase -l`, 做 local rebase.
        > `-l` 意思是在 local 做 rebase, 而不從 remote 抓取最新的進度.
    1. 再換回新的 url.
    1. 執行 git svn rebase

    順帶說明一下, 一開始我在改變 url 後直接執行 git svn rebase, 得到一個錯誤訊息:

    ```
    Unable to determine upstream SVN information from working tree history
    ```

    所以, 1~4就是讓 local 能對得上 remote. 最後再透過 6 把 local-remote 對上.

+ reference
    - [How do I tell git-svn about a remote branch created after I fetched the repo?](https://stackoverflow.com/questions/296975/how-do-i-tell-git-svn-about-a-remote-branch-created-after-i-fetched-the-repo)
    - [Add an SVN remote to your Git repo](https://coderwall.com/p/vfop7g/add-an-svn-remote-to-your-git-repo)

# SVN Commands

command line 加上參數 `--username` 與 `--password`, 自動帶上帳號密碼

```
$ svn export svn://172.18.41.35/VAD8992_android/AMSS_postCS-1092_LABF64-2820/vad8992_postCS --username Mark --password godofwar --no-auth-cache
$ svn checkout --username user --password pass svn://server/repo
```

ps. `<>` 表示必要, `[]`表示可選

## Help

```
$ svn　help              # list all commands
$ svn　help　<command>    # list detail of this command
```

## CheckOut

從遠端倉儲複製到 local

```
$ svn co svn+ssh://noob@yourdomain.com/path/foo/repository1
$ svn co svn+ssh://noob@yourdomain.com/path/foo/repository1 -r <版本號> [local path]
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
# 只從 svn 中忽略, 而不刪除文件
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

+ update

    ```
    $ svn up -r 10  # 當前的工作版本是版本10
        or
    $ svn up        # 更新到最新的版本
    ```

## List

列出遠端 server 的 directory

```
$ svn list <https://svn_server_repository>
    trunk
    branch
    tags
    ...

$ svn list <https://svn_server_repository/tags>
    TagV1.0
    TagV2.0
    TagV3.0
    ...

$ svn list <https://svn_server_repository/branch>
    Branch_1
    Branch_2
    Branch_3
    ...
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

+ 換行符號

    設定 SVN 配置文件 (等同強制修改目標文件, 需要 commit 進版)

    > + windows: `%APPDATA%\Roaming\Subversion\config`
    > + UNIX:    `~/.subversion/config`

    ```
    [miscellany]
        enable-auto-props = yes

    [auto-props]
        *.java = svn:eol-style=native
        *.c = svn:eol-style=native
        *.h = svn:eol-style=native
        *.mk = svn:eol-style=native
        Makefile = svn:eol-style=native
        Makefile* = svn:eol-style=native
        *.sh = svn:eol-style=native;svn:executable
    ```


# reference

+ [在linux下, SVN基本的指令](http://dannysun-unknown.blogspot.com/2017/03/linuxsvn.html)
+ [linux下svn命令使用大全](https://pxnet2768.pixnet.net/blog/post/66987519)
+ [使用svn進行文件和文件夾的忽略](https://www.jianshu.com/p/c02d8b335495)
+ [SVN 組件及指令](https://lamb-mei.com/40/svn-%E7%B5%84%E4%BB%B6%E5%8F%8A%E6%8C%87%E4%BB%A4/)
