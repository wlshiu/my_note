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

