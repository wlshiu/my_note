此部分由 Gimini 產生,未驗證
---


在 Verilator (litex_sim) 中為真實的 picorv32.v 實現 GDB Step-by-Step 除錯, 核心架構是：
在 SoC 中新增第二組 UART 專門傳輸 GDB 協定封包, 並在裸機程式中嵌入一個輕量級 GDB Stub,
透過 PicoRV32 的 ebreak 中斷機制(IRQ Location 1)攔截 CPU 狀態並回傳給 GDB。

**以下是完整的硬體配置、GDB Stub 實作與除錯操作流程**


# 步驟一：在 LiteX 模擬器中新增第二組 UART (uart_gdb)


為了不讓 GDB 的控制封包($g#67、+ 等)與你程式的 printf 輸出混在一起, 我們建立一個極簡的 Python 啟動腳本 `sim_gdb.py`,
繼承自 SimSoC 並多掛載一組導向虛擬序列埠(PTY)的 uart_gdb。

在 `/home/padauk/Working/litex` 目錄下建立 `sim_gdb.py`

先執行一次產生硬體標頭檔(不啟動模擬)
```
$python3 sim_gdb.py --no-run
```


# 步驟二：撰寫 PicoRV32 專用精簡版 GDB Stub (gdb_stub.c & gdb_stub.h)

PicoRV32 的中斷向量機制如下：
當觸發 ebreak(機器碼 0x00100073)或中斷時, CPU 會跳轉到 irq_regs 儲存的暫存器上下文並進入 LiteX 的 isr() 函式。

我們可以攔截 isr(), 實作 GDB Remote Serial Protocol (RSP) 的核心指令(`?` 查詢狀態、`g/G` 讀寫暫存器、`m/M` 讀寫記憶體、`Z0/z0` 設定軟體斷點、`s` 單步執行、`c` 繼續執行)。


# 步驟三：修改 demo/main.c 與 demo/Makefile 並編譯

在 main() 開頭初始化 GDB Stub 並呼叫 `GDB_BREAKPOINT()` 讓程式在進入時自動暫停, 等待電腦端的 GDB 連入：

確保 demo/Makefile 的 OBJECTS 變數把 gdb_stub.o 加進去(例如 OBJECTS = isr.o gdb_stub.o main.o), 然後指向剛剛生成的 build/sim_gdb 進行編譯


# 步驟四：啟動模擬器並連接 GDB 進行 Step-by-Step 除錯

1. 啟動 sim_gdb.py(第一個終端機)

    ```
    $ python3 sim_gdb.py
    ```

    啟動後, 終端機上方會印出第二組 UART 分配到的虛擬序列埠路徑

    ```
    [serial2pty] serial_gdb -> /dev/pts/4
    ```


    往下捲動到 `litex>` 提示字元後, 輸入 serialboot 或在 sim_gdb.py 的 Builder 加上 `--ram-init`(或直接用 lxterm 載入 demo/demo.bin)：
    (小技巧：最快的載入方式是在 sim_gdb.py 的 main() 中加入 sim_config.add_module("clocker", ...)
     並直接將 demo.bin 透過 Builder 的 soc.add_ram(..., init=get_mem_data("demo/demo.bin")) 預載,
     或者啟動時直接帶參數傳遞 `--ram-init=demo/demo.bin` 給底層 Vsim 執行檔：`./build/sim_gdb/gateware/obj_dir/Vsim --ram-init=demo/demo.bin`)。

    當程式執行到 GDB_BREAKPOINT() 時, 終端機畫面會印出：

    ```
    Waiting for GDB connection on uart_gdb...
    ```

2. 啟動 riscv-none-elf-gdb 連線到 `/dev/pts/4`(第二個終端機)

    ```
    $ /home/padauk/Toolchain/xpack-riscv-none-elf-gcc-11.5.0-2/bin/riscv-none-elf-gdb demo/demo.elf
    ```

    進入 (gdb) 後, 直接將 target remote 指向剛剛印出的 /dev/pts/4(無需任何中間橋接程式)：

    ```
    (gdb) set remotebaud 115200
    (gdb) target remote /dev/pts/4

    ```

    連線成功後, GDB 會立刻顯示目前停在 main() 的 GDB_BREAKPOINT() 下一行！此時你就可以自由執行：






