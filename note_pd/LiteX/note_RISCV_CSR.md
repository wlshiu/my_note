note_RISCV_CSR
---

# Exception Debug

`CSR_mcause`/`CSR_epc`/`CSR_mtval`


## 三者的核心分工與關聯


| CSR 名稱 | 核心問題        | 硬體寫入的內容                                                                                            | 軟體(Handler)如何使用
| :-       | :-             | :-                                                                                                       | :-
| mcause   | 發生了什麼事?   | 最高位元(MSB)代表是否為中斷(1=中斷, 0=異常);其餘位元為具體的 Exception Code(例如: 2=非法指令、5=Load 存取錯誤)。 | 作為判斷依據(類似 switch-case),決定要跳轉到哪一段處理邏輯。
| mepc     | 在哪裡發生的?   | 觸發異常當下的指令記憶體位址(PC),或是中斷發生時下一條即將執行的指令位址。                                       | 1. 除錯時定位出錯的程式碼位置。
|          |                |                                                                                                          | 2. 處理完畢執行 mret 指令時,CPU 會跳回 mepc 的位址繼續執行(若是系統呼叫 ecall 或非法指令,軟體需先手動將 mepc + 4 以避免無窮迴圈)。
| mtval    | 具體的錯誤細節? |  依據 mcause 的種類,提供輔助的異常資訊(Machine Trap Value)。若該異常無需額外資訊,硬體通常會填 0。                | 配合 mcause 進行精準處理(例如缺頁異常時,直接讀取 mtval 得知是哪個虛擬位址觸發了 Page Fault,進而配置實體記憶體)。

+ `epc` 判定 `32b-instruction` or `16b-instruction`

    - `CSR_mepc` 本身紀錄的是 `Pointer` (除了 Exception_2, Illegal Instruction), 因此必然為偶數
    - 對`CSR_mepc`取值後, 是 machine-code (instruction OPCode)
        > + `32b-instruction` 的 `bit[1:0] = 0x3`
        > + `16b-instruction` 的 `bit[1:0] != 0x3`

        ```
        int     instruction_size = 4;
        if( (CSR_mepc & 0x1) == 0 ) // mecp records pointer
        {
            uint16_t    machine_code = *(volatile uint16_t*)(CSR_mepc);
            if( (machine_code & 0x3) != 0x3 )
            {
                instruction_size = 2;   // Compression Extension
            }
        }
        ```


## 實際運作的連動關係(以常見情境為例)

這三個暫存器必須一起看才有完整意義,其中 `mcause` 決定了你該如何解讀 `mepc` 和 `mtval`:

+ 非法指令 (Illegal Instruction)
    - `mcause`: `2`(Illegal instruction)。
    - `mepc`: 指向那條硬體看不懂的指令位址。
    - `mtval`: 直接存入那條非法指令的 **Binary 機器碼(Instruction bits)**(部分精簡架構可能寫 0)。
            Handler 可以直接讀取 `mtval` 進行軟體模擬(Instruction Emulation),不用再去記憶體抓一次指令。

+ 記憶體存取錯誤 / 缺頁(Page Fault / Access Fault)
    - `mcause`: `12`(Instruction page fault)、`13`(Load page fault)或 `15`(Store page fault)。
    - `mepc`: 指向正在執行 `lw`、`sw` 或取指令(Fetch)的 PC 位址。
    - `mtval`: 存入**導致出錯的那個目標記憶體位址**(Faulting virtual address)。
        > `mepc` 是**指令本身的位置**,而 `mtval` 是**指令試圖讀寫的資料位置**(若是取指令出錯,兩者通常相同)。

+ 環境呼叫(Environment Call, ecall)
    - `mcause`: `8` / `9` / `11`(視 U/S/M mode 而定)。
    - `mepc`: 指向 `ecall` 這條指令的位址。
    - `mtval`: 硬體寫入 `0`(因為不需要額外錯誤資訊,系統呼叫的參數是放在通用暫存器 `a0~a7` 中)。
        處理完畢後,OS 必須執行 `mepc = mepc + 4`,否則 `mret` 回去會再次執行同一條 `ecall`。



