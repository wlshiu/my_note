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
#define GPIO_A_BASE             0xF0000000UL
#define UART_BASE               0xF0010000UL

#define TIMER_PRESCALER_BASE    0xF0020000UL
#define TIMER_INTERRUPT_BASE    0xF0020010UL
#define TIMER_A_BASE            0xF0020040UL
#define TIMER_B_BASE            0xF0020050UL

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
typedef enum
{
    NONE = 0,
    EVEN = 1,
    ODD = 2
} UartParity;

typedef enum
{
    ONE = 0,
    TWO = 1
} UartStop;

typedef struct
{
    uint32_t    dataLength;
    UartParity  parity;
    UartStop    stop;
    uint32_t    clockDivider;
} Uart_Config;

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
#define UART_FRAME_DATA_LEN_SHIFT       0
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
    volatile uint32_t LIMIT;
} Prescaler_Reg;

typedef struct
{
    volatile uint32_t PENDINGS;
    volatile uint32_t MASKS;
} InterruptCtrl_Reg;

typedef struct
{
    volatile uint32_t CLEARS_TICKS;
    volatile uint32_t LIMIT;
    volatile uint32_t VALUE;
} Timer_Reg;


#define TIMER_PRESCALER     ((Prescaler_Reg *)     TIMER_PRESCALER_BASE)
#define TIMER_INTERRUPT     ((InterruptCtrl_Reg *) TIMER_INTERRUPT_BASE)
#define TIMA                ((Timer_Reg *)         TIMER_A_BASE)
#define TIMB                ((Timer_Reg *)         TIMER_B_BASE)

/* 2. Timer 控制位元巨集 */
#define TIMER_TICK_CLK         (1 << 0)   // 使用系統時脈計數
#define TIMER_TICK_PRESCALER   (1 << 1)   // 使用 Prescaler 溢位脈衝計數
// #define TIMER_CLEAR_ON_LIMIT   (1 << 16)  // 達到 LIMIT 時自動歸零 (Auto-reload)
#define TIMER_AUTO_RELOAD      (1 << 16)  // 達到 LIMIT 時自動歸零 (Auto-reload)

#define TIMER_IRQ_A            (1 << 0)   // Timer A 中斷位元
#define TIMER_IRQ_B            (1 << 1)   // Timer B 中斷位元

/* =========================================================================
 * 1. APB3 SPI Master 暫存器定義 (Base: 0xF0030000)
 * ========================================================================= */
#define SPI_BASE        0xF0030000

typedef struct
{
    volatile uint32_t DATA;       /* 0x00: TX/RX FIFO 讀寫 (Bit[31]=RX Valid, Bit[24]=Push RX, Bit[7:0]=Data) */
    volatile uint32_t STATUS;     /* 0x04: Bit[31:16]=TX FIFO 可用空間, Bit[9]=RX中斷Pending, Bit[8]=Cmd空Pending, Bit[1]=RX中斷致能, Bit[0]=Cmd空中斷致能 */
    volatile uint32_t CONFIG;     /* 0x08: Bit[0]=CPOL, Bit[1]=CPHA, Bit[7:4]=SS Active High Mask */
    volatile uint32_t CLOCK_DIV;  /* 0x0C: SCLK 除頻器 (SCLK = F_sys / (2 * (CLOCK_DIV + 1))) */
    volatile uint32_t SS_SETUP;   /* 0x10: SS 拉低到第一個 SCLK 的延遲週期數 */
    volatile uint32_t SS_HOLD;    /* 0x14: 最後一個 SCLK 到 SS 拉高的延遲週期數 */
    volatile uint32_t SS_DISABLE; /* 0x18: 連續傳輸間 SS 維持高電位的最小週期數 */
} Spi_Reg;

#define SPI ((Spi_Reg *)SPI_BASE)

/* SPI DATA 讀取 Bit-fields */
#define SPI_DATA_RX_VALID           (1UL << 31)
#define SPI_DATA_MASK               (0xFFUL)

/* SPI STATUS Bit-fields */
#define SPI_STATUS_CMD_INT_EN       (1UL << 0)
#define SPI_STATUS_RX_INT_EN        (1UL << 1)
#define SPI_STATUS_CMD_INT_PENDING  (1UL << 8)
#define SPI_STATUS_RX_INT_PENDING   (1UL << 9)
#define SPI_STATUS_TX_AVAIL_SHIFT   16
#define SPI_STATUS_TX_AVAIL_MASK    (0xFFFFUL << SPI_STATUS_TX_AVAIL_SHIFT)



/* SPI 命令格式 (寫入 SPI->DATA) */
#define SPI_CMD_DATA(byte)      (0x00000000 | ((byte) & 0xFF))  /* 僅送出 1 Byte */
#define SPI_CMD_DATA_RX(byte)   (0x01000000 | ((byte) & 0xFF))  /* 送出 1 Byte 並將接收資料推入 RX FIFO */
#define SPI_CMD_SS_ENABLE(id)   (0x11000000 | ((id) & 0xFF))    /* 拉低指定 SS 片選腳 (例如 id=0) */
#define SPI_CMD_SS_DISABLE(id)  (0x10000000 | ((id) & 0xFF))    /* 釋放指定 SS 片選腳 */

/* =========================================================================
 * 2. APB3 I2C Controller 暫存器定義 (Base: 0xF0040000)
 * ========================================================================= */
#define I2C_BASE        0xF0040000

typedef struct
{
    volatile uint32_t TX_DATA;        /* 0x00: Bit[8]=Valid, Bit[9]=Enable, Bit[10]=Repeat, Bit[11]=DisableOnDataConflict, Bit[7:0]=Data */
    volatile uint32_t TX_ACK;         /* 0x04: Bit[8]=Valid, Bit[9]=Enable, Bit[10]=Repeat, Bit[0]=ACK/NACK (0=ACK, 1=NACK) */
    volatile uint32_t RX_DATA;        /* 0x08: Bit[8]=Valid (讀取後自動清除), Bit[7:0]=Received Data */
    volatile uint32_t RX_ACK;         /* 0x0C: Bit[8]=Valid, Bit[0]=Received ACK (0=ACK, 1=NACK) */
    volatile uint32_t RESERVED0[4];   /* 0x10 ~ 0x1C */
    volatile uint32_t INT_ENABLE;     /* 0x20: 中斷致能遮罩 */
    volatile uint32_t INT_FLAG;       /* 0x24: 中斷狀態旗標 (寫 1 清除) */
    volatile uint32_t SAMPLING_DIV;   /* 0x28: 輸入取樣時脈除頻 */
    volatile uint32_t TIMEOUT;        /* 0x2C: Bus 逾時週期數 */
    volatile uint32_t TSU_DAT;        /* 0x30: Data Setup Time */
    volatile uint32_t RESERVED1[3];   /* 0x34 ~ 0x3C */
    volatile uint32_t MASTER_STATUS;  /* 0x40: Bit[0]=IsBusy, Bit[4]=Start, Bit[5]=Stop, Bit[6]=Drop */
    volatile uint32_t RESERVED2[3];   /* 0x44 ~ 0x4C */
    volatile uint32_t T_LOW;          /* 0x50: SCL 低電位週期數 */
    volatile uint32_t T_HIGH;         /* 0x54: SCL 高電位週期數 */
    volatile uint32_t T_BUF;          /* 0x58: Bus Free Time (Stop 到 Start 間隔) */
} I2c_Reg;

#define I2C ((I2c_Reg *)I2C_BASE)

/* I2C 常用控制位元 */
#define I2C_TX_VALID            (1 << 8)
#define I2C_TX_ENABLE           (1 << 9)
#define I2C_RX_VALID            (1 << 8)
#define I2C_RX_LISTEN           (1 << 9)  /* 必須設為 1 才會鎖存接收到的 Data/ACK */
#define I2C_RX_DATA_MASK        (0xFF)
#define I2C_TX_ACK_NACK         (1 << 0)  /* 0 = ACK, 1 = NACK */
#define I2C_RX_ACK_NACK         (1 << 0)  /* 0 = 收到 ACK, 1 = 收到 NACK */

#define I2C_MASTER_BUSY         (1 << 0)
#define I2C_MASTER_START        (1 << 4)
#define I2C_MASTER_STOP         (1 << 5)
#define I2C_MASTER_DROP         (1 << 6)

/* I2C 中斷位元 (依據 Murax.v 實際映射) */
#define I2C_INT_RX_DATA         (1 << 0)  /* INT_ENABLE Bit 0: RX_DATA Valid 中斷 */
#define I2C_INT_RX_ACK          (1 << 1)  /* INT_ENABLE Bit 1: RX_ACK Valid 中斷 */
#define I2C_INT_TX_DATA_EMPTY   (1 << 2)  /* INT_ENABLE Bit 2 */
#define I2C_INT_TX_ACK_EMPTY    (1 << 3)  /* INT_ENABLE Bit 3 */
#define I2C_INT_START           (1 << 4)  /* INT_ENABLE / INT_FLAG Bit 4 */
#define I2C_INT_RESTART         (1 << 5)  /* INT_ENABLE / INT_FLAG Bit 5 */
#define I2C_INT_STOP            (1 << 6)  /* INT_ENABLE / INT_FLAG Bit 6 */
#define I2C_INT_DROP            (1 << 7)  /* INT_ENABLE / INT_FLAG Bit 7 */

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
static inline void uart_init(Uart_Config *pCfg)
{
    UART->CLOCK_DIVIDER = pCfg->clockDivider;
    UART->FRAME_CONFIG  = ((pCfg->dataLength - 1) << UART_FRAME_DATA_LEN_SHIFT) | \
                          (pCfg->parity << UART_FRAME_PARITY_SHIFT) | \
                          (pCfg->stop << UART_FRAME_STOP_SHIFT);
    return;
}

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
static inline void timer_set_prescaler(uint32_t pclk, uint32_t divider)
{
    divider = (divider) ? divider : 1;
    TIMER_PRESCALER->LIMIT = (pclk / divider) - 1;
    return;
}

static inline void timer_init(Timer_Reg *pTim, uint16_t period_ticks, bool auto_reload, bool irq_en)
{
    // 設定 Timer：每 1000 個 us (即 1 ms) 溢位一次並自動歸零
    pTim->LIMIT = period_ticks - 1;
    pTim->VALUE = 0; // 清空目前計數值
    pTim->CLEARS_TICKS = (auto_reload ? TIMER_AUTO_RELOAD : 0) | TIMER_TICK_PRESCALER;

    // 清除殘留的中斷旗標並開啟 Timer A 中斷遮罩
    if( irq_en )
    {
        if( pTim == TIMA )
        {
            TIMER_INTERRUPT->PENDINGS |= TIMER_IRQ_A;
            TIMER_INTERRUPT->MASKS    |= TIMER_IRQ_A;
        }
        else if( pTim == TIMB )
        {
            TIMER_INTERRUPT->PENDINGS |= TIMER_IRQ_B;
            TIMER_INTERRUPT->MASKS    |= TIMER_IRQ_B;
        }
    }
    else
    {
        if( pTim == TIMA )
        {
            TIMER_INTERRUPT->MASKS    &= ~TIMER_IRQ_A;
            TIMER_INTERRUPT->PENDINGS &= ~TIMER_IRQ_A;
        }
        else if( pTim == TIMB )
        {
            TIMER_INTERRUPT->MASKS    &= ~TIMER_IRQ_B;
            TIMER_INTERRUPT->PENDINGS &= ~TIMER_IRQ_B;
        }
    }
    return;
}

static inline void timer_a_clear_irq(void)
{
    TIMER_INTERRUPT->PENDINGS |= TIMER_IRQ_A;
    return;
}

static inline void timer_b_clear_irq(void)
{
    TIMER_INTERRUPT->PENDINGS |= TIMER_IRQ_B;
    return;
}

/* --- SPI 輔助函式 --- */
static inline void spi_init_master(uint32_t clk_div, uint32_t mode)
{
    SPI->CONFIG     = (mode & 0x03);     /* Mode 0~3 (Bit0=CPOL, Bit1=CPHA), SS Active-Low */
    SPI->CLOCK_DIV  = clk_div;           /* 12MHz / (2 * (clk_div + 1)) -> div=5 時為 1MHz */
    SPI->SS_SETUP   = 2;
    SPI->SS_HOLD    = 2;
    SPI->SS_DISABLE = 2;
    return;
}

static inline void spi_rx_irq_enable(bool enable)
{
    if (enable)
        SPI->STATUS |= SPI_STATUS_RX_INT_EN;
    else
        SPI->STATUS &= ~SPI_STATUS_RX_INT_EN;
}

static inline uint32_t spi_tx_free_slots(void)
{
    return (SPI->STATUS & SPI_STATUS_TX_AVAIL_MASK) >> SPI_STATUS_TX_AVAIL_SHIFT;
}

static inline void spi_push_cmd(uint32_t cmd)
{
    while (spi_tx_free_slots() == 0);
    SPI->DATA = cmd;
}

/* --- I2C 輔助函式 --- */
static inline void i2c_init_master_100khz(void)
{
    I2C->SAMPLING_DIV = 2;      /* 12MHz / (2 + 1) = 4MHz 取樣率 */
    // I2C->TIMEOUT      = 0;      /* 停用 Timeout 避免單步除錯或模擬誤觸發 */
    I2C->TIMEOUT      = 120000; /* 10ms 逾時保護 (不可設為 0，否則會立即觸發 Drop) */
    I2C->TSU_DAT      = 6;      /* 500ns Data Setup Time */
    I2C->T_LOW        = 60;     /* 5us SCL Low (12MHz * 5us = 60) */
    I2C->T_HIGH       = 60;     /* 5us SCL High (12MHz * 5us = 60) */
    I2C->T_BUF        = 60;     /* 5us Bus Free Time */

    /* 清除所有殘留中斷旗標 */
    I2C->INT_FLAG     = 0xFFFFFFFF;
}

static inline void i2c_irq_enable(uint32_t mask)
{
    I2C->INT_ENABLE |= mask;
}

static inline void i2c_irq_disable(uint32_t mask)
{
    I2C->INT_ENABLE &= ~mask;
}

static inline void i2c_master_start(void)
{
    I2C->MASTER_STATUS = I2C_MASTER_START;
    while (I2C->MASTER_STATUS & I2C_MASTER_START);
}

static inline void i2c_master_stop(void)
{
    I2C->MASTER_STATUS = I2C_MASTER_STOP;
    while (I2C->MASTER_STATUS & I2C_MASTER_STOP);
}

/* Master 送出 1 Byte 並等待 Slave 回應 ACK (回傳 true 代表收到 ACK) */
static inline bool i2c_master_write_byte(uint8_t byte)
{
    I2C->RX_ACK  = I2C_RX_LISTEN; /* 開啟 RX_ACK 鎖存 */
    I2C->TX_DATA = (uint32_t)byte | I2C_TX_VALID | I2C_TX_ENABLE;
    I2C->TX_ACK  = I2C_TX_VALID;  /* ENABLE=0: 釋放 SDA 讀取 Slave ACK */

    uint32_t ack;
    do {
        ack = I2C->RX_ACK;
    } while (!(ack & I2C_RX_VALID));

    return ((ack & I2C_RX_ACK_NACK) == 0);
}

/* Master 觸發接收 1 Byte (由中斷或輪詢讀取 RX_DATA)，send_nack=true 代表最後一筆 */
static inline void i2c_master_trigger_read_byte(bool send_nack)
{
    I2C->RX_DATA = I2C_RX_LISTEN; /* 開啟 RX_DATA 鎖存 */
    I2C->TX_DATA = I2C_TX_VALID;  /* ENABLE=0: 釋放 SDA 讓 Slave 傳送資料 */
    I2C->TX_ACK  = I2C_TX_VALID | I2C_TX_ENABLE | (send_nack ? I2C_TX_ACK_NACK : 0);
}

#ifdef __cplusplus
}
#endif

#endif /* __MURAX_H__ */
