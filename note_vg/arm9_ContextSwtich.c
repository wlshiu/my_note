__attribute__((always_inline))
static inline void vPortSaveContext(void)
{
    __asm volatile ("nop                                    \n");
    __asm volatile ("nop                                    \n");
        // store r0 value to (sp_irq = sp_irq - 4). (is it necessary ??)
    __asm volatile ("stmdb  sp!, {r0}                       \n");

        // store the sp_usr to (sp_irq - 4)
    __asm volatile ("stmdb  sp, {sp}^                       \n");
    __asm volatile ("nop                                    \n");
        // user mode (sp_irq = sp_irq - 4)
    __asm volatile ("sub    sp, sp, #4                      \n");
        // load sp_irq to r0 and then (sp_irq = sp_irq + 4)
        // ps. r0 = sp_usr
    __asm volatile ("ldmia  sp!, {r0}                       \n");

        // store the lr_irq to sp_usr
        // and then (r0 = sp_usr - 4)
    __asm volatile ("stmdb  r0!, {lr}                       \n");

        // temporarily store (sp_usr - 4) to lr_irq and free r0 register
    __asm volatile ("mov    lr, r0                          \n");

        // load the original value of r0 (when enters IRQ) to r0
    __asm volatile ("ldmia  sp!, {r0}                       \n");

        // store r0~r12, sp_usr, lr_usr to (sp_usr - 4)
    __asm volatile ("stmdb  lr, {r0-lr}^                    \n");
    __asm volatile ("nop                                    \n");
        // lr = sp_usr - 4
        // lr = lr - 60 (15 words)
    __asm volatile ("sub    lr, lr, #60                     \n");

        // read spsr_irq to r0
    __asm volatile ("mrs    r0, spsr                        \n");
        // store spsr to (sp_usr - 4 - 60)
    __asm volatile ("stmdb  lr!, {r0}                       \n");

        // store data to stack of user mode
    __asm volatile ("ldr    r0, =ulCriticalNesting          \n");
    __asm volatile ("ldr    r0, [r0]                        \n");
    __asm volatile ("stmdb  lr!, {r0}                       \n");

        // Store the new top of stack for the task.
    __asm volatile ("ldr    r0, =pxCurrentTCB               \n");
    __asm volatile ("ldr    r0, [r0]                        \n");
    __asm volatile ("str    lr, [r0]                        \n");
    __asm volatile ("nop                                    \n");
}

//__attribute__((arm))
__attribute__((always_inline))
static inline void vPortRestoreContext(void)
{
    __asm volatile ("nop                                    \n");
    __asm volatile ("nop                                    \n");
        // Set the LR to the task stack.
    __asm volatile ("ldr    r0, =pxCurrentTCB               \n");
    __asm volatile ("ldr    r0, [r0]                        \n");
    __asm volatile ("ldr    lr, [r0]                        \n");

        // The critical nesting depth is the first item on the stack.
        // Load it into the ulCriticalNesting variable.
    __asm volatile ("ldr    r0, =ulCriticalNesting          \n");
    __asm volatile ("ldmia  lr!, {r1}                       \n");
    __asm volatile ("str    r1, [r0]                        \n");

        // load spsr_irq (at sp_usr - 4 - 60 - 4) to r0
        // lr = sp_usr - 4 - 60
    __asm volatile ("ldmia  lr!, {r0}                       \n");
        // set back the originalg spsr_irq
    __asm volatile ("msr    spsr_cxsf, r0                   \n");

        // load back original r0~r14 data (at sp_usr - 4) to r0~r14
    __asm volatile ("ldmia  lr, {r0-r14}^                   \n");
    __asm volatile ("nop                                    \n");
        // lr = sp_usr - 4 - 60
        // load back lr_irq (at sp_usr).
    __asm volatile ("ldr    lr, [lr, #+60]                  \n");

        // pc = lr_irq - 4 and return
    __asm volatile ("subs   pc, lr, #4                      \n");
}
