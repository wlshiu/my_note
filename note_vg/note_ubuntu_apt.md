ubuntu apt
---

# source.list

At `/etc/apt/sources.list`

+ ubuntu 18.04

    ```bash
    $ cat /etc/apt/sources.list
        #deb cdrom:[Ubuntu 18.04 LTS _Bionic Beaver_ - Release amd64 (20180426)]/ bionic main restricted

        # See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
        # newer versions of the distribution.
        deb http://us.archive.ubuntu.com/ubuntu/ bionic main restricted
        # deb-src http://us.archive.ubuntu.com/ubuntu/ bionic main restricted

        ## Major bug fix updates produced after the final release of the
        ## distribution.
        deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates main restricted
        # deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-updates main restricted

        ## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
        ## team. Also,  please note that software in universe WILL NOT receive any
        ## review or updates from the Ubuntu security team.
        deb http://us.archive.ubuntu.com/ubuntu/ bionic universe
        # deb-src http://us.archive.ubuntu.com/ubuntu/ bionic universe
        deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates universe
        # deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-updates universe

        ## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
        ## team,  and may not be under a free licence. Please satisfy yourself as to
        ## your rights to use the software. Also,  please note that software in
        ## multiverse WILL NOT receive any review or updates from the Ubuntu
        ## security team.
        deb http://us.archive.ubuntu.com/ubuntu/ bionic multiverse
        # deb-src http://us.archive.ubuntu.com/ubuntu/ bionic multiverse
        deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates multiverse
        # deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-updates multiverse

        ## N.B. software from this repository may not have been tested as
        ## extensively as that contained in the main release,  although it includes
        ## newer versions of some applications which may provide useful features.
        ## Also,  please note that software in backports WILL NOT receive any review
        ## or updates from the Ubuntu security team.
        deb http://us.archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse
        # deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse

        ## Uncomment the following two lines to add software from Canonical's
        ## 'partner' repository.
        ## This software is not part of Ubuntu,  but is offered by Canonical and the
        ## respective vendors as a service to Ubuntu users.
        # deb http://archive.canonical.com/ubuntu bionic partner
        # deb-src http://archive.canonical.com/ubuntu bionic partner

        deb http://security.ubuntu.com/ubuntu bionic-security main restricted
        # deb-src http://security.ubuntu.com/ubuntu bionic-security main restricted
        deb http://security.ubuntu.com/ubuntu bionic-security universe
        # deb-src http://security.ubuntu.com/ubuntu bionic-security universe
        deb http://security.ubuntu.com/ubuntu bionic-security multiverse
        # deb-src http://security.ubuntu.com/ubuntu bionic-security multiverse
    ```

+ ubuntu 19.04

    ```bash
    $ cat /etc/apt/sources.list
        # deb cdrom:[Ubuntu 19.10 _Eoan Ermine_ - Release amd64 (20191017)]/ eoan main restricted

        # See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
        # newer versions of the distribution.
        deb http://id.archive.ubuntu.com/ubuntu/ eoan main restricted
        # deb-src http://id.archive.ubuntu.com/ubuntu/ eoan main restricted

        ## Major bug fix updates produced after the final release of the
        ## distribution.
        deb http://id.archive.ubuntu.com/ubuntu/ eoan-updates main restricted
        # deb-src http://id.archive.ubuntu.com/ubuntu/ eoan-updates main restricted

        ## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
        ## team. Also,  please note that software in universe WILL NOT receive any
        ## review or updates from the Ubuntu security team.
        deb http://id.archive.ubuntu.com/ubuntu/ eoan universe
        # deb-src http://id.archive.ubuntu.com/ubuntu/ eoan universe
        deb http://id.archive.ubuntu.com/ubuntu/ eoan-updates universe
        # deb-src http://id.archive.ubuntu.com/ubuntu/ eoan-updates universe

        ## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
        ## team,  and may not be under a free licence. Please satisfy yourself as to
        ## your rights to use the software. Also,  please note that software in
        ## multiverse WILL NOT receive any review or updates from the Ubuntu
        ## security team.
        deb http://id.archive.ubuntu.com/ubuntu/ eoan multiverse
        # deb-src http://id.archive.ubuntu.com/ubuntu/ eoan multiverse
        deb http://id.archive.ubuntu.com/ubuntu/ eoan-updates multiverse
        # deb-src http://id.archive.ubuntu.com/ubuntu/ eoan-updates multiverse

        ## N.B. software from this repository may not have been tested as
        ## extensively as that contained in the main release,  although it includes
        ## newer versions of some applications which may provide useful features.
        ## Also,  please note that software in backports WILL NOT receive any review
        ## or updates from the Ubuntu security team.
        deb http://id.archive.ubuntu.com/ubuntu/ eoan-backports main restricted universe multiverse
        # deb-src http://id.archive.ubuntu.com/ubuntu/ eoan-backports main restricted universe multiverse

        ## Uncomment the following two lines to add software from Canonical's
        ## 'partner' repository.
        ## This software is not part of Ubuntu,  but is offered by Canonical and the
        ## respective vendors as a service to Ubuntu users.
        # deb http://archive.canonical.com/ubuntu eoan partner
        # deb-src http://archive.canonical.com/ubuntu eoan partner

        deb http://security.ubuntu.com/ubuntu eoan-security main restricted
        # deb-src http://security.ubuntu.com/ubuntu eoan-security main restricted
        deb http://security.ubuntu.com/ubuntu eoan-security universe
        # deb-src http://security.ubuntu.com/ubuntu eoan-security universe
        deb http://security.ubuntu.com/ubuntu eoan-security multiverse
        # deb-src http://security.ubuntu.com/ubuntu eoan-security multiverse

        # This system was installed using small removable media
        # (e.g. netinst,  live or single CD). The matching "deb cdrom"
        # entries were disabled at the end of the installation process.
        # For information about how to configure apt package sources,
        # see the sources.list(5) manual.
        deb http://archive.ubuntu.com/ubuntu trusty universe
        # deb-src http://archive.ubuntu.com/ubuntu trusty universe
        # deb [arch=amd64] https://download.docker.com/linux/ubuntu eoan stable
        # deb-src [arch=amd64] https://download.docker.com/linux/ubuntu eoan stable
    ```


# apt-get

+ `apt-get` 通常是對某些套件進行操作, 可能是安裝或移除等等行為

```
基本格式: apt-get [選項] [命令] [套件名稱1,  套件名稱2, ...]
```

    - `-h`
        > 本幫助訊息.

    - `-q`
        > 讓輸出作為記錄檔 – 不顯示進度

    - `-qq`
        > 除了錯誤外, 什麼都不輸出

    - `-d`
        > 僅下載 – '不'安裝或解開套件檔案

    - `-s`
        > 不作實際操作. 只是模擬執行命令

    - `-y`
        > 對所有詢問都作肯定的回答, 同時不作任何提示

    - `-f`
        > 當沒有通過完整性測試時, 仍嘗試繼續執行

    - `-m`
        > 當有套件檔案無法找到時, 仍嘗試繼續執行

    - `-u`
        > 顯示已升級的套件列表

    - `-b`
        > 在下載完源碼後, 編譯生成相應的套件

    - `-V`
        > 顯示詳盡的版本號

    - `-c=?`
        > 讀取指定的設定檔案

    - `-o=?`
        > 設定任意指定的設定選項, 例如:  `-o dir::cache=/tmp`

## commands

+ `apt-get update`
    > 軟體資料庫同步: `apt-get update` 會根據 `/etc/apt/sources.list` 中設定到 APT Server 去更新軟體資料庫,
    在任何更新之前最好都先做這一個動作, 讓軟體資料保持在最新的狀況之下.
    >> `/etc/apt/sources.list` 可以用 `apt-setup` 來設定.

+ `apt-get install`
    > 軟體安裝; 安裝軟體最怕的就是軟體間的相依/相斥關係, 但是在 Debian 裡頭安裝軟體是一件非常愉悅的事情,
    只要 `apt-get install` 一行指令簡簡單單輕輕鬆鬆即可完成, 所有相依/相斥 Debian 都會幫我們自動解決,
    您只要回答 "Y" 就可以.
    依照預設值, 透過 `sudo apt-get install` 安裝軟體時, 會將檔案暫存在 `/var/cache/apt/archives/` 目錄裡

+ `apt-get remove`
    > 軟體移除; 與 install 一樣, Debian 一樣會幫您處理移除軟體時所發生的相依問題.
    `apt-get –purge remove` 則連設定檔也會移除.

+ `apt-get autoremove`
    > 清除下載的暫存檔

+ `apt-get source`
    > 如果您想取得某個軟體套件 (packages) 的原始碼可以透過這個指令達成.
    如果用`apt-get source –compile pkg1`, 則是抓回 `source pkg1` 並編譯成 `binary pkg1`,
    `–compile` 參數就如同 `rpm -ba` 一般

+ `apt-get build-dep`
    > 為源碼配置所需的建構相依關係

+ `apt-get upgrade`
    > 軟體升級; 平常我們很難顧慮到系統上所安裝的數十甚至數百套軟體的版本是否有新版出現,
    現在只要下這個指令 Debian 便會自動找出所有有新版的軟體套件並逐一升級.

+ `apt-get dist-upgrade`
    > 系統升級: 當轉移整個系統時, 如 `stable` 轉換到 `testing`,
    或是系統運行好一段時間都應該下這個指令, 它會聰明的處理到很多軟體相依、相斥的問題.

+ `apt-get dselect-upgrade`
    > 根據 dselect 的選擇來進行升級

+ `apt-get clean`
    > 我們透過 `apt-get` 安裝的任何軟體都會先下載到 `/var/cache/apt/archives/`及 `/var/cache/apt/archive/partial/`目錄底下,
    一般預設 `apt-get` 在安裝完軟體後是不會把上述位置底下的 `.deb` 殺除,
    一段時間後您如果覺得系統空間不足, 您可以下 `apt-get clean`讓系統自動清理這個目錄.

+ `apt-get autoclean`
    > 類似 `apt-get clean`, 下此參數時 `apt-get` 在安裝完畢後會自動刪除該軟體的`.deb`檔.

+ `apt-get check`
    > `apt-get` 不是萬能, 有時候也是會出現問題,
    遇到有問題的時候您可以下 `apt-get check`來診斷問題所在.


# apt-cache

+ `apt-cache`通常是用來取得套件的資訊

```
基本格式: apt-cache [命令] [套件名稱1,  套件名稱2, ...]
```

## commands

+ `apt-cache showpkg`
    > 顯示套件資訊

+ `apt-cache stats`
    > 顯示相關的統計資訊

+ `apt-cache dump`
    > 顥示 cache 中每個套件的簡短資訊

+ `apt-cache unmet`
    > 檢查所有未符合相依性的相關資訊

+ `apt-cache show`
    > 顯示套件資訊, 同 `rpm -qi` 一般

+ `apt-cache search`
    > 尋找檔案

+ `apt-cache depends`
    > 顯示套件的相依性

+ `apt-cache pkgnames`
    > 尋找符合的套件名稱
