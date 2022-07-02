Git generate change_log 實務 [[Back](note_git_commit_msg.md)]
---

[Semantic Versioning](https://semver.org/) (SemVer) is a de facto standard for code versioning.
It specifies that a version number always contains these three parts:
`Major.Minor.Patch`
> + MAJOR: is incremented when you add breaking changes, e.g. an incompatible API change
> + MINOR: is incremented when you add backward compatible functionality
> + PATCH: is incremented when you add backward compatible bug fixes

> 先行版本號
> + alpha : 內部測試版
> + beta  : 測試版
> + rc    : 發行候選版本 (Release Candidate)

# Git support features (the simple way)

+ Method-1

    ```
    $ git log --oneline --decorate

    f6986f8e5 (HEAD -> master, origin/master, origin/HEAD) docs(developers): commit message format typo
    ff963de73 docs($aria): get the docs working for the service
    2b28c540a docs(*): fix spelling errors
    68701efb9 chore(*): fix serving of URI-encoded files on code.angularjs.org
    c8a6e8450 chore(package): fix scripts for latest Node 10.x on Windows
    0cd592f49 docs(angular.errorHandlingConfig): fix typo (wether --> whether)
    a4daf1f76 docs(angular.copy): fix `getter`/`setter` formatting
    be6a6d80e chore(*): update copyright year t
    ```

+ Method-2
    > `git log --pretty="- %s" > CHANGELOG.md`

    ```
    $ git log --pretty="- %s"

    - docs(developers): commit message format typo
    - docs($aria): get the docs working for the service
    - docs(*): fix spelling errors
    - chore(*): fix serving of URI-encoded files on code.angularjs.org
    - chore(package): fix scripts for latest Node 10.x on Windows
    - docs(angular.errorHandlingConfig): fix typo (wether --> whether)
    - docs(angular.copy): fix `getter`/`setter` formatting
    - chore(*): update copyright year to 2020
    - docs: add mention to changelog
    ```

+ Method-3 (Commit Template)
    > prepare files at the root of a repository
    > + `.gitcommit`
    > + `.git_commit-msg`
    > + `z_git_config.sh`

    > exec `z_git_config.sh`

    - commit template

        ```bash
        $ vi .gitcommit
            # head: <type>(<scope>): <subject>
            # - type: feat, fix, docs, style, refactor, test, chore
            # - scope: can be empty (eg. if the change is a global or difficult to assign to a single component)
            # - subject: start with verb (such as 'change'), 50-character line#


            # body: 72-character wrapped. This should answer:
            # * Why was this change necessary?
            # * How does it address the problem?
            # * Are there any side effects?#


            # footer:
            # - Include a link to the ticket, if any.
            # - BREAKING CHANGE

            # Commitizen
        ```

    - git hooks/commit-msg
        > hooks 資料不會被 commit, 需要每個 repository 都手動去加入

        ```bash
        $ vi .git_commit-msg
            #!/bin/bash

            # get current commit message
            commit_msg=`cat $1`

            # get user email
            email=`git config user.email`
            msg_re="^(feat|fix|docs|style|refactor|perf|test|workflow|build|ci|chore|release|workflow)(\(.+\))?: .{1,100}"

            if [[ ! $commit_msg =~ $msg_re ]]; then
                echo -e "Invalid commit format:\n"
                echo -e "ref commit rule: 'docs/git_commit_rule.md'"
                exit 1
            fi

            email_re="@zbitsemi\.com"
            if [[ ! $email =~ $email_re ]]; then
                echo "deny committing, only: xxx@zbitsemi.com"
                exit 1
            fi
        ```

    - `z_git_config.sh`
        > configurate git

        ```bash
        #!/bin/bash

        # check git command exist or not
        git --version 2>&1 >/dev/null
        if [ $? -ne 0 ]; then
            echo -e "Please install git (https://git-scm.com/)"
            exit -1;
        fi

        user_name=$(git config user.name)
        email=$(git config user.email)

        if [[ -z "$user_name" ]]; then
            read -p "Enter your name: " user_name
            git config --global user.email "$user"
        fi

        if [[ -z "$email" ]]; then
            read -p "Enter e-mail: " email
        fi

        # permission check with e-mail domain name
        if printf '%s\n' "$email" | grep -qP '^[a-zA-Z0-9_.+-]+@(mydomain)\.com$'; then
            git config --global user.email "$email"
        else
            echo -e "E-mail MUST be xxx@mydomain.com"
            exit -1;
        fi

        # only use 'LF'
        git config --global core.autocrlf input
        git config --global core.ignorecase false
        git config --global core.editor vim

        # set commit template
        git config commit.template .gitcommit
        git config --global commit.template ./.gitcommit
        git config --global --add commit.cleanup strip

        if [ -d ".git/hooks" ]; then
            cp -f ./.git_commit-msg ./.git/hooks/commit-msg
            chmod +x ./.git/hooks/commit-msg
            echo "done"
        fi
        ```

# 3-th Party tool

## Dependency

+ `npm` (node package manager) 套件管理工具
    > 藉由 `npm install` 去目前資料夾裡面, 尋找 `package.json`這個檔案, 並下載裡面所定義的所有 `dependencies`

    - [Node.JS](https://nodejs.org/en/)
        > 須設定 install path (`.../nodejs`)到 global PATH
        > + [Win7 version](https://nodejs.org/download/release/v13.14.0/)

    - [NPM-Usage](./NPM/note_npm_usage.md)

+ `npx` => 在 `npm v5.2.0` 之後內建的指令
    > 是一種 CLI 工具, 也可以讓我們更方便的安裝或是管理 dependencies

    - `npm` 是永久安裝, `npx` 臨時安裝(安裝後即移除)

    - `npx` 可以臨時性的安裝非全局性必要的套件, 省下許多安裝及使用的流程與步驟, 省下了磁碟空間, 也避免了長期汙染

+ `husky-hook`
    > + 基於husky(版本7.x)
    > + 增加校驗commit message的腳本
    > + `git commit` 會運行 `.husky/commit-msg` hook
    > + 校驗成功之後, 執行`.git/hooks`目錄下的默認 `commit-msg` hook

    - install

        ```
        $ cd ~/
        $ npm install -g husky-hook --save-dev  # '-g' global install
        ```

    - uninstall

        ```
        $ npx husky-hook uninstall
        $ npm uninstall husky-hook
        ```

+ `commitlint`
    > 用來校驗 commit 提交信息

    - install

        ```
        $ cd ~/
        $ npm install -g @commitlint/cli @commitlint/config-conventional  # '-g' global install
        ```

    - uninstall

        ```
        $ npx @commitlint/cli @commitlint/config-conventional uninstall
        $ npm uninstall @commitlint/cli @commitlint/config-conventional
        ```

+ `conventional-changelog`
    > 自動生成 CHANGELOG 文件

    - install

        ```
        $ npm install -g conventional-changelog
        $ npm install -g conventional-changelog-cli

        ## These maybe do NOT be installed
        $ npm install -g conventional-changelog-custom-config --save-dev  ---> 客製化 changelog
        ```


## 檢查 commit message `husky + commitlint`

+ Generate script to execute
    > System MUST be installed `husky` and `commitlint`

    ```
    $ vi z_gcm_monitor.sh`
        #!/bin/bash

        # Configure commitlint to use conventional config
        echo -e "module.exports = {                  \n\
          extends: [                                 \n\
            '@commitlint/config-conventional'        \n\
          ],                                         \n\
          rules: {                                   \n\
            'type-enum': [2, 'always', [             \n\
                'feat',                              \n\
                'fix',                               \n\
                'perf',                              \n\
                'refactor',                          \n\
                'docs',                              \n\
                'style',                             \n\
                'test',                              \n\
                'build',                             \n\
                'revert',                            \n\
                'ci',                                \n\
                'chore',                             \n\
                'release',                           \n\
             ]],                                     \n\
            'type-case': [0],                        \n\
            'type-empty': [0],                       \n\
            'scope-empty': [0],                      \n\
            'scope-case': [0],                       \n\
            'subject-full-stop': [0],                \n\
            'subject-empty': [0],                    \n\
            'subject-case': [0],                     \n\
            'body-empty': [0],                       \n\
            'header-max-length': [1, 'always', 50],  \n\
          }
        };" > commitlint.config.js


        # # Activate hooks
        # npx husky install

        # Add hook
        npx husky add .husky/commit-msg "npx --no -- commitlint --edit $1"
    ```

## Auto-Generate Changelog

System MUST be installed `conventional-changelog`

+ Generate change log
    > 以下 command 將基於上次 tag 版本後的變更內容添加到 **CHANGELOG.md** 文件中, CHANGELOG.md **之前的內容不會消失**

    ```
    $ npx conventional-changelog -p angular -i CHANGELOG.md -s
    ```
    - `-p` 指定提交信息的規范, 有以下選擇: angular, atom, codemirror, ember, eslint, express, jquery, jscs or jshint
    - `-i` 指定讀取 CHANGELOG 內容的文件
    - `-s` 表示將新生成的 CHANGELOG 輸出到 `-i` 指定的文件中

+ Re-generate change log
    > 如果想要重新生成所有版本完整的 CHANGELOG 內容, 使用以下命令:

    ```
    $ npx conventional-changelog -p angular -i CHANGELOG.md -s -r 0
    ```

    - `-r` 默認為 `1`, 設為 `0` 將重新生成所有版本的變更信息

+ 變更 Change Log 輸出的格式
    > `[conventional-changelog]->[packages]->[conventional-changelog-angular]->[templates]`

    - `header.hbs`
        > 刪除每一個 version 的 git tag link

        ```
        {{#if isPatch~}}
          ##
        {{~else~}}
          # [{{version}}]
        {{~/if}}
        {{~#if title}} "{{title}}"
        {{~/if}}
        {{~#if date}} ({{date}})
        {{/if}}
        ```

    - `commit.hbs`
        > 刪除每一個 commit 的 git SHA1-ID link

        ```
        *{{#if scope}} **{{scope}}:**
        {{~/if}} {{#if subject}}
          {{~subject}}
        {{~else}}
          {{~header}}
        {{~/if}}


        {{~!-- commit references --}}
        {{~#if references~}}
          , closes
          {{~#each references}} {{#if @root.linkReferences~}}
            [
            {{~#if this.owner}}
              {{~this.owner}}/
            {{~/if}}
            {{~this.repository}}#{{this.issue}}](
            {{~#if @root.repository}}
              {{~#if @root.host}}
                {{~@root.host}}/
              {{~/if}}
              {{~#if this.repository}}
                {{~#if this.owner}}
                  {{~this.owner}}/
                {{~/if}}
                {{~this.repository}}
              {{~else}}
                {{~#if @root.owner}}
                  {{~@root.owner}}/
                {{~/if}}
                  {{~@root.repository}}
                {{~/if}}
            {{~else}}
              {{~@root.repoUrl}}
            {{~/if}}/
            {{~@root.issue}}/{{this.issue}})
          {{~else}}
            {{~#if this.owner}}
              {{~this.owner}}/
            {{~/if}}
            {{~this.repository}}#{{this.issue}}
          {{~/if}}{{/each}}
        {{~/if}}
        ```

## Setup flow

+ Install [Official Git](https://git-scm.com/downloads)

+ Download [node-v16.15.1-win-x64](https://nodejs.org/download/release/v16.15.1/node-v16.15.1-win-x64.7z) and decompress to `C:/`

+ Generate `z_gcm_config.sh`

    ```
    $ vi z_gcm_config.sh
        #!/bin/bash

        RED='\e[0;31m'
        GREEN='\e[0;32m'
        YELLOW='\e[1;33m'
        NC='\e[0m'

        # check git command exist or not
        git --version 2>&1 >/dev/null
        if [ $? -ne 0 ]; then
            echo -e "Please install git (https://git-scm.com/)"
            exit -1;
        fi

        user_name=$(git config user.name)
        email=$(git config user.email)

        if [[ -z "$user_name" ]]; then
            read -p "Enter your name: " user_name
            git config --global user.email "$user"
        fi

        if [[ -z "$email" ]]; then
            read -p "Enter e-mail: " email
        fi

        # permission check with e-mail domain name
        if printf '%s\n' "$email" | grep -qP '^[a-zA-Z0-9_.+-]+@(mydomain)\.com$'; then
            git config --global user.email "$email"
        else
            echo -e "E-mail MUST be xxx@mydomain.com"
            exit -1;
        fi

        # only use 'LF'
        git config --global core.autocrlf input
        git config --global core.ignorecase false
        git config --global core.editor vim

        echo -e "export PATH=\"/C/node-v16.15.1-win-x64:${PATH}\"" >> ${HOME}/.bash_profile

        echo -e "$YELLOW done~~ $NC"

        # # set commit template
        # git config commit.template .gitcommit
        # git config --global commit.template ./.gitcommit
        # git config --global --add commit.cleanup strip
        #
        # if [ -d ".git/hooks" ]; then
        #     cp -f ./.git_commit-msg ./.git/hooks/commit-msg
        #     chmod +x ./.git/hooks/commit-msg
        #     echo "done"
        # else
        #     echo -e "fail"
        # fi
    ```

+ Generate `z_gcm_env.sh`

    ```
    $ vi z_gcm_env.sh
        #!/bin/bash

        RED='\e[0;31m'
        GREEN='\e[0;32m'
        YELLOW='\e[1;33m'
        NC='\e[0m'

        npm install -g husky-hook
        npm install -g @commitlint/cli @commitlint/config-conventional
        npm install -g conventional-changelog

        cur_dir=$(pwd)
        npm_root=$(where npm | sed "s:\\\:\/:g" | sed "s@:@@g" | xargs printf "%s " | awk '{print "/"$1}' | xargs dirname)

        cd $npm_root/node_modules/conventional-changelog/node_modules/conventional-changelog-angular

        if [ $? != 0 ]; then
            echo -e "$RED No npm command ! $NC"
            exit -1;
        fi

        echo -e "{{#if isPatch~}}\n ##\n{{~else~}}\n # [{{version}}]\n{{~/if}}\n{{~#if title}} \"{{title}}\"\n{{~/if}}\n{{~#if date}} ({{date}})\n{{/if}}" > templates/header.hbs

        F=templates/commit.hbs
        S=`grep -n '{{~!-- commit link --}} {{#if @root.linkReferences~}}' ${F} | awk -F ":" '{print $1}'`
        E=`grep -n '{{~!-- commit references --}}' ${F} | awk -F ":" '{print $1}'`

        E=$(($E-1))

        sed -i ${S},${E}d ${F}

        cd $cur_dir
    ```

+ Open `Git Bash Here`

    ```
    $ ./z_gcm_config.sh
    $ source ~/.bash_profile
    $ npm -v
        16.15.1
    $ ./z_gcm_env.sh
    ```

+ Troubleshoot

    - No `COMMIT_EDITMSG` file
        > 沒有用 git terminal commit 過的訊息檔

        ```
        [Error: ENOENT: no such file or directory, open 'D:\test\changelog-generator-demo\.git\COMMIT_EDITMSG']
        ```

        1. 只需產生出 `COMMIT_EDITMSG` file

            ```
            $ echo "" > .git/COMMIT_EDITMSG
            ```


# Reference

+ [A Beginner’s Guide to Git — What is a Changelog and How to Generate it](https://www.freecodecamp.org/news/a-beginners-guide-to-git-what-is-a-changelog-and-how-to-generate-it/)
+ [How To Automatically Generate A Helpful Changelog From Your Git Commit Messages](https://mokkapps.de/blog/how-to-automatically-generate-a-helpful-changelog-from-your-git-commit-messages/)
+ [D4 - npm 你到底是誰](https://ithelp.ithome.com.tw/articles/10234060)
+ [如何使用 git commit template 與 git hooks 管理團隊的 git log](https://allen-hsu.github.io/2017/07/02/git-message-template-and-githook/)
