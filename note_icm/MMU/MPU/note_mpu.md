MPU (Memory Protection Unit)
----

# Difinitions

+ VPN (Virtual Page Number)
+ PFN (Page Frame Number)
+ VA (Virtual Addrress)
+ PA (Physical Addrress)


# NDS32

+ `8-entry` TLB-like structure in hardware

    - The information in the MPU TLB includes the following items
        1. Address remapping
        1. Address bound checking
        1. Cacheability attribute
        1. Accessibility attribute

+ 4KBytes alignment

+ `PSW.IT`

    - `PSW.IT == 1`
        > MPU TLB structure 會為 fetch instruction 而產生
        > + memory remapping
        > + various attributes
        > + protection information

    - `PSW.IT == 0`
        > 會關掉 instruction fetch 的 memory remapping, MMU_CTL.NTCx 被用來產生 cacheability attribute

+ `PSW.DT`

    - `PSW.DT == 1`
        > MPU TLB structure 會為 load/store instruction 而產生
        > + memory remapping
        > + various attributes
        > + protection information

    - `PSW.DT == 0`
        > 會關掉 load/store instruction 的 memory remapping, MMU_CTL.NTCx 被用來產生 cacheability attribute


## MMU_CFG (MMU Configuration Register, rc3)

+ MMPS, bit[1,0], **RO**
    > The major category for the Memory Management Protection Scheme

    - `0`  No memory management

    - `1`  Protection Unit
        > MPU type

    - `2`  TLB MMU
        > MMU tpye

    - `3`  Reserved

## [MMU](../note_nds32_mmu.md)

## MPU

`PSW.IT == 1`時, 開啟 fetch instructions MPU

`PSW.DT == 1`時, 開啟 load/store instructions (data access) MPU

### TLB_VPN (TLB Access VPN Register, mr2)

+ Hrange, bit[28,12], **RW**
    > High Range
    >> 上限是 512MB virtual address section (一個 entry 可以保護 512 MBytes)

    - 當 Load/Store/Fetch instruction 的 virtual address 大於等於 Hrange  `VA(28,12) >= Hrange(28,12)`,
    會發出 Read/Write/Execute protection exception

    - 當 write 操作時, 包含了 the MPU TLB entry 的 high virtual address limit
    - 當 read 操作時, 保持同樣的讀出


### TLB_DATA (TLB Access Data Register, mr3)

```
31           12   11  9 8  ~ 6 5 ~ 4 3 ~ 1 0
 +-----------+---------+-----+-----+-----+---+
 | PSB       | Reserved|  C  |  X  |  M  | V |
 +-----------+---------+-----+-----+-----+---+
```

+ V, bit[0], **RW**
    > This MPU Table Entry is valid and present.
    表示此 Page Table Entry 是有效且存在

+ M, bit[3,1], **RW**
    > 只能管理  load/store instructions 去存取此 page 的權限,
    不能管理 an instruction fetching and execution 的權限.

    - Reserved values (0, 4, 6)
        > 當讀出 MPU TLB entry 時, 會發出 `Reserved Attribute exception`

M[3:1]  | User mode            | Superuser mode
:-      | :-                   | :-
0       | Reserved             | Reserved
1       | Read only            | Read only
2       | Read only            | Read/Write
3       | Read/Write           | Read/Write
4       | Reserved             | Reserved
5       | No Read/Write access | Read only
6       | Reserved             | Reserved
7       | No Read/Write access | Read/Write



+ X, bit[5,4], **RW**
    > Execution permission.

Bit-5 (S)  | Bit-4 (U)  | Meaning
:-         | :-         | :-
0          | 0          | None executable page for all modes
0          | 1          | User only code (Less useful)
1          | 0          | Privileged code
1          | 1          | User code

+ C, bit[8,6], **RW**
    > Cacheability.

    - Reserved values (3)
        > 當讀出 MPU TLB entry 時, 會發出 `Reserved Attribute exception`

Encoding | Meaning
:-       | :-
0        | Device space
1        | Device space, write bufferable/coalescable
2        | Non-cacheable memory
3        | Reserved
4        | Cacheable, write-back, write-allocate memory (shared)
5        | Cacheable, write-through, no-write-allocate memory(shared)
6        | Cacheable, non-shared, write-back, write-allocate memory
7        | Cacheable, non-shared, write-through, no-write-allocate memory

+ Reserved, bit[11,9]

+ PSB, bit[31,12], **RW**
    > Physical Section Base, 4KB-align
    >> Contains the PSB field to and from the MPU TLB structure.

    - formula

        ```
        PA(31,0) = {PSB(31,12) + VA(28,12)}.VA(11,0) // what mean ??
        ```


### MPU Exceptions

Name                | Generating condition                               | Entry vector
:-                  |  :-                                                | :-
MPU TLB Invalid     | The MPU TLB entry is invalid, that is,             | TLB fill (the same entry point of the MMU TLB fill exception)
<space>             | MPU[VA(31,29)].V == 0                              |
Read protection     | The load operation has no read permission.         | TLB misc.
violation           | It can occur when there is a conflict              |
<space>             | between MPU[VA(31,29)].M                           |
<space>             | and the processor operating mode.                  |
Write protection    | The store operation has no write permission.       | TLB misc.
violation           | It can occur when there is a conflict between      |
<space>             | MPU[VA(31,29)].M and the processor operating mode. |
Non-executable code | The fetched code has no permission to be executed. | TLB misc. (the same entry point of the MMU non-executable page exception)
<space>             | It can occur when there is a conflict between      |
<space>             | MPU[VA(31,29)].X and the processor operating mode. |
Reserved attribute  | The value read out from the MPU TLB entry          | TLB misc. (the same entry point of the MMU reserved PTE attribute exception)
<space>             | MPU[VA(31,29)] contains a reserved value           |
<space>             | in C or M field.                                   |

### 配置 MPU entry

+ `__nds32__tlbop_twr`
    > TLB Target Write
    >> 假如 entry 被 lock, 會清除 lock 並複寫 entry

    ```c
    #include <nds32_intrinsic.h>
    void func(void)
    {
        unsigned int    w_num;
        ...
        /**
         * 1. 將設定資訊寫到 TLB_VPN, TLB_DATA, TLB_MISC.
         * 2. prepare write entry number into w_num.
         */

        w_num = 1;
        ...

        /* 將 TLB_VPN, TLB_DATA, TLB_MISC 推進對應的 MPU TLB entry. */
        __nds32__tlbop_twr(w_num << 29);    // Entry-Number at bit[31,29]
        __nds32__isb();                     // inst serialization barrier.
    }
    ```

+ `__nds32__tlbop_trd`
    > TLB Target Read

    ```c
    #include <nds32_intrinsic.h>
    void func(void)
    {
        unsigned int    rd_num, tlb_out;
        ...
        // prepare read entry number.
        rd_num = 4;
        ...

        /* 選擇要讀的 MPU TLB entry 並將資料放到 TLB_VPN, TLB_DATA, TLB_MISC. */
        __nds32__tlbop_trd(rd_num << 29);   // Entry-Number at bit[31,29]
        __nds32__dsb();                     // data serialization barrier.

        // move read result to tlb_out.
        tlb_out = __nds32__mfsr(NDS32_SR_TLB_VPN);
    }
    ```

- `vPortStoreTaskMPUSettings`
    > 在 task initialize 時被呼叫, 用來設定 task 需要被保護的 range

+ `vPortRestoreTaskMPU`
    > 當 Context Switch 時, 在 SWI exception 中被呼叫.
    將下一個 task 需要被保護的 range 重新設定給 H/w MPU.


+ `xPortRaisePrivilege`
    > 目的是切換成 privilege mode.

    - 利用 mfsr instruction 來確認是否為 privilege mode
        > 特權模式才能呼叫, 不然會發 `General_Exception`.

        1. 當 user mode 呼叫 `xPortRaisePrivilege` 時, 程序會跳到 `General_Exception` (Exception 必定是特權模式).
        1. 在 `General_Exception` 中判斷 IPC 是否為 `xPortRaisePrivilege` (是否從 xPortRaisePrivilege 跳進來)
            > IPC 意指 進入 Exception 前的 PC 值; IPSW 則意指 進入 Exception 前的 PSW 值
        1. 假如是從 `xPortRaisePrivilege` 進入 `General_Exception`,
            > + 則將 IPC + 4 (指到 IPC 下一行)
            > + 紀錄目前的 IPSW, 並其做為回傳值 (以便程序可以恢復到原本的模式)
            > + 將 IPSW 的 privilege mode 拉起 (離開 Exception 時, IPSW 會複寫 PSW, 就直接切換到特權模式)

        1. 假如不是從 `xPortRaisePrivilege` 進來
            > 做一般 `General_Exception` 的例外處理

+ `vPortResetPrivilege`
    > 恢復到原本的模式

+ `MPU_TLB`
    > MPU_TLB(portMPU_ENTRY(entry_id), 4KB_align(area_range), 4KB_align(PA), attribute)

    - entry_id
        > 0 ~ 7

    - portMPU_ENTRY()
        > convert entry_id to CSR format

    - PA
        > Physical Address

    - attribute
        > C/X/M/V flags


### reference

+ `3.4.2.  TLB Access VPN Register`
+ `3.4.3.  TLB Access Data Register`
+ [MIPS虛擬地址到實體地址轉換過程](https://www.itread01.com/content/1549591408.html)

