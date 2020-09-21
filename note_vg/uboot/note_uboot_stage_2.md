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
+ `autoboot_command()`

# reference

+ [Uboot啟動流程分析(六)](https://www.cnblogs.com/Cqlismy/p/12194641.html)