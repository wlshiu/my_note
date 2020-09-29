uboot boot Stage 2 [[Back](note_uboot_quick_start.md)]
---

# source code

## `board_init_r()`

board initialize relocated

+ sourece code
    > At `common/board_r.c`

    ```c
    void board_init_r(gd_t *new_gd, ulong dest_addr)
    {
        /*
         * Set up the new global data pointer. So far only x86 does this
         * here.
         * TODO(sjg@chromium.org): Consider doing this for all archs, or
         * dropping the new_gd parameter.
         */
    #if CONFIG_IS_ENABLED(X86_64)
        arch_setup_gd(new_gd);
    #endif

    #ifdef CONFIG_NEEDS_MANUAL_RELOC
        int i;
    #endif

    #if !defined(CONFIG_X86) && !defined(CONFIG_ARM) && !defined(CONFIG_ARM64)
        gd = new_gd;
    #endif
        gd->flags &= ~GD_FLG_LOG_READY;

    #ifdef CONFIG_NEEDS_MANUAL_RELOC
        for (i = 0; i < ARRAY_SIZE(init_sequence_r); i++)
            init_sequence_r[i] += gd->reloc_off;
    #endif

        if (initcall_run_list(init_sequence_r))
            hang();

        /* NOTREACHED - run_main_loop() does not return */
        hang();
    }
    ```

+ `init_sequence_r[]` list

    ```c
    static init_fnc_t init_sequence_r[] = {
        initr_trace,        /* 初始化 tracing buffer 相關 */
        initr_reloc,        /* 標記重定位完成 */
        /* TODO: could x86/PPC have this also perhaps? */
    #ifdef CONFIG_ARM
        initr_caches,       /* Enable i-caches and d-cache */
        /* Note: For Freescale LS2 SoCs, new MMU table is created in DDR.
         *	 A temporary mapping of IFC high region is since removed,
         *	 so environmental variables in NOR flash is not available
         *	 until board_init() is called below to remap IFC to high
         *	 region.
         */
    #endif
        initr_reloc_global_data,    /* 初始化 gd 的一些成員變量 */
    #if defined(CONFIG_SYS_INIT_RAM_LOCK) && defined(CONFIG_E500)
        initr_unlock_ram_in_cache,
    #endif
        initr_barrier,
        initr_malloc,       /* 初始化 heap malloc 區域 */
        log_init,
        initr_bootstage,	/* Needs malloc() but has its own timer; 初始化 bootstage */
        initr_console_record,   /* 初始化 console I/O buffer 相關內容 */
    #ifdef CONFIG_SYS_NONCACHED_MEMORY
        initr_noncached,
    #endif
    #ifdef CONFIG_OF_LIVE
        initr_of_live,
    #endif
    #ifdef CONFIG_DM
        initr_dm,
    #endif
    #if defined(CONFIG_ARM) || defined(CONFIG_NDS32) || defined(CONFIG_RISCV) || \
        defined(CONFIG_SANDBOX)
        board_init,	/* Setup chipselects */
    #endif
        /*
         * TODO: printing of the clock inforamtion of the board is now
         * implemented as part of bdinfo command. Currently only support for
         * davinci SOC's is added. Remove this check once all the board
         * implement this.
         */
    #ifdef CONFIG_CLOCKS
        set_cpu_clk_info, /* Setup clock information */
    #endif
    #ifdef CONFIG_EFI_LOADER
        efi_memory_init,
    #endif
        stdio_init_tables,
        initr_serial,
        initr_announce,
    #if CONFIG_IS_ENABLED(WDT)
        initr_watchdog,
    #endif
        INIT_FUNC_WATCHDOG_RESET
    #ifdef CONFIG_NEEDS_MANUAL_RELOC
        initr_manual_reloc_cmdtable,
    #endif
    #if defined(CONFIG_PPC) || defined(CONFIG_M68K) || defined(CONFIG_MIPS)
        initr_trap,
    #endif
    #ifdef CONFIG_ADDR_MAP
        initr_addr_map,
    #endif
    #if defined(CONFIG_BOARD_EARLY_INIT_R)
        board_early_init_r,
    #endif
        INIT_FUNC_WATCHDOG_RESET
    #ifdef CONFIG_POST
        initr_post_backlog,
    #endif
        INIT_FUNC_WATCHDOG_RESET
    #if defined(CONFIG_PCI) && defined(CONFIG_SYS_EARLY_PCI_INIT)
        /*
         * Do early PCI configuration _before_ the flash gets initialised,
         * because PCU resources are crucial for flash access on some boards.
         */
        initr_pci,
    #endif
    #ifdef CONFIG_ARCH_EARLY_INIT_R
        arch_early_init_r,
    #endif
        power_init_board,
    #ifdef CONFIG_MTD_NOR_FLASH
        initr_flash,
    #endif
        INIT_FUNC_WATCHDOG_RESET
    #if defined(CONFIG_PPC) || defined(CONFIG_M68K) || defined(CONFIG_X86)
        /* initialize higher level parts of CPU like time base and timers */
        cpu_init_r,
    #endif
    #ifdef CONFIG_CMD_NAND
        initr_nand,     /* 初始化 nand flash */
    #endif
    #ifdef CONFIG_CMD_ONENAND
        initr_onenand,
    #endif
    #ifdef CONFIG_MMC
        initr_mmc,      /* 初始化 sd/mmc */
    #endif
        initr_env,      /* 環境變量初始化 */
    #ifdef CONFIG_SYS_BOOTPARAMS_LEN
        initr_malloc_bootparams,
    #endif
        INIT_FUNC_WATCHDOG_RESET
        initr_secondary_cpu,    /* 初始化其它的 CPU 核 */
    #if defined(CONFIG_ID_EEPROM) || defined(CONFIG_SYS_I2C_MAC_OFFSET)
        mac_read_from_eeprom,
    #endif
        INIT_FUNC_WATCHDOG_RESET
    #if defined(CONFIG_PCI) && !defined(CONFIG_SYS_EARLY_PCI_INIT)
        /*
         * Do pci configuration
         */
        initr_pci,
    #endif
        stdio_add_devices,  /* 初始化各種 I/O 設備 */
        initr_jumptable,    /* 初始化跳轉表相關的內容 */
    #ifdef CONFIG_API
        initr_api,
    #endif
        console_init_r,		/* fully init console as a device */
    #ifdef CONFIG_DISPLAY_BOARDINFO_LATE
        console_announce_r,
        show_board_info,
    #endif
    #ifdef CONFIG_ARCH_MISC_INIT
        arch_misc_init,		/* miscellaneous arch-dependent init */
    #endif
    #ifdef CONFIG_MISC_INIT_R
        misc_init_r,		/* miscellaneous platform-dependent init */
    #endif
        INIT_FUNC_WATCHDOG_RESET
    #ifdef CONFIG_CMD_KGDB
        initr_kgdb,
    #endif
        interrupt_init,     /* 初始化中斷相關內容 */
    #ifdef CONFIG_ARM
        initr_enable_interrupts,    /* 開啟 interrupt */
    #endif
    #if defined(CONFIG_MICROBLAZE) || defined(CONFIG_M68K)
        timer_init,		/* initialize timer */
    #endif
    #if defined(CONFIG_LED_STATUS)
        initr_status_led,
    #endif
        /* PPC has a udelay(20) here dating from 2002. Why? */
    #ifdef CONFIG_CMD_NET
        initr_ethaddr,      /* 獲取 mac 地址 */
    #endif
    #if defined(CONFIG_GPIO_HOG)
        gpio_hog_probe_all,
    #endif
    #ifdef CONFIG_BOARD_LATE_INIT
        board_late_init,    /* 板子後期一些外設的初始化 */
    #endif
    #if defined(CONFIG_SCSI) && !defined(CONFIG_DM_SCSI)
        INIT_FUNC_WATCHDOG_RESET
        initr_scsi,
    #endif
    #ifdef CONFIG_BITBANGMII
        initr_bbmii,
    #endif
    #ifdef CONFIG_CMD_NET
        INIT_FUNC_WATCHDOG_RESET
        initr_net,          /* 初始化板子的網絡設備 */
    #endif
    #ifdef CONFIG_POST
        initr_post,
    #endif
    #if defined(CONFIG_IDE) && !defined(CONFIG_BLK)
        initr_ide,
    #endif
    #ifdef CONFIG_LAST_STAGE_INIT
        INIT_FUNC_WATCHDOG_RESET
        /*
         * Some parts can be only initialized if all others (like
         * Interrupts) are up and running (i.e. the PC-style ISA
         * keyboard).
         */
        last_stage_init,
    #endif
    #ifdef CONFIG_CMD_BEDBUG
        INIT_FUNC_WATCHDOG_RESET
        initr_bedbug,
    #endif
    #if defined(CONFIG_PRAM)
        initr_mem,
    #endif
        run_main_loop,      /* 主循環函數, 用於處理輸入的命令 */
    };
    ```

    - `board_init()`
        > At `board/<vendor>/<soc>/xxx_board.c`

    - `initr_serial()`
        > 重新初始化初始化串口.
        relocation 前呼叫 `serial_init()`, relocation 後也是呼叫 `serial_init()`

    - `initr_env()`
        > 初始化環境變數, 並從環境變數獲取到 `loadaddr` 的值.
        必要時也會對 env_driver 做 relocate

    - `interrupt_init()`
        > 初始化中斷

        ```c
        int interrupt_init(void)
        {
            /*
             * setup up stacks if necessary
             */
            /* 這個宏在 arch/arm/lib/vectors.S 中,
             * 最開始裡面隨便填充的一個值,
             * 現在填上可以使用的值
             */
            IRQ_STACK_START_IN = gd->irq_sp + 8;

            return 0;
        }
        ```

        1. `arch/arm/lib/vectors.S`

            ```
            /* IRQ stack memory (calculated at run-time) + 8 bytes */
            .globl IRQ_STACK_START_IN
            IRQ_STACK_START_IN:
            #ifdef IRAM_BASE_ADDR /* 未定義 */
                .word   IRAM_BASE_ADDR + 0x20
            #else
                .word	0x0badc0de
            #endif
            ```

    - `run_main_loop()`

        ```c
        static int run_main_loop(void)
        {
        #ifdef CONFIG_SANDBOX
            sandbox_main_loop_init();
        #endif
            /* main_loop() can return to retry autoboot, if so just run it again */
            for (;;)
                main_loop();
            return 0;
        }
        ```

## `main_loop()`

+ sourece code
    > At `common/main.c`

    ```c
    void main_loop(void)
    {
        const char *s;

        bootstage_mark_name(BOOTSTAGE_ID_MAIN_LOOP, "main_loop");

        if (IS_ENABLED(CONFIG_VERSION_VARIABLE))
            env_set("ver", version_string);  /* set version variable */

        cli_init();

        if (IS_ENABLED(CONFIG_USE_PREBOOT))
            run_preboot_environment_command();

        if (IS_ENABLED(CONFIG_UPDATE_TFTP))
            update_tftp(0UL, NULL, NULL);

        s = bootdelay_process();
        if (cli_process_fdt(&s))
            cli_secure_boot_cmd(s);

        autoboot_command(s);

        cli_loop();
        panic("No CLI available");
    }
    ```

+ `bootdelay_process()`
    > 為了設置啟動延時使用, 可以通過`CONFIG_BOOTDELAY`設置啟動延時多少秒

+ `cli_process_fdt()`
    > 判斷是否有 secure boot 相關的

+ `autoboot_command()`
    > 執行環境變量 `bootcmd`的內容, 也就是執行相關的命令

## `bootm`

+ source code
    > At `cmd/bootm.c`

    ```c
    int do_bootm(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
    {
        /* determine if we have a sub command */
        argc--; argv++;
        if (argc > 0) {
            char *endp;

            simple_strtoul(argv[0], &endp, 16);
            /* endp pointing to NULL means that argv[0] was just a
             * valid number, pass it along to the normal bootm processing
             *
             * If endp is ':' or '#' assume a FIT identifier so pass
             * along for normal processing.
             *
             * Right now we assume the first arg should never be '-'
             * 判斷是否有子命令
             */
            if ((*endp != 0) && (*endp != ':') && (*endp != '#'))
                return do_bootm_subcommand(cmdtp, flag, argc, argv);
        }

        /* 最終調用到 do_bootm_states,
         * 在 do_bootm_states 中執行的操作如 states 標識所示:
         * BOOTM_STATE_START
         * BOOTM_STATE_FINDOS
         * BOOTM_STATE_FINDOTHER
         * BOOTM_STATE_LOADOS
         * BOOTM_STATE_OS_PREP
         * BOOTM_STATE_OS_FAKE_GO
         * BOOTM_STATE_OS_GO
         */
        return do_bootm_states(cmdtp, flag, argc, argv, BOOTM_STATE_START |
            BOOTM_STATE_FINDOS | BOOTM_STATE_FINDOTHER |
            BOOTM_STATE_LOADOS |
    #ifdef CONFIG_SYS_BOOT_RAMDISK_HIGH
            BOOTM_STATE_RAMDISK |
    #endif
    #if defined(CONFIG_PPC) || defined(CONFIG_MIPS)
            BOOTM_STATE_OS_CMDLINE |
    #endif
            BOOTM_STATE_OS_PREP | BOOTM_STATE_OS_FAKE_GO |
            BOOTM_STATE_OS_GO, &images, 1);
    }
    ```

    - state type

        1. `BOOTM_STATE_START`
            > 開始執行 bootm 的一些準備動作.

            ```
            #define BOOTM_STATE_START (0x00000001)
            ```

        1. BOOTM_STATE_FINDOS
            > 查找 OS image

            ```
            #define BOOTM_STATE_FINDOS (0x00000002)
            ```

        1. BOOTM_STATE_FINDOTHER
            > 查找 OS image 以外的其他鏡像, 比如 FDT\ramdisk 等等

            ```
            #define BOOTM_STATE_FINDOTHER (0x00000004)
            ```

        1. BOOTM_STATE_LOADOS
            > 加載 OS

            ```
            #define BOOTM_STATE_LOADOS (0x00000008)
            ```

        1. BOOTM_STATE_RAMDISK
            > 操作 ramdisk

            ```
            #define BOOTM_STATE_RAMDISK (0x00000010)
            ```

        1. BOOTM_STATE_FDT
            > 操作 FDT

            ```
            #define BOOTM_STATE_FDT (0x00000020)
            ```

        1. BOOTM_STATE_OS_CMDLINE
            > 操作 commandline

            ```
            #define BOOTM_STATE_OS_CMDLINE (0x00000040)
            ```

        1. BOOTM_STATE_OS_BD_T

            ```
            #define BOOTM_STATE_OS_BD_T (0x00000080)
            ```

        1. BOOTM_STATE_OS_PREP
            > 跳轉到 OS 前的準備動作

            ```
            #define BOOTM_STATE_OS_PREP (0x00000100)
            ```

        1. BOOTM_STATE_OS_FAKE_GO
            > 偽跳轉, 一般都能直接跳轉到 kernel 中去

            ```
            #define BOOTM_STATE_OS_FAKE_GO (0x00000200) /* 'Almost' run the OS */
            ```

        1. BOOTM_STATE_OS_GO
            > 跳轉到 kernel 中去

            ```
            #define BOOTM_STATE_OS_GO (0x00000400)
            ```

+ `do_bootm_states`
    > 主要流程簡單說明如下:
    > + BOOTM_STATE_START
    >> bootm 的準備動作
    > + BOOTM_STATE_FINDOS
    >> 獲取 kernel 信息
    > + BOOTM_STATE_FINDOTHER
    >> 獲取 ramdisk 和 fdt 的信息
    > + BOOTM_STATE_LOADOS
    >> 加載 kernel 到對應的位置上(有可能已經就在這個位置上了)
    > + BOOTM_STATE_RAMDISK and BOOTM_STATE_FDT
    >> 重定向 ramdisk 和 fdt(不一定需要)
    > + BOOTM_STATE_OS_PREP
    >> 執行跳轉前的準備動作
    > + BOOTM_STATE_OS_GO
    >> 設置啟動參數, 跳轉到 kernel 所在的地址上

    > 在這些流程中, 起傳遞作用的是`bootm_headers_t images`這個數據結構,
    有些流程是解析鏡像, 往這個結構體裡寫數據.
    而跳轉的時候, 則需要使用到這個結構體裡面的數據。

    - `struct bootm_headers`
        > At `include/image.h`

        ```c
        typedef struct bootm_headers {
            /*
             * Legacy os image header, if it is a multi component image
             * then boot_get_ramdisk() and get_fdt() will attempt to get
             * data from second and third component accordingly.
             */
            image_header_t  *legacy_hdr_os;     /* image header pointer; Legacy-uImage 的 iamge header */
            image_header_t  legacy_hdr_os_copy; /* header copy; Legacy-uImage的 iamge header 備份 */
            ulong           legacy_hdr_valid;   /* Legacy-uImage 的鏡像頭是否存在的標記 */

        #if IMAGE_ENABLE_FIT
            const char  *fit_uname_cfg; /* configuration node unit name; 配置節點名 */

            void        *fit_hdr_os;    /* os FIT image header; FIT-uImage 中 kernel 鏡像頭 */
            const char  *fit_uname_os;  /* os subimage node unit name; FIT-uImage 中 kernel 的節點名 */
            int         fit_noffset_os; /* os subimage node offset; FIT-uImage 中 kernel 的節點偏移 */

            void        *fit_hdr_rd;    /* init ramdisk FIT image header; FIT-uImage 中 ramdisk 的鏡像頭 */
            const char  *fit_uname_rd;  /* init ramdisk subimage node unit name; FIT-uImage 中 ramdisk 的節點名 */
            int         fit_noffset_rd; /* init ramdisk subimage node offset; FIT-uImage 中 ramdisk 的節點偏移 */

            void        *fit_hdr_fdt;   /* FDT blob FIT image header; FIT-uImage 中 FDT 的鏡像頭 */
            const char  *fit_uname_fdt; /* FDT blob subimage node unit name; FIT-uImage 中 FDT 的節點名 */
            int         fit_noffset_fdt;/* FDT blob subimage node offset; FIT-uImage 中 FDT 的節點偏移 */
        #endif

            image_info_t    os;     /* os image info; 操作系統信息的結構體 */
            ulong           ep;     /* entry point of OS; 操作系統的入口地址 */

            ulong       rd_start, rd_end;/* ramdisk start/end; ramdisk 在內存上的起始地址和結束地址 */

            char        *ft_addr;   /* flat dev tree address;  fdt 在內存上的地址 */
            ulong       ft_len;     /* length of flat device tree; fdt 在內存上的長度 */

            ulong       initrd_start;   //
            ulong       initrd_end;     //
            ulong       cmdline_start;  //
            ulong       cmdline_end;    //
            bd_t        *kbd;           //

            int         verify;     /* getenv("verify")[0] != 'n' */ // 是否需要驗證
            int         state;      /* 狀態標識, 用於標識對應的 bootm 需要做什麼操作 */

        #ifdef CONFIG_LMB
            struct lmb  lmb;        /* for memory mgmt */
        #endif

        } bootm_headers_t;
        ```

    - source code
        > At `common/bootm.c`

        ```c
        int do_bootm_states(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[],
                    int states, bootm_headers_t *images, int boot_progress)
        {
            boot_os_fn *boot_fn;
            ulong iflag = 0;
            int ret = 0, need_boot_fn;

            images->state |= states;

            /*
             * Work through the states and see how far we get. We stop on
             * any error.
             */
            /**
             *  判斷 states 是否需要 BOOTM_STATE_START 動作,
             *  也就是 bootm 的準備動作,
             *  需要的話則調用 bootm_start()
             */
            if (states & BOOTM_STATE_START)
                ret = bootm_start(cmdtp, flag, argc, argv);

            /**
             *  判斷 states 是否需要 BOOTM_STATE_FINDOS 動作,
             *  也就是獲取 kernel 信息,
             *  需要的話在調用 bootm_find_os()
             */
            if (!ret && (states & BOOTM_STATE_FINDOS))
                ret = bootm_find_os(cmdtp, flag, argc, argv);

            /**
             *  判斷 states 是否需要 BOOTM_STATE_FINDOTHER 動作,
             *  也就是獲取 ramdisk 和 fdt 等其他鏡像的信息,
             *  需要的話則調用 bootm_find_other()
             */
            if (!ret && (states & BOOTM_STATE_FINDOTHER))
                ret = bootm_find_other(cmdtp, flag, argc, argv);

            /**
             *  這裡要重點注意, 前面的步驟都是在解析 uImage 鏡像並填充 bootm_headers_t images.
             *  也就是說解析 uImage 的部分在此之前,
             *  而後續則是使用 bootm_headers_t images 裡面的內容來進行後續動作
             */

            /* Load the OS */
            /**
             *  判斷 states 是否需要 BOOTM_STATE_LOADOS 動作,
             *  也就是加載操作系統的動作,
             *  需要的話則調用 bootm_load_os
             */
            if (!ret && (states & BOOTM_STATE_LOADOS)) {
                iflag = bootm_disable_interrupts();
                ret = bootm_load_os(images, 0);
                if (ret && ret != BOOTM_ERR_OVERLAP)
                    goto err;
                else if (ret == BOOTM_ERR_OVERLAP)
                    ret = 0;
            }

            /* Relocate the ramdisk */
            /**
             * 是否需要重定向 ramdinsk, do_bootm 流程的話是不需要的
             */
        #ifdef CONFIG_SYS_BOOT_RAMDISK_HIGH
            if (!ret && (states & BOOTM_STATE_RAMDISK)) {
                ulong rd_len = images->rd_end - images->rd_start;

                ret = boot_ramdisk_high(&images->lmb, images->rd_start,
                    rd_len, &images->initrd_start, &images->initrd_end);
                if (!ret) {
                    env_set_hex("initrd_start", images->initrd_start);
                    env_set_hex("initrd_end", images->initrd_end);
                }
            }
        #endif

            /**
             *  是否需要重定向 fdt, do_bootm 流程的話是不需要的
             */
        #if IMAGE_ENABLE_OF_LIBFDT && defined(CONFIG_LMB)
            if (!ret && (states & BOOTM_STATE_FDT)) {
                boot_fdt_add_mem_rsv_regions(&images->lmb, images->ft_addr);
                ret = boot_relocate_fdt(&images->lmb, &images->ft_addr,
                            &images->ft_len);
            }
        #endif

            /* From now on, we need the OS boot function */
            if (ret)
                return ret;

            /**
             *  獲取對應操作系統的啟動函數, 存放到 boot_fn 中
             */
            boot_fn = bootm_os_get_boot_func(images->os.os);
            need_boot_fn = states & (BOOTM_STATE_OS_CMDLINE |
                    BOOTM_STATE_OS_BD_T | BOOTM_STATE_OS_PREP |
                    BOOTM_STATE_OS_FAKE_GO | BOOTM_STATE_OS_GO);
            if (boot_fn == NULL && need_boot_fn) {
                if (iflag)
                    enable_interrupts();
                printf("ERROR: booting os '%s' (%d) is not supported\n",
                       genimg_get_os_name(images->os.os), images->os.os);
                bootstage_error(BOOTSTAGE_ID_CHECK_BOOT_OS);
                return 1;
            }


            /* Call various other states that are not generally used */
            if (!ret && (states & BOOTM_STATE_OS_CMDLINE))
                ret = boot_fn(BOOTM_STATE_OS_CMDLINE, argc, argv, images);
            if (!ret && (states & BOOTM_STATE_OS_BD_T))
                ret = boot_fn(BOOTM_STATE_OS_BD_T, argc, argv, images);

            /**
             *  跳轉到 OS 前的準備動作,
             *  會直接調用啟動函數,
             *  但是標識是 BOOTM_STATE_OS_PREP
             */
            if (!ret && (states & BOOTM_STATE_OS_PREP)) {
        #if defined(CONFIG_SILENT_CONSOLE) && !defined(CONFIG_SILENT_U_BOOT_ONLY)
                if (images->os.os == IH_OS_LINUX)
                    fixup_silent_linux();
        #endif
                ret = boot_fn(BOOTM_STATE_OS_PREP, argc, argv, images);
            }

        #ifdef CONFIG_TRACE
            /* Pretend to run the OS, then run a user command */
            if (!ret && (states & BOOTM_STATE_OS_FAKE_GO)) {
                char *cmd_list = env_get("fakegocmd");

                ret = boot_selected_os(argc, argv, BOOTM_STATE_OS_FAKE_GO,
                        images, boot_fn);
                if (!ret && cmd_list)
                    ret = run_command_list(cmd_list, -1, flag);
            }
        #endif

            /* Check for unsupported subcommand. */
            if (ret) {
                puts("subcommand not supported\n");
                return ret;
            }

            /* Now run the OS! We hope this doesn't return */
            /**
             *  BOOTM_STATE_OS_GO 標識,
             *  跳轉到操作系統中, 並且不應該再返回了
             */
            if (!ret && (states & BOOTM_STATE_OS_GO))
                ret = boot_selected_os(argc, argv, BOOTM_STATE_OS_GO,
                        images, boot_fn);

            /* Deal with any fallout */
        err:
            if (iflag)
                enable_interrupts();

            if (ret == BOOTM_ERR_UNIMPLEMENTED)
                bootstage_error(BOOTSTAGE_ID_DECOMP_UNIMPL);
            else if (ret == BOOTM_ERR_RESET)
                do_reset(cmdtp, flag, argc, argv);

            return ret;
        }
        ```

+ `bootm_start`
    > 填入 `struct bootm_headers.verify` and `struct bootm_headers.lmb`

+ `bootm_find_os`
    > 填入 `struct bootm_headers.os` and `struct bootm_headers.ep`

+ `bootm_find_other`
    > 填入 `struct bootm_headers.rd_start`, `struct bootm_headers.rd_end`,
    `struct bootm_headers.ft_addr` and `struct bootm_headers.initrd_end`

+ `bootm_load_os`
    > 在 bootm_load_os() 中, 會對 kernel image 進行 load 到對應的位置上,
    並且如果 kernel image 是被 mkimage 壓縮過的, 那麼會先經過解壓之後再進行 load.
    >> 這裡要注意, 這裡的壓縮和 Image 壓縮成 zImage 並不是同一個,
    而是 uboot 在 Image 或者 zImage 的基礎上進行的壓縮.

    - source code

        ```c
        static int bootm_load_os(bootm_headers_t *images, int boot_progress)
        {
            image_info_t os = images->os;
            ulong load = os.load;
            ulong load_end;
            ulong blob_start = os.start;
            ulong blob_end = os.end;
            ulong image_start = os.image_start;
            ulong image_len = os.image_len;
            ulong flush_start = ALIGN_DOWN(load, ARCH_DMA_MINALIGN);
            bool no_overlap;
            void *load_buf, *image_buf;
            int err;

            load_buf = map_sysmem(load, 0);
            image_buf = map_sysmem(os.image_start, image_len);

            /**
             *  調用 bootm_decomp_image,
             *  對 image_buf 的 image 進行解壓縮,
             *  並 load 到 load_buf 上
             */
            err = image_decomp(os.comp, load, os.image_start, os.type,
                       load_buf, image_buf, image_len,
                       CONFIG_SYS_BOOTM_LEN, &load_end);
            if (err) {
                err = handle_decomp_error(os.comp, load_end - load, err);
                bootstage_error(BOOTSTAGE_ID_DECOMP_IMAGE);
                return err;
            }

            flush_cache(flush_start, ALIGN(load_end, ARCH_DMA_MINALIGN) - flush_start);

            debug("   kernel loaded at 0x%08lx, end = 0x%08lx\n", load, load_end);
            bootstage_mark(BOOTSTAGE_ID_KERNEL_LOADED);

            no_overlap = (os.comp == IH_COMP_NONE && load == image_start);

            if (!no_overlap && load < blob_end && load_end > blob_start) {
                debug("images.os.start = 0x%lX, images.os.end = 0x%lx\n",
                      blob_start, blob_end);
                debug("images.os.load = 0x%lx, load_end = 0x%lx\n", load,
                      load_end);

                /* Check what type of image this is. */
                if (images->legacy_hdr_valid) {
                    if (image_get_type(&images->legacy_hdr_os_copy)
                            == IH_TYPE_MULTI)
                        puts("WARNING: legacy format multi component image overwritten\n");
                    return BOOTM_ERR_OVERLAP;
                } else {
                    puts("ERROR: new format image overwritten - must RESET the board to recover\n");
                    bootstage_error(BOOTSTAGE_ID_OVERWRITTEN);
                    return BOOTM_ERR_RESET;
                }
            }

            lmb_reserve(&images->lmb, images->os.load, (load_end -
                                    images->os.load));
            return 0;
        }
        ```

+ `bootm_os_get_boot_func`
    > 根據 OS 類型獲得到對應的操作函數

    ```c
    /* At 'common/bootm_os.c' */

    static boot_os_fn *boot_os[] = {
    ...
    #ifdef CONFIG_BOOTM_LINUX
        [IH_OS_LINUX] = do_bootm_linux,
    #endif
    };
    ```

+ `do_bootm_linux`
    > `boot_fn(BOOTM_STATE_OS_PREP, argc, argv, images)`

    - source code
        > At `arch/arm/lib/bootm.c`

        ```c
        int do_bootm_linux(int flag, int argc, char * const argv[],
                   bootm_headers_t *images)
        {
            /* No need for those on ARM */
            if (flag & BOOTM_STATE_OS_BD_T || flag & BOOTM_STATE_OS_CMDLINE)
                return -1;

            /**
             *  當 flag 為 BOOTM_STATE_OS_PREP,
             *  則說明只需要做準備動作 boot_prep_linux()
             */
            if (flag & BOOTM_STATE_OS_PREP) {
                boot_prep_linux(images);
                return 0;
            }

            /**
             *  當 flag 為 BOOTM_STATE_OS_GO,
             *  則說明只需要做跳轉動作
             */
            if (flag & (BOOTM_STATE_OS_GO | BOOTM_STATE_OS_FAKE_GO)) {
                boot_jump_linux(images, flag);
                return 0;
            }

            /**
             *  以全局變量 'bootm_headers_t images' 為參數傳遞給 boot_prep_linux()
             */
            boot_prep_linux(images);

            /**
             *  以全局變量 'bootm_headers_t images' 為參數傳遞給 boot_jump_linux()
             */
            boot_jump_linux(images, flag);
            return 0;
        }
        ```

+ `boot_prep_linux`
    > 主要的目的是修正 LMB, 並把 LMB 填入到 fdt 中
    >> LMB (logical memory blocks), 主要是用於表示內存的保留區域,
    主要有 fdt 的區域, ramdisk 的區域等等

    - source code
        >  AT `arch/arm/lib/bootm.c`

        ```c
        static void boot_prep_linux(bootm_headers_t *images)
        {
            char *commandline = env_get("bootargs");

            if (IMAGE_ENABLE_OF_LIBFDT && images->ft_len) {
        #ifdef CONFIG_OF_LIBFDT
                debug("using: FDT\n");
                /**
                 *  修正 LMB, 並把 LMB 填入到 fdt 中
                 */
                if (image_setup_linux(images)) {
                    printf("FDT creation failed! hanging...");
                    hang();
                }
        #endif
            } else if (BOOTM_ENABLE_TAGS) {
                ...
            } else {
                printf("FDT and ATAGS support not compiled in - hanging\n");
                hang();
            }
        }
        ```

+ `boot_jump_linux`
    > 經過 `kernel_entry` 之後就跳轉到 kernel 環境中了

    - source code
        > At `arch/arm/lib/bootm.c`

        ```c
        static void boot_jump_linux(bootm_headers_t *images, int flag)
        {
            ...

            /**
             *  從 bd 中獲取 machine-id
             */
            unsigned long machid = gd->bd->bi_arch_number;
            char *s;

            /**
             * kernel 入口函數, 也就是 kernel 的入口地址, 對應 kernel 的 _start 地址.
             */
            void (*kernel_entry)(int zero, int arch, uint params);
            unsigned long r2;
            int fake = (flag & BOOTM_STATE_OS_FAKE_GO); // 偽跳轉, 並不真正地跳轉到 kernel 中

            /**
             *  將 kernel_entry 設置為 images 中的 ep (kernel的入口地址),
             *  後面直接執行 kernel_entry 也就跳轉到了 kernel 中了
             */
            kernel_entry = (void (*)(int, int, uint))images->ep;

            debug("## Transferring control to Linux (at address %08lx)" \
                "...\n", (ulong) kernel_entry);
            bootstage_mark(BOOTSTAGE_ID_RUN_OS);
            announce_and_cleanup(fake);

            /**
             *  把 images->ft_addr(fdt 的地址)放在 'r2' 中
             */
            if (IMAGE_ENABLE_OF_LIBFDT && images->ft_len)
                r2 = (unsigned long)images->ft_addr;
            else
                r2 = gd->bd->bi_boot_params;

            if (!fake) {
                ...

                    /**
                     *  這裡通過調用 kernel_entry, 就跳轉到了 images->ep 中了,
                     *  也就是跳轉到 kernel 中了, 具體則是 kernel 的 _start 地址.
                     *
                     *  參數 0 則傳入到 'register r0'中, 參數 machid 傳入到 'register r1' 中,
                     *  把 images->ft_addr(fdt 的地址)放在'register r2'中.
                     *  滿足了kernel啟動的硬件要求.
                     */
                    kernel_entry(0, machid, r2);
            }
        }
        ```

+ reference
    - [第01節_傳遞dtb給內核](https://blog.51cto.com/11134889/2326410)
    - [uboot啟動kernel篇(二)——bootm跳轉到kernel的流程](https://blog.csdn.net/ooonebook/article/details/53495021)

# reference

+ [Uboot啟動流程分析(六)](https://www.cnblogs.com/Cqlismy/p/12194641.html)
+ [Schulz-how-to-support-new-board-u-boot-linux.pdf](https://elinux.org/images/2/2a/Schulz-how-to-support-new-board-u-boot-linux.pdf)
