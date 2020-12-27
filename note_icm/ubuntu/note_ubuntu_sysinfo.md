Ubuntu system info
---

+ 查看 Ubuntu 的版本

    ```
    $ lsb_release -a
        or
    $ cat /etc/issue
    ```

+ Linux Kernel 的版本

    ```
    $ uname -a
    ```
+ CPU 資訊

    ```
    $ cat /proc/cpuinfo
    ```

+ MEM 資訊

    ```
    cat /proc/meminfo
    ```

+ 查看記憶體使用情形

    ```
    # 以 MB 的方式顯示
    $ free -m
    ```

+ 顯示卡型號

    ```
    $ lspci | grep VGA
    ```

# reference

+ [Ubuntu : 查看系統資訊 by Command](https://m.xuite.net/blog/chingwei/blog/28082882)

