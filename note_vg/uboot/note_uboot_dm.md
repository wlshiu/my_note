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


# Components of DM

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
    #define UCLASS_DRIVER(__name)                       \
        ll_entry_declare(struct uclass_driver, __name, uclass)

    #define ll_entry_declare(_type, _name, _list)               \
        _type _u_boot_list_2_##_list##_2_##_name __aligned(4)   \
                __attribute__((unused,                          \
                section(".u_boot_list_2_"#_list"_2_"#_name)))

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

+ udevice API

    - `device_bind()`
        > At `drivers/core/device.c`

        ```c
        /* 初始化一個 udevice, 並將其與其 uclass and driver 綁定. */
        int device_bind(struct udevice *parent, const struct driver *drv,
                const char *name, void *platdata, int of_offset,
                struct udevice **devp)
        ```

    - `device_bind_by_name()`
        > At `drivers/core/device.c`

        ```c
        /* 通過 name 獲取 driver 並且調用 device_bind 對 udevice 初始化,
         * 並將其與其 uclass and driver 綁定
         */
        int device_bind_by_name(struct udevice *parent, bool pre_reloc_only,
                    const struct driver_info *info, struct udevice **devp)
        ```
    - `int uclass_bind_device()`
        > At `drivers/core/uclass.c`

        ```c
        /* Connect the device into uclass's list of devices. */
        int uclass_bind_device(struct udevice *dev)
        ```

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
    #define U_BOOT_DRIVER(__name)                        \
        ll_entry_declare(struct driver, __name, driver)

    #define ll_entry_declare(_type, _name, _list)               \
        _type _u_boot_list_2_##_list##_2_##_name __aligned(4)   \
                __attribute__((unused,                          \
                section(".u_boot_list_2_"#_list"_2_"#_name)))

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

## root device

根設備其實是一個虛擬設備, 主要是為 uboot 的其他 devices 提供一個掛載點

相關的定義如下:

```c
// At drivers/core/root.c

static const struct driver_info root_info = {
    .name       = "root_driver",
};

/* This is the root driver - all drivers are children of this */
U_BOOT_DRIVER(root_driver) = {
    .name   = "root_driver",
    .id = UCLASS_ROOT,
};

/* This is the root uclass */
UCLASS_DRIVER(root) = {
    .name   = "root",
    .id = UCLASS_ROOT,
};
```

# DM initial flow

+ DM initialize
    > 創建 root device 的 udevice, 存放在`gd->dm_root`中

+ 解析並產生 udevice 和 uclass

    - 創建 udevice 和 uclass
    - 綁定 udevice 和 uclass
    - 綁定 uclass_driver 和 uclass
    - 綁定 driver 和 udevice
    - 部分 driver 函數的調用

+ `initf_dm()` before relocation

    ```c
    static int initf_dm(void)
    {
    #if defined(CONFIG_DM) && CONFIG_VAL(SYS_MALLOC_F_LEN)
        int ret;

        bootstage_start(BOOTSTATE_ID_ACCUM_DM_F, "dm_f");
        /*
         * 對 DM 進行初始化和設備的解析.
         * 當 dm_init_and_scan 的參數為 true 時,
         * 只會對帶有 "u-boot,dm-pre-reloc" 屬性的節點進行解析
         */
        ret = dm_init_and_scan(true);
        bootstage_accum(BOOTSTATE_ID_ACCUM_DM_F);
        if (ret)
            return ret;
    #endif
    #ifdef CONFIG_TIMER_EARLY
        ret = dm_timer_init();
        if (ret)
            return ret;
    #endif

        return 0;
    }
    ```

+ `initr_dm()` after relocation

    ```c
    static int initr_dm(void)
    {
        int ret;

        /* Save the pre-reloc driver model and start a new one */
        gd->dm_root_f = gd->dm_root;    /* 存儲 relocate 之前的根設備 */
        gd->dm_root = NULL;
    #ifdef CONFIG_TIMER
        gd->timer = NULL;
    #endif
        bootstage_start(BOOTSTATE_ID_ACCUM_DM_R, "dm_r");
        /*
         * 對 DM 進行初始化和設備的解析.
         * 當 dm_init_and_scan 的參數為 false 時,
         * 會對所有節點都進行解析
         */
        ret = dm_init_and_scan(false);
        bootstage_accum(BOOTSTATE_ID_ACCUM_DM_R);
        if (ret)
            return ret;
    #ifdef CONFIG_TIMER_EARLY
        ret = dm_timer_init();
        if (ret)
            return ret;
    #endif

        return 0;
    }
    ```

## `dm_init_and_scan()`

+ source code
    > At `driver/core/root.c`

    ```c
    int dm_init_and_scan(bool pre_reloc_only)
    {
        int ret;

        ret = dm_init(IS_ENABLED(CONFIG_OF_LIVE));  /* DM 的初始化 */
        if (ret) {
            debug("dm_init() failed: %d\n", ret);
            return ret;
        }
        ret = dm_scan_platdata(pre_reloc_only);     /* 從平台設備中解析 udevice 和 uclass */
        if (ret) {
            debug("dm_scan_platdata() failed: %d\n", ret);
            return ret;
        }

        if (CONFIG_IS_ENABLED(OF_CONTROL) && !CONFIG_IS_ENABLED(OF_PLATDATA)) {
            /* 從 dtb 中解析 udevice 和 uclass */
            ret = dm_extended_scan_fdt(gd->fdt_blob, pre_reloc_only);
            if (ret) {
                debug("dm_extended_scan_dt() failed: %d\n", ret);
                return ret;
            }
        }

        ret = dm_scan_other(pre_reloc_only);
        if (ret)
            return ret;

        return 0;
    }
    ```

## `dm_init()`

+ source code
    > At `drivers/core/root.c`
    >> + root device 的 udevice, 存放在`gd->dm_root`中
    >> + root uclass list 則存放在 `gd->uclass_root`

    ```
    /* 宏定義 root device 指標 gd->dm_root */
    #define DM_ROOT_NON_CONST           (((gd_t *)gd)->dm_root)

    /* 宏定義 gd->uclass_root (uclass 的 list) */
    #define DM_UCLASS_ROOT_NON_CONST    (((gd_t *)gd)->uclass_root)

    int dm_init(bool of_live)
    {
        int ret;

        if (gd->dm_root) {
            /* 根設備已經存在, 說明 DM 已經初始化過了 */
            dm_warn("Virtual root driver already exists!\n");
            return -EINVAL;
        }

        /* 初始化 uclass 鏈表 */
        INIT_LIST_HEAD(&DM_UCLASS_ROOT_NON_CONST);

    #if defined(CONFIG_NEEDS_MANUAL_RELOC)
        /* 手動重設  method pointers 到 relocation 後的 address */
        fix_drivers();
        fix_uclass();
        fix_devices();
    #endif

        /**
         *  DM_ROOT_NON_CONST 是指根設備 udevice, root_info 是表示根設備的設備信息.
         *  device_bind_by_name 會查找和設備信息匹配的 driver,
         *  然後創建對應的 udevice 和 uclass 並進行綁定,
         *  最後放在 DM_ROOT_NON_CONST 中.
         *  此時 root device 的 udevice 以及對應的 uclass 都已經創建完成
         */
        ret = device_bind_by_name(NULL, false, &root_info, &DM_ROOT_NON_CONST);
        if (ret)
            return ret;
    #if CONFIG_IS_ENABLED(OF_CONTROL)
    # if CONFIG_IS_ENABLED(OF_LIVE)
        if (of_live)
            DM_ROOT_NON_CONST->node = np_to_ofnode(gd->of_root);
        else
    #endif
            DM_ROOT_NON_CONST->node = offset_to_ofnode(0);
    #endif
        /**
         *  對 root device 執行 probe 操作
         */
        ret = device_probe(DM_ROOT_NON_CONST);
        if (ret)
            return ret;

        return 0;
    }
    ```

## `dm_extended_scan_fdt()`

+ source code
    > At `drivers/core/root.c`

    ```c
    static int dm_scan_fdt_node(struct udevice *parent, const void *blob,
                    int offset, bool pre_reloc_only)
    {
        int ret = 0, err;

        /*
         *  以下是遍歷每一個 dts 節點並且調用 lists_bind_fdt 對其進行解析並綁定
         *  fdt_first_subnode 獲得 blob 設備樹, 從偏移 offset 處開始
         */
        for (offset = fdt_first_subnode(blob, offset);
             offset > 0;
             offset = fdt_next_subnode(blob, offset)) {
            const char *node_name = fdt_get_name(blob, offset, NULL);

            /*
             * The "chosen" and "firmware" nodes aren't devices
             * themselves but may contain some:
             */
            if (!strcmp(node_name, "chosen") ||
                !strcmp(node_name, "firmware")) {
                pr_debug("parsing subnodes of \"%s\"\n", node_name);

                err = dm_scan_fdt_node(parent, blob, offset,
                               pre_reloc_only);
                if (err && !ret)
                    ret = err;
                continue;   /* 沒有子節點的話則繼續掃瞄下一個節點 */
            }

            /*
             *  判斷節點狀態是否是 disable, 如果是的話直接忽略
             */
            if (!fdtdec_get_is_enabled(blob, offset)) {
                pr_debug("   - ignoring disabled device\n");
                continue;
            }

            /*
             *  解析並綁定這個節點
             */
            err = lists_bind_fdt(parent, offset_to_ofnode(offset), NULL,
                         pre_reloc_only);
            if (err && !ret) {
                ret = err;
                debug("%s: ret=%d\n", node_name, ret);
            }
        }

        if (ret)
            dm_warn("Some drivers failed to bind\n");

        return ret;
    }

    int dm_scan_fdt(const void *blob, bool pre_reloc_only)
    {
    #if CONFIG_IS_ENABLED(OF_LIVE)
        if (of_live_active())
            return dm_scan_fdt_live(gd->dm_root, gd->of_root,
                        pre_reloc_only);
        else
    #endif
        /**
         *  parent         = gd->dm_root, 表示以 root device 作為父設備開始解析
         *  blob           = gd->fdt_blob, 指定了對應的 dtb data
         *  offset         = 0, 從偏移 0 的節點開始掃瞄
         *  pre_reloc_only = 0, 解析 relotion 前或是 relotion 後的設備
         */
        return dm_scan_fdt_node(gd->dm_root, blob, 0, pre_reloc_only);
    }

    int dm_extended_scan_fdt(const void *blob, bool pre_reloc_only)
    {
        int ret;

        ret = dm_scan_fdt(blob, pre_reloc_only);
        if (ret) {
            debug("dm_scan_fdt() failed: %d\n", ret);
            return ret;
        }

        ret = dm_scan_fdt_ofnode_path("/clocks", pre_reloc_only);
        if (ret) {
            debug("scan for /clocks failed: %d\n", ret);
            return ret;
        }

        ret = dm_scan_fdt_ofnode_path("/firmware", pre_reloc_only);
        if (ret)
            debug("scan for /firmware failed: %d\n", ret);

        return ret;
    }
    ```

+ `lists_bind_fdt()`
    > At `drivers/core/lists.c`

    ```c
    int lists_bind_fdt(struct udevice *parent, ofnode node, struct udevice **devp,
               bool pre_reloc_only)
    {
        struct driver *driver = ll_entry_start(struct driver, driver); /* 獲得 driver table start pointer */
        const int n_ents = ll_entry_count(struct driver, driver);      /* 計算 driver item 的數量 */
        const struct udevice_id *id;
        struct driver *entry;
        struct udevice *dev;
        bool found = false;
        const char *name, *compat_list, *compat;
        int compat_length, i;
        int result = 0;
        int ret = 0;

        if (devp)
            *devp = NULL;
        name = ofnode_get_name(node);
        log_debug("bind node %s\n", name);

        /*
         *  compatible 用來匹配的關鍵詞
         */
        compat_list = ofnode_get_property(node, "compatible", &compat_length);
        if (!compat_list) {
            if (compat_length == -FDT_ERR_NOTFOUND) {
                log_debug("Device '%s' has no compatible string\n",
                      name);
                return 0;
            }

            dm_warn("Device tree error at node '%s'\n", name);
            return compat_length;
        }

        /*
         * Walk through the compatible string list, attempting to match each
         * compatible string in order such that we match in order of priority
         * from the first string to the last.
         */
        for (i = 0; i < compat_length; i += strlen(compat) + 1) {
            compat = compat_list + i;
            log_debug("   - attempt to match compatible string '%s'\n",
                  compat);

            for (entry = driver; entry != driver + n_ents; entry++) {
                /**
                 *  搜尋 driver table 裡是否有對應的 compatible string
                 *  Check if a driver matches a compatible string
                 */
                ret = driver_check_compatible(entry->of_match, &id,
                                  compat);
                if (!ret)
                    break;
            }
            if (entry == driver + n_ents)
                continue;   /* 沒有對應的 compatible string */

            if (pre_reloc_only) {
                /**
                 *  check 是否有 'u-boot,dm-pre-reloc'
                 *  或是 'u-boot,dm-pre-proper' 屬性
                 */
                if (!dm_ofnode_pre_reloc(node) &&
                    !(entry->flags & DM_FLAG_PRE_RELOC))
                    return 0;
            }

            log_debug("   - found match at '%s': '%s' matches '%s'\n",
                  entry->name, entry->of_match->compatible,
                  id->compatible);

            /**
             *  進行 binding, 將設備節點和 parent 節點建立聯繫, 也就是建立樹形結構.
             *  device_bind_with_driver_data() -> device_bind_common()
             */
            ret = device_bind_with_driver_data(parent, entry, name,
                               id->data, node, &dev);
            if (ret == -ENODEV) {
                log_debug("Driver '%s' refuses to bind\n", entry->name);
                continue;
            }
            if (ret) {
                dm_warn("Error binding driver '%s': %d\n", entry->name,
                    ret);
                return ret;
            } else {
                found = true;
                if (devp)
                    *devp = dev;
            }
            break;
        }

        if (!found && !result && ret != -ENODEV)
            log_debug("No match for node '%s'\n", name);

        return result;
    }
    ```

+ `device_bind_common()`
    > At `drivers/core/device.c`

    ```c
    static int device_bind_common(struct udevice *parent, const struct driver *drv,
                      const char *name, void *platdata,
                      ulong driver_data, ofnode node,
                      uint of_platdata_size, struct udevice **devp)
    {
        struct udevice *dev;
        struct uclass *uc;
        int size, ret = 0;

        if (devp)
            *devp = NULL;
        if (!name)
            return -EINVAL;

        /**
         *  根據 id 查找同類 uclass, 如果沒有, 就新建一個 uclass
         */
        ret = uclass_get(drv->id, &uc);
        if (ret) {
            debug("Missing uclass for driver %s\n", drv->name);
            return ret;
        }

        /**
         *  生成一個 udevice
         */
        dev = calloc(1, sizeof(struct udevice));
        if (!dev)
            return -ENOMEM;

        INIT_LIST_HEAD(&dev->sibling_node);
        INIT_LIST_HEAD(&dev->child_head);
        INIT_LIST_HEAD(&dev->uclass_node);
    #ifdef CONFIG_DEVRES
        INIT_LIST_HEAD(&dev->devres_head);
    #endif
        dev->platdata = platdata;   // 指向設備 platdata
        dev->driver_data = driver_data;
        dev->name = name;           // 驅動名字
        dev->node = node;
        dev->parent = parent;       // 設置 udevice 的父設備
        dev->driver = drv;          // 绑定 udevice 和 driver
        dev->uclass = uc;           // 設置 udevice 的所屬 uclass

        dev->seq = -1;
        dev->req_seq = -1;
        if (CONFIG_IS_ENABLED(DM_SEQ_ALIAS) &&
            (uc->uc_drv->flags & DM_UC_FLAG_SEQ_ALIAS)) {
            /*
             * Some devices, such as a SPI bus, I2C bus and serial ports
             * are numbered using aliases.
             *
             * This is just a 'requested' sequence, and will be
             * resolved (and ->seq updated) when the device is probed.
             */
            if (CONFIG_IS_ENABLED(OF_CONTROL) && !CONFIG_IS_ENABLED(OF_PLATDATA)) {
                if (uc->uc_drv->name && ofnode_valid(node))
                    dev_read_alias_seq(dev, &dev->req_seq);
    #if CONFIG_IS_ENABLED(OF_PRIOR_STAGE)
                if (dev->req_seq == -1)
                    dev->req_seq =
                        uclass_find_next_free_req_seq(drv->id);
    #endif
            } else {
                dev->req_seq = uclass_find_next_free_req_seq(drv->id);
            }
        }

        if (drv->platdata_auto_alloc_size) {
            bool alloc = !platdata;

            if (CONFIG_IS_ENABLED(OF_PLATDATA)) {
                if (of_platdata_size) {
                    dev->flags |= DM_FLAG_OF_PLATDATA;
                    if (of_platdata_size <
                            drv->platdata_auto_alloc_size)
                        alloc = true;
                }
            }
            if (alloc) {
                dev->flags |= DM_FLAG_ALLOC_PDATA;
                /**
                 *  為 udevice 分配平台數據的空間,
                 *  由 driver 中的 platdata_auto_alloc_size 決定
                 */
                dev->platdata = calloc(1,
                               drv->platdata_auto_alloc_size);
                if (!dev->platdata) {
                    ret = -ENOMEM;
                    goto fail_alloc1;
                }
                if (CONFIG_IS_ENABLED(OF_PLATDATA) && platdata) {
                    memcpy(dev->platdata, platdata,
                           of_platdata_size);
                }
            }
        }

        size = uc->uc_drv->per_device_platdata_auto_alloc_size;
        if (size) {
            dev->flags |= DM_FLAG_ALLOC_UCLASS_PDATA;
            dev->uclass_platdata = calloc(1, size);
            if (!dev->uclass_platdata) {
                ret = -ENOMEM;
                goto fail_alloc2;
            }
        }

        if (parent) {
            size = parent->driver->per_child_platdata_auto_alloc_size;
            if (!size) {
                size = parent->uclass->uc_drv->
                        per_child_platdata_auto_alloc_size;
            }
            if (size) {
                dev->flags |= DM_FLAG_ALLOC_PARENT_PDATA;
                dev->parent_platdata = calloc(1, size);
                if (!dev->parent_platdata) {
                    ret = -ENOMEM;
                    goto fail_alloc3;
                }
            }
        }

        /* put dev into parent's successor list */
        if (parent)
            list_add_tail(&dev->sibling_node, &parent->child_head); /* 添加到父設備的子設備 list 中 */

        /**
         * 綁定 uclass 和 udevice,
         * 將 udevice 連接到對應的 uclass list (udev->uclass->dev_head) 上
         */
        ret = uclass_bind_device(dev);
        if (ret)
            goto fail_uclass_bind;

        /* if we fail to bind we remove device from successors and free it */
        if (drv->bind) {
            ret = drv->bind(dev);   /* 執行 udevice 對應 driver 的 bind method */
            if (ret)
                goto fail_bind;
        }
        if (parent && parent->driver->child_post_bind) {
            ret = parent->driver->child_post_bind(dev); /* 父節點 driver 的 child_post_bind method */
            if (ret)
                goto fail_child_post_bind;
        }
        if (uc->uc_drv->post_bind) {
            /* 設備所屬的 uclass_driver 的 post_bind method.
             * (具體的設備節點就是在這個接口下, 在 soc 下進行展開的)
             */
            ret = uc->uc_drv->post_bind(dev);
            if (ret)
                goto fail_uclass_post_bind;
        }

        if (parent)
            pr_debug("Bound device %s to %s\n", dev->name, parent->name);
        if (devp)
            *devp = dev;  /* 將 udevice 進行返回 */

        /**
         *  設置已經綁定的標誌.
         *  後續可以通過 'dev->flags & DM_FLAG_ACTIVATED'
         *  或者 device_active 宏來判斷設備是否已經被激活
         */
        dev->flags |= DM_FLAG_BOUND;

        return 0;

     ...
        return ret;
    }
    ```

## `device_probe()`

激活一個設備主要是通過 device_probe(), 主要的流程:
> + 分配設備的私有數據
> + 對父設備進行 probe
> + 執行 probe device 之前 uclass 需要調用的一些函數
> + 調用 driver 的 ofdata_to_platdata, 將 dts 信息轉化為設備的平台數據
> + 調用 driver 的 probe()
> + 執行 probe device 之後 uclass 需要調用的一些函數

+ source code
    > At `drivers/core/device.c`

    ```c
    int device_probe(struct udevice *dev)
    {
        const struct driver *drv;
        int size = 0;
        int ret;
        int seq;

        if (!dev)
            return -EINVAL;

        /* 表示這個設備已經被激活了 */
        if (dev->flags & DM_FLAG_ACTIVATED)
            return 0;

        drv = dev->driver;
        assert(drv);

        /* Allocate private data if requested and not reentered */
        if (drv->priv_auto_alloc_size && !dev->priv) {
            /* 分配私有數據 */
            dev->priv = alloc_priv(drv->priv_auto_alloc_size, drv->flags);
            if (!dev->priv) {
                ret = -ENOMEM;
                goto fail;
            }
        }
        /* Allocate private data if requested and not reentered */
        size = dev->uclass->uc_drv->per_device_auto_alloc_size;
        if (size && !dev->uclass_priv) {
            /* 為設備所屬 uclass 分配私有數據 */
            dev->uclass_priv = alloc_priv(size,
                              dev->uclass->uc_drv->flags);
            if (!dev->uclass_priv) {
                ret = -ENOMEM;
                goto fail;
            }
        }

        /* Ensure all parents are probed */
        if (dev->parent) {
            size = dev->parent->driver->per_child_auto_alloc_size;
            if (!size) {
                size = dev->parent->uclass->uc_drv->
                        per_child_auto_alloc_size;
            }
            if (size && !dev->parent_priv) {
                dev->parent_priv = alloc_priv(size, drv->flags);
                if (!dev->parent_priv) {
                    ret = -ENOMEM;
                    goto fail;
                }
            }

            /* recursive 到最上層 parent */
            ret = device_probe(dev->parent);
            if (ret)
                goto fail;

            /*
             * The device might have already been probed during
             * the call to device_probe() on its parent device
             * (e.g. PCI bridge devices). Test the flags again
             * so that we don't mess up the device.
             */
            if (dev->flags & DM_FLAG_ACTIVATED)
                return 0;
        }

        seq = uclass_resolve_seq(dev);
        if (seq < 0) {
            ret = seq;
            goto fail;
        }
        dev->seq = seq;

        /* 設置 udevice 的激活標誌 */
        dev->flags |= DM_FLAG_ACTIVATED;

        /*
         * Process pinctrl for everything except the root device, and
         * continue regardless of the result of pinctrl. Don't process pinctrl
         * settings for pinctrl devices since the device may not yet be
         * probed.
         */
        if (dev->parent && device_get_uclass_id(dev) != UCLASS_PINCTRL)
            pinctrl_select_state(dev, "default");

        if (CONFIG_IS_ENABLED(POWER_DOMAIN) && dev->parent &&
            (device_get_uclass_id(dev) != UCLASS_POWER_DOMAIN) &&
            !(drv->flags & DM_FLAG_DEFAULT_PD_CTRL_OFF)) {
            ret = dev_power_domain_on(dev);
            if (ret)
                goto fail;
        }

        /* uclass 在 probe device 之前的一些函數的調用 */
        ret = uclass_pre_probe_device(dev);
        if (ret)
            goto fail;

        if (dev->parent && dev->parent->driver->child_pre_probe) {
            ret = dev->parent->driver->child_pre_probe(dev);
            if (ret)
                goto fail;
        }

        if (drv->ofdata_to_platdata &&
            (CONFIG_IS_ENABLED(OF_PLATDATA) || dev_has_of_node(dev))) {
            /* 調用 driver 中的 ofdata_to_platdata,
             * 將 dts 信息轉化為設備的平台數據
             */
            ret = drv->ofdata_to_platdata(dev);
            if (ret)
                goto fail;
        }

        /* Only handle devices that have a valid ofnode */
        if (dev_of_valid(dev)) {
            /*
             * Process 'assigned-{clocks/clock-parents/clock-rates}'
             * properties
             */
            ret = clk_set_defaults(dev, 0);
            if (ret)
                goto fail;
        }

        if (drv->probe) {
            /* 調用 driver 的 probe method, 到這裡設備才真正激活了 */
            ret = drv->probe(dev);
            if (ret) {
                dev->flags &= ~DM_FLAG_ACTIVATED;
                goto fail;
            }
        }

        ret = uclass_post_probe_device(dev);
        if (ret)
            goto fail_uclass;

        if (dev->parent && device_get_uclass_id(dev) == UCLASS_PINCTRL)
            pinctrl_select_state(dev, "default");

        return 0;
    ...
        return ret;
    }
    ```

+ 透過 uclass 來取得 udevice 並 probe
    > At `drivers/core/uclass.c`

    ```c
    /*
     * 通過索引從 uclass 的設備鏈表中獲取 udevice, 並且進行 probe
     */
    int uclass_get_device(enum uclass_id id, int index, struct udevice **devp)

    /**
     *  通過設備名從 uclass 的設備鏈表中獲取 udevice, 並且進行 probe
     */
    int uclass_get_device_by_name(enum uclass_id id, const char *name,
                      struct udevice **devp)

    /**
     *  通過序號從 uclass 的設備鏈表中獲取 udevice, 並且進行 probe
     */
    int uclass_get_device_by_seq(enum uclass_id id, int seq, struct udevice **devp)

    /**
     *  通過 dts 節點的偏移從 uclass 的設備鏈表中獲取 udevice, 並且進行 probe
     */
    int uclass_get_device_by_of_offset(enum uclass_id id, int node,
                       struct udevice **devp)

    /**
     *  通過設備的 "phandle" 屬性從 uclass 的設備鏈表中獲取 udevice, 並且進行 probe
     */
    int uclass_get_device_by_phandle(enum uclass_id id, struct udevice *parent,
                     const char *name, struct udevice **devp)

    /**
     *  從 uclass 的設備鏈表中獲取第一個 udevice, 並且進行 probe
     */
    int uclass_first_device(enum uclass_id id, struct udevice **devp)

    /**
     *  從 uclass 的設備鏈表中獲取下一個 udevice, 並且進行 probe
     */
    int uclass_next_device(struct udevice **devp)
    ```

# examples of serial

serial-uclass 只操作作為 console 的 serial

+ serial uclass driver
    > At `drivers/serial/serial-uclass.c`

    ```
    UCLASS_DRIVER(serial) = {
        .id            = UCLASS_SERIAL,     // 注意這裡的 uclass id
        .name          = "serial",
        .flags         = DM_UC_FLAG_SEQ_ALIAS,
        .post_probe    = serial_post_probe,
        .pre_remove    = serial_pre_remove,
        .per_device_auto_alloc_size = sizeof(struct serial_dev_priv),
    };
    ```

+ serial driver

    - dts (ex. s5pv210 serial)

        ```
        ...
        serial@e2900000 {
            compatible = "samsung,exynos4210-uart"; // 注意這裡的 compatible
            reg = <0xe2900000 0x100>;
            interrupts = <0 51 0>;
            id = <0>;
        };
        ```

    - driver source

        ```
        static const struct udevice_id s5p_serial_ids[] = {
            { .compatible = "samsung,exynos4210-uart" }, // 注意這裡的 compatible
            { }
        };

        U_BOOT_DRIVER(serial_s5p) = {
            .name       = "serial_s5p",
            .id         = UCLASS_SERIAL,    // 注意這裡的 uclass id
            .of_match   = s5p_serial_ids,
            .ofdata_to_platdata = s5p_serial_ofdata_to_platdata,
            .platdata_auto_alloc_size = sizeof(struct s5p_serial_platdata),
            .probe      = s5p_serial_probe,
            .ops        = &s5p_serial_ops,
            .flags      = DM_FLAG_PRE_RELOC,
        };
        ```

+ flow

    - 在 uboot 初始化 DM 時, 創建 udevice 和 uclass 的對應
    - 在 uboot 初始化 DM 時, 綁定 udevice 和 uclass
    - udevice 的 probe method
    - uclass interface

        1. 原則上先從 root_uclass list 中提取對應的 uclass,
        然後通過 uclass->uclass_driver->ops 來進行 method 調用

        1. 調用 uclass 直接呼叫 API(不推薦, 有些是為了與舊版相容), 像 serial-uclass 使用的是這種方式
            > 這部分應該屬於 serial core, 但是也放在了 serial-uclass.c 中實現.
            其他 uclass 也有類似的情況

            ```
            static void serial_find_console_or_panic(void)
            {
                const void *blob = gd->fdt_blob;
                struct udevice *dev;
            ...
                /* skip 部分 code */
                if (CONFIG_IS_ENABLED(OF_PLATDATA)) {
                    uclass_first_device(UCLASS_SERIAL, &dev);
                    if (dev) {
                        gd->cur_serial_dev = dev;
                        return;
                    }
                } else if (CONFIG_IS_ENABLED(OF_CONTROL) && blob) {
                    /* Live tree has support for stdout */
                    if (of_live_active()) {
                        struct device_node *np = of_get_stdout();

                        /**
                         *  透過 uclass_get_device_xxx(),
                         *  從 uclass 的設備鏈表中獲取 udevice, 並且進行 probe
                         */
                        if (np && !uclass_get_device_by_ofnode(UCLASS_SERIAL,
                                np_to_ofnode(np), &dev)) {

                            /**
                             *  將 udevice 存儲在 gd->cur_serial_dev,
                             *  後續 uclass 可以直接通過 gd->cur_serial_dev 獲取到對應的設備並且進行操作
                             *  但是注意, 這種並不是通用做法
                             */
                            gd->cur_serial_dev = dev;
                            return;
                        }
                    } else {
                        if (!serial_check_stdout(blob, &dev)) {
                            gd->cur_serial_dev = dev;
                            return;
                        }
                    }
                }
            ...
            }

            int serial_init(void)
            {
                // 調用 serial_find_console_or_panic 進行作為 console serial的初始化
                serial_find_console_or_panic();
                gd->flags |= GD_FLG_SERIAL_READY;

                return 0;
            }
            ...

            static void _serial_putc(struct udevice *dev, char ch)
            {
                /* 獲取設備對應的 driver 的 ops 操作集 */
                struct dm_serial_ops *ops = serial_get_ops(dev);
                int err;

                do {
                    /* 以udevice為參數, 調用ops中對應的操作函數 */
                    err = ops->putc(dev, ch);
                } while (err == -EAGAIN);
            }

            /* 直接開放 API */
            void serial_putc(char ch)
            {
                if (gd->cur_serial_dev)
                    /* 將 console 對應的 serial 的 udevice 作為參數傳入 */
                    _serial_putc(gd->cur_serial_dev, ch);
            }
            ```

# examples of dm_gpio

```
                 app
                  |
    --------------------------------
                  | API
                  |
    dts <----> gpio core (instance in gpio uclass)
                  |
                gpio uclass ------- gpio uclass_driver
                  |
            +-----+-----+
            |           |
       gpio udevice  gpio udevice
          (bank 1)    (bank 2)
            |           |
        gpio driver  gpio driver
            |           |
           H/w 1       H/w 2
```

+ gpio core
    > 也在 gpio uclass 中實現

    - 主要是為上層提供接口
    - 從 dts 中獲取 GPIO 屬性
    - 從 gpio uclass 的設備鏈表中獲取到相應的 udevice 設備, 並使用其操作集

+ gpio uclass

    - 鏈接屬於該 uclass 的所有 gpio udevice 設備
    - 為 gpio udevice 的 driver 提供統一的操作集接口

+ bank 和 gpio

    - 有些平台上, 將某些使用同一組寄存器的 gpio 構成一個 bank, 例如三星的 s5pv210
    - 並不是所有平台都有 bank 的概念, 例如高通的 GPIO 都有自己獨立的寄存器, 因此可以將高通當成只有一個bank

+ gpio udevice

    - 一個 bank 對應一個 gpio udevice, 用 bank 中的偏移來表示具體的 GPIO 號
    - gpio udevice 的 driver 就會根據 bank 以及 offset 對相應的寄存器上的相應的 bit 進行操作.

+ flow
    - 一個 bank 對應一個 udevice, udevice 中私有數據中存放著該 bank 的信息, 比如相應 register bass 等
    - APP 層用 gpio_desc 來描述一個 GPIO, 其中包括該 GPIO 所屬的 udevice, 在 bank 內的偏移, 以及標誌位.
    - APP 層通過調用 gpio core 的接口從 dtsi 獲取到 GPIO 屬性對應的 gpio_desc
    - APP 層使用 gpio_desc 來作為調用 gpio core 的操作接口的參數
    - gpio core 從 gpio_desc 提取 udevice, 並調用其 driver 中對應的 methods,
        以 bank 內的偏移作為其參數(這樣 driver 就能判斷出是哪個 GPIO 了)
    - driver 中提取 udevice 的私有數據中的 bank 信息, 並進行相應的操作

##

# reference

+ [uboot 驅動模型](https://blog.csdn.net/ooonebook/article/details/53234020)
+ [uboot dm-gpio使用方法以及工作](https://blog.csdn.net/ooonebook/article/details/53340441)

+ [uboot驱动模型(DM)分析(二)](https://www.cnblogs.com/gs1008612/p/8253213.html)
    - ![uclass,uclass_driver,udevice,driver之間的關係](https://images2017.cnblogs.com/blog/1288891/201801/1288891-20180109195640754-1116532786.png)