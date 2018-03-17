# Git usage
---
- MS Word files (https://git-scm.com/book/en/v2/Customizing-Git-Git-Attributes)

    1. 新增 .gitattributes file
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

    2. 當你要看比較結果時，如果檔副檔名是`doc`，Git 會使用 `word` 篩檢程式(filter)。什麼是 `word` 篩檢程式呢？你必須設定它。
       下面你將設定 Git 使用 strings 程式，把 Word 文檔轉換成可讀的文字檔，之後再進行比較： 
       ```
       $ git config diff.word.textconv catdoc
       ```

- clone 時把 submodule 一起抓下來
    ```
    $ git clone --recursive url_remote
    
    # 抓下來才發現 submodule 是空的，可以用以下指令去抓
    $ git submodule init
    $ git submodule update --recursive

    git submodule init：根據 .gitmodules 的名稱和 URL，將這些資訊註冊到 .git/config 內，
                       可是把 .gitmodules 內不用的 submodule 移除，
		       使用這個指令並沒辦法自動刪除 .git/config 的相關內容，必須手動刪除；
    git submodule update：根據已註冊(也就是 .git/config)的 submodule 進行更新，例如 clone 遺失的 submodule，
                          也就是上一段講的方法，所以執行這個指令前最好加上 --init；
    git submodule sync：如果 submodule 的 remote URL 有變動，可以在 .gitmodules 修正 URL，
                        然後執行這個指令，便會將 submodule 的 remote URL 更正。

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
    $ git merge <branch_name>           # 合併另一個 branch，若沒有 conflict 衝突會直接 commit。若需要解決衝突則會再多一個 commit。
    $ git merge --squash <branch_name>  # 將另一個 branch 的 commit 合併為一筆，特別適合需要做實驗的 fixes bug 或 new feature，最後只留結果。合併完不會幫你先 commit。
    $ git cherry-pick 321d76f           # 只合併特定其中一個 commit。如果要合併多個，可以加上 -n 指令就不會先幫你 commit，這樣可以多 pick幾個要合併的 commit，最後再 git commit 即可
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
    ```

- Git stash
    ```
    $ git stash         # 暫存目前所有檔案狀態到 stack, 並 checkout 到 HEAD (概念上就是保存一份 patch)
    $ git stash pop     # 將暫存的檔案狀態 pop出來 (將保存的 patch打進來)
    ```

- Git blame

    ```
    $ git blame filename        # 關於此檔案的所有 commit 紀錄
    ```

- Git reset 還原

    ```
    $ git reset HEAD filename       # 從 staging area 狀態回到 unstaging 或 untracked (檔案內容並不會改變)
    $ git reset --hard HEAD         # 還原到最前面
    $ git reset --hard HEAD~3
    $ git reset --soft HEAD~3
    ```

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

- Git apply / Git am  (加入patch)
    + patch 由 git diff 產生

        ```
        $ git diff > yyy.patch
        ps. 類似UNIX更新文件的操作, 單純修改檔案
        ```

    	- 合併 patch
            $ git apply /xxx/yyy.patch
            ps. git apply會一次性將差異全部補齊

            在實際打補丁之前，可以先用 git apply --check 查看補丁是否能夠乾淨順利地應用到當前分支中：
            $ git apply --check yyy.patch
            error: patch failed: ticgit.gemspec:1
            error: ticgit.gemspec: patch does not apply
            ps. 如果沒有任何輸出，表示我們可以順利採納該補丁。
                如果有問題，除了報告錯誤資訊之外，該命令還會返回一個非零的狀態，所以在 shell 腳本裡可用於檢測狀態。

        - 有error時:
            把沒有衝突的文件先合併了，剩下有衝突的作標記。
            $ git apply --reject yyy.patch

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

        2. 對於打過的補丁又再打一遍，會產生衝突，因此加上 -3 選項，git會很聰明地告訴我，無需更新，原有的補丁已經應用。
            $ git am -3 yyy.patch

	+ linux cmd
	> $ patch -p0 < your.patch

- Git 匯出

    ```
    利用 git archive 這個 Git 內建命令來產生本次變更的所有檔案
    $ git archive --output=files.tar HEAD $(git diff-tree -r --no-commit-id --name-only --diff-filter=ACMRT HEAD)

    匯出最新版本
    $ git archive --format=tar.gz --prefix=folder_name/ HEAD > export.tar.gz
    ```

- Git cherry-pick
    ```
    # from server
    git fetch ssh://name@code.gerrit.com:888/kernel/linux refs/changes/11/64307/1 && git cherry-pick FETCH_HEAD
    ```

# Repo usage
---
- repo help
	> repo help COMMAND

- repo status
    > 顯示所有project的狀態

- repo init -u URL
    > 用來在目前目錄安裝下載整個Android repository，會下建立一個".repo"的目錄。

    + **-u**: 用來指定一個URL，從這個URL中獲取repository的manifest文件。
	    例如：repo init -u git://android.git.kernel.org/platform/manifest.git，獲取的manifest文件放在.repo目錄中，命名為manifest.xml。
	    這個文件的內容其實就是Android work space下所有被git管理的git repository的列表！

	    如果你有仔細看，可以發現到.repo/manifests是個被git管理的repository，裡面放著所有的manifest文件 (*.xml)。
	    而透過參數的設定，則可以指定要使用哪個manifest文件，甚至是該文件的不同branch。

    + **-m**：用來選擇獲取 repository 中的某一個特定的 manifest 文件。如果不具體指定，那麼表示為預設的 manifest 文件 (default.xml)

		```
    	repo init -u git://android.git.kernel.org/platform/manifest.git -m dalvik-plus.xml
	    or
	repo init -m proj20151031.xml  # You must put proj20151031.xml to .repo/manifests/
		```
    + **-b**：用來指定某個manifest 分支。

		```
		repo init -u git://android.git.kernel.org/platform/manifest.git -b release-1.0
		```

    + **options**:
        - `-u URL, --manifest-url=URL`:
							manifest repository location

        - `-b REVISION, --manifest-branch=REVISION`:
							manifest branch or revision

        - `-m NAME.xml, --manifest-name=NAME.xml`:
							initial manifest file

        - `--mirror`:            mirror the forrest

        - `--reference=DIR`:     location of mirror directory

		- `--depth=DEPTH`:       create a shallow clone with given depth; see git clone

        - `-g GROUP, --groups=GROUP`: restrict manifest projects to ones with a specified group

        - `-p PLATFORM, --platform=PLATFORM`:
                            restrict manifest projects to ones with a
                            specifiedplatform group
                            [auto|all|none|linux|darwin|...]


- repo sync [PROJECT_LIST]
    > 下載最新文件, 更新成功後, 文件會和遠端server中的代碼是一樣的。
      可以指定需要更新的project, 如果不指定任何參數，則會同步整個所有的project。

	> 沒有指定 –local-only 選項, 那麼就對保存在變量 all_projects 中的 AOSP子項目進行網絡更新,
	  也就是從遠程倉庫中下載更新到本地倉庫來, 這是通過調用Sync類的成員函數_Fetch來完成的

    + **Options**:
        - `-h, --help`:             show this help message and exit
        - `-f, --force-broken`:     continue sync even if a project fails to sync
        - `-l, --local-only`:       only update working tree, don't fetch
        - `-n, --network-only`:     fetch only, don't update working tree
        - `-d, --detach`:           detach projects back to manifest revision
        - `-c, --current-branch`:   fetch only current branch from server
        - `-q, --quiet`:            be more quiet
        - `-j JOBS, --jobs=JOBS`:   projects to fetch simultaneously (default 1)

        - `-m NAME.xml, --manifest-name=NAME.xml`:
                                    temporary manifest to use for this sync

        - `--no-clone-bundle`:      disable use of /clone.bundle on HTTP/HTTPS
        - `-s, --smart-sync`:       smart sync using manifest from a known good build

        - `-t SMART_TAG, --smart-tag=SMART_TAG`:
                                    smart sync using manifest from a known tag

        - `-u MANIFEST_SERVER_USERNAME, --manifest-server-username=MANIFEST_SERVER_USERNAME`:
                                    username to authenticate with the manifest server

        - `-p MANIFEST_SERVER_PASSWORD, --manifest-server-password=MANIFEST_SERVER_PASSWORD`:
                                    password to authenticate with the manifest server

- repo upload [PROJECT_LIST]
    > 上傳修改的代碼 ，如果你的代碼有所修改，那麼在運行 repo sync 的時候，會提示你上傳修改的代碼。
      所有修改的代碼分支會上傳到 Gerrit，Gerrit 收到上傳的代碼，會轉換為一個改動，從而可以讓人們來review 修改的代碼。


    - 使用帶有 --amend 參數

		```
	    $ git add xxx.c
	    $ git commit --amend [-a]
		```
    > 預設的編輯器會出現，裡面會包含上一次提交的訊息內容，將訊息修改/儲存變更並離開編輯器。<br>
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

- repo diff [PROJECT_LIST]
    > 顯示尚未commit的改動差異

- repo download [target] [revision]
    > 下載指定的修改版本

	```
	下載修改版本為 1241 的代碼。
   	$ repo download platform/frameworks/base 1241
	```

- repo start new_branch_name [PROJECT_LIST]
    > 在指定的project中建立新的branch，並且切換到該branch上。
    >> --all：代表指定所有的git projects

- repo prune [PROJECT_LIST]
    > 刪除已經 merge好的project。

- repo forall -p [PROJECT_LIST] -c [COMMAND]
    > 針對指定的project執行`-c`所帶入的 command, 這個被執行的命令就不限於僅僅是 git命令了, 而是任何被系統支持的命令, 比如：ls, pwd, cp 等

	```
	將所有project中的改動全部都清掉。
    $ repo forall -p -c git reset --hard HEAD
	```

- repo manifest -r -o xxx.xml
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
    		- ...

        ```
        e.g.
            <?xml version='1.0' encoding='utf-8'?>
            <manifest>
              <remote fetch="ssh://review.gerrithub.io/Open-TEE" name="origin" review="https://review.gerrithub.io/Open-TEE" />
              <default remote="origin" revision="master" />
              <project name="project" path="test_OpenTEE/project" >
                <copyfile src="README.md" dest="test_OpenTEE/README" />
              </project>
              <project name="libtee" path="test_OpenTEE/libtee" />
              <project name="libtee_pkcs11" path="test_OpenTEE/libtee_pkcs11" />
            </manifest>
        ```

- misc
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



