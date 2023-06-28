Semihosting
---

使用 ARM 所開發的 target system, 不一定會提供所有的 I/O device.
因此 ARM 設計了 Semihost 這種機制, 讓運行 ARM debugger (ICE) 的 Host, 可以與 target system 進行 I/O 溝通, 以利產品開發.
> e.g. 可以透過呼叫 `printf()` 將資料列印到 Host 螢幕, 而呼叫 `scanf()` 可以讀取 Host 鍵盤的輸入

```
        Target System                               Host
    +--------------------+                  +--------------------+
    | printf(...)        |                  |     Screen display |
    |     |              |   SVC handler    |             |      |
    |     +---> SVC/SWI -+<---------------->+-- Debuggr --+      |
    |                    |  by Debug Agent  |                    |
    +--------------------+                  +--------------------+
```

## Semihosting 原理

Semihost 的實作是透過使用定義好的 S/w IRQ(SVC or SWI), 使程式在執行過程中產生中斷.
一旦目標系統上的程式呼叫到對應的指令(semihosting call), 便產生軟體中斷, 接著 Debug Agent 就會負責處理此中斷, 進行與 Host 的溝通.

當 Debug Agent 處理指令時, 可以經由 SVC/SWI 的中斷編號得知, 此次的 S/w IRQ 是否屬於 semihost request.
其對應的編號可能是 `0xAB` 或 `0x123456`
> + `SVC 0x12346`
>> In ARM state for all architectures
> + `SVC 0xAB`
>> In ARM state and Thumb state, excluding ARMv6-M and ARMv7-M.
This behavior is not guaranteed on all debug targets from ARM or from third parties.
> + `BKPT 0xAB`
>> For ARMv6-M and ARMv7-M, Thumb state only.


每個 semihosting request 都有一個對應的號碼(Semihosting Operation Number), 用來表示其運作方式.
為了要區別這些不同的運作方式, ARM 定義使用 semihosting request 時,
`r0` 用來傳送此運算型態, 而`r1`則用來傳送其他的參數. 而其執行結果則透過`r0`回傳


| SVC Operation Number    | Description                                                   |
| :-                      | :-                                                            |
| SYS_OPEN (0x01)         | Open a file on the host                                       |
| SYS_CLOSE (0x02)        | Close a file on the host                                      |
| SYS_WRITEC (0x03)       | Write a character to the console                              |
| SYS_WRITE0 (0x04)       | Write a null-terminated string to the console                 |
| SYS_WRITE (0x05)        | Write to a file on the host                                   |
| SYS_READ (0x06)         | Read the contents of a file into a buffer                     |
| SYS_READC (0x07)        | Read a byte from the console                                  |
| SYS_ISERROR (0x08)      | Determine if a return code is an error                        |
| SYS_ISTTY (0x09)        | Check whether a file is connected to an interactive device    |
| SYS_SEEK (0x0A)         | Seek to a position in a file                                  |
| SYS_FLEN (0x0C)         | Return the length of a file                                   |
| SYS_TMPNAM (0x0D)       | Return a temporary name for a file                            |
| SYS_REMOVE (0x0E)       | Remove a file from the host                                   |
| SYS_RENAME (0x0F)       | Rename a file on the host                                     |
| SYS_CLOCK (0x10)        | Number of centiseconds since execution started                |
| SYS_TIME (0x11)         | Number of seconds since January 1, 1970                       |
| SYS_SYSTEM (0x12)       | Pass a command to the host command-line interpreter           |
| SYS_ERRNO (0x13)        | Get the value of the C library errno variable                 |
| SYS_GET_CMDLINE (0x15)  | Get the command-line used to call the executable              |
| SYS_HEAPINFO (0x16)     | Get the system heap parameters                                |
| SYS_ELAPSED (0x30)      | Get the number of target ticks since execution started        |
| SYS_TICKFREQ (0x31)     | Determine the tick frequency                                  |

Semihost Operation Number 的定義
> + `0x00 ~ 0x31`
>> 提供 ARM 使用, 其功能參考上表
> + `0x32 ~ 0xFF`
>> 保留以後供 ARM 使用
> + `0x100 ~ 0x1FF`
>> 保留供其他應用使用, 此部份不會被 ARM 使用, 若要開發自己的 S/w IRQ, 可以使用此部分
> + `0x200 ~ 0xFFFFFFFF`
>> 未定義, 強烈建議不要使用此部份

+ Implement

    ```c
    static inline int semihost_dbg_cmd(int cmd, void *data)
    {
        register int r0 asm ("r0");
        asm ("mov r0, %0\n\t"
             "mov r1, %1\n\t"
             "bkpt #0xAB\n\t"
             :
             : "r" (cmd), "r" (data)
             : "r0", "r1");
        return r0;
    }

    /**
     *  Semihosting OP-Code SYS_WRITE0
     */
    static inline void dbg_puts(char *str)
    {
        semihost_dbg_cmd(0x04, str);
        return;
    }

    /**
     *  Semihosting OP-Code SYS_WRITEC
     */
    static inline void dbg_putc(char c)
    {
        semihost_dbg_cmd(0x03, &c);
        return;
    }

    /**
     *  Semihosting OP-Code SYS_SYSTEM
     */
    static inline void dbg_system(char *cmd)
    {
        int data[2] = {(int)cmd, (int)strlen(cmd)};
        semihost_dbg_cmd(0x12, data);
        return;
    }

    /**
     *  實作在 newlib, 歸類到 system call
     */
    extern void initialise_monitor_handles(void);
    void main()
    {
        initialise_monitor_handles(); //  在所有 printf 之前呼叫

        printf("start .....");
    }
    ```

+ GDB configure to receive semihost commands

    ```
    (gdb) monitor arm semihosting enable
    ```

# Reference

+ [Semihosting(半主機)](http://albert-oma.blogspot.com/2012/04/semihosting.html)
+ [Semihosting - github](https://github.com/chaosAD/Semihosting/tree/master)
