
#include "murax_reg.h"

volatile uint8_t i2c_last_rx = 0;
volatile uint8_t i2c_rx_done = 0;

void i2c_init_100khz(void)
{
    /* 1. 設定取樣與逾時參數 (12 MHz 基準) */
    I2C->SAMPLING_DIV = 2;      /* 12MHz / (2+1) = 4MHz 取樣率 */
    I2C->TIMEOUT      = 60000;  /* 5 ms Bus 逾時保護 */
    I2C->TSU_DAT      = 6;      /* 500 ns Data Setup Time */

    /* 2. 設定 100 kHz SCL 時序 (T_LOW + T_HIGH ≈ 120 cycles) */
    I2C->T_LOW  = 60;           /* 5.0 us */
    I2C->T_HIGH = 60;           /* 5.0 us */
    I2C->T_BUF  = 60;           /* 5.0 us Stop-to-Start 間隔 */

    /* 3. 清除所有舊中斷旗標，並致能 RX_DATA_FULL 中斷 */
    I2C->INT_FLAG   = 0xFFFFFFFF;
    I2C->INT_ENABLE = I2C_INT_RX_DATA_FULL;
}

/* 輔助函式：送出 1 Byte 並檢查 Slave ACK (回傳 0 代表收到 ACK) */
static int i2c_write_byte_poll(uint8_t byte)
{
    /* 填入要傳送的資料 */
    I2C->TX_DATA = I2C_TX_VALID | I2C_TX_ENABLE | byte;
    /* 讓出 SDA 以接收 Slave 的 ACK 位元 (Enable=0) */
    I2C->TX_ACK  = I2C_TX_VALID;

    /* 等待收到 ACK 狀態 */
    uint32_t rx_ack;
    do
    {
        rx_ack = I2C->RX_ACK;
    }
    while (!(rx_ack & I2C_TX_VALID));

    return (rx_ack & 0x01); /* 0 = ACK, 1 = NACK */
}

/* I2C Master 寫入暫存器範例: START -> [Addr+W] -> [Reg] -> [Val] -> STOP */
int i2c_write_reg(uint8_t dev_addr_7bit, uint8_t reg_addr, uint8_t val)
{
    while (I2C->MASTER_STATUS & I2C_MASTER_BUSY);

    /* 發送 START */
    I2C->MASTER_STATUS = I2C_MASTER_START;
    while (I2C->MASTER_STATUS & I2C_MASTER_START);

    if (i2c_write_byte_poll((dev_addr_7bit << 1) | 0) != 0) goto stop_err;
    if (i2c_write_byte_poll(reg_addr) != 0) goto stop_err;
    if (i2c_write_byte_poll(val) != 0) goto stop_err;

    /* 發送 STOP */
    I2C->MASTER_STATUS = I2C_MASTER_STOP;
    while (I2C->MASTER_STATUS & I2C_MASTER_STOP);
    return 0;

stop_err:
    I2C->MASTER_STATUS = I2C_MASTER_STOP;
    while (I2C->MASTER_STATUS & I2C_MASTER_STOP);
    return -1;
}

/* I2C Master 讀取 1 Byte (觸發 RX_DATA_FULL 中斷收資料) */
int i2c_read_reg_irq(uint8_t dev_addr_7bit, uint8_t reg_addr)
{
    i2c_rx_done = 0;
    while (I2C->MASTER_STATUS & I2C_MASTER_BUSY);

    /* 1. 寫入目標暫存器位址 */
    I2C->MASTER_STATUS = I2C_MASTER_START;
    while (I2C->MASTER_STATUS & I2C_MASTER_START);
    if (i2c_write_byte_poll((dev_addr_7bit << 1) | 0) != 0) return -1;
    if (i2c_write_byte_poll(reg_addr) != 0) return -1;

    /* 2. Repeated START 切換為讀取模式 */
    I2C->MASTER_STATUS = I2C_MASTER_START;
    while (I2C->MASTER_STATUS & I2C_MASTER_START);
    if (i2c_write_byte_poll((dev_addr_7bit << 1) | 1) != 0) return -1;

    /* 3. 釋放 SDA 接收 1 Byte (Enable=0)，並對最後 1 Byte 回傳 NACK (Bit0=1) */
    I2C->TX_DATA = I2C_TX_VALID;
    I2C->TX_ACK  = I2C_TX_VALID | I2C_TX_ENABLE | 0x01;

    /* 4. 等待 irqCallback() 收到資料 */
    while (!i2c_rx_done);

    /* 5. 發送 STOP */
    I2C->MASTER_STATUS = I2C_MASTER_STOP;
    while (I2C->MASTER_STATUS & I2C_MASTER_STOP);
    return 0;
}
