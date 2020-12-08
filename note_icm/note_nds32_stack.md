NDS32
---

+ Stack of FreeRTOS

```
Stack Layout:

SP_BOUND
                   V8                                              V10
    Low |-----------------------|                       |----------------------|
        |          $FPU         | configSUPPORT_FPU     |          $FPU        | configSUPPORT_FPU
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

SP_BASE
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

