NU ARM assemble
---

# format

+ 任何彙編行都是如下架構, 註釋用 `@`，`[]`中的內容為可選, 可有可無

    ```

    [<label>:] [<instruction or directive>} @ comment
    ```

    ```asm
            .global add     @ give the symbol add external linkage
    add:
        ADD r0, r0, r1  @ add input arguments
        MOV pc, lr      @ return from subroutine
                        @ end of program
    ```

    - `@` 表示註釋從當前位置到行尾的字符.
    - `#` 註釋掉一整行.
    - `;` 新行分隔符.

+ 任何以 `:` 結尾的都被認為是一個標籤 (label), 而不一定非要在一行的開始

+ label 只能由 `a` ~ `z`, `A` ~ `Z`, `0` ~ `9`, `.`, `_` 等字符組成

    - 當標籤為 `0` ~ `9` 的數字時為局部標號，局部標籤可以重複出現

        ```asm
        1:
            subs r0,r0,#1   @ 每次循環使 r0=r0-1
            bne 1f          @ 跳轉到 1 標號去執行
                            @   標籤 + f: 在引用的地方向前的標號
                            @   標籤 + b: 在引用的地方向後的標號
                            @ 局部標號代表它所在的地址,因此也可以當作 '變量'或者 '函數' 來使用。
        ```

+ `_start`
    > 彙編程序的預設入口是 `_start` label, 用戶也可以在 link script 中用 `ENTRY` 標誌指明其它入口點.

        ```asm
            .section  .data
            < initialized data here>

            .section  .bss
            < uninitialized data here>

            .section  .text
            .globl _start      @ give the symbol add external linkage

        _start:
            <instruction code goes here>
        ```

+ macro definition

    ```asm
     .macro 宏名 參數名列表   @ 偽指令.macro定義一個宏
     body                   @ 如果在宏體中使用參數，那麼在宏體中使用該參數時添加前綴 '\'
     .endm                  @.endm表示宏結束
    ```

    ```asm
    .macro SHIFTLEFT a, b   @ name: SHIFTLEFT, arguments: a, b
    .if \b < 0              @ '\b' argument in body
    MOV \a, \a, ASR #-\b
    .exitm                  @ exit macro
    .endif
    MOV \a, \a, LSL #\b
    .endm                   @ end of macro
    ```

+ constant number
    - 十進制數以 `非0` 數字開頭,如: `123` 和 `9876`
    - 二進制數以 `0b` 開頭,其中字母也可以為大寫
    - 八進制數以 `0` 開始,如: `0456`, `0123`
    - 十六進制數以 `0x`開頭,如: `0xabcd`, `0X123f`；
    - 字符串常量需要用引號括起來,中間也可以使用轉義字符,如: "You are welcome!\n"

+ ARM引數傳遞規定
    > `R0` ~ `R3`這4個暫存器用來傳遞函式呼叫的第1到4個引數, 超出的通過堆疊來傳遞,`R0` 同時用來存放函式呼叫的`返回值`.

# instruction

    `.`開頭的都是 Assembler instruction, 就是給彙編器讀的指令, 不屬於ARM instruction set

+ `include`
    > `.include 'file'` 包含指定的頭文件, 可以把一個彙編常量定義放在頭文件中

+ `.section`
    > 自定義一個段

    ```asm
    .section .mysection     @ 自定義數據段，段名為 '.mysection'
    ```

+ `.code`, `.arm`, `.thumb`
    > 指定生成的指令集格式 32 或 16 bits

    ```asm
    .code 32  @ 使用 ARM 指令
    .arm      @ 使用 ARM 指令
        or
    .code 16  @ 使用 Thumb 指令
    .thumb    @ 使用 Thumb 指令
    ```

+ `.section`
    > 宣告某代碼區段為該 section 的

+ `.global`
    > 宣告為全域變數

+ `.align`
    > 將code對齊邊界 ,單位是2的平方

    ```asm
    .align 2  //= 2*2
    ```

+ `.equ`
    > 就如同C語言的 `#define` 一樣

    ```asm
    .equ var1 , 0x50000000
    ```

+ `.req`
    > 為寄存器定義一個別名 `[name] .req [register name]`

    ```asm
    acc .req r0
    ```

+ `.byte`
    > 定義一個字節, 並為之分配空間 `.byte expressions`

+ `.word`
    > 在記憶體中配置 4bytes 的空間,並且可以初始化數值

    ```asm
    _label:   .word   __vector_reset
    ```

+ `.short`
    > 定義一個短整型, 並為之分配空間 `.short expressions`

+ `.int`
    > 定義一個整型,並為之分配空間 `.int expressions`

+ `.long`
    > 定義一個長整型, 並為之分配空間 `.long expressions`

+ `.ascii`
    > 定義一個字符串並為之分配空間 `.ascii 'string'`

+ `.size:`
    > 設定指定符號的大小

    ```asm
    .size main, . - main  @ '.' 表示當前地址,減去 main 符號的地址為整個main函式的大小
    ```

+ `NOP`
    > 空操作, 相當於 `MOV r0, r0`

+ `str`
    > register ---> memory,
    將src暫存器的內容直搬到搬到一 memory address

    ```asm
    str   r1, [r0]          /* r1的內容值放入r0的位址 */
    str   r1, [ r0  ,#4 ]   /* r1的內容值放入r0+4的位址 */
    str   r1, [r0] , #4     /* r1的內容值放入r0的位址,並且 --> r0=r0+4 */
    ```

+ `ldr`,
    > memory ---> register, 將記憶體的內容值 LOAD 進通用暫存器 R0~R12
    >> `ldr <register> , =<expression>` 相當於 PC register 或其它寄存器的長轉移

    ```asm
    ldr  r0 , =_start    /* 將標籤所在位址放入r0  */
    ldr  r0 , = 0x123    /* 立即值放入r0 */
    ldr  r0 , [r1,#4]    /* 將 (r1+4)地址中的內容值放入r0  */
    ldr  r0, [r1],#4     /* 將 (r1+0)地址中的內容值放入r0,並且 --> r1=r1+4  */
    ```

+ `adr`
    > 將記憶體位址 LOAD 進通用暫存器 R0~R12
    >> `adr <register> <label>` 相於PC寄存器或其它寄存器的小範圍轉移

    ```asm
    adr  r0 , =_address
    ```

+ `adrl`
    > `adrl <register> <label>` 相於PC寄存器或其寄存器的中範圍轉移

+ `cmp`
    > 將 2數相減看是否為零,以此來進行比較,並且將比較結果更新至 CPSR 的零旗標

    ```asm
    cmp r1,r3
    ```

+ `bne`
    > 常與cmp搭配使用,cmp 的結果不相等才跳躍

    ```asm
    cmp   r1,r3     /* 更新至CPSR */
    bne   _main     /* 看CPSR的值決定 */
    ```

+ `beq`
    > 常與 cmp 搭配使用, cmp 的結果相等才跳躍

    ```asm
    cmp   r1,r3     /* 更新至CPSR */
    beq   _main     /* 看CPSR的值決定 */
    ```

+ `sub{s}`
    > 在尾端加 s 表示運算的結果會更新到 CPSR

    ```asm
    subs r3,r3,#1 --> 當r3-1 =0 ,CPSR 的的零旗標會變成1
    ```

+ `teq`
    > 將 2 運算元的內容值執行 XOR 運算，並且結果會更新至 CPSR 旗標位元

    ```asm
    teq r1, #0x1a
        or
    teq  r1,r2
    ```

+ `orr`
    > 將 2 運算元進行 OR 運算(orr Rd ,op1 ,op2) ,並存入目的暫存器Rd,
    其中運算元1(op1)必須是暫存器

    ```asm
    orr r1 ,r2,#3
    orr r1 ,r1,r2
    ```

+ `b{gt}`
    > 若為正數值 (代表 >0) 就進行跳轉

+ `stm` and  `ldm`
    > - `stm` (Store Multiple registers): 儲存多個暫存器的值到 mem
    > - `ldm` (Load Multiple registers): 從 mem 載入到多個暫存器

    ```asm
    STMFD(多個暫存器push到堆疊)
        stmfd r13!,{r0-r3}

    LDMFD(多個暫存器pop到堆疊)
        ldmfd r13!,{r0-r3}

    FD(Full Descending stack)：堆疊為下(低位址)增長,SP(R13)指向DATA本身
             !:指令執行完後,將地址寫回r13
    ```

# operator

+ `-` 表示取負數
+ `~`表示取補,
+ C語言中的用法相似
    - `+`, `*`, `/`, `%`
    - `>>`, `<<`
    - `|`, `&`, `^`, `!`
    - `<`, `>`, `==`, `>=`, `<=`
    - `&&`, `||`


# embedding to C

    ```c
    asm(
        "
        instruction 1 ...
        instruction 2 ...
                :
        "
        : 輸出列表
        : 輸入列表
        : 被更改的resource
        );
    ```

    ```c
       void  function(void){
             unsigned int var1= 123;
             unsigned int var2= 456;
               asm (
                    "ldr  r0 , = %0 ;"  /* %0 代表輸入參數第一項,即var1 */
                    "ldr  r1 , = %1 ;"  /* %1 代表輸入參數第二項,即var2 */
                              :
                    "\n"

                    :  無
                    : "=r" (var1) , "=r" (var2) /* 輸入為var變數 , 'r' 代表暫存器 r0~r15, '='代表唯寫 */
                     : "r0" ,"r1"               /* 表示 r0 和 r1 會被更改到 */
                );
            }

    ```

