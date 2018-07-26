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
                > load multiple regions at the same address, link dynamic link

            a. `FIXED`
                > put to fixed address

            a. `+offset`
                > to specify a load region base address, which is based on previous section end address + offset


        4. region-related symbols
            > like global verable in the img

            a. `Load$$`(http://www.keil.com/support/man/docs/armlink/armlink_pge1362065953229.htm)
                > for each execution region

                ```
                Load$$ [region_name] $$Base:        mean the load address of the region.
                Load$$ [region_name] $$Length:      mean the region length in bytes.
                Load$$ [region_name] $$Limit:       mean the address of the byte beyond the end of the execution region.
                Load$$ [region_name] $$RO$$Base:    mean the address of the RO output section in this execution region.
                ...

                ```

            a. `Image$$` (http://www.keil.com/support/man/docs/armlink/armlink_pge1362065952432.htm)
                > for each execution region

                ```
                Image$$ [region_name] $$Base:           mean the Execution address of the region.
                Image$$ [region_name] $$Length:         mean the Execution region length in bytes excluding ZI length.
                Image$$ [region_name] $$Limit:          mean the Address of the byte beyond the end of the non-ZI part of the execution region.
                Image$$ [region_name] $$RO$$Base:       mean the Execution address of the RO output section in this region.
                Image$$ [region_name] $$RO$$Length:     mean the Length of the RO output section in bytes.
                ...

                ```

            a. `Load$$LR$$`
                > for each load region

                ```
                Load$$LR$$ [load_region_name] $$Base:       mean the Address of the load region.
                Load$$LR$$ [load_region_name] $$Length:     mean the Length of the load region.
                Load$$LR$$ [load_region_name] $$Limit:      mean the Address of the byte beyond the end of the load region.
                ```

        5. section type
            a. `+RO`
                > Read-Only
            a. `+RW`
                > Read-and-Write
            a. `+ZI`
                > Zero-Initialed

        5. Configure user section (http://www.keil.com/support/man/docs/armlink/armlink_pge1362066000009.htm)
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


+ ROM code (for boot)
    - function
        1. Search specific MARK ("SNC7312A") in SPI Flash, and get the BINs loading table
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






