linux network sub-system
---

# Definitions

+ NIC (Network Interface Controller)
    > 網路卡

+ `PRE_CPU` type
    > 每個 Core 都各自存一份, 當其中一個 Core 更動時,
    會自動同步到其他 Cores 的那一份

+ kernel version
    > 大部分為 `kernel v4.14.136`


# NAPI(New API) mechanism

NAPI 的核心概念在於:
在一個繁忙 network, 每次有 packet 到達時, 不需要都引發中斷, 因為高頻率的中斷, 可能會影響系統的整體效率.
假想一個場景, 我們使用標準的 100M 網卡, 可能實際達到的接收速率為 80MBits/s,
而此時數據包平均長度為 1500Bytes, 則每秒產生的中斷數目為

```
(80M bits/s) / (8 Bits/Byte * 1500 Byte) = 6667 個中斷 /s
```

每秒 6667 個中斷, 對於系統是個很大的壓力, 此時其實可以轉為使用輪詢 (polling) 來處理, 而不是中斷.
但 polling 在網路流量較小的時沒有效率, 因此低流量時, 基於中斷的方式則比較合適,
這就是 NAPI 出現的原因, 在**低流量時候使用中斷**接收 packets, 而在**高流量時候則使用基於 polling 的方式**接收

ps. 經過連續兩次對 NAPI 的重構, 因此 2.6 version 和 later version 有些許差異,
    將最後的重構戲稱為 Newer newer NAPI

在最初實現的 NAPI 中, 有 2 個字段在 `struct net_device` 中, 分別為 `(*poll)()` 和 `weight`,
而所謂的 Newer newer NAPI, 是在 2.6.24 版內核之後, 對原有的 NAPI 實現的幾次重構,
其核心是將 NAPI 相關功能和 net_device 分離, 這樣減少了耦合, 代碼更加的靈活,
因為 NAPI 的相關信息已經從特定的 net device 剝離了, 不再是以前的一對一的關係了.
例如有些網絡適配器, 可能提供了多個 port, 但所有的 port 卻是共用同一個 RX 的中斷,
這時候, 分離的 NAPI 信息只需存一份, 同時被所有的 port 來共享,
這樣, 代碼框架上更好地適應了真實的硬件能力.

ps. 簡單說, NAPI 提供了一個可以在 interrupt 跟 poll 兩個模式切換的 framework

+ Pros
    > NAPI 適合處理高速率數據包的處理, 而帶來的好處如下

    - 中斷緩和 (Interrupt mitigation)
        > 由上面的例子可以看到, 在高流量下, 網卡產生的中斷可能達到每秒幾千次,
        而如果每次中斷都需要系統來處理, 是一個很大的壓力,
        而 NAPI 使用輪詢時是禁止了網卡的接收中斷的,
        這樣會減小系統處理中斷的壓力.

    - 數據包節流 (Packet throttling)
        > NAPI 之前的 Linux NIC driver 總在接收到數據包之後產生一個 IRQ,
        接著在 ISR 裡將這個 skb 加入本地的 `softnet`, 然後觸發本地 `NET_RX_SOFTIRQ` 軟中斷後續處理.
        如果包速過高, 因為 IRQ 的優先級高於 SoftIRQ, 導致系統的大部分資源都在響應中斷,
        但 softnet 的隊列大小有限, 接收到的超額數據包也只能丟掉, 所以這時這個模型是在用寶貴的系統資源做無用功.
        而 NAPI 則在這樣的情況下, 直接把 packets 丟掉, 不會繼續將需要丟掉的 packets 扔給內核去處理,
        這樣, 網卡將需要丟掉的 packets 儘早丟掉, 內核將不需要處理要丟掉的 packets, 這樣也減少了內核的壓力.

+ data structure

    - `struct napi_struct`
        > Newer newer NAPI 的中心結構體是

        ```c
        struct napi_struct {
            /* The poll_list must only be managed by the entity which
             * changes the state of the NAPI_STATE_SCHED bit.  This means
             * whoever atomically sets that bit can add this napi_struct
             * to the per-CPU poll_list, and whoever clears that bit
             * can remove from the list right before clearing the bit.
             */
            struct list_head    poll_list;      // 用於加入處於 polling 狀態的設備隊列

            unsigned long       state;          // 設備的狀態
            int>                weight;         // 每次處理的該設備的最大 skb 數量
            unsigned int        gro_count;
            int>        (*poll)(struct napi_struct *, int); // polling method
        #ifdef CONFIG_NETPOLL
            int>        poll_owner;
        #endif
            struct net_device   *dev;
            struct sk_buff      *gro_list;
            struct sk_buff      *skb;
            struct hrtimer      timer;
            struct list_head    dev_list;
            struct hlist_node   napi_hash_node;
            unsigned int        napi_id;
        };

        ```

        > 與之前的 NAPI 實現的最大的區別是, 該結構體不再是 net_device 的一部分,
        事實上, 現在希望 NIC driver 自己單獨分配與管理 napi instance,
        通常將其放在了 NIC driver 的私有信息, 這樣的好處在於, 如果驅動願意, 可以創建多個 `struct napi_struct`.
        因為現在越來越多的硬件已經開始支持多接收隊列(multiple receive queues),
        如此多個 `struct napi_struct` 的實現使得多隊列的使用也更加的有效.

    - `struct softnet_data`
        > 這是一個 `PER_CPU` 的 queue, 更準確地說是每個 CPU 各自綁定一份,
        屬於該 CPU 的 data queue (incoming packets are placed on per-CPU queues).

        ```c
        struct softnet_data {
            /**
             *  poll_list:
             *      napi->poll_list 結構掛到這個 poll_list,
             *      包括 NAPI interface 的 driver 以及 non-NAPI interface 的 driver ,
             *      都可以統一加入到這個 poll_list
             */
            struct list_head    poll_list;
            struct sk_buff_head process_queue;

            /* stats */
            unsigned int        processed;
            unsigned int        time_squeeze;
            unsigned int        received_rps;
        #ifdef CONFIG_RPS
            struct softnet_data *rps_ipi_list;
        #endif
        #ifdef CONFIG_NET_FLOW_LIMIT
            struct sd_flow_limit __rcu *flow_limit;
        #endif
            struct Qdisc        *output_queue;
            struct Qdisc        **output_queue_tailp;
            struct sk_buff      *completion_queue;

        #ifdef CONFIG_RPS
            /* input_queue_head should be written by cpu owning this struct,
             * and only read by other cpus. Worth using a cache line.
             */
            unsigned int        input_queue_head ____cacheline_aligned_in_smp;

            /* Elements below can be accessed between CPUs for RPS/RFS */
            call_single_data_t  csd ____cacheline_aligned_in_smp;
            struct softnet_data rps_ipi_next;
            unsigned int        cpu;
            unsigned int        input_queue_tail;
        #endif
            unsigned int        dropped;
            struct sk_buff_head input_pkt_queue;
            struct napi_struct  backlog;
        };
        ```

        > `struct softnet_data` 在處理 data 時, 最小單位為 `struct napi_struct`(綁定在 poll_list).
        所以一個 `struct napi_struct` 在 softnet_data 的 poll list 只會發生
        > + enqueue
        > + dequeue
        > + reorder


## Non-NAPI
## NAPI
## API

[Linux NAPI處理流程分析](https://www.cnblogs.com/ck1020/p/6838234.html)

[Linux 內核網絡協議棧 ------ 數據從接收到ip層](https://blog.csdn.net/shanshanpt/article/details/20377657)

[NAPI/非NAPI收包分析](https://chengqian90.com/Linux%E5%86%85%E6%A0%B8/NAPI-%E9%9D%9ENAPI%E6%94%B6%E5%8C%85%E5%88%86%E6%9E%90.html)



+ `net_dev_init()`

    ```c
    // linux at net/core/dev.c
    static int __init net_dev_init(void)
    {
        int i, rc = -ENOMEM;
    ...

        /*
         *  Initialise the packet receive queues.初始化話數據包的接收隊列
         */

        for_each_possible_cpu(i) {  // 對於每一個 CPU 都會進行處理
            struct work_struct *flush = per_cpu_ptr(&flush_works, i);
            struct softnet_data *sd = &per_cpu(softnet_data, i); // 每個 CPU 中都有一個 softnet_data 結構

            INIT_WORK(flush, flush_backlog);

            skb_queue_head_init(&sd->input_pkt_queue);  // 初始化接收數據隊列
            skb_queue_head_init(&sd->process_queue);
    #ifdef CONFIG_XFRM_OFFLOAD
            skb_queue_head_init(&sd->xfrm_backlog);
    #endif
            INIT_LIST_HEAD(&sd->poll_list);  // 初始化設備隊列(注意poll_list在處理數據的時候會被遍歷)
            sd->output_queue_tailp = &sd->output_queue;
    #ifdef CONFIG_RPS
            sd->csd.func = rps_trigger_softirq;
            sd->csd.info = sd;
            sd->cpu = i;
    #endif

            /**
             *  這個很重要!
             *  在以後的處理這個 device 上的數據時,
             *  使用 sd->backlog.poll 這個 callback
             */
            sd->backlog.poll = process_backlog;
            sd->backlog.weight = weight_p;
        }

        netdev_dma_register();

        dev_boot_phase = 0;

        /**
         *  建立 bottom self handler of napi
         */
        open_softirq(NET_TX_SOFTIRQ, net_tx_action, NULL);
        open_softirq(NET_RX_SOFTIRQ, net_rx_action, NULL);

        hotcpu_notifier(dev_cpu_callback, 0);
        dst_init();
        dev_mcast_init();
        rc = 0;
    out:
        return rc;
    }
    ```

+ `netif_rx()`
    > 在傳統(不支援 NAPI) NIC device driver 中的 ISR 呼叫

    ```c
    // linux at net/core/dev.c
    /**
     *  netif_rx()
     *      + netif_rx_internal()
     *          + enqueue_to_backlog()
     */
    static int enqueue_to_backlog(struct sk_buff *skb, int cpu,
                      unsigned int *qtail)
    {
        struct softnet_data *sd;
        unsigned long flags;
        unsigned int qlen;

        sd = &per_cpu(softnet_data, cpu); // 取得當前 CPU 的 softnet_data

        local_irq_save(flags);  // 關中斷，禁止中斷

        rps_lock(sd);
        if (!netif_running(skb->dev))
            goto drop;
        qlen = skb_queue_len(&sd->input_pkt_queue);

        // 每個 CPU 都有輸入隊列的最大長度,如果超過, 則丟棄該數據幀
        if (qlen <= netdev_max_backlog && !skb_flow_limit(skb, qlen)) {
            if (qlen) { // 如果隊列中有元素
    enqueue:
                /**
                 *  將 skb 添加到隊列的末尾
                 *  注意這裡產生軟中斷 NET_RX_SOFTIRQ, 進一步處理包
                 */
                __skb_queue_tail(&sd->input_pkt_queue, skb);
                input_queue_tail_incr_save(sd, qtail);
                rps_unlock(sd);

                /**
                 *  開中斷
                 *  同時需要知道, NET_RX_SOFTIRQ 是由 net_rx_action() 處理
                 */
                local_irq_restore(flags);
                return NET_RX_SUCCESS;
            }

            /* Schedule NAPI for backlog device
             * We can use non atomic operation since we own the queue lock
             */
            if (!__test_and_set_bit(NAPI_STATE_SCHED, &sd->backlog.state)) {
                if (!rps_ipi_queued(sd))
                    /**
                     *  如果 qlen == 0, 說明 sd->backlog 可能已經從當前 CPU 的 poll-list 中移除了,
                     *  要重新加入 list_add_tail(&n->poll_list, &__get_cpu_var(softnet_data).poll_list);
                     *  其實就是讓後面 action 中循環能夠找到這個設備,
                     *  然後 goto 到上面重新將包放入隊列
                     */
                    ____napi_schedule(sd, &sd->backlog);
            }
            goto enqueue;
        }

    drop:
        sd->dropped++; // 紀錄 drop 數量
        rps_unlock(sd);

        local_irq_restore(flags); // 開中斷, 允許中斷

        atomic_long_inc(&skb->dev->rx_dropped);

        /**
         *  因為丟包才能才第到此處,
         *  所以將 skb free 掉並 return NET_RX_DROP
         */
        kfree_skb(skb);
        return NET_RX_DROP;
    }
    ```

+ `process_backlog()`

    ```
    static int process_backlog(struct napi_struct *napi, int quota)
    {
        struct softnet_data *sd = container_of(napi, struct softnet_data, backlog);
        bool again = true;
        int work = 0;

        /* Check if we have pending ipi, its better to send them now,
         * not waiting net_rx_action() end.
         */
        if (sd_has_rps_ipi_waiting(sd)) {
            local_irq_disable();
            net_rps_action_and_irq_enable(sd);
        }

        napi->weight = dev_rx_weight;
        while (again) {
            struct sk_buff *skb;

            // 從隊裡獲取一個 skb
            while ((skb = __skb_dequeue(&sd->process_queue))) {
                rcu_read_lock();
                __netif_receive_skb(skb);  // 處理接收數據
                rcu_read_unlock();
                input_queue_head_incr(sd);
                if (++work >= quota)
                    return work;

            }

            local_irq_disable();
            rps_lock(sd);
            if (skb_queue_empty(&sd->input_pkt_queue)) {
                /*
                 * Inline a custom version of __napi_complete().
                 * only current cpu owns and manipulates this napi,
                 * and NAPI_STATE_SCHED is the only possible flag set
                 * on backlog.
                 * We can use a plain write instead of clear_bit(),
                 * and we dont need an smp_mb() memory barrier.
                 */
                napi->state = 0;
                again = false;
            } else {
                skb_queue_splice_tail_init(&sd->input_pkt_queue,
                               &sd->process_queue);
            }
            rps_unlock(sd);
            local_irq_enable();
        }

        return work;
    }
    ```

+ `netif_napi_add()`
    > NIC driver 告訴內核要使用 napi 的機制
    > + 初始化響應參數
    > + 註冊 poll 的 callback function

    ```c
    // at /net/core/dev.c
    void netif_napi_add(struct net_device *dev, struct napi_struct *napi,
                        int (*poll)(struct napi_struct *, int), int weight)
    {
        INIT_LIST_HEAD(&napi->poll_list);
        hrtimer_init(&napi->timer, CLOCK_MONOTONIC, HRTIMER_MODE_REL_PINNED);
        napi->timer.function = napi_watchdog;
        napi->gro_count = 0;
        napi->gro_list = NULL;
        napi->skb = NULL;

        /**
         *  註冊 poll method
         */
        napi->poll = poll;
        if (weight > NAPI_POLL_WEIGHT)
            pr_err_once("netif_napi_add() called with weight %d on device %s\n",
                        weight, dev->name);

        /**
         *  weight 該值並沒有一個非常嚴格的要求, 實際上是個經驗數據,
         *  一般 10Mb 的網卡, 我們設置為 16, 而更快的網卡, 我們則設置為 64.
         */
        napi->weight = weight;
        list_add(&napi->dev_list, &dev->napi_list);
        napi->dev = dev;
    #ifdef CONFIG_NETPOLL
        napi->poll_owner = -1;
    #endif
        set_bit(NAPI_STATE_SCHED, &napi->state);
        napi_hash_add(napi);
    }
    ```

+ `napi_schedule_prep()`
    >  check if napi can be scheduled or not

+ `__napi_schedule()`
    > NIC driver 告訴內核開始調度 napi 的機制, 稍後 poll callback function 會被調用
    >> switch to polling mode

+ `napi_complete()`
    > NIC driver 告訴內核其工作不飽滿即中斷不多, 數據量不大,
    改變 napi 的狀態機, 後續將採用**純中斷**方式響應數據.
    >> switch to interrupt mode

    ```c
    // at include/linux/netdevice.h
    static inline bool napi_complete(struct napi_struct *n)
    {
        return napi_complete_done(n, 0);
    }
    ```

+ `net_rx_action()`
    > 內核初始化註冊的 softIRQ, 註冊進去的 poll callback function 會被其呼叫

+ `napi_enable/disable`
    > 可能存在多個 `napi_struct` instances, 因此需要每個 instances 都能獨立的開關.
    當 NIC interface 關閉時, 需要 NIC driver 保證有 disable 所有的 napi_struct instances

    ```
    void napi_enable(struct napi *napi);
    void napi_disable(struct napi *napi);
    ```

# skb (socket buffer)

主要操作會在 IP layer (L3), 借鏡 stack 概念, 讓資料往上長.
App layer 在最底下, 每下去一層, 資料就往上長 protocol header

```
    +------------------+     sk_buff mem layout 0
    | struct sk_buff 0 |     +-----------------+
    |  +-------------+ |     | header room     |
    |  | next        | |     +-----------------+
    |  +-------------+ |     |  linear         |
    |  | prev        | |     |  data area      |
    |  +-------------+ |     |    (l0_0)       |
    |  | head/end    | |     +-----------------+
    |  +-------------+ |     | tail room       |
    |  | len = l0    | |     +-----------------+
    |  +-------------+ |     | skb_shared_info |
    +------------------+     | +------------+  |
                             | | frags      |  |          non-linear data area
                             | |          -----+----->  +----------------------+
                             | +------------+  |        | struct skb_frag l0_1 |
                             | | frag_list  |  |        +----------------------+
                +------------+----          |  |        | struct skb_frag l0_2 |
                |            | +------------+  |        +----------------------+
                |            +-----------------+        |   ...                |
                v                                       +----------------------+
    +------------------+                                | struct skb_frag l0_n |
    | struct sk_buff 1 |     sk_buff mem layout 1       +----------------------+
    |  +-------------+ |     +-----------------+
 +------- next       | |     |  header room    |
 |  |  +-------------+ |     +-----------------+
 |  |  | prev        | |     |linear data area |
 |  |  +-------------+ |     |    (l1_0)       |
 |  |  | head/end    | |     +-----------------+
 |  |  +-------------+ |     |  tail room      |
 |  |  | len = l1    | |     +-----------------+
 |  |  +-------------+ |     | skb_shared_info |
 |  +------------------+     | +------------+  |           non-linear data area
 \__________                 | | frags    -----+----->  +----------------------+
            |                | +------------+  |        | struct skb_frag l1_1 |
            v                | | frag_list  |  |        +----------------------+
    +------------------+     | +------------+  |        | struct skb_frag l1_2 |
    | struct sk_buff 2 |     +-----------------+        +----------------------+
    |  +-------------+ |                                |    ...               |
 +-------  next      | |                                +----------------------+
 |  |  +-------------+ |                                | struct skb_frag l1_m |
 |  |  | prev        | |                                +----------------------+
 |  |  +-------------+ |
 |  |  | head/end    | |
 |  |  +-------------+ |
 |  |  | len = l2    | |
 |  |  +-------------+ |
 |  +------------------+
 |
 v
```

```c
// linux 4.16 at include/linux/skbuff.h
struct sk_buff {
...
    struct sk_buff  *next;
    struct sk_buff  *prev;

    /**
     *  struct sock		*sk;
     *  表示從屬於那個 socket, 主要是被 L4 用到.
     *  由本機發出或者由本機進程接收時才有效, 因為插口相關的信息被L4(TCP或 UDP)或者用戶空間程序使用.
     *  如果 sk_buff 只在轉發中使用(src addr 和dest addr 都不是本機地址), 這個指針是 NULL
     */
    struct sock		*sk;
...

    /**
     *  _skb_refdst,
     *  其實應該是 struct dst_entry, 但最後一個 bit (LSB) 被偷去當 refcount.
     *  主要用於路由子系統, 這個數據結構保存了一些路由相關信息
     */
    unsigned long	_skb_refdst;

    /**
     *  skb 的析構函數, 一般都是設置為 sock_rfree 或者 sock_wfree
     */
    void            (*destructor)(struct sk_buff *skb);

...
	unsigned int    len, data_len;
	__u16           mac_len, hdr_len;

...
    __u32	priority;   // 優先級, 主要用於 QOS

...
	__be16          protocol;         //這個表示 L3 層的協議, 比如 IP, IPV6 等等
	__u16           transport_header; // L4, record the offset between head to L4 header
	__u16           network_header;   // L3, record the offset between head to L3 header
	__u16           mac_header;       // L2, record the offset between head to L2 header
...
	sk_buff_data_t  tail;
	sk_buff_data_t  end;
	unsigned char   *head, *data;

    /**
     *  refcount_t  users
     *  reference conut, 只保護 sk_buff 結構本身
     *  通常還是使用函數 skb_get() 和 kfree_skb() 來操作這個變量
     */
    refcount_t      users;
};

struct skb_shared_info {
    atomic_t        dataref;        // 物件被引用次數
    unsigned short  nr_frags;       // 分頁段數目, 即 frags 陣列的元素個數
    unsigned short  tso_size;
    unsigned short  tso_segs;
    unsigned short  ufo_size;
    unsigned int    ip6_frag_id;
    struct sk_buff  *frag_list;     // 用於分段
    skb_frag_t      frags[MAX_SKB_FRAGS]; // 儲存的 memory pages 資料
                                          // skb->data_len = 所有的陣列資料長度之和
};
```

+ data struct

    - `len`
        > 整個資料區域的長度.

        ```
        l1 = l1_0 + (l1_1 + l1_2 + ... + l1_m) + l2
        l0 = l0_0 + (l0_1 + l0_2 + ... + l0_n) + l1

        In struct sk_buff 0
        len = l0
        ```

    - `data_len`
        > fragment 中數據大小

        ```
        l1 = l1_0 + (l1_1 + l1_2 + ... + l1_m) + l2
        l0 = l0_0 + (l0_1 + l0_2 + ... + l0_n) + l1

        In struct sk_buff 0
        data_len = (l0_1 + l0_2 + ... + l0_n) + l1
                 = l0 - l0_0
        ```

    - `head`
        > head pointer of `header room` of sk_buff memory layout
        >> 指向 memory buffer 的開端

    - `data`
        > the current position in **linear data area**
        >> 指向實際數據的開頭 (linear data area)

    - `tail`
        > the tail position in **linear data area**
        >> 指向實際數據的結尾 (linear data area)

    - `end`
        > the end pointer of `end room` of sk_buff memory layout
        >> 指向 memory buffer 的尾端

    - `struct skb_shared_info`
        > 為了減少 copy 的次數, 資料會被對映到多個 memory pages, 稱做 `paged data`.
        使用 `struct skb_grag_struct` 來記錄一個 paged data 資訊,
        而 `skb_shared_info->frags[]` 則用來管理所包含的 `paged datas`

+ API

    - `alloc_skb(size)` at include/linux/skbuff.h
        > 建立 struct sk_buff 並分配 sk_buff 對應的 mem layout
        (head room + linear data area + end room + skb_shared_info)
        >> `size` 包括所有協議層 (L4 ~ L2) 的總和,
        `struct skb_shared_info`則用於管理 paged data 及 fragments

        > head, data 和 tail 都指向記憶體的開始位置 (len = data_len = 0),
        `head` 在這個位置始終不變, 它表示的是分配的記憶體的開始位置.
        `end` 的位置也是不變的, 表示的是分配的記憶體的結束位置.
        >> `data` 和 `tail` 會隨著資料的加入和減少變化, 總之表示的是放入資料的記憶體區域

        ```
        skb->mac_header = (typeof(skb->mac_header))~0U;
            等同
        skb->mac_header = (__u16)~0U;
        ```

    - `kfree_skb()`
        > free an sk_buff,
        >> 使用 ref_cnt 來判定是否真的 free

    - `skb_reserve(len)`
        > 為 protocol header 預留空間, 以最大的空間預留.
        因為很多 header 都會有可選項, 所以只能是按照最大的分配.
        只能用於 buffer 為空時 (len = 0)
        >> 只調整 linear data start address, 可用來 align start address

        ```c
        static inline void skb_reserve(struct sk_buff *skb, int len)
        {
            skb->data += len;
            skb->tail += len;
        }
        ```

        ```
        skb_reserve(m)

        +------------+  <------ head
        |            |      ^
        |            |      |
        | head room  |      | m
        |            |      |
        |            |      |
        |            |      v
        +------------+  <------ tail/data
        | tail room  |
        |            |
        +------------+  <------ end
        ```

    - `skb_put()`
        > 用於操作線性資料區域 `tail room` 的資料, 可以在數據包的末尾追加數據
        >> `tail room` 指 `tail` 到 `end` 的區域

        > 使用限制
        > + 不能用於有 `paged data` (non-linear data) 的情況
        >> user 需自行判斷是否有 `paged data`
        > + 加入的資料不能超過 buffer 實際大小
        >> user 需自行計算大小

        ```c
        void *skb_put(struct sk_buff *skb, unsigned int len)
        {
            void *tmp = skb_tail_pointer(skb);
            SKB_LINEAR_ASSERT(skb);
            skb->tail += len;   // 縮小 tail room
            skb->len  += len;   // 資料空間增大 len
            if (unlikely(skb->tail > skb->end)) // 如果 tail 指標超過end指標了,那麼處理錯誤
                skb_over_panic(skb, len, __builtin_return_address(0));
            return tmp;
        }
        ```
        ```
        skb_put(x)
        len = n + x

        +------------+  <------ head
        |            |
        | head room  |
        |            |
        +------------+  <------ data
        |  data of   |      ^
        |  app layer |      | n bytes
        |            |      v
        +------------+   ------  (prev_tail)
        |  padding   |      ^
        |            |      | x bytes
        |            |      v
        +------------+  <------ tail
        | tail room  |
        +------------+  <------ end
        ```

    - `pskb_put()`
        > 和 skb_put() 相同, 但用於有 `paged data` 的情況

    - `skb_push()`
        > 用於操作 `head room` 區域的協議頭
        >> 用來加入 protocol header

        > 只修改相關的變數, **需額外自行填值到 data area**

        ```
        void *skb_push(struct sk_buff *skb, unsigned int len)
        {
            skb->data -= len;   // 向上移動指標, 縮小 head room
            skb->len  += len;   // 資料長度增加
            if (unlikely(skb->data<skb->head)) // data指標超過head那麼就是處理錯誤
                skb_under_panic(skb, len, __builtin_return_address(0));
            return skb->data;
        }
        ```

        ```
        skb_push(n) // push n bytes
        len = n

        +------------+  <------ head
        |            |
        | head room  |
        |            |
        +------------+  <------ data
        |  data of   |      ^
        |  app layer |      | n bytes
        |            |      v
        +------------+  <------ tail
        | tail room  |
        +------------+  <------ end
        ```
        ```
        skb_push(sizeof(tcp_hdr)) // push sizeof(tcp_hdr) bytes
        len = n + sizeof(tcp_hdr)

        +------------+  <------ head
        |            |
        | head room  |
        |            |
        +------------+  <------ data
        |            |      ^
        |  tcp_hdr   |      | sizeof(tcp_hdr) bytes
        |            |      v
        +------------+   ------
        |  data of   |      ^
        |  app layer |      | n bytes
        |            |      v
        +------------+  <------ tail
        | tail room  |
        +------------+  <------ end
        ```

    - `pskb_may_pll(skb, len)`
        > 判斷是否有足夠的 tata

        ```
        if( !pskb_may_pll(skb, sizeof(struct iphdr)) )
            return err; // skb 不足一個 ip header
        ```

    - `skb_pull()`
        > 與 `skb_push()`對應, 一般用在解包的時候
        >> 用來去除 protocol header, 增大 head room 剩餘的空間

        ```c
        static inline void *__skb_pull(struct sk_buff *skb, unsigned int len)
        {
            skb->len -= len;    // 剝去 header 的大小, 長度減小
            BUG_ON(skb->len < skb->data_len);
            return skb->data += len; // 往下移動指標, 去除一層 protocol header
        }

        static inline void *skb_pull_inline(struct sk_buff *skb, unsigned int len)
        {
            return unlikely(len > skb->len) ? NULL : __skb_pull(skb, len);
        }

        void *skb_pull(struct sk_buff *skb, unsigned int len)
        {
            return skb_pull_inline(skb, len);
        }
        ```
    - `skb_reset_tail_pointer()`
        > 對齊 `tail` 和 `data`
    - `skb_reset_transport_header()`
        > record the offset of head to transport header
    - `skb_reset_network_header()`
        > record the offset of head to network header
    - `skb_reset_mac_header()`
        > record the offset of head to mac header

    - `skb_headroom()`
        > get head room length
        >> head room 還剩多少空間

    - `skb_tailroom()`
        > get the tail room
        >> tail room 還剩多少空間 (only linear data area)

    - `skb_clone()`
        > 只複製 struct skb 而不複製 data buffer

        ```
                                                                       clone
        +---------------+            sk_buff mem layout           +---------------+
        |struct sk_buff |  +------> +-----------------+ <-----+   | struct sk_buff|
        |               |  |        |  header room    |       |   |               |
        |    head   -------+  +---> +-----------------+ <--+  +-------- head      |
        |    data   ----------+     |linear data area |    +----------- data      |
        |    tail   -----------+    |    (l1_0)       |     +---------- tail      |
        |    end    -------+   +--> +-----------------+ <---+  +------- end       |
        +---------------+  |        |  tail room      |        |  |               |
                           +------> +-----------------+ <------+  +---------------+
                                    | skb_shared_info |
                                    +-----------------+
        ```

    - `pskb_copy()`
        > 只複製 skb 的 struct skb 及 linear data area, skb_shared_info 的部分則共用

        ```
           skb                                                                         skb
        +------+             sk_buff mem layout      sk_buff mem layout           +------+
        | head -----------> +-----------------+     +-----------------+ <---------- head |
        | data -------+     |  header room    |     |  header room    |     +------ data |
        | tail ----+  +---> +-----------------+     +-----------------+ <---+ +---- tail |
        | end  --+ |        |linear data area |     |linear data area |       | +-- end  |
        |      | | |        |    (l1_0)       |     |    (l1_0)       |       | | |      |
        +------+ | +------> +-----------------+     +-----------------+ <-----+ | +------+
                 |          |  tail room      |     |  tail room      |         |
                 +--------> +-----------------+     +-----------------+ <-------+
                            | skb_shared_info ---+--- skb_shared_info |
                            +-----------------+  |  +-----------------+
                                                 |
                                                 v
                                          +---------------+
                                          | fragment buff |
                                          +---------------+
        ```

    - `skb_copy()`
        > 整個 skb 都複製, 包括 linear data area 及 skb_shared_info (non-linear data area)

        ```
           skb                                                                      skb
        +------+             sk_buff mem layout      sk_buff mem layout           +------+
        | head -----------> +-----------------+     +-----------------+ <---------- head |
        | data -------+     |  header room    |     |  header room    |     +------ data |
        | tail ----+  +---> +-----------------+     +-----------------+ <---+ +---- tail |
        | end  --+ |        |linear data area |     |linear data area |       | +-- end  |
        |      | | |        |    (l1_0)       |     |    (l1_0)       |       | | |      |
        +------+ | +------> +-----------------+     +-----------------+ <-----+ | +------+
                 |          |  tail room      |     |  tail room      |         |
                 +--------> +-----------------+     +-----------------+ <-------+
                            | skb_shared_info |     | skb_shared_info |
                            +--------|--------+     +------|----------+
                                     |                     |
                                     v                     v
                              +---------------+     +---------------+
                              | fragment buff |     | fragment buff |
                              +---------------+     +---------------+
        ```

    - `skb_trim()`
        > cut buffer 到一個長度
        >> 有 `paged data`時, 則需使用 `pskb_trim()`

    - `skb_shinfo()`
        > 獲得 `skb_shared_info`的 pointer

        ```
        // 直接 cast skb->end to pointer of struct skb_shared_info
        #define skb_shinfo(SKB)         ((struct skb_shared_info *)(skb_end_pointer(SKB)))
        ```

+ sk_buff using behavior

    - create skb structure

        ```
        len = sizeof(struct sk_buff)
        ```

    - create skb data buffer (sk_buff mem layout)

        ```
        size = (size of L2 header)
             + (size of L3 header)
             + (size of L4 header)
             + (size of payload)
             + sizeof(struct skb_shared_info)
        ```

    - reserve the max protocol header size (L2 + L3 + L4)

        ```
        sk_reserve(skb, header_len);
        ```

    - copy payload to tail room
        > payload 往下擴充

        ```
        skb_put(skb, user_data_len);
        csum_and_copy_from_user()  // calculate checksum and copy user data to sk_buff
        ```

    - request head room to set UDP header
        > protocol header 往上設置

        ```
        pUdp_hdr = skb_push(skb, udp_header_len);
        ```

    - request head room to set IP header
        > protocol header 往上設置

        ```
        pIp_hdr = skb_push(skb, ip_header_len);
        ```

    - request head room to set MAC header
        > protocol header 往上設置

        ```
        pMac_hdr = skb_push(skb, mac_header_len);
        ```



# Socket work flow

```
     [server]            [client]

     socket()            socket()
        |                   |
        v                   |
      bind()                |
        |                   |
        v                   |
     listen()               |
        |                   |
        v                   v
     accept()  <------- connect()
        |                   |
        v                   v
      recv()   <-------   send()
        |                   |
        v                   v
     close()             close()

```

```
                    +--------------------+
                    |    application     |
                    |   socket()/bind()  |
    user            |    send()/recv()   |
    space           +--------------------+
   ___________________________|___________________________________
                              v
    kernel      +----------------------------+
    space       | VFS (Virtual File System)  |
                +----------------------------+
                    +------------------------+      --+
                    |           INET         |        |
                    +------------------------+        |
                    +-----+ +-------+ +------+        |
                    | TCP | | IP    | | ICMP |        |
                    +-----+ |       | |      |        |
                    +-------+       | |      |        | TCP/IP stack
                    | reouting      | |      |        |
                    |      system   | |      |        |
                    +---------------+ +------+        |
                    +-----+ +----------------+        |
                    | ARP | | Neighbour      |        |
                    |     | |     sub-system |        |
                    +-----+ +----------------+      --+
                    +------------------------+
                    |      Device driver     |
                    +------------------------+
   ___________________________|___________________________________
                              v
    H/w                    MAC/PHY
```

+ `INET`
    > 是 Linux 網絡子系統的一個抽象層次, 向上提供了操作的接口,
    但實際還需要調用下層的功能才能完成數據發收, 監聽等任務.
    具體調用下層的什麼功能, 要根據通信類別(TCP/UDP/RAW)來選擇.
    >> `RAW`從某種意義上說, 並不是額外的應用層通信方式, 它只是告訴應用層不用理會,
    直接把數據傳遞到下一層即可, 由網絡層直接處理.
    `ICMP` 是基於 `RAW` 方式的一個重要協議, 只不過它有一些特殊的性質, 所以單獨列出.

    - 核心數據結構, 就是 `struct socket`.
    每一個 socket 文件都有一個 socket 控制實體(數據結構 struct socket 的 instance)與之對應.
    這個 socket 控制實體, 自身以及其成員包含了 socket 的所有信息,
    包括狀態, 標誌, 操作, 數據緩衝區信息等.


+ `ARP` (Address Resolution Protocol)
    > ARP 的功能, 是將 IP 地址映射成 MAC address 的**過程**
    >> 位址解析(address resolution)就是主機在傳送 frame 前,
    將 destination IP 位址轉換成 dastination MAC 位址的過程.

    - 運作方式
        > 當主機 A(163.15.2.1)欲透過 Ethernet 網路傳送訊息給 IP = 163.15.2.4 主機,
        則發送出 ARP Request(查問 163.15.2.4)廣播到所屬網路區段內.
        所有主機都會接收到該 ARP Request 封包, 並分解是否詢問自己, 如果不是就不予理會而拋棄.
        主機 C(163.15.2.4)收到 ARP Request 後, 發現詢問自己則回應 ARP Reply(包含 MAC 位址)給發問者(163.15.2.1)

+ `Neighbour sub-system`
    > 將 IP 地址映射成 data link 硬件地址
    >> MAC 地址是硬件地址的一種. 對於非以太網設備, 其硬件地址不一定是 MAC 地址.
    ARP 可以看成是 Neighbour sub-system 的一個特殊情況.



## data structure

對網際網路協議而言, 包含很多協議簇(Protocal Families, PF)或是地址簇(Address Families, AF),
像是 `AX25` 協議簇, `INET4` 協議簇, `INET6` 協議簇,
`IPX(Internetwork Packet Exchange)` 協議簇, `DNNET`協議簇等.

而每一個協議簇中又包含多個協議,
以 INET4 協議簇為例, 又包含`ipv4`, `tcp`, `udp`, `icmp`等協議.

針對網路協議簇與網路協議之間的關係, linux sockfs的架構也按此進行了劃分.

Normal structure:
```
    +--> struct socket         +------> struct proto_ops
    |       * ops   -----------+            * connect
    |    +- * sock                          * accept
    |    |                                  * listen      ops of system
    |    |                                  * bind         ^
    |    |                                  * sendmsg      |
    |    |                                  * recvmsg      |
    |    |   ___________________________________________________________
    |    v
    |   struct sock              +----> struct proto       |
    +------ * sk_socket          |          * connect      |
            * sk_prot -----------+          * accept       v
                (struct sock_common         * bind        ops of transport (L4)
                    -> skc_prot)            * sendmsg
                                            * recvmsg
```

在 `/net/ipv4/af_inet.c` 中, 使用 `strcut inet_protosw  inetsw_array[]` 定義了所支援的 protocols,
另外定義了 global inetsw, 用於串接 inet4 相關的所有 `strcut inet_protosw` 類型
af_inet4 註冊的變量如下所示, 包含了 `tcp`, `udp`, `icmp`, `raw socket` 等.

```
/* This is used to register socket interfaces for IP protocols.  */
struct inet_protosw {
    struct list_head list;

        /* These two fields form the lookup key.  */
    unsigned short   type;     /* This is the 2nd argument to socket(2). */
    unsigned short   protocol; /* This is the L4 protocol number.  */

    struct proto            *prot;
    const struct proto_ops  *ops;

    unsigned char    flags;      /* See INET_PROTOSW_* below.  */
};

static struct list_head  inetsw[SOCK_MAX];

// 依照 type 分類串接
inetsw[SOCK_DGRAM] -----------+
inetsw[SOCK_STREAM]---+        |
inetsw[SOCK_RAW]      |        |
                      |        |
                      |        |
        --------------+        |
        |                      v
        |  +------------------------------------+      +-------------------------------------+
        |  | struct inet_protosw inetsw_udp = { | <--> | struct inet_protosw inetsw_icmp = { |
        |  |     type     = SOCK_DGRAM,         |      |     type     = SOCK_DGRAM,          |
        |  |     protocol = IPPROTO_UDP,        |      |     protocol = IPPROTO_ICMP,        |
        |  |     prot     = &udp_prot,          |      |     prot     = &ping_prot,          |
        |  |     ops      = &inet_dgram_ops,    |      |     ops      = &inet_sockraw_ops,   |
        |  | }                                  |      | }                                   |
        |  +------------------------------------+      +-------------------------------------+
        |
        v
    +---------------------------------------+
    | struct inet_protosw inetsw_stream = { |
    |     type     = SOCK_STREAM,           |
    |     protocol = IPPROTO_TCP,           |
    |     prot     = &tcp_prot,             |
    |     ops      = &inet_stream_ops,      |
    | }                                     |
    +---------------------------------------+
```


+ `struct socket`
    > 主要 socket handle

+ `struct sock`
    > 包括 source/distination ip address, socket 收發的 queue 等信息


+ `struct net_proto_family`
    > 該結構體主要用於說明網絡協議簇, 即針對ax25協議簇,inet4協議簇,inet6協議簇,ipx協議簇等.

    ```c
    struct net_proto_family {
        int family;
        int (*create)(struct net *net, struct socket *sock,
                        int protocol, int kern);
        struct module *owner;
    };
    ```

    - `family` 用於說明協議簇的類型,
        > 目前linux支持的協議簇類型包括
        > + AF_UNIX
        > + AF_LOCAL
        > + AF_INET
        > + AF_INET6
        > + AF_NETLINK

    - `create()`, 用於初始化 `strcut sock`類型,
    根據傳遞的協議號, 掛上協議相關的 description.

+ `struct inet_protosw`
    > 定義主要 inet 相關的實現

    ```c
    enum sock_type
    {
        SOCK_STREAM = 1,
        SOCK_DGRAM = 2,
        SOCK_RAW = 3,
        SOCK_RDM = 4,
        SOCK_SEQPACKET = 5,
        SOCK_DCCP = 6,
        SOCK_PACKET = 10,
    };

    struct inet_protosw
    {
        struct list_head list;

        /* These two fields form the lookup key. */
        unsigned short  type; /* This is the 2nd argument to socket(2). */
        unsigned short  protocol; /* This is the L4 protocol number. */
        struct proto    *prot;
        const struct proto_ops *ops;
        char            no_check; /* checksum on rcv/xmit/none? */
        unsigned char   flags; /* See INET_PROTOSW_* below. */

    };
    ```

    - `type` 用於指示socket的類型
        > socket 的類型包括 `SOCK_STREAM`, `SOCK_DGRAM`
        具體的類型 `enum sock_type`
    - `protocol` 用於說明協議的類型
        > 包括 `ip`, `tcp`, `udp`, `icmp`, `dccp`等

    - `prot` 用於指向協議相關的處理接口
    - `proto_ops` 用於指向 socket 類型的 interface(SOCK_STREAM/SOCK_DGRAM 等對應的interface)

+ `struct proto_ops`
    > 主要用於描述 socket 類型(SOCK_STREAM/SOCK_DGRAM 等)的 interface,
    其中 `family` 用於說明協議簇的類型;
    而 `release`, `bind`, `connect`, `accept`, `poll`, `ioctl`, `listen`, `shutdown`, `setsockopt` 等,
    則與 sockfs 提供的系統調用 interface 對應.

+ `struct proto`
    > 主要用於具體協議相關的 description, 對於大多數協議的 socket 而言,
    只需要使用註冊的 `struct proto_ops` 所提供的 description, 即可完成對 sockfs 的系統調用的實現;
    而對一些特定的協議(e.g. udp, icmp, tcp), 則需要使用 `struct proto` 來進行定義.


## net init flow of kernel booting

```
// linux at /init/main.c
start_kernel()
    - rest_init()
        - kernel_init() with kernel thread
            - kernel_init_freeable()
                - do_basic_setup()
                    - do_initcalls()
                        + core_initcall(sock_init); // init_lv 1, at /net/socket.c
                        - fs_initcall(inet_init);   // inti_lv 5, at /net/ipv4/af_inet.c
                            + arp_init/ip_init/tcp_init/icmp_init
```


+ `inet_init()` at `/net/ipv4/af_inet.c`

    - regitster interface of protocols of `transport layer (L4)` to `socket layer (user)`
        > methods
        > + `connect`
        > + `bind`
        > + `ioctl`
        > + `setsockopt/getsockopt`
        > + `shutdown`

        ```c
        proto_register(&tcp_prot, 1);
        proto_register(&udp_prot, 1);
        proto_register(&raw_prot, 1);
        proto_register(&ping_prot, 1);

        (void)sock_register(&inet_family_ops);
        ```

    - register recv_handler of protocols of `transport layer (L4)` to `IP layser (L3)`
        > IP layer parses the IP header (get protocol type) and pass packets to upper layer

        ```c
        inet_add_protocol(&icmp_protocol, IPPROTO_ICMP); // for ping function
        inet_add_protocol(&udp_protocol, IPPROTO_UDP);
        inet_add_protocol(&tcp_protocol, IPPROTO_TCP);
        ```

    - 在 `struct inet_protosw inetsw_array[]` 中,
    每個元素的 `struct proto_ops` 和`struct proto`都會被初始化,
    並且透過 `inet_register_protosw()`,
    將每個元素註冊到全域 `static struct list_head inetsw[SOCK_MAX];`


## send/recv flow

TODO draw flow chart
* [Linux內核二層數據包接收流程](https://blog.csdn.net/eric_liufeng/article/details/10286593)
* [Linux內核數據包的發送傳輸](https://blog.csdn.net/eric_liufeng/article/details/10252857)


+ send

    - socket (app) to transpot layer
        > app to L4

        ```
        // linux at net/socket.c
        sock_sendmsg()
            + __sock_sendmsg()
                + struct socket *sock;
                + sock->ops->sendmsg() // 這個 ops 是 struct socket 結構體中的 struct proto_ops
                    + inet_sendmsg
                        + struct sock *sk = sock->sk;
                        + sk->sk_prot->sendmsg() // 這個 ops 是 struct sock 結構體中的 struct proto
                            e.g. udp_sendmsg()
        ```

    - transport layer (L4) to network layer (L3)

        ```
        // linux at net/ipv4/udp.c
        udp_sendmsg()
            + ip_route_output_flow()
            + ip_make_skb()
                + udp_send_skb(skb, fl4)
        ```

        1. `udp_sendmsg`
            > udp 模塊發送數據包的入口, 在該函數中會先調用 `ip_route_output_flow()` 獲取路由信息(主要包括 Src IP 和網卡),
            然後調用 `ip_make_skb()` 構造 skb 結構體, 最後將網卡的信息和該 skb 連結.

        1. `ip_route_output_flow()`
            > 該函數會根據路由表和目的 IP, 找到這個數據包應該從哪個設備發送出去.
            > + 如果該 socket 沒有綁定 Src IP, 該函數還會根據路由表找到一個最合適的 Src IP 給它.
            > + 如果該 socket 已經綁定了 Src IP, 但根據路由表, 從這個 Src IP 對應的網卡沒法到達目的地址,
            則該包會被丟棄, 於是數據發送失敗, `sendto()` 將返回錯誤.
            `ip_route_output_flow()`最後會將找到的設備和 Src IP 塞進 flowi4 結構體並返回給 `udp_sendmsg()`

        1. `ip_make_skb()`
            > 該函數的功能是構造 skb 包, 構造好的 skb 包裡面已經分配了 IP header,
            並且初始化了部分信息(IP header 的 Src IP 就在這裡被設置進去),
            同時會呼叫 `__ip_append_dat()`, 如果需要 fragment 的話, 會在 `__ip_append_data()` 中進行分片,
            同時還會檢查 socket 的 **send buffer** 是否已經用光, 如果被用光的話, 返回 **ENOBUFS**.

        1. `udp_send_skb(skb, fl4)`
            > 主要是往 skb 裡面填充 UDP header, 同時處理 checksum, 然後調用 IP 層的相應函數.

    - network layer (L3) to data link layer (L2)

        ```
        udp_send_skb(skb, fl4)
            // linux at net/ipv4/ip_output.c
            + ip_send_skb()
                + ip_local_out()
                    +__ip_local_out()
                        + nf_hook(NF_INET_LOCAL_OUT)
                            -> dst_output() at /include/net/dst.h
                                |
                        +-------+
                        |
                        v
                    + ip_output()
                        + NF_HOOK_COND(NF_INET_POST_ROUTING)
                            -> ip_finish_output()
                                |
                        +-------+
                        |
                        v
                    + ip_finish_output2
                        + neigh_output()
                            + neigh_hh_output()
                                + dev_queue_xmit()
                                + n->output(n, skb)
                                    -> neigh_resolve_output() at net/ipv4/arp.c

        ps. n->output(n, skb) 和 n->nud_state 有關,
            屬鄰居子系統的範疇, 最後他們的出口都是 dev_queue_xmit()
        ```

        1. `ip_send_skb()`
            > IP 模塊發送數據包的入口, 該函數只是簡單的調用一下後面的函數

        1. `__ip_local_out_sk()`
            > 設置 IP header 的長度和 checksum, 然後調用下面 **netfilter** 的鉤子(hook)

        1. `nf_hook(..., NF_INET_LOCAL_OUT)`
            > netfilter 的 hook, 可以通過 iptables 來配置怎麼處理該數據包,
            如果該數據包沒被丟棄, 則繼續往下走

        1. `dst_output()`
            > 該函數根據 skb 裡面的信息, 調用相應的 output 函數, 在我們 UDP IPv4 這種情況下,
            會調用 `ip_output()`

        1. `ip_output()`
            > 將上面 udp_sendmsg 得到的網卡信息寫入 skb, 然後調用 NF_INET_POST_ROUTING 的鉤子

            ```c
            int ip_output(struct net *net, struct sock *sk, struct sk_buff *skb)
            {
                struct net_device *dev = skb_dst(skb)->dev;

                IP_UPD_PO_STATS(net, IPSTATS_MIB_OUT, skb->len);

                /* 設置輸出設備和協議 */
                skb->dev = dev;
                skb->protocol = htons(ETH_P_IP);

                /* 經過NF的POST_ROUTING鉤子點 */
                return NF_HOOK_COND(NFPROTO_IPV4, NF_INET_POST_ROUTING,
                                    net, sk, skb, NULL, dev,
                                    ip_finish_output,
                                    !(IPCB(skb)->flags & IPSKB_REROUTED));
            }
            ```

        1. `NF_HOOK_COND(..., NF_INET_POST_ROUTING)`
            > 在這裡, 用戶有可能配置了 SNAT, 從而導致該 skb 的路由信息發生變化

        1. `ip_finish_output()`
            > 這裡會判斷經過了上一步後, 路由信息是否發生變化,
            如果發生變化的話, 需要重新調用 `dst_output()`, 否則往下走

            > 重新調用`dst_output()`時, 可能就不會再走到 `ip_output()`,
            而是走到被 netfilter 指定的 output 函數裡,
            這裡有可能是 xfrm4_transport_output()

            ```c
            static int ip_finish_output(struct net *net, struct sock *sk, struct sk_buff *skb)
            {
                unsigned int mtu;
                int ret;

                ret = BPF_CGROUP_RUN_PROG_INET_EGRESS(sk, skb);
                if (ret) {
                    kfree_skb(skb);
                    return ret;
                }

                #if defined(CONFIG_NETFILTER) && defined(CONFIG_XFRM)
                /* Policy lookup after SNAT yielded a new policy */
                if (skb_dst(skb)->xfrm) {
                    IPCB(skb)->flags |= IPSKB_REROUTED;
                    return dst_output(net, sk, skb);
                }
                #endif
                /* 獲取mtu */
                mtu = ip_skb_dst_mtu(sk, skb);

                /* 是gso, 則調用gso輸出 */
                if (skb_is_gso(skb))
                    return ip_finish_output_gso(net, sk, skb, mtu);

                /* 長度>mtu或者設置了IPSKB_FRAG_PMTU標記, 則分片 */
                if (skb->len > mtu || (IPCB(skb)->flags & IPSKB_FRAG_PMTU))
                    return ip_fragment(net, sk, skb, mtu, ip_finish_output2);

                /* 輸出數據包 */
                return ip_finish_output2(net, sk, skb);
            }
            ```

        1. `ip_finish_output2()`
            > 根據 dest IP 到路由表裡面找到下一跳(nexthop)的地址,
            然後調用 `__ipv4_neigh_lookup_noref()`去 arp表裡面找下一跳的 neighbor 信息,
            沒找到的話會調用 `__neigh_create()`構造一個空的 neigh 結構體

            ```c
            static int ip_finish_output2(struct net *net, struct sock *sk, struct sk_buff *skb)
            {
                struct dst_entry *dst = skb_dst(skb);
                struct rtable *rt = (struct rtable *)dst;
                struct net_device *dev = dst->dev;
                unsigned int hh_len = LL_RESERVED_SPACE(dev);
                struct neighbour *neigh;
                u32 nexthop;

                if (rt->rt_type == RTN_MULTICAST) {
                    IP_UPD_PO_STATS(net, IPSTATS_MIB_OUTMCAST, skb->len);
                }
                else if (rt->rt_type == RTN_BROADCAST)
                    IP_UPD_PO_STATS(net, IPSTATS_MIB_OUTBCAST, skb->len);

                /* Be paranoid, rather than too clever. */
                /* skb頭部空間不能存儲鏈路頭 */
                if (unlikely(skb_headroom(skb) < hh_len && dev->header_ops)) {
                    struct sk_buff *skb2;

                    /* 重新分配skb */
                    skb2 = skb_realloc_headroom(skb, LL_RESERVED_SPACE(dev));
                    if (!skb2) {
                        kfree_skb(skb);
                        return -ENOMEM;
                    }
                    /* 關聯控制塊 */
                    if (skb->sk)
                        skb_set_owner_w(skb2, skb->sk);

                    /* 釋放skb */
                    consume_skb(skb);

                    /* 指向新的skb */
                    skb = skb2;
                }

                if (lwtunnel_xmit_redirect(dst->lwtstate))
                {
                    int res = lwtunnel_xmit(skb);

                    if (res <  || res == LWTUNNEL_XMIT_DONE)
                        return res;
                }

                rcu_read_lock_bh();
                /* 獲取下一跳 */
                nexthop = (__force u32) rt_nexthop(rt, ip_hdr(skb)->daddr);
                /* 獲取鄰居子系統 */
                neigh = __ipv4_neigh_lookup_noref(dev, nexthop);

                /* 創建鄰居子系統 */
                if (unlikely(!neigh))
                    neigh = __neigh_create(&arp_tbl, &nexthop, dev, false);

                /* 成功 */
                if (!IS_ERR(neigh)) {
                    int res;

                    /* 更新路由緩存確認 */
                    sock_confirm_neigh(skb, neigh);

                    /* 通過鄰居子系統輸出 */
                    res = neigh_output(neigh, skb);

                    rcu_read_unlock_bh();
                    return res;
                }
                rcu_read_unlock_bh();

                net_dbg_ratelimited("%s: No header cache and no neighbour!\n",
                                    __func__);
                /* 釋放skb */
                kfree_skb(skb);
                return -EINVAL;
            }
            ```

        1. `neigh_output()`
            > 在該函數中, 如果上一步 `ip_finish_output2()` 得到 neigh 信息,
            將直接調用 `neigh_hh_output()`進行快速輸出, 否則調用鄰居子系統的輸出回調函數進行慢速輸出
            >> 將 neigh 信息裡面的 mac 地址填到 skb 中, 然後調用 `dev_queue_xmit()` 發送數據包

            > 否則調用鄰居子系統的輸出回調函數進行慢速輸出

            ```c
            static inline int neigh_hh_output(const struct hh_cache *hh, struct sk_buff *skb)
            {
                unsigned int seq;
                unsigned int hh_len;

                /* 拷貝二層頭到skb */
                do {
                    seq = read_seqbegin(&hh->hh_lock);
                    hh_len = hh->hh_len;
                    /* 二層頭部 < DATA_MOD, 直接使用該長度拷貝 */
                    if (likely(hh_len <= HH_DATA_MOD)) {
                        /* this is inlined by gcc */
                        memcpy(skb->data - HH_DATA_MOD, hh->hh_data, HH_DATA_MOD);
                    }
                    /* >= DATA_MOD, 對齊頭部, 拷貝 */
                    else {
                        unsigned int hh_alen = HH_DATA_ALIGN(hh_len);

                        memcpy(skb->data - hh_alen, hh->hh_data, hh_alen);
                    }
                } while (read_seqretry(&hh->hh_lock, seq));

                skb_push(skb, hh_len);

                /* 發送 */
                return dev_queue_xmit(skb);
            }

            static inline int neigh_output(struct neighbour *n, struct sk_buff *skb)
            {
                const struct hh_cache *hh = &n->hh;

                /* 連接狀態  && 緩存的頭部存在, 使用緩存輸出 */
                if ((n->nud_state & NUD_CONNECTED) && hh->hh_len)
                    return neigh_hh_output(hh, skb);
                /* 使用鄰居項的輸出回調函數輸出, 在連接或者非連接狀態下有不同的輸出函數 */
                else
                    return n->output(n, skb);
            }
            ```
    - data link layer (netdevice)

        ```
                        |
                        v
               +------------------+
        +------| dev_queue_xmit() |
        |      +------------------+
        |                   |
        |                   v
        |            +----------------–+
        |            | Traffic Control |
        |            +----------------–+
        | loopback          |
        |   or              +------------------------------------------------------–+
        | IP tunnels        |                                                       |
        |                   v                                                       v
        |     +-----------------------+  Failed +----------------+      +-----------------+
        +---–>| dev_hard_start_xmit() | ----->  | raise          | ---> | net_tx_action() |
              +-----------------------+         | NET_TX_SOFTIRQ |      +-----------------+
                            |                   +----------------+
                            +-------------------------+
                            |                         |
                            v                         v
                    +------------------+     +------------------------+
                    | ndo_start_xmit() |     | packet taps(AF_PACKET) |
                    +------------------+     +------------------------+
        ```

        1. `dev_queue_xmit()`
            > netdevice 子系統的入口函數, 它會先獲取設備對應的 qdisc,
            如果沒有的話(e.g. loopback 或者 IP tunnels), 就直接調用 `dev_hard_start_xmit()`,
            否則數據包將經過 Traffic Control 模塊進行處理

        1. Traffic Control
            > 這裡主要是進行一些過濾和優先級處理, 在這裡, 如果隊列滿了的話, 數據包會被丟掉,
            詳情請參考文檔, 這步完成後也會走到 `dev_hard_start_xmit()`

        1. `dev_hard_start_xmit()`
            > 該函數中, 首先是拷貝一份 skb 給 `packet taps()`(tcpdump 就是從這裡得到數據的),
            然後調用 `ndo_start_xmit()`.
            如果 `dev_hard_start_xmit()` 返回 Failed 的話(大部分情況可能是 NETDEV_TX_BUSY),
            調用它的函數會把 skb 放到一個地方, 然後拋出軟中斷 `NET_TX_SOFTIRQ`,
            交給 softIRQ 處理程序 `net_tx_action()` 稍後重試
            (如果是 loopback 或者 IP tunnels 的話, 失敗後不會有重試的邏輯)

            ```c
            static inline netdev_tx_t __netdev_start_xmit(const struct net_device_ops *ops,
                    struct sk_buff *skb, struct net_device *dev,
                    bool more)
            {
                skb->xmit_more = more ? 1 : 0;
                return ops->ndo_start_xmit(skb, dev);
            }

            static inline netdev_tx_t netdev_start_xmit(struct sk_buff *skb, struct net_device *dev,
                    struct netdev_queue *txq, bool more)
            {
                const struct net_device_ops *ops = dev->netdev_ops;
                int rc;
                /* __netdev_start_xmit 裏面就完全是使用driver 的ops去發包了, 其實到此爲止, 一個 skb 已經從 netdevice
                 * 這個層面送到 driver 層了, 接下來會等待 driver 的返回*/
                rc = __netdev_start_xmit(ops, skb, dev, more);

                /*如果返回 NETDEV_TX_OK, 那麼會更新下 Txq 的 trans 時間戳哦, txq->trans_start = jiffies;*/
                if (rc == NETDEV_TX_OK)
                    txq_trans_update(txq);

                return rc;
            }

            static int xmit_one(struct sk_buff *skb, struct net_device *dev,
                                struct netdev_queue *txq, bool more)
            {
                unsigned int len;
                int rc;

                /* 如果有抓包的工具的話, 這個地方會進行抓包, such as Tcpdump */
                if (!list_empty(&ptype_all))
                    dev_queue_xmit_nit(skb, dev);

                len = skb->len;
                trace_net_dev_start_xmit(skb, dev);
                /* 調用 netdev_start_xmit, 快到driver的tx函數了 */
                rc = netdev_start_xmit(skb, dev, txq, more);
                trace_net_dev_xmit(skb, rc, dev, len);

                return rc;
            }

            struct sk_buff *dev_hard_start_xmit(struct sk_buff *first, struct net_device *dev,
                                                struct netdev_queue *txq, int *ret)
            {
                struct sk_buff *skb = first;
                int rc = NETDEV_TX_OK;
                /*此處skb爲什麼會有鏈表呢？*/
                while (skb) {
                    /*取出skb的下一個數據單元*/
                    struct sk_buff *next = skb->next;
                    /*置空, 待發送數據包的next*/
                    skb->next = NULL;

                    /*將此數據包送到driver Tx函數, 因爲dequeue的數據也會從這裏發送, 所以會有netx！*/
                    rc = xmit_one(skb, dev, txq, next != NULL);

                    /*如果發送不成功, next還原到 skb->next 退出*/
                    if (unlikely(!dev_xmit_complete(rc))) {
                        skb->next = next;
                        goto out;
                    }
                    /*如果發送成功, 把next置給skb, 一般的next爲空 這樣就返回, 如果不爲空就繼續發！*/
                    skb = next;

                    /*如果txq被stop, 並且skb需要發送, 就產生TX Busy的問題！*/
                    if (netif_xmit_stopped(txq) && skb) {
                        rc = NETDEV_TX_BUSY;
                        break;
                    }
                }

            out:
                *ret = rc;
                return skb;
            }
            ```

        1. `packet taps(AF_PACKET)`
            > 當第一次發送數據包和重試發送數據包時, 都會經過這裡

        1. `ndo_start_xmit()`
            > 會綁定到具體網卡驅動的相應函數, 到這步之後, 就歸網卡 driver 管了

+ recv

```
                tcp_v4_rcv()
                udp_rcv()
                icmp_rcv()
                    ^
    transport       |
    layer           |
    ________________|___________________________________
    network         |
    layer           |
                    |
            ip_local_deliver()
                    ^
                    | local host
                    |               not host
          ip_route_input_noref() --------------+
              [路由節點查找]                   |
                    ^                          |
                    |                          v
                    |                    ip_forward()
             ip_rcv_finish()                   |
                    ^                          |
                    | Yes                      |
                    |                 No       |
        NF_HOOK(NF_INET_PRE_ROUTING) ----+     |
                    ^                    |     |
                    |                    |     |
                    |                    v     |
                 ip_rcv()               drop   |
                    ^                          |
                    |                          |
    ________________|__________________________v________
    device
    driver             MAC/PHY

```
    - socket (app) to transpot layer
        > app to L4

        ```
        // linux at net/socket.c
        sock_recvmsg()
            + __sock_recvmsg()
                + struct socket *sock;
                + sock->ops->recvmsg() // 這個 ops 是 struct socket 結構體中的 struct proto_ops
                    + sock_common_recvmsg()
                        + struct sock *sk = sock->sk;
                        + sk->sk_prot->recvmsg() //這個 ops 是 struct sock 結構體中的 struct proto
                            e.g. udp_recvmsg()
        ```

    - data link layer (L2) to network layer (L3)
        > 從 `netif_receive_skb(struct sk_buff *skb)` 開始, 網卡收到數據包後產生中斷通知 CPU 有數據到達,
        在中斷服務函數中觸發接收軟中斷, 等待內核在適當的時間調度 NAPI 方式的接收函數完成數據的接收,
        並非所有網卡或者 MAC 控制器都是支持 NAPI方法(需要硬件能支持)的,
        NAPI 服務函數最重要的工作就是調用 `netif_receive_skb` 將數據從 data link 層 (L2)送到 network 層 (L3).

        > 收到的數據最終能不能送到應用層, 是和擁塞控制/路由/協議層如何處理該數據包相關的,
        由於該函數是在軟中斷(softIRQ)中調用的, 所以該函數執行時硬件中斷是開啟的,
        這就意味著可能前一次 MAC 接收到的數據還沒有傳遞到網絡層時, MAC 又接收到數據又產生新中斷,
        而新的數據需要存放在一個通常被稱為 DMA 緩衝區的地方, 這也意味著要支持NAPI方式就需要多個緩衝區,
        這也是硬件為支持NAPI方式必須支持的一個特性.


        ```c
        // linux at /net/core/dev.c
        netif_receive_skb()
            + netif_receive_skb_internal()
                + __netif_receive_skb()
                    + __netif_receive_skb_core()
                        + deliver_skb()
        ```

        1. `deliver_skb()`

            ```c
            static inline int deliver_skb(struct sk_buff *skb,
                              struct packet_type *pt_prev,
                              struct net_device *orig_dev)
            {
                if (unlikely(skb_orphan_frags_rx(skb, GFP_ATOMIC)))
                    return -ENOMEM;
                refcount_inc(&skb->users);
                return pt_prev->func(skb, skb->dev, pt_prev, orig_dev);
            }

            /* register at inet_init() of net/ipv4/af_inet.c */
            dev_add_pack(&ip_packet_type);
            static struct packet_type   ip_packet_type __read_mostly = {
                .type = cpu_to_be16(ETH_P_IP),
                .func = ip_rcv,
            };
            ```

    - network layer (L3) to transport layer (L4)

        ```
        ip_rcv() at net/ipv4/ip_input.c (Main IP Receive routine)
            + NF_HOOK(..., NF_INET_PRE_ROUTING)
                -> ip_rcv_finish()
                    + ip_route_input_noref()
                        + ip_route_input_rcu()
                            + ip_route_input_slow()
                                + ip_mkroute_input()
                                    + __mkroute_input()
                                        + rt_dst_alloc() at net/ipv4/route.c // routine table
                                            [dst.output = ip_output]
                                        + [dst.input = ip_forward]
                            + rt_dst_alloc()
                                [dst.input  = ip_local_deliver]
                    + dst_input()
                        |
                +-------+
                |
                v
            skb_dst(skb)->input(skb) // skb->dst->input()
            ps. skb->dst->input 在 ip_route_input_noref() 中完成了賦值

        ```

        1. `ip_route_input_noref()`
        1. `ip_forward()`

            ```c
            /* 單播轉發處理, 負責處理轉發相關的所有動作 */
            ip_forward() at net/ipv4/ip_forward.c
                +  NF_HOOK(..., NF_INET_FORWARD)
                    -> ip_forward_finish() //
                        + dst_output
                            |
                +-----------+
                |
                v
           + ip_output()
            ```

        1. `ip_local_deliver()`

            ```
            ip_local_deliver() at net/ipv4/ip_input.c
                + NF_HOOK(..., NF_INET_LOCAL_IN)
                    -> ip_local_deliver_finish()
                            |
                +-----------+
                |
                v
            ret = ipprot->handler(skb);

            /* transport layer (L4) protocol */
            static const struct net_protocol tcp_protocol = {
                .handler =	tcp_v4_rcv, /*TCP*/
            };

            static const struct net_protocol udp_protocol = {
                .handler =	udp_rcv, /*UDP*/
            };

            static const struct net_protocol icmp_protocol = {
                .handler =	icmp_rcv, /*ICMP*/
            };

            static const struct net_protocol igmp_protocol = {
                .handler =	igmp_rcv, /*IGMP*/
            };
            ```

        1. `ip_local_deliver_finish()`

            ```c
            static int ip_local_deliver_finish(struct net *net, struct sock *sk, struct sk_buff *skb)
            {
                ...
                resubmit:
                    /* 如果是RAW-IP報文, 送往 RAW-IP 對應的處理??? */
                    raw = raw_local_deliver(skb, protocol);

                    /* IP層上的 ipprot 負責管理所有的傳輸協議 */
                    ipprot = rcu_dereference(inet_protos[protocol]);
                    if (ipprot) {
                        int ret;

                        if (!ipprot->no_policy) {
                            if (!xfrm4_policy_check(NULL, XFRM_POLICY_IN, skb)) {
                                kfree_skb(skb);
                                goto out;
                            }
                            nf_reset(skb);
                        }
                        ret = ipprot->handler(skb);
                        if (ret < 0) {
                            protocol = -ret;
                            goto resubmit;
                        }
                        __IP_INC_STATS(net, IPSTATS_MIB_INDELIVERS);
                    } else {
                        if (!raw) {
                            if (xfrm4_policy_check(NULL, XFRM_POLICY_IN, skb)) {
                                __IP_INC_STATS(net, IPSTATS_MIB_INUNKNOWNPROTOS);
                                /**
                                 * 是RAW-IP報文,會在RAW-IP處理例程???
                                 * 就丟棄, 並向對端發送 ICMP_DEST_UNREACH, ICMP_PROT_UNREACH
                                 */
                                icmp_send(skb, ICMP_DEST_UNREACH,
                                      ICMP_PROT_UNREACH, 0);
                            }
                            kfree_skb(skb);
                        } else {
                            __IP_INC_STATS(net, IPSTATS_MIB_INDELIVERS);
                            consume_skb(skb);
                        }
                    }
                }
                ...
            }
            ```
## BSD socket API

+ `socket()`
    > create network handle

    ```c
    // linux at net/socket.c
    SYSCALL_DEFINE3(socket, int, family, int, type, int, protocol)
    {
        int retval;
        struct socket *sock;
        int flags;

        flags = type & ~SOCK_TYPE_MASK;
        if (flags & ~(SOCK_CLOEXEC | SOCK_NONBLOCK))
            return -EINVAL;
        type &= SOCK_TYPE_MASK;

        if (SOCK_NONBLOCK != O_NONBLOCK && (flags & SOCK_NONBLOCK))
            flags = (flags & ~SOCK_NONBLOCK) | O_NONBLOCK;

        retval = sock_create(family, type, protocol, &sock);
        if (retval < 0)
            goto out;

        /**
         *  將 socket handle 掛上 socket_file_ops, 並封裝成 fd
         */
        retval = sock_map_fd(sock, flags & (O_CLOEXEC | O_NONBLOCK));
        if (retval < 0)
            goto out_release;

    out:
        /* It may be already another descriptor 8) Not kernel problem. */
        return retval;

    out_release:
        sock_release(sock);
        return retval;
    }
    ```

    - `socket_file_ops`
        > 標準 file description

        ```c
        // linux at net/socket.c
        static const struct file_operations     socket_file_ops = {
            owner =         THIS_MODULE,
            llseek =        no_llseek,
            read_iter =     sock_read_iter,
            write_iter =    sock_write_iter,
            poll =          sock_poll,
            unlocked_ioctl = sock_ioctl,
        #ifdef CONFIG_COMPAT
            compat_ioctl =  compat_sock_ioctl,
        #endif
            mmap =          sock_mmap,
            release =       sock_close,
            fasync =        sock_fasync,
            sendpage =      sock_sendpage,
            splice_write =  generic_splice_sendpage,
            splice_read =   sock_splice_read,
        };
        ```

    - sock create

        ```c
        // linux at net/socket.c
        int sock_create(int family, int type, int protocol, struct socket **res)
        {
            return __sock_create(current->nsproxy->net_ns, family, type, protocol, res, 0);
        }

        int __sock_create(struct net *net, int family, int type, int protocol,
                     struct socket **res, int kern)
        {
            ...

            /* Compatibility.

               This uglymoron is moved from INET layer to here to avoid
               deadlock in module load.
             */
            if (family == PF_INET && type == SOCK_PACKET) {
                pr_info_once("%s uses obsolete (PF_INET,SOCK_PACKET)\n",
                         current->comm);
                /**
                 *  為了向後相容, 強制修改地址族為 PF_PACKET
                 */
                family = PF_PACKET;
            }

            /**
             *  SELinux相關的安全檢查
             */
            err = security_socket_create(family, type, protocol, kern);
            if (err)
                return err;

            ...

            /**
             *  從系統 global array 'net_families' 中,
             *  獲取指定協議族定義的 struct net_proto_family 結構,
             *  每個協議族在初始化過程中, 都會向系統註冊一個這樣的結構
             *  IPv4 在 inet_init() 中完成註冊
             */
            rcu_read_lock();
            pf = rcu_dereference(net_families[family]);
            err = -EAFNOSUPPORT;
            if (!pf)
                goto out_release;

            /*
             * We will call the ->create function, that possibly is in a loadable
             * module, so we have to bump that loadable module refcnt first.
             */
            if (!try_module_get(pf->owner))
                goto out_release;

            /* Now protected by module ref count */
            rcu_read_unlock();

            /**
             *  呼叫協議族提供的 create() method 完成協議族相關的套接字建立工作,
             *  對於AF_INET, 該函式為 inet_create()
             */
            err = pf->create(net, sock, protocol, kern);
            if (err < 0)
                goto out_module_put;

            ...
        }
        ```

+ `bind()`
    > 為 socket handle 綁定本機 IP 地址和一個沒被佔用的 port number

    ```c
    // linux at net/socket.c
    SYSCALL_DEFINE3(bind, int, fd, struct sockaddr __user *, umyaddr, int, addrlen)
    {
        struct socket *sock;
        struct sockaddr_storage address;
        int err, fput_needed;

        sock = sockfd_lookup_light(fd, &err, &fput_needed);
        if (sock) {
            err = move_addr_to_kernel(umyaddr, addrlen, &address);
            if (err >= 0) {
                err = security_socket_bind(sock,
                               (struct sockaddr *)&address,
                               addrlen);
                if (!err)
                    err = sock->ops->bind(sock,
                                  (struct sockaddr *)
                                  &address, addrlen);
            }
            fput_light(sock->file, fput_needed);
        }
        return err;
    }
    ```

    - `port number` 的目的是為了實現複用(Multiplexing), 屬於 TCP/UDP layer (L4)
        > 用來區分不同進程設置的標識.
        這些進程都使用 network layer (IP layer, L3) 收發封包(復用),
        port number 就是用來確定正在發送/收到的封包屬於哪個進程.


+ `listen()`
    > server side. 用來等待 client 的連接

    ```
    // linux at net/socket.c
    SYSCALL_DEFINE2(listen, int, fd, int, backlog)
    {
        struct socket *sock;
        int err, fput_needed;
        int somaxconn;

        sock = sockfd_lookup_light(fd, &err, &fput_needed);
        if (sock) {
            somaxconn = sock_net(sock->sk)->core.sysctl_somaxconn;
            if ((unsigned int)backlog > somaxconn)
                backlog = somaxconn;

            err = security_socket_listen(sock, backlog);
            if (!err)
                err = sock->ops->listen(sock, backlog);

            fput_light(sock->file, fput_needed);
        }
        return err;
    }
    ```

+ `connect()`
    > client side. 用來請求與指定的 server (IP and port number)連接

    ```
    // linux at net/socket.c
    SYSCALL_DEFINE3(connect, int, fd, struct sockaddr __user *, uservaddr,
            int, addrlen)
    {
        struct socket *sock;
        struct sockaddr_storage address;
        int err, fput_needed;

        sock = sockfd_lookup_light(fd, &err, &fput_needed);
        if (!sock)
            goto out;
        err = move_addr_to_kernel(uservaddr, addrlen, &address);
        if (err < 0)
            goto out_put;

        err =
            security_socket_connect(sock, (struct sockaddr *)&address, addrlen);
        if (err)
            goto out_put;

        err = sock->ops->connect(sock, (struct sockaddr *)&address, addrlen,
                     sock->file->f_flags);
    out_put:
        fput_light(sock->file, fput_needed);
    out:
        return err;
    }
    ```

+ `accept()`
    > server side. 獲得 client 的 IP 和 port number 信息.
    接受 client 連接請求, 並生成一個新的 socket handle
    >> 一個 client 連線進來, 就會產生一個獨立的 socket handle

    ```c
    SYSCALL_DEFINE3(accept, int, fd, struct sockaddr __user *, upeer_sockaddr,
            int __user *, upeer_addrlen)
    ```

+ `recv()/send()`
    > 收發封包

    ```c
    // linux at net/socket.c
    SYSCALL_DEFINE4(send, int, fd, void __user *, buff, size_t, len,
            unsigned int, flags)
    SYSCALL_DEFINE4(recv, int, fd, void __user *, ubuf, size_t, size,
            unsigned int, flags)
    ```

+ `close()`
    > 關閉 socket handle, 並釋放資源
    > + socket handle of client incoming
    >> 僅僅關閉 client 連線, server 持續運作
    > + socket handle of a server
    >> 關閉 server 運作


# netfilter
> netfilter 是 kernel 的防火牆框架, 該框架可實現:
> + 數據包過濾
> + 數據包處理
> + 地址偽裝
> + 透明代理
> + 動態網絡地址轉換(Network Address Translation, NAT),
> + 以及基於用戶及媒體訪問控制(Media Access Control, MAC)地址的過濾和基於狀態的過濾, 包速率限制等

+ [Netfilter 之 五個鉤子點](http://www.linuxtcpipstack.com/685.html)
+ [第十一章 Linux包過濾防火牆-netfilter--基於Linux3.10](https://blog.csdn.net/shichaog/article/details/44629715)



# MISC

+ OSI vs TCP/IP Model

    ```
            OSI                   TCP/IP
        Application  --+
            |          |
            v          | ---->  Application
        Presentation   |             |
            |          |             |
            v          |             |
         Session     --+             |
            |                        |
            v                        v
         Transport    ---->      Transport (TCP/UDP, L4)
            |                        |
            v                        v
         Network      ---->      Internet  (IP, L3)
            |                        |
            v                        v
        Data link     ---->      Data link (L2)
          (MAC)                    (MAC)
            |                        |
            v                        v
         Physical     ---->      Physical (L1)

    ```

    - Transport layer (只看 IP address)
        > QoS (Quality of Service) maintain
        > + control the reliability of a link
        through `flow control`, `error control`, and `segmentation` or `de-segmentation`

    - Network(Internet) layer (只看 IP address)
        > IP layer should handle
        > + Routing protocols
        > + Multicast group management
        >> IGMP (用來管理多播資料)
        > + Network-layer address assignment.
        > + ICMP (Internet Control Message Protocol) handle
        >> 用來傳送關於 IP 傳送的診斷資訊,
        `ping` 則是用 ICMP 的'Echo request(8)'和 'Echo reply(0)' 訊息來實現的.

    - Data link layer (只看 MAC address)
        > 可細分成兩層 LLC 和 MAC

        1. LLC (Logical Link Control)
        1. MAC (Media Access Control)
            > 使用 MAC address 定址 (MAC address 是唯一的)
            > + 碰撞處理 (CSMA/CD)

            >> 早期網路發展時以 MAC 判別個網路介面之位置,
            但後來網際網路發展後, 才有 IP 的制定與使用

    - Physical layer
        > + modulation and demodulation
        > + error correlation
        > + Analog and digital converter

# reference


+ [NAPI機制分析](http://abcdxyzk.github.io/blog/2015/08/27/kernel-net-napi/)
+ [NAPI(New API)的一些淺見](https://www.jianshu.com/p/6292b3f4c5c0)
+ [Linux協議棧--IPv4協議的註冊](http://cxd2014.github.io/2017/09/02/inet-register/)
    > htag: network
+ [內核收發包分析(二)----inet_init/arp_init函數](https://www.twblogs.net/a/5b82282e2b717737e032ba5d)
+ [LINUX 套接字文件系統(sockfs)分析之二 相關結構體分析](https://kknews.cc/zh-tw/code/y5ql82j.html)
+ [LINUX VFS分析之SOCKFS分析一(ockfs註冊及相關結構體說明)](https://daydaynews.cc/zh-hant/technology/165624.html)
+ [Linux協議棧--NAPI機制](http://cxd2014.github.io/2017/10/15/linux-napi/)

+ [***(譯) Linux 網絡棧監控和調優:接收數據(2016)](http://arthurchiao.art/blog/tuning-stack-rx-zh/)
+ [***(譯) Linux 網絡棧監控和調優:發送數據(2017)](http://arthurchiao.art/blog/tuning-stack-tx-zh/)
+ [學習Linux-4.12內核網路協議棧(2.4)——接口層數據包的發送](https://www.twblogs.net/a/5b872d9d2b71775d1cd66bf4)

+ [***Linux網絡協議棧--IP](https://blog.csdn.net/wearenoth/article/details/7819925)


+ [sk_buff數據結構圖](https://blog.csdn.net/aaa6695798/article/details/4878461)
+ [sk_buff 詳解(一)](https://blog.csdn.net/farmwang/article/details/54234176)



+ [shichaog linux 3.10-網絡](https://blog.csdn.net/shichaog/category_2433909.html)
+ [Linux內核二層數據包接收流程](https://blog.csdn.net/eric_liufeng/article/details/10286593)

+ [第十一章 Linux包過濾防火牆-netfilter--基於Linux3.10](https://blog.csdn.net/shichaog/article/details/44629715)
+ [網卡適配器收發數據幀流程](https://www.iambigboss.top/post/54107_1_1.html)
+ [Linux內核網絡數據包處理流程](https://www.cnblogs.com/muahao/p/10861771.html)
+ [網卡收包流程](https://codertw.com/%E7%A8%8B%E5%BC%8F%E8%AA%9E%E8%A8%80/697653/)
+ [NAPI 之(三)——技術在 Linux 網絡驅動上的應用和完善](https://www.itdaan.com/tw/fb05ad962549e1d9e0da79f648296af1)
+ [Linux kernel 之 socket 創建過程分析](https://www.cnblogs.com/chenfulin5/p/6927040.html)
+ [從socket應用到網卡驅動：Linux網絡子系統分析概述](https://freemandealer.github.io/2016/03/08/tcp-ip-internal/)

## lwip

+ [lwIP TCP/IP 協議棧筆記之十九:JPerf 工具測試網速](https://www.twblogs.net/a/5d8ca92bbd9eee541c34c03e)
+ [Lwip之IP/MAC地址衝突檢測](https://blog.csdn.net/tianjueyiyi/article/details/51097447)
+ [TCP/IP協議棧之LwIP(三)-網際尋址與路由(IPv4 + ARP + IPv6)](https://blog.csdn.net/m0_37621078/article/details/94646591)
