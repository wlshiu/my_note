Cotex M3
---
# GNU Bootstrap
+ crt is the abbreviation of c runtime


## bootstrap flow

master object file `crt1.o`, `crti.o`, `crtbegin.o`, `crtend.o`, and `crtn.o`
ps. `crti.o` and `crtbegin.o` are for initializing.
    `crtend.o` and `crtn.o` are for de-initializing.


+ C process

    ```
    crt1.o -> crti.o -> main.o -> [system_libraries] -> crtn.o
    ```

    - `crt1.o`
        ```
        $ nm /usr/lib/crt1.o
        00000000 R _IO_stdin_used
        00000000 D __data_start
                 U __libc_csu_fini
                 U __libc_csu_init
                 U __libc_start_main
        00000000 R _fp_hw
        00000000 T _start
        00000000 W data_start
                 U main
        ```

    - `crti.o`
        ```
        $ nm /usr/lib/crti.o
                 U _GLOBAL_OFFSET_TABLE_
                 w __gmon_start__
        00000000 T _fini
        00000000 T _init
        ```
    - flow
        ```
        _start
            -> __libc_start_main (initial libc)
                -> _init (setup process, e.g. setup global variables)
                   ps. _init() will put at .init section by linker

                    -> main (user object)

                        -> _fini (clean process)
                           ps. _fini() will put at .fini section by linker
        ```

+ C++ process

    ```
    crt1.o -> crtbegin.o -> main.o -> [system_libraries] -> crtend.o
    ```

    - `crtbegin.o`

    - `crtend.o`

    - flow
        ```
        _start
            -> __libc_start_main (initial glibc)
                -> _init (setup process, e.g. setup global variables)
                    -> main (user object)
                        -> _fini
        ```

# Reset

+ Core Reset
    >CM3 允許由 S/w trigger reset, 用於特殊的調試或維護目的.
    >> set `SCB->AIRCR.VECTRESET`

    > 這種 reset 的作用範圍, 覆蓋了整個 CM3 CPU 中, 除了調試邏輯之外的所有角落, 但是它**不會影響到 CM3 CPU 外部的任何電路**,
    >> SoC 上的 peripheral 和其它電路都不受影響


    - examples

        ```c
        void NVIC_CoreReset(void)
        {
            __DSB();

            // set VECTRESET
            SCB->AIRCR = ((0x5FA << SCB_AIRCR_VECTKEY_Pos)      |
                          (SCB->AIRCR & SCB_AIRCR_PRIGROUP_Msk) |
                          SCB_AIRCR_VECTRESET_Msk);
            __DSB();
            while(1);
        }
        ```

        ```asm
        __asm void NVIC_CoreReset_a(void)
        {
            LDR R0, =0xE000ED0C
            LDR R1, =0x05FA0001  // set VECTRESET
            STR R1, [R0]

            B   .
        }
        ```

+ System Reset
    >  System Reset 是會波及整個 SoC 上的電路 (它會使 CM3 CPU 把送往 System Reset 發生器的請求線置為有效)
    >> set `SCB->AIRCR.SYSRESETREQ`

    > 但是 **System Reset 發生器是由 IC Vendor 實現**, 因此不同的 IC 對 System Reset 的 response 也不同.

    - 大多數情況下, Reset 發生器在響應 SYSRESETREQ 時, 同時它也會把 CM3 CPU 的系統復位信號(SYSRESETn)設為有效, 通常 SYSRESETREQ 不應 reset 調試邏輯.
        > 這裡有一個要注意的地方, 從 SYSRESETREQ 被設為有效, 到 Reset 發生器執行 Reset 指令, 會有一個 delay time, 在此 delay time 間, CPU 仍可以響應中斷請求;
        因此最好在發出 reset request 前, 先排除中斷訊號 `__set_FAULTMASK(1);` (set FAULTMASK)

    - example

        ```c
        void NVIC_SysReset(void)
        {
            __DSB();

            SCB->AIRCR = ((0x5FA << SCB_AIRCR_VECTKEY_Pos)      |
                          (SCB->AIRCR & SCB_AIRCR_PRIGROUP_Msk) |
                          SCB_AIRCR_SYSRESETREQ_Msk);
            __DSB();
            while(1);
        }
        ```

        ```asm
        __asm void NVIC_SysReset_a(void)
        {
            LDR R0, =0xE000ED0C
            LDR R1, =0x05FA0004
            STR R1, [R0]

            B   .
        }
        ```

# Dual Core sample

[LPCOpen-keil-lpc43xx](https://github.com/micromint/LPCOpen-keil-lpc43xx)

+ architeture, no MMU (physical addrress access)
    ```
      core 0       core 1           core 2
    msgQ  |        msgQ            msgQ  |
     ^    |           ^               ^  |
     |    +-----------+               |  |
     |    | push msg                  |  |
     |    +---------------------------+  |
     +-----------------------------------+
            push msg

    ```

    - Implement IPC with message queue
    - In multi-processor case, you should select which core you want to communicate

+ code flow
    ```
    ipc_msg  <->  ipc_example (mw) <-> APP

    ipc_msg: handle msgQ push/pop, semephore from IRQ
    ipc_example: procedure register, receiving task, callback by procedure ID

    ```

    - trigger IRQ in *ipc_msg*
        ```
        void ipc_send_signal(void)
        {
            __asm__ __volatile__("dsb");
            __asm__ __volatile__("sev");
        }

        ```

        1. `DSB` (Data Synchronization Barrier)
            > The DSB operation will complete when all explicit memory accesses before this instruction have completed.

        1. `SEV` (Send Event)
            > Sends an event to all processors in a multi-processor system.

    - procedure callback in *ipc_example*
        > register callbacks by procedure ID

        ```c
        // register callback to this table by procedure ID
        static void (*cb_ipc_procedure_table[IPC_MAX_IDS]) (uint32_t);

        void* task_ipc_recv(void *argv)
        {
            ...
            if( IPC_popMsg(&msg) )
            {
                if (cb_ipc_procedure_table[msg.id])
                    cb_ipc_procedure_table[msg.id](msg.data);
            }
            ...
        }
        ```
+ ISR of FreeRTOS
    - xSemaphoreCreateBinary (more like SetEvent/WaitEvent)
        > Default is `empty` state.
          It must first be given using the xSemaphoreGive()/xSemaphoreGiveFromISR() before it can subsequently use the xSemaphoreTake().

        1. mutex v.s. binary semaphore
            > `Mutexes` include a `priority inheritance mechanism`, binary semaphores do not.
            >> The binary semaphores is the better choice for implementing synchronisation
                (between tasks or between tasks and an interrupt),
                and mutexes is the better choice for implementing simple mutual exclusion.

    - portEND_SWITCHING_ISR()
        > set PendSV to avoid others tasks interrupt with high priorities.
        >> freeze switch algorithm of the scheduler. After ISR handling, continue the scheduling algorithm

        ```
                task_cur    task_isr_handler        ISR
                    |
                    |
                    |
                    +------------------------------->|
                                                     |
                                    |<---------------+ portEND_SWITCHING_ISR
                                    |                   (freeze)
                                    |
                                    |
           continue |<--------------+
                    |
                    |

        ```

# Hard Faul Handle

> To detect problems as early as possible, all Cortex-M processors have a fault exception mechanism included.
If a fault is detected, the corresponding fault exception is triggered
and one of the fault exception handlers is executed.

You can reference [Using Cortex-M3/M4/M7 Fault Exceptions](http://www.keil.com/appnotes/docs/apnt_209.asp)


Fault Exception Handlers
------------------------
Fault exceptions trap illegal memory accesses and illegal program behavior.
The following conditions are detected by fault exception handlers:

+ UsageFault_Handler
    > It detects execution of undefined instructions,
        unaligned memory access for load/store multiple.
        When enabled, divide-by-zero and other unaligned memory accesses are detected.

+ BusFault_Handler
    > It detects memory access errors on instruction fetch, data read/write,
        interrupt vector fetch, and register stacking (save/restore) on interrupt (entry/exit).

+ MemMang_Handler
    > It detects memory access violations to regions that are defined in the Memory Management Unit (MPU).
        For example, code execution from a memory region with read/write access only.

+ HardFault_Handler
    > It is the default exception and can be triggered because of an error during exception processing,
        or because an exception cannot be managed by any other exception mechanism.


Each exception has an associated `Exception Number` (IRQ numbers) and an associated `Priority Number`.

| Exception       | Exception Number  |  Priority      | IRQ Number  |  Activation
|-----------------|-------------------|----------------|-------------|----------------------
| NMI             |     2             |      -2        |   -14       |  Asynchronous
| HardFault       |     3             |      -1        |   -13       |  Synchronous
| MemManage fault |     4             |  Configurable  |   -12       |  Synchronous
| BusFault        |     5             |  Configurable  |   -11       |  Synchronous when precise, asynchronous when imprecise.
| UsageFault      |     6             |  Configurable  |   -10       |  Synchronous

+ NMI (Non-Maskable Interrupt)
    > 是一種不能藉由 mask 機制來關閉的硬體中斷.

    - NMI 可用來通報一個不可恢復的 H/w 錯誤(e.g. system hung), 以作即時的反應處理.
        > 在某些系統, NMI 可由外部 H/w 拉 NMI pin (e.g. 按特定 hot key), 或者是由其他 processor 來觸發產生
        >> SoC 系統內, 某一 processor 無法 handle 一般 interrupt 時, 由其它 processor 觸發 NMI

        1. 無法恢復的錯誤
            > + Chipset 系統內部錯誤
            > + Memory 有損壞 (Check-Sum/ECC 錯誤)
            > + Bus 偵測到資料損壞

    - 當 NMI 收到並進入到 NMI_Handler 時, 就可在 handler 作一些debug機制
        > + Cache flush 以利開發者之後分析 memory dump,
        > + 用 ICE 去 break 在此 handler, 並即時分析系統 Status, Registers, ...etc.

+ The HardFault exception is always enabled and has a fixed priority.
    > it is higher than other interrupts and exceptions, but lower than NMI (Non-Maskable Interrupt).

+ All other fault exceptions (MemManage fault, BusFault, and UsageFault) have a programmable priority.
    > they can be enable/disable by modifying the `SCB` (System Control Block).

    - System Control Block (SCB)
        > SCB provides system implementation information, and system control.
            And it included some registers to cont control fault exceptions.

        1. CCR (Configuration and Control Register) - Address:**0xE000ED14**/RW/privileged
            > Control the behavior of the UsageFault for divideby-zero and unaligned memory accesses.

        2. SHP (System Handler Priority Registers) - Address:**0xE000ED18**/RW/privileged
            > Control the exception priority.

        3. SHCSR (System Handler Control and State Register) - Address:**0xE000ED24**/RW/privileged
            > Enables the system handlers, and indicates the pending status of the BusFault, MemManage fault, and SVC exceptions.

+ BusFaults
    > BusFaults are subdivided into two classes: synchronous and asynchronous bus faults.
        The fault handler can use the BFSR to determine whether
        faults are asynchronous (IMPRECISERR) or synchronous (PRECISERR).

    - Synchronous
        > Synchronous bus faults are also described as a precise bus faults.
            Exception is trigger immediately when fault happen.
    - Asynchronous
        > Asynchronous bus faults are described as imprecise bus faults.
            Sometiems,the processor pipeline proceeds to the subsequent instruction execution
            before the bus error response is observed. When an asynchronous bus fault is triggered,
            the BusFault exception is pended.
            If another higher priority interrupt event arrived at the same time,
            the higher priority interrupt handler is executed first,
            and then the BusFault exception takes place.


Supported Fault types
---------------------
The bit names are mapping to the bit fields of status registers

| Fault type                                               | Handler    | Status Register  | Bit Name
|----------------------------------------------------------|------------|------------------|------------
| Bus error on a vector read error                         | HardFault  |    HFSR          | VECTTBL
| Fault that is escalated to a hard fault                  | HardFault  |    HFSR          | FORCED
| Fault on breakpoint escalation                           | HardFault  |    HFSR          | DEBUGEVT
| Fault on instruction access                              | MemManage  |    MMFSR         | IACCVIOL
| Fault on direct data access                              | MemManage  |    MMFSR         | DACCVIOL
| Context stacking, because of an MPU access violation     | MemManage  |    MMFSR         | MSTKERR
| Context unstacking, because of an MPU access violation   | MemManage  |    MMFSR         | MUNSTKERR
| During lazy floating-point state preservation            | MemManage  |    MMFSR         | MLSPERR
| During exception stacking                                | BusFault   |    BFSR          | STKERR
| During exception unstacking                              | BusFault   |    BFSR          | UNSTKERR
| During instruction prefetching, precise                  | BusFault   |    BFSR          | IBUSERR
| During lazy floating-point state preservation            | BusFault   |    BFSR          | LSPERR
| Precise data access error, precise                       | BusFault   |    BFSR          | PRECISERR
| Imprecise data access error, imprecise                   | BusFault   |    BFSR          | IMPRECISERR
| Undefined instruction                                    | UsageFault |    UFSR          | UNDEFINSTR
| Attempt to enter an invalid instruction set state        | UsageFault |    UFSR          | INVSTATE
| Failed integrity check on exception return               | UsageFault |    UFSR          | INVPC
| Attempt to access a non-existing coprocessor             | UsageFault |    UFSR          | NOCPC
| Illegal unaligned load or store                          | UsageFault |    UFSR          | UNALIGNED
| Stack overflow                                           | UsageFault |    UFSR          | STKOF
| Divide By 0                                              | UsageFault |    UFSR          | DIVBYZERO


Status and address registers for fault exceptions
-------------------------------------------------

| Handler    | Status/Address Register |    Address      | Description
|------------|-------------------------|-----------------|-----------------
| HardFault  |  HFSR                   |    0xE000ED2C   |  HardFault Status Register
| MemManage  |  MMFSR                  |    0xE000ED28   |  MemManage Fault Status Register
| MemManage  |  MMFAR                  |    0xE000ED34   |  MemManage Fault Address Register
| BusFault   |  BFSR                   |    0xE000ED29   |  BusFault Status Register
| BusFault   |  BFAR                   |    0xE000ED38   |  BusFault Address Register
| UsageFault |  UFSR                   |    0xE000ED2A   |  UsageFault Status Register
| UsageFault |  AFSR                   |    0xE000ED3C   |  Auxiliary Fault Status Register. Implementation defined content
| UsageFault |  ABFSR                  |    -            |  Auxiliary BusFault Status Register. Only for Cortex-M7


Bit field of EXC_RETURN
-----------------------
When entering an exception handler, the LR register is updated to a special value
called `EXC_RETURN` with the upper 28 bits all set to 1. This value, when loaded into
the PC at the end of the exception handler execution, will cause the CPU to perform
an exception return sequence. Bit 2 of the LR register determines the used stack
before entering the exception.


|bits         |   31:28              | 27:4     | 3                    |   2          | 1        | 0
|-------------|----------------------|----------|----------------------|--------------|----------|-----------
|descriptions | EXC_RETURN indicator | reserved | return mode          | return stack | reserved | processor state
|value        |    0xF               | 0xFFFFFF | 1:thread, 0: handler | 0:MSP, 1:PSP |    0     |  1 (reserved)


Example
-------
    It base on CMSIS environment.


+ HardFault_Handler

    ```c
    typedef struct stack_frm
    {
        unsigned long   r0;
        unsigned long   r1;
        unsigned long   r2;
        unsigned long   r3;
        unsigned long   r12; // IP, Intra-Procedure-call Scratch Register
        unsigned long   lr;  // R14, link register
        unsigned long   pc;  // R15, Program Counter
        unsigned long   psr; // Program Status Register
    } stack_frm_t;

    void HardFault_Handler()
    {
        __asm volatile
        (
            "TST lr, #4          \n"
            "ITE EQ              \n"
            "MRSEQ r0, MSP       \n"
            "MRSNE r0, PSP       \n" // put stack frame start address to 1-st argument
            "MOV r1, lr          \n" // put the LR register value to 2-nd argument
            "B Hard_Fault_Handler\n" // jump to function Hard_Fault_Handler
        );
    }

    void Hard_Fault_Handler(
        unsigned long   *pStack,
        unsigned int    lr_value)
    {
        stack_frm_t     *pStack_frm = (stack_frm_t*)pStack;

        printf("[HardFault]\n");
        {
            unsigned long   cfsr = 0;
            unsigned long   bus_fault_addr = 0;
            unsigned long   mem_mgt_fault_addr = 0;

            bus_fault_addr     = SCB->BFAR;
            mem_mgt_fault_addr = SCB->MMFAR;
            cfsr               = SCB->CFSR;

            printf("- FSR/FAR:\n");
            printf("   CFSR = x%x\n", cfsr);
            printf("   HFSR = x%x\n", SCB->HFSR);
            printf("   DFSR = x%x\n", SCB->DFSR);
            printf("   AFSR = x%x\n", SCB->AFSR);

            if (cfsr & 0x0080) printf("   MMFAR = x%x\n", mem_mgt_fault_addr);
            if (cfsr & 0x8000) printf("   BFAR  = x%x\n", bus_fault_addr);
        }

        printf("- Stack frame:\n");
        printf("   R0  = x%x\n", pStack_frm->r0);
        printf("   R1  = x%x\n", pStack_frm->r1);
        printf("   R2  = x%x\n", pStack_frm->r2);
        printf("   R3  = x%x\n", pStack_frm->r3);
        printf("   R12 = x%x\n", pStack_frm->r12);
        printf("   LR  = x%x\n", pStack_frm->lr);
        printf("   PC  = x%x\n", pStack_frm->pc);
        printf("   PSR = x%x\n", pStack_frm->psr);

        __asm volatile("BKPT #01");  // set breakpoint
        while(1);
    }
    ```

    - Keil IDE

        1. set breakpoint at HardFault_Handler()

        2. check report

            > Memu `Peripherals` -> `Core Peripherals` -> `Fault Reports`

            > If the UsageFault handler is not enabled,
            a UsageFault is escalated to a Hard Fault (FORCED bit will be display).

            ```
            Fault Reports window
                        +---------------------+
                        | MemManage faults    |
                        |                     |
                        |                     |
                        +---------------------+
                        | Bus Faults          |
                        |                     |
                    +---|- IMPRECISERR        |
                    |   |                     |
                    |   +---------------------+
                    |   | UsageFaults         |
                    |   |                     |
                    |   |                     |
                    |   +---------------------+
                    |   |  Hard Faults        |
                    |   |                     |
                    |   |                     |
                    +---|-> FORCED            |
                        +---------------------+
                        |  Debug Faults       |
                        |                     |
                        |                     |
                        +---------------------+

            ```

        3. use `backtrace` to find the fault statement
            > you also can get the next instruction address by checking LR (R14, link register)

            > **Concept**
            >+ `BL` instruction, Syntax: `BL{cond}{.W} label`
            >> The `BL` instruction causes a branch to label,
                and copies the address of the next instruction
                into LR (R14, link register) for branch return.


+ Tips
    - Hard Fault Reasons

        1. Overflow
            >+ Out of array range
            >+ Out of memory
            >+ Stack overflow
            >+ Error Interrupt Handling

    - Solution

        1. Tip 1: Trace Disassembly
            > step 1. Brackpoint at HardFault_Handler()

            > step 2. Open CPU Registers Window, and get `EXC_RETURN` value at LR (Link Register)
            >>   if `0xFFFFFFE9`, check MSP (Main Stack Pointer) <br>
            >>   if `0xFFFFFFFD`, check PSP (Process Stack Pointer) <br>
            >
            > If `bit 2` of the `EXC_RETURN` is `0` then the main stack (MSP is saved) was used,
            > else the process stack (PSP is saved) was used.

            > step 3. check stack frame data from MSP/PSP in memory window
            >> We can look up PC and LR values in disassembly to map the sourece code.

            ```c
            struct stack_frame
            {
                volatile uint32_t    r0;  // Register R0
                volatile uint32_t    r1;  // Register R1
                volatile uint32_t    r2;  // Register R2
                volatile uint32_t    r3;  // Register R3
                volatile uint32_t    r12; // Register R12
                volatile uint32_t    lr;  // Link register
                volatile uint32_t    pc;  // Program counter

                union {
                    volatile uint32_t   byte;

                    struct {
                        uint32_t     IPSR : 8;  // Interrupt Program Status register (IPSR)
                        uint32_t     EPSR : 19; // Execution Program Status register (EPSR)
                        uint32_t     APSR : 5;  // Application Program Status register (APSR)
                    } bits;
                } psr; // Program status register.

            } stack_frame_t;

            // cast for getting PC and LR values
            stack_frame_t   *pStack_frm = (stack_frame_t*)pMSP; //pPSP;
            ```

            > step 4. look up Address with Disassembly

        2. Tip 2: with Keil IDE
            > step 1. brackpoint at at HardFault_Handler()

            > step 2. menu `View` -> `Call Stack Window` -> mouse right button `Show Caller Code`

            > setp 3. check the source code



# ARM registers

| Register |   Function                                         | Description
|----------|----------------------------------------------------|---------------
| R0       | general-purpose                                    | pass arguments and keep the result when return.
| R1~R7    | general-purpose (support 16/32 bits instructions)  | pass arguments to the callee
| R8~R12   | general-purpose (support **32-bit** instructions)  | pass arguments to the callee
| R11 (fp) | Frame Pointer                                      | where the stack **was**
| R12 (ip) | Scratch register / specialist use by linker        | -
| R13 (sp) | Lower end of current stack frame                   | where the stack **is**
| R14 (lr) | Link address / scratch register                    | where you **were**
| R15 (pc) | Program coutner                                    | where you **are**


+ official document
    - [Cortex-M3 Devices Generic User Guide](https://developer.arm.com/docs/dui0552/latest/preface) -> Chapter 2
    - [Cortex-M4 Devices Generic User Guide](https://developer.arm.com/docs/dui0553/latest/preface)

+ stack frame structure

    ```
               H            |<previous> | <---- SP points here before interrupt
                | SP + 0x1C |   xPSR    |
                | SP + 0x18 |    PC     |
     Decreasing | SP + 0x14 |    LR     |
      memory    | SP + 0x10 |    R12    |
      address   | SP + 0x0C |    R3     |
                | SP + 0x08 |    R2     |
                V SP + 0x04 |    R1     |
               L  SP + 0x00 |    R0     | <---- SP points here after interrupt
    ```


# Dual Core Communication (My rule)

+ Two cores are in the same memory space
+ Use bit-banding feature
    - use *atomic* to sync two cores
    - share buffer range `0x20000000 ~ 0x20000FFF`

+ architecture

    ```
    0x20000000  +--------------------------+
                | rpc_share_hdr_t          |
                |                          |
                +--------------------------+
                | rpmsg_t * max_queue_num  |
                |                          |
                |         ...              |
                |                          |
    0x20000FFF  +--------------------------+
                |                          |

    ```

    - rpc header (proprietary)
        ```
        typedef struct rpc_share_hdr
        {
            // core_0 -> core_1
            uint32_t        queue_0[4];       // bit-field (for bit-banding) to record the read/write index
            uint32_t        max_queue_0_num;  // set the max queue number by user, but the MAX = 32*4

            // core_1 -> core_0
            uint32_t        queue_1[4];       // bit-field (for bit-banding) to record the read/write index
            uint32_t        max_queue_1_num;  // set the max queue number by user, but the MAX = 32*4

            uint32_t        spin_lock[2];   // bit-field (for bit-banding) to implement spin lock with bit-banding

        } rpc_share_hdr_t;
        ```

    - rpmsg header (proprietary)
        ```
        typedef enum rpc_cmd
        {
            RPC_CMD_UNKNOWN     = 0,
            RPC_CMD_HOLLOW,

        } rpc_cmd_t;

        typedef struct rpmsg_comm
        {
            rpc_cmd_t       cmd;
            uint32_t        report_rst;
        } rpmsg_comm_t;

        typedef struct rpmsg
        {
            rpmsg_comm_t        comm;

            union {
                struct {
                    // if difference memory space, need to prepare data region in share buffer.
                    uint8_t         *pStr;
                } hollow;

                struct {
                    uint32_t    argv0;
                    uint32_t    argv1;
                    uint32_t    argv2;
                    uint32_t    argv3;
                    uint32_t    argv4;
                } def;
            };
        } rpmsg_t;
        ```


# Keil

+ definition
    - `PRAM`
        >  `0 ~ 64k` in SRAM

+ scatter file
    > [scatter-loader](http://www.keil.com/support/man/docs/armlink/armlink_deb1353594352617.htm)
    >> like link script

    - format
        ```
        LOAD_ROM_1 0x00000000 0x00010000
        {
            EXEC_ROM_1 0x00000000 0x00010000
            {
                program1.o (+RO)
            }
        }

        LOAD_ROM_2 0x40002000 0x10000
        {
            EXEC_ROM_2 0x00004000 0x1000
            {
                program1.o(+RO +RW +ZI)
            }

            CODE_1 0x00008000 OVERLAY 0x1000
            {
                code1.o(+RO +RW +ZI)
            }

            CODE_2 0x00008000 OVERLAY 0x1000
            {
                code2.o(+RO +RW +ZI)
            }
        }
        ```

        1. Load region (the root brace)
            > A load region description specifies the region of memory where its child execution regions are to be placed
            >>  [name] [placed address] [Attributes] [max range size]

            ```
            LOAD_ROM_1 0x00000000 0x00010000
            {
                [exec_ragnge 0]
                [exec_ragnge 1]
                ...
            }
            ```

        2. Execute region (sub-level in root brace)
            > An execution region description specifies the region of memory where parts of your image are to be placed at run-time
            >>  [name] [run time exec address] [Attributes] [max range size]

            ```
            EXEC_ROM_1 0x00000000 0x00010000
            {
                [symbol/object section]
                ...
            }
            ```

            1. if [run time exec address] and [placed address] are the same, skip process of moving data

        3. [attribute](http://www.keil.com/support/man/docs/armlink/armlink_pge1362075670305.htm)
            > [name] [exec address] [attribute] [data length]

            ```
            CODE_1 0x00008000 OVERLAY 0x1000
            {
                code1.o(+RO +RW +ZI)
            }
            ```

            a. `OVERLAY`
                load multiple regions at the same address, link dynamic link

            a. `FIXED`
                put to fixed address

            a. `+offset`
                to specify a load region base address, which is based on previous section end address + offset


        4. region-related symbols
            > like global verable in the img

            a. [`Load$$`](http://www.keil.com/support/man/docs/armlink/armlink_pge1362065953229.htm)
                for each execution region

            ```
            Load$$ [region_name] $$Base:        mean the load address of the region.
            Load$$ [region_name] $$Length:      mean the region length in bytes.
            Load$$ [region_name] $$Limit:       mean the address of the byte beyond the end of the execution region.
            Load$$ [region_name] $$RO$$Base:    mean the address of the RO output section in this execution region.
            ...
            ```

            a. [`Image$$`](http://www.keil.com/support/man/docs/armlink/armlink_pge1362065952432.htm)
                for each execution region

            ```
            Image$$ [region_name] $$Base:           mean the Execution address of the region.
            Image$$ [region_name] $$Length:         mean the Execution region length in bytes excluding ZI length.
            Image$$ [region_name] $$Limit:          mean the Address of the byte beyond the end of the non-ZI part of the execution region.
            Image$$ [region_name] $$RO$$Base:       mean the Execution address of the RO output section in this region.
            Image$$ [region_name] $$RO$$Length:     mean the Length of the RO output section in bytes.
            ...
            ```

            a. [`Load$$LR$$`](http://www.keil.com/support/man/docs/armlink/armlink_pge1362065953823.htm)
                for each load region

            ```
            Load$$LR$$ [load_region_name] $$Base:       mean the Address of the load region.
            Load$$LR$$ [load_region_name] $$Length:     mean the Length of the load region.
            Load$$LR$$ [load_region_name] $$Limit:      mean the Address of the byte beyond the end of the load region.
            ```

        5. section type

            a. `+RO`
                Read-Only

            a. `+RW`
                Read-and-Write

            a. `+ZI`
                Zero-Initialed

        5. [Configure user section](http://www.keil.com/support/man/docs/armlink/armlink_pge1362066000009.htm)

            a. `__attribute__((section("name")))` in C code
            ```
            int sqr(int n1) __attribute__((section("foo")));
            int sqr(int n1)
            {
                return n1*n1;
            }
            ```

            b. scatter file
            ```
            FLASH 0x24000000 0x4000000
            {
                ...

                ADDER 0x08000000
                {
                    file.o (foo)                  ; select section foo from file.o
                }
            }
            ```

    - Now, each project has self `.sct`
        1. `Option for target` -> linker -> Scatter File (edit)

+ user section name
    - in source code
        ```c
        #pragma arm section code = ".mytest"  // user RO section start
        // your source code
        #pragma arm section // user RO section end
        ```

    - in scatter file
        ```
        RW_IRAM1  0x1FFF8000  0x00008000
        { ; RW data
            *(.mytest) ; user section
            .ANY (+RW +ZI)
        }
        ```

+ ROM code (for boot)
    - function
        1. Search specific MARK ("MyChipName") in SPI Flash, and get the BINs loading table
            > header info of loading table is defined in `LoadTable.s`

        2. loading bootloader_bin to `PRAM`
        3. change remapping flag (chang memory space) and reset PC to `0x00000000` (in PRAM)
        4. enter bootloader process

    - from
        1. Progream by F/W and release BIN file
        2. conver BIN file to VHDL langage
        3. Add to boot section in a chip


+ bootloader
    - function
        1. loading target APP bin, e.g. wifi AP/SAT mode
        2. help to move ROM partition from storage
            > support booting from SPI-flash/SD/USB

        3. dynamic loading bin
            > `DLO_List.s` and `BOOTLOADER_MODE.sct`

    - from
        > ~/share/bootloader






