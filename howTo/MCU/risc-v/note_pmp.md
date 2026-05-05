Physical Memory Protection (PMP)
---

# PMA (Physical Memory Attributes) vs PMP

PMA (Physical Memory Attributes) 的核心作用, 是描述實體記憶體位址空間, 各個區域的固有硬體特性.
> Hard-code configuration of Hardware layer

PMP (Physical Memory Protection)
> CPU run-time re-configurates memory regions

| 特性           | Physical Memory Attributes (PMA)  | Physical Memory Protection (PMP)
| :-:            | :-:                               | :-:
| 屬性來源       |   硬體固有特性(通常不可更改)         |  軟體配置（可由 M-mode 修改）
| 主要目的       |   確保硬體操作的正確性與一致性       |  實施安全隔離與存取控制
| 典型屬性       |   Cacheable, Atomics, Idempotency  |  R (讀), W (寫), X (執行)
| 權限執行優先序  |     通常先執行，作為底層否決權       |  在 PMA 通過後, 進一步過濾權限




# Bit-fields type in RISC-V

+ WIRI:`Write Ignore, Read Ignore`
+ WARL: `Write Any Values, Reads Legal Values Only`
+ WLRL: `Write/Read Only Legal Values`


# Concepts of PMP

PMP hardware module 被用來實作類似 `ARM TrustZone` 的安全機制,
它可以設定 `memory regions`, RISC-V 是否能做 Read/Write/Execute 操作 (在 M/S/U mode 下),
當存取設定的 memory region 時, 會觸發 exception
+ exception 1 `Instruction access fault`
    > if **Disable Executable** permission
+ exception 5 `Load access fault`
    > if **Disable Readable** permission
+ exception 7 `Store or AMO access fault`
    > if **Disable Writable** permission

PMP 預設只允許在 M-mode 下設定, 而 S/U mode 則只能執行 PMP 設定
> PMP 也支援`完全隔離 (M-mode 也被隔離且無法修改)`, 此時只能藉由 `system reset` 才能解鎖

## CSRs of PMP

### regiser `pmpcfg(i), i= 0 ~ 15` (PMP Configuration Register)

> 最多設置 **4 * 16 個 memory regions**

+ 每個 memory region 用 `8-bits pmp(i)cfg` 來配置

    ```c
    union {
        uint8_t     cfg;
        struct {
            uint8_t  R    : 1;  // Readable, 0: disable, 1: enable
            uint8_t  W    : 1;  // Writable, 0: disable, 1: enable
            uint8_t  X    : 1;  // Executable, 0: disable, 1: enable
            uint8_t  A    : 2;  // Address Matching Mode
            uint8_t       : 2;
            uint8_t  L    : 1;  // Fully isolation (M-mode MUST follow the configuration),
                                // 0: disable, 1: enable
        } cfg_b;
    } pmpicfg;
    ```

    - `A (Address Matching Mode)`
        1. `0: OFF`
            > PMP disable this region check
        1. `1: TOR (Top of Range)`
            > + range: `pmpaddr(i-1) <= target-addr < pmpaddr(i)`
            > + range: `0 <= target-addr < pmpaddr(0)`

        1. `3: NAPOT (Naturally aligned power-of-two region, region >= 8-byts)`
            > + NAPOT 模式 `只支援 region sizoe 為 2的冪次` 大小
            > + RISC-V 設計一個編碼, 用一個 register 來包含 base-address 和 address-mask

            ```
            當一個 2^k bytes 的 memory size, 讓 pmpaddr 的 LSB 有連續 (k - 3) 個 1 並緊接著一個 0.

            hardware 從 pmpaddr LSB 連續 1 的狀態, 就可以知道 addr-mask 是 ((0x1 << k) - 1),

            同時最小的 memory region 是 4-bytes, 因此將 (addr-region-base >> 2) 來節省電路

            從以上的邏輯, hardware 在判定 Address Matching 的方式為:
            1. 偵測 pmpaddr LSB 中, 連續 1 的數量為 k'
            2. addr-mask = ((0x1 << k') - 1)
            3. addr-region-base = (pmpaddr & ~((0x1 << K') - 1)) << 2
            4. 判定是否 match region
                is_matching = ((target-addr & ~addr-mask) == addr-region-base) ? true : false;


            假設 target memory region: '0x8000_0000 ~ 0x8000_0FFF' (region 2^12 byts, k=12)
            則 pmpaddr = (0x8000_0000 >> 2) | ((0x1ul << (12 - 3)) -1)
                       = 0x2000_01FF

                hardware 看到 pmpaddr (0x2000_01FF) 時,
                    從 LSB 獲得
                    1. addr-mask = (0x1 << (9 + 3)) - 1
                                 = 0xFFF
                    2. addr-region-base = (pmpaddr & ~((0x1 << 9) - 1)) << 2
                                        = 0x8000_0000
                    3. is_matching = ((target-addr & ~0xFFF) == 0x8000_0000) ? true : false;
            ```

        1. `2: NA4 (Naturally aligned 4-byte region, region only 4-bytes)`
            > The specific case of NAPOT


    - `L (Locking M-Mode Permission)`
        > PMP 將 M-mode 納入 `pmp(i)cfg` 規則, 並進行隔離.
        >> 若要取消 M-mode 隔離, 必須要 `system reset`



+ 每個 `pmpcfg(i)` register 都包含 `4 個 memory region cfg`
    > 當 RV64 時, `i= 0, 2, 4, ..., 62`, 且每個 register 包含 `8 個 memory region cfg`

    ```
    union {
        uint32_t    pmpcfgi
        struct {
            pmpxcfg     pmp0cfg;
            pmpxcfg     pmp1cfg;
            pmpxcfg     pmp2cfg;
            pmpxcfg     pmp3cfg;
        } ;
    } reg_pmpcfgi;
    ```


### regiser `pmpaddr(i), i= 0 ~ 63` (PMP Address Register)

`pmpcfg(i)` 對應到 `pmpaddr(i)`







# Reference

+ `riscv-privileged-v1.10.pdf`
    - chapt `Physical Memory Protection`




