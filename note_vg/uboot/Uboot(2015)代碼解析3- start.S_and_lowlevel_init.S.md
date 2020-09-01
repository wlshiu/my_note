Uboot(2015)代碼解析3
---


# start.S

`start.S` 主要做了

> + 使 CPU 進入 SVC 模式,  禁用中斷.
> + 初始化 cp15 協處理器,  暫時關閉 MMU,  ICACHE.
> + 跳轉到`lowlevel_init.S`.
> + 最後跳轉到`_main`(位於 arch/arm/lib/crt0.S)

```c
    .globl  reset
    .globl  save_boot_params_ret
 
reset:
    /* Allow the board to save important registers */
    b   save_boot_params
save_boot_params_ret:
    /*
     * disable interrupts (FIQ and IRQ),  also set the cpu to SVC32 mode, 
     * except if in HYP mode already
     */
 
    //配置cpsr寄存器, 使CPU進入SVC模式, 同時禁用IRQ和FIQ中斷.
    mrs r0,  cpsr                                         //r0 = cpsr
    and r1,  r0,  #0x1f       @ mask mode bits             //r1 = r0 & 0x1f
    teq r1,  #0x1a       @ test for HYP mode              //if(r1 != 0x1a) {  //0x1a, HYP模式, 它比超級管理員要稍微低一點,  它主要是用來做一些虛擬化的擴展。
    bicne   r0,  r0,  #0x1f       @ clear all mode bits    //r0 = r0 & ~(0x1f)
    orrne   r0,  r0,  #0x13       @ set SVC mode           //r0 = r0 | 0x13}  //進入SVC模式
    orr r0,  r0,  #0xc0       @ disable FIQ and IRQ        //r0 |= 0xc0  //禁用IRQ和FIQ中斷
    msr cpsr, r0                                          //cpsr  =r0
 
/*
 * Setup vector:
 * (OMAP4 spl TEXT_BASE is not 32 byte aligned.
 * Continue to use ROM code vector only in OMAP4 spl)
 */
#if !(defined(CONFIG_OMAP44XX) && defined(CONFIG_SPL_BUILD))
    /* Set V=0 in CP15 SCTLR register - for VBAR to point to vector */
    mrc p15,  0,  r0,  c1,  c0,  0   @ Read CP15 SCTLR Register    // r0 = p15(0, c1, c0)
    bic r0,  #CR_V       @ V = 0                               // r0 = r0 & ~(1<<13) 
    mcr p15,  0,  r0,  c1,  c0,  0   @ Write CP15 SCTLR Register   // p15(0, c1, c0) = r0
 
    /* Set vector address in CP15 VBAR register */
    ldr r0,  =_start                       // r0 = _start
    mcr p15,  0,  r0,  c12,  c0,  0  @Set VBAR // p15(0, c12, c0) = r0
#endif
 
    /* the mask ROM code should have PLL and others stable */
#ifndef CONFIG_SKIP_LOWLEVEL_INIT
    bl  cpu_init_cp15   //初始化cp15
    bl  cpu_init_crit   //初始化時鐘
#endif
 
    bl  _main
 
/*------------------------------------------------------------------------------*/
 
ENTRY(c_runtime_cpu_setup)
/*
 * If I-cache is enabled invalidate it
 */
#ifndef CONFIG_SYS_ICACHE_OFF
    mcr p15,  0,  r0,  c7,  c5,  0   @ invalidate icache        // p15(0, c7, c5) = r0
    mcr     p15,  0,  r0,  c7,  c10,  4  @ DSB                  // p15(0, c7, c10) = r0
    mcr     p15,  0,  r0,  c7,  c5,  4   @ ISB                  // p15(0, c7, c5) = r0
#endif
 
    bx  lr                                                 // goto lr
 
ENDPROC(c_runtime_cpu_setup)
 
/*************************************************************************
 *
 * void save_boot_params(u32 r0,  u32 r1,  u32 r2,  u32 r3)
 *  __attribute__((weak));
 *
 * Stack pointer is not yet initialized at this moment
 * Don't save anything to stack even if compiled with -O0
 *
 *************************************************************************/
ENTRY(save_boot_params)
    b   save_boot_params_ret        @ back to my caller
ENDPROC(save_boot_params)
    .weak   save_boot_params
 
/*************************************************************************
 *
 * cpu_init_cp15
 *
 * Setup CP15 registers (cache,  MMU,  TLBs). The I-cache is turned on unless
 * CONFIG_SYS_ICACHE_OFF is defined.
 *
 *************************************************************************/
ENTRY(cpu_init_cp15)
    /*
     * Invalidate L1 I/D
     */
    mov r0,  #0          @ set up for MCR               //r0 = 0
    mcr p15,  0,  r0,  c8,  c7,  0   @ invalidate TLBs      //p15(0, c8, c7) = r0
    mcr p15,  0,  r0,  c7,  c5,  0   @ invalidate icache    //p15(0, c7, c5) = r0
    mcr p15,  0,  r0,  c7,  c5,  6   @ invalidate BP array  //p15(0, c7, c5) = r0
    mcr     p15,  0,  r0,  c7,  c10,  4  @ DSB              //p15(0, c7, c10) = r0
    mcr     p15,  0,  r0,  c7,  c5,  4   @ ISB              //p15(0, c7, c5) =r0
 
    /*
     * disable MMU stuff and caches
     */
    mrc p15,  0,  r0,  c1,  c0,  0                            //r0 = p15(0, c1, c0)
    bic r0,  r0,  #0x00002000 @ clear bits 13 (--V-)       //r0 = r0 & ~(0x00002000)
    bic r0,  r0,  #0x00000007 @ clear bits 2:0 (-CAM)      //r0 = r0 & ~(0x00000007)
    orr r0,  r0,  #0x00000002 @ set bit 1 (--A-) Align     //r0 = r0 | (0x00000002)
    orr r0,  r0,  #0x00000800 @ set bit 11 (Z---) BTB      //r0 = r0 | (0x00000800)
#ifdef CONFIG_SYS_ICACHE_OFF
    bic r0,  r0,  #0x00001000 @ clear bit 12 (I) I-cache   //r0 = r0 & ~(0x00001000)
#else
    orr r0,  r0,  #0x00001000 @ set bit 12 (I) I-cache     //r0 = r0 | 0x00001000
#endif
    mcr p15,  0,  r0,  c1,  c0,  0                            //p15(0, c1, c0) = r0
 
#ifdef CONFIG_ARM_ERRATA_716044
    mrc p15,  0,  r0,  c1,  c0,  0   @ read system control register     //r0 = p15(0, c1, c0)
    orr r0,  r0,  #1 << 11    @ set bit #11                          //r0 = r0 | (1 << 11)
    mcr p15,  0,  r0,  c1,  c0,  0   @ write system control register    //p15(0, c1, c0) = r0
#endif
 
#if (defined(CONFIG_ARM_ERRATA_742230) || defined(CONFIG_ARM_ERRATA_794072))
    mrc p15,  0,  r0,  c15,  c0,  1  @ read diagnostic register         //r0 = p15(0, c15, c0)
    orr r0,  r0,  #1 << 4     @ set bit #4                           //r0 = r0 | (1 << 4)
    mcr p15,  0,  r0,  c15,  c0,  1  @ write diagnostic register        //p15(0, c15, c0) = r0
#endif
 
#ifdef CONFIG_ARM_ERRATA_743622
    mrc p15,  0,  r0,  c15,  c0,  1  @ read diagnostic register         //r0 = p15(0, c15, c0)
    orr r0,  r0,  #1 << 6     @ set bit #6                           //r0 = r0 | (1 << 6)
    mcr p15,  0,  r0,  c15,  c0,  1  @ write diagnostic register        //p15(0, c15, c0) = r0
#endif
 
#ifdef CONFIG_ARM_ERRATA_751472
    mrc p15,  0,  r0,  c15,  c0,  1  @ read diagnostic register         //r0 = p15(0, c15, c0)
    orr r0,  r0,  #1 << 11    @ set bit #11                          //r0 = r0 | (1 << 11)
    mcr p15,  0,  r0,  c15,  c0,  1  @ write diagnostic register        //p15(0, c15, c0) = r0
#endif
#ifdef CONFIG_ARM_ERRATA_761320
    mrc p15,  0,  r0,  c15,  c0,  1  @ read diagnostic register         //r0 = p15(0, c15, c0)
    orr r0,  r0,  #1 << 21    @ set bit #21                          //r0 = r0 | (1 << 21)
    mcr p15,  0,  r0,  c15,  c0,  1  @ write diagnostic register        //p15(0, c15, c0) = r0
#endif
#ifdef CONFIG_ARM_ERRATA_845369
    mrc p15,  0,  r0,  c15,  c0,  1  @ read diagnostic register         //r0 = p15(0, c15, c0)
    orr r0,  r0,  #1 << 22    @ set bit #22                          //r0 = r0 | (1 << 22)
    mcr p15,  0,  r0,  c15,  c0,  1  @ write diagnostic register        //p15(0, c15, c0) = r0
#endif
 
    mov r5,  lr          @ Store my Caller                                  //r5 = lr
    mrc p15,  0,  r1,  c0,  c0,  0   @ r1 has Read Main ID Register (MIDR)      //r1 = p15(0, c0, c0)
    mov r3,  r1,  lsr #20     @ get variant field                            //r3 = (r1 >> 20)
    and r3,  r3,  #0xf        @ r3 has CPU variant                           //r3 = r3 & 0xf
    and r4,  r1,  #0xf        @ r4 has CPU revision                          //r4 = r1 & 0xf
    mov r2,  r3,  lsl #4      @ shift variant field for combined value       //r2 = (r3 << 4)
    orr r2,  r4,  r2      @ r2 has combined CPU variant + revision           //r2 = r4 | r2
 
#ifdef CONFIG_ARM_ERRATA_798870
    cmp r2,  #0x30       @ Applies to lower than R3p0                     //if(r2 >= 0x30) 
    bge skip_errata_798870      @ skip if not affected rev               //  goto skip_errata_798870
    cmp r2,  #0x20       @ Applies to including and above R2p0            //if(r2 < 0x20)
    blt skip_errata_798870      @ skip if not affected rev               //  goto skip_errata_798870
 
    mrc p15,  1,  r0,  c15,  c0,  0  @ read l2 aux ctrl reg                   //r0 = p15(1, c15, c0)
    orr r0,  r0,  #1 << 7         @ Enable hazard-detect timeout           //r0 = r0 | (1 << 7)
    push    {r1-r5}         @ Save the cpu info registers                //sp = {r1-r5}
    bl  v7_arch_cp15_set_l2aux_ctrl                                      //v7_arch_cp15_set_l2aux_ctrl();
    isb             @ Recommended ISB after l2actlr update               //指令同步隔離。最嚴格：它會清洗流水線,  以保證所有它前面的指令都執行
    pop {r1-r5}         @ Restore the cpu info - fall through            //{r1-r5} = sp
skip_errata_798870:
#endif
 
#ifdef CONFIG_ARM_ERRATA_454179
    cmp r2,  #0x21       @ Only on < r2p1                                 //if(r2 >= 0x21)
    bge skip_errata_454179                                               //goto skip skip_errata_454179
 
    mrc p15,  0,  r0,  c1,  c0,  1   @ Read ACR                               //r0 = p15(0, c1, c0)
    orr r0,  r0,  #(0x3 << 6) @ Set DBSM(BIT7) and IBE(BIT6) bits          //r0 = r0 | (0x3 << 6)
    push    {r1-r5}         @ Save the cpu info registers                //sp = {r1-r5}
    bl  v7_arch_cp15_set_acr                                             //v7_arch_cp15_set_acr();
    pop {r1-r5}         @ Restore the cpu info - fall through            //{r1-r5} = sp
 
skip_errata_454179:
#endif
 
#ifdef CONFIG_ARM_ERRATA_430973
    cmp r2,  #0x21       @ Only on < r2p1                                 //if(r2 >= 0x21)
    bge skip_errata_430973                                               //goto skip_errata_430973
 
    mrc p15,  0,  r0,  c1,  c0,  1   @ Read ACR                               //r0 = p15(0, c1, c0)
    orr r0,  r0,  #(0x1 << 6) @ Set IBE bit                                //r0 = r0 | (0x1 << 6)
    push    {r1-r5}         @ Save the cpu info registers                //sp = {r1-r5}
    bl  v7_arch_cp15_set_acr                                             //v7_arch_cp15_set_acr();
    pop {r1-r5}         @ Restore the cpu info - fall through            //{r1-r5} = sp
 
skip_errata_430973:
#endif
 
#ifdef CONFIG_ARM_ERRATA_621766
    cmp r2,  #0x21       @ Only on < r2p1                                     //if(r2 >= 0x21)
    bge skip_errata_621766                                                   //goto skip_errata_621766
 
    mrc p15,  0,  r0,  c1,  c0,  1   @ Read ACR                                   //r0 = p15(0, c1, c0)
    orr r0,  r0,  #(0x1 << 5) @ Set L1NEON bit                                 //r0 = r0 | (0x1 << 5)
    push    {r1-r5}         @ Save the cpu info registers                    //sp = {r1-r5}
    bl  v7_arch_cp15_set_acr                                                 //v7_arch_cp15_set_acr();
    pop {r1-r5}         @ Restore the cpu info - fall through                //{r1-r5} = sp
 
skip_errata_621766:
#endif
 
    mov pc,  r5          @ back to my caller                                  //pc = r5 返回調用者處
ENDPROC(cpu_init_cp15)
 
#ifndef CONFIG_SKIP_LOWLEVEL_INIT
/*************************************************************************
 *
 * CPU_init_critical registers
 *
 * setup important registers
 * setup memory timing
 *
 *************************************************************************/
ENTRY(cpu_init_crit)
    /*
     * Jump to board specific initialization...
     * The Mask ROM will have already initialized
     * basic memory. Go here to bump up clock rate and handle
     * wake up conditions.
     */
    b   lowlevel_init       @ go setup pll, mux, memory  //goto lowlevel_init
```


# lowlevel_init.S

`lowlevel_init.S`主要做了

> + 設置sp臨時堆棧.
> + 做最基礎的時鐘初始化(平台相關).
> + 跳轉回`start.S`

```c
ENTRY(lowlevel_init)
    /*
     * Setup a temporary stack. Global data is not available yet.
     */
    ldr sp,  =CONFIG_SYS_INIT_SP_ADDR                               //sp = CONFIG_SYS_INIT_SP_ADDR 設置臨時堆棧, 用於c語言環境搭建
    bic sp,  sp,  #7 /* 8-byte alignment for ABI compliance */       //sp = sp & ~(0x7)             低3位清零
#ifdef CONFIG_DM
    mov r9,  #0                                                     //r9 = 0x0
#else
    /*
     * Set up global data for boards that still need it. This will be
     * removed soon.
     */
#ifdef CONFIG_SPL_BUILD
    ldr r9,  =gdata                                                //r9 = gdata        將r9設置為gdata處
#else
    sub sp,  sp,  #GD_SIZE                                          //sp = sp - GD_SIZE
    bic sp,  sp,  #7                                                //sp = sp & ~(0x7)
    mov r9,  sp                                                    //r9 = sp
#endif
#endif
    /*
     * Save the old lr(passed in ip) and the current lr to stack
     */
    push    {ip,  lr}                                              //sp = {ip, lr}
 
    /*
     * Call the very early init function. This should do only the
     * absolute bare minimum to get started. It should not:
     *
     * - set up DRAM
     * - use global_data
     * - clear BSS
     * - try to start a console
     *
     * For boards with SPL this should be empty since SPL can do all of
     * this init in the SPL board_init_f() function which is called
     * immediately after this.
     */
    bl  s_init                                                   //s_init();   //時鐘初始化(平台相關)
    pop {ip,  pc}                                                 //{ip, pc}= sp   返回 至調用者                                                                                                              
ENDPROC(lowlevel_init)
```

# reference

+ [Uboot 2015 代碼解析3 start.S lowlevel_init.S](https://blog.csdn.net/a827143452/article/details/89413228)
