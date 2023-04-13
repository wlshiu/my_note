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
| `-boot` a c d n                  | boot from a: floppy，c: cdrom, d: HDD, n: network |


## `-s -S`

`-s` 等同 `-gdb tcp::1234`
`-S` 啟動 gdb server, 啟動後 qemu 不立即運行 image, 而是等待 gdb client 連接


# Reference
+ [qemu參數大全](https://www.zhaixue.cc/qemu/qemu-param.html)
+ [qemu常用偏好設定說明](https://blog.csdn.net/weixin_39871788/article/details/123250595)
+ [qemu-system-x86_64命令總結](http://blog.leanote.com/post/7wlnk13/%E5%88%9B%E5%BB%BAKVM%E8%99%9A%E6%8B%9F%E6%9C%BA)
+ [qemu的詳細資料大全(入門必看!!!)](https://biao2488890051.blog.csdn.net/article/details/126299695?spm=1001.2101.3001.6650.7&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-7-126299695-blog-123250595.235%5Ev28%5Epc_relevant_t0_download&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-7-126299695-blog-123250595.235%5Ev28%5Epc_relevant_t0_download&utm_relevant_index=12)
