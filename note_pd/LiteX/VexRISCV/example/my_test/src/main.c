//#include "stddefs.h"
#include <stdint.h>

#include "murax_reg.h"

#define HSI_CLOCK_Hz        (12ul*1000*1000)


static uint32_t g_data_var = 0x12345678;  /* 應由 crt.S 從 Flash 搬移至 SRAM */
static uint32_t g_bss_var;                /* 應由 crt.S 清零為 0x00000000 */

static uint32_t g_exception_cause = 0;

/* 中斷狀態計數器 */
static uint32_t g_timer_ticks = 0;
static uint32_t g_uart_rx_count = 0;
static char     g_uart_last_char = 0;


static void delay_loops(volatile uint32_t count)
{
    while (count--)
    {
        asm volatile ("nop");
    }
}

void main()
{
    /* Clear interrupt penddings */
    TIMER_INTERRUPT->MASKS    = 0x0ul;
    TIMER_INTERRUPT->PENDINGS = 0xFFFFFFFF;

    timer_set_prescaler(HSI_CLOCK_Hz, 12*1000);

    gpio_set_dir(0xFF, true);
    gpio_write(0x0);

    uart_puts("\n========================================\n");
    uart_puts("  VexRiscv Murax SoC Core & Timer Test\n");
    uart_puts("========================================\n");

    uint32_t    mie_val, mstatus_val;
    /* ---------------------------------------------------------------------
     * 測試 0: 驗證硬體 CSR 實際寫入狀態
     * --------------------------------------------------------------------- */
    asm volatile ("csrr %0, mie" : "=r"(mie_val));
    asm volatile ("csrr %0, mstatus" : "=r"(mstatus_val));
    uart_puts("[Test 0] CSR Check:\n");
    uart_puts("  MIE     = "); uart_put_hex(mie_val);     uart_puts("\n");
    uart_puts("  MSTATUS = "); uart_put_hex(mstatus_val); uart_puts("\n");

    /* ---------------------------------------------------------------------
     * 測試 1: 全域變數讀寫 (.data 搬移, .bss 清零, $gp 定址)
     * --------------------------------------------------------------------- */
    uart_puts("\n[Test 1] SRAM .data & .bss Check:\n");
    uart_puts("  Init .data (expect 0x12345678) = "); uart_put_hex(g_data_var); uart_puts("\n");
    uart_puts("  Init .bss  (expect 0x00000000) = "); uart_put_hex(g_bss_var);  uart_puts("\n");

    g_data_var += 0x11111111;
    g_bss_var   = 0xAABBCCDD;
    if (g_data_var == 0x23456789 && g_bss_var == 0xAABBCCDD)
        uart_puts("  -> PASS!\n");
    else
        uart_puts("  -> FAIL!\n");

    /* ---------------------------------------------------------------------
     * 測試 2: RV32M 硬體乘除法指令驗證 (MulSimplePlugin + DivPlugin)
     * --------------------------------------------------------------------- */
    uart_puts("\n[Test 2] RV32M Hardware Mul/Div Check:\n");
    volatile uint32_t a = 12345;
    volatile uint32_t b = 6789;
    uint32_t mul_res = a * b;          /* 83810205 = 0x04FED1DD */
    uint32_t div_res = mul_res / 123;  /* 681383   = 0x000A65A7 */
    uint32_t rem_res = mul_res % 123;  /* 96       = 0x00000060 */

    uart_puts("  MUL = "); uart_put_hex(mul_res); uart_puts("\n");
    uart_puts("  DIV = "); uart_put_hex(div_res); uart_puts("\n");
    uart_puts("  REM = "); uart_put_hex(rem_res); uart_puts("\n");
    if (mul_res == 0x04FED79D && div_res == 0x000A65A7 && rem_res == 0x60)
        uart_puts("  -> PASS!\n");
    else
        uart_puts("  -> FAIL!\n");

    /* ---------------------------------------------------------------------
     * 測試 3: Timer 週期性中斷驗證 (12MHz -> 1ms tick, 觸發 5 次)
     * --------------------------------------------------------------------- */
    uart_puts("\n[Test 3] Timer Interrupt (mcause 0x80000007):\n");
    timer_set_prescaler(12000000, 1000000); /* 12MHz / 12 = 1MHz (1us/tick) */
    timer_init(TIMA, 1000, true, true);     /* 1000us = 1ms 自動重載並開啟中斷 */

    while (g_timer_ticks < 5);              /* 等待 5 次中斷 (5ms) */
    timer_init(TIMA, 1000, false, false);   /* 關閉 Timer A 中斷 */

    uart_puts("  Timer ticks = "); uart_put_hex(g_timer_ticks); uart_puts("\n");
    uart_puts("  -> PASS!\n");

    /* ---------------------------------------------------------------------
     * 測試 4: UART RX 外部中斷驗證 (mcause 0x8000000B)
     * --------------------------------------------------------------------- */
    uart_puts("\n[Test 4] UART RX Interrupt (mcause 0x8000000B):\n");

    /* 先清空開機可能殘留的 RX FIFO */
    while (uart_rx_available() > 0)
    {
        volatile uint32_t dummy = UART->DATA;
        (void)dummy;
    }

    /* 開啟 UART RX 中斷 (利用 murax_reg.h 內建函式) */
    uart_rx_irq_enable(true);

    uart_puts("  [Waiting] Please type a character and press Enter...\n");

    /* 等待至少接收到 1 個字元觸發中斷 */
    while (g_uart_rx_count == 0);

    /* 稍微等待讓同一行輸入的剩餘字元 (例如 '\n') 也收完 */
    delay_loops(50000);

    uart_puts("  UART RX IRQ Count = "); uart_put_hex(g_uart_rx_count);  uart_puts("\n");
    uart_puts("  Last RX Byte      = "); uart_put_hex(g_uart_last_char); uart_puts("\n");
    uart_puts("  -> PASS!\n");

    uart_puts("\n========================================\n");
    uart_puts("  Core & Timer Tests Completed!\n");
    uart_puts("========================================\n");


    while(1)
    {
        asm volatile ("nop");
        asm volatile ("nop");
        asm volatile ("nop");
    }

}

__attribute__((optimize("O0")))
void irqCallback(void)
{
    uint32_t    mcause = csr_read_mcause();

    if( !(mcause & MCAUSE_INT_FLAG) )
    {
        // exception
        g_exception_cause = mcause;
        return;
    }

    mcause &= MCAUSE_CODE_MASK;

    if( mcause == MCAUSE_MTI ) /* 1. 檢查是否為 Timer 中斷 (Machine Timer Interrupt, Code = 7) */
    {
        if( TIMER_INTERRUPT->PENDINGS & TIMER_IRQ_A )
        {
            g_timer_ticks++;
            timer_a_clear_irq();
        }
    }

    if( mcause == MCAUSE_MEI ) /* 2. 檢查是否為外部中斷 (Machine External Interrupt, Code = 11) */
    {
        uint32_t    status = 0;

        /**
         *  Software interrupt priority
         */

        /* 檢查 SPI RX FIFO 非空中斷 (STATUS Bit 9 = RX Interrupt Pending) */
        if( SPI->STATUS & (1 << 9) )
        {
        }

        /* 檢查 I2C 中斷旗標 */
        status = I2C->INT_FLAG;
        if( status & I2C_INT_RX_DATA_FULL )
        {
        }

        /* 檢查 UART RX 中斷 (若也有開啟 UART 中斷) */
        status = UART->STATUS;
        if( status & UART_STATUS_RX_INT_PENDING )   /* RX FIFO Interrupt Pending */
        {
            while( uart_rx_available() ) // Rx FIFO remain
            {
                /**
                 *  Verilator Simulator 用 hbreak 無法停下來,
                 *  但執行正確
                 */
                uint8_t    rx_val = (uint8_t)(UART->DATA & 0xFF);

                g_uart_rx_count++;
                g_uart_last_char = (char)rx_val;

                uart_putc(rx_val);
            }
        }
    }

    return;
}
