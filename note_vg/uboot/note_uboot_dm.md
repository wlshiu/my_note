uboot Device Module [Back](note_uboot_quick_start.md)
---

uboot Device Module (DM) 為 driver 的定義和 interface 提供了統一的方法.

DM 提高了驅動之間的兼容性以及訪問的一致性, 是一種類似 kernel device driver 的機制

# Concept

## Architecture

```
         app
          |
        uclass ------- uclass_driver
          |
    +-----+-----+
    |           |
udevice       udevice
    |           |
 driver       driver
    |           |
  H/w          H/w
```

+ Definitions
    - uclass (u-boot class)
        > 為那些使用相同接口的設備提供了統一的接口.
        e.g. I2C uclass 下可能有 10 個 I2C ports, 4個使用 A chip, 另外 6 個使用 B chip

    - uclass_driver
        > 對應 uclass 的驅動程序.
        主要提供 uclass 操作時, 如綁定 udevice 時的一些操作
        >> uclass_driver 會和 uclass 綁定

    - udevice (u-boot device)
        > 簡單說就是抽象具體的設備, 可以理解為 kernel 中的 device.
        >> udevice 會和 uclass 綁定;
        udevice 找到對應的 uclass 的方式, 主要是通過 udevice 對應 driver 的 id,
        和 uclass 對應的 uclass_driver 的 id 是否匹配

    - driver
        > udevice 的驅動, 可以理解為 kernel 中的 device_driver.
        和底層 H/w 設備通信, 並且為設備提供相對應的 method instances
        >> driver 會和 udevice 綁定

+ flow
    > 在 `initf_dm()` 解析 fdt 中的設備的時候, 會動態生成 `udevice`.
    然後找到 udevice 對應的driver, 通過 driver 中的 uclass id 得到 uclass_driver id.
    從 uclass list 中查找對應的 uclass 是否已經生成, 沒有生成的話則動態生成 uclass


    - App layer 直接使用 uclass 的 interface



# Analyze code

## uclass id

每一種 uclass 都有自己的ID號, 定義在其對應的 uclass_driver 中.
其附屬的 udevice 的 driver 中的 uclass id 必須與其一致.

```
// At include/dm/uclass-id.h

enum uclass_id {
    /* These are used internally by driver model */
    UCLASS_ROOT = 0,
    UCLASS_DEMO,
    UCLASS_CLK,         /* Clock source, e.g. used by peripherals */
    UCLASS_PINCTRL,     /* Pinctrl (pin muxing/configuration) device */
    UCLASS_SERIAL,      /* Serial UART */
    ...
}
```

## uclass

+ structure
    > At `include/dm/uclass.h`

    ```c
    struct uclass {
        void *priv;                     // uclass 的私有數據指針
        struct uclass_driver *uc_drv;   // 對應的 uclass driver
        struct list_head dev_head;      // 鏈表頭, 連接所屬的所有 udevice
        struct list_head sibling_node;  // 鏈表節點, 用於把 uclass 連接到 uclass_root list 上
    };
    ```

+ 所有生成的 uclass 都會被掛載 `gd->uclass_root` list,
    並藉由 `uclass_find()`, 來直接遍歷 `gd->uclass_root` list


## uclass_driver

+ structure
    > At `include/dm/uclass.h`

    ```c
    struct uclass_driver {
        const char *name;   // 該 uclass_driver 的命令
        enum uclass_id id;  // 對應的 uclass id

        /* 以下函數指針主要是調用時機的區別 */
        int (*post_bind)(struct udevice *dev);  // 在 udevice 被綁定到該 uclass 之後調用
        int (*pre_unbind)(struct udevice *dev); // 在 udevice 被解綁出該 uclass 之前調用
        int (*pre_probe)(struct udevice *dev);  // 在該 uclass 的一個 udevice 進行 probe 之前調用
        int (*post_probe)(struct udevice *dev); // 在該 uclass 的一個 udevice 進行 probe 之後調用
        int (*pre_remove)(struct udevice *dev); // 在該 uclass 的一個 udevice 進行 remove 之前調用
        int (*child_post_bind)(struct udevice *dev); // 在該 uclass 的一個 udevice 的一個子設備被綁定到該 udevice 之後調用
        int (*child_pre_probe)(struct udevice *dev); // 在該 uclass 的一個 udevice 的一個子設備進行 probe 之前調用
        int (*init)(struct uclass *class);      // 安裝該 uclass 的時候調用
        int (*destroy)(struct uclass *class);   // 銷毀該 uclass 的時候調用
        int priv_auto_alloc_size;               // 需要為對應的 uclass 分配多少私有數據
        int per_device_auto_alloc_size;
        int per_device_platdata_auto_alloc_size;
        int per_child_auto_alloc_size;
        int per_child_platdata_auto_alloc_size;
        const void *ops;        // 操作集合
        uint32_t flags;         // 標識為
    };
    ```

+ 如何宣告 uclass_driver

    ```c
    #define ll_entry_declare(_type, _name, _list)               \
        _type _u_boot_list_2_##_list##_2_##_name __aligned(4)   \
                __attribute__((unused,                          \
                section(".u_boot_list_2_"#_list"_2_"#_name)))

    #define UCLASS_DRIVER(__name)                       \
        ll_entry_declare(struct uclass_driver, __name, uclass)


    UCLASS_DRIVER(serial) = {
        .id             = UCLASS_SERIAL,
        .name           = "serial",
        .flags          = DM_UC_FLAG_SEQ_ALIAS,
        .post_probe     = serial_post_probe,
        .pre_remove     = serial_pre_remove,
        .per_device_auto_alloc_size = sizeof(struct serial_dev_priv),
    };
    ```

    - 轉換後

        ```c
        struct uclass_driver  _u_boot_list_2_uclass_2_serial = {
            .id            = UCLASS_SERIAL,   // 設置對應的 uclass id
            .name          = "serial",
            .flags         = DM_UC_FLAG_SEQ_ALIAS,
            .post_probe    = serial_post_probe,
            .pre_remove    = serial_pre_remove,
            .per_device_auto_alloc_size = sizeof(struct serial_dev_priv),
        }
        ```

    - memory address
        > 由 link script 中的 `.u_boot_list : { KEEP(*(SORT(.u_boot_list*))); }` 來決定
        >> 最後所有 uclass driver 結構體以 array 的形式,
        被放在`.u_boot_list_2_uclass_1`和`.u_boot_list_2_uclass_3`的區間中.
        這個 array 列表簡稱 `uclass_driver table`

        ```
        /* u-boot.map */
        .u_boot_list_2_uclass_1     // ll_entry_start(struct uclass_driver, uclass)
        .u_boot_list_2_uclass_2_gpio
                        0x23e368e0  0x48 _u_boot_list_2_uclass_2_gpio // gpio uclass driver
        .u_boot_list_2_uclass_2_root
                        0x23e36928  0x48 _u_boot_list_2_uclass_2_root // root uclass drvier
        .u_boot_list_2_uclass_2_serial
                        0x23e36970  0x48 _u_boot_list_2_uclass_2_serial // serial uclass driver
        ...

        .u_boot_list_2_uclass_3     // ll_entry_end(struct uclass_driver, uclass)
        ```

    - API to get `uclass_driver table`

        ```c
        // 會根據 .u_boot_list_2_uclass_1 的 address 來得到 uclass_driver table 的 start
        struct uclass_driver     *uclass =
            ll_entry_start(struct uclass_driver, uclass);

        // 獲得 uclass_driver table 的 elements number
        const int   n_ents = ll_entry_count(struct uclass_driver, uclass);
        ```
    - API to find the uclass_driver

        ```c
        // 從 uclass_driver table 中獲取 target uclass id 的 uclass_driver
        struct uclass_driver *lists_uclass_lookup(enum uclass_id id);
        ```

## udevice

+ structure
    > At `include/dm/device.h`

    ```c
    struct udevice {
        const struct driver *driver; // 該 udevice 對應的 driver
        const char *name;           // 設備名
        void *platdata;             // 該 udevice 的平台數據
        void *parent_platdata;      // 提供給父設備使用的平台數據
        void *uclass_platdata;      // 提供給所屬 uclass 使用的平台數據
        int of_offset;              // 該 udevice 的 dtb 節點偏移, 代表了 dtb 裡面的這個 node
        ulong driver_data;          // 驅動數據
        struct udevice *parent;     // 父設備
        void *priv;                 // 私有數據的指針
        struct uclass *uclass;      // 所屬 uclass
        void *uclass_priv;          // 提供給所屬 uclass 使用的私有數據指針
        void *parent_priv;          // 提供給其父設備使用的私有數據指針
        struct list_head uclass_node; // 用於連接到其所屬 uclass 的鏈表上
        struct list_head child_head;  // 鏈表頭, 連接其子設備
        struct list_head sibling_node; // 用於連接到其父設備的鏈表上
        uint32_t flags;             // 標識
        int req_seq;
        int seq;
    #ifdef CONFIG_DEVRES
        struct list_head devres_head;
    #endif
    };
    ```

+ 如何定義 udevice
    > 在 dtb 存在的情況下, 由 uboot 解析 dtb 後動態生成

+ 連接點

    - 連接到對應 uclass 中 (uclass->dev_head)
    - 連接到父設備的子設備鏈表中 (udevice->child_head)
        > 最終的根設備是 `gd->dm_root`

+ Get the udevice
    > 從 uclass 中取得 udevice, 遍歷 `uclass->dev_head`, 獲取對應的 udevice


## driver

+ structure
    > At `include/dm/device.h`

    ```c
    struct driver {
        char *name;                         // 驅動名
        enum uclass_id id;                  // 對應的 uclass id
        const struct udevice_id *of_match;  // compatible 字符串的匹配表, 用於和 device tree 裡面的設備節點匹配
        int (*bind)(struct udevice *dev);   // 用於綁定目標設備到該 driver 中
        int (*probe)(struct udevice *dev);  // 用於 probe 目標設備, 激活
        int (*remove)(struct udevice *dev); // 用於 remove 目標設備
        int (*unbind)(struct udevice *dev); // 用於解綁目標設備到該 driver 中
        int (*ofdata_to_platdata)(struct udevice *dev); /* 在 probe 之前, 解析對應 udevice 的 dts 節點,
                                                         * 轉化成 udevice 的平台數據
                                                         */
        int (*child_post_bind)(struct udevice *dev);    // 如果目標設備的一個子設備被綁定之後, 調用
        int (*child_pre_probe)(struct udevice *dev);    // 在目標設備的一個子設備被 probe 之前, 調用
        int (*child_post_remove)(struct udevice *dev);  // 在目標設備的一個子設備被 remove 之後, 調用
        int priv_auto_alloc_size;                   // 需要分配多少空間作為其 udevice 的私有數據
        int platdata_auto_alloc_size;               // 需要分配多少空間作為其 udevice 的平台數據
        int per_child_auto_alloc_size;              // 對於目標設備的每個子設備需要分配多少空間作為父設備的私有數據
        int per_child_platdata_auto_alloc_size;     // 對於目標設備的每個子設備需要分配多少空間作為父設備的平台數據
        const void *ops;                            /* driver-specific operations.
                                                     * 操作集合的指針, 提供給 uclass 使用,
                                                     * 沒有規定操作集的格式, 由具體 uclass 決定
                                                     */
        uint32_t flags;                     // 一些標誌位
    };
    ```

+ 如何宣告 driver

    ```c
    #define ll_entry_declare(_type, _name, _list)               \
        _type _u_boot_list_2_##_list##_2_##_name __aligned(4)   \
                __attribute__((unused,                          \
                section(".u_boot_list_2_"#_list"_2_"#_name)))

    #define U_BOOT_DRIVER(__name)                        \
        ll_entry_declare(struct driver, __name, driver)


    U_BOOT_DRIVER(serial_s5p) = {
        .name     = "serial_s5p",
        .id       = UCLASS_SERIAL,
        .of_match = s5p_serial_ids,
        .ofdata_to_platdata       = s5p_serial_ofdata_to_platdata,
        .platdata_auto_alloc_size = sizeof(struct s5p_serial_platdata),
        .probe    = s5p_serial_probe,
        .ops      = &s5p_serial_ops,
        .flags    = DM_FLAG_PRE_RELOC,
    };
    ```

    - 轉換後

        ```c
        struct driver _u_boot_list_2_driver_2_serial_s5p= {
            .name       = "serial_s5p",
            .id         = UCLASS_SERIAL,
            .of_match   = s5p_serial_ids,
            .ofdata_to_platdata       = s5p_serial_ofdata_to_platdata,
            .platdata_auto_alloc_size = sizeof(struct s5p_serial_platdata),
            .probe      = s5p_serial_probe,
            .ops        = &s5p_serial_ops,
            .flags      = DM_FLAG_PRE_RELOC,
        };
        ```

    - memory address
        > 由 link script 中的 `.u_boot_list : { KEEP(*(SORT(.u_boot_list*))); }` 來決定
        >> 最後所有 driver 結構體以 array 的形式,
        被放在`.u_boot_list_2_driver_1`和`.u_boot_list_2_driver_3`的區間中.
        這個 array 列表簡稱 `driver table`

        ```
        /* u-boot.map */
        .u_boot_list_2_driver_1     // ll_entry_start(struct driver, driver);
        .u_boot_list_2_driver_2_gpio_exynos
                        0x23e36754       0x44 _u_boot_list_2_driver_2_gpio_exynos
        .u_boot_list_2_driver_2_root_driver
                        0x23e36798       0x44 _u_boot_list_2_driver_2_root_driver
        .u_boot_list_2_driver_2_serial_s5p
                        0x23e367dc       0x44 _u_boot_list_2_driver_2_serial_s5p
                        0x23e367dc

        ...
        .u_boot_list_2_driver_3     // ll_entry_end(struct driver, driver);
        ```

    - API to get `driver table`

        ```c
        // 會根據 .u_boot_list_2_driver_1 的段地址來得到 driver table 的地址
        struct driver   *drv =
                ll_entry_start(struct driver, driver);

        // 獲得 driver table 的長度
        const int       n_ents = ll_entry_count(struct driver, driver);
        ```
    - API to find the uclass_driver

        ```c
        // 從 driver  table 中獲取名字為 name 的 driver
        struct driver *lists_driver_lookup_name(const char *name);
        ```

# reference

+ [uboot 驅動模型](https://blog.csdn.net/ooonebook/article/details/53234020)
+ [uboot dm-gpio使用方法以及工作](https://blog.csdn.net/ooonebook/article/details/53340441)
