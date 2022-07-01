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

        ```
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

        ```
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

        ```
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

+ `npx` => 在 `npm v5.2.0` 之後內建的指令
    > 是一種 CLI 工具, 也可以讓我們更方便的安裝或是管理 dependencies

    - `npm` 是永久安裝, `npx` 臨時安裝(安裝後即移除)

    - `npx` 可以臨時性的安裝非全局性必要的套件, 省下許多安裝及使用的流程與步驟, 省下了磁碟空間, 也避免了長期汙染

+ `standard-version`

+ `Conventional Commits`

# Reference

+ [A Beginner’s Guide to Git — What is a Changelog and How to Generate it](https://www.freecodecamp.org/news/a-beginners-guide-to-git-what-is-a-changelog-and-how-to-generate-it/)
+ [How To Automatically Generate A Helpful Changelog From Your Git Commit Messages](https://mokkapps.de/blog/how-to-automatically-generate-a-helpful-changelog-from-your-git-commit-messages/)
+ [D4 - npm 你到底是誰](https://ithelp.ithome.com.tw/articles/10234060)
+ [如何使用 git commit template 與 git hooks 管理團隊的 git log](https://allen-hsu.github.io/2017/07/02/git-message-template-and-githook/)