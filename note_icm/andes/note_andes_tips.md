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

