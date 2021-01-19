Kconfig
---

kconfig 全看使用者的創意及使用方式, 用的好可以很強大, 用不好就只是一個前段

# 特點

+ 友善的互動式前端

    - 可搜尋 option 並查看 help, 可達到某個程度的文件說明

+ 支援 option 相依或互斥關係, 可以輕鬆建立好 options 間的關係
    > 大量減少不必要的選項

+ 多樣的變數型態 `int`, `bool`, `string`
    > 用的好, defconfig 內容可以變的更簡潔

+ 多樣的 key word, 因應不同的需求, 限縮配置的範圍
    - `memu` 可多選
    - `choice` 只允許單選
    - `range` 可以在配置時期, 就可以先避免錯誤

+ defconfig 方便配置 option, 也容易和別人同步 project configuration
    > 也容易做 CI

+ 檢查是否有同名的 option (double check)
    > makefile 有可能就被覆蓋過去
    >> 有多少人知道 makefile 中 `?=`, `:=`, `=` 之間的差異

+ 同時輸出 `config` 及 `config.h`
    > option naem 在 makefile 及 source code 都是一致的
    >> makefile 用 `SUPPORT_XXX`, source code 用 `ENABLE_XXX`, 這...

    - include global `confi.h` 可以省去 `CFLAGS+= -Dxxx` 這種煩人的動作
        > 更期望一個跳轉就可以看到 option 定義,
        而不是 grep 出一堆結果, 然後再去猜是哪一個,
        甚至又用另一個 option 去隔 if/else

    - 只要在 kconfig 添加好 option, makefile 及 source code 就可以直接使用,
    不需要到處東改一點西改一點.
        > 修改的地方越少越可以減少人工錯誤機會


