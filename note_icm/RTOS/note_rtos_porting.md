RTOS Port
---

# Interrupt vector

+ SWI (S/w interrupt)
    > priority 最低

+ system tick
    > priority 最高

# 開關中斷總線的時機

+ 在 start schedule 前, 中斷應關閉

+ 第一次 context switch 時, 根據 CPU 特性, 可在 restore GPRs 時打開中斷總線


# Heap configuration

# Stack layout

General Purpose Registers push/pop order

## In ISR

Use stack pool for ISR

## In Context-Switch

Use stack pool for a task

+ stack initialize when a task creation

+ SWI trigger




