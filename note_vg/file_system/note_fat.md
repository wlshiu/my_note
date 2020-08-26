FAT (File Allocation Table) file system
---

# definition

+ `MBR` in FAT file system
    > Master Boot Record

+ `PBR` in FAT file system
    > Private Boot Record or Boot Sector

+ sector (扇區)
    > physical 最小單位, 一般 default 是 `512 bytes`

+ cluster (簇)
    > file system 存取的最小單元, 是 Sectors 的集合 (power of 2)
    >> 當 cluster 是 `4KB` 時, 要存一個 `10KB` 的文件,
    那麼它需要佔用三個簇, 實際佔用空間大小為 `12KB`

+ FAT table
    > the mapping table between file and clusters

# Concpt

FAT physical structure

```
+---------------------------------------+
|   MBR (1 sector)                      |
|   紀錄 partition area,                |
|   e.g. partition 1 from sector n ~ m, |
|        partition 2 from sector x ~ y, |
|           ...                         |
+---------------------------------------+
|   boot sector (1 sector)              |
|   紀錄 FAT 基本 physical 資訊         |
|   e.g. cluster size,                  |
|        total sectors,                 |
|        ...                            |
+---------------------------------------+
|   FSINFO (1 sector)                   |
|   紀錄 extra information              |
|   e.g. Free cluster count,            |
|        Next free cluster              |
|                                       |
+---------------------------------------+
|   reserved sectors                    |
+---------------------------------------+
|   FAT table (FAT32: 32-th sectors)    |
|   紀錄檔案所對應的 cluster index      |
+---------------------------------------+
|   Data area                           |
|                                       |
+---------------------------------------+
```

+ boot sector

    ```
    // uboot define
    typedef struct boot_sector {
        __u8    ignored[3];         /* Bootstrap code */
        char    system_id[8];       /* Name of fs vendor */
        __u8    sector_size[2];     /* Bytes of a sector */
        __u8    cluster_size;       /* Sectors of a cluster */
        __u16   reserved;           /* Number of reserved sectors */
        __u8    fats;               /* Number of FAT table */
        __u8    dir_entries[2];     /* Number of root directory entries, FAT16 only */
        __u8    sectors[2];         /* Number of sectors, FAT16 use */
        __u8    media;              /* Media type */
        __u16   fat_length;         /* Sectors/FAT */
        __u16   secs_track;         /* Sectors/track */
        __u16   heads;              /* Number of heads */
        __u32   hidden;             /* Number of hidden sectors */
        __u32   total_sect;         /* Number of sectors (if sectors == 0) */

        /* FAT32 only */
        __u32   fat32_length;       /* Sectors of a FAT table */
        __u16   flags;              /* Bit 8: fat mirroring, low 4: active fat */
        __u8    version[2];         /* Filesystem version */
        __u32   root_cluster;       /* First cluster in root directory */
        __u16   info_sector;        /* Filesystem info sector */
        __u16   backup_boot;        /* Backup boot sector */
        __u16   reserved2[6];       /* Unused */
    } boot_sector;
    ```

    - `fat32_length`
        > Sectors of a FAT table

        ```
        total_clusters = total_sectors / cluster_size;

        # 一個 sector 可以記錄 128 個 fat_table_item, 1 個 item 需要 4bytes
        fat_table_sectors = total_clusters / (sector_size / 4);
        ```

    - `media`
        > Media type

        ```
        For RAMdisks:
        fa

        For hard disks:
        Value  DOS version
        f8     2.0
        ```

    - `cluster_size`
        > Sectors of a cluster

        1. FAT16

|Drive     | size Secs/cluster |  Cluster size                      |
| :-       | :-                | :-                                 |
| <  16 MB |     8             |     4 KiB                          |
| < 128 MB |     4             |     2 KiB                          |
| < 256 MB |     8             |     4 KiB                          |
| < 512 MB |    16             |     8 KiB                          |
| <   1 GB |    32             |    16 KiB                          |
| <   2 GB |    64             |    32 KiB                          |
| <   4 GB |   128             |    64 KiB   (Windows NT only)      |
| <   8 GB |   256             |   128 KiB   (Windows NT 4.0 only)  |
| <  16 GB |   512             |   256 KiB   (Windows NT 4.0 only)  |

        1. FAT32

| Drive size | Secs/cluster | Cluster size |
| :-         | :-           | :-           |
|  < 260 MB  |    1         | 512 bytes    |
|  <   8 GB  |    8         |   4 KiB      |
|  <  16 GB  |   16         |   8 KiB      |
|  <  32 GB  |   32         |  16 KiB      |
|  <   2 TB  |   64         |  32 KiB      |


+ FSINFO

```
#pragma pack(1)
typedef struct fsinfo {
    uint32_t        FSI_LeadSig;        /* Lead Signature, 0x41615252 */

    uint8_t         Reserved[480];

    uint32_t        FSI_StrucSig;       /* Struct Signature, 0x61417272  */
    uint32_t        FSI_Free_Count;     /* Free Cluster Count */
    uint32_t        FSI_Nxt_Free;       /* Next Free Cluster */
    uint8_t         Reserved_1[12];
    uint16_t        Signature;          /* Trail Signature, 0xaa55 */
} fsinfo_t;
#pragma pack
```

+ FAT table (文件分配表)
    > 當我們存儲 10KB 的文件時, 需要使用三個簇, 但是一定連續的三個簇嗎?
    並非一定是連續的, 那麼如何知道是使用了哪三個族呢, 就需要我們**文件分配表**來記錄了,
    第一個簇的地址, 下一個簇是哪個, 哪個是最後的結束簇

    > FAT32 中每個 cluster address 是 `32bites`,
    FAT table 中的所有位置都以 `32bits` 為單位進行劃分,
    並對所有劃分後的位置由 `0` 開始地址編號.
    >> + **0號地址**與 **1號地址**被系統保留並存儲特殊標誌內容.
    >> + 從 **2號地址**開始, 每個地址對應於數據區的簇號,
    FAT table 中的地址編號與數據區中的 cluster number 相同

    - fat table 中的 item-0 跟 item-1 不與任何簇對應
        > + item-0 值總是 `0x0FFFFFF8`
        > + item-1 能被用於記錄髒標誌, 以說明文件系統沒有被正常卸載或者磁盤表面存在錯誤.
        不過這個值並不重要. 正常情況下 item-1 的值為 `0xFFFFFFFF` 或 `0x0FFFFFFF`

    - fat table 中未被使用 item 的預設值必須為 `0`
    - fat table 中某個 cluster 存在壞扇區, 則整個簇會用 `0xFFFFFF7`標記為壞簇
    - fat table 中文件結束的 item 值為 `0x0FFFFFFF`

        ```
        uint32_t    fat_table[]; // fat_table[cluster_index]

        /**
         *  cluster_index >= 2, one cluster = 8 * sector
         *  sector_index = start_sector_index + ((cluster_index - 2) * 8)
         */

        // default
        fat_table[0] = 0x0FFFFFF8;
        fat_table[1] = 0xFFFFFFFF;
        fat_table[2] = 0x0FFFFFFF;  // 根目錄 Root directory 所在簇, 開始 sector number

        // by application
        fat_table[3] = 0x0FFFFFFF;  // 某個檔案或目錄, 佔了一個 cluster, 其資料放在 cluster-3
        fat_table[4] = 0x0FFFFFFF;  // 某個檔案或目錄, 佔了一個 cluster, 其資料放在 cluster-4
        fat_table[5] = 0x0FFFFFFF;  // 某個檔案或目錄, 佔了一個 cluster, 其資料放在 cluster-5

        // 某個檔案占用 cluster-6 ~ cluster-8
        fat_table[6] = 7;           // 目前在 cluster-6, 且資料延續到 cluster-7
        fat_table[7] = 8;           // 資料延續到 cluster-8
        fat_table[8] = 0x0FFFFFFF;  // 資料到此 cluster 結束

        fat_table[9] = 0;           // 未使用
        fat_table[10] = 0;          // 未使用

        fat_table[11] = 0xFFFFFF7;  // bad cluster (壞)
        ```

# FAT 格式文件系統相關操作命令

+ `fatinfo`
    > 用來查詢mmc設備中指定分區的文件系統信息.
    >> 該命令的用法中, `<interface>` 表示要查看的接口, 例如 mmc,
    `[<dev[:part]>]`中的 dev 表示要查詢的設備號, part 則表示要查詢的分區

    ```
    => fatinfo
        fatinfo - print information about filesystem

        Usage:
        fatinfo <interface> [<dev[:part]>]
            - print information about filesystem from 'dev' on 'interface'

    => mmc list
    FSL_SDHC: 0 (SD)
    FSL_SDHC: 1
    => fatinfo mmc 0:1      # 查看 sd 卡中 partition 1 的文件系統信息
    ```

+ `fatwrite`
    > save memory data to device with Fat file system

    ```
    usage: fatwrite <interface> <dev:[partition]> <mem addr> <save name> <length>
    e.g.
    => fatwrite mmc 0:1 0x700000 kernel.img 0x2792f4

    表示從地址 0x700000 dump 0x2792f4 bytes 大小的內存保存到 mmc0 的第一分區命名為 kernel.img
    ```

+ `fatload`
    > load a file to memory with Fat file system

    ```
    usage: fatload <interface> <dev:[partition]> <mem addr> <file name>
    e.g.
    => fatload mmc 0:1 0x40008000 uImage

    從第 0 個存儲設備的第 1 個分區的根目錄讀出 uImage 文件到內存地址 0x40008000
    ```

# reference

+ [FAT32文件系統格式詳解(圖文針對具體文件存儲,分析fat32 SD卡)](https://blog.csdn.net/csdn66_2016/article/details/88066637)
+ [Uboot常用命令使用](https://www.cnblogs.com/Cqlismy/p/12214305.html)