#ifndef __MURAX_H__
#define __MURAX_H__

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* =========================================================================
 * 1. 系統記憶體與周邊基底位址定義 (Memory Map)
 * ========================================================================= */
#define EFLASH_BASE             0x00000000UL
#define EFLASH_SIZE             (32 * 1024UL)

#define SRAM_BASE               0x20000000UL
#define SRAM_SIZE               (2 * 1024UL)

#define APB_PERIPH_BASE         0xF0000000UL
#define GPIO_A_BASE             (APB_PERIPH_BASE + 0x00000UL)
#define UART_BASE               (APB_PERIPH_BASE + 0x10000UL)
#define TIMER_BASE              (APB_PERIPH_BASE + 0x20000UL)

/* =========================================================================
 * 2. GPIO 控制器 (Apb3Gpio)
 * ========================================================================= */
typedef struct
{
    volatile uint32_t INPUT;            /* 0x00: 輸入接腳狀態 (Read-Only) */
    volatile uint32_t OUTPUT;           /* 0x04: 輸出資料暫存器 (R/W) */
    volatile uint32_t OUTPUT_ENABLE;    /* 0x08: 輸出致能 (1=Output, 0=Input) */
} Gpio_Reg;

#define GPIO_A                  ((Gpio_Reg *) GPIO_A_BASE)

/* =========================================================================
 * 3. UART 控制器 (Apb3UartCtrl)
 * ========================================================================= */
typedef struct
{
    volatile uint32_t DATA;             /* 0x00: TX/RX FIFO 資料讀寫 */
    volatile uint32_t STATUS;           /* 0x04: 狀態與中斷控制 */
    volatile uint32_t CLOCK_DIVIDER;    /* 0x08: 鮑率除頻器 */
    volatile uint32_t FRAME_CONFIG;     /* 0x0C: 訊框格式設定 */
} Uart_Reg;

#define UART                    ((Uart_Reg *) UART_BASE)

/* UART DATA 暫存器 Bit-fields */
#define UART_DATA_MASK                  (0xFFUL << 0)
#define UART_DATA_RX_VALID              (1UL << 16)

/* UART STATUS 暫存器 Bit-fields */
#define UART_STATUS_TX_INT_EN           (1UL << 0)
#define UART_STATUS_RX_INT_EN           (1UL << 1)
#define UART_STATUS_TX_INT_PENDING      (1UL << 8)
#define UART_STATUS_RX_INT_PENDING      (1UL << 9)

#define UART_STATUS_TX_AVAIL_SHIFT      16
#define UART_STATUS_TX_AVAIL_MASK       (0xFFUL << UART_STATUS_TX_AVAIL_SHIFT)
#define UART_STATUS_RX_OCCUPANCY_SHIFT  24
#define UART_STATUS_RX_OCCUPANCY_MASK   (0xFFUL << UART_STATUS_RX_OCCUPANCY_SHIFT)

/* UART FRAME_CONFIG 暫存器 Bit-fields */
#define UART_FRAME_DATA_LEN_MASK        (0xFFUL << 0)
#define UART_FRAME_PARITY_SHIFT         8
#define UART_FRAME_PARITY_MASK          (0xFFUL << UART_FRAME_PARITY_SHIFT)
#define UART_FRAME_STOP_SHIFT           16
#define UART_FRAME_STOP_MASK            (0xFFUL << UART_FRAME_STOP_SHIFT)

/* =========================================================================
 * 4. 計時器模組 (MuraxApb3Timer)
 * ========================================================================= */
typedef struct
{
    volatile uint32_t LIMIT;            /* +0x00: 16-bit 溢位上限值 */
    volatile uint32_t VALUE;            /* +0x04: 16-bit 當前計數值 */
    volatile uint32_t CTRL;             /* +0x08: 控制暫存器 (致能與自動重載) */
    volatile uint32_t RESERVED;         /* +0x0C: 保留對齊 */
} Timer_Channel_Reg;

typedef struct
{
    volatile uint32_t PRESCALER_LIMIT;  /* 0x00: 16-bit 預除頻上限 */
    volatile uint32_t RESERVED0[3];     /* 0x04 ~ 0x0C: 保留 */
    Timer_Channel_Reg TIMER_A;          /* 0x10 ~ 0x1C: 計時器 A */
    Timer_Channel_Reg TIMER_B;          /* 0x20 ~ 0x2C: 計時器 B */
    volatile uint32_t INTERRUPT_STATUS; /* 0x30: 中斷狀態 (Write-1-to-Clear) */
    volatile uint32_t INTERRUPT_MASK;   /* 0x34: 中斷遮罩 (1=Enable) */
} Timer_Block_Reg;

#define TIMER                   ((Timer_Block_Reg *) TIMER_BASE)

/* Timer CTRL 暫存器 Bit-fields */
#define TIMER_CTRL_EN                   (1UL << 0)  /* 1 = 啟動計數 */
#define TIMER_CTRL_AUTO_RELOAD          (1UL << 1)  /* 1 = 達到 LIMIT 自動清零循環 */
#define TIMER_CTRL_CASCADE_A            (1UL << 16) /* Timer B 串接 Timer A 脈衝 */

/* Timer INTERRUPT_STATUS / INTERRUPT_MASK Bit-fields */
#define TIMER_INT_A                     (1UL << 0)
#define TIMER_INT_B                     (1UL << 1)

/* =========================================================================
 * 5. RISC-V CSR 中斷控制巨集
 * ========================================================================= */
#define MSTATUS_MIE                     (1UL << 3)  /* Machine Global Interrupt Enable */
#define MIE_MTIE                        (1UL << 7)  /* Machine Timer Interrupt Enable */
#define MIE_MEIE                        (1UL << 11) /* Machine External Interrupt Enable */

#define MCAUSE_INT_FLAG                 (1UL << 31)
#define MCAUSE_CODE_MASK                0x7FFFFFFFUL
#define MCAUSE_MTI                      7UL         /* Machine Timer Interrupt */
#define MCAUSE_MEI                      11UL        /* Machine External Interrupt */

static inline uint32_t csr_read_mcause(void)
{
    uint32_t val;
    asm volatile ("csrr %0, mcause" : "=r"(val));
    return val;
}

static inline void irq_global_enable(void)
{
    asm volatile ("csrs mstatus, %0" :: "r"(MSTATUS_MIE));
}

static inline void irq_global_disable(void)
{
    asm volatile ("csrc mstatus, %0" :: "r"(MSTATUS_MIE));
}

static inline void irq_enable_sources(uint32_t mie_mask)
{
    asm volatile ("csrs mie, %0" :: "r"(mie_mask));
}

static inline void irq_disable_sources(uint32_t mie_mask)
{
    asm volatile ("csrc mie, %0" :: "r"(mie_mask));
}

/* =========================================================================
 * 6. 周邊內聯輔助函式 (Inline Helper Functions)
 * ========================================================================= */

/* --- GPIO 輔助函式 --- */
static inline void gpio_set_dir(uint32_t pin_mask, bool is_output)
{
    if (is_output)
    {
        GPIO_A->OUTPUT_ENABLE |= pin_mask;
    }
    else
    {
        GPIO_A->OUTPUT_ENABLE &= ~pin_mask;
    }
}

static inline void gpio_write(uint32_t value)
{
    GPIO_A->OUTPUT = value;
}

static inline void gpio_set_pins(uint32_t pin_mask)
{
    GPIO_A->OUTPUT |= pin_mask;
}

static inline void gpio_clear_pins(uint32_t pin_mask)
{
    GPIO_A->OUTPUT &= ~pin_mask;
}

static inline void gpio_toggle_pins(uint32_t pin_mask)
{
    GPIO_A->OUTPUT ^= pin_mask;
}

static inline uint32_t gpio_read(void)
{
    return GPIO_A->INPUT;
}

/* --- UART 輔助函式 --- */
static inline uint32_t uart_tx_free_slots(void)
{
    return (UART->STATUS & UART_STATUS_TX_AVAIL_MASK) >> UART_STATUS_TX_AVAIL_SHIFT;
}

static inline uint32_t uart_rx_available(void)
{
    return (UART->STATUS & UART_STATUS_RX_OCCUPANCY_MASK) >> UART_STATUS_RX_OCCUPANCY_SHIFT;
}

static inline void uart_putc(char c)
{
    while (uart_tx_free_slots() == 0);
    UART->DATA = (uint8_t)c;
}

static inline void uart_puts(const char *s)
{
    while (*s)
    {
        if (*s == '\n')
        {
            uart_putc('\r');
        }
        uart_putc(*s++);
    }
}

static inline void uart_put_hex(uint32_t val)
{
    const char hex[] = "0123456789ABCDEF";
    uart_puts("0x");
    for (int i = 28; i >= 0; i -= 4)
    {
        uart_putc(hex[(val >> i) & 0xFUL]);
    }
}

static inline void uart_rx_irq_enable(bool enable)
{
    if (enable)
    {
        UART->STATUS |= UART_STATUS_RX_INT_EN;
    }
    else
    {
        UART->STATUS &= ~UART_STATUS_RX_INT_EN;
    }
}

/* --- Timer 輔助函式 --- */
static inline void timer_set_prescaler(uint16_t divider)
{
    TIMER->PRESCALER_LIMIT = (divider > 0) ? (uint32_t)(divider - 1) : 0;
}

static inline void timer_a_init(uint16_t period_ticks, bool auto_reload, bool irq_en)
{
    TIMER->TIMER_A.CTRL = 0;
    TIMER->TIMER_A.VALUE = 0;
    TIMER->TIMER_A.LIMIT = (period_ticks > 0) ? (uint32_t)(period_ticks - 1) : 0;
    TIMER->INTERRUPT_STATUS = TIMER_INT_A; /* 清除殘留旗標 */

    if (irq_en)
    {
        TIMER->INTERRUPT_MASK |= TIMER_INT_A;
    }
    else
    {
        TIMER->INTERRUPT_MASK &= ~TIMER_INT_A;
    }

    uint32_t ctrl = TIMER_CTRL_EN | (auto_reload ? TIMER_CTRL_AUTO_RELOAD : 0);
    TIMER->TIMER_A.CTRL = ctrl;
}

static inline void timer_a_clear_irq(void)
{
    TIMER->INTERRUPT_STATUS = TIMER_INT_A;
}

#ifdef __cplusplus
}
#endif

#endif /* __MURAX_H__ */
