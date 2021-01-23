Andes tips
---


## 查看 Predefined Macros

```
$ cd ~/Andestech/BSPv320/toolchains/nds32le-elf-mculib-v3m/bin
$ echo " " |./nds32le-elf-cpp -E -dM | grep NDS32
    #define NDS32_ABI_2 1
    #define __NDS32__ 1
    #define __NDS32_BASELINE_V3M 1
    #define NDS32_FIRST_PSEUDO_REGISTER 136
    #define NDS32_EL 1
    #define __NDS32_EL 1
    #define __NDS32_REDUCE_REGS 1
    #define __NDS32_ABI_2__ 1
    #define __NDS32_REDUCE_REGS__ 1
    #define __NDS32_ABI_2 1
    #define __NDS32_BASELINE_V3M__ 1
    #define NDS32_BASELINE_V3M 1
    #define __NDS32_EL__ 1
    #define NDS32_REDUCE_REGS 1

```

## 產生software interrupt

```c
void gen_swi()
{
    unsigned int int_pend;
    int_pend = __nds32__mfsr(NDS32_SR_INT_PEND);
    int_pend |= 0x10000;
    __nds32__mtsr(int_pend, NDS32_SR_INT_PEND);
    __nds32__dsb();
}
```


## 避免某些程式碼被optimize


+ 對 function

```c
__attribute__((optimize("O0"))) int add (int a, int b )
{
    int x = a;
    int y = b;
    return x + y;
}
```

+ 對 source code 區域

```c
#pragma GCC push_options
#pragma GCC optimize ("O0")
int add (int a, int b )
{
    int x = a;
    int y = b;
    return x + y;
}
#pragma GCC pop_options

int main ()
{
    int r = 1;
    int a = r;
    int b = r;
    func ();
    return 0;
}
```

    - `#pragma GCC push_options`
        > 把原來的option push進去, 例如是`-Os`

    - `#pragma GCC optimize ("O0")`
        > 以下的 source code 使用 `-O0`

    - `#pragma GCC pop_options`
        > 把 `-Os` pop 回來, 恢復原來的 optimize 設定


## C語言程式轉成組合語言

```
$ ds32le-elf-gcc -S hello1.c
```

+ `hello1.c`

```
#include <stdio.h>
int empty(void);

int main(void)
{
   printf("!!This is program 1!!\n");
   empty();
   return 0;
}

int empty()
{
   printf("!!This is an empty function!!\n");
   return 0;
}
```

+ `hello1.s`

```asm
   ! For N1033A-S N1033-S N903A-S N903-S N1233-S
   ! Use little-endian byte order
   ! Generate baseline V2 instructions
   ! Generate 16/32-bit mixed instructions
   ! Generate multiply with accumulation instructions using register $d0/$d1
   ! Generate integer div instructions using register $d0/$d1
   ! Generate performance extension instructions
   ! Generate instructions for ABI: 2
   .file   1 "hello1.c"
   .abi_2
   .section   .mdebug.abi_nds32
   .previous
   .section   .rodata
   .align   2
.LC0:
   .string   "!!This is program 1!!"
   .text
   .align   2
   .globl   main
   .type   main, @function
main:
   ! pretend args size: 0, auto vars size: 0, pushed regs size: 8, outgoing args size: 0
   ! frame pointer: $fp, needed: yes
   ! $fp $lp
   ! use $r8 as function entrypoint: no
   ! use v3 push/pop: no
   ! prologue frame size: 8
   smw.adm   $sp, [$sp], $sp, 10
   addi   $fp, $sp, 4
   ! end of prologue
   la   $r0, .LC0
   .hint_func_args 62
   bal   puts
   .hint_func_args 63
   bal   empty
   movi   $r0, 0
   ! epilogue - AABI
   addi   $sp, $fp, -4
   lmw.bim   $sp, [$sp], $sp, 10
   .hint_func_args 62
   ret
   .size   main, .-main
   .section   .rodata
   .align   2
.LC1:
   .string   "!!This is an empty function!!"
   .text
   .align   2
   .globl   empty
   .type   empty, @function
empty:
   ! pretend args size: 0, auto vars size: 0, pushed regs size: 8, outgoing args size: 0
   ! frame pointer: $fp, needed: yes
   ! $fp $lp
   ! use $r8 as function entrypoint: no
   ! use v3 push/pop: no
   ! prologue frame size: 8
   smw.adm   $sp, [$sp], $sp, 10
   addi   $fp, $sp, 4
   ! end of prologue
   la   $r0, .LC1
   .hint_func_args 62
   bal   puts
   movi   $r0, 0
   ! epilogue - AABI
   addi   $sp, $fp, -4
   lmw.bim   $sp, [$sp], $sp, 10
   .hint_func_args 62
   ret
   .size   empty, .-empty
   .ident   "GCC: (2011-07-29) 4.4.4"
```
