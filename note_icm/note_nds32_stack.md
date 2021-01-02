NDS32
---

+ Stack of FreeRTOS

```
Stack Layout:

SP_BOUND (overflow)
                   V8                                              V10
    Low |-----------------------|                       |----------------------|
        |          $FPUs        | configSUPPORT_FPU     |          $FPUs       | configSUPPORT_FPU
        |-----------------------|                       |----------------------|
        |          $SP          |  8-byte alignment     |         Dummy word   | Dummy word for 8-byte stack pointer alignment
        |-----------------------|                       |----------------------|
        |          $SP          |                       |          $IPC        |
        |-----------------------|                       |----------------------|
        |          $PSW         |                       |          $IPSW       | configSUPPORT_ZOL
        |-----------------------|                       |----------------------|
        |          $IPC         |                       |          $LB         | (ZOL)
        |-----------------------|                       |----------------------|
        |          $IPSW        |                       |          $LE         | (ZOL)
        |-----------------------|                       |----------------------|
        |          $LB          | (ZOL)                 |          $LC         | (ZOL)
        |-----------------------|                       |----------------------|
        |          $LE          | (ZOL)                 |         $IFC_LP      | configSUPPORT_IFC
        |-----------------------|                       |----------------------|
        |          $LC          | (ZOL)                 |          $R0         |
        |-----------------------|                       |----------------------|
        |          $IFC_LP      |                       |    .      |    .     |
        |-----------------------|                       |    .      |    .     |
        |             .lo       |                       | $R(10-n)  | $R(24-n) |
        |          $d1.hi       |                       |-----------|----------|
        |-----------------------|                       |    $R10   | $R24     |
        |             .lo       |                       |-----------|----------|
        |          $d0.hi       |                       |    $R15   | $R25     |
        |-----------------------|                       | (Reduced) | (full)   |
        |          $R2          |                       |----------------------|
        |-----------------------|                       |          $R28 (FP)   |
        |    .      |   .       |                       |----------------------|        ^
        |    .      |   .       |                       |          $R29 (GP)   |        |
        | $R(10-n)  | $R(26-n)  |                       |----------------------|        |
        |-----------|-----------|                       |          $R30 (LP)   |
        |    $R10   |  $R26     |                       |----------------------| ( Stack Pointer )
        |-----------|-----------|
        |    $R15   |  $R27     |
        | (Reduced) |  (full)   |
        |-----------------------|
        |          $R28 (FP)    |
        |-----------------------|
        |          $R29 (GP)    |
        |-----------------------|
        |          $R30 (LP)    |
        |-----------------------|        ^
        |          $R0          |        |
        |-----------------------|        |
        |          $R1          |
        |-----------------------| ( Stack Pointer )
   High

SP_BASE (underflow)
```


+ General Purpose Registers
   > The AndeStar 32-bit instructions can access thirty-two 32-bit General Purpose Registers (GPR) r0 to r31
   and four 32-bit User Special Registers (USR) d0.lo, d0.hi, d1.lo, and d1.hi.
   >> The four 32-bit USRs can be combined into two 64-bit accumulator registers
   and store the multiplication result of two 32-bit numbers.

Register | 32/16-bit (5) | 16-bit (4) | 16-bit (3) | Comments
 :-:     | :-:           | :-:        | :-:        | :-
r0       | a0            | h0         | o0         |
r1       | a1            | h1         | o1         |
r2       | a2            | h2         | o2         |
r3       | a3            | h3         | o3         |
r4       | a4            | h4         | o4         |
r5       | a5            | h5         | o5         | Implied register for
<space>  |               |            |            | beqs38 and bnes38
r6       | s0            | h6         | o6         | Saved by callee
r7       | s1            | h7         | o7         | Saved by callee
r8       | s2            | h8         |            | Saved by callee
r9       | s3            | h9         |            | Saved by callee
r10      | s4            | h10        |            | Saved by callee
r11      | s5            | h11        |            | Saved by callee
r12      | s6            |            |            | Saved by callee
r13      | s7            |            |            | Saved by callee
r14      | s8            |            |            | Saved by callee
r15      | ta            |            |            | Temporary register for assembler \
<space>  |               |            |            | Implied register for slt(s\|i)45, b[eq\|ne]zs8
r16      | t0            | h12        |            |　Saved by caller
r17      | t1            | h13        |            |　Saved by caller
r18      | t2            | h14        |            |　Saved by caller
r19      | t3            | h15        |            |　Saved by caller
r20      | t4            |            |            |　Saved by caller
r21      | t5            |            |            |　Saved by caller
r22      | t6            |            |            |　Saved by caller
r23      | t7            |            |            |　Saved by caller
r24      | t8            |            |            |　Saved by caller
r25      | t9            |            |            |　Saved by caller
r26      | p0            |            |            | Reserved for Privileged-mode use.
r27      | p1            |            |            | Reserved for Privileged-mode use
r28      | s9/fp         |            |            | Frame pointer / Saved by callee
r29      | gp            |            |            |　Global pointer
r30      | lp            |            |            |　Link pointer
r31      | sp            |            |            |　Stack pointer

+ Reduced Register (for save cost)
    > In this `Reduced Register` configuration, **r11-r14**, and **r16-r27** are not available

Register | 32/16-bit (5) | 16-bit (4) | 16-bit (3) | Comments
 :-:     | :-:           | :-:        | :-:        | :-
r0       | a0            | h0         | o0         |
r1       | a1            | h1         | o1         |
r2       | a2            | h2         | o2         |
r3       | a3            | h3         | o3         |
r4       | a4            | h4         | o4         |
r5       | a5            | h5         | o5         | Implied register for
<space>  |               |            |            | beqs38 and bnes38
r6       | s0            | h6         | o6         | Saved by callee
r7       | s1            | h7         | o7         | Saved by callee
r8       | s2            | h8         |            | Saved by callee
r9       | s3            | h9         |            | Saved by callee
r10      | s4            | h10        |            | Saved by callee
r15      | ta            |            |            | Temporary register for assembler \
<space>  |               |            |            | Implied register for slt(s\|i)45, b[eq\|ne]zs8
r28      | fp            |            |            | Frame pointer / Saved by callee
r29      | gp            |            |            | Global pointer
r30      | lp            |            |            | Link pointer
r31      | sp            |            |            | Stack pointer

# Calling Convention (呼叫慣例)

## definitions

+ caller v.s callee

    ```
    caller -> callee
    main() -> foo()
    ```
+ primitive type
    > C 語言的 primitive type, 指的是基本型別, e.g. int, float, double, long, ...etc.

+ FP (Frame Pointer)
    > 紀錄上一個 frame 的結束 address

    ```
    int bar()              |        stack
    {                      |    L +-----------+
        return 18;         |      |           |
    }                      |      |           | <---- sp (curr_sp)
                           |      +-----------+ <---- fp (#0 fp, alig-8bytes)
    int foo(int x, int y)  |      |           |
    {                      |      |  bar()    |
        int z = 0;         |      |           |
        z = bar();         |      +-----------+ <---- fp (#1 fp, alig-8bytes)
        z = x + y + z;     |      |           |
        return z;          |      | foo()     |
    }                      |      |           |
                           |      +-----------+ <---- fp (#2 fp, alig-8bytes)
    void main()            |      |           |
    {                      |      | main()    |
        int rst = 0;       |      |           |
        rst = foo(5, 6);   |      +-----------+ <---- msp (Main sp)
        return;            |      |           |
    }                      |      |           |
                           |    H +-----------+
                           |
    ```

+ Architecture of stack frame
    > 每個 stack frame 包含 4 個 blocks (每個 block 都是 8-bytes alignment).
    分別為 `callee-saved area`, `local variables`, `duplicate incoming arguments`, and `outgoing arguments`

    ```
    Low
        +----------------+ align(8)
        |   outgoing     |
        |   arguments    |
        +----------------+
        | padding        |
        +----------------+ align(8)
        |   duplicate    |
        |   incoming     |
        |   arguments    |
        +----------------+
        | padding        |
        +----------------+ align(8)
        |   local        |
        |   variables    |
        +----------------+
        | padding        |
        +----------------+ align(8)
        |   callee-saved |
        |   area         |
        +----------------+
        | padding        |
        +----------------+ align(8)
    High
    ```

    - callee-saved area
        > May be unnecessary under optimaization.
        > + `r6 ~ r10`, `r11 ~ r13`, `fp`, `gp`, `lp`

    - local variables
        > May be unnecessary under optimaization.
        > + Local variables
        > + Spilling variables
        >> 代表一個變數在 memory 中而不在 CPU 的 GPRs

    - duplicate incoming arguments
        > May be unnecessary under optimaization.
        > + Duplicate values passed by registers.
        >> input 變數

    - outgoing arguments
        > May be unnecessary if there is no outgoing alignments theat are placed on stack.
        > + The outgoing arguments need to be placed in reverse order.
        >> 回傳值 (return value)


## calling flow

+ Prologue
    > stack frame construction (進入 function 前)


    ```
    Low
        +---------------------+
        |                     |
        |                     |
        +---------------------+ <---- $sp = sp_2
        |       push          |
        | local variables     |
        |       and           |
        | outgoing arguments  |
        |                     |
        +---------------------+ <---- sp_1, $fp = fp_1 = sp_1
        |       push          |
        |   callee-saved      |
        |       registers     |
        |                     |
        |     fp/gp/lp        |
        |     r11 ~ r14       |
        |     r6 ~ r10        |
        +---------------------+ <---- sp_0
        |      caller's       |
        |    stack frame      |
        +---------------------+ <---- $fp = fp_0
        |                     |
        |                     |
        |                     |
        +---------------------+
    High
    ```

    - push callee-saved registers (r6 ~ r10, r11 ~ 14) 到 stack
    - push `fp` 和 `lp` 到 stack
    - 將目前的 `sp` 存到 `fp`
    - 計算 function 所需要的 stack size, e.g. local variables, outgoing arguments
    - 紀錄 enf of stack frame 的 address 到 `sp`

+ Epilogue
    > stack frame destruction (離開 function 後)

    - `sp` 退回到 callee-saved 的 address
    - pop callee-saved registers (restore GPRs)
    - 藉由 `lp` 回到 caller 的位置, caller 繼續往下執行

+ 函數變數傳遞(Passing)與回傳(Return)

    ```
    /**
     *  $r0 = c
     *  $r1 = unused
     *  $r2, $r3 = ll
     *  $r4 = f
     *  $r5 = i
     *  [$fp +0], [$fp +4] = d
     */
    double sum(char c, long long ll, float, f, int i, double d)
    {
        double  rst = 0.0f;
        rst = c + ll + f + i + d;
        return rst;
        /* $r0, $r1 = rst */
    }
    ```

    - passing

        1. `r0 ~ r5` 被 Caller 用來 passing 變數給 Callee

        1. 變數型別小於 4-bytes 時, 自動補零或擴展到 4-bytes 有號型別
            > 一個 register 至小必須要放一個參數

        1. 變數型別需要 8-bytes 時, 變數的位置會從下一個偶數編號的 registe 開始, 並佔兩個連續的 registes
            > 會有空的 register

        1. 假如變數數量超過 `r0 ~ r5`, 超過的變數則放到 Caller 的 outgoing arguments block.
        Callee 則可藉由 `fp` 或是 `sp` 來找回 (offset calculation).

        1. 假如變數型別不是 4-bytes alignment時, 無條件進位到 4-bytes alignment

        1. 非 primitive type 的變數 (structure), 會被拆分成兩部分; 優先放到 `r0 ~ r5`, 剩餘的則放到 stack

    - return

        1. 回傳值基本上都會放在 `r0` (4-bytes)

        1. 假如回傳值的型別小於 4-bytes 時, 自動補零或是擴展到 4-bytes 有號型別

        1. 假如回傳值的型別是 8-bytes 時, 則會放在 `r0` 及 `r1`

        1. 假如回傳值超過 8-bytes 時 (structure), 回傳值的 address 放到 `r0`, `r1` 則會放回傳值內第一個 member 的值
            > Caller 必須先 allocate 好回傳值的空間


## examples

+ Only callee-saved area and local variables

    ```
    int  main()         | Low
    {                   |     +---------+
        int  a, b, c;   |     |         |
        a = 66;         |     |         |
        b = 77;         |     |         | <---- $sp
        c = 88;         |     +---------+ <---- $fp -20
        c = a + b;      |     | c = 88  |
        return c;       |     +---------+ <---- $fp -16
    }                   |     | b = 77  |
                        |     +---------+ <---- $fp -12
                        |     | a = 66  |
                        |     +---------+
                        |     |         |
                        |     +---------+ <---- $fp
                        |     |         |
                        |     |         |
                        |     +---------+
                        | High
    ```

+ A case of calling a function with arguments

    ```
    int foo(int x, int y)   |           Low
    {                       |              +-------------+
        int a, b, c;        |              |             |
        a = 77;             |              |             |
        b = 88;             |         ---- +-------------+ <---- $sp
        c = a + b + x +y;   |  $fp -32 --> | y = $r1     |    ^
        return c;           |  $fp -28 --> | x = $r0     |    |
    }                       |              +-------------+    |
                            |              |             |    |
    int main()              |              +-------------+    |
    {                       |  $fp -20 --> | c = a+b+x+y |    | foo()
        int rst;            |  $fp -16 --> | b = 88      |    |
        rst = foo(55, 66);  |  $fp -12 --> | a = 77      |    |
        return 0;           |              +-------------+    |
    }                       |              |             |    |
                            |              |             |    |
                            |              +-------------+    |
                            |              | $fp'        |    v
                            |         ---- +-------------+ <---- $fp
                            |              |             |    ^
                            |  $fp' -8 --> +-------------+    |
                            |              | rst         |    |
                            |  $fp' -4 --> +-------------+    | main()
                            |              | $fp''       |    |
                            |  $fp' -0 --> +-------------+    |
                            |    $r0 = 55  | $lp         |    |
                            |    $r1 = 66  |             |    v
                            |              +-------------+ <---- $fp'
                            |              |             |
                            |              |             |
                            |        High  +-------------+
    ```

+ A case of variadic function (不定變數)

    ```
    ```



