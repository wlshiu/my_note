decive tree
---

Device Tree 是一種描述硬體的資料結構, 它起源於 OpenFirmware (OF)

# definitions

+ DTS/DTC/DTB

    ```
    DTS (Device Tree source file)
        --> DTC (Device Tree Compiler)
            -->  DTB (Device Tree binary or Device Tree blob)
                --> bootloader (將儲存在 flash 中的 DTB copy到 memory)
                    --> kernel
    ```

+ `Blob` (Binary Large Object)
    > 表示的是二進位檔案集合的資料內容

+ `of_xxx` api
    > **Open Firmware API**, 用來與 device tree 建立對應關係



# reference

+ [Device Tree（一）：背景介紹](http://www.wowotech.net/linux_kenrel/why-dt.html)
+ [Device Tree（二）：基本概念](http://www.wowotech.net/linux_kenrel/dt_basic_concept.html)
+ [Device Tree（三）：代碼分析](http://www.wowotech.net/linux_kenrel/dt-code-analysis.html)

+ [Linux DTS(Device Tree Source)裝置樹詳解之一(背景基礎知識篇)](https://www.itread01.com/content/1547001725.html)
