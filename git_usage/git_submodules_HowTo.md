git submodules 使用
---


# 為主項目添加Submodules
+ On git_server
    > + Create projec repo: prj_1.git
    > + Create lib repo: lib_1.git

+ On local
    > + `git clone <prj_1.git>`
    > + `git submodule add -b master <lib_1.git> <destination_path>`
    >> 成功將會被新增file ".gitmodules"

+ On local
    > + `git commit -a -m "add submodules lib_1"`
    > + `git push origin master`


# Clone帶有Submodule的 repo
+ On local
    - 方法一
        > + `git clone <prj_1.git>`
        > + `git submodule init`
        >> `submodule init`即是在`.git/config`中註冊子模塊的信息
        > + `git submodule update`
        >> 執行 update後, 才會真正將 submodule 的部份 clone下來

    - 方法二
        > + `git clone --recursive <prj_1.git>`
        >> `--recursive`參數的含義：可以在 clone 項目時同時 clone 關聯的 submodules。

# 修改Submodule

`git submodule` 做了3件事情
> + 記錄引用的倉庫
> + 記錄主項目中Submodules的目錄位置
> + 記錄引用Submodule的SHA1_id

因此需要到 submodule裡, 操作自己的 repo

+ On local
    > + `cd <submodule_path>`
    > + `git checkout <branch>`
    > + `git commit -a -m "update submodule context"`

+ On local submodule_directory
    > + `git push origin <branch>`
    >> 更新到 remote端 <lib_1.git> repo

+ On local project_directory
    > + `git commit -a -m "update libs/lib_1 to lastest SHA1 id"`
    > + `git push origin master`
    >> 更新 submodule引用的 SHA1 id到 remote端 <prj_1.git> repo


# 同步主項目的Submodules

+ On local project_directory
    > + `git pull origin <branch>`
    >> 同步 submodule 引用的 SHA1 id到 local project, 但 submodule 尚未同步

+ On local project_directory
    > + `git submodule init`
    >> `submodule init` 同步 `.git/config`中子模塊的註冊信息
    > + `git submodule update`
    >> 真正同步 submodule 的 context


# 批次同步 Submodules

+ On local project_directory

    - git support
        > + `git submodule foreach git pull`
        >> 循環進入(enter)每個子模塊的目錄，然後執行foreach後面的命令,
        該後面的命令可以任意的，例如 `git submodule foreach ls -l` 可以列出每個子模塊的文件列表

    - 撰寫 shell
        > + 新增 shell file: `update-submodules.sh`
        > + shell file context
        >> 先把子模塊的路徑寫入到文件`/tmp/study-git-submodule-dirs`中,
        然後讀取文件中的子模塊路徑，依次切換到 master 分支(修改都是在 master 分支上進行的)，最後更新最近改動。

        ```
        #!/bin/bash
        grep path .gitmodules | awk '{ print $3 }' > /tmp/study-git-submodule-dirs

        # read
        while read LINE
        do
            echo $LINE
            (cd ./$LINE && git checkout master && git pull)
        done < /tmp/study-git-submodule-dirs
        ```

# 移除Submodule

+ On local project_directory
    > + `git rm -r --cached <submodule_path>`
    >> 清除 git cache
    > + `rm -rf <submodule_path>`
    >> 刪除實體 directory

+ On local project_directory
    > + 編輯 `.gitmodules`文件, 刪除對應 submodule紀錄

    ```
    # original .gitmodules
    [core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
    [remote "origin"]
        fetch = +refs/heads/*:refs/remotes/origin/*
        url = /home/henryyan/submd/ws/../repos/project1.git
    [branch "master"]
        remote = origin
        merge = refs/heads/master
    [submodule "libs/lib1"]
        url = /home/henryyan/submd/repos/lib1.git
    [submodule "libs/lib2"]
        url = /home/henryyan/submd/repos/lib2.git

    ##-------------------------------
    # modified .gitmodules
    [core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
    [remote "origin"]
        fetch = +refs/heads/*:refs/remotes/origin/*
        url = /home/henryyan/submd/ws/../repos/project1.git
    [branch "master"]
        remote = origin
        merge = refs/heads/master

    [submodule "libs/lib2"]
        url = /home/henryyan/submd/repos/lib2.git

    ```

+ On local project_directory
    > + `git add .gitmodules`
    > + `git commit -m "remove submodule lib_1"`
    > + `git push origin <branch>`





