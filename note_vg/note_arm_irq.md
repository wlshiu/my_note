ARM IRQ
---

+ Instructions

    - data access

    ```
    I.   str src_register, [dest_register]
    II.  stm dest_pointer, [src_register array]
    III. ldr dest_register, [src_register] (or 立即數)  /* src_register 裡面的值給 dest_register */
    IV.  ldm src_pointer, [src_register array]
    ```

        1. stmxx and ldmxx

        ```
        stmib/ldmib : xxxIA 執行後增加 (increase after), e.g i++;
        stmia/ldmia : xxxIB 執行前增加 (increase before), e.g. ++i
        stmdb/ldmdb : xxzDA 執行後減少 (decrease after), e.g i--
        stmda/ldmda : xxxDB 執行前減少 (decrease before), e.g --i
        ```

        1. `stmda`
            > push registers to stack

        ```
        /**
         *  其中
         *  '!'         表示在操作結束後,將最後的地址寫回 r0中
         *  '{r1-r7}'   表示register list,可以包含多個寄存器,它們使用',' 隔開,如{R1,R2,R6-R9},寄存器由小到大排列
         *  '^'         為 optional 後綴, eg. 'stmda sp,{sp}^'.
         *                  允許在 user mode 或 system mode 下使用.它有以下兩個功能
         *                  1. 傳入或傳出 user mode 的 register value, 而不是當前模式的寄存器數據
         *                  2. 若 instruction 是 LDMxx 那麼除了正常的多寄存器傳送外,還將SPSR也複製到CPSR中.
         *                      這用於異常處理返回,僅在異常模式下使用.
         *
         */
        stmda r0!,{r1-r7}

        /**
         *  比如當前r0指向的內存地址是 0x1000,
         *  r0 = r0 + 4, 把r1存入 address 0x1000,
         *  r0 = r0 + 4, 然後r2存入0x1004,
         *  r0 = r0 + 4, 然後r3存入0x1008,
         *  如果是32位的處理器就是每次加4個字節,
         *  以此類推把 r1-r7按照遞增的地址存入
         */
        ```

        1. `stmdb`
            > push registers to stack

        ```
        /**
         *  其中
         *  '!'         表示在操作結束後,將最後的地址寫回 r0中
         *  '{r1-r7}'   表示register list,可以包含多個寄存器,它們使用',' 隔開,如{R1,R2,R6-R9},寄存器由小到大排列
         *  '^'         為 optional 後綴, eg. 'stmda sp,{sp}^'.
         *                  允許在 user mode 或 system mode 下使用.它有以下兩個功能
         *                  1. 傳入或傳出 user mode 的 register value, 而不是當前模式的寄存器數據
         *                  2. 若 instruction 是 LDMxx 那麼除了正常的多寄存器傳送外,還將SPSR也複製到CPSR中.
         *                      這用於異常處理返回,僅在異常模式下使用.
         *
         */
        stmdb sp!,{r0-r12,lr}

        /**
         *  含義：
         *  sp! 就是從sp的地址開始存的意思
         *  sp = sp - 4,先壓lr,sp = lr (即將lr中的內容放入sp所指的內存地址)
         *  sp = sp - 4,再壓r12,sp = r12
         *  sp = sp - 4,再壓r11,sp = r11
         *  ......
         *  sp = sp - 4,
         *  最後壓r0,sp = r0
         */
        ```

        1. `ldmia`
            > pop stack daata to registers

        ```
        /**
         *  將lr彈出接著再從 r12 到r0
         */
        ldmia sp!,{r0-r12,lr}

        /**
         *  就是恢復各個registers,其 '^' 表示會把spsr的值恢復到 cpsr中
         */
        ldmia sp!, {r0-r12,pc}^
        ```

        1. `ldr`
            > Load the register. ldr的第二個參數前面是 `=`時,表示偽指令, 否則為讀取 memory address

        ```
        /**
         *  從r1中的存儲器地址處讀取一個字,然後放入到r0中
         */
        ldr r0, [r1]
        ```

        1. `str`
            > Store to the register

        ```
        /**
         *  把r0的值寫入寄存器r1所指向的地址中
         */
        str r0, [r1]
        ```

        1. `mov`

        ```
        /* 將r2的值複製到r1中 */
        mov r1, r2

        /* 常數必須用立即數 (immediate value) 表示 */
        mov r1, #4096
        ```

    + Mathematical operators

        - `add`

        ```
        add r1, r2, #1 /* r1 = r2 + 1 */
        ```

        - `sub`

        ```
        sub r1, r2, #1 /* r1 = r2 - 1 */
        ```

    + logic operators

        - `bic`
            > AND with NOT: Rd =Rn & ~N

        ```
        ldr r1, =0b1111     /* mov r1, #0b1111 */
        ldr r2, =0b0101     /* mov r2, #0b0101 */

        bic r0, r1, r2      /* r0 = r1 & ~r2; r0 = 0b1010 */
        ```

        - `orr`
            > Rd = Rn | N
        ```
        ldr r1, =0b1111   /* mov r1, #0b1111 */
        ldr r2, =0b0101   /* mov r2, #0b0101 */

        orr r0, r1, r2  /* r0 = r1 | r2; r0 = 0b1111 */
        ```

    + Specific register

        - `msr` (general-purpose register to PSR)
            > Load an immediate value, or the contents of a general-purpose register,
                into the specified fields of a Program Status Register (PSR).
            >> move state value to status register of core

        ```
        msr cpsr, r0 /* 將r0的值餵給 cpsr */
        ```

        - `mrs` (PSR to general-purpose register)
            > Move the contents of a PSR to a general-purpose register.
            >> move status register of core to state value

        ```
         mrs r0, cpsr    /* 將 cpsr的值餵給 r0 */
        ```

        - `cpsr_cxsf`
            > fields access of cpsr (用小寫字母)
            >> 如果加後綴,那麼就代表只操作這一個區域,其他的不操作,
            避免對某些位操作而影響其他位 (auto field mask)

            1. c: control field mask byte (PSR[7:0])
            1. x: extension field mask byte (PSR[15:8])
            1. s: status field mask byte (PSR[23:16)
            1. f: flags field mask byte (PSR[31:24]).

            ```
            msr cpsr_c, #0xdf  /* 只操作 control field */
            ```

    + misc

        - `adr`
            > get address

        ```
        adr r0, _start  /* r0 <- current position of code */
        ```

        - `adr` v.s `ldr`

        ```
        ldr r0, _start  /* <鏈接時確定>從內存地址 _start 的地方把值讀入.執行這個後,r0 = 0xe1a00000 */
        adr r1, _start  /* <運行時確定>取得 _start 的地址到 r0,但是請看反編譯的結果,它是與位置無關的,其實取得的是相對的位置. */
                        /* (位置無關碼請查驗《常用交叉編譯工具整理》一篇, arm-linux-ld部分)
                         * 例如這段代碼在 0x0c008000 運行,那麼 adr r0, _start 得到 r0 = 0x0c008000
                         * 如果在地址 0 運行,就是 0x00000000 了.
                         */

        ldr r2, =_start /* <鏈接時確定>取得標號 _start 的絕對地址.
                         *  這條指令看上去只是一個指令,但是它要佔用 2 個 32bit 的空間,一條是指令,另一條是 _start 的數據
                         *  因為在編譯的時候不能確定 _start 的值,而且也不能用 mov 指令來給 r0 賦一個 32bit 的常量,所以需要
                         *  多出一個空間存放 _start 的真正數據,在這裡就是 0x0c008014, 因此可以看出,這個是絕對的尋址,
                         *  不管這段代碼在什麼地方運行,它的結果都是 r0 = 0x0c008014
                         */
        ```

# Interrupt of ARM

+ CPSR register (Current Program Status Register)

```
CPSR register (ARM9EJ-S):

<----- f ------------>            <---------------- c ----------------->
 31   30  29  28                    7   6   5   4    3    2    1    0
+---+---+---+---+---+-------------+---+---+---+----+----+----+----+----+
| N | Z | C | V | Q |............ | I | F | T | M4 | M3 | M2 | M1 | M0 |
+---+---+---+---+---+-------------+---+---+---+----+----+----+----+----+

The condition code flags-
N: 當前指令運算結果,兩個表示的有符號整數運算時,N=1 表示運算結果為負數, N=0 表示結果為正書或零
Z: Z=1 表示運算的結果為零. 對於CMP指令, Z=1 表示進行比較的兩個數大小相等
C: Carry. C=1 表示運算產生了進位
V: Overflow. V=1 表示符號為溢位
Q: Sticky overflow (ARMv5E).指示增強的 DSP 指令是否發生了溢位

The control bits-
I: disable IRQ mode (when I == 1)
F: disable FIQ mode (when F == 1)
T: current instruction mode (0 = arm mdoe, 1 = thumb mode)
M4~M0: mode bits
        b10000 User (User mode)
        b10001 FIQ (Privileged mode)
        b10010 IRQ (Privileged mode)
        b10011 Supervisor (Privileged mode)
        b10111 Data Abort (Privileged mode)
        b11011 Undefined (Privileged mode)
        b11111 System (Privileged mode)

c: control field mask byte (PSR[7:0])
x: extension field mask byte (PSR[15:8])
s: status field mask byte (PSR[23:16)
f: flags field mask byte (PSR[31:24]).
```

+ SPSR (Saved Program Status Register)
    > The register that holds the CPSR of the task immediately
    before the exception occurred that caused the switch to the current mode

+ ARM working mode
    > 不同的 working mode, 有各自專屬的 registers (為了不互相影響),
    但同時為了成本考量, 將部分的 registers 拉出來公用.
    因此公用的 registers在換 working mdoe 時,需要先做備份

| Register | User / System | FIQ      | Supervisor | Abort    | IRQ      | Undefined  |
| :-       | :-            | :-       |:-          | :-       | :-       | :-         |
| R0       | R0_usr        |          |            |          |          |            |
| R1       | R1_usr        |          |            |          |          |            |
| R2       | R2_usr        |          |            |          |          |            |
| R3       | R3_usr        |          |            |          |          |            |
| R4       | R4_usr        |          |            |          |          |            |
| R5       | R5_usr        |          |            |          |          |            |
| R6       | R6_usr        |          |            |          |          |            |
| R7       | R7_usr        |          |            |          |          |            |
| R8       | R8_usr        | R8_fiq   |            |          |          |            |
| R9       | R9_usr        | R9_fiq   |            |          |          |            |
| R10      | R10_usr       | R10_fiq  |            |          |          |            |
| R11      | R11_usr       | R11_fiq  |            |          |          |            |
| R12      | R12_usr       | R12_fiq  |            |          |          |            |
| R13(SP)  | SP_usr        | SP_fiq   | SP_svc     | SP_abt   | SP_irq   | SP_und     |
| R14(LR)  | LR_usr        | LR_fiq   | LR_svc     | LR_abt   | LR_irq   | LR_und     |
| R15(PC)  | PC_usr        |          |            |          |          |            |
| CPSR     | CPSR          |          |            |          |          |            |
| SPSR     |               | SPSR_fiq | SPSR_svc   | SPSR_abt | SPSR_irq | SPSR_und   |

ps.
1. User/System mode 兩者共用所有 registers
1. Rn_xxx 表示這個 register 是 xxx mdoe 獨自擁有的
1. Banked Register的意思是 "備份寄存器", 也就是獨立使用不與其他共用

    - User
        > User mode 是應用程序的工作模式,它運行在操作系統的 user space,
        它沒有權限去操作其它硬件資源,只能執行處理自己的數據,也不能切換到其它模式下.
        要想訪問硬件資源或切換到其它模式只能通過 SWI 或產生 exception

    - System
        > System mode 是特權模式,不受 User mode 的限制.
        **User mode和System mode共用一套寄存器**,
        OS 在該模式下可以方便的訪問 User mode 的寄存器,
        而且 OS 的一些特權任務可以使用這個模式訪問一些受控的資源.
        >> User mode 與 System mode 兩者使用相同的寄存器,**都沒有SPSR**,
        但系統模式比用戶模式有更高的權限,可以訪問所有系統資源

    - FIQ
        > 快速中斷模式是相對一般中斷模式而言的,
        它是用來處理對時間要求比較緊急的中斷請求,
        主要用於**高速數據傳輸**及通道處理中

    - IRQ
        > 一般中斷模式也叫普通中斷模式,用於處理一般的中斷請求,
        通常在H/w產生中斷信號之後自動進入該模式,
        該模式為特權模式,可以自由訪問系統硬件資源

    - Supervisor (SVC)
        > Supervisor mode 是CPU上電後默認模式,因此在該模式下主要用來做系統的初始化, SWI 處理也在該模式下.
        當 User mode 下的 application 請求使用硬件資源時,通過軟件中斷進入該模式
        >> 系統 reset 或開機, 軟中斷時進入到SVC模式下

    - Data Abort
        > Abort mdoe 用於支持虛擬內存或存儲器保護,
        當用戶程序訪問非法地址,沒有權限讀取的內存地址時,會進入該模式.
        linux下編程時經常出現的 segment fault 通常都是在該模式下拋出返回的

    - Undefined
        > Undefined mode 用於支持硬件協處理器的 S/w simulation,
        CPU 在 instruction 的譯碼階段不能識別該 instruction 操作時,會進入 Undefined mode


+ Priority

    system mode > exception mode (FIQ > IRQ) > user mode

    - IRQ priority
        1. reset (1, highest)
        2. datat abort (2)
        3. FIQ (3)
        4. IRQ (4)
        5. 預取指中止 (5)
        6. Undefined (6)
        7. SWI (7, lowest)

+ User and Privileged mode

    - User mode
        > access limited resource of system
        >> + 不能直接進行 CPU 模式的切換

        1. mode bits of CPSR
            > + `User` (user space)

        1. 任何模式下執行 SWI 指令, 都會進入 `Supervisor` 模式

    - Privileged mode
        > access fully resource of system
        >> + 可以任意地進行 CPU 模式的切換
        >> + 允許使用 `msr` and `mrs`

        1. mode bits of CPSR
            > + `FIQ` (exception)
            > + `IRQ` (exception)
            > + `Supervisor` (exception)
            >> 提供 OS 使用的一種保護模式, swi (S/w interrupt) 命令狀態
            > + `Datat Abort` (exception)
            >> 虛擬記憶體管理和記憶體資料訪問保護
            > + `Undefined` (exception)
            >> 支援通過軟體模擬硬體的協處理
            > + `System` (kernel space)


+ Instruction mode
    當 switch instruction mode 時, 不影響 ARM working mode 和 register context

    當 CPU 在處理異常時, 不管當時 CPU 處於什麼狀態, 都強制切換到 ARM instruction mode

    - ARM mode
        > 32-bits instruction set

    - Thumb mode
        > 16-bits instruction set

    - Mode change

    ```S
    /**
     *  If the LSB of Rn is '1', enter THUMB mdoe.
     *  If the LSB of Rn is '0', enter ARM mdoe.
     *  ps. ARM instructions 的 bit[0:1] 始終為 0 (cpu ignore),
     *      Thumb instructions 的 bit[0] 始終為 0 (cpu ignore)
     *      因此偷 bit[0] 來作為 flag of instruction mode
     */
    bx  Rn  /* Rn is the register of R0 ~ */
    ```


+ linux bootstrup flow

首先,ARM開發板在剛上電或 reset 後都會首先進入 SVC 即管理模式,此時程序計數器 R15-PC 值會被賦為 0x0000-0000
bootloader就是在此模式下,位於0x0000-0000的 NOR FLASH 或 SRAM 中裝載的,
因此開機或 reset 後 bootloader 會被首先執行

接著 bootloader 引導 Linux內核,
此時 Linux內核一樣運行在 ARM的 SVC即管理模式下
當內核啟動完畢,準備進入user space init進程時,
內核將 ARM的當前程序狀態 CPSR寄存器 M[4:0]設置為10000,進而user space 程序只能運行在 User mode.
由於 User mode 下對資源的訪問受限,因此可以達到保護Linux操作系統內核的目的

需要強調的是:
Linux kernel space 是從 SVC即管理模式下啟動的,但在某些情況下,
如: 硬件中斷, 程序異常(被動)等情況下進入其他特權模式,這時仍然可以進入 kernel space (因為可以操作內核了).
同樣 Linux user space 是從 user mode 啟動的,
但當進入 system mode 時,仍然可以操作Linux application program (進入user space,如init進程的啟動過程)

ps. 只要是中斷或異常發生, 就會進入 kernel space (privileged mode),
    但 user space 卻有可能在 user mode 或 system mode

+ ARM-thumb 過程調用標準

    - r0-r3 用作傳入函數參數,傳出函數返回值.
        在子程序調用之間,可以將 r0-r3 用於任何用途.
        被調用函數在返回之前不必恢復 r0-r3.
        如果調用函數需要再次使用 r0-r3 的內容,則它必須保留這些內容.
    - r4-r11 被用來存放函數的局部變量.
        如果被調用函數使用了這些寄存器,它在返回之前必須恢復這些寄存器的值.
    - r12 是內部調用暫時寄存器 ip.
        它在過程鏈接膠合代碼(例如,交互操作膠合代碼)中用於此角色.
        在過程調用之間,可以將它用於任何用途.
        被調用函數在返回之前不必恢復 r12.
    - 寄存器 r13 是棧指針 sp.
        它不能用於任何其它用途.
        sp 中存放的值在退出被調用函數時必須與進入時的值相同.
    - 寄存器 r14 是鏈接寄存器 lr.
        如果您保存了返回地址,則可以在調用之間將 r14 用於其它用途,程序返回時要恢復
    - 寄存器 r15 是程序計數器 PC.
        它不能用於任何其它用途.
    - 在中斷程序中,所有的寄存器都必須保護,編譯器會自動保護R4～R11,所以一般你自己只要在程序的開頭

    ```S
    sub lr,lr,#4
    stmfd sp!,{r0-r3,r12,lr}；
    // 保護R0～R3,R12,LR就可以了,除非你用彙編人為的去改變R4~R11的值。(具體去看UCOS os_cpu_a.S中的IRQ中斷的代碼)
    ```



