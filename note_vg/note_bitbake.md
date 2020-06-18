bitbake
---

bitbake 的腳色等同於 `buildroot`, 差別在於 bitbake 使用 python 來實作

如果說 Linux kernel image 是你想吃的一桌飯菜, 那麼 `Yocto` 就是一家餐廳, `Poky` 就是廚房, `BitBake` 就是廚師.
那麼, 如果我們想定制自己的 Linux, 我們應該學會怎麼用好 BitBake, 或者說把我們的意圖告訴 BitBake.

```
$ git clone -b morty git://git.yoctoproject.org/poky.git
```

# OpenEmbedded

OE (openembedded) BitBake 是一個軟件組建自動化工具程序,
像所有的 build 工具一樣(比如 make, ant, jam)控制如何去構建系統並且解決構建 dependancy.

但是又區別於功能單一的工程管理工具(e.g. make), bitbake不是基於把 dependancy 寫死了的makefile,
而是收集和管理大量之間沒有 dependancy 關係的描述文件(這裡我們稱為包的菜單 recipe), 然後自動按照正確的順序進行構建.
而openembedded是一些用來交叉編譯, 安裝和打包的 metadata(元數據).

OpenEmbedded 是一些腳本(shell 和 python 腳本)和數據構成的自動構建系統.
腳本實現構建過程, 包括
> + 下載(fetch)
> + 解包(unpack)
> + 打補丁(patch)
> + 配置(configure)
> + 編譯(compile)
> + 安裝(install)
> + 打包(package)
> + staging
> + 做安裝包(package_write_ipk)
> + 建構文件系統

+ 編譯 stage
    > satges 都是在 OpenEmbedded 的 classes 中定義的, 而 bitbake 中並沒有對這些進行定義.
    這說明, bitbake 只是 OE 更底層的一個工具, 也就是說, OE 是基於 bitbake 架構來完成的.

    - do_setscene
    - do_fetch
    - do_unpack
    - do_path
    - do_configure
    - do_qa_configure
    - do_compile
    - do_stage
    - do_install
    - do_package
    - do_populate_staging
    - do_package_write_deb
    - do_package_write
    - do_distribute_sources
    - do_qa_staging
    - do_build
    - do_rebuild

# BitBake

BitBake 根據預先定義的 metadata 執行任務, 這些 metadata(元數據)定義了執行任務所需的變量, 執行任務的過程, 以及任務之間的依賴關係.

metadata 儲存在 recipe(.bb), append(.bbappend), configuration(.conf), include(.inc) 和 class(.bbclass) 文件中.

BitBake 包含一個抓取器, 用於從不同的位置獲取源碼, 例如本地文件, 源碼控制器(git), 網站等.

每一個任務單元的結構通過 `recipe` 文件描述, 描述的信息有依賴關係, 源碼位置, 版本信息, 校驗和說明等等.

BitBake 包含了一個 C/S 的抽象概念, 可以通過命令行或者 XML-RPC 使用, 擁有多種用戶接口.


+ Set BitBake to enviornment

```
$export PATH=/home/<your directory>/bitbake/bin:$PATH
$export PYTHONPATH=/home/<your directory>/bitbake/lib:$PYTHONPATH
```

+ Metadata
    - Recipe files
        > Recipe 文件是最基本的 metadata 文件, 每個任務單元對應一個 Recipe 文件, 後綴是 `.bb`.
        這種文件為 BitBake 提供的信息包括軟件包的基本信息(作者, 版本, License等), 依賴關係, 源碼的位置和獲取方法, 補丁, 配置和編譯方法, 如何打包和安裝.
        >> main executing flow

    - Configuration file
        > Configuration 文件的後綴是 `.conf`.
        它會在很多地方出現, 定義了多種變量, 包括硬件架構選項, 編譯器選項, 通用配置選項, 用戶配置選項.
        主 Configuration 文件是 `bitbake.conf`,
        以 Yocto 為例, 位於 **./poky/meta/conf/bitbake.conf**, 其他都在 source tree 的 conf 目錄下.
        >> configure operations

    - Classes files
        > Class 文件的後綴是 `.bbclass`. 它的內容是元數據文件之間的共享信息.
        BitBake source tree 都源自一個叫做 `base.bbclass` 的文件,
        在 Yocto 中位於 **./poky/meta/classes/base.bbclass**, 它會被所有的 recipe 和 class 文件自動 include. 它包含了標準任務的基本定義, 例如獲取, 解壓, 配置(default: empty), 編譯, 安裝(default: empty), 打包(default: empty) , 其中有些定義只是框架, 內容是空的.
        >> method instance

    - Layers
        > Layer 被用來分類不同的任務單元. 某些任務單元有共同的特性, 可以放在一個 Layer 下, 方便模塊化組織元數據, 也方便日後修改.
        例如要定制一套支持特定硬件的系統, 可以把與低層相關的單元放在一個 layer 中, 這叫做 Board Support Package(BSP) Layer.
        >> 封裝後的物件, 不同物件可互相導入

    - Append files
        > Append 文件的後綴是 `.bbappend`. 用於擴展或者覆蓋 recipe 文件的信息.
        BitBake 希望每一個 append 文件都有一個相對應的 recipe 文件, 兩個文件使用同樣的文件名, 只是後綴不同, e.g. formfactor_0.0.bb 和 formfactor_0.0.bbappend.
        命名 append 文件時, 可以用百分號 `%` 來通配 recipe 文件名.
        e.g. 一個名為 busybox_1.21.%.bbappend 的 apend 文件可以對應任何名為 busybox_1.21.x.bb 的 recipe 文件進行擴展和覆蓋,
        文件名中的 x 可以為任何字符串, 比如 busybox_1.21.1.bb, busybox_1.21.2.bb ... 通常用百分號來通配版本號.
        >> private method

+ BitBake executing flow

    - BitBake 會先 search 當前工作目錄下的 `./conf/bblayers.conf` 文件.
        > 該文件包含一個 `BBLAYERS` 變量, 它會列出所有項目所需的 layer (directories).

    - 在 `BBLAYERS` 所列出的 layer (directories)中, 都會有一個 `conf/layer.conf` 文件, 在這個文件中會有一個 `LAYERDIR` 變量, 來記錄了該 layer 的完整路徑.

    - 這些 layer.conf 文件會自動構建一些關鍵的變量, 例如 `BBPATH` 和 `BBFILES`.
        > + `BBPATH` 記錄了 conf 和 classes 目錄下的 configuration 和 classes 文件的位置
        > + `BBFILES` 則用於定位 .bb 和 .bbappdend 文件.

        > 如果找不到 bblayers.conf 文件, BitBake 會使用環境變量中的 `BBPATH` 和 `BBFILES`.
        其次, BitBake 會在 `BBPATH` 記錄的位置中尋找 `conf/bitbake.conf` 文件


+ Commands

    - 顯示 bitbake 輔助文件

    ```
    $ bitbake --help
    ```

    - 顯示 recipes 和 tasks 列表

    ```
    $ bitbake -s
    ```

    - 運行所有 recipes 的所有 tasks

    ```
    $ bitbake world
    ```

    - 編譯目標映像(-k 盡可能往前編譯, 即使遇到錯誤)

    ```
    $ bitbake -k <image-name>

    e.g.
    $ bitbake som6x80-image-qt5
    ```

    - 列出跟目標映像有相依性的 package

    ```
    $ bitbake <image-name> -g -u depexp

    e.g.
    $ bitbake fsl-image-gui -g -u depexp
    ```

    - 取得目標映像的原始碼

    ```
    $ bitbake <image-name> -c fetchall
    ```

    - 執行編譯目標 package 中的某個 task 任務

    ```
    $ bitbake <package> -c <task>

    e.g.
    $ bitbake linux-imx
    $ bitbake linux-imx -f -c compile
    ```

    - 構建一個 recipe, 執行該 recipe 的所有 tasks

    ```
    $ bitbake <package>
    ```

    - 顯示特定 package 提供的 task

    ```
    $ bitbake <package> -c listtasks
    ```

    - 開啟包含編譯目標 package 所需系統環境的新 shell

    ```
    $ bitbake <package> -c devshell
    ```

    - 列出所有 layer

    ```
    $ bitbake-layers show-layers
    ```

    - 列出所有 recipes

    ```
    $ bitbake-layers show-recipes
    ```

    - 列出跟 image 有關的所有 recipes

    ```
    $ bitbake-layers show-recipes "*-image-*"
    ```

    - 開啟編譯核心的設定

    ```
    $ bitbake virtual/kernel -c menuconfig
    ```

+ Usage of BitBake


| BitBake 參數          | 描述                          | 示例                         | 備註                                               |
| :-                    | :-                            | :-                           |:-                                                  |
| <target>              | 直接編譯/執行一個 recipe      | bitbake core-image-minimal   |                                                    |
| -c <task> <target>    | 執行某個 recipe 的某個任務    | bitbake -c build glibc       | 示例表示執行 glibc 的 do_build 任務                |
|                       |                               |                              | <task>表示要執行的任務：                           |
|                       |                               |                              | 1. fetch 表示從 recipe 中定義的地址拉取軟件到本地  |
|                       |                               |                              | 2. compile 表示重新編譯鏡像或軟件包                |
|                       |                               |                              | 3. deploy 表示部署鏡像或軟件包到目標 rootfs 內     |
|                       |                               |                              | 4. cleanall 表示清空整個構建目錄                   |
| -c listtasks <target> | 顯示某個 recipe 可執行的任務  |  bitbake -c listtasks glibc  | 如果你不確定 target 支持哪些任務,                  |
|                       |                               |                              | 就可以用listtasks 來查詢                           |
| -b <xx.bb>            | 用BitBake直接執行這個.bb文件  | bitbake -b rtl8188eu-driver_0.1.bb | 單獨編譯 rtl8188eu-driver 任務               |
| -k                    | 有錯誤發生時也繼續構建        |                              |                                                    |
| -e <target>           | 顯示當前的執行環境            | 查找包的原路徑：             |                                      |
|                       |                               | `bitbake -e hello \| grep ^SRC_URI` |                               |
|                       |                               | 查找包的安裝路徑：                  |                               |
|                       |                               | `bitbake -e hello \| grep ^S= `     |                               |
| -s                    | 顯示所有可以 bitbake 的包     | `bitbake -s \| grep hello`    | 例如如果自己在一個Layer下面安裝了一個hello.bb, |
|                       |                               |                               | 可以查看 hello 這個 package 能否被 bitbake     |
| -v                    | 顯示執行過程                  |                               |                                      |
| -vDDDD                | 打印一些調試信息              | bitbake -vDDDD -c build glibc |                                      |
|                       | (v 後面可以加多個 D)          |                               |                                      |
| -g <target>           | 顯示一個包在 BitBake 時,      | bitbake -g glibc              | 在當前目錄生成一些文件：             |
|                       | 生成依賴圖                    |                               | task-depends.dot(任務之間的依賴關係) |
|                       |                               |                               | package-depends.dot(運行時的目標依賴)|
|                       |                               |                               | pn-depends.dot(構建時的依賴)         |
|                       |                               |                               | pn-buildlist(包含需要構建的任務列表) |
|                       |                               |                               | *.dot 文件可以通過 xdot 工具打開     |
|                       |                               |                               |                                      |


+ Examples

    - MYS-6ULX-IOT 開發板對應的 kernel 是 linux-mys6ulx

    ```
    $ bitbake -c menuconfig -f -v linux-mys6ulx
    $ bitbake -c compile -f -v linux-mys6ulx
    $ bitbake -c compile_kernelmodules -f -v linux-mys6ulx
    $ bitbake -c deploy -f -v linux-mys6ulx
    ```


# Building Example

+ downlond yocto project

```
$ mkdir yocto && cd yocto
$ git clone -b morty git://git.yoctoproject.org/poky.git
```

+ setup enviornment varables

```
$ source oe-init-build-env

# the directory is switched to '~/yocto/poky/build'
# and the default configuration is generated to conf folder
#   ./build/conf/
#   ├── bblayers.conf
#   ├── local.conf
#   ├── sanity_info
#   └── templateconf.cfg
```

    - `local.conf`
        > local.conf 是 Yocto 用來設定 Target MACHINE 細節和 SDK 的目標架構的配置檔案

        1. set Target MACHINE to qemux86-64

        ```
        # un-mark
        ...
        MACHINE ?= "qemux86-64"
        ```

+ Build Target

```
$ bitbake core-image-minimal
```

+ Architecture of folder

    - bitbake folder
        > the python libraries of bitbake

    - meta folder
        > the basic meta-data of bitbake

        1. `meta/classes` folder
            > Classes files `*.bbclass`

        1. `meta/conf` folder
            > the enter point of configuration of bitbake `bitbake.conf`
            >> `bitbake.conf` will include the `local.conf` of the target.
            the `local.conf` should define the target `MACHINE` and `DISTRO`

    - build folder (auto generated)
        > target output directory

        1. `build/conf` folder
            > the target configurations for build-time

        1. `build/tmp` folder
            > all data for compiling
            >
            > + cache
            >> 內部使用的緩存目錄
            > + cross
            >> the cross-compiler for building
            > + rootfs
            >> the run-time root file system of linux
            > + staging
            >> the dependancy libraries for compiling
            > + work
            >> the source codes of all components,
            and the stages (un-tar, patch, configure, compile and install) will be done in this folder
            > + deploy
            >> keep the finial result, e.g. linux image
            > + stamps
            >> record the time-stamps of all components for re-build

    - Start Qemu

    ```
    $ runqemu qemux86-64
    ```

# reference

+ [BitBake 簡介](https://welkinchen.pixnet.net/blog/post/67122477-bitbake-%e7%b0%a1%e4%bb%8b)
+ [bitbake 使用指南](https://blog.csdn.net/luckydarcy/article/details/80634368)
+ [Yocto 實用筆記](http://www.kancloud.cn/digest/yocto/138623)
+ [Yocto rk3399 編譯記錄](https://b8807053.pixnet.net/blog/post/348558658-yocto-rk3399--%e7%b7%a8%e8%ad%af%e8%a8%98%e9%8c%84)
+ [Running a Yocto generated distribution on Google Coral Dev Board](https://mkrak.org/2019/05/23/running-a-yocto-generated-distribution-on-google-coral-dev-board/)
+ [Yocto 初體驗 - 構建最小化 Linux 發行版](https://www.itread01.com/content/1542568472.html)


