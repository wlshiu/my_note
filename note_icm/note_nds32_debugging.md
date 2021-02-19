NDS32 Debugging
---

# Excepteions

## Reset/NMI
+ Cold Reset
+ Warm Reset
+ Non-Maskable Interrupt (NMI)

## Interrupt
+ External interrupt
+ Software interrupt
+ Performance counter interrupt
+ Local DMA interrupt

## TLB fill exception (Instruction/Data)

## PTE not present exception (Instruction/Data)
+ Non-Leaf PTE not present
+ Leaf PTE not present

## TLB miscellaneous exception
+ Read protection violation (Data)
+ Write protection violation (Data)
+ Page modified (Data)
+ Non-executable page (Instruction)
+ Access bit (Instruction/Data)
+ Reserved PTE Attribute (Instruction/Data)
+ TLB VLPT miss (Instruction/Data)

## System Call exception

## Debug exception
+ Instruction breakpoint
+ Data address & value break
+ BREAK exception
+ Hardware single stepping
+ Load/store instruction global stop

## General exception

+ Branch target alignment (Instruction) or alignment check exception (Data) exception
+ Reserved instruction exception
+ Trap exception
+ Arithmetic exception
+ Precise bus error (Instruction/Data)
    - 不存在的位址
+ Imprecise bus error (Instruction/Data)
    - 不存在的位址 (Non-existent address)
        > S/w 令 CPU 讀寫特定的 physical address 時, CPU 會將這個 physical address 填入 Address Bus, 並等待所有其他連接著 CPU 的硬體來認領並回應這個請求.
        當沒有任何硬體回應 CPU 時, CPU會觸發一個異常, 表示整個電腦系統都無法辨識上述請求的 physical address

    - Unaligned access (非對齊存取)

+ Coprocessor N not-usable exception
+ Coprocessor N-related exception
+ Privileged instruction exception
+ Reserved value exception
+ Nonexistent memory address (Instruction/Data)
+ MPZIU control (Instruction/Data)
+ Next-precise stack overflow exception
    > Stack overflow

## Machine error exception (Instruction/Data)
+ Cache locking error
+ TLB locking error
+ TLB multiple hit
+ Parity/ECC error
+ Unimplemented page size error
+ Illegal parallel memory accesses (Audio extension)
+ Local memory base setup error (for Unified Local Memory configuration)

# Priority Table

| Interruption Name (highest to lowest)                 | Vector Entry Point            |
|-------------------------------------------------------|-------------------------------|
| cold reset/warm reset                                 | Reset/NMI                     |
| Local memory base setup error - next-precise          | Machine error                 |
| Stack overflow/underflow exception - next-precise     | General exception             |
| Debug data address watchpoint - next-precise          | Debug                         |
| Debug data value watchpoint - next-precise            | Debug                         |
| Hardware single-stepping                              | Debug                         |
| NMI                                                   | Reset/NMI                     |
| External debug request (debug interrupt)              | Debug                         |
| ECC error - imprecise                                 | Machine error                 |
| Data bus error - imprecise*                           | General exception             |
| Instruction bus error - imprecise* (e.g. HW prefetch) | General exception             |
| Interrupt                                             | (Based on interrupt priority) |
| Debug instruction breakpoint                          | Debug                         |
| Instruction alignment check                           | General exception             |
| ITLB multiple hit                                     | Machine error                 |
| ITLB fill                                             | TLB fill                      |
| ITLB VLPT miss                                        | TLB VLPT miss                 |
| IPTE not present (non-leaf)                           | PTE not present               |
| IPTE not present (leaf)                               | PTE not present               |
| Reserved IPTE attribute                               | TLB misc                      |
| Instruction MPZIU control                             | General exception             |
| ITLB non-execute page                                 | TLB misc                      |
| IAccess bit                                           | TLB misc                      |
| Instruction machine error                             | Machine error                 |
| Instruction nonexistent memory address                | General exception             |
| Instruction bus error (precise)                       | General exception             |
| Reserved instruction                                  | General exception             |
| Privileged instruction                                | General exception             |
| Reserved value                                        | General exception             |
| Unimplemented page size error                         | Machine error                 |
| Break                                                 | Debug                         |
| Coprocessor                                           | General exception             |
| Trap/syscall                                          | General exception             |
| Arithmetic                                            | General exception             |
| Branch target alignment                               | General exception             |
| Debug data address watchpoint                         | Debug                         |
| Load/store instruction global stop                    | Debug                         |
| Data alignment check                                  | General exception             |
| DTLB multiple hit                                     | Machine error                 |
| DTLB fill                                             | TLB fill                      |
| DTLB VLPT miss                                        | TLB VLPT miss                 |
| DPTE not present (non-leaf)                           | PTE not present               |
| DPTE not present (leaf)                               | PTE not present               |
| Reserved DPTE attribute                               | TLB misc                      |
| Data MPZIU control                                    | General exception             |
| DTLB permission (R/W)                                 | TLB misc                      |
| Dpage modified                                        | TLB misc                      |
| DAccess bit                                           | TLB misc                      |
| Data machine error                                    | Machine error                 |
| Data nonexistent memory address                       | General exception             |
| Debug data value watchpoint - precise                 | Debug                         |
| Data bus error - precise                              | General exception             |


# Andes ICE (ICEman)

+ install

    ```
    $ cd path/BSPvXXX/ice
    $ sudo ./ICEman.sh
    ```

    - Re-connect cable

+ trigger AICE

    ```
    $ ICEman -N reset-hold-script.tpl
        Andes ICEman v4.5.3 (OpenOCD) BUILD_ID: 2019120517
        Burner listens on 2354
        Telnet port: 4444
        TCL port: 6666
        Open On-Chip Debugger 0.10.0+dev-gdb5c113 (2019-12-05-17:33)
        Licensed under GNU GPL v2
        For bug reports, read
                http://openocd.org/doc/doxygen/bugs.html
        Andes AICE-MINI v1.0.1
        There is 1 core in target
        JTAG frequency 12 MHz
        The core #0 listens on 1111.
        ICEman is ready to use.
    ```

# NDS32 Debug tips

+ NDS32 可以只 reset CPU, 且保留 GPRs (只會 reset $sp, $pc, $fp)

    ```
    # '-H': ICE 連線時, 強制 reset CPU
    $ ICEman -N reset-hold-script.tpl -H
    ```


+ 強制 Blocking 在 General Exception 的進入點
    > 無法重新編譯情況下, 且原本的 General Exception handler 會做比較多的事情, 可能會破壞當時資訊

    ```
    gdb) set *0x0=0x00d500d5
    ```

    - instruction `j8`

        ```
        opcode | offset (8-bits)
        0xd5   | 0x00
        ```

        1. example

            ```asm
            000009d2 <1>:
            1:
                b 1
            9d2:    d5 00    j8 9d2 <1>
            ```

+ 確認 ILM/DLM 是否活著
    > ILM/DLM 不通過 BUS. CPU 可以直通

    - Dump ILM/DLM memory

        ```
        gdb) x/12xw 0x00000000
        ```

+ 確認 BUS 是否活著
    > 存取掛在 Bus 上的 module

    - access Bus Ram

        ```
        gdb) x/12xw 0x60000000
        ```

    - read/write CSRs (Control and Status Registers) of H/w module

        ```
        gdb) x/12xw 0xC0001000
        ```

+ 查看 system register info

    ```
    gdb) info registers <Simple Mnemonics>
    gdb) info registers cr0
    gdb) info registers mr8
    ```


