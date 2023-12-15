RISCV BootFlow [[Back]](note_riscv_quick_start.md#RISC-V-BootFlow)
----

在理解 RISC-V 的 boot 流程之前, 首先需要知道的是 RISC-V 設計的三種模式:
> + M-mode(Machine Mode)
> + S-mode(Supervisor Mode)
> + U-mode(User Mode)

![arm_vs_riscv_boot_level](./flow/arm_vs_riscv_boot_level.jpg)<br>
Fig 1. ARM vs RISCV Boot Levels


對於 ARM64 來說, 系統上電後, 啟動會處於 `EL3 secure world`, 所以對於 ARM64 來說,
一般都會使用 `ARM Trusted firmware (TF-A)`, 在 `Nnormal Space (EL2)` 與 `Secure Space (EL3)` 進行切換.

而對於 RISC-V 來說, 系統上電啟動後, 會在`M-Mode`, 而 RISC-V 目前是沒有 Hypervisor 這一層的概念的, 所以目前採用的是 OpenSBI, 如 Fig 2.

![riscv_with_opensbi.jpg](./flow/riscv_with_opensbi.jpg)<br>
Fig 2. RISC-V with OpenSBI


## RISC-V Boot Flow

RISC-V 啟動流程分為多個階段

![riscv_bootflow.jpg](./flow/riscv_bootflow.jpg)<br>
Fig 3. RISC-V Boot Flow

### OpenSBI Boot Flow analysis

[fw_base.S](fw_base.S)

OpenSBI 在一開始的 Assembly 階段做了這些事:

+ 首先 main-core 會去做 relocate (將 target 的 kernel, 從 LMA to VMA), 此時 slave-cores 會進入 loop 等待 main-core 做完 relocate
    > main-core 做完 relocate 後, 會通過寫一個 global 變數(_boot_status), 通知 slave-cores 此時已經完成了重定位

+ 完成重定位後, main-core 會去為每個 core 分配一段 stack 及 scratch 空間, 並將一些 scratch 參數放入 scratch 空間
    > e.g. 下一階段的跳轉地址, 下一階段的 Mode 等

    ```c
    typedef struct _scratch {
        unsigned long fw_start;           // 起始地址: Firmware linked to OpenSBI library
        unsigned long fw_size;            // 地址長度: Firmware linked to OpenSBI library
        unsigned long next_arg1;          // a1暫存器: 下一啟動階段 a1 暫存器
        unsigned long next_addr;          // 地址：下一啟動階段
        unsigned long next_mode;          // 優先順序模式: 下一啟動階段
        unsigned long warmboot_addr;      // 地址: warm boot
        unsigned long platform_addr;      // 地址: 啟動平台地址
        unsigned long hartid_to_scratch;  // 地址: HART id到sbi scratch 的轉換函數
        unsigned long trap_exit;          // 地址: 陷入退出函數
        unsigned long tmp0;               // 臨時儲存
        unsigned long options;            // OpenSBI 庫選項
    } scratch_t;
    ```

+ main-core 在完成 stack 分配後, 會對 `.bss section` 歸 0

+ 然後進行 fdt 的 重新導向, fdt 的 source address 保存在 `$a1` 中 (這個 $a1 的值從進入 OpenSBI至今, 都還保持著原先的值),
  fdt 的 destination address 則通過 macro 決定
    > 在搬運 fdt 的過程中, 首先會判斷 `$a1` 的值是否符合要求(是否存在 fdt 需要搬運), 如果`$a1 == 0` 直接跳過這一部分,

+ 搬完 fdt 後, main-core 會寫一個全域變數, 通知 slave-cores 該做的初始化已經完成, 接下來準備啟動 c call 了

+ slave-cores 接收到這個通知後, 會跳出等待循環, 並開始下一階段

+ OpenSBI assembly 的最後, 就是每個 core 去找到自己的 stack 空間, 然後把 Stack Top 設定到 `$sp` 中,
    再設定好 trap handler (CSR_Reg.mvtec), 接著就是跳轉到 核心程序入口, 如 `sbi_init()`.

+ `c code`

    ```c
    // 傳入的參數 scratch 已經在 fw_base.S 中初始化好了
    void __noreturn sbi_init(struct sbi_scratch *scratch)
    {
        bool next_mode_supported    = FALSE;
        bool coldboot           = FALSE;
        u32 hartid          = current_hartid();

        // plat 就定義在 platform 資料夾下面, 你編譯的時候指定的是哪個平台, 就看相應平台的程式碼

        const struct sbi_platform *plat = sbi_platform_ptr(scratch);

        if ((SBI_HARTMASK_MAX_BITS <= hartid) ||
            sbi_platform_hart_invalid(plat, hartid))
            sbi_hart_hang();

        switch (scratch->next_mode) {
            case PRV_M:
                next_mode_supported = TRUE;
                break;
            case PRV_S:
                if (misa_extension('S'))
                    next_mode_supported = TRUE;
                break;
            case PRV_U:
                if (misa_extension('U'))
                    next_mode_supported = TRUE;
                break;
            default:
                sbi_hart_hang();
        }

        /*
         * Only the HART supporting privilege mode specified in the
         * scratch->next_mode should be allowed to become the coldboot
         * HART because the coldboot HART will be directly jumping to
         * the next booting stage.
         *
         * We use a lottery mechanism to select coldboot HART among
         * HARTs which satisfy above condition.
         */

        /**
         *  使用原子指令避免多個 hart 的多次 cold-boot
         *  使得只有一個 hart 進行 old-boot
         */
        if (next_mode_supported && atomic_xchg(&coldboot_lottery, 1) == 0)
            coldboot = TRUE;

        /*
         * Do platform specific nascent (very early) initialization so
         * that platform can initialize platform specific per-HART CSRs
         * or per-HART devices.
         */
        if (sbi_platform_nascent_init(plat))
            sbi_hart_hang();

        /**
         *  只有一個 hart 會執行 cold-boot, 其它hart都會執行 warm-boot,
         *  warm-boot 中有個函數叫 sbi_hsm_init(), 會等待 cold-boot 完成才會繼續向下執行
         */
        if (coldboot)
            init_coldboot(scratch, hartid);
        else
            init_warmboot(scratch, hartid);
    }

    static void __noreturn init_coldboot(struct sbi_scratch *scratch, u32 hartid)
    {
        int rc;
        unsigned long *init_count;
        const struct sbi_platform *plat = sbi_platform_ptr(scratch);

        /* Note: This has to be first thing in coldboot init sequence */
        /**
         * 其實就是初始化了 hartid_to_scratch_table, 可以方便地根據 hart id 獲取相應的
         * struct sbi_scratch info
         */
        rc = sbi_scratch_init(scratch);
        if (rc)
            sbi_hart_hang();

        /* Note: This has to be second thing in coldboot init sequence */
        /**
         *  這個函數初始化了 struct sbi_domain_memregion root_fw_region;
         *  root_fw_region = {
         *      .base = scratch->fw_start,
         *      .order = log2roundup(scratch->size),
         *      .flags = 0
         *  };
         *  root_memregs[0] = root_fw_region;
         *  root_memregs[1] = {0, log2roundup(~0UL)=64,
         *                     (SBI_DOMAIN_MEMREGION_READABLE |
         *                     SBI_DOMAIN_MEMREGION_WRITEABLE |
         *                     SBI_DOMAIN_MEMREGION_EXECUTABLE)};
         *
         *  root_memregs[2] = {0, 0, 0};
         */
        /*
            struct sbi_domain root = {
                .name = "root",
                .possible_harts = &root_hmask, //記錄的就是哪些 hart 是可用的
                .regions = root_memregs,
                .system_reset_allowed = TRUE,
                .boot_harid = cold_hartid,
                .next_arg1 = scratch->next_arg1,
                .next_addr = scratch->next_addr,
                .next_mode = scratch->next_mode
            };
            最後呼叫了 sbi_domain_register 函數
        */
        rc = sbi_domain_init(scratch, hartid);
        if (rc)
            sbi_hart_hang();

        /**
         *  這裡獲得的是 scratch 空間中, 空閒空間地址相對 scratch 空間 start_base 的 offset,
         *  scratch 空間的大小是 SBI_SCRATCH_SIZE = 4KB,
         *  struct sbi_scratch 佔用的空間是 10 * __SIZEOF_POINTER__
         */
        init_count_offset = sbi_scratch_alloc_offset(__SIZEOF_POINTER__);
        if (!init_count_offset)
            sbi_hart_hang();

        /**
         *  這裡將當前 hart 的狀態設定成了 SBI_HSM_STATE_START_PENDING,
         *  將其它 hart 的狀態設定成了 SBI_HSM_STATE_STOPPED.
         *  如果當前的 hart 不是執行 cood-boot 的 hart, 就會呼叫 sbi_hsm_hart_wait(),
         *  只有當 hart 狀態被設定為 SBI_HSM_STATE_START_PENDING, 才會跳出 sbi_hsm_hart_wait().
         *  因此該函數會阻止 warm-boot 的 hart 繼續執行, 直到 cood-boot 完成並將執行 warm-boot 的 hart的狀態修改為
         *  SBI_HSM_STATE_START_PENDING
         */
        rc = sbi_hsm_init(scratch, hartid, TRUE);
        if (rc)
            sbi_hart_hang();

        /**
         *  實際上呼叫的就是 (struct sbi_platform)->platform_ops_addr->early_init()
         */
        rc = sbi_system_early_init(scratch, TRUE);
        if (rc)
            sbi_hart_hang();

        rc = sbi_hart_init(scratch, hartid, TRUE);
        if (rc)
            sbi_hart_hang();

        /**
         *  實際上呼叫的就是 (struct sbi_platform)->platform_ops_addr->console_init()
         */
        rc = sbi_console_init(scratch);
        if (rc)
            sbi_hart_hang();

        /**
         *  關於 pmu 參見
         *  https://github.com/riscv-software-src/opensbi/blob/master/docs/pmu_support.md
         */
        rc = sbi_pmu_init(scratch, TRUE);
        if (rc)
            sbi_hart_hang();

        sbi_boot_print_banner(scratch);

        /**
         *  實際上呼叫的就是 (struct sbi_platform)->platform_ops_addr->irqchip_init()
         */
        rc = sbi_irqchip_init(scratch, TRUE);
        if (rc) {
            sbi_printf("%s: irqchip init failed (error %d)\n",
                   __func__, rc);
            sbi_hart_hang();
        }

        /**
         * 實際上呼叫的就是 (struct sbi_platform)->platform_ops_addr->ipi_init()
         */
        rc = sbi_ipi_init(scratch, TRUE);
        if (rc) {
            sbi_printf("%s: ipi init failed (error %d)\n", __func__, rc);
            sbi_hart_hang();
        }

        /**
         *  static struct sbi_ipi_event_ops tlb_ops = {
         *      .name = "IPI_TLB",
         *      .update = tlb_update,
         *      .sync = tlb_sync,
         *      .process = tlb_process,
         *  };
         *  將 該變數註冊到了
         *  static const struct sbi_ipi_event_ops *ipi_ops_array[SBI_IPI_EVENT_MAX];
         *  中
         */
        rc = sbi_tlb_init(scratch, TRUE);
        if (rc) {
            sbi_printf("%s: tlb init failed (error %d)\n", __func__, rc);
            sbi_hart_hang();
        }

        /**
         *  實際上呼叫的就是 (struct sbi_platform)->platform_ops_addr->timer_init()
         */
        rc = sbi_timer_init(scratch, TRUE);
        if (rc) {
            sbi_printf("%s: timer init failed (error %d)\n", __func__, rc);
            sbi_hart_hang();
        }

        /**
         *  函數中使用到了 sbi_ecall_exts 該變數定義在
         *  build/lib/sbi/sbi_ecall_exts.c
         *  後面會介紹該檔案的生成
         */
        rc = sbi_ecall_init();
        if (rc) {
            sbi_printf("%s: ecall init failed (error %d)\n", __func__, rc);
            sbi_hart_hang();
        }

        /*
         * Note: Finalize domains after HSM initialization so that we
         * can startup non-root domains.
         * Note: Finalize domains before HART PMP configuration so
         * that we use correct domain for configuring PMP.
         */
        rc = sbi_domain_finalize(scratch, hartid);
        if (rc) {
            sbi_printf("%s: domain finalize failed (error %d)\n",
                   __func__, rc);
            sbi_hart_hang();
        }

        rc = sbi_hart_pmp_configure(scratch);
        if (rc) {
            sbi_printf("%s: PMP configure failed (error %d)\n",
                   __func__, rc);
            sbi_hart_hang();
        }

        /*
         * Note: Platform final initialization should be last so that
         * it sees correct domain assignment and PMP configuration.
         */
        rc = sbi_platform_final_init(plat, TRUE);
        if (rc) {
            sbi_printf("%s: platform final init failed (error %d)\n",
                   __func__, rc);
            sbi_hart_hang();
        }


        sbi_boot_print_general(scratch);

        sbi_boot_print_domains(scratch);

        sbi_boot_print_hart(scratch, hartid);

        wake_coldboot_harts(scratch, hartid);

        init_count = sbi_scratch_offset_ptr(scratch, init_count_offset);
        (*init_count)++;

        sbi_hsm_prepare_next_jump(scratch, hartid);

        /**
         *  從這裡切換到啟動過程的下一個階段
         */
        sbi_hart_switch_mode(hartid, scratch->next_arg1, scratch->next_addr,
                     scratch->next_mode, FALSE);
    }
    ```



## Misc

![riscv_GPRs](./flow/riscv_GPRs.jpg)<br>
Fig.  RISC-V GPRs

# Reference

+ [RISC-V CPU加電執行流程 - mkh2000 - 部落格園](https://www.cnblogs.com/mkh2000/p/15811708.html)
+ [關於risc-v啟動部分思考-騰訊雲開發者社區-騰訊雲](https://cloud.tencent.com/developer/article/1764021)
+ [articles/20220816-introduction-to-qemu-and-riscv-upstream-boot-flow.md · yjmstr/RISCV-Linux - Gitee.com](https://gitee.com/YJMSTR/riscv-linux/blob/master/articles/20220816-introduction-to-qemu-and-riscv-upstream-boot-flow.md)
+ [RISC-V 指令集架構介紹 - Integer Calling convention | Jim's Dev Blog](https://tclin914.github.io/77838749/)
+ OpenSBI
    - [opensbi firmware原始碼分析(1)\_opensbi原始碼詳解-CSDN部落格](https://blog.csdn.net/passenger12234/article/details/126182720?spm=1001.2101.3001.6650.2&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-2-126182720-blog-132554315.235%5Ev39%5Epc_relevant_anti_t3&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-2-126182720-blog-132554315.235%5Ev39%5Epc_relevant_anti_t3&utm_relevant_index=3)
    - [opensbi入門 - LightningStar - 部落格園](https://www.cnblogs.com/harrypotterjackson/p/17558399.html#_label9)

+ [詳解RISC v中斷 - LightningStar - 部落格園](https://www.cnblogs.com/harrypotterjackson/p/17548837.html)


