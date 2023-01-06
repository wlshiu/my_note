/**
 * Copyright (c) 2023 Wei-Lun Hsu. All Rights Reserved.
 */
/** @file exception_HardFault.c
 *
 * @author Wei-Lun Hsu
 * @version 0.1
 * @date 2023/01/06
 * @license
 * @description
 */


#include <stdint.h>
#include <stdarg.h>

#if defined(CONFIG_USE_F103)
#include "xxx32f1x.h"
#endif
//=============================================================================
//                  Constant Definition
//=============================================================================

// BFSR flags
#define IBUSERR         (0x1ul << 0)
#define PRECISERR       (0x1ul << 1)
#define IMPRECISERR     (0x1ul << 2)
#define UNSTKERR        (0x1ul << 3)
#define STKERR          (0x1ul << 4)
#define BFARVALID       (0x1ul << 7)

// UFSR flags
#define UNDEFINSTR      (0x1ul << 0)
#define INVSTATE        (0x1ul << 1)
#define INVPC           (0x1ul << 2)
#define NOCP            (0x1ul << 3)
#define UNALIGNED       (0x1ul << 8)
#define DIVBYZERO       (0x1ul << 9)

// MMFSR flags
#define IACCVIOL        (0x1ul << 0)
#define DACCVIOL        (0x1ul << 1)
#define MUNSTKERR       (0x1ul << 3)
#define MSTKERR         (0x1ul << 4)
#define MMARVALID       (0x1ul << 7)
//=============================================================================
//                  Macro Definition
//=============================================================================

#if defined(CONFIG_USE_F103)

#ifndef BB_PERI_ADDR
#define BB_PERI_ADDR(reg, bit)     (volatile uint32_t*)(PERIPH_BB_BASE + ((((uint32_t)&(reg) - PERIPH_BASE) << 5) + ((bit) << 2)))
#endif // BB_PERI_ADDR

#ifndef BB_PERI_REG
#define BB_PERI_REG(reg, bit)      (*BB_PERI_ADDR(reg, bit))
#endif  // BB_PERI_REG

#endif

//=============================================================================
//                  Structure Definition
//=============================================================================

//=============================================================================
//                  Global Data Definition
//=============================================================================

//=============================================================================
//                  Private Function Definition
//=============================================================================
static void
_send_bytes(const char *pCur, int len)
{
    while( len-- )
    {
#if defined(CONFIG_USE_F103)
        while( BB_PERI_REG(USART1->SR, USART_SR_TXE_Pos) == 0 ) {}
        BB_PERI_REG(USART1->SR, USART_SR_TXE_Pos) = 0x0;

        USART1->DR = *pCur++;

        while( BB_PERI_REG(USART1->SR, USART_SR_TC_Pos) == 0 ) {}
        BB_PERI_REG(USART1->SR, USART_SR_TC_Pos) = 0x0;
#endif
    }
    return;
}

static int _do_strlen(const char *str)
{
    int     cnt;
    for(cnt = 0; *str; ++cnt, ++str);
    return cnt;
}

static char *_do_itoa(const char *numbox, int num, unsigned int base)
{
    static char buf[16] = {0};
    int     i;
    if(num == 0)
    {
        buf[14] = '0';
        return &buf[14];
    }

    int negative = (num < 0);

    if(negative)
        num = -num;

    for(i = 14; i >= 0 && num; --i, num /= base)
        buf[i] = numbox[num % base];

    if(negative)
    {
        buf[i] = '-';
        --i;
    }
    return buf + i + 1;
}

static int _do_printf(const char *format, ...)
{
    int i, count = 0;

    va_list(v1);
    va_start(v1, format);

    int tmpint;
    char *tmpcharp;

    for(i = 0; format[i]; ++i)
    {
        if(format[i] == '%')
        {
            char        flag_field_width = -1;

            switch(format[i + 1])
            {
                case '%':
                    tmpint = '%';
                    _send_bytes((char*)&tmpint, 1);
                    break;
                case 'd':
                case 'x':
                case 'X':
                    tmpint = va_arg(v1, int);
                    tmpcharp = _do_itoa(format[i + 1] == 'x' ? "0123456789abcdef" : "0123456789ABCDEF",
                                        tmpint, format[i + 1] == 'd' ? 10 : 16);
                    _send_bytes(tmpcharp, _do_strlen(tmpcharp));
                    break;
                case 's':
                    tmpcharp = va_arg(v1, char *);
                    _send_bytes(tmpcharp, _do_strlen(tmpcharp));
                    break;
            }
            /* Skip the next character */
            ++i;
        }
        else
            _send_bytes(format + i, 1);
    }

    va_end(v1);
    return count;
}

static void
_usage_err(uint32_t CFSR_Value)
{
    uint32_t    UFSR = ((CFSR_Value & SCB_CFSR_USGFAULTSR_Msk) >> SCB_CFSR_USGFAULTSR_Pos);

    _do_printf("\n>>> Usage fault: (CFSR= x%x, UFSR= x%x)\n"
               "%s%s%s%s%s%s",
               CFSR_Value, UFSR,
               (UFSR & DIVBYZERO)  ? "  Divide by zero UsageFault\n" : "",
               (UFSR & UNALIGNED)  ? "  Un-aligned access UsageFault\n" : "",
               (UFSR & NOCP)       ? "  No coprocessor UsageFault\n" : "",
               (UFSR & INVPC)      ? "  Invalid PC load UsageFault\n" : "",
               (UFSR & INVSTATE)   ? "  Invalid state UsageFault\n" : "",
               (UFSR & UNDEFINSTR) ? "  Undefined instruction UsageFault\n" : "");
    return;
}

static void
_bus_fault_err(uint32_t CFSR_Value)
{
    uint32_t    BFSR = ((CFSR_Value & SCB_CFSR_BUSFAULTSR_Msk) >> SCB_CFSR_BUSFAULTSR_Pos);

    _do_printf("\n>>> Bus fault: (CFSR = x%x, BFSR= x%x)\n"
               "%s%s%s%s%s%s",
               CFSR_Value, BFSR,
               (BFSR & IBUSERR)     ? "  IBUSERR\n" : "",
               (BFSR & PRECISERR)   ? "  Precise Data Bus Error\n" : "",
               (BFSR & IMPRECISERR) ? "  Imprecise Data Bus Error\n" : "",
               (BFSR & UNSTKERR)    ? "  Unstacking Error\n" : "",
               (BFSR & STKERR)      ? "  Stacking error\n" : "",
               (BFSR & BFARVALID)   ? "  Bus Fault Address Register Valid\n" : "");
    return;
}

static void
_mem_mgt_err(uint32_t CFSR_Value)
{
    uint32_t    MMFSR = (CFSR_Value & SCB_CFSR_MEMFAULTSR_Msk);

    _do_printf("\n>>> Mem Mgt fault: (CFSR = x%x, MMFSR= x%x)\n"
               "%s%s%s%s%s",
               CFSR_Value, MMFSR,
               (MMFSR & IACCVIOL)  ? "  Instruction Access Violation\n" : "",
               (MMFSR & DACCVIOL)  ? "  Data Access Violation\n" : "",
               (MMFSR & MUNSTKERR) ? "  Memory Unstacking Error\n" : "",
               (MMFSR & MSTKERR)   ? "  Memory Stacking Error\n" : "",
               (MMFSR & MMARVALID) ? "  MMARVALID\n" : "");
    return;
}

static void
_dbg_fault(uint32_t DFSR_Value)
{
    _do_printf("\n>>> Debug Fault: (DFSR = x%x)\n"
               "%s%s%s%s%s",
               DFSR_Value,
               (DFSR_Value & SCB_DFSR_EXTERNAL_Msk) ? "  EXTERNAL\n" : "",
               (DFSR_Value & SCB_DFSR_VCATCH_Msk)   ? "  VCATCH\n" : "",
               (DFSR_Value & SCB_DFSR_DWTTRAP_Msk)  ? "  DWTTRAP\n" : "",
               (DFSR_Value & SCB_DFSR_BKPT_Msk)     ? "  BKPT\n" : "",
               (DFSR_Value & SCB_DFSR_HALTED_Msk)   ? "  HALTED\n" : "");
    return;
}

void __attribute__((used))
_hal_hard_fault_handler(uint32_t *sp)
{
    /**
     *  These are volatile to try and prevent the compiler/linker optimising them
     *  away as the variables never actually get used.  If the debugger won't show the
     *  values of the variables, make them global my moving their declaration outside of this function.
     */
    volatile uint32_t   r0, r1, r2, r3;
    volatile uint32_t   r12;
    volatile uint32_t   lr; /* Link register. */
    volatile uint32_t   pc; /* Program counter. */
    volatile uint32_t   psr;/* Program status register. */

    volatile uint32_t cfsr  = SCB->CFSR;
    volatile uint32_t hfsr  = SCB->HFSR;
    volatile uint32_t mmfar = SCB->MMFAR;
    volatile uint32_t bfar  = SCB->BFAR;
    volatile uint32_t dfsr  = SCB->DFSR;

    _do_printf("\n=========\nHard Fault:\n"
             "SCB->CFSR  = x%x\n",
             "SCB->HFSR  = x%x\n",
             "SCB->MMFAR = x%x\n",
             "SCB->BFAR  = x%x\n\n",
             cfsr, hfsr, mmfar, bfar);

    if( (hfsr & SCB_HFSR_FORCED_Msk) )
    {
        if( (cfsr & SCB_CFSR_USGFAULTSR_Msk) )
            _usage_err(cfsr);

        if( (cfsr & SCB_CFSR_BUSFAULTSR_Msk) )
            _bus_fault_err(cfsr);

        if( (cfsr & SCB_CFSR_MEMFAULTSR_Msk) )
            _mem_mgt_err(cfsr);
    }

    _dbg_fault(dfsr);

    r0  = sp[0];
    r1  = sp[1];
    r2  = sp[2];
    r3  = sp[3];
    r12 = sp[4];
    lr  = sp[5];
    pc  = sp[6];
    psr = sp[7];

    _do_printf("=================== Registers information ====================\n"
               "R0 : x%x\n"
               "R1 : x%x\n"
               "R2 : x%x\n"
               "R3 : x%x\n"
               "R12: x%x\n"
               "LR : x%x\n"
               "PC : x%x\n"
               "PSR: x%x\n"
               "==============================================================\n",
               r0, r1, r2, r3, r12, lr, pc, psr);

    while(1);
    return;
}
//=============================================================================
//                  Public Function Definition
//=============================================================================
// void exception_dump(void) __attribute__((naked));
#if defined(__CC_ARM)
__asm void HardFault_Handler(void)
{
    IMPORT  _hal_hard_fault_handler
    MOV     R0, LR
    LSLS    R0, #29               //; Check bit 2
    BMI     SP_is_PSP             //; previous stack is PSP
    MRS     R0, MSP               //; previous stack is MSP, read MSP
    B       SP_Read_Ready
SP_is_PSP
    MRS     R0, PSP               //; Read PSP

SP_Read_Ready
    B       _hal_hard_fault_handler
}

#elif defined(__GNUC__)

void HardFault_Handler(void)
{
#if 0//defined(CONFIG_USE_F103)
    BB_PERI_REG(RCC->APB2ENR, RCC_APB2ENR_USART1EN_Pos) = 0x1;

    /**
     *  USART1 GPIO Configuration
     *  PA8     ------> USART1_CK
     *  PA9     ------> USART1_TX
     *  PA10    ------> USART1_RX
     */
    BB_PERI_REG(RCC->APB2ENR, RCC_APB2ENR_IOPAEN_Pos) = 0x1;
    GPIOA->CRH  |= 0x04B0;

    USARTx->BRR  = CONFIG_USART_BAUD_RATE;
    USARTx->CR1  = 0x0000200C;
#endif

    __asm volatile (
        " tst lr, #4                \n"
        " ite eq                    \n"
        " mrseq r0, msp             \n"
        " mrsne r0, psp             \n"
        " b _hal_hard_fault_handler \n"
    );
}
#endif
