# Git usage
---
- Upgrade Git version on Ubuntu

    ```
    $ sudo add-apt-repository ppa:git-core/ppa
    $ sudo apt-get update
    $ sudo apt-get install git
    ```
- 換行符號

    1. `AutoCRLF`

        ```
        $ git config --global core.autocrlf true    # 設定成 true 的作用是 commit 時會自動將 CRLF 轉成 LF, checkout 時會自動將 LF 轉成 CRLF
        $ git config --global core.autocrlf input   # 設定成 input 的作用是 commit 時會自動將 CRLF 轉成 LF, checkout 時不轉換
        $ git config --global core.autocrlf false   # 設定成 false 的則是停止自動轉換, 不管 commit 或是 checkout 都不會進行轉換
        ```

    1. `SafeCRLF`
        > 這設定是更加嚴格的過濾換行符, 只要 git add 或是 commit 或是 push 都會過濾

        ```
        $ git config --global core.safecrlf true    # 不允許 有 LF 與 CRLF 混合的檔案
        $ git config --global core.safecrlf false   # 允許 有 LF 與 CRLF 混合的檔案
        $ git config --global core.safecrlf warn    # 允許 有 LF 與 CRLF 混合的檔案, 但是會出現 warning 警告訊息
        ```


- handle MS Word files (https://git-scm.com/book/en/v2/Customizing-Git-Git-Attributes)
    > [Pandoc](https://pandoc.org/installing.html)

    + 新增 `.gitattributes` file

        ```
        # Documents
        *.doc  diff=word
        *.DOC  diff=word
        *.docx diff=word
        *.DOCX diff=word
        *.dot  diff=astextplain
        *.DOT  diff=astextplain
        *.pdf  diff=astextplain
        *.PDF  diff=astextplain
        *.rtf  diff=astextplain
        *.RTF diff=astextplain
        ```

    + 當你要看比較結果時, 如果檔副檔名是`doc`, Git 會使用 `word` 篩檢程式(filter)。什麼是 `word` 篩檢程式呢? 你必須設定它.
       下面你將設定 Git 使用 strings 程式, 把 Word 文檔轉換成可讀的文字檔, 之後再進行比較:

       ```
       $ git config diff.word.textconv catdoc
       ```

    + `*.docx`
        > install **Pandoc**

        > [還能這樣玩？用 git 追蹤 Word 文檔的版本](https://oicebot.github.io/2019/02/18/using-microsoft-word-with-git.html)

        - `.gitconfig`
            > `~/.gitconfig` or `C:\Documents and Settings\user\.gitconfig`

            ```
            [diff "pandoc"]
               textconv=pandoc --to=markdown
               prompt = false
            [alias]
               wdiff = diff --word-diff=color --unified=1
            ```

        - 在 project 根目錄下添加或者編輯文件 `.gitattributes`

            ```
            *.docx diff=pandoc
            *.doc diff=pandoc
            ```

        - display diff

            ```
            $ git log -p --word-diff=color xxx.docx
                or
            $ git wdiff HEAD^   # 比對前一版
            ```

- clone 時把 submodule 一起抓下來

    ```
    $ git clone --recursive url_remote

    # 抓下來才發現 submodule 是空的, 可以用以下指令去抓
    $ git submodule init
    $ git submodule update --recursive

    git submodule init：根據 .gitmodules 的名稱和 URL, 將這些資訊註冊到 .git/config 內,
                        可是把 .gitmodules 內不用的 submodule 移除,
                        使用這個指令並沒辦法自動刪除 .git/config 的相關內容, 必須手動刪除；
    git submodule update：根據已註冊(也就是 .git/config)的 submodule 進行更新, 例如 clone 遺失的 submodule,
                          也就是上一段講的方法, 所以執行這個指令前最好加上 --init；
    git submodule sync：如果 submodule 的 remote URL 有變動, 可以在 .gitmodules 修正 URL,
                        然後執行這個指令, 便會將 submodule 的 remote URL 更正。

    ```

- git save password

    + linux

        ```
        $ git config --global credential.helper 'cache --timeout 86400'
        ```

    + windows

        ```
        git config --global credential.helper wincred
        ```

- 檢查目前 Git 的狀態

    ```
    $ git status

    ps. Untracked files 表示過去在這個 Git Repository 中從未有這支檔案 (unstage)
        使用 git add 這個指令來把它加入追蹤 (change to stage)
    ```

- Git 新增檔案

    ```
    $ git add .             # 將資料先暫存到 staging area, add 之後再新增的資料, 於此次 commit 不會含在裡面.
    $ git add filename
    $ git add modify-file   # 修改過的檔案, 也要 add. (不然 commit 要加上 -a 的參數)
    $ git add -u            # 只加修改過的檔案, 新增的檔案不加入.
    $ git add -i            # 進入互動模式
    ```

- Git 刪除檔案

    ```
    $ git rm filename
    ```

- Git Commit

    ```
    $ git commit
    $ git commit --amend                    # 修改上次的commit, 如果已經 push出去就無法修改
    $ git commit -m 'commit message'
    $ git commit -a -m 'commit -message'    # 將所有修改過得檔案都 commit, 但是 新增的檔案 還是得要先 add.
    $ git commit -a -v                      # -v 可以看到檔案哪些內容有被更改, -a 把所有修改的檔案都 commit
    ```

- Git show

    ```
    $ git show some_branch_name:some_file_name.js     # show 特定檔案在特定分支的內容
    $ git show some-branch-name:some-file-name.js > deleteme.js
    ```

- Git Tag

    ```
    $ git tag v1 ebff       # log 是 commit ebff810c461ad1924fc422fd1d01db23d858773b 的內容, 設定簡短好記得 Tag: v1
    $ git tag 中文 ebff     # tag 也可以下中文, 任何文字都可以
    $ git tag -d 中文       # 把 tag=中文 刪掉
    ```

- Git merge 合併

    ```
    $ git merge
    $ git merge master
    $ git merge new-branch
    $ git merge <branch_name>           # 合併另一個 branch, 若沒有 conflict 衝突會直接 commit。若需要解決衝突則會再多一個 commit。
    $ git merge --squash <branch_name>  # 將另一個 branch 的 commit 合併為一筆, 特別適合需要做實驗的 fixes bug 或 new feature, 最後只留結果。合併完不會幫你先 commit。
    $ git cherry-pick 321d76f           # 只合併特定其中一個 commit。如果要合併多個, 可以加上 -n 指令就不會先幫你 commit, 這樣可以多 pick幾個要合併的 commit, 最後再 git commit 即可
    ```

- Git diff

    ```
    $ git diff master                   # 與 Master 有哪些資料不同
    $ git diff --cached                 # 比較 staging area 跟本來的 Repository
    $ git diff tag1 tag2                # tag1, 與 tag2 的 diff
    $ git diff tag1:file1 tag2:file2    # tag1, 與 tag2 的 file1, file2 的 diff
    $ git diff                          # 比較 目前位置 與 staging area
    $ git diff --cached                 # 比較 staging area 與 Repository 差異
    $ git diff HEAD                     # 比較目前位置 與 Repository 差別
    $ git diff new-branch               # 比較目前位置 與 branch(new-branch) 的差別
    $ git diff --stat
    $ git diff --name-only --cached     # get the staged files list
    $ git diff –-name-only -b branchA branchB  # 列出兩個branch的差異檔案
    ```

- Git stash
    ```
    $ git stash                # 暫存目前所有檔案狀態到 stack, 並 checkout 到 HEAD (概念上就是保存一份 patch)
    $ git stash -u "my Commit" # 將 Untracked的檔案一併暫存起來
    $ git stash list           # 列出目前暫存的列表
      stash@{0}: WIP on dog: 053fb21 add dog 2
      stash@{1}: WIP on cat: b174a5a add cat 2

    $ git stash pop           # 將暫存的檔案 pop出來(從編號最小的優先),套用成功之後,那個 Stash就會被刪除
    $ git stash pop stash@{1} # 喚回需要的暫存

    $ git stash apply stash@{0} # 套用暫存到現在的分支上,但 Stash不會刪除

    $ git stash drop stash@{0}　# 刪除暫存
    ```

- Git blame

    ```
    $ git blame filename            # 關於此檔案的所有 commit 紀錄, 可以顯示檔案每行修改的人
    $ git log -L 1,1:some_file.txt  # 修改 line 1 ~ line 1 的 commit
    ```

- Git reset 還原

    ```
    $ git reset HEAD filename       # 從 staging area 狀態回到 unstaging 或 untracked (檔案內容並不會改變)
    $ git reset --hard HEAD         # 還原到最前面
    $ git reset --hard HEAD~3
    $ git reset --soft HEAD~3
    ```

- Git bisect 二分法尋找有錯誤的 commit
    1. `$ git bisect start` # 告訴git開始執行2分法。
    2. `$ git bisect good some-commit-hash` # 告訴git哪一個commit是正常的(例如在你休假前最後一個commit)。
    3. `$ git bisect bad some-commit-hash` # 告訴git哪一個commit是壞掉的(例如目前master分支最新的commit)。
        `git bisect bad HEAD`(HEAD 表示為最新的commit).
        >　此時會切換到好與壞的commit中間點, 你必須確認這個中間點commit是否是正常的.
        如果是壞掉的再次執行git bisect bad告訴git這個commit是壞掉的.
        接著會在切換到一個新的commit, 再次確認後, 確定這個commit是正常的, 使用git bisect good告訴git這個commit是正常的.
        當你找到開始出問題的commit, git bisect就已經完成任務了.

    4. `$ git bisect reset` # 回到你一開始執行git bisect的commit(例如你是在master分支最新的commit執行的)
    5. `$ git bisect log`   # 顯示git bisect最後一次成功的紀錄.

- Git remote 維護遠端檔案

    ```
    $ git remote
    $ git remote add new-branch http://git.example.com.tw/project.git       # 增加遠端 Repository 的 branch(origin -> project)
    $ git remote show                                                       # 秀出現在有多少 Repository
    $ git remote rm new-branch                                              # 刪掉
    $ git remote update                                                     # 更新所有 Repository branch
    $ git branch -r                                                         # 列出所有 Repository branch
    ```

- Git branch

    ```
    git branch                              # 列出目前有多少 branch
    git branch new-branch                   # 產生新的 branch (名稱: new-branch), 若沒有特別指定, 會由目前所在的 branch / master 直接複製一份.
    git branch new-branch master            # 由 master 產生新的 branch(new-branch)
    git branch new-branch v1                # 由 tag(v1) 產生新的 branch(new-branch)
    git branch -d new-branch                # 刪除 new-branch
    git branch -D new-branch                # 強制刪除 new-branch
    git checkout -b new-branch test         # 產生新的 branch, 並同時切換過去 new-branch
    git branch -r                           # 列出所有 Repository branch
    git branch -a                           # 列出所有 branch
    git branch -m old-branch new-branch     # old-branch 的名字改成 new-branch
    git branch -m new-branch                # 已經在 old-branch, 想要直接把名字改成 new-branch
    git branch --set-upstream branch        # 遠端branch 將一個已存在的 branch 設定成 tracking 遠端的branch。
    ```

- Git checkout 切換 branch

    ```
    $ git checkout branch-name              # 切換到 branch-name
    $ git checkout master                   # 切換到 master
    $ git checkout -b new-branch master     # 從 master 建立新的 new-branch, 並同時切換過去 new-branch
    $ git checkout -b newbranch             # 由現在的環境為基礎, 建立新的 branch
    $ git checkout -b newbranch origin      # 於 origin 的基礎, 建立新的 branch
    $ git checkout filename                 # 還原檔案到 Repository 狀態
    $ git checkout HEAD .                   # 將所有檔案都 checkout 出來(最後一次 commit 的版本), 注意, 若有修改的檔案都會被還原到上一版. (git checkout -f 亦可)
    $ git checkout xxxx .                   # 將所有檔案都 checkout 出來(xxxx commit 的版本, xxxx 是 commit 的編號前四碼), 注意, 若有修改的檔案都會被還原到上一版.
    $ git checkout -- *                     # 恢復到上一次 Commit 的狀態(* 改成檔名, 就可以只恢復那個檔案)
    ```
- Git rev-list
    > Lists commit objects in reverse chronological order.

    ```
    # Checkout out by date
    # option `-1`: how many items to list
    $ git checkout `git rev-list -1 --before="2012-01-15 12:00" master`
        or
    $ git rev-list -1 --before="2012-01-15 12:00" master | xargs -Iz git checkout z

    ```

- Git log

    ```
    $ git log                                                   # 將所有 log 秀出
    $ git log --graph                                           # 將所有 log 秀出
    $ git log --all                                             # 秀出所有的 log (含 branch)
    $ git log -p                                                # 將所有 log 和修改過得檔案內容列出
    $ git log -p filename                                       # 將此檔案的 commit log 和 修改檔案內容差異部份列出
    $ git log --name-only                                       # 列出此次 log 有哪些檔案被修改
    $ git log --stat --summary                                  # 查每個版本間的更動檔案和行數
    $ git log filename                                          # 這個檔案的所有 log
    $ git log directory                                         # 這個目錄的所有 log
    $ git log -S'foo()'                                         # log 裡面有 foo() 這字串的.
    $ git log --no-merges                                       # 不要秀出 merge 的 log
    $ git log --since="2 weeks ago"                             # 最後這 2週的 log
    $ git log --pretty=oneline                                  # 秀 log 的方式
    $ git log --pretty=short                                    # 秀 log 的方式
    $ git log --pretty=format:'%h was %an, %ar, message: %s'
    $ git log --pretty=format:'%h : %s' --graph                 # 會有簡單的文字圖形化, 分支等.
    $ git log --pretty=format:'%h : %s' --topo-order --graph    # 依照主分支排序
    $ git log --pretty=format:'%h : %s' --date-order --graph    # 依照時間排序

    [alias] -- at .gitconfig
    mylog1 = log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all
    mylog2 = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all
    ```

- Git rename

    ```
    $ git mv <old name> <new name>      # need to re-commit
        if error "fatal: renaming ‘foldername’ failed: Invalid argument"
        => $ git mv foldername tempname && git mv tempname folderName
    ```

- Git mergetool
    > when CONFLICT happens
    >> 修改後存檔離開, 會自動 resolved conflict。
        若無修改離開也會自動 resolved conflict, 並維持衝突的內容。

    ```
    <<<<<<< HEAD
    boycott
    =======
    chocolate
    >>>>>>> C


    <<<<<<< 到 ======= 之間為 local branch data
    ======= 到 >>>>>>> 之間則為 merged branch data
    ```

    + set diff tool with vimdiff
        ```
        $ git config --global merge.tool vimdiff
        $ git config --global difftool.prompt false
        $ git config --global alias.d difftool  # optional, set alias cmd 'git d == git difftool'
        ```

    + layout
        ```
        +--------------------------------+
        | LOCAL  |     BASE     | REMOTE |
        +--------------------------------+
        |             MERGED             |
        +--------------------------------+

        LOCAL : 目前 branch的內容
        BASE  : 兩個衝突 nodes 的 parent node 內容
        REMOTE: 要 merge 的 branch內容
        MERGED: 顯示檔案目前的結果
        ```

    + Resolving conflict
        1. move between differences
            ```
            // in merged window
            command
                [c              jump to previous hunk
                ]c              jump to next hunk
            ```
        2. select version
            > your cursor should between `<<<<<<< HEAD` and `>>>>>>>` in merged window
            ``` vim
            :diffget RE  " get from REMOTE
            :diffget BA  " get from BASE
            :diffget LO  " get from LOCAL
            ```

        3. `diffupdate`
            > Update the diff and restore the cursor position

        4. `:wqa`
            > a fast way to Save the file and quit

        5. 確定全部都用 remote 的版本為準時
            ```
            $ git checkout --theirs <conflict file>
            ```

        6. 確定全部都用 local 的版本為準時
            ```
            $ git checkout --ours <conflict file>
            ```

        7. 在 pull 遇到衝突時, 確定全部都用 remote 的版本為準時
            ```
            $ git checkout origin/master <conflict files>
            ```

- Git mergetool with p4merge (GUI)

    + difftool

        ```
        $ git config --global diff.tool p4merge
        $ git config --global difftool.p4merge.path "$PROGRAMFILES\Perforce\p4merge.exe"
        $ git config --global difftool.prompt false  # disable comfirm window

        $ git difftool
        ```

    + mergetool

        ```
        $ git config --global mergetool.keepBackup false    # disable backup
        $ git config --global merge.tool p4merge
        $ git config --global mergetool.p4merge.cmd  "$PROGRAMFILES\Perforce\p4merge.exe $LOCAL $REMOTE $BASE $MERGED"
        $ git config --global mergetool.p4merge.trustExitCode true

        $ git mergetool
        ```

- Git apply / Git am  (加入patch)
    + patch 由 git diff 產生

        ```
        $ git diff > yyy.patch
        ps. 類似UNIX更新文件的操作, 單純修改檔案
        ```

        - 合併 patch
            `$ git apply /xxx/yyy.patch`
            ps. git apply會一次性將差異全部補齊

            在實際打補丁之前, 可以先用 git apply --check 查看補丁是否能夠乾淨順利地應用到當前分支中：
            `$ git apply --check yyy.patch`
            error: patch failed: ticgit.gemspec:1
            error: ticgit.gemspec: patch does not apply
            ps. 如果沒有任何輸出, 表示我們可以順利採納該補丁。
                如果有問題, 除了報告錯誤資訊之外, 該命令還會返回一個非零的狀態, 所以在 shell 腳本裡可用於檢測狀態。

        - 有error時:
            把沒有衝突的文件先合併了, 剩下有衝突的作標記。
            `$ git apply --reject yyy.patch`

    + patch 由 format-patch 生成

        ```
        a) 兩個節點之間的提交：
            $ git format-patch node_A node_B
        b) 單個節點：
            $ git format-patch -1 node_A （-n就表示要生成幾個node的提交）
        c) 最近一次提交節點的patch：
            $ git format-patch HEAD^ (依次類推……)

        ps. git format-patch 是 git專有, 會根據提交的 node一個節點一個 patch。
        ```

        1. 合併 patch
            $ git am yyy.patch
            ps. git am 會連同 patch作者的 history一併補上 (多了一個 patch作者 history的 commint記錄)

        2. 對於打過的補丁又再打一遍, 會產生衝突, 因此加上 -3 選項, git會很聰明地告訴我, 無需更新, 原有的補丁已經應用。
            $ git am -3 yyy.patch

    + linux cmd
    > $ patch -p0 < your.patch

- Git 匯出

    ```
    利用 git archive 這個 Git 內建命令來產生本次變更的所有檔案
    $ git archive --output=files.tar HEAD $(git diff-tree -r --no-commit-id --name-only --diff-filter=ACMRT HEAD)
        or
    $  git archive -o ./updated.tar HEAD $(git diff --name-only HEAD^)

    匯出某兩次commit的差異檔案
    $ git archive -o ./updated.tar COMMIT_ID_1 $(git diff --name-only COMMIT_ID_1 COMMIT_ID_2)

    匯出最新版本
    $ git archive --format=tar.gz --prefix=folder_name/ HEAD > export.tar.gz
    ```

- Git cherry-pick
    ```
    # from server
    git fetch ssh://name@code.gerrit.com:888/kernel/linux refs/changes/11/64307/1 && git cherry-pick FETCH_HEAD
    ```
+ Git clean
    ```
    # 刪除所有不在 repository 內的目錄及檔案
    $ git clean -fxd
    ```

+ Git clear history
    ```
    # Checkout
    $ git checkout --orphan [new_branch]

    # Add all the files
    $ git add -A

    # Commit the changes
    $ git commit -am "commit message"

    # Delete the branch
    $ git branch -D master

    # Rename the [new_branch] branch to master
    $ git branch -m master

    Finally, force update your repository
    $ git push -f origin master
    ```

+ Git rebase
    ```
    # current history
    $ git log --oneline
    27f6ed6 (HEAD -> master) add dog 2
    2bab3e7 add dog 1
    ca40fc9 add 2 cats
    1de2076 add cat 2
    cd82f29 add cat 1
    382a2a5 add database settings
    bb0c9c2 init commit
    ```

    - delete commit
        ```
        # start at 'bb0c9c2' node
        $ git rebase -i bb0c9c2
        pick 382a2a5 add database settings  # the order will be inverse
        pick cd82f29 add cat 1
        pick 1de2076 add cat 2
        pick ca40fc9 add 2 cats
        pick 2bab3e7 add dog 1
        pick 27f6ed6 add dog 2

        ps. you should edit the above list (delete node or re-order) and save.
            It will start rebase when you exit
        ```

        1. you should care the relation of the creation and modification (create first)

        1. if conflict, you can over write the conflict files and continue re-base flow
            ```
            $ cp ~/xxxx/some_files ./conflict_files
            $ git add/rm <conflicted_files>
            $ git rebase --continue
            ```


# tig

+ `q`
    > leave

+ tree view
    > 直接查看 commit 當時的 repo 檔案內容, 省去 git checkout 的麻煩

    - main view 底下對選中的 commit 按 `t`

+ status view

    - `u`
        > 檔案加入或移出這次的 commit

    - `@`
        > 往下選 chunk

    - `1`
        > 只加入單行的修改

+ ref
    - [Tig: text-mode interface for Git](https://jonas.github.io/tig/)
    - [tig - git 的命令列好夥伴](http://blog.kidwm.net/388)

# Repo usage
---
+ repo help
    > repo help COMMAND

+ repo status
    > 顯示所有project的狀態

+ repo init -u URL
    > 用來在目前目錄安裝下載整個Android repository, 會下建立一個".repo"的目錄。

    - **-u**: 用來指定一個URL, 從這個URL中獲取repository的manifest文件。
        例如：repo init -u git://android.git.kernel.org/platform/manifest.git, 獲取的manifest文件放在.repo目錄中, 命名為manifest.xml。
        這個文件的內容其實就是Android work space下所有被git管理的git repository的列表！

        如果你有仔細看, 可以發現到.repo/manifests是個被git管理的repository, 裡面放著所有的manifest文件 (*.xml)。
        而透過參數的設定, 則可以指定要使用哪個manifest文件, 甚至是該文件的不同branch。

    - **-m**：用來選擇獲取 repository 中的某一個特定的 manifest 文件。如果不具體指定, 那麼表示為預設的 manifest 文件 (default.xml)

        ```
        repo init -u git://android.git.kernel.org/platform/manifest.git -m dalvik-plus.xml
        or
        repo init -m proj20151031.xml  # You must put proj20151031.xml to .repo/manifests/
        ```
    - **-b**：用來指定某個manifest 分支。

        ```
        repo init -u git://android.git.kernel.org/platform/manifest.git -b release-1.0
        ```

    - download tag projects

        ```
        repo init -u git@url_manifest.git -b refs/tags/tag_v1.3
        ```

    - **options**:
        1. `-u URL, --manifest-url=URL`:
                            manifest repository location

        1. `-b REVISION, --manifest-branch=REVISION`:
                            manifest branch or revision

        1. `-m NAME.xml, --manifest-name=NAME.xml`:
                            initial manifest file

        1. `--mirror`:            mirror the forrest

        1. `--reference=DIR`:     location of mirror directory

        1. `--depth=DEPTH`:       create a shallow clone with given depth; see git clone

        1. `-g GROUP, --groups=GROUP`: restrict manifest projects to ones with a specified group

        1. `-p PLATFORM, --platform=PLATFORM`:
                            restrict manifest projects to ones with a
                            specifiedplatform group
                            [auto|all|none|linux|darwin|...]


+ repo sync [PROJECT_LIST]
    > 下載最新文件, 更新成功後, 文件會和遠端server中的代碼是一樣的。
      可以指定需要更新的project, 如果不指定任何參數, 則會同步整個所有的project。

    > 沒有指定 –local-only 選項, 那麼就對保存在變量 all_projects 中的 AOSP子項目進行網絡更新,
      也就是從遠程倉庫中下載更新到本地倉庫來, 這是通過調用Sync類的成員函數_Fetch來完成的

    - **Options**:
        1. `-h, --help`:             show this help message and exit
        1. `-f, --force-broken`:     continue sync even if a project fails to sync
        1. `-l, --local-only`:       only update working tree, don't fetch
        1. `-n, --network-only`:     fetch only, don't update working tree
        1. `-d, --detach`:           detach projects back to manifest revision
        1. `-c, --current-branch`:   fetch only current branch from server
        1. `-q, --quiet`:            be more quiet
        1. `-j JOBS, --jobs=JOBS`:   projects to fetch simultaneously (default 1)

        1. `-m NAME.xml, --manifest-name=NAME.xml`:
                                    temporary manifest to use for this sync

        1. `--no-clone-bundle`:      disable use of /clone.bundle on HTTP/HTTPS
        1. `-s, --smart-sync`:       smart sync using manifest from a known good build

        1. `-t SMART_TAG, --smart-tag=SMART_TAG`:
                                    smart sync using manifest from a known tag

        1. `-u MANIFEST_SERVER_USERNAME, --manifest-server-username=MANIFEST_SERVER_USERNAME`:
                                    username to authenticate with the manifest server

        1. `-p MANIFEST_SERVER_PASSWORD, --manifest-server-password=MANIFEST_SERVER_PASSWORD`:
                                    password to authenticate with the manifest server

+ repo upload [PROJECT_LIST]
    > 上傳修改的代碼 , 如果你的代碼有所修改, 那麼在運行 repo sync 的時候, 會提示你上傳修改的代碼。
      所有修改的代碼分支會上傳到 Gerrit, Gerrit 收到上傳的代碼, 會轉換為一個改動, 從而可以讓人們來review 修改的代碼。


    - 使用帶有 --amend 參數

        ```
        $ git add xxx.c
        $ git commit --amend [-a]
        ```
    > 預設的編輯器會出現, 裡面會包含上一次提交的訊息內容, 將訊息修改/儲存變更並離開編輯器。<br>
    >
        ```
        修改預設編輯器
        $ git config --global core.editor vim
        ```

    - 重新 upload to Gerrit
    >
        ```
        $ repo upload .
        ```

+ repo diff [PROJECT_LIST]
    > 顯示尚未commit的改動差異

+ repo download [target] [revision]
    > 下載指定的修改版本

    ```
    下載修改版本為 1241 的代碼。
    $ repo download platform/frameworks/base 1241
    ```

+ repo start new_branch_name [PROJECT_LIST]
    > 在指定的project中建立新的branch, 並且切換到該branch上。
    >> --all：代表指定所有的git projects

+ repo prune [PROJECT_LIST]
    > 刪除已經 merge好的project。

+ repo forall -p [PROJECT_LIST] -c [COMMAND]
    > 針對指定的project執行`-c`所帶入的 command, 這個被執行的命令就不限於僅僅是 git命令了, 而是任何被系統支持的命令, 比如：ls, pwd, cp 等

    ```
    將所有project中的改動全部都清掉。
    $ repo forall -p -c git reset --hard HEAD
    ```

    - create tag for all projects

        ```
        repo forall -p -c git tag tag_v1.3
        repo forall -p -c git push origin --tags
        ```
+ create manifest

    ```
    $ cd manifest
    $ cp default.xml target_manifest.xml
    $ vi ./target_manifest.xml
        # modify target_manifest.xml
        # revision="refs/tags/tag_v1.3"

        # you also can add to default attribute of xml
        <default revision="refs/tags/tag_v1.3"
                remote="aosp"
                sync-j="4" />

    $ git add target_manifest.xml
    $ git commit -m "release v1.3"
    $ git push original master
    ```

+ repo manifest -r -o xxx.xml
    - generate revision xml file

    - manifest.xml Format

        + Element `remote`
            - Attribute **name**: A short name unique to this manifest file.
            - Attribute **fetch**: The Git URL prefix for all projects which use this remote.
            - Attribute **push**: The Git URL prefix for all projects which use this remote.
            - Attribute **review**: Host-name of the Gerrit server where reviews are uploaded to by "repo upload".
        + Element `default`
            - Attribute **remote**: Element <remote->name>
            - Attribute **revision**: focus branch name in all project
        + Element `project`
            - Attribute **name**:       project name on Remote
            - Attribute **path**:       relative path to the .repo
            - Attribute **revision**:   The version which wants to track for this project. It can be a branch name(HEAD)/tags/SHA-1.
            - Attribute **clone-depth**: history depth when git clone in a project
        - ...

        ```
        e.g.
            <?xml version='1.0' encoding='utf-8'?>
            <manifest>
              <remote fetch="ssh://review.gerrithub.io/Open-TEE" name="origin" review="https://review.gerrithub.io/Open-TEE" />
              <default remote="origin" revision="master" clone-depth="1" />
              <project name="project" path="test_OpenTEE/project" >
                <copyfile src="README.md" dest="test_OpenTEE/README" />
              </project>
              <project name="libtee" path="test_OpenTEE/libtee" />
              <project name="libtee_pkcs11" path="test_OpenTEE/libtee_pkcs11" />
            </manifest>
        ```

# git server authentication

manifests of projects

+ generate SSH key

    ```
    $ ssh-keygen -t rsa -C "your mail address"
    ```

+ add SSH key (**id_rsa.pub**) to gitlab server
    > profile settings -> SSH Key

+ try to communicate gitlab server

    ```
    $ ssh -T git@gitlabserver.vangotech.com
    ...
    Welcome to GitLab
    ```

+ download `repo`

    ```
    $ mkdir ~/.bin
    $ curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.bin/repo
    $ sudo chmod a+x ~/.bin/repo
    $ PATH=$PATH:~/.bin
    ```

+ download source code

    ```
    $ repo init -u git@gitlabserver.com:My/manifests.git -b master -m default.xml
    $ repo sync
    $ repo start local --all
    ```

# windows download code

+ install `python2.7` to `C:\\`
    - [python 2.7](https://www.python.org/ftp/python/2.7/python-2.7.amd64.msi)
    - add python to environment `PATH`
        > `C:\Python27` and `C:\Python27\Scripts`

+ download `repo` command

    ```
    $ curl https://storage.googleapis.com/git-repo-downloads/repo > /C/Users/[user-name]/AppData/Local/Programs/Git/mingw64/bin
        or
    $ curl https://storage.googleapis.com/git-repo-downloads/repo > ~[your-git-path]/Git/mingw64/bin
    ```

+ execute `~[your-git-path]/Git/git-bash.exe` with `Administrator` permission

+ download source code

    ```
    $ repo init -u git@gitlabserver.vangotech.com:SW/manifests.git -b master -m phoenix.xml
    $ repo sync
    $ repo start local/test --all
    ```

+ misc
    - install repo

        ```shell
        $ curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
        $ chmod a+x ~/bin/repo
        $ ~/bin/repo
            error: repo is not installed.  Use "repo init" to install it here. # repo be not installed
        $ repo init
            Get https://gerrit.googlesource.com/git-repo/clone.bundle
            fatal: manifest url (-u) is required.                               # install success but need a url of manifest repository
        ```

        1. repo commands (after installed)

            ```shell
            $ repo help
            usage: repo COMMAND [ARGS]
            The most commonly used repo commands are:
              abandon        Permanently abandon a development branch
              branch         View current topic branches
              branches       View current topic branches
              checkout       Checkout a branch for development
              cherry-pick    Cherry-pick a change.
              diff           Show changes between commit and working tree
              diffmanifests  Manifest diff utility
              download       Download and checkout a change
              grep           Print lines matching a pattern
              info           Get info on the manifest branch, current branch or unmerged branches
              init           Initialize repo in the current directory
              list           List projects and their associated directories
              overview       Display overview of unmerged project branches
              prune          Prune (delete) already merged topics
              rebase         Rebase local branches on upstream branch
              smartsync      Update working tree to the latest known good revision
              stage          Stage file(s) for commit
              start          Start a new branch for development
              status         Show the working tree status
              sync           Update working tree to the latest revision
              upload         Upload changes for code review
            See 'repo help <command>' for more information on a specific command.
            See 'repo help --all' for a complete list of recognized commands.
            ```
        1. manifests.git
            > 建立 manifest.xml 的 repository, 並用 git 管理
            >> you can reference the directory of android

                ```shell
                # google example
                $ repo init -u https://android.googlesource.com/platform/manifest.git
                    or
                $ repo init -u ssh://[user-name]@repo_url
                ```

        1. manifest format 說明
            ```xml
            <!-- example default.xml-->

            <?xml version="1.0" encoding="UTF-8"?>
            <manifest>
                <remote name="aosp"
                        fetch=".."
                        review="https://android-review.googlesource.com/" />
                <default revision="master"
                         remote="aosp"
                         sync-j="4" />

                <include name="base.xml" />

                <project path="adk1/board" name="device/google/accessory/arduino" />
                <project path="adk1/app" name="device/google/accessory/demokit" />
                <project path="adk2012/app" name="device/google/accessory/adk2012" />
                <project path="adk2012/board" name="device/google/accessory/adk2012_demo" />
                <project path="external/ide" name="platform/external/arduino-ide" />
                <project path="external/toolchain" name="platform/external/codesourcery" />
                <remove-project name="adk1/app" />
            </manifest>
            ```

            a. manifest
                > 這個是配置的頂層元素, 即根標誌

            a. remote
                > + name
                >> 在每一個.git/config 文件的 remote 項中用到這個 name,
                即表示每個 git 的 remote name (這個名字很關鍵, 如果多個 remote 屬性的話, default 屬性中需要指定 default remote, 可用 `$ git remote -v` 來確認)。
                git pull and get fetch的時候會用到這個 remote name。

                > + alias
                >> 可以覆蓋之前定義的 remote name, name 必須是固定的, 但是 alias 可以不同, 可以用來指向不同的 remote url

                > + fetch
                >> 所有 git url 真正路徑的前綴, 所有 git 的 project name 加上這個前綴, 就是 git url 的真正路徑

                > + review
                >> 指定Gerrit的服務器名, 用於 repo upload 操作。如果沒有指定, 則 repo upload 沒有效果

            a. default
                > 設定所有　projects　的默認屬性值, 如果在　project　元素裡沒有指定一個屬性, 則使用　default　元素的屬性值。

                > + remote
                >> 遠程服務器的名字(上面 remote 屬性中提到過, 多個 remote 的時候需要指定 default remote, 就是這裡設置了)

                > + revision
                >> 所有 git 的默認 branch, 後面 project 沒有特殊指出 revision 的話, 就用這個branch

                > + sync_j
                >> 在 repo sync 中默認並行的數目

                > + sync_c
                >> 如果設置為 true, 則只同步指定的分支(revision 屬性指定), 而不是所有的 ref 內容

                > + sync_s
                >> 如果設置為 true, 則會同步 git 的子項目

            a. project
                > 需要 clone 的單獨 git

                > + name
                >> git 的名稱, 用於生成 git url。
                URL 格式是：${remote fetch}/${project name}.git 其中的 fetch 就是上面提到的 remote 中的 fetch 元素, name 就是此處的 name

                > + path
                >> clone 到本地的 git 的工作目錄, 如果沒有配置的話, 跟 name 一樣

                > + remote
                >> 定義 remote name, 如果沒有定義的話就用 default 中定義的 remote name

                > + revision
                >> 指定需要獲取的 git 提交點, 可以定義成固定的 branch, 或者是明確的 commit 哈希值

                > + groups
                >> 列出 project 所屬的組, 以空格或者逗號分隔多個組名。所有的 project 都自動屬於`all`組。
                每一個 project 自動屬於 `name:'name'` 和 `path:'path'`組。
                例如 <project name="monkeys" path="barrel-of"/>,
                它自動屬於 `default`, `name:monkeys`, and `path:barrel-of` 組。
                如果一個 project 屬於 notdefault 組, 則, repo sync 時不會下載

                > + sync_c
                >> 如果設置為 true, 則只同步指定的分支(revision 屬性指定), 而不是所有的 ref 內容。

                > + sync_s
                >> 如果設置為 true, 則會同步 git 的子項目

                > + upstream
                >> 在哪個 git 分支可以找到一個 SHA1。用於同步 revision 鎖定的 manifest(-c 模式)。該模式可以避免同步整個ref空間

                > + annotation
                >> 可以有 0 個或多個 annotation, 格式是 name-value, `repo forall` 命令是會用來定義環境變量

            a. include
                > 通過 name 屬性可以引入另外一個 manifest 文件(路徑相對與當前的 manifest.xml 的路徑)

                > + name
                >> 另一個需要導入的 manifest 文件名字

            a. remove-project
                > 從內部的 manifest 表中刪除指定的 project。經常用於本地的 manifest 文件, 用戶可以替換一個 project 的定義
                >> remove 前述已設定的 project, 搭配 `include` 使用

                > + name
                >> 要移除的 project name

            a. manifest-server
                > 它的 url 屬性用於指定 manifest 服務的 URL, 通常是一個 XML RPC 服務

                > 它要支持一下RPC方法
                > + GetApprovedManifest(branch, target)
                >> 返回一個manifest用於指示所有projects的分支和編譯目標。
                    target 參數來自環境變量 TARGET_PRODUCT 和 TARGET_BUILD_VARIANT, 組成 $TARGET_PRODUCT-$TARGET_BUILD_VARIANT

                > + GetManifest(tag)
                >> 返回指定tag的manifest


    - The major purpose of repo and git is one issue one branch, so this is what I do when I fix a bug or modify a new issue.
      and I think will decrease problem during operating repo and git. This is only my work flow, you can still use your own flow too.
      but if use only one branch all the time, please be sure your git tree always synchronous with server to reduce repo problem.

      >1. goto git project directory you want to modify
      >2. $ repo prune .   <-- check local git branch and delete local branch that already merged in amcode server.
      >3. $ repo sync .    <-- sync current project with server.
      >4. $ repo start [issue branch name] .    <-- start a branch for this issue.
      >5. modify code you want
      >6. $ git commit -a
      >7. $ repo upload .  <-- upload current git project to amcode review board.




