Qemu options
---

| 參數                              |  說明                                          |
| :-                               | :-                                            |
| `-M` vexpress-a9                 | 指定要模擬的 machine (開發板): vexpress-a9        |
| `-m` 512M                        | 指定 DRAM 記憶體大小為 512MB                      |
| `-cpu` cortex-a9                 | 指定 CPU 架構                                   |
| `-smp` n                         | CPU 的個數 (default = 1)                        |
| `-kernel` ./zImage               | 要運行的 image                                  |
| `-dtb` ./vexpress-vap-ca9.dtb    | 要載入的 DeviceTree 檔案                         |
| `-append` cmdline                | 設定 Linux kernel 命令列, 啟動參數                |
| `-initrd` file_path              | 使用 Host 上的 raw file, 作為初始化 ram disk      |
| `-nographic`                     | 非圖形化啟動                                     |
| `-sd` rootfs.ext3_path           | 使用 Host 上的 rootfs.ext3 作為 SD card ISO      |
| `-net` nic                       | 建立一個網路卡                                    |
| `-net` nic -net tap              | 將開發板網路卡和主機網路卡建立橋接(Bridge)           |
| `-mtdblock` file_path            | 使用 Host 上的 raw file, 作為 external Flash ISO |
| `-cdrom` file_path               | 使用 Host 上的 raw file, 作為 CDROM ISO          |
| `-display` vnc= display          | 設定顯示後端類型                                  |
| `-vnc` display                   | `-display vnc=` 的簡寫形式                      |
| `-display` none                  | default: `-vnc localhost:0,to=99,id=default`  |
| `-boot` a c d n                  | boot from a: floppy, c: cdrom, d: HDD, n: network |

+ 標準選項

    ```
    # qemu的標準選項主要涉及指定主機型別、CPU模式、NUMA、軟碟機裝置、光碟機裝置及硬體裝置等。
    -name name              # 虛擬機器名稱
    -M machine              # 指定要模擬的主機型別, 如standard PC, ISA-only PC或Intel-Mac等, 可以使用 "qemu-kvm -M ?" 獲取所支援的所有型別
    -m megs                 # 設定虛擬機器的RAM大小
    -cpu model              # 設定CPU模型, 如coreduo、qemu64等, 可以使用 "qemu-kvm -cpu ?" 獲取所支援的所有模型
    -smp n                  # 設定模擬的SMP架構中 CPU 的個數
        [,cores=cores]      # 每個CPU的核心數
        [,threads=threads]  # 執行緒數
        [,sockets=sockets]  # CPU的socket數目
        [,maxcpus=maxcpus]  # 用於指定熱插入的CPU個數上限
    -numa   非一致記憶體訪問
    -numa opts: 指定模擬多節點的numa 裝置

    -fda file:
    -fdb file: 使用指定檔案(file)作為軟盤映像, file為 /dev/fd0 表示使用物理軟碟機
    -hda file:
    -hdb file:
    -hdc file:
    -hdd file: 使用指定file作為硬碟映像
    -cdrom file: 使用指定file作為CD-ROM映像, 需要注意的是-cdrom和-hdc不能同時使用: 將file指定為 /dev/cdrom 可以直接使用物理光碟機

    -drive                          # 定義一個硬碟裝置: 可用子選項有很多
        file=/path/to/somefile      # 硬碟映像檔案
        if=interface                # 硬碟裝置介面型別 ide、scsi、sd、virtio（半虛擬化）
        index=index                 # 設定同一種控制器型別中不同裝置的索引號, 即標識號
        media=media                 # 定義介質型別為硬碟還是光碟disk、cdrom
        snapshot=snapshot           # 指定當前硬碟裝置是否支援快照功能: on或off
        cache=cache                 # 定義如何使用物理機快取來訪問塊數據, 其可用值有 none、writeback、unsafe 和 writethrough 四個
        format=format               # 指定映像檔案的格式, 具體格式可參見 qemu-img 命令

    -boot [order=drives][,once=drives][,menu=on|off]    # 定義啟動裝置的引導次序, 每種裝置使用一個字元表示:
                                                        # 不同的架構所支援的裝置及其表示字元不盡相同,
                                                        # 在x86 PC架構上,
                                                        # a、b表示軟碟機,
                                                        # c表示第一個光碟機裝置,
                                                        # n-p表示網路適配器, 預設為硬碟裝置.
                                                        # 例如: -boot order=dc,once=d
    ```

+ Network 選項

    ```
    nic #定義網路介面
        # 建立一個新的網絡卡裝置並連線至 vlan n 中:
        # PC架構上預設的 NIC 為 e1000,
        # macaddr 用於為其制定 mac 地址,
        # name 用於指定一個在監控時顯示的網上裝置名稱.
        # qemu可以模擬多個型別的網絡卡裝置,
        # 如: virtio、i82557b、i82559er、ne2k_isa、pcnet、
        #     rtl8139、e1000、smc91c111、lance及mcf_fec等.
        # 不過, 不同平臺架構上, 其支援的型別可能只包含前述列表中的一部分,
        # 可以使用 'qemu-system-x86_64 -net nic,model=?' 來獲取目前平臺支援的型別
        # ps. 逗號沒空格

        -net nic [,vlan=n,macaddr=n,model=type,name=name,addr=addr,vectors=v]
            vlan                # vlan號
            macaddr             # mac地址(mac 預設不變)
            model               # e1000 virtio
            name                # 裝置名
            addr                # ip地址

    tap # nic 管理虛擬機器中的介面, tap 就是管理宿主機上的對應介面
        # 通過物理機的 TAP 網路介面連線至 vlan n 中,
        # 使用 'script=file' 指定的指令碼(預設為'/etc/qemu-ifup')來配置目前網路介面,
        # 並使用 'downscript=file' 指定的指令碼(預設為'/etc/qemu-ifdown')來撤銷介面配置.
        # 使用'script=no'和'downscript=no'可分別用來禁止執行指令碼.
        # ps. 逗號沒空格

        -net tap[,vlan=n][,name=name][,fd=h][,ifname=name][,script=file][,downscript=dfile]

    user    # 在使用者模式配置網路棧, 其不依賴於管理許可權; 有效選項有

        -net user[,option][,option][,...]
            vlan=n              # 連線至 vlan n, 預設 n=0
            name=name           # 指定介面的顯示名稱, 常用於監控模式中
            net=addr[/mask]     # 設定 GuestOS 中可見的 IP網路, 掩碼可選, 預設為 '10.0.2.0/8'
            host=addr           # 指定 GuestOS 中看到的物理機的IP地址, 預設為指定網路中的第二個, 即 x.x.x.2
            dhcpstart=addr      # 指定 DHCP 服務地址池中, 16個地址的起始IP, 預設為第16個至第31個, 即 x.x.x.16-x.x.x.31
            dns=addr            # 指定 GuestOS 可見的 dns 伺服器地址, 預設為 GuestOS 網路中的第3個地址, 即 x.x.x.3
            tftp=dir            # 啟用內建的 tftp 伺服器, 並使用指定的 dir 作為 tftp 伺服器的預設根目錄
            bootfile=file       # BOOTP 檔名稱, 用於實現網路引導 GuestOS ,
                                # 如: 'qemu -hda linux.img -boot n -net user,tftp=/tftpserver/pub,bootfile=/pexlinux.0'
    ```


+ Display 選項

    ```
    SDL
     -sdl                           # 啟用SDL

    VNC
     -vnc display [option, option]   # 預設情況下, qemu使用SDL顯示VGA輸出;
                                     # 使用-vnc選項, 可以讓qemu監聽在vnc上, 並將VGA輸出重定向至vnc會話,
                                     # 使用此選項時, 必須使用-k選項指定鍵盤佈局型別;
                                     # 其中有許多子選項, 具體請參考qemu的手冊
        display
            1. host:N                        # N為控制檯號
                192.168.1.1:1                # 5900為起始埠
            2. unix:/path/to/socket_file     # 監聽在套接字
            3. none                          # 不顯示
        option
            password                        # 連線時需要驗證密碼, 設定密碼通過 monitor 介面使用 change
            reverse                         # "反向"連線至某處於監聽狀態的 vnc view上

    -vga type                       # 指定要模擬的VGA介面型別, 常見的型別有:
            cirrus  : Cirrus Logic GD5446顯示卡
            std     : 帶有Bochs VBI擴充套件的標準VGA顯示卡
            vmware  : VMware SVGA-II相容的顯示適配器
            qxl     : QXL半虛擬化顯示卡: 與VGA相容, 在Guest中安裝qxl驅動后能以很好的方式工作, 在使用spice協議時推薦使用此型別
            none    : 禁用VGA卡

    -monitor stdio          # 在標準輸入輸出上顯示monitor界面
    -nographic              # 預設情況下, qemu使用SDL來顯示VGA輸出, 而此選項用於禁止圖形介面,
                            # 此時, qemu類似一個簡單的命令列程式, 其模擬串列埠裝置將被重定向到控制檯
    -curses                 # 禁止圖形介面, 並使用curses/ncurses作為互動介面
    -alt-grab               # 使用Ctrl+Alt+Shift組合鍵釋放滑鼠
    -ctrl-grab              # 使用右Ctrl鍵釋放滑鼠
    -spice option[,option[,...]]    # 啟用spice遠端桌面協議: 其中有許多子選項, 具體請參照qemu-kvm手冊。
    ```


## `-s -S`

`-s` 等同 `-gdb tcp::1234`
`-S` 啟動 gdb server, 啟動後 qemu 不立即運行 image, 而是等待 gdb client 連接並下達 continue command


# Reference
+ [qemu參數大全](https://www.zhaixue.cc/qemu/qemu-param.html)
+ [qemu常用偏好設定說明](https://blog.csdn.net/weixin_39871788/article/details/123250595)
+ [qemu-system-x86_64命令總結](http://blog.leanote.com/post/7wlnk13/%E5%88%9B%E5%BB%BAKVM%E8%99%9A%E6%8B%9F%E6%9C%BA)
+ [qemu的詳細資料大全(入門必看!!!)](https://biao2488890051.blog.csdn.net/article/details/126299695?spm=1001.2101.3001.6650.7&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-7-126299695-blog-123250595.235%5Ev28%5Epc_relevant_t0_download&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-7-126299695-blog-123250595.235%5Ev28%5Epc_relevant_t0_download&utm_relevant_index=12)
