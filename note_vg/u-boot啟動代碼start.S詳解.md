u-boot啟動代碼start.S詳解
---

+ 定義入口.
    > 由於一個可執行的Image必須有一個入口點, 並且只能有一個全局入口,
    通常這個入口放在 ROM(Flash)的0x0地址.
    因此,必須通知編譯器以使其知道這個入口,該工作可通過修改link script來完成.

+ 設置異常向量(Exception Vector).
+ 設置CPU的速度、時鐘頻率及終端控制寄存器.
+ 初始化內存控制器.
+ 將ROM中的程序複製到RAM中.
+ 初始化堆棧(stack).
+ 轉到RAM中執行,該工作可使用指令`ldr pc`來完成.

```asm
    .globl _start   //u-boot啟動入口
_start:
    b       reset   //復位向量並且跳轉到reset
    ldr     pc, _undefined_instruction
    ldr     pc, _software_interrupt
    ldr     pc, _prefetch_abort
    ldr     pc, _data_abort
    ldr     pc, _not_used
    ldr     pc, _irq            // 中斷向量
    ldr     pc, _fiq            // 中斷向量
    b       sleep_setting       // 跳轉到sleep_setting
```

系統上電或reset後,cpu的PC一般都指向0x0地址,在0x0地址上的指令是

```asm
reset:          // 復位啟動子程序

    /******** 設置CPU為SVC32模式***********/
    mrs     r0, cpsr             // 將CPSR狀態寄存器讀取,保存到R0中
    bic     r0, r0, #0x1f
    orr     r0, r0, #0xd3
    msr     cpsr, r0             // 將R0寫入狀態寄存器中
    /************** 關閉看門狗 ******************/
    ldr     r0, =pWTCON
    mov     r1, #0x0
    str     r1, [r0]
    /************** 關閉所有中斷 *****************/
    mov     r1, #0xffffffff
    ldr     r0, =INTMSK
    str     r1, [r0]
    ldr     r2, =0x7ff
    ldr     r0, =INTSUBMSK
    str     r2, [r0]
    /************** 初始化系統時鐘 *****************/
    ldr     r0, =LOCKTIME
    ldr     r1, =0xffffff
    str     r1, [r0]

clear_bss:
    ldr     r0, _bss_start      // 找到bss的起始地址
    add     r0, r0, #4          // 從bss的第一個字開始
    ldr     r1, _bss_end        // bss末尾地址
    mov     r2, #0x00000000     // 清零
clbss_l:
    str     r2, [r0]            // bss段空間地址清零循環
    add     r0, r0, #4
    cmp     r0, r1
    bne     clbss_l

/*****************
 * 關鍵的初始化子程序
 *  cpu初始化關鍵寄存器
 *  設置重要寄存器
 *  設置內存時鐘
 ************************/
cpu_init_crit:      /** flush v4 I/D caches*/
    mov     r0, #0
    mcr     p15, 0, r0, c7, c7, 0   /* flush v3/v4 cache */
    mcr     p15, 0, r0, c8, c7, 0   /* flush v4 TLB */
/************* disable MMU stuff and caches ****************/
    mrc     p15, 0, r0, c1, c0, 0
    bic     r0, r0, #0x00002300     @ clear bits 13, 9:8 (--V- --RS)
    bic     r0, r0, #0x00000087     @ clear bits 7, 2:0 (B--- -CAM)
    orr     r0, r0, #0x00000002     @ set bit 2 (A) Align
    orr     r0, r0, #0x00001000     @ set bit 12 (I) I-Cache
    mcr     p15, 0, r0, c1, c0, 0

/*******
 * 在重新定位前,我們要設置RAM的時間,因為內存時鐘依賴開發板硬件的,
 * 你將會找到board目錄底下的 memsetup.S.
 **************/
    mov     ip, lr
  #ifndef CONFIG_S3C2440A_JTAG_BOOT
    bl      memsetup     // 調用 memsetup子程序(在board/smdk2442/memsetup.S)
  #endif
    mov     lr, ip
    mov     pc, lr       // 子程序返回
```


```asm
memsetup:

/**************** 初始化內存 **************/
    mov     r1, #MEM_CTL_BASE
    adrl    r2, mem_cfg_val
    add     r3, r1, #52
1:
    ldr     r4, [r2], #4
    str     r4, [r1], #4
    cmp     r1, r3
    bne     1b

/*********** 跳轉到原來進來的下一個指令(start.S文件裡) ***************/
    mov     pc, lr      // 子程序返回
```

並通過下段代碼拷貝到內存裡

```asm
relocate:               // 把uboot重新定位到RAM
    adr     r0, _start              // r0 是代碼的當前位置
    ldr     r2, _armboot_start      // r2 是armboot的開始地址
    ldr     r3, _armboot_end        // r3 是armboot的結束地址
    sub     r2, r3, r2              // r2得到armboot的大小
    ldr     r1, _TEXT_BASE          // r1 得到目標地址
    add     r2, r0, r2              // r2 得到源結束地址

copy_loop:              // 重新定位代碼
    ldmia   r0!, {r3-r10}           // 從源地址[r0]中複製
    stmia   r1!, {r3-r10}           // 複製到目標地址[r1]
    cmp     r0, r2                  // 複製數據塊直到源數據末尾地址[r2]
    ble     copy_loop

/****************** 建立堆棧 *******************/
    ldr     r0, _armboot_end            // armboot_end重定位
    add     r0, r0, #CONFIG_STACKSIZE   // 向下配置堆棧空間
    sub     sp, r0, #12                 // 為abort-stack預留個3字

/**************** 跳轉到C代碼去 **************/
    ldr     pc, _start_armboot          // 跳轉到start_armboot函數入口,start_armboot字保存函數入口指針

_start_armboot:
    .word   start_armboot       // start_armboot函數在lib_arm
```

/board.c中實現, 從此進入第二階段C語言代碼部分
