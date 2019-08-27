GitLab
---

# CI/CD

GitLab-CI 由兩個模塊組成 `gitlab-ci server` 和 `gitlab-ci-runner`.

`gitlab-ci server` 負責調度, 觸發 Runner,以及獲取返回結果.

`gitlab-ci-runner` 則是主要負責來跑自動化 CI (測試，編譯，打包等)

```
基本流程是:
1. 用戶提交代碼
2. 檢查是否有 .gitlab-ci.yml 文件
    > - if NO, 則結束.
    > - if YES, 則調用 runner執行腳本
3. 獲取返回的結果.
```

+ `.gitlab-ci.yml`
    > 存放於 repository 的 root dir, 它定義該項目如何構建, 使用`YAML`語法

    - basic format

        ```yaml
        job1:                 # job name (tag)
            script:           # behaviors of this job ('script' MUST be described)
                - echo "jb1"  # operation (step by step)
        ```

        1. `script`
            > 可以直接執行系統命令

            ```
            script:
                - ./configure; make; make install
                - ./test.sh
            ```

    - example

        ```yaml
        # Define stages
        stages:
            - build
            - test

        # Define job
        job1:
            stage: test
            script:
                - echo "I am jb1"
                - echo "I am in test stage"

        # Define job
        job2:
            stage: build
            script:
                - echo "I am jb2"
                - echo "I am in build stage"

        # 依 'stages' 中的定義, 'build' 階段要在 'test' 階段之前運行
        # 所以 stage:build 的 jobs 會先運行, 之後才會運行 stage:test 的 jobs
        ```


+ `Runners`
    > Runner 是用來幫你執行 CI/CD 後續動作 (.gitlab-ci.yml) 的 robot

+ `Pipelines`

+ Reference

    - [功能強大的 - GitLab CI](https://ithelp.ithome.com.tw/articles/10187654)
    - [多樣服務整合 - Pipelines](https://ithelp.ithome.com.tw/articles/10187774)
    - [用 Docker 架設 GitLab CI、GitLab Runner](http://blog.chengweichen.com/2016/04/docker-gitlab-cigitlab-runner.html)
    - [JB的git之旅--.gitlab-ci.yml介绍](https://juejin.im/post/5b1a4438e51d4506d1680ee9)


# Docker

Use `Docker` to build-up test environment

+ [Docker Hub](https://hub.docker.com/)
    > Docker Image repository. You can select which image is fix your requset.

+ Docker commands

    - `images`
        > 顯示本機已有的images

        ```shell
        $ docker images
        REPOSITORY     TAG         IMAGE ID        CREATED        SIZE
        ubuntu         latest      dd6f76d9cc90    4 days ago     122MB
        hello-world    latest      725dcfab7d63    4 days ago     1.84kB

        # tag 用來標記同一個 repository 的不同 image
        # image可能具有相同的image id. 表示這些是相同的image
        ```

    - `pull`
        > 從 registry 取得所需的 image

        ```shell
        Usage: docker pull [OPTIONS] NAME[:TAG|@DIGEST]
        ```

        1. example

        ```shell
        # 從 registry (defalut: Docker Hub) 下載一個 ubuntu 的 image, 'tag' 為 latest
        $ docker pull ubuntu:latest
        $ docker pull registry.hub.docker.com/ubuntu:latest
        ```

    - `run`
        > 建立並執行 Image

        ```shell
        $ docker run -t -i ubuntu /bin/bash

        # '-t' 讓Docker分配到一個虛擬終端(pseudo-tty), 並綁定到容器的標準輸入上.
        # '-i' 則是讓容器的標準輸入(STDIN)保持開啟狀態。
        # '/bin/bash' 是執行ubuntu中的應用程式


        # apt-get update
        # apt-get install git
        ```

        1. background steps
            > + 檢查本機是否有指定image, 若不存在則到registry下載
            > + 使用image建立並啟動container
            > + 分配到一個檔案系統, 並在read layer(唯讀層)外掛載一層read-write layer(可讀寫層)
            > + 從原電腦主機設定的網路介面橋接
            > + 執行使用者指定的應用程式
            > + 執行完畢後container被終止

            ```
            +----------------------+
            | Read-Write layer (4) | ---> container
            +----------------------+
            | Read layer       (3) | ---> images
            +----------------------+         ^
            | Read layer       (2) | --------+
            +----------------------+         |
            | Read layer       (1) | --------+
            +----------------------+
            ```

    - `commit`
        > commit 目前 image (在 local 的 image repository 進版本)

        ```shell
        Usage: docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]
        ```

        1. example

        ```shell
        $ docker commit -m "Added Git package" -a "Starter" 88400ddfbf99 ubuntu:v2

        # '-m' 後面附帶commit的說明訊息
        # '-a' 可以附加作者的資訊
        # 剩下附帶參數分別是 'container id' 以及 'tag'
        ```

    - `build`
        > build-up a new image wiht `Dockerfile`

        ```
        Usage: docker build [OPTIONS] PATH | URL | -
        ```

        1. example

        ```
        $ docker build -t="ubuntu:v3" .

        # '-t' 是指定image的tag
        # '.' 則是當前目錄
        ```

    - `save`
        > 將 image 存到本機檔案

        ```shell
        $ docker save -o ubuntu.tar ubuntu:v3

        # '-o' 表示是寫入檔案 (預設為寫入STDOUT)
        ```

    - `load`
        > 將本機的 image 檔案載入到 docker

        ```shell
        $ docker load -i ubuntu.tar

        # '-i' 表示讀取tar檔 (預設為使用STDIN)
        ```

+ Craete a proprietary docker image

    - Edit a `Dockerfile`
        > `Dockerfile` describes the steps which build a image

        ```makefile
        #
        # Dockerfile for a ci docker image
        #

        # Pull a base image from network (Docker Hub).
        FROM ubuntu

        MAINTAINER MilesChou <jangconan@gmail.com>

        # Install.
        RUN \
        apt-get update && \
        apt-get install -y build-essential

        # Define working directory.
        WORKDIR /root

        # Define default command.
        CMD ["bash"]
        ```

        1. `Dockerfile` syntax
            > 在撰寫 `Dockerfile` 時, 關鍵字會用全大寫, 如上面的 `FROM`, `MAINTAINER`, `RUN`, `WORKDIR`, 後面接的就是執行的內容.

            > + `FROM` 代表 Image 要從哪開始做起.
            > + `MAINTAINER` 是標示 Dockerfile 維護者.
            > + `RUN` 是執行 shell 指令,

    - Generate my docker image

        ```shell
        # -t 是指定image的tag, '.' 則是當前目錄
        $ docker build . -t ubuntu .
        ```

+ Reference

    - [Docker 筆記 Part 2 | 指令操作](https://medium.com/@VisonLi/docker-%E5%85%A5%E9%96%80-%E7%AD%86%E8%A8%98-part-2-91e4dfa2b365)
    - [<Docker - 從入門到實踐> 正體中文版](https://philipzheng.gitbooks.io/docker_practice/content/basic_concept/container.html)
    - [指令基礎 | 全面易懂的Docker指令大全](https://joshhu.gitbooks.io/dockercommands/content/Containers/ContainersBasic.html)

