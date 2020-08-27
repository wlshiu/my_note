decive tree
---

Device Tree 是一種描述硬體的資料結構, 它起源於 OpenFirmware (OF).

由一系列被命名的結點(node)和屬性(property)組成, 而結點本身可包含子結點.
所謂屬性, 其實就是成對出現的 name 和 value.

基本上就是畫一棵電路板上 CPU, 匯流排, 裝置組成的樹,
Bootloader 會將這棵樹傳遞給 kernel, 然後 kernel 可以識別這棵樹,
並根據它展開出 Linux kernel 中的 platform_device, i2c_client, spi_device等裝置,
而這些裝置用到的 memory, IRQ等資源, 也被傳遞給了 kernel,
核心會將這些資源繫結給展開的相應的裝置.

> 可以動態探測到的 device 是不需要描述在 device tree 中


# definitions

+ DTS/DTC/DTB

    ```
    DTS (Device Tree source file)
        --> DTC (Device Tree Compiler)
            -->  DTB (Device Tree binary or Device Tree blob)
                --> bootloader (將儲存在 flash 中的 DTB copy到 memory)
                    --> kernel
    ```

+ `dtsi` file
    > dts 文件可以通過 include 某些 `*.dtsi`來作為配置的基礎, 在此基礎上添加或覆蓋原有內容
    >> 類似於 C 語言的 header file

+ `Blob` (Binary Large Object)
    > 表示的是二進位檔案集合的資料內容

+ `of_xxx` api
    > **Open Firmware API**, 用來與 device tree 建立對應關係

+ Interrupt Nexus
    > 中斷聯結, 路由子設備的中斷訊號給中斷控制器



## overview

```
# NOT the real DTS file

device-tree/
    name = "device-tree"
    model = "MyBoardName"
    compatible = "MyBoardFamilyName"
    #address-cells = <2>
    #size-cells = <2>
    linux,phandle = <0>

    - cpus
        name = "cpus"
        linux,phandle = <1>
        #address-cells = <1>
        #size-cells = <0>

        - PowerPC,970@0
            name = "PowerPC,970"
            device_type = "cpu"
            reg = <0>
            clock-frequency = <0x5f5e1000>
            64-bit
            linux,phandle = <2>

    - memory@0
        name = "memory"
        device_type = "memory"
        reg = <0x00000000 0x00000000 0x00000000 0x20000000>
        linux,phandle = <3>

    - chosen
        name = "chosen"
        bootargs = "root=/dev/sda2"
        linux,phandle = <4>
```

+ 除了`root` node, 每個 node 都只有一個 parent
+ 一個 device tree 文件中只能有一個 root node
    > **root node 的 node name 必須是'/'**

+ 每個 node 中包含了若干的 property/value 來描述該 node 的一些特性

+ 每個 node 用節點名字(node name)標識, 節點名字的格式是`node-name@unit-address`.
    > 如果該 node 沒有 reg屬性, 那麼該節點名字中不能包括 `@`和`unit-address`.

    - `unit-address`的具體格式是和設備掛在那個 bus上相關
        > + 以 CPU 來說, 其 `unit-address`就是從 0 開始編址, 依序編號
        > + 以 ethernet controller 來說, 其`unit-address`就是 register base address

+ 如何引用一個node
    > 指定唯一一個 node 必須使用 full path.
    cpu node 可以通過 `/cpus/PowerPC,970@0` 訪問

+ property
    > 標識了設備的特性, 它的值(value)是多種多樣的:
    > + 可能是空, 也就是沒有值的定義.
    >> 例如上圖中的 64-bit, 這個屬性沒有賦值.
    > + 可能是一個`u32`/`u64`的數值, 也可能是一個數組, 例如 `<0x00000000 0x00000000 0x00000000 0x20000000>`
    >> 值得一提的是 `cell` 這個術語, 在 Device Tree 表示 `32bits` 的信息單位, 例如`#address-cells = <1>`.
    > + 可能是一個字串, 當然也可能是一個 string list
    >> e.g. `device_type = "memory"` or `name = "PowerPC,970"`


# DTS syntax

```
# 一個node被定義成如下

[label:] node-name[@unit-address] {
   [properties definitions]
   [child nodes]
}
```

+ `[]`的部分表示 optional
+ `label` 方便在 dts 文件中引用
+ `child node` 的格式和 node 是完全一樣的
    > 一個 dts 文件中可嵌套多個 node, property 以及 child note, child note property 描述

## example 1

```
/ {
    #address-cells = <1>;
    #size-cells = <1>;
    chosen { };
    aliases { };
    memory {
        device_type = "memory";
        reg = <0 0>;
    };
};
```

+ `/` 是根節點的 node name
+ `{`和`}`之間的內容是該節點的具體的定義, 其內容包括各種屬性的定義以及 child node or sub-node 的定義

+ `chosen`, `aliases`和`memory`都是 sub-node
    > sub-node 的結構和 root node 是完全一樣的, 故 sub-node 也有自己的屬性和它自己的 sub-node,
    最終形成了一個樹狀的 device tree

+ 屬性的定義採用 `property = value` 的形式
    > `#address-cells` 和 `#size-cells` 就是 property, 而 `<1>` 就是 value

    - value 的種類

        1. string or string list (用雙引號表示)

            ```
            device_type = "memory"
            ```

        1. 32bits unsigned integers (用尖括號表示)

            ```
            #size-cells = <1>
            ```

        1. binary data (用方括號表示)

            ```
            binary-property = [0x01 0x23 0x45 0x67]
            ```

+ property `device_type`
    > 定義了該 node 的設備類型, e.g cpu, serial, memory 等

+ property `reg`
    > 定義了訪問該 device node 的地址信息.
    描述格式為 `reg <address, size>`, 其值可以為任意長度.
    >> 具體用多長的數據來表示 `address` 和 `size`,
    是在其 parent node 中定義`#address-cells`和`#size-cells`

+ `#address-cells` and `#size-cells` 用來描述 memory address 特性
    > `#` 是 number 的意思

    - `#address-cells`
        > 這個屬性是用來表達 current node 中, property `reg` 的 `address` 要用幾個 cell (1 cell = u32) 來描述

    - `#size-cells`
        > 這個屬性是用來表達 current node 中, property `reg` 的 `size` 要用幾個 cell (1 cell = u32) 來描述


+ `memory node`是所有設備樹文件的必備節點, 它定義了系統 physical 內存的 layout
    > 其`device_type`必須等於 `memory`.
    `reg` 則描述 memory 的起始地址和長度.

    - exampe
        > 64-bits platform 且 physical memory 分成兩段
        > + RAM: starting address 0x0, length 0x80000000 (2GB)
        > + RAM: starting address 0x100000000, length 0x100000000 (4GB)

        ```
        / {
            #address-cells = <2>; /* 64-bits 需要 2 個 cells*/
            #size-cells = <2>;    /* 64-bits 需要 2 個 cells*/
            memory {
                device_type = "memory";
                reg = <0x00000000 0x00000000 0x00000000 0x80000000
                       0x00000001 0x00000000 0x00000001 0x00000000>;
            };
        };

            or

        / {
            #address-cells = <2>; /* 64-bits 需要 2 個 cells*/
            #size-cells = <2>;    /* 64-bits 需要 2 個 cells*/

            memory@0 {
                device_type = "memory";
                reg = <0x00000000 0x00000000 0x00000000 0x80000000>;
            };

            memory@100000000  {
                device_type = "memory";
                reg = <0x00000001 0x00000000 0x00000001 0x00000000>;
            };
        };
        ```

## example 2

```
#include "skeleton.dtsi"

/ {
    compatible = "samsung,s3c24xx"; --------- A
    interrupt-parent = <&intc>;     --------- B

    aliases {
        pinctrl0 = &pinctrl_0;      --------- C
    };

    intc:interrupt-controller@4a000000 { ---- D
        compatible = "samsung,s3c2410-irq";
        reg = <0x4a000000 0x100>;
        interrupt-controller;
        #interrupt-cells = <4>;
    };

    serial@50000000 {               -------- E
        compatible = "samsung,s3c2410-uart";
        reg = <0x50000000 0x4000>;
        interrupts = <1 0 4 28>, <1 1 4 28>;
        status = "disabled";
    };

    pinctrl_0: pinctrl@56000000 {   -------- F
        reg = <0x56000000 0x1000>;

        wakeup-interrupt-controller {
            compatible = "samsung,s3c2410-wakeup-eint";
            interrupts = <0 0 0 3>,
                     <0 0 1 3>,
                     <0 0 2 3>,
                     <0 0 3 3>,
                     <0 0 4 4>,
                     <0 0 5 4>;
        };
    };
...
};
```

+ `#include "skeleton.dtsi"`
    > 一般 dtsi 本身會有一個 root node `/`, 在上例則有兩個 root node 出現.
    >> Device Tree Compiler 會對 DTS 的 node 進行合併, 最終生成的 DTB 只有一個 root node


+ `compatible`
    > kernel 用來判斷是什麼 machine type, 並匹配適合的 driver

    ```
    compatible = "manufacturer,model","model",...
    ```

    - 第一個字串說明結點代表的確切裝置, 其後的字串則說明可相容的其他裝置
        > 前面的是特指, 後面的則涵蓋更廣的範圍
        >> 假設定義該屬性為 `compatible = "aaaaaa", "bbbbb"`.
        那麼 kernel 可能首先使用 aaaaaa 來匹配適合的driver,
        如果沒有匹配到, 那麼使用字符串 bbbbb 來繼續尋找適合的 driver

    - `compatible = "samsung,s3c24xx";`
        > 指明了 samsung 是生產商, s3c24xx 是model類型, 具體描述的是哪一個系列的SOC

+ interrupt tree
    > 也就是說 interrupt 也是一個樹狀結構 (抽象的連結各個 interrupt device),
    有可能和 device tree 不一樣.

    ```
    open-pic (root of the interrupt tree)
        ├─ device_1
        ├─ device_2
        ├─ PCI host bridge
            ├─ slot_0
            ├─ slot_1
            ├─ PCI-PCI bridge
                ├─ slot_11

    * interrupt domain * 3
        - domain_1: open-pic, device_1, device_2, PCI host bridge
        - domain_2: PCI host bridge, slot_0, slot_1, PCI-PCI bridge
        - domain_3: PCI-PCI bridge, slot_11

    * nexus node * 2 (負責轉發 IRQ events)
        - PCI host bridge
        - PCI-PCI bridge
    ```

    - interrupt domain
        > 因為 interrupt tree 結構, leaf device 發生 IRQ 時, 會一層一層往 interrupt parent 傳遞.
        因此其他沒有關聯起來的 device nodes 會看不到 interrupt event

+ `interrupt-parent`
    > 用來標識 H/w interrupt source 如何物理的連接到 interrupt controller
    >> 如果一個能夠產生中斷的 device node 沒有定義 `interrupt-parent`的話,
    其`interrupt-parent`屬性就會繼承自 parent node


    - `intc` 是一個 lable, 代表了某一個 device node (interrupt-controller@4a000000).
    使用`&`來引用這個 lable, 讓 DTC 自動轉換 lable 到 DTB 內

+ `interrupts`
    > 一個能產生中斷的設備, 必須要定義`interrups`這屬性.

+ `interrupt-controller`
    > 用來表示 H/w interrupt-controller

+ `interrupt-cells`
    > 用來表示 interrupt-controller 需要幾個 cells,
    來描述 interrupt specifier (interrupt source)


# of-API hook DTB



# reference

+ [Device Tree(一):背景介紹](http://www.wowotech.net/linux_kenrel/why-dt.html)
+ [Device Tree(二):基本概念](http://www.wowotech.net/linux_kenrel/dt_basic_concept.html)
+ [Device Tree(三):代碼分析](http://www.wowotech.net/linux_kenrel/dt-code-analysis.html)
+ [Device Tree 詳解](https://www.twblogs.net/a/5b7c4ca12b71770a43da5338)
+ [Linux DTS(Device Tree Source)裝置樹詳解之一(背景基礎知識篇)](https://www.itread01.com/content/1547001725.html)


+ [Booting ARM Linux](http://www.simtec.co.uk/products/SWLINUX/files/booting_article.html)