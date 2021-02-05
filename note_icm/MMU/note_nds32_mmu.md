NDS32 MMU (Memory Management Unit)
---

# MMU

## TLB_DATA (TLB Access Data Register, mr3)

```
31           12   11  10    8  7  6   5   4 3    1 0
 +-----------+---------+----+---+---+---+---+----+---+
 | PPN       | Reserved| C  | G | A | X | D | M  | V |
 +-----------+---------+----+---+---+---+---+----+---+
```

+ V, bit[0], **RW**
    > Valid bit.
    表示此 Page Table Entry 是有效且存在

+ M, bit[3,1], **RW**
    > 設定這個 page 的 r/w 權限.
    > + 假如沒有 read 權限, 則會發出 `Read Protection Violation exception` (讀保護衝突).
    > + 假如沒有 write 權限, 則會發出 `Write Protection Violation exception` (寫保護衝突).

    - MMU version 1
    - MMU version 2

+ D, bit[4], **RW**
    > Dirty bit

    - `0`
        > 當儲存這個 page時, 發出 Page Modified Exception.

    - `1`
        > 發出 No Page Modified Exception


+ X, bit[5], **RW**
    > Executable bit. 這個 page 是否 executable.

    - MMU version 1
        1. `0`
            > 此 page 不是 executable, 否則會發 `Non-Executable Page exception`
        1. `1`
            > This page is executable.

    - MMU version 2


+ A, bit[6], **RW**
    > 是否要發出 `Access Bit exception`

    - `0`
        > 停止發出 `Access Bit exception`

    - `1`
        > 任何存取此 page 時, 都會發出 `Access Bit exception`

+ G, bit[7], **RW**
    > 此 page 是否共享內容 (this page is shared across contexts or not)

    - `0`
        > This page is not shared with other context
    - `1`
        > This page is shared across contexts

+ C, bit[10,8], **RW**
    > Cacheability attributes (可緩存性屬性)

    - `0`
        > device space
    - `1`
        > device space, write bufferable/coalescable
    - `2`
        > non-cacheable memory
    - `3`
        > Reserved (發出 Reserved PTE Attribute exception)
    - `4`
        > cacheable, write-back, write-allocate memory (shared)
    - `5`
        > cacheable, write-through, no-write-allocate memory(shared)
    - `6`
        > cacheable, non-shared, write-back, write allocate memory
    - `7`
        > cacheable, non-shared, write-through, no-write-allocate memory

+ PPN, bit[31,12], **RW**
    > 此 page 的 Physical Page Number


## TLB_VPN (TLB Access VPN Register, mr2)

+ VPN, bit[31,12], **RW**


# [MPU](MPU/note_mpu.md)

# reference

