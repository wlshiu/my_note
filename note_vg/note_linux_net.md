linux network sub-system
---

# Definitions

+ NIC (Network Interface Controller)
    > 網路卡

+ `PRE_CPU` type
    > 每個 Core 都各自存一份, 當其中一個 Core 更動時,
    會自動同步到其他 Cores 的那一份


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


## Pros

NAPI 適合處理高速率數據包的處理, 而帶來的好處如下

+ 中斷緩和 (Interrupt mitigation)
    > 由上面的例子可以看到, 在高流量下, 網卡產生的中斷可能達到每秒幾千次,
    而如果每次中斷都需要系統來處理, 是一個很大的壓力,
    而 NAPI 使用輪詢時是禁止了網卡的接收中斷的,
    這樣會減小系統處理中斷的壓力.

+ 數據包節流 (Packet throttling)
    > NAPI 之前的 Linux NIC driver 總在接收到數據包之後產生一個 IRQ,
    接著在 ISR 裡將這個 skb 加入本地的 `softnet`, 然後觸發本地 `NET_RX_SOFTIRQ` 軟中斷後續處理.
    如果包速過高, 因為 IRQ 的優先級高於 SoftIRQ, 導致系統的大部分資源都在響應中斷,
    但 softnet 的隊列大小有限, 接收到的超額數據包也只能丟掉, 所以這時這個模型是在用寶貴的系統資源做無用功.
    而 NAPI 則在這樣的情況下, 直接把 packets 丟掉, 不會繼續將需要丟掉的 packets 扔給內核去處理,
    這樣, 網卡將需要丟掉的 packets 儘早丟掉, 內核將不需要處理要丟掉的 packets, 這樣也減少了內核的壓力.


## API

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





# reference

+ [NAPI機制分析](http://abcdxyzk.github.io/blog/2015/08/27/kernel-net-napi/)
+ [NAPI(New API)的一些淺見](https://www.jianshu.com/p/6292b3f4c5c0)


+ [Linux內核網絡數據包處理流程](https://www.cnblogs.com/muahao/p/10861771.html)
+ [網卡收包流程](https://codertw.com/%E7%A8%8B%E5%BC%8F%E8%AA%9E%E8%A8%80/697653/)
+ [NAPI 之（三）——技術在 Linux 網絡驅動上的應用和完善](https://www.itdaan.com/tw/fb05ad962549e1d9e0da79f648296af1)
