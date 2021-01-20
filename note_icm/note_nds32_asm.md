NDS32 ASM
---

NDS32 有 `32` 個 32-bits 通用暫存器, 也可以使用精簡暫存器 (15 個 32-bits 通用暫存器)以節省成本

# Definitions
+ xx
    > number of bits

+ opc_xx
    > op code

+ rt_xx
    > register of target
+ ra_xx
    > register of source A
+ rb_xx
    > register of source B
+ rd_xx
    > register of destination

+ sub_xx
    > sub_opcode

+ imm_xx
    > 立即數 (Immediate)

+ SRIDX
    > System Register Index

+ YY-memory(address)
    > 對 `address` 取值
    > + YY = word
    > + YY = Halfword
    > + YY = Byte

+ IPC
    > Interruption Program Counter

+ EDM
    > Embedded Debug Module (connect with AICE, Andes ICE)

+ ZOL (Zero Overhead Loop)
    >  ZOL is a set of mechanism in Andes DSP ISA extension to speed up performance of loops.

    - referenc Programming Guide

+ IFC (Inline Function Call)
    > `IFC_LP` records the PC of the instructions after IFCall9/IFCall instructions

    - referenc Programming Guide

+ `SE()` is a function to `Sign-Extend` an expression.
+ `ZE()` is a function to `Zero-Extend` an expression.

+ EX9IT
    > It is an extension for code size reduction.
    Compiler can put a frequently used 32-bit instruction in the instruction table
    and replace the 32-bit instruction with the 16-bit `ex9.it` instruction in the code
    for the code size reduction purpose.
    >> code size 減少, 可能會加長執行時間, 進而影響效能.

# Instruction Set (32-bits)

## Read/Write System Registers

Mnemonic         | Instruction              | Operation
:-               | :-                       | :-
mfsr rt5, SRIDX  | Move from System Register| rt5 = SR[SRIDX]
mtsr rt5, SRIDX  | Move to System Register  | SR[SRIDX] = rt5

## Load and Store Instructions

+ with Immediate

Mnemonic                            | Instruction                      | Operation
:-                                  | :-                               | :-
lwi     rt5, [ra5 + (imm15s << 2)]  | Load Word Immediate              | address = ra5 + SE(imm15s << 2) \
<space>                             |                                  | rt5 = Word-memory(address)
lhi     rt5, [ra5 + (imm15s << 1)]  | Load Halfword Immediate          | address = ra5 + SE(imm15s << 1) \
<space>                             |                                  | rt5 = ZE(Halfword-memory(address))
lhsi    rt5, [ra5 + (imm15s << 1)]  | Load Halfword Signed Immediate   | address = ra5 + SE(imm15s << 1) \
<space>                             |                                  | rt5 = SE(Halfword-memory(address))
lbi     rt5, [ra5+ imm15s]          | Load Byte Immediate              | address = ra5 + SE(imm15s) \
<space>                             |                                  | rt5 = ZE(Byte-memory(address))
lbsi    rt5, [ra5+ imm15s]          | Load Byte Signed Immediate       | address = ra5 + SE(imm15s) \
<space>                             |                                  | rt5 = SE(Byte-memory(address))
swi     rt5, [ra5 + (imm15s << 2)]  | Store Word Immediate             | address = ra5 + SE(imm15s << 2) \
<space>                             |                                  | Word-memory(address) = rt5
shi     rt5, [ra5 + (imm15s << 1)]  | Store Halfword Immediate         | address = ra5 + SE(imm15s << 1) \
<space>                             |                                  | Halfword-memory(address) = rt5[15:0]
sbi     rt5, [ra5 + imm15s]         | Store Byte Immediate             | address = ra5 + SE(imm15s) \
<space>                             |                                  | Byte-memory(address) = rt5[7:0]
lwi.bi  rt5, [ra5], (imm15s << 2)   | Load Word Immediate with         | rt5 = Word-memory(ra5) \
<space>                             | Post Increment                   | ra5 = ra5 + SE(imm15s << 2)
lhi.bi  rt5, [ra5], (imm15s << 1)   | Load Halfword Immediate with     | rt5 = ZE(Halfword-memory(ra5)) \
<space>                             | Post Increment                   | ra5 = ra5 + SE(imm15s << 1)
lhsi.bi rt5, [ra5], (imm15s << 1)   | Load Halfword Signed Immediate   | rt5 = SE(Halfword-memory(ra5)) \
<space>                             | with Post Increment              | ra5 = ra5 + SE(imm15s << 1)
lbi.bi  rt5, [ra5], imm15s          | Load Byte Immediate with         | rt5 = ZE(Byte-memory(ra5)) \
<space>                             | Post Increment                   | ra5 = ra5 + SE(imm15s)
lbsi.bi rt5, [ra5], imm15s          | Load Byte Signed Immediate       | rt5 = SE(Byte-memory(ra5)) \
<space>                             | with Post Increment              | ra5 = ra5 + SE(imm15s)
swi.bi  rt5, [ra5], (imm15s << 2)   | Store Word Immediate with        | Word-memory(ra5) = rt5 \
<space>                             | Post Increment                   | ra5 = ra5 + SE(imm15s << 2)
shi.bi  rt5, [ra5], (imm15s << 1)   | Store Halfword Immediate with    | Halfword-memory(ra5) = rt5[15:0] \
<space>                             | Post Increment                   | ra5 = ra5 + SE(imm15s << 1)
sbi.bi  rt5, [ra5], imm15s          | Store Byte Immediate with        | Byte-memory(ra5) = rt5[7:0] \
<space>                             | Post Increment                   | ra5 = ra5 + SE(imm15s)


+ with Registers

Mnemonic                            | Instruction                      | Operation
:-                                  | :-                               | :-
lw      rt5, [ra5 + (rb5 << sv)]    | Load Word                        | address = ra5 + (rb5 << sv) \
<space>                             |                                  | rt5 = Word-memory(address)
lh      rt5, [ra5 + (rb5 << sv)]    | Load Halfword                    | address = ra5 + (rb5 << sv) \
<space>                             |                                  | rt5 = ZE(Halfword-memory(address))
lhs     rt5, [ra5 + (rb5 << sv)]    | Load Halfword Signed             | address = ra5 + (rb5 << sv) \
<space>                             |                                  | rt5 = SE(Halfword-memory(address))
lb      rt5, [ra5 + (rb5 << sv)]    | Load Byte                        | address = ra5 + (rb5 << sv) \
<space>                             |                                  | rt5 = ZE(Byte-memory(address))
lbs     rt5, [ra5 + (rb5 << sv)]    | Load Byte Signed                 | address = ra5 + (rb5 << sv) \
<space>                             |                                  | rt5 = SE(Byte-memory(address))
sw      rt5, [ra5 + (rb5 << sv)]    | Store Word                       | address = ra5 + (rb5 << sv) \
<space>                             |                                  | Word-memory(address) = rt5
sh      rt5, [ra5 + (rb5 << sv)]    | Store Halfword                   | address = ra5 + (rb5 << sv) \
<space>                             |                                  | Halfword-memory(address) = rt5[15:0]
sb      rt5, [ra5 + (rb5 << sv)]    | Store Byte                       | address = ra5 + (rb5 << sv) \
<space>                             |                                  | Byte-memory(address) = rt5[7:0]
lw.bi   rt5, [ra5], rb5<<sv         | Load Word with Post Increment    | rt5 = Word-memory(ra5) \
<space>                             |                                  | ra5 = ra5 + (rb5 << sv)
lh.bi   rt5, [ra5], rb5<<sv         | Load Halfword with Post Increment| rt5 = ZE(Halfword-memory(ra5)) \
<space>                             |                                  | ra5 = ra5 + (rb5 << sv)
lhs.bi  rt5, [ra5], rb5<<sv         | Load Halfword Signed with        | rt5 = SE(Halfword-memory(ra5)) \
<space>                             | Post Increment                   | ra5 = ra5 + (rb5 << sv)
lb.bi   rt5, [ra5], rb5<<sv         | Load Byte with Post Increment    | rt5 = ZE(Byte-memory(ra5)) \
<space>                             |                                  | ra5 = ra5 + (rb5 << sv)
lbs.bi  rt5, [ra5], rb5<<sv         | Load Byte Signed with            | rt5 = SE(Byte-memory(ra5)) \
<space>                             | Post Increment                   | ra5 = ra5 + (rb5 << sv)
sw.bi   rt5, [ra5], rb5<<sv         | Store Word with Post Increment   | Word-memory(ra5) = rt5 \
<space>                             |                                  | ra5 = ra5 + (rb5 << sv)
sh.bi   rt5, [ra5], rb5<<sv         | Store Halfword with              | Halfword-memory(ra5) = rt5[15:0] \
<space>                             | Post Increment                   | ra5 = ra5 + (rb5 << sv)
sb.bi   rt5, [ra5], rb5<<sv         | Store Byte with Post Increment   | Byte-memory(ra5) = rt5[7:0] \
<space>                             |                                  | ra5 = ra5 + (rb5 << sv)

## Jump and Branch Instructions

+ Jump

Mnemonic            | Instruction             | Operation
:-                  | :-                      | :-
j       imm24s      | Jump                    | PC = PC + SE(imm24s << 1)
jal     imm24s      | Jump and Link           | LP= next sequential PC (PC + 4); \
<space>             |                         | PC = PC + SE(imm24s << 1)
jr      rb5         | Jump Register           | PC = rb5
ret     rb5         | Return from Register    | PC = rb5
<space>             |                         |
jral    rb5         |                         | jaddr = rb5; \
jral    rt5, rb5    | Jump Register and Link  | LP= PC + 4; or rt5 = PC + 4; \
<space>             |                         | PC = jaddr;


+ Branch

Mnemonic                    | Instruction                               | Operation
:-                          | :-                                        | :-
beq     rt5, ra5, imm14s    | Branch on Equal (2 Register)              | PC = (rt5 == ra5) ? (PC + SE(imm14s << 1)) : (PC + 4)
bne     rt5, ra5, imm14s    | Branch on Not Equal (2 Register)          | PC = (rt5 != ra5) ? (PC + SE(imm14s << 1)) : (PC + 4)
beqz    rt5, imm16s         | Branch on Equal Zero                      | PC = (rt5 ==0) ? (PC + SE(imm16s << 1)) : (PC + 4)
bnez    rt5, imm16s         | Branch on Not Equal Zero                  | PC = (rt5 != 0) ? (PC + SE(imm16s << 1)) : (PC + 4)
bgez    rt5, imm16s         | Branch on Greater than or Equal to Zero   | PC = (rt5 (signed)>= 0) ? (PC + SE(imm16s << 1)) : (PC + 4)
bltz    rt5, imm16s         | Branch on Less than Zero                  | PC = (rt5 (signed)< 0) ? (PC + sign-ext(imm16s << 1)) : (PC + 4)
bgtz    rt5, imm16s         | Branch on Greater than Zero               | PC = (rt5 (signed)> 0) ? (PC + SE(imm16s << 1)) : (PC + 4)
blez    rt5, imm16s         | Branch on Less than or Equal to Zero      | PC = (rt5 (signed)<= 0) ? (PC + SE(imm16s << 1)) : (PC + 4)
<space>                     |                                           |
bgezal  rt5, imm16s         | Branch on Greater than or Equal to Zero and Link  | LP = next sequential PC (PC + 4); \
<space>                     |                                                   | PC = (rt5 (signed)>= 0) ? (PC + SE(imm16s <<  1)), (PC + 4);
bltzal  rt5, imm16s         | Branch on Less than Zero and Link                 | LP = next sequential PC (PC +4); \
<space>                     |                                                   | PC = (rt5 (signed)< 0) ? (PC + SE(imm16s <<  1)), (PC + 4);



## Arithmetic logic unit (ALU: 算術邏輯單元)

+ with immediate

Mnemonic                | Instruction                        | Operation
:-                      | :-                                 | :-
addi    rt5, ra5, imm15s| Add Immediate                      | rt5= ra5+ SE(imm15s)
subri   rt5, ra5, imm15s| Subtract Reverse Immediate         | rt5 = SE(imm15s) – ra5
andi    rt5, ra5, imm15u| And Immediate                      | rt5= ra5 & ZE(imm15u)
ori     rt5, ra5, imm15u| Or Immediate                       | rt5= ra5 \| ZE(imm15u)
xori    rt5, ra5, imm15u| Exclusive Or Immediate             | rt5= ra5 ^ ZE(imm15u)
slti    rt5, ra5, imm15s| Set on Less Than Immediate         | rt5 = (ra5(unsigned) < SE(imm15s)) ? 1 : 0
sltsi   rt5, ra5, imm15s| Set on Less Than Signed Immediate  | rt5 = (ra5(signed) < SE(imm15s)) ? 1 : 0
movi    rt5, imm20s     | Move Immediate                     | rt5= SE(imm20s)
sethi   rt5, imm20u     | Set High Immediate                 | rt5 = {imm20u, 12'b0}

+ with register

Mnemonic                | Instruction               | Operation
:-                      | :-                        | :-
add     rt5, ra5, rb5   | Add                       | rt5 = ra5 + rb5
sub     rt5, ra5, rb5   | Subtract                  | rt5 = ra5 - rb5
and     rt5, ra5, rb5   | And                       | rt5 = ra5 & rb5
nor     rt5, ra5, rb5   | Nor                       | rt5 = ~(ra5 | rb5)
or      rt5, ra5, rb5   | Or                        | rt5 = ra5 | rb5
xor     rt5, ra5, rb5   | Exclusive Or              | rt5 = ra5 ^ rb5
slt     rt5, ra5, rb5   | Set on Less Than          | rt5 = (ra5 (unsigned) < rb5) ? 1 : 0
slts    rt5, ra5, rb5   | Set on Less Than Signed   | rt5 = (ra5 (signed) < rb5) ? 1 : 0
sva     rt5, ra5, rb5   | Set on Overflow Add       | rt5 = ((ra5 + rb5) overflow) ? 1 : 0
svs     rt5, ra5, rb5   | Set on Overflow Subtract  | rt5 = ((ra5 - rb5) overflow)) ? 1 : 0
seb     rt5, ra5        | Sign Extend Byte          | rt5 = SE(ra5[7:0])
seh     rt5, ra5        | Sign Extend Halfword      | rt5 = SE(ra5[15:0])
zeb     rt5, ra5        | Zero Extend Byte          | rt5 = ZE(ra5[7:0])
(alias of 'andi rt5, ra5, 0xFF')|                   |
zeh     rt5, ra5        | Zero Extend Halfword      | rt5 = ZE(ra5[15:0])
wsbh    rt5, ra5        | Word Swap Byte within Halfword | rt5 = {ra5[23:16], ra5[31:24], ra5[7:0], ra5[15:8]}

## Shift Instructions

Mnemonic                | Instruction                        | Operation
:-                      | :-                                 | :-
slli    rt5, ra5, imm5u | Shift Left Logical Immediate       | rt5 = ra5 << imm5u
srli    rt5, ra5, imm5u | Shift Right Logical Immediate      | rt5 = ra5 (logic)>> imm5u
srai    rt5, ra5, imm5u | Shift Right Arithmetic Immediate   | rt5 = ra5 (arith)>> imm5u
rotri   rt5, ra5, imm5u | Rotate Right Immediate             | rt5 = ra5 >>\| imm5u
sll     rt5, ra5, rb5   | Shift Left Logical                 | rt5 = ra5 << rb5(4,0)
srl     rt5, ra5, rb5   | Shift Right Logical                | rt5 = ra5 (logic)>> rb5(4,0)
sra     rt5, ra5, rb5   | Shift Right Arithmetic             | rt5 = ra5 (arith)>> rb5(4,0)
rotr    rt5, ra5, rb5   | Rotate Right                       | rt5 = ra5 >>\| rb5(4,0)


## Multiply Instructions

Mnemonic                | Instruction                       | Operation
:-                      | :-                                | :-
mul     rt5, ra5, rb5   | Multiply Word to Register         | rt5 = ra5 * rb5
mults64 d1, ra5, rb5    | Multiply Word Signed              | d1 = ra5 (signed)* rb5
mult64  d1, ra5, rb5    | Multiply Word                     | d1 = ra5 (unsigned)* rb5
madds64 d1, ra5, rb5    | Multiply and Add Signed           | d1= d1 + ra5 (signed)* rb5
madd64  d1, ra5, rb5    | Multiply and Add                  | d1= d1 + ra5 (unsigned)* rb5
msubs64 d1, ra5, rb5    | Multiply and Subtract Signed      | d1= d1- ra5 (signed)* rb5
msub64  d1, ra5, rb5    | Multiply and Subtract             | d1= d1- ra5 (unsigned)* rb5
mult32  d1, ra5, rb5    | Multiply Word                     | d1.LO = ra5 * rb5
madd32  d1, ra5, rb5    | Multiply and Add                  | d1.LO = d1.LO + ra5 * rb5
msub32  d1, ra5, rb5    | Multiply and Subtract             | d1.LO = d1.LO - ra5 * rb5
mfusr   rt5, USR        | Move From User Special Register   | rt5 = USReg[USR]
mtusr   rt5, USR        | Move To User Special Register     | USReg[USR] = rt5

## Divide Instructions

Mnemonic             | Instruction               | Operation
:-                   | :-                        | :-
DIV     Dt, ra5, rb5 | Unsigned Integer Divide   | `Dt.L` = Floor(ra5 (unsigned) / rb5); `Dt.H` = ra5 (unsigned) mod rb5;
DIVS    Dt, ra5, rb5 | Signed Integer Divide     | `Dt.L` = Floor(ra5 (signed) / rb5);   `Dt.H` = ra5 (signed) mod rb5;


## Conditional Move

Mnemonic              | Instruction                  | Operation
:-                    | :-                           | :-
cmovz   rt5, ra5, rb5 | Conditional Move on Zero     | if (rb5 == 0) { rt5 = ra5 }
cmovn   rt5, ra5, rb5 | Conditional Move on Not Zero | if (rb5 != 0) { rt5 = ra5 }

## Serialization Instructions

Mnemonic    | Instruction                       | Operation
:-          | :-                                | :-
dsb         | Data Serialization Barrier        |
isb         | Instruction Serialization Barrier |
break       | Breakpoint                        |
syscall     | System Call                       |
trap        | Trap Always                       |
teqz        | Trap on Equal Zero                |
tnez        | Trap on Not Equal Zero            |

## Special Return Instructions
Mnemonic        | Instruction                                                | Operation
:-              | :-                                                         | :-
iret            | Interruption Return                                        | Return from Interruption (exception or interrupt).
ret.itoff   rb5 | Return and turn off instruction address translation        | PC = rb5, PSW.IT = 0
ret.toff    rb5 | Return and turn off address translation (instruction/data) | PC = rb5, PSW.IT = 0, PSW.DT = 0


## Cache Control Instruction

Mnemonic | Instruction     | Operation
:-       | :-              | :-
cctl     | Cache Control   | Read, write, and control cache states.


## Miscellaneous Instructions

Mnemonic | Instruction                   | Operation
:-       | :-                            | :-
setend.b | Atomic set of PSW.BE bit      | PSW.BE = 1;
setend.l | Atomic clear of PSW.BE bit    | PSW.BE = 0;
setgie.e | Atomic enab;e of PSW.GIE bit  | PSW.GIE = 1;
setgie.d | Atomic disable of PSW.GIE bit | PSW.GIE = 0;
standby  | Wait for External Event       | Enter standby state and wait for external


# Pseudo-instructions

## load 32-bit value/address

+ `li`
    > Loads Immediate

    ```
    li  rt5,imm_32  /* loads 32-bit integer into register rt5. */
    ```

+ `la`
    > Load Address

    ```
    la  rt5,var  /* loads 32-bit address of var into register rt5. */
    ```

## load/store variables

+ `l.{bhw}  rt5, var`
    > loads immediate (byte/half-word/word) of `var` into register rt5.

+ `l.{bh}s  rt5, var`
    > loads signed immediate (byte/half-word) of `var` into register rt5.

+ `s.{bhw}  rt5, var`
    > stores register rt5 to var (address, type is byte/half-word/word).
    >> `*(u8*, u16*, u32*)var = rt5`

+ `br  rb5`
    > alias of `jr rb5`

+ `b  label`
    > branch to label.
    >> the same `j  label`

+ `move  rt5, ra5` (16-bits instruction)
    > Move contents between general-purpose registers
    >> `Rt5 = Ra5`

+ `pushm  ra5, rb5`
    > Pushes the contents of registers from `ra5` to `rb5` into stack.

    ```
    for(int i = reg_idx(ra5); i < reg_idx(rb5); i++)
    {
        sp -= 4;
        *sp = get_reg_value(i);
    }
    ```

+ `push  ra5`
    > Pushes the content of register `ra5` into stack

    ```
    sp -= 4;
    *sp = get_reg_value(ra5)
    ```

+ `popm  ra5, rb5`
    > Poppes top of stack values into registers `ra5` to `rb5`

    ```
    for(int i = reg_idx(ra5); i < reg_idx(rb5); i++)
    {
        set_reg_value(i) = *sp;
        sp += 4;
    }
    ```

+ `pop  rt5`
    > Poppes top of stack value into register `rt5`

    ```
    set_reg_value(rt5) = *sp;
    sp += 4;
    ```

# C functions to access register

```
#include <nds32_intrinsic.h>
```

## `__nds32__break()`

```
void __nds32__break(const unsigned int swid);
```

## `__nds32__mfsr()`

```
unsigned int __nds32__mfsr(const enum nds32_sr srname);
```

+ `srname`  is an SR symbolic mnemonic with a prefix `NDS32_SR_`

    - `NDS32_SR_PSW`
    - `NDS32_SR_IPSW`
    - `NDS32_SR_P_IPSW`
    - `NDS32_SR_ICM_CFG`
    - `NDS32_SR_DCM_CFG`
    - `NDS32_SR_MMU_CFG`
    - `NDS32_SR_CORE_ID`
    - `NDS32_SR_IVB`
    - `NDS32_SR_EVA`
    - `NDS32_SR_P_EVA`
    - `NDS32_SR_ITYPE`
    - `NDS32_SR_P_ITYPE`
    - `NDS32_SR_IPC`
    - `NDS32_SR_P_IPC`
    - `NDS32_SR_OIPC`


## `__nds32__mtsr()`

```
void __nds32__mtsr(unsigned int val, const enum nds32_sr srname)
```

+ `srname` is an SR symbolic mnemonic with a prefix `NDS32_SR_`

    ```
    unsigned int    psw = __nds32__mfsr(NDS32_SR_PSW);
    ```

## `__nds32__mfusr`

```
unsigned int __nds32__mfusr(const enum nds32_usr usrname)
```

+ `usrname` is a USR symbolic mnemonic with a prefix `NDS32_USR_`.

    ```c
    unsigned int    pfm_ctl = __nds32__mfusr(NDS32_USR_PFM_CTL);
    ```


+ **get pc (program counter)**

    ```
    unsigned long   pc = __nds32__mfusr(NDS32_USR_PC);
    ```

    ```asm
    /* assembly */
    mfusr   <rt5>, $pc
    ```

## `__nds32__mtusr`

```
void __nds32__mtusr(unsigned int val, const enum nds32_usr usrname)
```

+ `usrname` is a USR symbolic mnemonic with a prefix `NDS32_USR_`

    ```c
    #include <nds32_intrinsic.h>

    void func(void)
    {
        ...
        unsigned int    pfm_ctl = __nds32__mfusr(NDS32_USR_PFM_CTL);

        //get PFM_CTL
        pfm_ctl = pfm_ctl | 0x00000001;
        __nds32__mtusr(pfm_ctl, NDS32_USR_PFM_CTL); //enable PFMC0
        ...
    }
    /* assume the access permission is enabled in user mode*/

    ```

## `__nds32__setgie_dis()`

disables global interrupts
(won't take effect immediately)

## `__nds32__setgie_en()`

enables global interrupts
(won't take effect immediately).

## `__nds32__gie_dis()`

disables global interrupts
(will take effect immediately)

## `__nds32__gie_en()`

enables global interrupts
(will take effect immediately)

## `__nds32__get_current_sp`

```
unsigned long   sp = __nds32__get_current_sp();
```

## `__nds32__set_current_sp`

```
void __nds32__set_current_sp(unsigned int sp
```

```c
#include <nds32_intrinsic.h>

void func(void)
{
    // adjust sp value to sp - 4
    unsigned int sp;
    sp = __nds32__get_current_sp();
    sp = sp - 4;
    __nds32__set_current_sp(sp);
}
```

## `__nds32__nop`

```
void __nds32__nop()
```

## `__nds32__return_address`

returns the return address ($lp)

```
// lp is the return address of func
unsigned long   lp = __nds32__return_address();
```









