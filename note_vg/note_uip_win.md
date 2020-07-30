uip協議棧移植到window
---

uip移植到window平台目的是為仿真單片機運行環境, 方便調試和學習, 加快開發.

# 準備工作

+ 下載 [uip 1.0](https://github.com/adamdunkels/uip/tags)

+ 下載 `wpcap sdk`

+ 下載 `wireshark`



# uip協議棧移植

     使用 vs2008 創建控制台工程, 解壓uip代碼. 複製unix文件夾, 重命名為 win.

+ 修改 `clock-arc.c`

    ```c
    clock_time_t
    clock_time(void)
    {
        return GetTickCount();
    }

    // 以上函數是獲取系統運行時間, 單位為 ms.
    ```

+ 修改 `tapdev.c`

    ```c
    //網卡初始化
    void tapdev_init(void)
    {
        EthernetInit();
    }

    //讀取網絡數據
    unsigned int tapdev_read(void)
    {
        return EthernetRead(uip_buf, UIP_BUFSIZE);
    }

    //發送網絡數據
    void tapdev_send(void)
    {
        EthernetSend(uip_buf, uip_len);
    }
    ```

+ 增加 `intetypes.h`

    ```c
    typedef unsigned char   uint8_t;
    typedef unsigned short  uint16_t;
    typedef unsigned long   uint32_t;


    #define IP2DWORD(a,b,c,d)    ((uint32_t)(uint8_t)(d)|(uint32_t)(uint8_t)(c)<<8|(uint32_t)(uint8_t)(b)<<16|(uint32_t)(uint8_t)(a)<<24)
    #define DWORD2IP(val,array)   \
        do{ array[0] = (uint8_t)((val >> 24) & 0x000000FF); \
            array[1] = (uint8_t)((val >> 16) & 0x000000FF); \
            array[2] = (uint8_t)((val >> 8) & 0x000000FF); \
            array[3] = (uint8_t)((val >> 0) & 0x000000FF); \
        }while(0)

    #define ENDIANCHANGE32(A)               ((((uint32_t)(A) & 0xff000000) >> 24) | \
                                            (((uint32_t)(A) & 0x00ff0000) >> 8) | \
                                            (((uint32_t)(A) & 0x0000ff00) << 8) | \
                                            (((uint32_t)(A) & 0x000000ff) << 24))

    #define snprintf    _snprintf
    ```

+ 配置 `uip-conf.h`

    ```c
    #define UIP_CONF_BUFFER_SIZE     640   // wifi環境下DHCP包大於420

    #define UIP_UDP_APPCALL     uip_udp_appcall

    typedef struct httpd_state  uip_tcp_appstate_t;
    typedef struct httpd_state  uip_udp_appstate_t;
    ```

+ 至此已移植完成.


# 收發網絡數據包

+ 使用 uip 協議棧後, 要直接收發以太網包. 這時要用到 `winpcap`.

    ```c
    int EthernetInit()
    {
        if (pcap_findalldevs(&alldevs, errbuf) == -1)
        {
            return -2;
        }

        if ((fp = pcap_open_live(alldevs->name,
                                 65536,   // portion of the packet to capture. It doesn't matter in this case
                                 1,    // promiscuous mode (nonzero means promiscuous)
                                 1000,
                                 errbuf   // error buffer
                                )) == NULL)
        {
            DisplayErrorMsg(errbuf);
            pcap_freealldevs(alldevs);
            alldevs = NULL;
            return -1;
        }
    }

    int EthernetSend(void* buffer, int nSize)
    {
        if(fp == NULL)  return -1;

        if (pcap_sendpacket(fp, (const u_char*)buffer, nSize) != 0)
        {
            pcap_geterr(fp);
            return 0;
        }

        return 1;
    }

    int EthernetRead(char* buffer, int nSize)
    {
        if(fp == NULL)  return -1;
        pcap_loop(fp, 1, packet_handler, NULL);
        return 0;
    }

    void packet_handler(u_char *param, const struct pcap_pkthdr *header, const u_char *pkt_data)
    {
        memcpy(szCapBuffer, pkt_data, bufferLen);
    }

    ```

# 測試

通過DHCP獲取動態IP, 接可以在同一台機器上測試了.

ps. winpcap不能抓自己發給自己的數據包, 需要把本機IP加入路由表, 但加入後, 本地TCP通訊又不正常了.


```c
void uIP_Net_Init(void)
{
    timer_set(&periodic_timer, CLOCK_SECOND / 2);
    timer_set(&arp_timer, CLOCK_SECOND * 10);

    uip_ethaddr.addr[0] = 0x00;
    uip_ethaddr.addr[1] = 0x1B;
    uip_ethaddr.addr[2] = 0x11;
    uip_ethaddr.addr[3] = 0x13;
    uip_ethaddr.addr[4] = 0x86;
    uip_ethaddr.addr[5] = 0xb0;

    tapdev_init();
    uip_init();
    dhcpc_init(&uip_ethaddr, 6);
    dhcpc_request();
}

int UipPro(void)
{
    int i;
    if(1)
    {
        uip_len = tapdev_read();
        if(uip_len > 0)
        {
            if(BUF->type == htons(UIP_ETHTYPE_IP))
            {
                uip_arp_ipin();
                uip_input();
                if(uip_len > 0)
                {
                    uip_arp_out();
                    tapdev_send();
                }
            }
            else if(BUF->type == htons(UIP_ETHTYPE_ARP))
            {
                uip_arp_arpin();
                if(uip_len > 0)
                {
                    tapdev_send();
                }
            }
        }
        else if(timer_expired(&periodic_timer))
        {
            timer_reset(&periodic_timer);
            for(i = 0; i < UIP_CONNS; i++)
            {
                uip_periodic(i);
                if(uip_len > 0)
                {
                    uip_arp_out();
                    tapdev_send();
                }
            }

            #if UIP_UDP
            for(i = 0; i < UIP_UDP_CONNS; i++)
            {
                uip_udp_periodic(i);
                if(uip_len > 0)
                {
                    uip_arp_out();
                    tapdev_send();
                }
            }
            #endif /* UIP_UDP */

            /* Call the ARP timer function every 10 seconds. */
            if(timer_expired(&arp_timer))
            {
                timer_reset(&arp_timer);
                uip_arp_timer();
            }
        }
    }
    return 0;
}

int main(int argc, char* argv[])
{
    uIP_Net_Init();

    while(1)
    {
        UipPro();
    }

    return 0;
}
```

# reference

+ [UIP移植](https://blog.csdn.net/lpdpzc/article/details/8804262)
+


