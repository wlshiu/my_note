VMware
---





## Tips

+ 滑鼠脫離 `ctrl + alt`

+ `apt-get` 使用 `https protocol`

    - dependency libs

        ```
        $ wget https://ports.ubuntu.com/pool/universe/a/apt/apt-transport-https_2.4.13_all.deb
        $ sudo dpkg -i ./apt-transport-https_2.4.13_all.deb
        ```


    - edit sources.list

        ```
        replace http://tw.archive.canonical.com/ubuntu/ to https://mirrors.wikimedia.org/ubuntu/
        ```

+ 查詢主機 IP (內建)

    ```
    $ hostname -I
    ```

+ `Guest OS` 共用剪貼簿

    ```
    $ sudo apt-get install open-vm-tools
    $ sudo apt-get install open-vm-tools-desktop
    ```

+ SFTP 傳輸

    - dependency libs

        ```
        $ sudo apt-get install openssh-server
        ```

    - Set SSH port

        ```
        $ sudo vim /etc/ssh/sshd_config
            ...
            #Port 22  ====> unmark and set target numbur 1024 ~ 65535 (0 ~ 1023 已規範特定用途)
        ```

    - Restart SSH server

        ```
        $ service ssh restart
        ```




# Reference

+ [VMware安装Ubuntu(2024最新最全版)-CSDN博客](https://blog.csdn.net/fanyun_01/article/details/136540798)
+ [VMware虚拟机桥接方式实现上网互通\_vmware不同网段 虚拟机 互通-CSDN博客](https://blog.csdn.net/weixin_41595700/article/details/113677999)
+ [使用 Samba 把VMware 里的Ubuntu 20.04 的目录共享给Windows](https://www.skfwe.cn/p/%E4%BD%BF%E7%94%A8-samba-%E6%8A%8Avmware-%E9%87%8C%E7%9A%84ubuntu-20.04-%E7%9A%84%E7%9B%AE%E5%BD%95%E5%85%B1%E4%BA%AB%E7%BB%99windows/)

