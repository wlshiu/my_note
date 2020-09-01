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

+ directory of linux kernel

    - arch
        > 代表了一種 CPU 架構, 取決於使用的**指令集**, 也可能會使用不同的 toolchain

    - `mach-<mach>`
        > 每個`mach-<mach>`對應一種 SoC

    - `plat-<plat>`
        > platform

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
    >> interrupt nexus 需要在不同的 interrupt domains 之間進行轉譯,
    需要定義 `interrupt-map` 的屬性


+ block device
    > 以 block為單位來操作, e.g. flash

+ character device
    > 可以用 byte 為單位來操作, e.g.

+ platform device
    > 基本特徵是可以通過 CPU bus 直接尋址.
    > + 連接物理總線的 host bridges 設備.
    > + 集成在 SOC 平台上面的 controller

    - Platform Bus
        > 基於底層 bus 模塊, 抽象出一個虛擬的 Platform bus, 用於掛載 Platform 設備
    - Platform Device
        > 基於底層 device 模塊, 抽象出 Platform Device, 用於表示 Platform 設備

    - Platform Driver
        > 基於底層 device_driver 模塊, 抽象出 Platform Driver, 用於驅動 Platform 設備

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

+ 如何引用一個 node
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

+ chosen node
    > chosen node 主要用來描述由系統指定的 runtime parameter, 它並沒有描述任何硬件設備節點信息.
    原先通過 tag list 傳遞的一些 linux kernel 運行的參數, 可以通過 chosen 節點來傳遞.
    e.g. command line 可以通過 bootargs 這個 property 來傳遞.
    如果存在 chosen node, 它的 parent 節點必須為`/` 根節點.

    ```
    chosen {
        bootargs = "tegraid=40.0.0.00.00 vmalloc=256M video=tegrafb console=ttyS0,115200n8 earlyprintk";
    };
    ```

+ aliases node
    > aliases node 用來定義別名, 類似 C++ 中的 `call by reference`

    ```
    aliases {
        i2c6 = &pca9546_i2c0;
        i2c7 = &pca9546_i2c1;
        i2c8 = &pca9546_i2c2;
        i2c9 = &pca9546_i2c3;
    };
    ```

+ memory node
    > 對於 memory node, device_type 必須為 memory, 由描述可以知道該 memory node 的起始地址.
    一般而言, 在`.dts`中不對 memory 進行描述, 而是通過 `bootargs` 中類似`521M@0x00000000`的方式傳遞給 kernel


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

        1. 32-bits unsigned integers (用尖括號表示)

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

    + interrupt domain * 3
        - domain_1: open-pic, device_1, device_2, PCI host bridge
        - domain_2: PCI host bridge, slot_0, slot_1, PCI-PCI bridge
        - domain_3: PCI-PCI bridge, slot_11

    + nexus node * 2 (負責轉發 IRQ events)
        - PCI host bridge
        - PCI-PCI bridge
    ```

    - interrupt domain
        > 因為 interrupt tree 結構, leaf device 發生 IRQ 時, 會一層一層往 interrupt parent 傳遞.
        因此其他沒有關聯起來的 device nodes 會看不到 interrupt event

    - 每個能產生中斷的設備, 都可以產生一個或者多個 interrupt,
    每個 interrupt source 都是限定在其所屬的 interrupt domain 中.
        > interrupt specifier, 描述了interrupt source 的信息

+ `interrupt-parent`
    > 用來標識 H/w interrupt source 如何物理的連接到 interrupt controller.
    同時也指明了設備樹中的各個 device node 如何路由 interrupt event.
    >> 如果一個能夠產生中斷的 device node 沒有定義 `interrupt-parent`的話,
    其`interrupt-parent`屬性就會繼承自 parent node

    - `intc` 是一個 lable, 代表了某一個 device node (interrupt-controller@4a000000).
    使用`&`來引用這個 lable, 讓 DTC 自動轉換 lable 到 DTB 內

+ `interrupts`
    > 一個能產生中斷的設備, 必須要定義`interrups`這屬性.

+ `interrupt-controller`
    > 用來表示該 node 是一個 H/w interrupt-controller 而不是interrupt nexus

+ `interrupt-cells`
    > 用來表示 interrupt-controller 需要幾個 cells,
    來描述 interrupt specifier (interrupt source)

## example 3

```
/* s3c2416.dtsi at linux-3.14/arch/arm/boot/dts */

#include "s3c24xx.dtsi"
#include "s3c2416-pinctrl.dtsi"

/ {
    model = "Samsung S3C2416 SoC";
    compatible = "samsung,s3c2416";     --------- A

    cpus {                              --------- B
        #address-cells = <1>;
        #size-cells = <0>;

        cpu {
            compatible = "arm,arm926ejs";
        };
    };

    interrupt-controller@4a000000 {     --------- C
        compatible = "samsung,s3c2416-irq";
    };

...
};
```

+ `compatible = "samsung,s3c2416";`
    > 在 `s3c24xx.dtsi`文件中已經定義了 `compatible` 這個屬性,
    而 `s3c2416.dtsi`中重複定義了這個屬性.
    DTC 將**目前的 compatible 屬性**覆蓋了 `s3c24xx.dtsi`中的 compatible 屬性值

+ `cpus`
    > 對於 root 節點, 必須有一個 cpus 的 child node 來描述系統中的 CPU 信息.
    對於 CPU 的編址我們用一個 u32 整數就可以描述了,
    因此對於 cpus node, `#address-cells` 是 1, 而`#size-cells`是 0.
    其實 CPU 的 node 可以定義很多屬性, 例如 TLB, cache, 頻率等,
    不過對於ARM, 這裡只需定義了 compatible 屬性就OK了,
    arm926ejs 包括了所有的 processor 相關的信息.

+ `interrupt-controller@4a000000`
    > `s3c24xx.dtsi` 和 `s3c2416.dtsi`中都有 `interrupt-controller@4a000000`這個 node,
    DTC 會對這兩個 node 進行合併

    ```
    interrupt-controller@4a000000 {
        compatible = "samsung,s3c2416-irq";
        reg = <0x4a000000 0x100>;
        interrupt-controller;
        #interrupt-cells = <0x4>;
        linux,phandle = <0x1>;
        phandle = <0x1>;
    };
    ```

# DTB

## binary architecture

```
# DTB
+------------------------------+
|  DTB header                  |
| (struct boot_param_header)   |
+------------------------------+
|           alignment padding  |
+------------------------------+
|  memory reserve              |
|       map                    |
+------------------------------+
|           alignment padding  |
+------------------------------+
|   device-tree                |
|   structure block            |
+------------------------------+
|           alignment padding  |
+------------------------------+
|   device-tree                |
|   strings block              |
+------------------------------+
```

+ DTB header

    - `magic`
        > 用來識別 DTB 的.
        通過這個 magic, kernel 可以確定 bootloader 傳遞的參數 block 是一個 DTB 還是 tag list.

    - `totalsize`
        > DTB 的 total size

    - `off_dt_struct`
        > device tree structure block 的 offset

    - `off_dt_strings`
        > device tree strings block 的 offset

    - `off_mem_rsvmap`
        > offset to memory reserve map.
        有些系統, 我們也許會保留一些 memory 有特殊用途(例如: DTB 或者 initrd image),
        或者在有些 `DSP+ARM` 的 SOC platform上, 有寫 memory 被保留用於 ARM 和 DSP 進行信息交互.
        這些保留內存不會進入內存管理系統.

    - `version`
        > 該DTB的版本

    - `last_comp_version`
        > 兼容版本信息

    - `boot_cpuid_phys`
        > 我們從哪一個CPU (用ID標識) booting

    - `dt_strings_size`
        > device tree strings block 的 size.
        和 off_dt_strings 一起確定了 strings block 在內存中的位置

    - `dt_struct_size`
        > device tree structure block 的 size.
        和 off_dt_struct 一起確定了 device tree structure block 在內存中的位置


+ memory reserve map
    > 這個區域包括了若干的 reserve memory 描述符.
    每個 reserve memory 描述符是由 `address` 和 `size`組成.
    其中 address 和 size 都是用 `U64` 來描述

+ device tree structure
    > device tree structure block 區域是由若干的 slices 組成,
    每個 slices 開始位置都是保存了 token, 以此來描述該分片的屬性和內容.
    共計有5種token：

    > - `FDT_BEGIN_NODE` (0x00000001)
    >> 該 token 描述了一個 node 的開始位置, 緊挨著該 token 的就是 node name(包括unit address)

    > - `FDT_END_NODE` (0x00000002)
    >> 該 token 描述了一個 node 的結束位置。

    > - `FDT_PROP` (0x00000003)
    >> 該 token 描述了一個 property 的開始位置, 該 token 之後是兩個u32的數據, 分別是 `length` 和 `name offset`.
    `length` 表示該 property value data 的 size.
    `name offset` 表示該屬性字符串在 device tree strings block 的偏移值.
    length 和 name offset 之後就是長度為 length 具體的屬性值數據。

    > - `FDT_NOP` (0x00000004)

    > - `FDT_END` (0x00000009)
    >> 該 token 標識了一個 DTB 的結束位置

    - DTB 可能的結構組合

        ```
        FDT_NOP * n (optional)
        FDT_BEGIN_NODE

            node name
            paddings

            data of properties

            FDT_BEGIN_NODE
                node name
                paddings

                data of properties

                FDT_BEGIN_NODE
                    ...
                FDT_END_NODE

            FDT_END_NODE

            FDT_BEGIN_NODE
                ...
            FDT_END_NODE

            FDT_BEGIN_NODE
                ...
            FDT_END_NODE

        FDT_NOP * n (optional)
        FDT_END_NODE
        FDT_END
        ```

+ device tree strings
    > 定義了各個 node 中使用的屬性的字符串表.
    由於很多屬性會出現在多個 node 中,
    因此所有的屬性字符串組成了一個 string block (這樣可以壓縮 DTB 的 size).


# kernel flow with DTB

base kernel v3.14

+ `setup_arch()`

    ```c
    void __init setup_arch(char **cmdline_p)
    {
        const struct machine_desc *mdesc;
    ...

        mdesc = setup_machine_fdt(__atags_pointer);
        if (!mdesc)
            mdesc = setup_machine_tags(__atags_pointer, __machine_arch_type);
        machine_desc = mdesc;
        machine_name = mdesc->name;
    ...
    }
    ```

    + `__atags_pointer`
        > 把 bootloader 傳來的 r2 值, 存在 `__atags_pointer`.
        >> 紀錄 DTB 的 base address

    + `__machine_arch_type`
        > 把 bootloader 傳來的 r1 值, 存在 `__machine_arch_type`.
        >> 紀錄 machine type ID (傳統 tag list, device tree 不使用)

        - 傳統確定 HW platform 流程
            > 靜態定義若干的 `struct machine_desc`, 在啟動過程中,
            通過`machine type ID`作為索引, 在這些靜態定義的 machine description 中掃瞄,
            找到那個ID匹配的描述符.

+ 匹配 platform
    > `setup_machine_fdt()` 根據 Device Tree 的信息, 找到最適合的 machine description

    ```c
    const struct machine_desc * __init setup_machine_fdt(unsigned int dt_phys)
    {
        const struct machine_desc *mdesc, *mdesc_best = NULL;

        if (!dt_phys || !early_init_dt_scan(phys_to_virt(dt_phys)))
            return NULL;

        mdesc = of_flat_dt_match_machine(mdesc_best, arch_get_next_mach);

        if (!mdesc) {
            // error handle
        }

        /* Change machine number to match the mdesc we're using */
        __machine_arch_type = mdesc->nr;

        return mdesc;
    }
    ```

    - `early_init_dt_scan()`

        - 為 DTB scan 進行準備工作
        - 運行時參數傳遞
            > 運行所需的參數是在掃瞄 DTB 的 chosen node 時完成的,
            具體的動作就是獲取 chosen node 的 `bootargs`, `initrd`等屬性的 value,
            並將其保存在全局變量(boot_command_line, initrd_start, initrd_end)中.
            使用類似 tag list 的方法, 並通過 parsing 字串, 獲取相關信息, 保存在同樣的全局變量中.
            具體代碼位於 early_init_dt_scan()中

        ```c
        bool __init early_init_dt_scan(void *params)
        {
            if (!params)
                return false;

            /* 全局變量 initial_boot_params 指向了 DTB 的 header*/
            initial_boot_params = params;

            /* 檢查 DTB 的 magic, 確認是一個有效的 DTB */
            if (be32_to_cpu(initial_boot_params->magic) != OF_DT_HEADER) {
                initial_boot_params = NULL;
                return false;
            }

            /* 掃瞄 /chosen node, 保存運行時參數(bootargs)到 boot_command_line,
               此外, 還處理 initrd 相關的 property,
               並保存在 initrd_start 和 initrd_end 這兩個全局變量中 */
            of_scan_flat_dt(early_init_dt_scan_chosen, boot_command_line);

            /* 掃瞄根節點, 獲取 {size,address}-cells信息,
               並保存在 dt_root_size_cells 和 dt_root_addr_cells 全局變量中 */
            of_scan_flat_dt(early_init_dt_scan_root, NULL);

            /* 掃瞄 DTB 中的 memory node, 並把相關信息保存在 meminfo 中,
               全局變量 meminfo 保存了系統內存相關的信息. */
            of_scan_flat_dt(early_init_dt_scan_memory, NULL);

            return true;
        }
        ```

    - `of_flat_dt_match_machine()`
        > 在 machine description 的列表中 scan, 找到最合適的那個 machine description.

        1. `DT_MACHINE_START`和`MACHINE_END`用來定義一個 machine description
        1. compiler 把這些 machine descriptor 放到 `.arch.info.init section`, 形成 machine 描述符的 array
        1. 匹配方式則是 比較 root node 的 compatible 字符串列表,
        以及 machine 描述符的 compatible 字符串列表

+ 轉換 DTB 成 device_node

    - `unflatten_device_tree()`

        ```c
        // at drivers/of/fdt.c
        void __init unflatten_device_tree(void)
        {
            __unflatten_device_tree(initial_boot_params, &of_allnodes,
                        early_init_dt_alloc_memory_arch);

            /* Get pointer to "/chosen" and "/aliases" nodes for use everywhere */
            of_alias_scan(early_init_dt_alloc_memory_arch);
        }
        ```

    - `struct device_node`
        > 主要功能就是掃瞄 DTB, 並將 device node 組織成
        > + global list
        >> 全局變量 `struct device_node *of_allnodes` 就是指向設備樹的 global list
        > + tree

        ```c
        struct device_node {
            const char *name;           // device node name
            const char *type;           // 對應 device_type 的屬性
            phandle phandle;            // 對應該節點的 phandle 屬性
            const char *full_name;      // 從"/"開始的, 表示該 node 的 full path

            struct    property *properties; // 該節點的屬性列表
            struct    property *deadprops;  // 如果需要刪除某些屬性, kernel 並非真的刪除, 而是掛入到 deadprops 的列表
            struct    device_node *parent;  // parent, child 以及 sibling 將所有的 device node 連接起來
            struct    device_node *child;
            struct    device_node *sibling;
            struct    device_node *next;    // 通過該指針可以獲取相同類型的下一個 node
            struct    device_node *allnext; // 通過該指針可以獲取 node global list 下一個 node
            struct    proc_dir_entry *pde;  // 開放到 userspace 的 proc 接口信息
            struct    kref kref;            // 該 node 的 reference count
            unsigned long _flags;
            void    *data;
        };
        ```

    - `__unflatten_device_tree()`
        > 具體的 node scan flow

        ```c
        static void __unflatten_device_tree(struct boot_param_header *blob, // ----- 需要掃瞄的DTB
                         struct device_node **mynodes,                      // ----- global list指針
                         void * (*dt_alloc)(u64 size, u64 align))           // ----- 內存分配函數
        {
            unsigned long size;
            void *start, *mem;
            struct device_node **allnextp = mynodes;

            /* 此處刪除了 health check代碼, 例如檢查DTB header的magic, 確認blob的確指向一個DTB */

            /* scan過程分成兩輪, 第一輪主要是確定device-tree structure的長度, 保存在size變量中 */
            start = ((void *)blob) + be32_to_cpu(blob->off_dt_struct);
            size = (unsigned long)unflatten_dt_node(blob, 0, &start, NULL, NULL, 0);
            size = ALIGN(size, 4);

            /* 初始化的時候, 並不是掃瞄到一個 node 或者 property 就分配相應的內存,
               實際上內核是一次性的分配了一大片內存,
               這些內存包括了所有的 struct device_node/node name/struct property 所需要的內存 */
            mem = dt_alloc(size + 4, __alignof__(struct device_node));
            memset(mem, 0, size);

            *(__be32 *)(mem + size) = cpu_to_be32(0xdeadbeef);   // 用來檢驗後面 unflattening 是否溢出

            /* 這是第二輪的 scan, 第一次 scan 是為了得到保存所有 node 和 property 所需要的內存 size,
               第二次就是實打實的要構建 device node tree 了 */
            start = ((void *)blob) + be32_to_cpu(blob->off_dt_struct);
            unflatten_dt_node(blob, mem, &start, NULL, &allnextp, 0);


            /* 此處略去校驗溢出和校驗 OF_DT_END */
        }
        ```

## link to device driver

要加入 linux kernel 的設備驅動模型, 那麼就需要根據 device_node 的樹狀結構(root 是 of_allnodes),
將一個個的 device node, 掛入到相應的總線 device list 中.

但也不是所有的 device node 都會掛入 bus 上的設備鏈表,
像 cpus node, memory node, choose node 等

+ cpus node

    ```c
    // trace: setup_arch() -> arm_dt_init_cpu_maps()

    void __init arm_dt_init_cpu_maps(void)
    {
        /**
         *  scan device node global list, 尋找 full path 是 "/cpus" 的那個 device node.
         *  cpus 這個device node只是一個容器, 其中包括了各個 cpu node 的定義,
         *  以及所有 cpu node 共享的 property
         */
        cpus = of_find_node_by_path("/cpus");
    ...

        for_each_child_of_node(cpus, cpu) {     // 遍歷cpus的所有的 child node
            u32 hwid;

            if (of_node_cmp(cpu->type, "cpu"))  // 我們只關心那些 device_type 是 cpu 的 node
                continue;

            if (of_property_read_u32(cpu, "reg", &hwid)) {  // 讀取 reg屬性的值並賦值給 hwid
                return;
            }

            // reg 的屬性值的 8 MSBs 必須設置為 0, 這是 ARM CPU binding 定義的.
            if (hwid & ~MPIDR_HWID_BITMASK)
                return;

            // 不允許重複的 CPU id, 那是一個災難性的設定
            for (j = 0; j < cpuidx; j++)
                if (WARN(tmp_map[j] == hwid, "Duplicate /cpu reg "
                                 "properties in the DT\n"))
                    return;

            /**
             *  array tmp_map 保存了系統中所有 CPU 的 MPIDR 值(CPU ID值), 具體的 index 的編碼規則是
             *  tmp_map[0] 保存了 booting CPU 的 id值,
             *  其餘的 CPU 的 ID 值保存在 1 ~ NR_CPUS 的位置
             */
            if (hwid == mpidr) {
                i = 0;
                bootcpu_valid = true;
            } else {
                i = cpuidx++;
            }

            tmp_map[i] = hwid;
        }

    ...

        // 根據 DTB 中的信息設定 cpu logical map array
        for (i = 0; i < cpuidx; i++) {
            set_cpu_possible(i, true);
            cpu_logical_map(i) = tmp_map[i];
        }
    }
    ```

+ memory node

    ```c
    // trace: setup_arch() -> setup_machine_fdt()
    //          -> early_init_dt_scan() -> early_init_dt_scan_memory()

    int __init early_init_dt_scan_memory(unsigned long node, const char *uname,
                         int depth, void *data)
    {
        char *type = of_get_flat_dt_prop(node, "device_type", NULL); // 獲取 device_type 屬性值
        __be32 *reg, *endp;
        unsigned long l;

        /**
         *  在初始化的時候, 我們會對每一個device node都要調用該call back函數,
         *  因此, 我們要過濾掉那些和 memory block 定義無關的node.
         *  和 memory block 定義有的節點有兩種, 一種是 node name 是 memory@ 形態的,
         *  另外一種是 node 中定義了 device_type 屬性並且其值是 memory
         */
        if (type == NULL) {
            if (depth != 1 || strcmp(uname, "memory@0") != 0)
                return 0;
        } else if (strcmp(type, "memory") != 0)
            return 0;

        /**
         *  獲取 memory 的起始地址和length的信息.
         *  有兩種屬性和該信息有關,
         *  一個是 linux,usable-memory,
         *  不過最新的方式還是使用reg屬性.
         */
        reg = of_get_flat_dt_prop(node, "linux,usable-memory", &l);
        if (reg == NULL)
            reg = of_get_flat_dt_prop(node, "reg", &l);
        if (reg == NULL)
            return 0;

        endp = reg + (l / sizeof(__be32));

        /**
         *  reg 屬性的值是 address, size 數組, 那麼如何來取出一個個的 address/size 呢?
         *  由於 memory node 一定是 root node 的 child,
         *  因此 dt_root_addr_cells(root node 的 '#address-cells'屬性值)
         *  和 dt_root_size_cells(root node 的'#size-cells'屬性值)之和
         *  就是 address, size 數組的 entry size.
         */
        while ((endp - reg) >= (dt_root_addr_cells + dt_root_size_cells)) {
            u64 base, size;

            base = dt_mem_next_cell(dt_root_addr_cells, &reg);
            size = dt_mem_next_cell(dt_root_size_cells, &reg);

            early_init_dt_add_memory_arch(base, size);  // 將具體的 memory block 信息加入到內核中.
        }

        return 0;
    }
    ```

+ interrupt controller
    > 只有該 node 中有 interrupt-controller 這個屬性定義,
    那麼 linux kernel 就會分配一個 interrupt controller 的描述符(struct intc_desc)並掛入隊列.
    通過 `interrupt-parent` 屬性, 可以確定各個 interrupt controller 的層次關係.
    在 scan 了所有的 Device Tree 中的 interrupt controller 的定義之後, 系統開始匹配過程.
    一旦匹配到了interrupt chip 列表中的項次後, 就會調用相應的初始化函數.
    如果CPU是 S3C2416 的話, 匹配到的是 irqchip 的初始化函數是 s3c2416_init_intc_of

    ```c
    // driver/irqchip/irq-s3c24xx.c
    IRQCHIP_DECLARE(s3c2416_irq, "samsung,s3c2416-irq", s3c2416_init_intc_of);
    IRQCHIP_DECLARE(s3c2410_irq, "samsung,s3c2410-irq", s3c2410_init_intc_of);
    ```

    - initialize IRQ

        ```c
        // machine description of interrupt controller of S3C2416
        DT_MACHINE_START(S3C2416_DT, "Samsung S3C2416 (Flattened Device Tree)")
        ...
            .init_irq    = irqchip_init,
        ...
        MACHINE_END

        void __init irqchip_init(void)
        {
            of_irq_init(__irqchip_begin);
        }

        start_kernel() --> init_IRQ() --> machine_desc->init_irq()
        ```

        1. `__irqchip_begin`
            > 所有的 irqchip 的一個 list

        1. `of_irq_init()`
            > 遍歷 Device Tree, 尋找匹配的 irqchip

            ```c
            void __init of_irq_init(const struct of_device_id *matches)
            {
                struct device_node *np, *parent = NULL;
                struct intc_desc *desc, *temp_desc;
                struct list_head intc_desc_list, intc_parent_list;

                INIT_LIST_HEAD(&intc_desc_list);
                INIT_LIST_HEAD(&intc_parent_list);

                /**
                 *  遍歷所有的 node, 尋找定義了 interrupt-controller 屬性的 node,
                 *  如果定義了 interrupt-controller 屬性則說明該 node 就是一個中斷控制器.
                 */
                for_each_matching_node(np, matches) {
                    if (!of_find_property(np, "interrupt-controller", NULL) ||
                            !of_device_is_available(np))
                        continue;

                    /**
                     *  分配內存並掛入鏈表, 當然還有根據 interrupt-parent 建立 controller 之間的父子關係.
                     *  對於 interrupt controller, 它也可能是一個樹狀的結構.
                     */
                    desc = kzalloc(sizeof(*desc), GFP_KERNEL);
                    if (WARN_ON(!desc))
                        goto err;

                    desc->dev = np;
                    desc->interrupt_parent = of_irq_find_parent(np);
                    if (desc->interrupt_parent == np)
                        desc->interrupt_parent = NULL;
                    list_add_tail(&desc->list, &intc_desc_list);
                }

                /**
                 *  正因為 interrupt controller 被組織成樹狀的結構, 因此初始化的順序就需要控制,
                 *  應該從根節點開始, 依次遞進到下一個 level 的 interrupt controller.
                 */
                while (!list_empty(&intc_desc_list)) {
                    /**
                     *  intc_desc_list 鏈表中的節點會被一個個的處理, 每處理完一個節點就會將該節點刪除,
                     *  當所有的節點被刪除, 整個處理過程也就是結束了.
                     */

                    list_for_each_entry_safe(desc, temp_desc, &intc_desc_list, list) {
                        const struct of_device_id *match;
                        int ret;
                        of_irq_init_cb_t irq_init_cb;

                        /**
                         *  最開始的時候 parent 變量是 NULL, 確保第一個被處理的是 root interrupt controller.
                         *  在處理完 root node 之後, parent 變量被設定為 root interrupt controller,
                         *  因此, 第二個循環中處理的是所有 parent 是root interrupt controller 的 child interrupt controller.
                         *  也就是level 1(如果root是level 0的話)的節點
                         */
                        if (desc->interrupt_parent != parent)
                            continue;

                        list_del(&desc->list);      // 從鏈表中刪除
                        match = of_match_node(matches, desc->dev); // 匹配並初始化
                        if (WARN(!match->data,      // match->data是初始化函數
                            "of_irq_init: no init function for %s\n",
                            match->compatible)) {
                            kfree(desc);
                            continue;
                        }

                        irq_init_cb = (of_irq_init_cb_t)match->data;
                        ret = irq_init_cb(desc->dev, desc->interrupt_parent); // 執行初始化函數
                        if (ret) {
                            kfree(desc);
                            continue;
                        }

                        // 處理完的節點放入 intc_parent_list 鏈表, 後面會用到
                        list_add_tail(&desc->list, &intc_parent_list);
                    }

                    /**
                     *  對於 level 0, 只有一個 root interrupt controller,
                     *  對於level 1, 可能有若干個 interrupt controller,
                     *  因此要遍歷這些 parent interrupt controller, 以便處理下一個 level 的 child node.
                     */
                    desc = list_first_entry_or_null(&intc_parent_list,
                                    typeof(*desc), list);
                    if (!desc) {
                        pr_err("of_irq_init: children remain, but no parents\n");
                        break;
                    }
                    list_del(&desc->list);
                    parent = desc->dev;
                    kfree(desc);
                }

                list_for_each_entry_safe(desc, temp_desc, &intc_parent_list, list) {
                    list_del(&desc->list);
                    kfree(desc);
                }
            err:
                list_for_each_entry_safe(desc, temp_desc, &intc_desc_list, list) {
                    list_del(&desc->list);
                    kfree(desc);
                }
            }
            ```

    - reg property of interrupt controller
        > 以 s3c2416 的 interrupt controller為例, 其`#interrupt-cells`的屬性值是 `4`,
        表示會使用 4 個參數
        > + `ctrl_num`
        >> 表示使用哪一種類型的 interrupt controller
        > + `parent_irq`
        >> 對於 sub controller, parent_irq 標識了其在 main controller 的 bit position
        > + `ctrl_irq`
        >> 標識了在 controller 中的 bit 位置
        > + `type`
        >> 標識了該中斷的 trigger type, 例如: 上升沿觸發還是電平觸發


+ initialize machine

    - backtrace

        ```c
        start_kernel()
            -> rest_init()
                -> kernel_init()
                    -> kernel_init_freeable()
                        -> do_basic_setup()
                            -> do_initcalls()
                                -> customize_machine()
        ```

    - `customize_machine()`
        > 一般會調用 machine 描述符中的 init_machine method,
        來把各種 Device Tree 中定義的 platform device 設備節點加入到系統
        (即 platform bus 的所有的子節點, 對於 device tree 中其他的設備節點,
        需要在各自 bus controller 初始化的時候自行處理)

        > 如果 machine 描述符中沒有定義 init_machine 函數,
        那麼直接調用 of_platform_populate() 把所有的 platform device 加入到 kernel 中
        >> of_platform_populate() 會遍歷 device node global list 中所有的node,
        並調用 of_platform_bus_create() 處理

        ```c
        static int __init customize_machine(void)
        {
            if (machine_desc->init_machine)
                machine_desc->init_machine();
            else
                of_platform_populate(NULL, of_default_bus_match_table, NULL, NULL);

            return 0;
        }
        arch_initcall(customize_machine);
        ```

        ```c
        static int of_platform_bus_create(struct device_node *bus,  // 要創建的那個 device node
                          const struct of_device_id *matches,       // 要匹配的 list
                          const struct of_dev_auxdata *lookup,      // 附屬數據
                          struct device *parent, bool strict)       // parent 指向父節點. strict 是否要求完全匹配
        {
            const struct of_dev_auxdata *auxdata;
            struct device_node *child;
            struct platform_device *dev;
            const char *bus_id = NULL;
            void *platform_data = NULL;
            int rc = 0;

            /* 刪除確保device node有compatible屬性的代碼 */

            auxdata = of_dev_lookup(lookup, bus);  // 在傳入的lookup table尋找和該device node匹配的附加數據
            if (auxdata) {
                bus_id = auxdata->name;            // 如果找到, 那麼就用附加數據中的靜態定義的內容
                platform_data = auxdata->platform_data;
            }

            /**
             *  ARM 公司提供了CPU core, 除此之外, 它設計了 AMBA 的總線來連接 SOC 內的各個 block.
             *  符合這個總線標準的 SOC 上的外設叫做 ARM Primecell Peripherals.
             *  如果一個 device node 的 compatible 屬性值是 'arm,primecell'的話,
             *  可以調用 of_amba_device_create() 來向 amba 總線上增加一個 amba device.
             */
            if (of_device_is_compatible(bus, "arm,primecell")) {
                of_amba_device_create(bus, bus_id, platform_data, parent);
                return 0;
            }

            /**
             *  如果不是 ARM Primecell Peripherals,
             *  那麼我們就需要向 platform bus 上增加一個 platform device 了
             */
            dev = of_platform_device_create_pdata(bus, bus_id, platform_data, parent);
            if (!dev || !of_match_node(matches, bus))
                return 0;

            /**
             *  一個 device node 可能是一個橋設備,
             *  因此要重複調用 of_platform_bus_create() 來把所有的 device node 處理掉
             */
            for_each_child_of_node(bus, child) {
                pr_debug("   create child: %s\n", child->full_name);
                rc = of_platform_bus_create(child, matches, lookup, &dev->dev, strict);
                if (rc) {
                    of_node_put(child);
                    break;
                }
            }
            return rc;
        }
        ```

        > 具體增加 platform device 的代碼在 of_platform_device_create_pdata() 中

        ```c
        static struct platform_device *of_platform_device_create_pdata(
                            struct device_node *np,
                            const char *bus_id,
                            void *platform_data,
                            struct device *parent)
        {
            struct platform_device *dev;

            if (!of_device_is_available(np))    // check status屬性, 確保是 enable 或者 OK 的.
                return NULL;

            /**
             *  of_device_alloc 除了分配 struct platform_device 的內存,
             *  還分配了該 platform device 需要的 resource 的內存(參考 struct platform_device 中的 resource 成員).
             *  當然, 這就需要解析該 device node 的 interrupt 資源以及 memory address 資源
             */
            dev = of_device_alloc(np, bus_id, parent);
            if (!dev)
                return NULL;

            /* 設定 platform_device 中的其他成員 */
            dev->dev.coherent_dma_mask = DMA_BIT_MASK(32);
            if (!dev->dev.dma_mask)
                dev->dev.dma_mask = &dev->dev.coherent_dma_mask;
            dev->dev.bus = &platform_bus_type;
            dev->dev.platform_data = platform_data;

            if (of_device_add(dev) != 0) {  // 把這個 platform device 加入統一設備模型系統中
                platform_device_put(dev);
                return NULL;
            }

            return dev;
        }
        ```

# reference

+ [Device Tree(一):背景介紹](http://www.wowotech.net/linux_kenrel/why-dt.html)
+ [Device Tree(二):基本概念](http://www.wowotech.net/linux_kenrel/dt_basic_concept.html)
+ [Device Tree(三):代碼分析](http://www.wowotech.net/linux_kenrel/dt-code-analysis.html)
+ [Device Tree 詳解](https://www.twblogs.net/a/5b7c4ca12b71770a43da5338)
+ [Linux DTS(Device Tree Source)裝置樹詳解之一(背景基礎知識篇)](https://www.itread01.com/content/1547001725.html)

+ [*linux ARM設備樹](https://zhuanlan.zhihu.com/p/74314042)
    - uboot下的相關結構體
    - DTB加載及解析過程 (uboot)

+ [Booting ARM Linux](http://www.simtec.co.uk/products/SWLINUX/files/booting_article.html)