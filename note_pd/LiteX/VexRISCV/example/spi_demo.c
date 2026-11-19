#include "murax_reg.h"

volatile uint8_t spi_rx_buf[16];
volatile uint8_t spi_rx_head = 0;

void spi_init(void)
{
    /* SPI Mode 0 (CPOL=0, CPHA=0), SS 低電位有效 (Active Low) */
    SPI->CONFIG = 0x00;

    /* 12 MHz / (2 * (5 + 1)) = 1 MHz SCLK */
    SPI->CLOCK_DIV  = 5;
    SPI->SS_SETUP   = 12; /* 1 us setup time */
    SPI->SS_HOLD    = 12; /* 1 us hold time */
    SPI->SS_DISABLE = 12; /* 1 us between transfers */

    /* 開啟 RX FIFO 非空硬體中斷 (Bit 1) */
    SPI->STATUS = (1 << 1);
}

/* 全雙工讀寫範例：拉低 SS0 -> 傳送並接收多筆資料 -> 釋放 SS0 */
void spi_transfer_block(const uint8_t *tx_data, uint32_t len)
{
    /* 1. 拉低 SS0 */
    while ((SPI->STATUS >> 16) == 0); /* 等待 TX FIFO 有空位 */
    SPI->DATA = SPI_CMD_SS_ENABLE(0);

    /* 2. 依序寫入資料並要求將 MISO 資料推入 RX FIFO */
    for (uint32_t i = 0; i < len; i++)
    {
        while ((SPI->STATUS >> 16) == 0);
        SPI->DATA = SPI_CMD_DATA_RX(tx_data[i]);
    }

    /* 3. 釋放 SS0 */
    while ((SPI->STATUS >> 16) == 0);
    SPI->DATA = SPI_CMD_SS_DISABLE(0);
}
