GNU ARM assemble
---

# ISA(Instruction Set Architecture) 符號定義

默認定義

+ `Rs`
    > source'or the first source operand.

+ `Rt`
    > target or the second source operand.

+ `Rd`
    > destination operand.

+ `Ra`
    > accumulate results

+ `Rn` or `Rm`
    > just mean two input registers, (n, m 通常是 `0 ~ 12`)



# format

+ 任何彙編行都是如下架構, 註釋用 `@`, `[]` or `{}`中的內容為可選, 可有可無

    ```

    [<label>:] [<instruction or directive>] @ comment
    ```

    ```asm
            .global add     @ give the symbol add external linkage
    add:
        ADD r0, r0, r1  @ add input arguments
        MOV pc, lr      @ return from subroutine
                        @ end of program
    ```

    - `;` or `@` 表示註釋從當前位置到行尾的字符.
        > 也可用 `/**/` or `//` 來註解

    - `\ ` 多行連接符

    - 可用 `#include`, `#if`, `#else`, `#endif`

+ 任何以 `:` 結尾的都被認為是一個標籤 (label), 而不一定非要在一行的開始

+ label 只能由 `a` ~ `z`, `A` ~ `Z`, `0` ~ `9`, `.`, `_` 等字符組成

    - 當標籤為 `0` ~ `9` 的數字時為局部標號 (range 0 ~ 99), 局部標籤可以重複出現

        ```asm
        1:
            subs r0,r0,#1   @ 每次循環使 r0=r0-1
            bne 1f          @ 跳轉到 1 標號去執行
                            @   標籤 + f: 在引用的地方向前的標號
                            @   標籤 + b: 在引用的地方向後的標號
                            @ 局部標號代表它所在的地址,因此也可以當作 '變量'或者 '函數' 來使用。
        ```

+ 立即數
    > 即數字, 在指令中需用 `#`前綴

        ```asm
        ADD R0, R0, ＃1 @ R0 = R0 + 1
        ```

+ 偽指令 (Pseudo Instruction)
    > 只在編譯階段發揮作用, 不控制機器的操作, 也不被彙編成機器代碼, 只能為彙編器 (assembler) 所識別並指導彙編如何進行

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

+ repeat loop

    ```asm
    .rept <number_of_times>  @ number_of_times 次數
    .endr
    ```

    ```
    ```

+ constant number
    - 十進制數以 `非0` 數字開頭,如: `123` 和 `9876`
    - 二進制數以 `0b` 開頭,其中字母也可以為大寫
    - 八進制數以 `0` 開始,如: `0456`, `0123`
    - 十六進制數以 `0x`開頭,如: `0xabcd`, `0X123f`；
    - 字符串常量需要用引號括起來,中間也可以使用轉義字符,如: "You are welcome!\n"

+ ARM引數傳遞規定
    > `R0` ~ `R3`這4個暫存器用來傳遞函式呼叫的第1到4個引數, 超出的通過堆疊來傳遞,`R0` 同時用來存放函式呼叫的`返回值`.

+ 跳轉指令
    > 用於實現程序流程的跳轉，在 ARM 程序中有兩種方法可以實現程序流程的跳轉

    1. 使用專門的跳轉指令: `B`, `BL`, `BLX`, `BX`
    1. 直接向程序計數器 `PC` 寫入跳轉地址值
        > 通過向程序計數器 PC 寫入跳轉地址值, 可以實現在 `4GB` 的地址空間中的任意跳轉, 在跳轉之前結合使用
        `MOV LR, PC`, 可以保存返回地址值, 從而實現在 `4GB` 連續的線性地址空間的子程序調用

+ 定址模式

    - 預先索引 (pre-index)

        ```asm
        r0 = 0x00000000
        r1 = 0x00090000     @ mem32[0x00090000] = 0x01010101, mem32[0x00090004] = 0x02020202
        LDR r0, [r1, #4]

        r0 = 0x02020202
        r1 = 0x00090000
        ```
        等同於 C code
        ```c
        uint32_t    R0 = 0;
        uint8_t     *pR1 = 0x00090000;

        R0 = *(pR1 + 4);
        ```

    - 自動索引 (auto-indexing)

        ```asm
        r0 = 0x00000000
        r1 = 0x00090000     @ mem32[0x00090000] = 0x01010101, mem32[0x00090004] = 0x02020202
        LDR r0, [r1, #4]!

        r0 = 0x02020202
        r1 = 0x00090004
        ```
        等同於 C code
        ```c
        uint32_t    R0 = 0,
        uint8_t     *pR1 = 0x00090000;
        pR1 += 4;
        R0 = *pR1;
        ```

    - 後定址 (post-indexing)

        ```asm
        r0 = 0x00000000
        r1 = 0x00090000     @ mem32[0x00090000] = 0x01010101, mem32[0x00090004] = 0x02020202
        LDR r0, [r1], #4

        r0 = 0x01010101
        r1 = 0x00090004
        ```
        等同於 C code
        ```c
        uint32_t    R0 = 0,
        uint8_t     *pR1 = 0x00090000;
        R0 = *pR1;
        pR1 += 4;
        ```

# register

+ `PC` (Program Counter) or `R15`
    >

+ `LR` (Link Register) or `R14`

+ `SP` (Stack Pointer) or `R13`

+ `CPSR` (Current Processor Status Register)

+ `SPSR` (Saved Processor Status Register)
    > 在中斷時用來自動儲存 `CPSR`的暫存器

    - `SPSR_FIQ`
    - `SPSR_IRQ`
    - `SPSR_SVC`
    - `SPSR_Undef`
    - `SPSR_Abort`


# instruction

    `.`開頭的都是 Assembler instruction, 就是給彙編器讀的指令, 不屬於ARM instruction set

    instruction 可以全大寫或是全小寫, 但不能大小寫混用

+ `include`
    > `.include 'file'` 包含指定的頭文件, 可以把一個彙編常量定義放在頭文件中

+ `.ifdef <symbol>`, `.ifndef <symbol>`, `.endif`
    > 相當於 C語言中的 `#ifdef`, `#ifndef`

    ```asm
    .ifdef <symbol>
    .endif

    .ifndef <symbol>
    .endif
    ```

+ `.set`
    > `.set <variable_name>, <variable_value>` 變數賦值

+ `.space`
    > 配置空間

    ```asm
    .space <number_of_bytes> {,<fill_byte>} @ 配置 number_of_bytes 位元組的資料空間,
                                            @ 並填補其值為 fill_byte, 若未指定該值, 預設填 0
    ```

+ `.section`
    > 自定義一個段 `.section <section_name> {, "<flags>"}`

    ```asm
    .section .mysection     @ 自定義數據段, 段名為 '.mysection'

    .section .mysection, "ax"   @ 自定義數據段, 段名為 '.mysection'
    ```

    - Flag
        1. a: allowable section
        1. w: writable section
        1. x: executable section

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
    /* 在 '_label' 的記憶體位置放入 '__vector_reset'的值, 其長度為 4bytes */
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
    str   r1, [r0]          @ r1的內容值放入r0的位址
    str   r1, [ r0  ,#4 ]   @ r1的內容值放入r0+4的位址
    str   r1, [r0] , #4     @ r1的內容值放入r0的位址,並且 --> r0=r0+4
    ```

+ `ldr偽指令` (絕對位址跳轉指令)
    > memory ---> register, 將記憶體的內容值 LOAD 進通用暫存器 R0~R12
    >> `ldr <register> , =<expression>` 相當於 PC register 或其它寄存器的長轉移, `=`表示把一個地址寫到某寄存器中

    ```asm
    ldr  r0 , =_start    @ 將標籤所在位址放入r0
    ldr  r0 , = 0x123    @ 立即值放入r0
    ldr  r0 , [r1,#4]    @ 將 (r1+4)地址中的內容值放入r0
    ldr  r0, [r1],#4     @ 將 (r1+0)地址中的內容值放入r0,並且 --> r1=r1+4

    @ 跳轉到對應的絕對地址去執行
    ldr pc, 0xAABBCCDD   @ 這是uboot中的用法
    ldr pc, do_und       @ symbol name
    ldr  pc, =main       @ ldr偽指令可以在立即數前加上 '=', 以表示把一個地址寫到某寄存器中
    ```

    ```
    ldr pc, =main
    這條指令為偽指令, 編譯的時候會將main的鏈接地址存入一個地址.
    再將
        ldr pc, =main
    轉化為
        ldr pc, [ pc, offset ]
    這樣一個指令.

    所以上面的反彙編出來的
        ldr pc, =main
    就變成了
        ldr pc. [ pc, #4 ] 相當於 pc = *(pc+4)

    由於ARM使用了流水線的原因, 所以在執行
        ldr pc. [ pc, #4 ]
    的時候 pc 不在這句代碼這裡了,
    而是跑到了 pc+8 的地方, 而
        pc = *(pc + 4) = 5000029c
        注意!!!!!!!! 這裡的 5000029c 是存在代碼段中的一個常量, 並不是計算出來的,
        不會隨程序的位置而改變, 所以無論代碼和 pc 怎麼變 *(pc+4) 的值時不會變的.

    ```

+ `B`, `BL`, `BLX`, `BX`
    > 相對位址跳轉指令, 相對於當前的 `pc` 向前或者向後跳轉

    Instruction | Description                                           | Thumb mode range  | ARM mode range
    ------------|:-----------------------------------------------------:|------------------:| ---------------
    B   <label> | Branch to target address                              | +/- 16 MB         | +/- 32 MB
    BL  <imm>   | Call a subroutine                                     | +/- 16 MB         | +/- 32 MB
    BLX <imm>   | Call a subroutine, change instruction set             | +/- 16 MB         | +/- 32 MB
    BLX <reg>   | Call a subroutine, optionally change instruction set  | +/- 16 MB         | +/- 32 MB
    BX          | Branch to target address, change instruction set      | Any               | Any

    - `B`
        > 立即跳轉到給定的目標地址，從那裡繼續執行

        ```asm
        B   Label @ 程序無條件跳轉到標號 Label 處執行
        ```

    - `BX`
        > 跳轉到指令中所指定的目標地址, 並自動切換 `ARM mode` 或 `Thumb mode`

    - `BL`
        > 跳轉之前，會在寄存器 `R14` 中保存 `PC` 的當前內容, 因此可以通過將 `R14` 的內容重新加載到 `PC` 中, 來返回到跳轉指令之後的那個指令處執行

    - `BLX`
        > 跳轉到指令中所指定的目標地址, 並自動在處理器的 `ARM mode` 及 `Thumb mode` 間切換, 該指令同時將 `PC` 的當前內容儲存到暫存器 `R14` 中

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
    cmp   r1,r3     @ 更新至CPSR
    bne   _main     @ 看CPSR的值決定
    ```

+ `beq`
    > 常與 cmp 搭配使用, cmp 的結果相等才跳躍

    ```asm
    cmp   r1,r3     @ 更新至CPSR
    beq   _main     @ 看CPSR的值決定
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

    - `stmdb`
        > 用於將寄存器壓棧 (push to stack), 地址先減而後完成操作

+ `add`
    > 加法

+ `sub`
    > 減法

+ `mul`
    > 乘法

+ `mrs`
    > 傳送 CPSR 或 SPSR 的數值到一般暫存器指令

+ `mov`
    > 資料搬移指令, 只能在寄存器之間移動數據, 或者把立即數移動到寄存器中

    ```asm
    MOV     R2, R1          @ R2 = R1 (C language)
    MOV     R1, #0x123456   @ R1 = 0x123456
    ```

+ `bic`
    > 位元清零 bit clear

    ```asm
    bic R0, R0, #0xF0000000 // 將 R0 bits[31:28] 清0
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

```c
int strcmp(const char *a, const char *b)
{
    asm(
        "strcmp_lop:                \n"
        "   ldrb    r2, [r0],#1     \n"
        "   ldrb    r3, [r1],#1     \n"
        "   cmp     r2, #1          \n"
        "   it      hi              \n"
        "   cmphi   r2, r3          \n"
        "   beq     strcmp_lop      \n"
        "	sub     r0, r2, r3  	\n"
        "   bx      lr              \n"
        :::
    );
}

size_t strlen(const char *s)
{
    asm(
        "	sub  r3, r0, #1			\n"
        "strlen_loop:               \n"
        "	ldrb r2, [r3, #1]!		\n"
        "	cmp  r2, #0				\n"
        "   bne  strlen_loop        \n"
        "	sub  r0, r3, r0			\n"
        "	bx   lr					\n"
        :::
    );
}
```

# example

```asm
                    ;進入main程式
141A:01FA 55            PUSH    BP          ;儲存暫存器現場
141A:01FB 8BEC          MOV     BP,SP

141A:01FD B80200        MOV     AX,0002     ;將2個位元組的2h入棧
141A:0200 50            PUSH    AX
141A:0201 B061          MOV     AL,61       ;將1個位元組的'a'入棧
141A:0203 50            PUSH    AX
141A:0204 E80400        CALL    020B        ;呼叫子程式
141A:0207 59            POP     CX          ;釋放區域性變數的空間
141A:0208 59            POP     CX
141A:0209 5D            POP     BP          ;恢復暫存器現場
141A:020A C3            RET                 ;main函式返回

                    ;進入子程式
141A:020B 55            PUSH    BP          ;儲存暫存器現場
141A:020C 8BEC          MOV     BP,SP
141A:020E 8A4604        MOV     AL,[BP+04]  ;讀出字元'a'
141A:0211 BB00B8        MOV     BX,B800     ;寫入到b800:0690h
141A:0214 8EC3          MOV     ES,BX
141A:0216 BB9006        MOV     BX,0690
141A:0219 26            ES:
141A:021A 8807          MOV     [BX],AL
141A:021C 8A4606        MOV     AL,[BP+06]  ;讀出資料2h
141A:021F BB00B8        MOV     BX,B800     ;寫入到b800:0691h
141A:0222 8EC3          MOV     ES,BX
141A:0224 BB9106        MOV     BX,0691
141A:0227 26            ES:
141A:0228 8807          MOV     [BX],AL
141A:022A 5D            POP     BP          ;恢復暫存器現場
141A:022B C3            RET                 ;子程式返回
141A:022C C3            RET
```

```asm
; ARM-MKD
;尋址方式,使用AXD調試時，可使用單步調試(F10)
;使用AXD的processor views-->register查看寄存器變化
;使用AXD的processor views-->memory查看內存的值
;使用AXD的processor views-->disassembly查看反彙編代碼



        GBLA    Test1   ;聲明一個全局的數學變量，變量名為Test1
        GBLL    Test2   ;申明一個全局的邏輯變量，變量名為Test2
Test1   SETA    0x3     ;將變量Test1賦值為3,注意書寫格式，需要頂格寫
Test2   SETL    {TRUE}  ;將變量Test2賦值為TRUE

;EQU偽指令
COUNT   EQU     0x30003100  ; 定義一個變量，地址為0x30003100

        AREA    Example1,CODE,READONLY  ; 聲明代碼段Example1
        ENTRY                           ; 標識程序入口
        CODE32                          ; 聲明32位ARM指令

START
        ;立即尋址
        MOV     R0, #0      ; R0 <= 0,將立即數0x00存入寄存器R0,可通過AXD的processor views-->register查看
        ADD R0, R0, #1      ; R0 <= R0 + 1
        ADD R0, R0, #0x3f   ; R0 <= R0 + 0x3f

        ;寄存器尋址
        MOV R1, #1          ; R1 <= 1,將立即數0x01存入寄存器R1
        MOV R2, #2          ; R2 <= 2,將立即數0x02存入寄存器R2
        ADD R0, R1 ,R2      ; R0 <= R1＋R2,將寄存器R1和R2的內容相加，其結果存放在寄存器R0中

        ;寄存器間接尋址
        LDR R1, =COUNT      ; R1 <= COUNT,將存儲器地址放入寄存器R0
        ; MOV   R0, #0x12   ; R0 <= 0x12,MOV指令目地操作數隻能是8位
        LDR R0, =0x12345678
        STR R0, [R1]        ; [R1] <= R0，將寄存器R0的內容存入寄存器R1所指向的存儲器
                            ;即設置COUNT為0x12345678,
                            ;STR指令用於從源寄存器中將一個32位的字數據傳送到存儲器中
                            ;可通過AXD的processor views-->memory查看0x30003100的值

        ;基址變址尋址
        LDR R1,=COUNT       ;將存儲器地址0x30003100放入寄存器R1
        LDR R2,=(COUNT+4)   ;將存儲器地址0x30003104放入寄存器R1
        MOV R3,#0x12        ;將立即數0x12存入寄存器R3
        STR R3,[R2]         ;將寄存器R3的內容存入寄存器R2所指向的存儲器
        LDR R4,[R1,#4]      ;將寄存器R1的內容加上4所指向的存儲器的字存入寄存器R4

        ;多寄存器尋址
        LDR   R1,=COUNT     ;將存儲器地址0x30003100放入寄存器R1
        LDMIA R1,{R5,R6}    ;R5 <= [R1],R6 <= [R1+4]


        ;相對尋址
        BL NEXT     ;跳轉到子程序NEXT處執行,注意使用F8(step in)
        NOP
        NOP


        ;跳轉指令(B)
        B   label1  ;跳轉到子程序label1處執行
        NOP
        NOP
        NOP

NEXT
        MOV R0,LR
        NOP
        NOP
        NOP
        MOV PC,LR   ;從子程序返回

label1
        NOP
        NOP
        NOP

        ;跳轉指令(BL)
        BL  lable2  ;跳轉到子程序label2處執行
        NOP
        NOP

        ;MOV指令
        MOV R0,#0x12    ;R0=0x12
        MOV R1,R0       ;R1=R0
        MOV R1,R0,LSL#3 ;R1=R0<<3

        ;MVN指令
        MVN R0,#0xff        ;R0 = 0xfffff00
        MVN R0,#0xA0000007  ; 0xA0000007的反碼為0x5FFFFFF8


        ;CMP指令(使用AXD查看CPSR)
        MOV R0,#1
        MOV R1,#2
        CMP R0,R1       ;若R0>R1,則置R0=3,若R0<=R1，則置R1=3
        MOVHI   R0,#3   ;根據CPSR條件標誌位中的HI(無符號大於)判斷，若R0>R1，則R0=3
        MOVLS   R1,#3   ;根據CPSR條件標誌位中的LS(無符號小於或等於)判斷,R0<=R1，則R1=3


        ;TST指令,測試R5的bit23是否為1，若是則置R5=0x01,不是則置R5=0x00
        LDR R5,=0xffffffff
        TST R5,#(1<<23)  ;當bit23位為1時，CPSR EQ位被設置
        MOVEQ   R5,#0x00
        MOVNE   R5,#0x01

        ;ADD指令
        MOV R1,#1
        MOV R2,#2
        MOV R3,#3
        ADD R0,R1,R2        ;R0=R1+R2
        ADD R0,R1,#256  ;R0=R1+256
        ADD R0,R2,R3,LSL#1  ;R0=R2+(R3<<1)

        ;SUB指令
        MOV R1,#100
        MOV R2,#8
        SUB R0,R1,R2    ;R0=R1-R2
        SUB R0,R1,#55   ;R0=R1-256

        ;AND指令
        MOV R0,#0xff
        AND R0,R0,#3    ;邏輯與運算,R0 = R0 & 3

        ;ORR指令
        MOV R0,#0xff
        ORR R0,R0,#3    ;邏輯或運算,R0 = R0 | 3


        ;BIC指令
        MOV R0,#0x77
        BIC R0,R0,#0x0b ;將R0的bit0,bit1,bit3清零，其餘位不變


        ;MUL指令
        MOV R1,#10
        MOV R2,#20
        MUL R0,R1,R2    ;R0=R1*R2

        ;MRS指令(將CPSR或者SPSR的內容傳送到通用寄存器)
        MRS R0,CPSR ;傳送CPSR的內容到R0
        MRS R1,SPSR ;傳送SPSR的內容到R1

        ;LDR指令
        LDR R1,=0x30003100  ;R1=0x30003100,使用AXD的processor views-->memory查看內存的值
        LDR R0,[R1]         ;R0=[R1]
        LDR R0,[R1,#4]      ;R0=[R1+4]

        ;LDRB,LDRH指令
        LDR R1,=0x30003100
        LDRB R0,[R1]        ;將存儲器地址為R1的字節數據讀入寄存器R0，並將R0的高24位清零
        LDRH R2,[R1]        ;將存儲器地址為R1的半字數據讀入寄存器R2，並將R2的高16位清零

        ;STR指令,內存地址0x30003100=0xab
        LDR R1,=0x30003100
        MOV R0,#0xab
        STR R0,[R1]         ;將R0中的字數據寫入以R1為地址的存儲器中
        STR R0,[R1,#8]      ;將R0中的字數據寫入以R1＋8為地址的存儲器中


        ;LDM,STM指令
        LDR     R1,=0x30003100
        LDMIA R1,{R5,R6}    ;R5 = [R1],R6 = [R1+4]
        MOV     R2,#0x33
        MOV     R3,#0X44
        STMIA   R1,{R2,R3}  ;[R1]=R2,[R1+4]=R2


        ;SWP指令
        SWP R0,R0,[R1]      ;該指令完成將R1所指向的存儲器中的字數據與R0中的字數據交換

        ;移位指令
        MOV R1,#4
        MOV R0,R1,LSL#2     ;R0=R1<<2
        MOV R1,#3
        MOV R0,R1,ROR#2     ;將R1中的內容循環右移兩位後傳送到R0中

        ;彙編控制偽指令，while指令
        WHILE   Test1<10
            MOV R0,#Test1
            MOV R1,#1
Test1   SETA Test1+1
        WEND

        ;彙編控制偽指令，IF指令
        IF Test2 = {TRUE}
            MOV R0,#1
            MOV R1,#2
        ELSE
            MOV R0,#0
            MOV R1,#0
        ENDIF
        B   out
lable2
        MOV R0,LR       ;查看R14
        NOP
        NOP
        MOV PC,LR       ;從子程序返回


out
        NOP
    END
```
