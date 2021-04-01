RTOS Port
---

# Interrupt vector

+ SWI (S/w interrupt)
    > priority 最低

+ system tick
    > priority 最高

# Heap configuration

# Stack layout

General Purpose Registers push/pop order

## In ISR

Use stack pool for ISR

## In Context-Switch

Use stack pool for a task

+ stack initialize when a task creation

+ SWI trigger




