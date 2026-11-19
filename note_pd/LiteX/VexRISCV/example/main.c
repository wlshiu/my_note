#include "murax_reg.h"

void irqCallback(void)
{
    uint32_t mcause = csr_read_mcause();

    if (mcause & MCAUSE_INT_FLAG)
    {
        uint32_t code = mcause & MCAUSE_CODE_MASK;

        if (code == MCAUSE_MTI && (TIMER->INTERRUPT_STATUS & TIMER_INT_A))
        {
            /* 1. 檢查是否為 Timer 中斷 (Machine Timer Interrupt, Code = 7) */
            timer_a_clear_irq();
        }
        else if (code == MCAUSE_MEI) /* 2. 檢查是否為外部中斷 (Machine External Interrupt, Code = 11) */
        {
            /* (A) 檢查 SPI RX FIFO 非空中斷 (STATUS Bit 9 = RX Interrupt Pending) */
            if (SPI->STATUS & (1 << 9))
            {
                uint32_t rx_val = SPI->DATA;
                while (rx_val & (1 << 31))   /* Bit[31] == 1 代表 RX FIFO 有有效資料 */
                {
                    spi_rx_buf[spi_rx_head & 0x0F] = (uint8_t)(rx_val & 0xFF);
                    spi_rx_head++;
                    rx_val = SPI->DATA; /* 讀空 FIFO 後中斷訊號會自動解除 */
                }
            }

            /* (B) 檢查 I2C 中斷旗標 */
            uint32_t    i2c_flags = I2C->INT_FLAG;
            if (i2c_flags & I2C_INT_RX_DATA_FULL)
            {
                uint32_t rx = I2C->RX_DATA;
                if (rx & I2C_TX_VALID)
                {
                    i2c_last_rx = (uint8_t)(rx & 0xFF);
                    i2c_rx_done = 1;
                }
                /* 寫 1 清除 I2C 中斷旗標，避免重複觸發 */
                I2C->INT_FLAG = I2C_INT_RX_DATA_FULL;
            }

            /* (C) 檢查 UART RX 中斷 (若也有開啟 UART 中斷) */
            uint32_t    uart_status = *(volatile uint32_t *)(UART_BASE + 0x04);
            if (uart_status & (1 << 9))   /* RX FIFO Interrupt Pending */
            {
                while (uart_rx_available() > 0)
                {
                    uart_putc((char)(UART->DATA & UART_DATA_MASK));
                }
            }

        }
    }
}

int main(void)
{
    gpio_set_dir(0xFF, true);
    timer_set_prescaler(12000);          /* 12MHz -> 1ms tick */
    timer_a_init(200, true, true);       /* 200ms 週期中斷 */
    uart_rx_irq_enable(true);

    irq_enable_sources(MIE_MTIE | MIE_MEIE);
    irq_global_enable();

    uart_puts("Murax Header Ready!\n");
    while (1);
}
