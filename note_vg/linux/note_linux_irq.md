Linux IRQ
---

linux 將 IRQ handle 分成了兩個部分:
* Top Half
    > + `全程關閉中斷, 離開時再打開中斷`
    > + 必須即時操作, e.g. clear IRQ.
    > + 共用 IRQ 時, 需盡快讓出占用時間

* Bottom Half
    > + deferable task, 屬於不那麼緊急需要處理的事情, e.g. move data to system memory
    > + 在執行 bottom half 的時候, 是開中斷的


```
                    |
                    v
                H/w IRQ (PIC/GIC)
                    |
                    v
                kernel IRQ
                sub-system
                    |
                    v
                Core selection
                    |
                    v
                TOP half
                    |
                    v
        +------ has SoftIRQ
        |           |
        |           v
        |       Bottom helf
        |           |
        v           v
```

# Definitions

+ PIC (Programmable Interrupt Controller)
    > 通常指 H/w 的 中斷控制器

+ GIC (Generic Interrupt Controller)
    > ARM 研發的一個通用的 H/w 中斷控制器, e.g. GIC-400, GIC-500, ...etc.

    - source code at `kernel/drivers/irqchip/irq-gic.c`

    - ARM 平台上一般把中斷分為三種類型, PPI, SPI, 和SGI

        1. SPI (shared processor interrupts)
        1. SGI (software generated interrupts)
            > SGI 是通過 S/w 寫入 GIC 的 `GICD_SGIR` register 而觸發的中斷,
            它可以用於 cores 之間的通信
        1. PPI (per processor interrupts)
            > PPI 類型的中斷和 SPI 一樣屬於外設的中斷,
            區別就是它會被送到其私有的 core 上, 而和其他的 core 無關

+ IPI (Inter-Processor Interrupt)
    > multi-cores interrupt

+ IRQ number
    > 這個 IRQ number 是一個虛擬的 interrupt ID, 和硬件無關,
    僅僅是被 kernel 用來標識一個外設中斷

+ HW interrupt ID
    > Interrupt H/w controller 用來標識外設的中斷.
    HW interrupt ID 在不同的 Interrupt H/w controller 上是會不同.
    >> 以 kernel來說, 希望 device 能得到相同的 IRQ number,
    而不會因 interrupt H/w controller 不同而不同.
    因此, linux kernel IRQ sub-system 需要提供一個將 HW interrupt ID 映射到 IRQ number 上的機制

+ device driver
    > 外設 device 的 driver

## linxu directory

```
    /           根目錄, 只能包含目錄, 不能包含具體文件.
    |- bin      存放可執行文件. 很多命令就對應/bin目錄下的某個程序, 例如 ls、cp、mkdir. /bin目錄對所有用戶有效.
    |- dev      硬件驅動程序. 例如聲卡、磁盤驅動等, 還有如 /dev/null、/dev/console、/dev/zero、/dev/full 等文件.
    |- etc      主要包含系統配置文件和用戶、用戶組配置文件.
    |- lib      主要包含共享庫文件, 類似於Windows下的DLL; 有時也會包含內核相關文件.
    |- boot     系統啟動文件, 例如Linux內核、引導程序等.
    |- home     用戶工作目錄(主目錄), 每個用戶都會分配一個目錄.
    |- mnt      臨時掛載文件系統. 這個目錄一般是用於存放掛載儲存設備的掛載目錄的, 例如掛載 CD-ROM 的 cdrom 目錄.
    |- proc     操作系統運行時, 進程(正在運行中的程序)信息及內核信息(比如cpu、硬盤分區、內存信息等)存放在這裡.
               proc目錄是偽裝的文件系統 proc 的掛載目錄, proc 並不是真正的文件系統.
    |- tmp      臨時文件目錄, 系統重啟後不會被保存.
    |- usr      user目錄下的文件比較混雜, 包含了管理命令、共享文件、庫文件等, 可以被很多用戶使用.
    |- var      主要包含一些可變長度的文件, 會經常對數據進行讀寫, 例如日誌文件和打印隊列裡的文件.
    |- sbin 和 bin 類似, 主要包含可執行文件, 不過一般是系統管理所需要的, 不是所有用戶都需要
```

# Concepts

+ linux kernel interrupt sub-system

```

                    +----------------+
                    | device drivers |
                    +----------------+
                             |
    -------------------------|---------------------------
    IRQ framework            |
                             v
                    +-------------------+
                    |     kernel IRQ    |
                    |       subsys      |
                    +-------------------+
                        |           |
                        v           v
        +-------------------+   +-------------------+
        | CPU architecture  |   |    HAL of IRQ     |
        | (single core/SMP) |   | (struct irq_chip) |
        +-------------------+   +-------------------+
                    |                      |
    ----------------|----------------------|---------------
    H/w             |                      |
                    v                      v
                +--------+          +-------------+             +-------+
                | Core_0 |          |  interrupt  |  IRQ   +----| dev 0 |
                | Core_1 |          |  controller | signal |    +-------+
                | ...    |          |  (PIC/GIC)  |<------>|        ...
                | Core_n |          +-------------+        |    +-------+
                +--------+                                 +----| dev n |
                                                                +-------+
```

## kernel IRQ sub-system

具體的使用場景是在 CPU 相關的處理函數中,
程序會讀取 HW interrupt ID,
並轉成 IRQ number, 調用對應的 `irq event handler`

+ device node (in Device tree) 和 irq chip

    - 靜態註冊 irq chip driver

        1. macro `IRQCHIP_DECLARE` (in irqchip.h)
            > 初始化了一個 `struct  of_device_id` 的靜態常量,
            並放置在 `.section  __irqchip_of_table` 中.

            >> `irq-gic.c` 中使用 IRQCHIP_DECLARE 來定義了數個靜態的 struct of_device_id 常量,
            e.g. `IRQCHIP_DECLARE(cortex_a9_gic, "arm,cortex-a9-gic", gic_of_init);`

            > GIC 其初始化函數都是 `gic_of_init`.
            compiler 會把所有的 macro IRQCHIP_DECLARE 定義的數據,
            放入到 memory 的 `__irqchip_of_table section`中, 我們將這個 section 叫做 `irq chip table`.
            這個 table 保存了 kernel 支援的中斷控制器 ID 信息.

            > `struct of_device_id` 這個數據結構主要被用來進行 Device node 和 irq chip driver 進行匹配用的.
            從該數據結構的定義可以看出, 在匹配過程中,
            `device name`, `device type` 和 `DT compatible string` 都是考慮的因素.
            更細節的內容請參考 `__of_device_is_compatible`函數

            ```c
            struct of_device_id {
                char    name[32];
                char    type[32];
                char    compatible[128];
                const void *data;
            };
            ```

    - 宣告 device node (in Device tree)
        > 通過 Device tree 的機制來傳遞.
        可以通過查看 `Documentation/devicetree/bindings/arm/gic.txt` 文件來確認配置規則

        ```
        intc: interrupt-controller@fff11000 {
                compatible = "arm,cortex-a9-gic";
                #interrupt-cells = <3>;
                #address-cells = <1>;
                interrupt-controller;
                reg = <0xfff11000 0x1000>,
                      <0xfff10100 0x100>;
            };
        ```

    - device node 配對 irq chip driver
        > 在系統啟動 machine 初始化的時候會調用 `irqchip_init` 函數進行 irq chip driver 的初始化

        ```c
        // at driver/irqchip/irqchip.c
        void __init irqchip_init(void)
        {
            of_irq_init(__irqchip_begin);
        }
        ```

        1. `__irqchip_begin` 就是內核 `irq chip table` 的 base address,
            > `irq chip table` 保存了 kernel 支持的所有的中斷控制器的 of_device_id 信息.

        1. `of_irq_init` 在所有的 device nodes 中尋找中斷控制器的 node, 並形成樹狀結構
            > 系統可以有多個 interrupt H/w controller, 之所以形成中斷控制器的樹狀結構,
            是為了讓系統中所有的中斷控制器驅動, 按照一定的順序進行初始化

            >> 在 `of_irq_init` 執行前, 系統已經完成了 device tree 的初始化,
            因此所有的 device nodes 都已經形成了一個 tree, 每個 node 代表一個設備的 device node

            > 從 root interrupt H/w controller 節點開始, 對每一個 interrupt H/w controller 的 device node,
            和 `irq chip table` 進行比對, 一旦匹配就調用該 interrupt H/w controller 的初始化函數,
            並把該中斷控制器的 device node 以及 parent 中斷控制器的 device node,
            作為參數傳遞給 `irq chip driver`.
            更詳細的信息可以參考 Device Tree 代碼分析文檔

    - 初始化 GIC `gic_of_init()`
        > `gic_of_init()` 調用的最關鍵的函數就是 `gic_init_bases()`, 它完成了主要的工作,
        其中就包括了 `irq domain`的註冊, 通過 `irq_domain_add_legacy()` 完成了註冊過程,

    - `irq domain` (Hardware IRQ number translation object)
        > 主要是建立 `hwirq` 和內核中的 `irq num` 之間的 mapping 關係.
        並且在 run-time 中, 負責對中斷號進行轉換並處理.

        1. `struct irq_domain_ops`
            > 提供 irq domain 的操作子

            ```c
            struct irq_domain_ops {
                int (*match)(struct irq_domain *d, struct device_node *node);
                int (*map)(struct irq_domain *d, unsigned int virq, irq_hw_number_t hw);
                void (*unmap)(struct irq_domain *d, unsigned int virq);
                int (*xlate)(struct irq_domain *d, struct device_node *node,
                         const u32 *intspec, unsigned int intsize,
                         unsigned long *out_hwirq, unsigned int *out_type);
            };
            ```

        1. `irq_domain_add_legacy()`
            > 創建並註冊 irq_domain 相關的資料, e.g. `irq_domain_ops`, `mapping method`, ...etc.
            >> `gic_irq_domain_ops` 定義了 mapping method

    - `set_handle_irq()` at `arch/arm/kernel/irq.c`
        > 註冊 IRQ Handler 到 platform 的 irq 處理接口中.
        當 CPU 發生了中斷時, 最先調用的 ISR, 然後在此 ISR 中進行 irq domain 處理

        > + root GIC 註冊 `gic_handle_irq()` 到 CPU 中斷服務程序入口
        >> 中斷來的時候會最先調用這個函數, 它中會讀取 GIC register 獲得 hwirq, 並且查找對應的 irq num.
        `irq_find_mapping()` 是查找 irq domain 中映射關係的關鍵函數.
        然後會調用 handle_IRQ 來處理對應的 irq num, 緊接著會調用相應的上層 IRQ Handler


## irq domain

隨著 linux kernel 的發展, 系統複雜度加大, 外設 device 增加其中斷數據也隨之增加,
因此需要多個 interrupt H/w controller 進行串接.

系統中所有的 interrupt H/w controller 會形成樹狀結構,
對於每個 interrupt H/w controller 都可以連接多個外設的中斷請求 (我們稱之 interrupt source),
interrupt H/w controller 會對連接其上的 interrupt source(根據其在 Interrupt controller 中物理特性)進行編號(也就是HW interrupt ID).
但這個編號僅僅限制在本 interrupt H/w controller 範圍內.

以軟件架構來說, 更希望對各式各樣的 interrupt H/w controller 進行抽象化,
對如何進行 HW interrupt ID 到 IRQ number 的對應關係上進行進一步的抽象化, irq domain 的概念也因應而生.

+ 註冊 irq domain

    - Linear mapping
        > 其實就是一個 lookup table, 以 HW interrupt ID 作為 index, 通過查表獲取對應的 IRQ number.
        對於 Linear map 而言, interrupt H/w controller 對其 HW interrupt ID 進行編碼的時候,
        要滿足一定的條件: hw ID不能過大, 而且ID排列最好是緊密的

        ```c
        static inline struct irq_domain *irq_domain_add_linear(struct device_node *of_node,
                             unsigned int size,                 // 該 interrupt domain 支持多少 IRQ
                             const struct irq_domain_ops *ops,  // callback函數
                             void *host_data)                   // driver私有數據
        {
            return __irq_domain_add(of_node, size, size, 0, ops, host_data);
        }
        ```

    - Radix Tree mapping
        > 建立一個 Radix Tree (key-value) 來維護 HW interrupt ID 到 IRQ number 映射關係.
        HW interrupt ID 作為 lookup key, 在 Radix Tree 檢索到 IRQ number.
        如果的確不能滿足線性映射的條件, 可以考慮 Radix Tree map
        >> 實際上, 內核中使用 Radix Tree map 的只有 PowerPC 和 MIPS 的硬件平台

        ```c
        static inline struct irq_domain *irq_domain_add_tree(struct device_node *of_node,
                             const struct irq_domain_ops *ops,
                             void *host_data)
        {
            return __irq_domain_add(of_node, 0, ~0, 0, ops, host_data);
        }
        ```

    - No mapping (directly control)
        > 有些中斷控制器很強, 可以通過 registers 配置 HW interrupt ID 而不是由物理連接決定的.
        例如 PowerPC 系統使用的 MPIC (Multi-Processor Interrupt Controller).
        在這種情況下, 不需要進行映射, 我們直接把 IRQ number 寫入 HW interrupt ID 配置寄存器就OK了,
        這時候, 生成的 HW interrupt ID 就是 IRQ number, 也就不需要進行 mapping 了

        ```c
        static inline struct irq_domain *irq_domain_add_nomap(struct device_node *of_node,
                             unsigned int max_irq,
                             const struct irq_domain_ops *ops,
                             void *host_data)
        {
            return __irq_domain_add(of_node, 0, max_irq, max_irq, ops, host_data);
        }
        ```

+ 建立 irq domain 的 map method
    > 註冊 irq domain 時, 具體 HW interrupt ID 和 IRQ number 的映射關係都還是空的.
    對於各個 irq domain 如何管理對應所需要的 database 還是需要建立的,
    e.g. Linear mapping 的 irq domain, 我們需要建立線性映射的 lookup table,
    而 Radix Tree map, 我們要把那個反應 IRQ number 和 HW interrupt ID 的 Radix tree 建立起來.
    >> kernel 提供 4 種方式建立

    - `irq_create_mapping()`
        > 建立 HW interrupt ID 和 IRQ number 的映射關係.
        該接口函數以 irq domain 和 HW interrupt ID 為參數, 返回 IRQ number(這個 IRQ number 是動態分配的)

        ```c
        extern unsigned int irq_create_mapping(struct irq_domain *host,
                                                irq_hw_number_t hwirq);
        ```

    - `irq_create_strict_mappings()`
        > 用來為一組 HW interrupt ID 建立映射

        ```c
        extern int irq_create_strict_mappings(struct irq_domain *domain,
                                                unsigned int irq_base,
                                                irq_hw_number_t hwirq_base,
                                                int count);
        ```

    - `irq_create_of_mapping()`
        > 到函數名字中的 of(open firmware), 就可知道這個接口是利用 device tree 進行映射關係的建立

        ```c
        extern unsigned int irq_create_of_mapping(struct of_phandle_args *irq_data);
        ```

        > 通常, 一個普通設備的 device tree node 已經描述了足夠的中斷信息, 在這種情況下,
        該設備的驅動在初始化的時候可以調用 `irq_of_parse_and_map()`,
        來進行該 device node 中斷內容(interrupts 和 interrupt-parent 屬性)的分析, 並建立映射關係.

        > 對於一個使用 Device tree 的普通驅動程序(我們推薦這樣做),
        基本上初始化需要調用 `irq_of_parse_and_map()` 獲取 IRQ number,
        然後調用 `request_threaded_irq()` 來申請 device 自己的 ISR.

    - `irq_create_direct_mapping()`
        > 這是給 no map 類型的 interrupt H/w controller 使用的

+ data structure

    - `struct irq_domain_ops`
        > 提供 irq domain 的操作子

        ```c
        struct irq_domain_ops {
            int     (*match)(struct irq_domain *d, struct device_node *node);
            int     (*map)(struct irq_domain *d, unsigned int virq, irq_hw_number_t hw);
            void    (*unmap)(struct irq_domain *d, unsigned int virq);
            int     (*xlate)(struct irq_domain *d, struct device_node *node,
                            const u32 *intspec, unsigned int intsize,
                            unsigned long *out_hwirq, unsigned int *out_type);
        };
        ```

        1. `xlate()` 語義是翻譯(translate)的意思, 那麼到底翻譯什麼呢?
        在 DTS 文件中, 各個使用中斷的 device node 會通過一些屬性 (e.g interrupts 和 interrupt-parent 屬性),
        來提供中斷信息給 kernel, 以便 kernel 可以正確的進行 driver 的初始化動作.
        這裡, interrupts 屬性所表示的 interrupt specifier,
        只能由具體的 interrupt H/w controller (也就是 irq domain)來解析.
        而 xlate 函數就是將指定的設備(node 參數)上若干個 (intsize 參數) 中斷屬性(intspec 參數),
        翻譯成 HW interrupt ID (out_hwirq 參數)和 trigger 類型(out_type).
        比如 `#interrupt-cells = <3>;` 對中斷控制器來說,
        描述該 field 中的一個 interrupt 需要三個 cell 來表示,
        那麼這三個 cell 就是通過 xlate 來解析的.

        1. `match()` 是判斷一個指定的 interrupt H/w controller(node 參數),
        是否和一個 irq domain 匹配(d 參數), 如果匹配的話, 返回 1.
        實際上, 內核中很少定義這個callback函數,
        `struct irq_domain`中有一個 of_node 指向了對應的 interrupt H/w controller 的 device node,
        因此, 如果不提供該函數, 那麼 default 的匹配函數,
        就會判斷 irq domain 的 of_node 成員是否等於傳入的 node 參數.

        1. `map()` 和 `unmap()` 是操作相反的函數, 我們描述其中之一就OK了.
        調用 map函數的時機是在創建(或者更新) HW interrupt ID (hw 參數)和 IRQ number (virq 參數)關係的時候.
        其實, 從發生一個中斷到調用該中斷的 handler 僅僅調用一個 `request_threaded_irq()` 是不夠的,
        還需要針對該 irq number 設定:

            i. 設定該 IRQ number 對應的中斷描述符(struct irq_desc) 的 `irq chip`

            i. 設定該 IRQ number 對應的中斷描述符(struct irq_desc) 的 `highlevel irq-events handler`

            i. 設定該 IRQ number 對應的中斷描述符(struct irq_desc) 的 `irq chip data`

            ```c
            irq_set_chip_and_handler(irq, &gic_chip, handle_fasteoi_irq);
            set_irq_flags(irq, IRQF_VALID | IRQF_PROBE);
            irq_set_chip_data(irq, d->host_data);
            ```
            > `irq_set_chip_and_handler()` 是用來設置 `struct irq_chip` 和對應的上層 IRQ Handler,
            一般內核中斷子系統已經實現了相應的函數, 我們只需要按需賦值即可,
            它負責對一個 irq num 調用所有通過 irq_request 註冊的 irq handler.
            我們稱之為上層中斷服務程序

        這些設定不適合由具體的硬件驅動來設定, 因此在 Interrupt H/w controller,
        也就是 irq domain 的 callback函數中設定.

    - `struct irq_domain`
        > irq domain 的 handle

        ```c
        struct irq_domain {
            struct list_head  link;
            const char      *name;
            const struct    irq_domain_ops *ops;   // callback函數
            void            *host_data;

            /* Optional data */
            struct device_node              *of_node; // 該interrupt domain對應的interrupt controller的device node
            struct irq_domain_chip_generic  *gc; // generic irq chip的概念, 本文暫不描述

            /* reverse map data. The linear map gets appended to the irq_domain */
            irq_hw_number_t     hwirq_max;          // 該domain中最大的那個HW interrupt ID
            unsigned int        revmap_direct_max_irq;
            unsigned int        revmap_size;        // 線性映射的size, for Radix Tree map和no map, 該值等於0
            struct radix_tree_root revmap_tree;     // Radix Tree map使用到的radix tree root node
            unsigned int        linear_revmap[];    // 線性映射使用的lookup table
        };
        ```

        1. linux kernel 中, 所有的 irq domain 被掛入一個 global link list `static LIST_HEAD(irq_domain_list);`.
        透過 `irq_domain_list` 這個 pointer, 可以獲取整個系統中 HW interrupt ID 和 IRQ number 的 mapping DB.
        `host_data` 定義了 interrupt H/w controller 使用的私有數據, 和具體的 interrupt H/w controller 相關資訊.
        對於 GIC, 該指針指向一個 `struct gic_chip_data`數據結構.

        1. members for Linear mapping

            i. `linear_revmap` 保存了一個線性的 lookup table, index是 HW interrupt ID, table 中保存了 IRQ number 值

            i. `revmap_size` 等於線性的 lookup table 的 size.

            i. `hwirq_max` 保存了最大的 HW interrupt ID

            i. `revmap_direct_max_irq`沒有用, 設定為 0

            i. `revmap_tree` 沒有用.

        1. members for Radix Tree map

            i. `linear_revmap`沒有用, `revmap_size`等於 0.

            i. `hwirq_max`沒有用, 設定為一個最大值.

            i. `revmap_direct_max_irq`沒有用, 設定為 0.

            i. `revmap_tree` 指向Radix tree的root node.


## IRQ mapping table

HW interrupt ID 和 IRQ number 的 mapping table 是在整個系統初始化的過程中建立起來的, 過程如下:

> + DTS 文件描述了系統中的 interrupt H/w controller 以及外設 IRQ 的拓撲結構,
在 linux kernel 啟動的時候, 由 `bootloader` 傳遞給 kernel(實際傳遞的是 DTB).

> + 在 Device Tree 初始化的時候, 建立系統內所有的 device node 的樹狀結構,
當然其中包括所有和中斷拓撲相關的數據結構(所有的 interrupt H/w controller 的 node 和使用中斷的外設 node)

> + 在 machine driver 初始化的時候會調用 `of_irq_init()`,
在該函數中會掃瞄所有 interrupt H/w controller 的節點,
並調用適合的 interrupt H/w controller driver 進行初始化.
毫無疑問, 初始化需要注意順序, 首先初始化 `root`, 然後 `first leve`l, `second level`, 最後是 `leaf node`.
在初始化的過程中, 一般會調用上節中的接口函數向系統增加 irq domain.
有些 interrupt H/w controller 會在其 driver 初始化的過程中創建映射

> + 在各個 driver 初始化的過程中, 創建映射


+ 初始化 interrupt H/w controller 時, 註冊 irq domain
    > 在 GIC 的代碼中沒有調用標準的註冊 irq domain 的接口函數.
    要瞭解其背後的原因, 我們需要回到過去.
    在舊的 linux kernel 中, ARM 體系結構的代碼不甚理想.
    在 arch/arm 目錄充斥了很多 board specific 的代碼, 其中定義了很多具體設備相關的靜態表格,
    這些表格規定了各個 device 使用的資源, 當然, 其中包括IRQ資源.
    在這種情況下, 各個外設的IRQ是固定的, 也就是說, HW interrupt ID 和 IRQ number 的關係是固定的.

    ```c
    // gic_of_init() -> gic_init_bases()

    void __init gic_init_bases(unsigned int gic_nr, int irq_start,
                   void __iomem *dist_base, void __iomem *cpu_base,
                   u32 percpu_offset, struct device_node *node)
    {
        irq_hw_number_t hwirq_base;
        struct gic_chip_data *gic;
        int gic_irqs, irq_base, i;

        ...

        /**
         *  對於root GIC
         *  系統支持的所有的中斷數目 - 16.
         *  之所以減去 16 主要是因為 root GIC 的 0-15號 HW interrupt 是 for IPI 的.
         *  也正因為如此hwirq_base從16開始
         */
        hwirq_base = 16;
        gic_irqs -= hwirq_base;

        /**
         *  申請 gic_irqs 個 IRQ 資源, 從 16 號開始搜索 IRQ number.
         *  由於是 root GIC, 申請的 IRQ 基本上會從 16號開始
         */
        irq_base = irq_alloc_descs(irq_start, 16, gic_irqs, numa_node_id());

        // 向系統註冊 irq domain 並創建映射
        gic->domain = irq_domain_add_legacy(node, gic_irqs, irq_base,
                        hwirq_base, &gic_irq_domain_ops, gic);

        ...
    }
    ```

    > 一旦 HW interrupt ID 和 IRQ number 的關係是固定的.
    我們就可以在 interupt H/w controller 的代碼中創建這些映射關係.
    此時對於這個版本的 GIC driver 而言,
    初始化之後, HW interrupt ID 和 IRQ number 的映射關係已經建立,
    保存在線性 lookup table 中, size 等於 GIC 支持的中斷數目
    >> index 0-15 對應的 IRQ 無效,
    index 16 對應 16號 HW interrupt ID,
    index 17 對應 17號 HW interrupt ID

    ```c
    struct irq_domain *irq_domain_add_legacy(struct device_node *of_node,
                         unsigned int size,
                         unsigned int first_irq,
                         irq_hw_number_t first_hwirq,
                         const struct irq_domain_ops *ops,
                         void *host_data)
    {
        struct irq_domain *domain;

        domain = __irq_domain_add(of_node, first_hwirq + size,  // 註冊irq domain
                      first_hwirq + size, 0, ops, host_data);
        if (!domain)
            return NULL;

        irq_domain_associate_many(domain, first_irq, first_hwirq, size);    // 創建映射

        return domain;
    }
    ```

+ 初始化 device driver 時, 建立 HW interrupt ID 和 IRQ number 的對應關係

    - 設備的驅動在初始化的時候, 可以調用 `irq_of_parse_and_map()` 來對該 device node 的中斷相關內容,
    進行分析並建立映射關係

    ```c
    unsigned int irq_of_parse_and_map(struct device_node *dev, int index)
    {
        struct of_phandle_args oirq;

        if (of_irq_parse_one(dev, index, &oirq))    // 分析 device node 中的 interrupt 相關屬性
            return 0;

        return irq_create_of_mapping(&oirq);        // 創建映射, 並返回對應的 IRQ number
    }
    ```

    - `irq_create_of_mapping()` 創建映射

    ```c
    unsigned int irq_create_of_mapping(struct of_phandle_args *irq_data)
    {
        struct irq_domain *domain;
        irq_hw_number_t hwirq;
        unsigned int type = IRQ_TYPE_NONE;
        unsigned int virq;

        domain = irq_data->np ? irq_find_host(irq_data->np) : irq_default_domain;

        /**
         *  找到 irq domain.
         *  這是根據傳遞進來的參數 irq_data 的 np 成員來尋找的
         */
        if (!domain)
        {
            return 0;
        }

        /**
         *  如果沒有定義xlate函數,
         *  那麼取 interrupts 屬性的第一個 cell 作為 HW interrupt ID.
         */
        if (domain->ops->xlate == NULL)
            hwirq = irq_data->args[0];
        else
        {
            /**
             *  interrupts 屬性最好由 interrupt controller(也就是 irq domain)分析
             *  如果 xlate 函數能夠完成屬性解析,
             *  那麼將輸出參數 hwirq 和 type,
             *  分別表示 HW interrupt ID 和 interupt type (觸發方式等)
             */
            if (domain->ops->xlate(domain, irq_data->np, irq_data->args,
                                   irq_data->args_count, &hwirq, &type))
                return 0;
        }

        /**
         *  Create mapping
         *  解析完, 最終還要調用 irq_create_mapping()來
         *  創建 HW interrupt ID 和 IRQ number 的映射關係
         */
        virq = irq_create_mapping(domain, hwirq);

        if (!virq)
            return virq;

        /* Set type if specified and different than the current one */
        if (type != IRQ_TYPE_NONE &&
                type != irq_get_trigger_type(virq)) {
            /**
             *  如果有需要, 調用irq_set_irq_type函數設定trigger type
             */
            irq_set_irq_type(virq, type);
        }

        return virq;
    }
    ```

    - `irq_create_mapping()` 創建映射
        > 獲得一個 IRQ number 以及其對應關係,
        virtual interrupt number 已經說明和具體的硬件連接沒有關係了,
        僅僅是一個 number 而已

    ```c
    unsigned int irq_create_mapping(struct irq_domain *domain,
                    irq_hw_number_t hwirq)
    {
        unsigned int hint;
        int virq;

        // 如果映射已經存在, 那麼不需要映射, 直接返回
        virq = irq_find_mapping(domain, hwirq);
        if (virq) {
            return virq;
        }

        // 分配一個IRQ 描述符以及對應的irq number
        hint = hwirq % nr_irqs;
        if (hint == 0)
            hint++;

        /* Allocate a virtual interrupt number */
        virq = irq_alloc_desc_from(hint, of_node_to_nid(domain->of_node));
        if (virq <= 0)
            virq = irq_alloc_desc_from(1, of_node_to_nid(domain->of_node));
        if (virq <= 0) {
            pr_debug("-> virq allocation failed\n");
            return 0;
        }

        // 建立 mapping
        if (irq_domain_associate(domain, virq, hwirq)) {
            irq_free_desc(virq);
            return 0;
        }

        return virq;
    }

    int irq_domain_associate(struct irq_domain *domain, unsigned int virq,
                 irq_hw_number_t hwirq)
    {
        struct irq_data *irq_data = irq_get_irq_data(virq);
        int ret;

        mutex_lock(&irq_domain_mutex);
        irq_data->hwirq = hwirq;
        irq_data->domain = domain;
        if (domain->ops->map) {
            // 調用 irq domain 的 map callback函數
            ret = domain->ops->map(domain, virq, hwirq);
        }

        if (hwirq < domain->revmap_size) {
            // 填寫線性映射 lookup table 的數據
            domain->linear_revmap[hwirq] = virq;
        } else {
            mutex_lock(&revmap_trees_mutex);
            // 向 radix tree 插入一個node
            radix_tree_insert(&domain->revmap_tree, hwirq, irq_data);
            mutex_unlock(&revmap_trees_mutex);
        }
        mutex_unlock(&irq_domain_mutex);

        // 該IRQ已經可以申請了, 因此 clear 相關flag
        irq_clear_status_flags(virq, IRQ_NOREQUEST);

        return 0;
    }
    ```

## mapping rule

在系統的啟動過程中, 經過了各個 interrupt H/w controller 以及各個外設驅動的努力,
整個 interrupt 系統的 mapping table (將 HW interrupt ID 轉成 IRQ number 的數據庫)已經建立.

一旦發生硬體中斷, 經過 CPU architecture 相關的中斷代碼之後, 會調用 ISR, 該函數的一般過程如下:

> 1. 首先找到 root interrupt H/w controller 對應的 irq domain

> 2. 根據 HW register 信息和 irq domain 信息獲取 HW interrupt ID

> 3. 調用 `irq_find_mapping()`找到 HW interrupt ID 對應的 irq number

> 4. 調用 `handle_IRQ()`(對於ARM平台) 來處理該 irq number

對於級聯(cascade)的情況, 過程類似上面的描述, 但是需要注意的是在步驟4 中,
不是直接調用該 IRQ 的 hander 來處理該 irq number.
因為, 這個 irq 需要各個 interrupt H/w controller level 上的解析.

舉一個簡單的二階級聯情況:
假設系統中有兩個 interrupt H/w controller, A和B.

A 是 root interrupt H/w controller,
B 連接到 A 的 13號 HW interrupt ID 上.

在 B interrupt H/w controller 初始化的時候, 除了初始化它做為 interrupt H/w controller 的那部分內容,
還有初始化它做為 root interrupt H/w controller A上的一個普通外設這部分的內容.

最重要的是調用 `irq_set_chained_handler()` 設定 handler.
這樣, 在上面的步驟4 的時候, 就會調用 13號 HW interrupt ID 對應的 handler(也就是 B 的 handler),
在該 handler 中, 會重複上面的(1)~(4)

+ 以一個級聯的 GIC 系統為例, 描述轉換過程

    - second GIC driver 初始化
        > second GIC 初始化之後, 該 irq domain 的 HW interrupt ID 和 IRQ number 的映射關係已經建立,
        保存在線性 lookup table 中, size 等於 GIC 支持的中斷數目
        >> index 0~32 對應的 IRQ 無效,
        root GIC 申請的最後一個 (IRQ號+1) 對應 32號 HW interrupt ID,
        root GIC 申請的最後一個 (IRQ號+2) 對應 33號 HW interrupt ID

    ```c
    // gic_of_init() -> gic_init_bases()

    void __init gic_init_bases(unsigned int gic_nr, int irq_start,
                   void __iomem *dist_base, void __iomem *cpu_base,
                   u32 percpu_offset, struct device_node *node)
    {
        irq_hw_number_t hwirq_base;
        struct gic_chip_data *gic;
        int gic_irqs, irq_base, i;
        ...

        /**
         *  對於 second GIC
         *  之所以減去 32 主要是因為對於 second GIC, 其0~15號 HW interrupt 是for IPI的, 因此要去掉.
         *  而 16~31 號 HW interrupt 是 for PPI的, 也要去掉.
         *  也正因為如此 hwirq_base 從 32 開始
         */
        hwirq_base = 32;
        gic_irqs -= hwirq_base;

        /**
         *  申請 gic_irqs個IRQ資源, 從 16號開始搜索 IRQ number.
         *  由於是 second GIC, 申請的 IRQ 基本上會從 root GIC 申請的最後一個 IRQ號+1開始
         */
        irq_base = irq_alloc_descs(irq_start, 16, gic_irqs, numa_node_id());

        // 向系統註冊irq domain並創建映射
        gic->domain = irq_domain_add_legacy(node, gic_irqs, irq_base,
                        hwirq_base, &gic_irq_domain_ops, gic);

        ...

    }
    ```

    - second GIC 其他部分的初始化
        > 下面的初始化函數去掉和級聯無關的代碼.
        對於 root GIC, 其傳入的 parent 是 NULL, 因此不會執行級聯部分的代碼.
        對於 second GIC, 它是作為其 parent (root GIC) 的一個普通的 irq source, 因此, 也需要註冊該IRQ的handler.
        由此可見, 非 root 的 GIC 的初始化分成了兩個部分
        > + 一部分是作為一個 interrupt H/w controller, 執行和 root GIC 一樣的初始化代碼.
        > + 另外一方面, GIC 又作為一個普通的 `interrupt generating device`,
        需要像一個普通的設備驅動一樣, 註冊其中斷handler.

    ```c
    int __init gic_of_init(struct device_node *node, struct device_node *parent)
    {
        ...

        if (parent) {
            // 解析 second GIC 的 interrupts 屬性, 並進行mapping, 返回IRQ number
            irq = irq_of_parse_and_map(node, 0);

            // 設置handler
            gic_cascade_irq(gic_cnt, irq);
        }
        ...
    }

    void __init gic_cascade_irq(unsigned int gic_nr, unsigned int irq)
    {
        // 設置 handler data
        if (irq_set_handler_data(irq, &gic_data[gic_nr]) != 0)
            BUG();

        // 設置handler
        irq_set_chained_handler(irq, gic_handle_cascade_irq);
    }
    ```


# Bottom Half

deferable task, 具體如何推遲執行, 可分成下面幾種情況:

> + 推遲到 top half 執行完畢
>> softirq 和 tasklet
> + 推遲到某個指定的時間片(例如40ms)之後執行
>> timer 類型的 softirq
> + 推遲到某個內核線程被調度的時候執行
>> 包括 `threaded irq handler` 以及通用的 `workqueue`機制,
當然也包括自己創建該驅動專屬 kernel thread(不推薦使用)

## softIRQ (NOT SWI interrupt)

> + run on `ISR`
>> one core only has self handler
> + high performance
> + handle re-entry of cores
>> In multi-cores, use spin lock

+ example
    > 假設 Core A 處理了這個網卡(NIC)中斷事件, 很快的完成了基本的 HW 操作後, trigger softIRQ.
    在返回中斷現場前, 會檢查 softIRQ 的觸發情況, 因此, 後續網路數據處理的 softirq 在 Core A 上執行.
    在執行過程中, NIC H/w 再次觸發中斷, GIC 將該中斷分發給 Core B (執行動作和 Core A 是類似的).
    最後, 網絡數據處理的 softIRQ 在 Core B 上執行.

    > 為了性能, 同一類型的 softIRQ 有可能在不同的 CPU 上同時執行,
    因此 handler 需要考慮 re-entry 的情況, 並引入同步機制

+ S/w IRQ vector table, `softirq_vec`
    > share with multi-cores (only one table)

    ```c
    enum {
        /* soft irq number */
        HI_SOFTIRQ=0,
        TIMER_SOFTIRQ,
        NET_TX_SOFTIRQ,
        NET_RX_SOFTIRQ,
        BLOCK_SOFTIRQ,
        BLOCK_IOPOLL_SOFTIRQ,
        TASKLET_SOFTIRQ,
        SCHED_SOFTIRQ,
        HRTIMER_SOFTIRQ,
        RCU_SOFTIRQ,        /* Preferable RCU should always be the last softirq */

        NR_SOFTIRQS
    };

    struct softirq_action
    {
        void    (*action)(struct softirq_action *);
    };

    /* S/w IRQ vector table */
    static struct softirq_action softirq_vec[NR_SOFTIRQS] __cacheline_aligned_in_smp;
    ```

    - register S/w IRQ handler

    ```c
    void open_softirq(int nr, void (*action)(struct softirq_action *))
    {
        softirq_vec[nr].action = action;
    }
    ```

+ S/w IRQ state info
    > CPU 在中斷 handler 中觸發了一個softirq,
    那麼該 CPU 需要負責調用該 softIRQ number 所對應的 action callback 來處理該軟中斷

    > 每個 core 都有自己的 irq_stat info

    ```c
    /* S/w IRQ state info */
    typedef struct
    {
        unsigned int    __softirq_pending;
    #ifdef CONFIG_SMP
        unsigned int    ipi_irqs[NR_IPI];
    #endif
    } ____cacheline_aligned irq_cpustat_t;

    irq_cpustat_t irq_stat[NR_CPUS] ____cacheline_aligned;
    ```

+ trigger S/w IRQ
    > control flag of `__softirq_pending`

    - `raise_softirq`
        > normal case

        ```c
        void raise_softirq(unsigned int nr)
        {
            unsigned long   flags;

            local_irq_save(flags);
            raise_softirq_irqoff(nr);
            local_irq_restore(flags);
        }
        ```

    - `raise_softirq_irqoff`
        > It MUST run with irqs disabled (Top half of interrupt).

+ enable/disable soft IRQ
    > `local_bh_disable()` 和 `local_bh_enable()`
    >> `local_bh_enable/disable`是給進程上下文使用的,
    用於防止 softIRQ handler 搶佔 local_bh_enable/disable 之間的 flow,
    以避免 race condition 發生

    > 假設在 local_bh_enable/disable 之間的臨界區執行時, 發生中斷, 由於代碼並沒有阻止 top half 的搶佔,
    因此 IRQ 會搶佔當前正在執行的 thread.
    在 ISR 中, 我們執行 raise_softirq(), 在返回中斷現場的時, 由於 local_bh_disable(),
    因此雖然觸發了 softIRQ, 但是不會調度執行.
    當代碼返回臨界區繼續執行, 直到 local_bh_enable(), 那麼之前 raise_softirq 就需要調度執行了,
    這也是為什麼在 local_bh_enable() 內會呼叫 do_softirq()

+ softIRQ behavior

    ```
        H/w IRQ
            |
            v
        gic_handle_irq()
            |
            v
        __handle_domain_irq()
            |
            v
        irq_enter()
            |
            v
        generic_handle_irq()
         (Top half)
            |
            v
        irq_exit()
            + invoke_softirq()
                + __do_softirq()
                   (Bottom half)
    ```

+ `__do_softirq` 分析

    ```c
    asmlinkage void __do_softirq(void)
    {
    ...

        pending = local_softirq_pending();  // 獲取softirq pending的狀態

        __local_bh_disable_ip(_RET_IP_, SOFTIRQ_OFFSET); // 標識下面的代碼是正在處理softirq

        cpu = smp_processor_id();
    restart:
        set_softirq_pending(0); // 清除pending標誌
        local_irq_enable();     // 打開中斷, softirq handler是開中斷執行的
        h = softirq_vec;        // 獲取軟中斷描述符指針

        while ((softirq_bit = ffs(pending))) {  // 尋找pending中第一個被設定為1的bit
            unsigned int vec_nr;
            int prev_count;

            h += softirq_bit - 1;       // 指向pending的那個軟中斷描述符
            vec_nr = h - softirq_vec;   // 獲取soft irq number

            h->action(h);   // 指向softirq handler

            h++;
            pending >>= softirq_bit;
        }

        local_irq_disable();    // 關閉本地中斷

        /**
         * 再次檢查 softirq pending, 有可能上面的 softirq handler 在執行過程中, 又發生了中斷, raise_softirq.
         * 如果的確如此, 那麼我們需要跳轉到 'restart' 那裡重新處理 soft irq.
         * 當然, 也不能總是在這裡不斷的loop, 因此linux kernel設定了下面的條件:
         *
         * 1. softirq 的處理時間 < 2ms
         * 2. 上次的 softIRQ 中沒有設定 TIF_NEED_RESCHED, 也就是說沒有有高優先級任務需要調度
         * 3. loop 的次數 < 10
         *
         * 因此, 只有同時滿足上面三個條件, 程序才會跳轉到 'restart' 那裡重新處理soft irq.
         * 否則 wakeup_softirqd 就 OK了.
         * 這樣的設計也是一個平衡的方案.
         * 一方面照顧了調度延遲:
         *     本來, 發生一個中斷, 系統期望在限定的時間內調度某個進程來處理這個中斷,
         *     如果 softirq handler 不斷觸發, 其實 linux kernel 是無法保證調度延遲時間的.
         * 另外一方面也照顧了硬件的 thoughput:
         *     已經預留了一定的時間來處理softirq.
         */
        pending = local_softirq_pending();
        if (pending) {
            if (time_before(jiffies, end) && !need_resched() &&
                --max_restart)
                goto restart;

            wakeup_softirqd();
        }

        __local_bh_enable(SOFTIRQ_OFFSET);  // 標識 softirq 處理完畢
    }
    ```

## tasklet

> + `base on softIRQ mechanism`, run on ISR
> + use friendly, lower performance
> + only one core serially handle

+ Concepts
    > 每個 cpu 都會維護一個 `tasklet list`, 用來管理本 cpu 需要處理的 tasklet

    - data structure
        > + `next` 指向了該 link list 中的下一個 tasklet
        > + `func` 此 tasklet 的 callback
        > + `data` 傳遞給 func 的參數
        > + `state` 表示該 tasklet 的狀態
        >> `TASKLET_STATE_SCHED` 表示該 tasklet 被調度到某個 CPU 上執行,
        `TASKLET_STATE_RUN` 表示該 tasklet 正在某個 CPU 上執行
        > + `count` 和 enable/disable 該 tasklet 相關
        >> 如果 `count == 0` 那麼該 tasklet 是處於 enable 的,
        如果 `count > 0`, 表示該 tasklet 是 disable 的.

        ```c
        struct tasklet_struct
        {
            struct tasklet_struct *next;
            unsigned long   state;
            atomic_t        count;       // ref count, 0: enable tasklet, others: disable tasklet

            void (*func)(unsigned long); // callback
            unsigned long   data;        // private data
        };
        ```

        1. `local_bh_disable()/local_bh_enable()`
            > 用來 disable/enable bottom half 的 (bottom half 總開關), 這裡就包括 softirq 和 tasklet

        1. `tasklet_disable()/tasklet_enable()`
            > 用來 disable/enable **當前的 tasklet**

            ```c
            static inline void tasklet_disable(struct tasklet_struct *t)
            {
                // 給 tasklet 的 count 加 1
                tasklet_disable_nosync(t);

                // 如果該 tasklet 處於 running 狀態, 那麼需要等到該 tasklet 執行完畢
                tasklet_unlock_wait(t);
                smp_mb();
            }

            static inline void tasklet_enable(struct tasklet_struct *t)
            {
                smp_mb__before_atomic();

                // 給 tasklet 的 count減 1
                atomic_dec(&t->count);
            }
            ```
    - priority
        > kernel 中, 和 tasklet 相關的 softirq 有兩項,
        > + `HI_SOFTIRQ` 用於高優先級的tasklet,
        > + `TASKLET_SOFTIRQ` 用於普通的tasklet
        > 對於 softirq 而言, 優先級就是出現在 softirq pending register (__softirq_pending) 中的先後順序,
        位於 `bit 0`擁有最高的優先級, 也就是說, 如果有多個不同類型的softirq同時觸發,
        那麼執行的先後順序依賴在 softirq pending register 的位置,
        **kernel 總是從右向左依次判斷是否 pull high**, 如果 high 則執行.
        >> HI_SOFTIRQ 佔據了 bit 0, 其優先級甚至高過 timer, 需要慎用
        (實際上, grep了內核代碼, 似乎沒有發現對 HI_SOFTIRQ 的使用)

    - 產生 tasklet

        1. 靜態初始化

            ```c
            // default eable
            #define DECLARE_TASKLET(name, func, data) \
                struct tasklet_struct name = { NULL, 0, ATOMIC_INIT(0), func, data }

            // default disable
            #define DECLARE_TASKLET_DISABLED(name, func, data) \
                struct tasklet_struct name = { NULL, 0, ATOMIC_INIT(1), func, data }
            ```

        1. 動態初始化

            ```c
            void tasklet_init(struct tasklet_struct *t,
                               void (*func)(unsigned long), unsigned long data);
            ```

    - 排程 tasklet `tasklet_schedule()`
        > 程序在多個 context 中可以多次排程同一個 tasklet (也可能來自多個 cpu),
        不過實際上該 tasklet 只會掛入第一次調度到的那個 cpu 的 tasklet list,
        也就是說, 即便是多次呼叫 tasklet_schedule(),
        實際上 tasklet 也只會掛到特定一個 CPU 的 tasklet list 中 (而且只會掛入一次).
        >> 這是通過 `TASKLET_STATE_SCHED` 這個 flag 來完成的.

        1. 假設一個 device driver 使用 tasklet 機制, 並且在中斷 top half 中,
        將靜態定義的 tasklet (這個 tasklet 是各個cpu共享的, 不是per cpu的)調度執行(呼叫 tasklet_schedule).
        當 device 檢測到硬件的動作(例如接收 FIFO 中數據達到半滿), 並觸發 IRQ signal, 而 GIC 收到中斷信號,
        會將該中斷分發給某個 CPU 執行其 top half handler, 我們假設這次是 cpu0,
        因此該 driver 的 tasklet 被掛入 cpu0 對應的tasklet list (tasklet_vec),
        並將 state 的狀態設定為 `TASKLET_STATE_SCHED`.
        device driver 中的 tasklet 雖已進入排程, 但是還沒有執行,
        如果這時候, 硬件又一次觸發中斷並在 cpu1 上執行, 雖然 `tasklet_schedule()` 再次被呼叫,
        但是由於 `TASKLET_STATE_SCHED` 已經設定,
        因此**不會**將 device driver 中的這個 tasklet 再掛入cpu1 的 tasklet list 中

        ```c
        static inline void tasklet_schedule(struct tasklet_struct *t)
        {
            if (!test_and_set_bit(TASKLET_STATE_SCHED, &t->state))
                __tasklet_schedule(t);
        }

        void __tasklet_schedule(struct tasklet_struct *t)
        {
            unsigned long flags;
            /**
             *  下面的 link list 操作是 per-cpu 的,
             *  因此這裡禁止本地中斷就可以攔截所有的並發
             */
            local_irq_save(flags);

            /**
             *  這裡的三行代碼就是將一個 tasklet 掛入 link list 的尾部
             */
            t->next = NULL;
            *__this_cpu_read(tasklet_vec.tail) = t;
            __this_cpu_write(tasklet_vec.tail, &(t->next));

            /**
             *  raise TASKLET_SOFTIRQ 類型的 softirq
             */
            raise_softirq_irqoff(TASKLET_SOFTIRQ);
            local_irq_restore(flags);
        }
        ```

    - 執行 tasklet

        1. 在退出 ISR 時, 如果有 pending 的 softirq, 那麼將執行該 softirq 的處理函數
            > + 退出 H/w IRQ handler 時
            > + 退出 SWI handler 時

        1. 在進程中呼叫 `local_bh_enable()` 時, 如果有 pending 的 softirq, 那麼將執行該 softirq 的處理函數.
        由於內核同步的要求, 進程有可能會呼叫 `local_bh_enable/disable` 來保護 softirq handler 中的臨界區.
        在臨界區代碼執行過程中, 中斷隨時會到來, 搶佔該進程(kernal space)的執行
        (ps. 這裡只是 disable 了 bottom half, 沒有禁止中斷觸發).
        在這種情況下, 中斷返回的時候是否會執行 softirq handler 呢？
        當然不會, 我們 disable 了 bottom half 的執行, 也就是意味著不能執行 softirq handler,
        但是本質上 bottom half 應該比進程有更高的優先級, 一旦條件允許, 要立刻搶佔進程的執行,
        因此, 當立刻離開臨界區, 調用 `local_bh_enable()` 的時候,
        會檢查 softirq pending, 如果 bottom half 處於 enable 的狀態,
        pending 的 softirq handler 會被執行.

        1. 當系統太繁忙了, 不斷產生中斷 (raise softirq), 由於 bottom half 的優先級高, 從而導致進程無法調度執行。
        這種情況下, softirq 會推遲到 softirqd 這個 kernel thread 中去執行

        1. `SKLET_SOFTIRQ` 類型的 softirq handler -> `tasklet_action()`

        ```c
        static void tasklet_action(struct softirq_action *a)
        {
            struct tasklet_struct *list;

            /**
             *  從本 cpu 的 tasklet list 中取出全部的 tasklet,
             *  保存在 list 這個臨時變量中, 同時重新初始化本 cpu 的 tasklet list, 使該鏈表為空.
             *  由於 bottom half 是開中斷執行的, 因此在操作 tasklet list 的時候需要使用關中斷保護
             */
            local_irq_disable();
            list = __this_cpu_read(tasklet_vec.head);
            __this_cpu_write(tasklet_vec.head, NULL);
            __this_cpu_write(tasklet_vec.tail, this_cpu_ptr(&tasklet_vec.head));
            local_irq_enable();

            // 遍歷 tasklet list
            while (list) {
                struct tasklet_struct *t = list;

                list = list->next;

                /**
                 *  tasklet_trylock() 主要是用來設定該 tasklet 的 state 為 TASKLET_STATE_RUN,
                 *  同時判斷該 tasklet 是否已經處於執行狀態, 這個狀態很重要, 它決定了後續的代碼邏輯
                 */
                if (tasklet_trylock(t)) {
                    /**
                     *  檢查該 tasklet 是否處於 enable 狀態,
                     *  如果是, 說明該 tasklet 可以真正進入執行狀態了
                     *  主要的動作就是清除 TASKLET_STATE_SCHED 狀態, 執行 tasklet callback function。
                     */
                    if (!atomic_read(&t->count)) {
                        if (!test_and_clear_bit(TASKLET_STATE_SCHED, &t->state))
                            BUG();
                        t->func(t->data);
                        tasklet_unlock(t);

                        // 處理下一個 tasklet
                        continue;
                    }

                    // 清除 TASKLET_STATE_RUN 標記
                    tasklet_unlock(t);
                }

                /**
                 *  如果該 tasklet 已經在別的 cpu 上執行了,
                 *  那麼我們將其掛入該 cpu 的 tasklet list 的尾部,
                 *  這樣, 在下一個 tasklet 執行時機到來的時候,
                 *  kernel 會再次嘗試執行該 tasklet,
                 *  在這個時間點, 也許其他 cpu 上的該 tasklet 已經執行完畢了.
                 *  通過這樣代碼邏輯, 保證了特定的 tasklet 只會在一個 cpu上 執行, 不會在多個 cpu 上並發
                 */
                local_irq_disable();
                t->next = NULL;
                *__this_cpu_read(tasklet_vec.tail) = t;
                __this_cpu_write(tasklet_vec.tail, &(t->next));

                // 再次觸發softirq, 等待下一個執行時機
                __raise_softirq_irqoff(TASKLET_SOFTIRQ);
                local_irq_enable();
            }
        }
        ```

        > 你也許會對 `tasklet_trylock()`的部分覺得奇怪, 為何這裡從 tasklet 的 list 中摘下一個本 cpu 要處理的 tasklet ndoe,
        而這個 list 中的 tasklet 已經處於 running 狀態了, 會有這種情況嗎 ?

        > 當 device driver 使用 tasklet 機制並且在中斷 top half 中, 將靜態定義的 tasklet 調度執行.
        device H/w 中斷 signal 首先送達 cpu0 處理, 因此該 driver 的 tasklet 被掛入 CPU0 對應的 tasklet list, 並在適當的時間點上開始執行該 tasklet.
        這時候, cpu0 的硬件中斷又來了, 該 driver 的 tasklet callback function 被搶佔, 雖然 tasklet 仍然處於 running 狀態.
        與此同時, device 又一次觸發中斷並在 cpu1 上執行, 這時候, 該 driver 的 tasklet 處於 running 狀態,
        並且 `TASKLET_STATE_SCHED` 已經被清除,
        因此, 調用 tasklet_schedule() 將會使得該 driver 的 tasklet 掛入 cpu1 的 tasklet list 中。
        由於 cpu0 在處理其他硬件中斷, 因此, cpu1 的 tasklet 後發先至, 進入 tasklet_action() 調用,
        這時候, 當從 cpu1 的 tasklet 摘取所有需要處理的 tasklet list 中, device 對應的 tasklet 實際上已經是在 cpu0 上處於執行狀態了.

        > 在設計 tasklet 的時候就規定, 同一種類型的 tasklet 只能在一個 cpu 上執行,
        因此 `tasklet_trylock()` 就是起這個作用的.

        ```c
        static inline int tasklet_trylock(struct tasklet_struct *t)
        {
            return !test_and_set_bit(TASKLET_STATE_RUN, &(t)->state);
        }
        ```

+ example
    > 假設 Core A 處理了這個網卡(NIC)中斷事件, 很快的完成了基本的 HW 操作後,
    執行 schedule tasklet (同時也 trigger TASKLET_SOFTIRQ softIRQ).
    在返回中斷現場前, 會檢查 softIRQ 的觸發情況.
    在 TASKLET_SOFTIRQ softIRQ 的 handler 中, 獲取 tasklet 相關信息並在 Core A 上執行該 tasklet 的 handler.
    在執行過程中, NIC硬件再次觸發中斷, GIC 將該中斷分發給 Core B (執行動作和 Core A 是類似的),

    > 雖然 TASKLET_SOFTIRQ softIRQ 在 Core B 上可以執行, 但是, 在檢查 tasklet 的狀態的時候,
    如果發現該 tasklet 在其他 CPU 上已經正在運行, 那麼該 tasklet 不會被處理,
    一直等到在 Core A 上的 tasklet 處理完, 在 Core B 上的這個 tasklet 才能被執行

## workqueue
Always run by kernel threads.
They have a process context and they can sleep



# Device tree about IRQ

interrupt H/w controller 的拓撲結構, 以及其 interrupt request line (signals) 的分配情況(分配給哪一個具體的外設),
都在 Device Tree Source (*.dts)文件中通過下面的屬性給出了描述.

對於那些產生中斷的外設, 我們需要定義 `interrupt-parent`和 `interrupts 屬性`:

+ `interrupt-parent`
    > 表明該外設的 interrupt request line (signals) 物理的連接到了哪一個中斷控制器上

+ `interrupts`
    > 這個屬性描述了具體該外設產生的 interrupt 的細節信息(也就是傳說中的 interrupt specifier).
    例如: HW interrupt ID(由該外設的 device node 中的 interrupt-parent 指向的 interrupt H/w controller 解析),
    interrupt觸發類型等.

對於 Interrupt H/w controller, 我們需要定義 `interrupt-controller` 和 `#interrupt-cells的屬性`:

+ `interrupt-controller`
    > 表明該 device node 就是一個中斷控制器

+ `#interrupt-cells`
    > 該中斷控制器用多少個cell (一個cell就是一個32-bit的單元),
    描述一個外設的interrupt request line.
    具體每個 cell 表示什麼樣的含義由 interrupt H/w controller 自己定義.

+ `interrupts` 和 `interrupt-parent`
    > 對於那些不是 root 的 interrupt H/w controller,
    其本身也是作為一個產生中斷的外設連接到其他的 interrupt H/w controller上,
    因此也需要定義 `interrupts` 和 `interrupt-parent` 的屬性


# reference

+ [Linux 核心設計: 中斷處理和現代架構考量](https://hackmd.io/@sysprog/linux-interrupt)
+ [Linux kernel的中斷子系統之(一):綜述](http://www.wowotech.net/irq_subsystem/interrupt_subsystem_architecture.html)
+ [Linux kernel的中斷子系統之(二):IRQ Domain介紹](http://www.wowotech.net/linux_kenrel/irq-domain.html)
+ [linux kernel的中斷子系統之(三):IRQ number和中斷描述符](http://www.wowotech.net/irq_subsystem/interrupt_descriptor.html)
+ [linux kernel的中斷子系統之(四):High level irq event handler](http://www.wowotech.net/irq_subsystem/High_level_irq_event_handler.html)
+ [Linux kernel的中斷子系統之(五):驅動申請中斷API](http://www.wowotech.net/irq_subsystem/request_threaded_irq.html)
+ [Linux kernel的中斷子系統之(六):ARM中斷處理過程](http://www.wowotech.net/linux_kenrel/irq_handler.html)
+ [linux kernel的中斷子系統之(七):GIC代碼分析](http://www.wowotech.net/linux_kenrel/gic_driver.html)
+ [linux kernel的中斷子系統之(八):softirq](http://www.wowotech.net/irq_subsystem/soft-irq.html)
+ [linux kernel的中斷子系統之(九):tasklet](http://www.wowotech.net/irq_subsystem/tasklet.html)
+ [Concurrency Managed Workqueue之(一):workqueue的基本概念](http://www.wowotech.net/irq_subsystem/workqueue.html)
+ [linux gic驅動](https://blog.csdn.net/rikeyone/article/details/51538414)

