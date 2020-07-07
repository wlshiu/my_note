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

主要操作會在 IP layer (L3)


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

+ send

```
// linux at net/socket.c
sock_sendmsg()
    + __sock_sendmsg()
        + struct socket *sock;
        + sock->ops->sendmsg() // 這個 ops 是 struct socket 結構體中的 struct proto_ops
            + inet_sendmsg
                + struct sock *sk = sock->sk;
                + sk->sk_prot->sendmsg() // 這個 ops 是 struct sock 結構體中的 struct proto
                    e.g. tcp_sendmsg()
```

+ recv

```
// linux at net/socket.c
sock_recvmsg()
    + __sock_recvmsg()
        + struct socket *sock;
        + sock->ops->recvmsg() // 這個 ops 是 struct socket 結構體中的 struct proto_ops
            + sock_common_recvmsg()
                + struct sock *sk = sock->sk;
                + sk->sk_prot->recvmsg() //這個 ops 是 struct sock 結構體中的 struct proto
                    e.g. tcp_recvmsg()
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



+ [(譯) Linux 網絡棧監控和調優:發送數據(2017)](http://arthurchiao.art/blog/tuning-stack-tx-zh/)
+ [網卡適配器收發數據幀流程](https://www.iambigboss.top/post/54107_1_1.html)
+ [Linux內核網絡數據包處理流程](https://www.cnblogs.com/muahao/p/10861771.html)
+ [網卡收包流程](https://codertw.com/%E7%A8%8B%E5%BC%8F%E8%AA%9E%E8%A8%80/697653/)
+ [NAPI 之(三)——技術在 Linux 網絡驅動上的應用和完善](https://www.itdaan.com/tw/fb05ad962549e1d9e0da79f648296af1)
+ [Linux kernel 之 socket 創建過程分析](https://www.cnblogs.com/chenfulin5/p/6927040.html)
+ [從socket應用到網卡驅動：Linux網絡子系統分析概述](https://freemandealer.github.io/2016/03/08/tcp-ip-internal/)
