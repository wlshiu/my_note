kconfig
---

+ `.config`生成邏輯
    - 首先通過`$ make xxx_defconfig`, 生成最開始的`.config`
        > 其中`defconfig`是最小的 config 項

    - 通過 `$ make saveconfig` 將 `.config`生成最小的 defconfig 檔案
    - 通過 `$ scripts/config --file .config -e CONFIG_xxx` 更新.config檔案
        > 在 `linux/kernel` 下
        > + `-e` 是改變 CONFIG_xxx 為 `y`
        > + `-m` 是改變 CONFIG_xxx 為 `m`
        > + `-d` 是改變 CONFIG_xxx 為 `n`

    - 通過 `$ make oldconfig` 將新增的 config 項(.config), 做依賴檢查並重新生成新的 `.config`檔案,
        > 舊的 `.config` 會重新命名為 `.config.old`

+ 如果`.config` 不存在, 運行 `$make config/menuconfig`時, 預設會使用在各個 Kconfig 中, 所定義的預設值
+ 如果 `.config` 存在, 運行 `$ make config/menuconfig`時, 則會使用當前`.config`的設定值
    > 若對設定進行了修改, `.config`則會被更新

+ `$ make xxx_defconfig` 會將`.../xxx_defconfig`中的設定值, load 到目前使用並生成當前的`.config`
+ `$ make savedefconfig` 則是將當前`.config`中的設定值, 經最小化處理並保存到 defconfig 中
    > 最小化處理, 表示會參考所有 Kconfig 的預設值, 並記錄與目前有差異的設定值

+ `$ make oldconfig` 是用當前 `.config`作為基礎, 按相互依賴關係, 重新生成一個`.config`檔案
    > 如果新的`.config` 和作為基礎的 `.config` 不一致, 會把基礎的`.config`重新命名為`.config.old`, 用於恢復對`.config`的修改


# Reference

+ [make defconfig savedefconfig olddefconfig區別\_make savedefconfig-CSDN部落格](https://blog.csdn.net/flc2762/article/details/103735072)
