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
    > H/w Interrupt controller 用來標識外設的中斷.
    HW interrupt ID 在不同的 Interrupt controller 上是會不同.
    >> 以 kernel來說, 希望 device 能得到相同的 IRQ number,
    而不會因 interrupt controller 不同而不同.
    因此, linux kernel IRQ sub-system 需要提供一個將 HW interrupt ID 映射到 IRQ number 上的機制


# Flow

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
            > 系統可以有多個 interrupt controller, 之所以形成中斷控制器的樹狀結構,
            是為了讓系統中所有的中斷控制器驅動, 按照一定的順序進行初始化

            >> 在 `of_irq_init` 執行前, 系統已經完成了 device tree 的初始化,
            因此所有的 device nodes 都已經形成了一個 tree, 每個 node 代表一個設備的 device node

            > 從 root interrupt controller 節點開始, 對每一個 interrupt controller 的 device node,
            和 `irq chip table` 進行比對, 一旦匹配就調用該 interrupt controller 的初始化函數,
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

            > + `xlate` 是負責翻譯的 callback, 在dts文件中, 各個設備通過一些屬性,
            e.g. `interrupts`和`interrupt-parent`來提供中斷信息給 kernel 和驅動;
            而 `xlate` 函數就是將指定的設備上若干個中斷屬性翻譯成 `hwirq` 和 `trigger` 類型,
            比如 `#interrupt-cells = <3>;` 對中斷控制器來說,
            描述該 field 中的一個 interrupt 需要三個 cell 來表示,
            那麼這三個 cell 就是通過 xlate 來解析的.

            > + `match` 用來判斷 interrupt controller 是否和一個 irq domain 匹配的, 如果是就返回 1.
            實際上, 該 callback 函數很少被設置, 內核中提供了默認的匹配函數,
            就是通過 of_node 來進行匹配的.

            > + `map`和`unmap` 是映射和解除映射操作
            >   > `map` 回調函數是在創建 hwirq 到 irq num 關係的時候被調用的,
                註冊 irq domain 只是一個空的關係表, 而這個是實質上關係的創建,
                是在 `irq_of_parse_and_map()`裡面進行的.
                在 map 回調函數中, 一般需要做如下幾個操作

            ```c
            irq_set_chip_and_handler(irq, &gic_chip, handle_fasteoi_irq);
            set_irq_flags(irq, IRQF_VALID | IRQF_PROBE);
            irq_set_chip_data(irq, d->host_data);
            ```

            >   > `irq_set_chip_and_handler` 函數是用來設置 `struct irq_chip` 和對應的上層 IRQ Handler,
                一般內核中斷子系統已經實現了相應的函數, 我們只需要按需賦值即可,
                它負責對一個 irq num 調用所有通過 irq_request 註冊的 irq handler.
                我們稱之為上層中斷服務程序

        1. `irq_domain_add_legacy()`
            > 創建並註冊 irq_domain 相關的資料, e.g. `irq_domain_ops`, `mapping method`, ...etc.
            >> `gic_irq_domain_ops` 定義了 mapping method

    - `set_handle_irq()` at `arch/arm/kernel/irq.c`
        > 註冊 IRQ Handler 到 platform 的 irq 處理接口中.
        當 CPU 發生了中斷時, 最先調用的 ISR, 然後在此 ISR 中進行 irq domain 處理

        > + root GIC 註冊 `gic_handle_irq()` 到 CPU 中斷服務程序入口
        >> 中斷來的時候會最先調用這個函數, 它中會讀取 GIC register 獲得 hwirq, 並且查找對應的 irq num.
        `irq_find_mapping` 是查找 irq domain 中映射關係的關鍵函數.
        然後會調用 handle_IRQ 來處理對應的 irq num, 緊接著會調用相應的上層 IRQ Handler


# Bottom Half

+ softIRQ
    > + run on ISR
    >> one core only has self SWI ISR
    > + high performance
    > + handle re-entry of cores
    >> In multi-cores, use spin lock

    - example
        > 假設 Core A 處理了這個網卡(NIC)中斷事件, 很快的完成了基本的 HW 操作後, trigger softIRQ.
        在返回中斷現場前, 會檢查 softIRQ 的觸發情況, 因此, 後續網路數據處理的 softirq 在 Core A 上執行.
        在執行過程中, NIC H/w 再次觸發中斷, GIC 將該中斷分發給 Core B (執行動作和 Core A 是類似的).
        最後, 網絡數據處理的 softIRQ 在 Core B 上執行.

        > 為了性能, 同一類型的 softIRQ 有可能在不同的 CPU 上同時執行,
        因此 SWI handler 需要考慮 re-entry 的情況, 並引入同步機制

    - S/w IRQ vector table, `softirq_vec`
        > share with multi-cores (only one table)

        ```c
        enum
        {
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

        1. register S/w IRQ handler

        ```c
        void open_softirq(int nr, void (*action)(struct softirq_action *))
        {
            softirq_vec[nr].action = action;
        }
        ```

    - S/w IRQ state info
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

    - trigger S/w IRQ
        > control flag of `__softirq_pending`

        1. `raise_softirq`
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

        1. `raise_softirq_irqoff`
            > It MUST run with irqs disabled (Top half of interrupt).

    - enable/disable soft IRQ
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

    - softIRQ behavior

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

    - `__do_softirq` 分析

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

            __local_bh_enable(SOFTIRQ_OFFSET);  // 標識softirq處理完畢
        }
        ```

+ tasklet
    > + `base on softIRQ mechanism`, run on ISR
    > + use friendly, lower performance
    > + only one core serially handle

    - example
        > 假設 Core A 處理了這個網卡(NIC)中斷事件, 很快的完成了基本的 HW 操作後,
        執行 schedule tasklet (同時也 trigger TASKLET_SOFTIRQ softIRQ).
        在返回中斷現場前, 會檢查 softIRQ 的觸發情況.
        在 TASKLET_SOFTIRQ softIRQ 的 handler 中, 獲取 tasklet 相關信息並在 Core A 上執行該 tasklet 的 handler.
        在執行過程中, NIC硬件再次觸發中斷, GIC 將該中斷分發給 Core B (執行動作和 Core A 是類似的),

        > 雖然 TASKLET_SOFTIRQ softIRQ 在 Core B 上可以執行, 但是, 在檢查 tasklet 的狀態的時候,
        如果發現該 tasklet 在其他 CPU 上已經正在運行, 那麼該 tasklet 不會被處理,
        一直等到在 Core A 上的 tasklet 處理完, 在 Core B 上的這個 tasklet 才能被執行

+ workqueue
    > Always run by kernel threads.
    They have a process context and they can sleep


# reference

+ [Linux 核心設計: 中斷處理和現代架構考量](https://hackmd.io/@sysprog/linux-interrupt)
+ [Linux kernel的中斷子系統之(一):綜述](http://www.wowotech.net/irq_subsystem/interrupt_subsystem_architecture.html)
+ [Linux kernel的中斷子系統之(二):IRQ Domain介紹](http://www.wowotech.net/linux_kenrel/irq-domain.html)
+ [linux gic驅動](https://blog.csdn.net/rikeyone/article/details/51538414)

