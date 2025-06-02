VMware
---

滑鼠脫離 `ctrl + alt`

## `apt` supports HTTPS protocol

+ dependency

    ```
    $ wget https://ports.ubuntu.com/pool/universe/a/apt/apt-transport-https_2.4.13_all.deb
    $ sudo dpkg -i ./apt-transport-https_2.4.13_all.deb
    ```


+ edit sources.list

    ```
    replace http://tw.archive.canonical.com/ubuntu/ to https://mirrors.wikimedia.org/ubuntu/
    ```

## SSH

+ dependency

    ```
    $ sudo apt-get install ssh openssh-server
    ```

+ Configure SSH-Daemon

    - 更改預設 SSH port

        ```
        $ sudo vim /etc/ssh/sshd_config
            ...

            #Port 22  ====> unmark and set target numbur 1024 ~ 65535 (0 ~ 1023 已規範特定用途)
        ```

        1. 測試新的 SSH port
            > + `ss` cmd

            ```
            $ ss -tulpn | grep [NEW-PORT]
                ...
                tcp    LISTEN     0      128       *:[NEW-PORT]            *:*                   users:(("sshd",pid=2946,fd=3))
                ...
            ```

            > + `netstat` cmd
            ```
            $ netstat -tulpn | grep [NEW-PORT]
                ...
                tcp        0      0 0.0.0.0:[NEW-PORT]          0.0.0.0:*               LISTEN      2946/sshd
                ...
            ```

    - Restart SSH server

        ```
        $ sudo service ssh restart
        ```

    - 使用 `ssh` cmd 登入

        ```
        $ ssh -p [forwarding-port] [user-name]@[host-ip]    # e.g. ssh -p 1688 root@123.123.123.123
        ```

## Samba

+ dependency

    ```
    $ sudo apt-get install samba samba-common
    ```

+ configure network interface

    - In global VMware
        > `Edit` -> `Virtual Netowrk Editor` -> `Change Settings` (Admin)

        ```
        Name   | Type      | External Connection | Host Connected | DHCP    | Subnet Address
        VMnet1 | Host-only | -                   | Connected      | Enabled | 192.168.52.0
        VMnet8 | NAT       | NAT                 | Connected      | Enabled | 192.168.156.0
        ```

        1. vmnet1
            > + Subnet IP: `192.168.52.0`
            > + Subnet mask: `255.255.255.0`
            > + DHCP Setting: `192.168.52.100` ~ `192.168.52.254`

    - In a Virtual Machine
        1. `Edit virtual machine settings` -> `Add` -> `Network Adapter`

        1. `Network Adapter`
            > Set to NAT mode

        1. `Network Adapter 2`
            > Set to Host-only

+ configure samba

    ```
    $ sudo vi /etc/samba/smb.conf
        [global]

            min protocol = SMB2

        ...

        # keep file attributes
        map archive = no
        map hidden = no
        map read only = no
        map system = no
        store dos attributes = yes

        [samba_share]
            Comment = Shared Folder
            Path = /home/<user-name>/
            public = yes
            writable = yes
            read only = no
            valid users = <user-name>
            force directory mode = 0775 #0777
            force create mode = 0644 #0777
            force security mode = 777
            force directory security mode = 777
            hide dot file = no
            create mask = 0644 #0777
            directory mask = 0775 #0777
            delete readonly = yes
            guest ok = yes
            available = yes
            browseable = yes

    $ sudo service smbd restart
    ```



## Network Interface

+ Bridged Networking
    > 如果你的主機在一個區網中, 這種方法是將你的 VMware Workstation 接入網路的其中一種常用的方法. <br>
    虛擬機就像一個新增加的且與主機有著同等地位的一台電腦, **橋接模式(Bridged)**可以享受所有可用的服務(包括檔案服務、列印服務等等).
    >> 也就是說在此模式下, 區網中的電腦也能發現此虛擬機, 並和虛擬機互通.

    > 如果你在新增虛擬機的時候, 選擇了`Bridged networking`或者是選擇了標準的設定流程, 那麼預設的橋接模式網路會自動設定. <br>
    如果你的主機在一個以設定好的區網中, 那麼選擇用橋接模式的網路, 會是讓你的虛擬機連上網絡一種簡單的方式
    >> 如果你選擇了橋接模式的網路連接的話, VMware Workstation 需要它自己一個獨立的網路連線. 比如說在TCP/IP架構的網路底下, 虛擬機需要一個單獨的IP連線

+ Network Address Translation (NAT)
    > NAT 可以讓你的 Virtual Machine 連上網路, 也是 VMware Workstation 推薦的方式. <br>
    它藉由 **Host OS**的撥號網路或寬頻連線, 來連上 Internet或者其他TCP/IP網路, 但無法讓的 **Virtual Machine**得到一個外部網路 IP 位址
    >> 如果使用者在`New Virtual Machine Wizard`裡面選擇了`Use network address translation`, 會自動地建立 NAT 連線

    > **Host OS** 被當作 IP 分享器, 而 ** Guest OS** 則是內部電腦

    -  NAT 模式預設會自動派發 IP (DHCP Server), 當然你可以在 Virtual Network Editor 裡設定要不要起動 DHCP Server

    - 如果你之前在`New Virtual Machine Wizard`選擇了其他模式, 但後來決定使用 NAT 的話,
    可以在`Virtual machine settings editor(VM -> Settings)`裡面進行設定

+ Host Only Networking
    > Host-only 模式是用來建立一個完全隔離的虛擬主機環境, 可以方便網路管理者, 用來測試與實驗各種不同的網路環境, 在不同的作業系統下的執行效能. <br>
    由於`Host-only`是完全隔離的一個環境, 因此外界網路無法連線進來, 可以安全地進行實驗

    > 在這種模式的底下, VMware Workstation 與 Host 會通過一個**私有的虛擬網路**進行網路連線,
    >> 在這個虛擬網路底下, 只有同為Host-only模式, 且在同一個虛擬交換機的連接下的主機或是虛擬主機, 才可以互相溝通, 外界的網路無法連線進來

    > `Host only模式`只能使用私人IP, IP/Gateway/DNS 等資源都由 VMnet 來分配


## Tips


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

    - dependency

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

