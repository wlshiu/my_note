Kernel syscall
----

+ ABI: Application Binary Interface
+ OABI: Old Application Binary Interface
    > 將 syscall number 以 argument 來傳遞

+ EABI: Extend Application Binary Interface
    > EABI 是基於 OABI 上的改進, 或者說它更適合目前大多數的硬體

    - EABI 將 syscall number 保存在 r7

# ARM system-call

```
// @ arch/arm/kernel/entry-common.S

/*
 * This is the syscall table declaration for native ABI syscalls.
 * With EABI a couple syscalls are obsolete and defined as sys_ni_syscall.
 */
    syscall_table_start sys_call_table
#define COMPAT(nr, native, compat) syscall nr, native
#ifdef CONFIG_AEABI
#include <calls-eabi.S>     <---- at arch/arm/include/generated/calls-eabi.S
#else
#include <calls-oabi.S>
#endif
#undef COMPAT
    syscall_table_end sys_call_table
```

```
// at arch/arm/include/generated/calls-eabi.S

NATIVE(1, sys_exit)
NATIVE(2, sys_fork)
NATIVE(3, sys_read)
NATIVE(4, sys_write)
NATIVE(5, sys_open)
....
```

+ `syscall_table_start`
    > syscall_table_start 會接收一個參數 sym, 然後定義一個 `__sys_nr` 值為零,
    >> `.type` 表示指定符號的類型為 object

    ```asm
        /* 定義 sys_call_table, 並將 __sys_nr 清 0 */
        .macro  syscall_table_start, sym
        .equ    __sys_nr, 0     // 定義一個 __sys_nr 值為零
        .type   \sym, #object   // 表示指定符號的類型為 object
    ENTRY(\sym)                 // 定義一個全域符號
        .endm
    ```

    > 這裡的 ENTRY() 是另一個 macro, **不是 link script 的 keyword ENTRY**

    ```asm
    #define ENTRY(name)             \
        .globl name;                \
        name:
    ```

    - `syscall_table_start sys_call_table`
        > + 建立一個 **sys_call_table** 的 symbol 並使用 `.globl` 定義為全域變數.
        > + 定義一個內部 symbol `__sys_nr`, 初始化為 0,
        >> `__sys_nr` 主要用於, 後續系統呼叫好的計算和判斷


+ `NATIVE(nr, func)`
    > 兩個參數
    > + `nr` syscall-id
    > + `func` syscall-method

    ```asm
    #define NATIVE(nr, func) syscall nr, func
    ```

    - `syscall`

        ```
        .macro  syscall, nr, func
        /*
         * __sys_nr 從 0 開始, 總是指向已初始化 system call 的下一個 syscall-id,
         * 如果需要初始化的 syscall-id 小於  __sys_nr,
         * 表示和已初始化的 syscall-id 衝突 => fail
         */
        .ifgt   __sys_nr - \nr
        .error  "Duplicated/unorded system call entry"
        .endif

        /*
         * .rept (repeat)表示 .endr 之前的指令執行次數
         */
        .rept   \nr - __sys_nr

        /*
         * 放置 sys_ni_syscall 函數到當前地址 (sys_ni_syscall 為一個空函數),
         * 即如果定義的 syscall-id 之間有間隔, 填充為該函數
         */
        .long   sys_ni_syscall
        .endr  // end of .rept

        .long   \func               // 將系統呼叫函數放置在當前地址
        .equ    __sys_nr, \nr + 1   // 將 __sys_nr 更新為當前系統呼叫號 +1
        .endm
        ```

    - `calls-eabi.S`
        > 其實就是使用 NATIVE() 實現一個 sys_call_table 的 array,
        不斷在 array tail 放置 sys_ni_syscall (function pointer)


+ `syscall_table_end`
    > 傳入的參數為 sys_call_table

    ```
    // the max size of sys_call_table
    #define __NR_syscalls   400
    ```

    ```
    .macro  syscall_table_end, sym
    /*
     * __NR_syscalls 是當前系統下靜態定義的最大 syscall-id,
     * 當前初始化的 syscall-id 不能超出
     */
    .ifgt   __sys_nr - __NR_syscalls
    .error  "System call table too big"
    .endif

    .rept   __NR_syscalls - __sys_nr
    /*
     * 當前已定義 syscall-id 到最大系統呼叫之間未使用的
     * syscall-id 使用 sys_ni_syscall 這個空函數填充
     */
    .long   sys_ni_syscall
    .endr

    .size   \sym, . - \sym      // 設定 sym 也就是 sys_call_table 的 size
    .endm
    ```


## Event of system call

syscall 儘管是由 user space 產生的, 但是在日常的程式中我們並不會直接使用 syscall,
只知道在使用諸如 read/write 函數時, 對應的 syscall 就會產生, 實際上發起 syscall 的真正流程, 被封裝在 C lib 中,
要查看 syscall 的產生細節, 一方面可以查看 C lib, 另一方面也可以查看編譯時的 dissemble code

syscall 產生過程
```
user_func()(e.g open) -> __libc_open() -> svc 0 -> vector_swi -> system_call -> sys_func
```

+ glibc
    > 既然 syscall 基本都是封裝在 glibc 中, 這裡以 close 為例

    ```
    // at close.c
    int __close (int fd)
    {
        return SYSCALL_CANCEL (close,  fd);
    }
    ```

    - `SYSCALL_CANCEL`
        > 整個流程幾乎全部由 macro 實現, 直到最後的 `INTERNAL_SYSCALL_RAW` macro

        ```c
        #define INTERNAL_SYSCALL_RAW(name, err, nr, args...)  \
                ({        \
                    register int _a1 asm ("r0"), _nr asm ("r7");  \
                    LOAD_ARGS_##nr (args)     \
                    _nr = name;      \
                    asm volatile ("swi 0x0 @ syscall " #name \
                    : "=r" (_a1)    \
                    : "r" (_nr) ASM_ARGS_##nr   \
                    : "memory");    \
                    _a1; })
        ```


        1. 其中的 `swi` 指令正是執行 syscall 的 S/w interrupt 指令
            > 在新版的 ARM 架構中, 使用 `svc` 指令代替 `swi`, 這兩者只是別名的關係, 並沒有什麼區別
            > + 在 OABI 規範中, syscall-id 由 swi(or svc) 後的參數指定
            > + 在 EABI 規範中, syscall-id 則由 `r7` 進行傳遞

    - 這裡需要區分 syscall 和 call sub-function

        1. 對於 call sub-function, 前四個參數被保存在 `r0 ~ r3` 中, 其它的參數被保存在 stack 上進行傳遞.

        1. syscall 的 swi(svc)指令, 將會引起 context-switch (user -> svc), 兩者不是使用同一個 stack (sp 不同),
        因此無法用 stack 直接進行傳遞, 因而需要將所有的參數保存在 General-purpose registers 中進行傳遞
            > 在核心檔案 include/linux/syscall.h 中, 定義了 syscall 相關的函數和 macro,
            其中 `SYSCALL_DEFINE_MAXARGS` 表示 syscall 支援的最多參數值
            >> 在 arm 下為 6, 也就是 arm 中 syscall 最多支援 6 個參數, 分別保存在 `r0 ~ r5` 中


+ Kernel handle syscall
    > syscall 的處理完全不像是想像中那麼簡單, 從 user space 到 kernel space 需要經 context-switch,
    svc 指令實際上是一條軟體中斷指令, 也是從user space 到 kernel space 的唯一通路(被動可以通過中斷, 其它異常)

    - svc 指令執行 syscall 的大致流程為

        > + 執行 svc 指令, 產生軟中斷, 跳轉到系統中斷向量表的 svc ISR,
        >> 這個地址是 0xffff0008 處(也可組態在 0x00000008處), 並將 CPU 模式設定為 Privileged mode.
        > + 保存 user mode 下的程序斷點資訊, 以便 syscall 返回時可以恢復 user mode 程序的執行.
        > + 根據傳入的 syscall-id (r7) 確定 kernel 中需要執行的 syscall, e.g. read 對應 syscall_read.
        > + 執行完 syscall  後返回到 user mode 程序, 繼續執行





# Reference

+ [Linux ARM系統呼叫過程分析(二)——Linux系統呼叫流程分析](https://blog.csdn.net/u013836909/article/details/120962460?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-1-120962460-blog-120265199.235^v28^pc_relevant_t0_download&spm=1001.2101.3001.4242.2&utm_relevant_index=3)
+ [System Call (系統呼叫)](https://hackmd.io/@combo-tw/Linux-%E8%AE%80%E6%9B%B8%E6%9C%83/%2F%40combo-tw%2FBJPoAcqQS)
+ [System Call & OS架構](https://ithelp.ithome.com.tw/m/articles/10275598)
+ [Linux系統呼叫(syscall)原理](http://gityuan.com/2016/05/21/syscall/)



