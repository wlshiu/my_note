ARM Memmory Barrier
---

為了提高 performance, memory data會從 physical memory 放到 cache 中,
甚至在 optimizing 時, 會更動原本 instructions的執行順序.
因此會造成寫 RAM 的指令被延遲幾個週期執行, 進而對 memory 的 program 不能即刻生效,
這會導致緊臨著的下一條指令仍然使用舊的 memory data.

為解決此問題, ARM 提供了 Memmory Barrier 的指令

+ ARM instruction

    - Data Memory Barrier (DMB)
        > DMB 指令保證: 僅當所有在它前面的 RAM訪問操作都執行完畢後,
        才提交(commit)在它後面的 RAM訪問操作. 當位於此指令前的所有 RAM訪問均完成時, DMB指令才會完成.

        ```
        A Data Synchronization Barrier (DSB) completes
        when all instructions before this instruction complete.
        ```

    - Data Synchronization Barrier (DSB)
        > 數據同步隔離. 比 `DMB` 嚴格: 僅當所有在它前面的 RAM訪問操作都執行完畢後,
        才執行在它後面的指令, 即任何指令都要等待 `DSB`前面的存儲訪問完成.
        位於此指令前的所有緩存, 如分支預測和 TLB(Translation Lookaside Buffer)維護操作全部完成

        ```
        A Data Memory Barrier (DMB) ensures that all explicit memory accesses before the DMB instruction complete
        before any explicit memory accesses after the DMB instruction start.
        ```

    - Instruction Synchronization Barrier (ISB)
        > 指令同步隔離. 最嚴格: 它會沖洗流水線(Flush Pipeline)後,才會從 cache 或者 RAM 中, 預取 `ISB`指令之後的指令.
        `ISB`通常用來保證上下文切換的效果, 例如更改 ASID(Address Space Identifier), TLB維護操作,
        和 C15 register 的修改等.

        ```
        An Instruction Synchronization Barrier (ISB) flushes the pipeline in the processor,
        so that all instructions following the ISB are fetched from cache or memory,
        after the ISB has been completed.

        When changing the stack pointer, software must use an ISB instruction immediately after the MSR instruction.
        This ensures that instructions after the ISB execute using the new stack pointer.
        ```

+ 用途

    `DMB` 在雙口RAM (two-dual RAM) 以及多核架構的操作中很有用. 如果 RAM 的訪問是帶 cache 的, 並且寫完之後馬上讀,
    就必須讓它 "喘口氣" (用DMB指令來隔離), 以保證 cache 中的數據已經落實到 RAM 中. `DSB` 比 `DMB`更保險(當然也是有執行代價的),
    它是寧可錯殺也不漏網(直接 flush cache), 使得任何它後面的指令, 不管要不要使用先前的存儲器訪問結果, 通通等待訪問完成.

    強者們可以在有絕對信心時使用 `DMB`, 新手還是使用 `DSB` 比較保險.

    同`DMB`/`DSB`相比, `ISB`指令看起來似乎最強悍, 不由分說就強制 flush 所有東西.
    不過它還有其它的用場——對於高級底層技巧: `自我更新(self-mofifying)代碼`, 非常有用.
    舉例來說, 如果某個程序從下一條要執行的指令處更新了自己, 但是先前的舊指令已經被預取到流水線中去了, 此時就必須清洗流水線,
    把舊版本的指令洗出去, 再預取新版本的指令.
    因此, 必須在被更新代碼段的前面使用 `ISB`, 以保證舊的代碼從流水線中被清洗出去, 不再有機會執行(現實編程中應該極少會用到)


# reference

+ [Linux 原子操作和內存屏障](https://www.cnblogs.com/arnoldlu/p/9236300.html)
+ [ARM 確保內存訪問的有序性](https://kknews.cc/code/zy449ra.html)
+ [ARM指令之精髓DMB,DSB,ISB指令](https://blog.csdn.net/guojing3625/article/details/16877639)
