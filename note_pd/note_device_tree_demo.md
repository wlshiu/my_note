Device Tree Demo [[Back](./note_kernel_module.md#device-tree)]
---

Device-Tree 起源於 `Open Firmware IEEE 1275 (OF)`, 將許多硬體的細節, 直接透過 Device-Tree 傳遞給 Linux kernel,
而不再需要在 kernel 中進行大量的 hard-code 編碼.

Device-Tree 是一種描述硬體的資料結構, 由一系列被命名的 node 和 property 組成, 而 node 本身可包含 sub-node.
所謂 property, 其實就是成對出現的 name 和 value

通常由 `.dts` (Device-Tree Source) 檔案, 以文字方式對系統設備樹進行描述, 經過 Device-Tree Compiler (DTC),
將 dts 檔案轉換成二進位檔案 `.dtb` (Binary Device-Tree Blob).

`.dtb` 檔案可由 Linux kernel 解析, 因此就可在不改動 Linux kernel 的情況下, 實現不同的平台狀況

在 kernel 中查看 Device-Tree
> 可對 `/proc/device-tree` 用 `ls`, `cat`, `tree` 等 commands 來查看

```
# tree /proc/device-tree
    ./device-tree/
    |-- #address-cells
    |-- #size-cells
    |-- aliases
    |   |-- name
    |   `-- serial0
    ...
    |   |-- compatible
    |   |-- interrupt-parent
    |   |-- interrupts
    |   |-- name
    |   `-- reg
    `-- virtio_mmio@10008000
        |-- compatible
        |-- interrupt-parent
        |-- interrupts
        |-- name
        `-- reg
```


# 基本概念

為了幫助理解 Device-Tree 的用法, 我們從一個簡單的電腦開始,  手把手建立一個 Device-Tree 來描述它

## Symbol definition

+ `/`
    > root node

+ `@`
    > 如果 device 有 address, 由此符號指定

    ```
    gpio@101F3000
    ```

+ `&`
    > 引用 node

+ `:`
    > 冒號前為 `label`, 是為了方便引用給節點起的 alias, 此 label 的一般引用方式為 `&label`

    ```
    gpioc : gpio@40020800 { ... }
    ```

    gpioc 代表是 base address 為 0x40020800 的 GPIO module,
    `&gpioc` 則表示引用 `gpio@40020800` node 的定義

+ `,`
    > 屬性名稱中, 可以使用逗號來分割, 如 compatible 屬性的名字 組成方式為 `"[manufacturer], [model]"` (加入廠商名是為了避免重名).
    自定義屬性名中通常也要有廠商名, 並以逗號分隔.

+ `#`
    > `#` 並不表示注釋, 而是表示有 specfic key-word, e.g. `#address-cells`, `#size-cells` 用來決定 reg 屬性的格式

    - `#xxx-cells` 取值時, 使用 big-endine

        ```
        0x11223344-55667788ull
        two cells as: <0x11223344 0x55667788>
        ```

+ ` `
    > 空屬性並不一定表示沒有賦值, e.g. `interrupt-controller` 一個空屬性, 用來聲明這個 node 接收中斷信號數據類型

+ `"..."`
    > 引號中的為字符串, 字符串數組: `"strint1","string2","string3"`

## Example

假設有這樣一台計算機(基於 ARM Versatile), 由`Acme`製造並命名為`Coyote's Revenge`:

一個 `ARM (32-bits) CPU` 連接到 local BUS 的 Memory mapping
+ 256MB SDRAM, 起始位址為 `0x0`
+ 兩個 serial port 起始位址為 `0x101F1000`, `0x101F2000`
+ GPIO controller, 起始位址為 `0x101F3000`
+ SPI controller 起始位址為 `0x10170000`, 並掛載以下設備:
    - MMC 插槽(SS 腳連接到 GPIO #1)
+ External bus bridge, 掛載以下設備
    - SMC SMC91111 乙太網路設備連接到 external bus, 基底位址 `0x10100000`
    - I2C controller 起始位址為 `0x10160000`, 並掛載以下設備
        1. Maxim DS1338 Real Time Clock (SlaveAddr b1101000 (0x58))
        1. 64MB NOR flash, 基底位址 `0x30000000`

### 初始結構

第一步, 先建構一個電腦的基本架構, 也就是一個有效 Device-Tree 的最小架構
> 在這一步, 要唯一地標誌這台計算機

```
/ {
    compatible = "acme,coyotes-revenge";
};
```

`compatible` 屬性以字串("xxx")的格式來指定系統名稱.
指定了具體設備和製造商名稱, 來避免命名空間的衝突是很重要的, 因為 `compatible` 是 OS 唯一能識別一台電腦所需的所有硬體資料.
如果電腦的所有細節都以 hard-code標示, 那麼 OS 可以在頂層 compatible 屬性中, 專注尋找 "acme,coyotes-revenge"

### CPU

接下來就要描述各個 CPU 了; 先加入一個**cpus**容器節點, 再將每個 CPU 當作子節點加入
> 在本例中, 系統是基於 ARM 的雙核心 Cortex A9 系統

```
/ {
    compatible = "acme,coyotes-revenge";
    cpus {
        cpu@0 {
            compatible = "arm,cortex-a9";
        };
        cpu@1 {
            compatible = "arm,cortex-a9";
        };
    };
};
```

各個 CPU 節點的 compatible 屬性是一個字串, 與頂層 compatible 屬性類似, 該字串以 `xxx,yyy` 的格式, 指定了 CPU 的確切型號.
隨後更多的屬性被加入 cpu 節點, 但首先我們需要先了解一些基本概念

### Node Naming

花點時間談談命名習慣是值得的;
每個 node 都必須有一個 `xxx@yyy` 格式的名稱, 使用簡單的 ascii 字串, 最長為 31 個 characters, 總的來說, node 命名是根據它代表什麼設備.
> 比如, 一個代表 3com 乙太網路適配器的 node, 應該命名為 `ethernet`, 而不是 3com509

如果 node 所描述的裝置有 address 的話, 就應該加上 unit-address
> unit-address 通常是用來存取裝置的主位址, 並在 node 的 reg 屬性中被列出

同層級 node 的命名必須是唯一, 但多個節點的通用名稱可以相同, 只要位址不同就行
> 即 `serial@101f1000`, `serial@101f2000`

關於節點命名的全部細節請參考 ePAPR 規範 2.2.1 節

### Device

系統中的**每個 device 皆由 Device-Tree 的一個 node 來表示**, 接下來將為 Device-Tree 新增 device node
> 在我們講到如何定址和處理中斷之前, 暫時將新節點置空

```
/ {
    compatible = "acme,coyotes-revenge";
    cpus {
        cpu@0 {
            compatible = "arm,cortex-a9";
        };
        cpu@1 {
            compatible = "arm,cortex-a9";
        };
    };

    serial@101F0000 {
        compatible = "arm,pl011";
    };

    serial@101F2000 {
        compatible = "arm,pl011";
    };

    gpio@101F3000 {
        compatible = "arm,pl061";
    };

    interrupt-controller@10140000 {
        compatible = "arm,pl190";
    };

    spi@10115000 {
        compatible = "arm,pl022";
    };

    external-bus {
        ethernet@0,0 {
            compatible = "smc,smc91c111";
        };

        i2c@1,0 {
            compatible = "acme,a1234-i2c-bus";
            rtc@58 {
                compatible = "maxim,ds1338";
        };

        flash@2,0 {
            compatible = "samsung,k8f1315ebm", "cfi-flash";
        };
    };
};

```

在上面的 Device-Tree 中, 系統中的 device node 已經加入進來, tree 的層次結構, 反映了 devices 如何連接到系統中.
外部匯流排上的 devices, 就是 `external-bus node` 的 sub-node, i2c devices 是 i2c-bus node (`i2c@...`) 的 sub-node.

總的來說, 層次結構表現的是**從 CPU 觀點來看的系統視圖**
> 目前這棵樹依然是無效的, 它缺少關於 devices 之間的連接資訊, 稍後將添加這些數據

Device-Tree 中應注意, `每個 device node 都有一個 compatible 屬性`.

flash node (`flash@...`) 的 compatible 屬性有兩個字串, 請閱讀下一節以了解更多內容
> 先前提到的, node 命名應反映 device 的類型, 而不是特定型號

請參考 ePAPR 規範 2.2.2 節的通用節點命名, 應優先使用這些命名

### `compatible` attribute

Tree 中的每個 device node, 都需要有一個 `compatible` 屬性
> compatible 是 OS 用來決定配對 device 和 device-driver 的依據

`compatible` 是 string list ("xxxx", "yyy"), list 中使用 `,` 來分割, 其中第一個字串指定 node 代表的確切 device,
而第二個字串, 代表了與該 device 相容的其他 device.
例如, Freescale MPC8349 SoC 有一個 serial port device 實作了 National Semiconductor ns16550 registers 介面,
因此 MPC8349 serial port device 的 compatible 屬性為 `compatible = "fsl,mpc8349-uart", "ns16550"`,
在此, `fsl,mpc8349-uart` 指定了確切的 device, `ns16550` 表明它與 National Semiconductor 16550 UART 是寄存器級相容的

ps. 由於歷史因素, `ns16550` 沒有製造商前綴, 所有新的 compatible 值, 都應使用 vendor 的 prefix,
這種做法使得現有的裝置驅動程式, 可以綁定到一個新裝置上, 同時仍能唯一準確的辨識硬體

warning: compatible 值不要使用通用概述符號, 如 `fsl,mpc83xx-uart` 等類似表達,
chip vendor 總是會改變並打破你的通配符假設, 到時候再想修改就為時已晚了,
相反, 你應該選擇一個特定的 chip name 實現, 並與所有後續 chip 保持相容

### address

可定址的 device 使用下列屬性, 將 address 資訊編碼進 Device-Tree

> + `reg`
> + `#address-cells`
> + `#size-cells`


每個可定址的 device 都有一個 `reg` 屬性 (region), 即以下面形式表示 (pair list)
> ```
> reg =<address-1 length-1 [address-2 length-2] [address-3 length-3] ...>
> ```

每個 pair 表示該 device 的位址範圍, 每個 addresses 值由一個或多個 32-bits integer (hex value) 組成, 被稱為做 cells,
同樣地, 長度值可以是 cells 列表, 也可以為空

既然 `address` 和 `length` 欄位是大小可變的變量, parents node 的 `#address-cells` 和 `#size-cells` 屬性, 用來說明各個 sub-node 有多少個 cells
> 換句話說, 正確解釋一個 sub-node 的 `reg` 屬性, 需要 parents node 的 `#address-cells` 和 `#size-cells` 值

下面從 CPU 開始, 新增 address 屬性到範例 Device-Tree

+ CPU Address

    Addressing 最簡單的例子就是 CPU node, 每個 CPU 都被分配一個 UID, UID 與大小無關

    ```
    / {
        compatible = "acme,coyotes-revenge";
        #address-cells = <1>;
        #size-cells = <1>;
        cpus {
            #address-cells = <1>;
            #size-cells = <0>;
            cpu@0 {
                compatible = "arm,cortex-a9";
                reg = <0>;
            };
            cpu@1 {
                compatible = "arm,cortex-a9";
                reg = <1>;
            };
        };

        serial@101F0000 {
            compatible = "arm,pl011";
        };

        serial@101F2000 {
            compatible = "arm,pl011";
        };

        gpio@101F3000 {
            compatible = "arm,pl061";
        };

        interrupt-controller@10140000 {
            compatible = "arm,pl190";
        };

        spi@10115000 {
            compatible = "arm,pl022";
        };

        external-bus {
            ethernet@0,0 {
                compatible = "smc,smc91c111";
            };

            i2c@1,0 {
                compatible = "acme,a1234-i2c-bus";
                rtc@58 {
                    compatible = "maxim,ds1338";
            };

            flash@2,0 {
                compatible = "samsung,k8f1315ebm", "cfi-flash";
            };
        };
    };
    ```

    在 cpus node 中, `#address-cells = <1>; #size-cells = <0>;`, 表示子暫存器值是一個 uint32 且不包含 length 欄位的位址
    > 在本例中, 兩個 CPU 被分配為 address 0 和 1; cpus node 的 `#size-cells = <0>;`, 是因為每個 CPU 只分配了位址值

    如果一個 node 有 `reg` 屬性, 則 node-name 必須包含 unit-address 屬性 (xxx@unit-address)
    > unit-address 值, 是 `reg` 屬性中的第一個 value
    > ```
    > cpu@0 {
    >     ...
    >     reg = <0>;
    > };
    > ```

    ps. ePAPR 中對 cell 的定義是 **一個 cell 包含 32-bits 資訊的單位**


+ Device with Memory Mapping

    與 cpus node 中的單一 address 值不同, MMP (Memory-Mapping unit) 會對 device 分配一個它能回應的 address range.
    `#size-cells` 用來說明每個 sub-node 中, reg 元組的長度大小。

    在下面的範例中, 每個 address 值是 1 cell (32-bits), 每個的 length 值也為 1 cell, 這在 32 位元系統中是非常典型的.

    64-bits 平台可以在 Device-Tree 中, 使用 `#address-cells = <2>;` 和 `#size-cells = <2>;`, 來實現 64-bits addressing

    ```
    / {
        compatible = "acme,coyotes-revenge";
        #address-cells = <1>;
        #size-cells = <1>;
        cpus {
            #address-cells = <1>;
            #size-cells = <0>;
            cpu@0 {
                compatible = "arm,cortex-a9";
                reg = <0>;
            };
            cpu@1 {
                compatible = "arm,cortex-a9";
                reg = <1>;
            };
        };

        serial@101F0000 {
            compatible = "arm,pl011";
            reg = <0x101f0000 0x1000>;
        };

        serial@101F2000 {
            compatible = "arm,pl011";
            reg = <0x101f2000 0x1000>;
        };

        gpio@101F3000 {
            compatible = "arm,pl061";
            reg = <0x101f3000 0x1000 0x101f4000 0x0010>
        };

        interrupt-controller@10140000 {
            compatible = "arm,pl190";
            reg = <0x10140000 0x1000>;
        };

        spi@10115000 {
            compatible = "arm,pl022";
            reg = <0x10115000 0x1000>;
        };

        external-bus {
            #address-cells = <2>;
            #size-cells = <1>;
            ethernet@0,0 {
                compatible = "smc,smc91c111";
                reg = <0 0 0x1000>;
            };

            i2c@1,0 {
                compatible = "acme,a1234-i2c-bus";
                reg = <1 0 0x1000>;
                rtc@58 {
                    compatible = "maxim,ds1338";
            };

            flash@2,0 {
                compatible = "samsung,k8f1315ebm", "cfi-flash";
                reg = <2 0 0x4000000>;
            };
        };
    };

    ```

    每個 device 都被分配了一個 base address 及該區域大小.
    本例中的 GPIO device, 其 address 被分成兩個範圍: `0x101f3000 ~ 0x101f3fff` 和 `0x101f4000 ~ 0x101f400f`.

    有些掛載於 Bus 上的 device 有不同的 addressing 方案.
    例如, device 也可以透過獨立 Chip-Select signal, 連接到外部匯流排.
    因為 parents node 定義了它的 sub-node 的 address range, 可根據需要選擇 address mapping 來最佳地描述該系統。.

    在外部匯流排中, 將 Chip-Select 寫進位址的裝置位址分配.
    > external-bus node 用了 2 個 cells 來表示 address 值 (一個是 Chip-Select Number, 一個是基於 Chip-Select Number 的 offset).
    length 欄位還是一個 cell, 這是因為只有 offset 的部分需要一個範圍

    > node name `...@2,0` 為 reg 第一個 address-value`<2 0 ...>` with `#address-cells = <2>;`
    > ```
    > flash@2,0 {
    >     ...
    >     reg = <2 0 0x4000000>;
    > };
    > ```

    所以, 在本例中, 每個 reg 條目包含 3 個 cells (Chip-Select Number, offset, length).
    由於 address range 包含 node 及其 sub-node, parent node 可以自由定義, 任何對 Bus 而言有意義的 addressing 方案.

+ Device without Memory-Mapping

    有些 device 不會 mapping 到 SoC internal Bus (e.g. I2C-Bus, SPI-Bus, USB-Bus),
    雖然這些 device 可以有位址範圍, 但是不能直接被 CPU 訪問, 而是由 master device 的驅動代替 CPU 來執行間接訪問.
    > 以 I2C-Device 為例, 每個 Slave 分配一個 Address, 但沒有與它相關的長度或範圍, 這與 CPU Address 定義很相似

    ```
    / {
        compatible = "acme,coyotes-revenge";
        #address-cells = <1>;
        #size-cells = <1>;
        cpus {
            #address-cells = <1>;
            #size-cells = <0>;
            cpu@0 {
                compatible = "arm,cortex-a9";
                reg = <0>;
            };
            cpu@1 {
                compatible = "arm,cortex-a9";
                reg = <1>;
            };
        };

        serial@101F0000 {
            compatible = "arm,pl011";
            reg = <0x101f0000 0x1000>;
        };

        serial@101F2000 {
            compatible = "arm,pl011";
            reg = <0x101f2000 0x1000>;
        };

        gpio@101F3000 {
            compatible = "arm,pl061";
            reg = <0x101f3000 0x1000 0x101f4000 0x0010>
        };

        interrupt-controller@10140000 {
            compatible = "arm,pl190";
            reg = <0x10140000 0x1000 >;
        };

        spi@10115000 {
            compatible = "arm,pl022";
            reg = <0x10115000 0x1000 >;
        };

        external-bus {
            #address-cells = <2>;
            #size-cells = <1>;
            ethernet@0,0 {
                compatible = "smc,smc91c111";
                reg = <0 0 0x1000>;
            };

            i2c@1,0 {
                compatible = "acme,a1234-i2c-bus";
                #address-cells = <1>;
                #size-cells = <0>;
                reg = <1 0 0x1000>;
                rtc@58 {
                    compatible = "maxim,ds1338";
                    reg = <58>;
            };

            flash@2,0 {
                compatible = "samsung,k8f1315ebm", "cfi-flash";
                reg = <2 0 0x4000000>;
            };
        };
    };
    ```

### `ranges` attribute

Address re-map or translate

我們已經討論過如何分配 address 給 device, 但在這些 address 只是 device node 可見的, 還未描述如何將這些 address 對應成 CPU-Bus memory space.
root node 是從 CPU 的角度來描述定址空間, 如果 root node 的 sub-node 已經使用了 CPU-Bus memory space, 就不需要任何明確地 mapping 了
> e.g. serial port `serial@101f0000` 直接被分配到 address `0x101f0000`

```
/ {
    compatible = "acme,coyotes-revenge";
    #address-cells = <1>;
    #size-cells = <1>;
    ...
    external-bus {
        #address-cells = <2>;
        #size-cells = <1>;
        ranges = <0 0 0x10100000 0x10000    // Chip-select 1, Ethernet
                  1 0 0x10160000 0x10000    // Chip-select 2, i2c controller
                  2 0 0x30000000 0x1000000>; // Chip-select 3, NOR Flash

        ethernet@0,0 {
            compatible = "smc,smc91c111";
            reg = <0 0 0x1000>;
        }

        i2c@1,0 {
            compatible = "acme,a1234-i2c-bus";
            #address-cells = <1>;
            #size-cells = <0>;
            reg = <1 0 0x1000>;
            rtc@58 {
                compatible = "maxim,ds1338";
                reg = <58>;
            };
        };

        flash@2,0 {
            compatible = "samsung,k8f1315ebm", "cfi-flash";
            reg = <2 0 0x4000000>;
        };
    };
};
```

`ranges` 是 **address translation table**, 由 3 個數字組成, 即

```
<child-bus-address, parent-bus-address, length>
```

+ child-bus-address
    > The `child-bus-address` is a physical address within **the child-bus' address space**.

    - 依照上例 `external-bus { #address-cells = <2>; ... }` 取 cell 數量

+ parent-bus-address
    > The `parent-bus-address` is a physical address within **the parent-bus' address space**.

    - 依照上例 `/ { ... #address-cells = <1>; ...}` 取 cell 數量

+ length
    > The `length` specifies the size of the range in **the child's address space**

    - 依照上例 `external-bus { #size-cells = <1>; ... }` 取 cell 數量


對於上例的外部匯流排, 3 個 ranges 被轉換為

+ chip-select 0 offset 0, mapping 到 `address: 0x10100000 ~ 0x1010ffff`
+ chip-select 1 offset 0, mapping 到 `address: 0x10160000 ~ 0x1016ffff`
+ chip-select 2 offset 0, mapping 到 `address: 0x30000000 ~ 0x30ffffff`

另外, 如果 parent node 和 sub-node 的 address space 是相同的, 那麼一個 node 可以加入一個空的 ranges 屬性
> 一個空的 ranges 屬性, 代表著 sub-node 的 address space 是 `1：1` 對應到 parent 的 address space

> 如果可以用`1:1 mapping`, 為什麼還需要 remapping address ?
>> 因為一些匯流排(e.g. PCI) 具有完全不同的 address space, 其細節需要展露給 OS. 其他像 DMA engine 需要知道 CPU-Bus 上的 physical address.
有時 devices 需要組合在一起, 因為他們都有相同的軟體可編程的 physical address mapping.
是否需要一一映射, 取決於 OS 所需的資訊以及硬體設計

另外在 `i2c@1,0` ndoe 上沒有 ranges 屬性
> 因 I2C-Bus 上的 device 並不是 be mapped to CPU-Bus address space, 相反, CPU 透過 `i2c@1,0` device 間接存取 `rtc@58` device.
>> ranges 屬性為空, 表示 device 不能被, 除了 parent device 以外的設備直接存取

另舉一例說明 ranges 屬性

```
soc {
    compatible = "simple-bus";
    #address-cells = <1>;
    #size-cells = <1>;
    ranges = <0x0 0xE0000000 0x00100000>;
    serial@4600 {
        device_type = "serial";
        compatible = "ns16550";
        reg = <0x4600 0x100>;
        clock-frequency = <0>;
        interrupts = <0xA 0x8>;
        interrupt-parent = <&ipic>;
    }
}
```

soc 的 ranges 屬性宣告, 從 physical address 為 `0x0` 且大小為 0x100000 (1MB) 的 child 的 address space,
mapping 到了physical address 為 `0xE0000000` 的 parent 的 address space,
有個這層映射關係, the serial device node 就可以透過 `load/store` address `0xE0004600` 來存取

當然在 64-bits OS 中也會看到這樣的映射(如下), `<... 0xf 0x00000000 ...>` 一起組成 parent 的 address space 即 0xf00000000

```
#address-cells = <2>;
dcsr: dcsr@f00000000 {
    #address-cells = <1>;
    ranges = <0x0 0xf 0x00000000 0x01072000>;
};
```

### Interrupt node

中斷訊號使用, 獨立於 tree 的 nodes 之間的連結, 描述中斷連線基本有 4 個屬性

+ `interrupt-controller`
    > 一個空的屬性, 用來標示該 node 是 **中斷控制 device**

    ```
    intc: interrupt-ctrl@10140000 {
        ...
        interrupt-controller;
    };

    ```

+ `#interrupt-cells`
    > 這是中斷控制器 node 的屬性.
    它宣告了中斷控制器的中斷說明符, 有使用多少個 cells (類似 `#address-cells` 和 `size-cells`)

+ `interrupt-parent`
    > device node 的屬性, 包含一個指向該 device 所連接中斷控制器的 Handle.

    - 為了使 Device-Tree 可以反應實際 physical layer 的層級關係
        > 有些 SoC 會將外部中斷, 先連接到一個中斷子系統 (擴充中斷數量), 再統一連接到一個 GIC (Global Interrupt Controller);
        也有 SoC 直接將外部中斷接到 GIC

    - 那些沒有 interrupt-parent 屬性的 node, 則從它們的 parent node 繼承該屬性

+ `interrupts`
    > device node 屬性, 包含 interrupt specifier list, 對應於該 device 上, 每個中斷輸出訊號的資訊
    >> 每個 `interrupt specifier` 含有幾個參數, 依照 `#interrupt-cells` 而定,
    至於每個 member 代表的意義, 則由 SoC 的 vender 決定

    `ref. <kernel_source>/Documentation/devicetree/bindings/interrupt-controller/*`

中斷說明符是一個或多個 cell 的資料(由`#interrupt-cells` 指定), 指定 device 連接到哪些中斷輸入

下面的範例中, 大多數 devices 只有一個中斷輸出, 但也有一個 device 上有多個中斷輸出的情況.
一個中斷符的意義, 完全取決於綁定的中斷控制器 device, 每個中斷控制器可以決定它需要多少 cell, 來唯一地確定一個中斷輸入.

將中斷宣告加入到下面的 DTS

```
/ {
    compatible = "acme,coyotes-revenge";
    #address-cells = <1>;
    #size-cells = <1>;
    interrupt-parent = <&intc>;
    cpus {
        #address-cells = <1>;
        #size-cells = <0>;
        cpu@0 {
            compatible = "arm,cortex-a9";
            reg = <0>;
        };

        cpu@1 {
            compatible = "arm,cortex-a9";
            reg = <1>;
        };
    };

    serial@101f0000 {
        compatible = "arm,pl011";
        reg = <0x101f0000 0x1000>;
        interrupts = < 1 0 >;
    };

    serial@101f2000 {
        compatible = "arm,pl011";
        reg = <0x101f2000 0x1000>;
        interrupts = < 2 0 >;
    };

    gpio@101f3000 {
        compatible = "arm,pl061";
        reg = <0x101f3000 0x1000
        0x101f4000 0x0010>;
        interrupts = < 3 0 >;
    };

    intc: interrupt-ctrl@10140000 {
        compatible = "arm,pl190";
        reg = <0x10140000 0x1000>;
        interrupt-controller;
        #interrupt-cells = <2>;
    };

    spi@10115000 {
        compatible = "arm,pl022";
        reg = <0x10115000 0x1000>;
        interrupts = < 4 0 >;
    };

    external-bus {
        #address-cells = <2>
        #size-cells = <1>;
        ranges = <0 0 0x10100000 0x10000    // Chipselect 1, Ethernet
                  1 0 0x10160000 0x10000    // Chipselect 2, i2c controller
                  2 0 0x30000000 0x1000000>; // Chipselect 3, NOR Flash

        ethernet@0,0 {
            compatible = "smc,smc91c111";
            reg = <0 0 0x1000>;
            interrupts = < 5 2 >;
        };

        i2c@1,0 {
            compatible = "acme,a1234-i2c-bus";
            #address-cells = <1>;
            #size-cells = <0>;
            reg = <1 0 0x1000>;
            interrupts = < 6 2 >;
            rtc@58 {
                compatible = "maxim,ds1338";
                reg = <58>;
                interrupts = < 7 3 >;
            };
        };

        flash@2,0 {
            compatible = "samsung,k8f1315ebm", "cfi-flash";
            reg = <2 0 0x4000000>;
        };
    };
};
```


### MISC node

+ Alias node

    特定節點通常透過完整路徑引用, 例如`/external-bus/ethernet@0,0`,
    但當 user 真正想知道是哪個 device 是 `eth0` 時, 這很不具有易讀性,
    Alias node 可分配一個短的 alias 給一個完整的 device path

    例如:
    ```
    aliases {
        ethernet0 = &ethernet0;
        serial0 = &serial0;
    };
    ```

    分配標識符給 device 時, 使用別名是受 OS 歡迎的

    這裡使用了一個新的語法 `property = &label;`, 該語法指定透過 label 引用的完整節點路徑, 為一個字串屬性.
    這與 `phandle = <&label>;` 不同, 它是把一個 pHandle 值插入到一個 cell

+ Chosen node

    chosen node 並不代表真正的 device, 而是作為 F/w 和 OS 之間傳遞資料的地方, 例如啟動參數.

    通常情況下, chosen node 在 DTS  source 檔案中為空, 並在開機時填bj4

    在範例中, F/w 可以新增以下 chosen node

    ```
    chosen {
        bootargs = "root=/dev/nfs rw nfsroot=192.168.1.1 console=ttyS0,115200";
    }
    ```




# Reference

+ [linux 設備樹筆記--dts 基本概念及文法 --- linux设备树笔记--dts基本概念及语法](https://e-mailky.github.io/2016-12-06-dts-introduce)
+ [Linux DTS(Device Tree Source)设备树详解之一(背景基础知识篇)](https://e-mailky.github.io/2019-01-14-dts-1)
+ [Linux DTS(Device Tree Source)设备树详解之二(dts匹配及发挥作用的流程篇)](https://e-mailky.github.io/2019-01-14-dts-2)
+ [Linux DTS(Device Tree Source)设备树详解之三(高通MSM8953实例分析篇)](https://e-mailky.github.io/2019-01-14-dts-3)


