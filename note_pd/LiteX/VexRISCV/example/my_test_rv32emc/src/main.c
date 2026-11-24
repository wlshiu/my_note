//#include "stddefs.h"
#include <stdint.h>

#include "murax_reg.h"

#define HSI_CLOCK_Hz        (32ul*1000*1000)


static uint32_t g_data_var = 0x12345678;  /* 應由 crt.S 從 Flash 搬移至 SRAM */
static uint32_t g_bss_var;                /* 應由 crt.S 清零為 0x00000000 */

static uint32_t g_exception_cause = 0;

/* 中斷狀態計數器 */
static uint32_t g_timer_a_ticks = 0;
static uint32_t g_timer_b_ticks = 0;

static uint32_t g_uart_rx_count = 0;
static char     g_uart_last_char = 0;

static uint32_t g_spi_rx_count = 0;
static uint8_t  g_spi_rx_buf[4];

static volatile uint32_t g_i2c_rx_count = 0;
static volatile uint8_t  g_i2c_rx_data  = 0;

typedef struct
{
    uint32_t ra;
    uint32_t t0, t1, t2;
    uint32_t a0, a1, a2, a3, a4, a5;
    uint32_t mcause;
    uint32_t mepc;
    uint32_t mtval;
} TrapFrame;

typedef enum Excp
{
    EXCP_INST_ACCESS_FAULT      = 1,
    EXCP_ILLEGAL_INSTRUCTION    = 2,
    EXCP_LOAD_MISALIGNED        = 4,
    EXCP_LOAD_ACCESS_FAULT      = 5,
    EXCP_STORE_MISALIGNED       = 6,
    EXCP_STORE_ACCESS_FAULT     = 7,
    EXCP_ECALL_FROM_M_MODE      = 11,
} Excp_t;


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

    /* 開啟 UART 腳位多工 (IOPAD[0]=TXD, IOPAD[1]=RXD) */
    pinmux_enable_uart(true);

    timer_set_prescaler(HSI_CLOCK_Hz, 32*1000);

    gpio_set_dir(0x0F00, true); /* 僅設定純 GPIO IOPAD[11:8] 為輸出，避免干擾 ALT 腳位 */
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
     * 測試 3: Timer A 週期性中斷驗證 (12MHz -> 1ms tick, mcause 0x80000007)
     * --------------------------------------------------------------------- */
    uart_puts("\n[Test 3] Timer A Interrupt (mcause 0x80000007):\n");
    timer_set_prescaler(32000000, 1000000); /* 32MHz / 32 = 1MHz (1us/tick) */
    timer_init(TIMA, 1000, true, true);     /* 1000us = 1ms 自動重載並開啟中斷 */

    while (g_timer_a_ticks < 5);            /* 等待 5 次中斷 (5ms) */
    timer_init(TIMA, 1000, false, false);   /* 關閉 Timer A 中斷 */

    uart_puts("  Timer A ticks = "); uart_put_hex(g_timer_a_ticks); uart_puts("\n");
    uart_puts("  -> PASS!\n");

     /* ---------------------------------------------------------------------
      * 測試 3B: Timer B 外部中斷驗證 (12MHz -> 1ms tick, mcause 0x8000000B)
      * --------------------------------------------------------------------- */
    uart_puts("\n[Test 3B] Timer B External Interrupt (mcause 0x8000000B):\n");
    timer_init(TIMB, 1000, true, true);     /* 1000us = 1ms 自動重載並開啟中斷 */

    while (g_timer_b_ticks < 5);            /* 等待 5 次外部中斷 (5ms) */
    timer_init(TIMB, 1000, false, false);   /* 關閉 Timer B 中斷 */

    uart_puts("  Timer B ticks = "); uart_put_hex(g_timer_b_ticks); uart_puts("\n");
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

    /* ---------------------------------------------------------------------
     * 測試 5: SPI Master Loopback 驗證 (mcause 0x8000000B)
     * --------------------------------------------------------------------- */
    uart_puts("\n[Test 5] SPI Master Loopback (mcause 0x8000000B):\n");

    /* 清空可能殘留的 SPI RX FIFO */
    while (SPI->DATA & SPI_DATA_RX_VALID);

    g_spi_rx_count = 0;

    /* 切換 IOPAD[7:4] 為 SPI 功能 */
    pinmux_enable_spi(true);

    /* 初始化 SPI: 32MHz / (2 * (15 + 1)) = 1MHz SCLK, Mode 0 */
    spi_init_master(15, 0);
    spi_rx_irq_enable(true);

    /* 執行一次 2-Byte 完整傳輸 (SS0 拉低 -> 送收 0xA5, 0x5A -> SS0 釋放) */
    spi_push_cmd(SPI_CMD_SS_ENABLE(0));
    spi_push_cmd(SPI_CMD_DATA_RX(0xA5));
    spi_push_cmd(SPI_CMD_DATA_RX(0x5A));
    spi_push_cmd(SPI_CMD_SS_DISABLE(0));

    /* 等待 2 筆資料皆透過外部中斷接收完成 (附帶簡單超時保護避免死鎖) */
    uint32_t timeout = 100000;
    while ((g_spi_rx_count < 2) && (--timeout > 0));

    spi_rx_irq_enable(false);

    uart_puts("  SPI RX IRQ Count = "); uart_put_hex(g_spi_rx_count);  uart_puts("\n");
    uart_puts("  RX Byte[0]       = "); uart_put_hex(g_spi_rx_buf[0]); uart_puts("\n");
    uart_puts("  RX Byte[1]       = "); uart_put_hex(g_spi_rx_buf[1]); uart_puts("\n");

    if (g_spi_rx_count == 2 && g_spi_rx_buf[0] == 0xA5 && g_spi_rx_buf[1] == 0x5A)
        uart_puts("  -> PASS!\n");
    else
        uart_puts("  -> FAIL!\n");


    /* ---------------------------------------------------------------------
     * 測試 6: I2C Master 讀取虛擬 Slave (0x50 -> 0x5A, mcause 0x8000000B)
     * --------------------------------------------------------------------- */
    uart_puts("\n[Test 6] I2C Master Read Slave 0x50 (mcause 0x8000000B):\n");

    g_i2c_rx_count = 0;
    g_i2c_rx_data  = 0;

    /* 切換 IOPAD[3:2] 為 I2C 功能 */
    pinmux_enable_i2c(true);

    i2c_init_master_100khz();
    i2c_irq_enable(I2C_INT_RX_DATA);

    /* 1. 發出 START */
    i2c_master_start();

    /* 2. 送出 Slave Address (0x50) + Read Bit (1) = 0xA1 */
    bool ack_ok = i2c_master_write_byte((0x50 << 1) | 0x01);
    uart_puts("  Slave 0x50 Addr ACK = "); uart_put_hex(ack_ok ? 1 : 0); uart_puts("\n");

    if (ack_ok)
    {
        /* 3. 讀取 1 Byte 資料並回傳 NACK 結束讀取 (資料將由 irqCallback 接收) */
        i2c_master_trigger_read_byte(true);

        uint32_t i2c_timeout = 100000;
        while ((g_i2c_rx_count == 0) && (--i2c_timeout > 0));
    }

    /* 4. 發出 STOP 釋放匯流排 */
    i2c_master_stop();
    i2c_irq_disable(I2C_INT_RX_DATA);

    uart_puts("  I2C RX IRQ Count    = "); uart_put_hex(g_i2c_rx_count); uart_puts("\n");
    uart_puts("  Received Data       = "); uart_put_hex(g_i2c_rx_data);  uart_puts("\n");

    if (ack_ok && g_i2c_rx_count == 1 && g_i2c_rx_data == 0x5A)
        uart_puts("  -> PASS!\n");
    else
        uart_puts("  -> FAIL!\n");

    /* ---------------------------------------------------------------------
     * 測試 7: 故意觸發 Exception
     * --------------------------------------------------------------------- */
    uart_puts("\n[Test 7] Trigger exceptions\n");

    /* 1. mcause = 2: 非法指令 (Illegal Instruction) */
    uart_puts("\n--- 7.1: EXCP_ILLEGAL_INSTRUCTION (code= 2) ---\n");

    //   1A: 執行全零非法指令 (0x00000000, 16-bit C.ILLEGAL)
    g_exception_cause = 0;
    __asm__ volatile (".half 0x0000");

    if( g_exception_cause == EXCP_ILLEGAL_INSTRUCTION )
        uart_puts("    [Pass] ");
    else
        uart_puts("    [FAIL] ");

    uart_puts("'16-bit C.ILLEGAL (0x0000)'\n");

    //   1B: 存取 RV32E 不存在的暫存器 x16 (addi x16, x16, 1 -> 0x00180813)
    g_exception_cause = 0;
    __asm__ volatile (".word 0x00180813");

    if( g_exception_cause == EXCP_ILLEGAL_INSTRUCTION )
        uart_puts("    [Pass] ");
    else
        uart_puts("    [FAIL] ");

    uart_puts("'RV32E x16 register access'\n");


    /* 2. mcause = 4: 讀取位址未對齊 (Load Address Misaligned) */
    uart_puts("\n--- 7.2: EXCP_LOAD_MISALIGNED (code= 4) ---\n");
    g_exception_cause = 0;

    // 強制從 SRAM 奇數位址 0x20000001 讀取 32-bit Word (lw)
    uint32_t    bad_addr = 0x20000001UL;
    uint32_t    val = 0;
    __asm__ volatile ("lw %0, 0(%1)" : "=r"(val) : "r"(bad_addr));

    if( g_exception_cause == EXCP_LOAD_MISALIGNED )
        uart_puts("    [Pass] ");
    else
        uart_puts("    [FAIL] ");

    uart_puts("'Unaligned 32-bit Load (0x20000001)'\n");


    /* 3. mcause = 6: 寫入位址未對齊 (Store Address Misaligned) */
    uart_puts("\n--- 7.3: EXCP_STORE_MISALIGNED  (code= 6) ---\n");
    g_exception_cause = 0;

    // 強制對 SRAM 非 2-byte 對齊位址 0x20000003 寫入 16-bit Halfword (sh)
    bad_addr = 0x20000003UL;
    val = 0x1234;
    __asm__ volatile ("sh %0, 0(%1)" : : "r"(val), "r"(bad_addr));

    if( g_exception_cause == EXCP_STORE_MISALIGNED )
        uart_puts("    [Pass] ");
    else
        uart_puts("    [FAIL] ");

    uart_puts("'Unaligned 16-bit Store (0x20000003)'\n");

    /* 4. mcause = 5: 讀取匯流排錯誤 (Load Access Fault)
     *      ps.需匯流排解碼器對無效位址回報 error=1 才會觸發
     */
    uart_puts("\n--- 7.4: EXCP_LOAD_ACCESS_FAULT (code= 5) ---\n");
    g_exception_cause = 0;

    // 存取未映射的位址空間 (0x80000000)
    uint32_t    unmapped_addr = 0x80000000UL;
    val = 0;
    __asm__ volatile ("lw %0, 0(%1)" : "=r"(val) : "r"(unmapped_addr));

    if( g_exception_cause == EXCP_LOAD_ACCESS_FAULT )
        uart_puts("    [Pass] ");
    else
        uart_puts("    [FAIL] ");

    uart_puts("'Unmapped Memory Load (0x80000000)'\n");


    /* 5. mcause = 7: 寫入匯流排錯誤 (Store Access Fault) */
    uart_puts("\n--- 7.5: EXCP_STORE_ACCESS_FAULT (code= 7) ---\n");
    g_exception_cause = 0;

    // 寫入未映射位址空間 (0x80000000)
    unmapped_addr = 0x80000000UL;
    val = 0xDEADBEAF;
    __asm__ volatile ("sw %0, 0(%1)" : : "r"(val), "r"(unmapped_addr));

    if( g_exception_cause == EXCP_STORE_ACCESS_FAULT )
        uart_puts("    [Pass] ");
    else
        uart_puts("    [FAIL] ");

    uart_puts("'Unmapped Memory Store (0x80000000)'\n");


    /* 6. mcause = 1: 取指匯流排錯誤 (Instruction Access Fault) */
    uart_puts("\n--- 7.6: EXCP_INST_ACCESS_FAULT (code= 1) ---\n");
    g_exception_cause = 0;

    // 定義函式指標指向未映射位址 0x80000000 並跳轉執行
    void (*cb_invalid)(void) = (void (*)(void))0x80000000UL;
    cb_invalid();

    if( g_exception_cause == EXCP_INST_ACCESS_FAULT )
        uart_puts("    [Pass] ");
    else
        uart_puts("    [FAIL] ");

    uart_puts("'Jump to Unmapped Address (0x80000000)'\n");

    /* 7. mcause = 11: 環境呼叫異常 (Environment Call from M-mode) */
    uart_puts("\n--- 7.7: EXCP_ECALL_FROM_M_MODE (code= 11) ---\n");
    g_exception_cause = 0;

    // 執行 32-bit 系統呼叫指令 ecall (0x00000073)
    __asm__ volatile ("ecall");

    if( g_exception_cause == EXCP_ECALL_FROM_M_MODE )
        uart_puts("    [Pass] ");
    else
        uart_puts("    [FAIL] ");

    uart_puts("'M-Mode ECALL Instruction'\n");


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
void trap_handler(TrapFrame *pFrame)
{
    uint32_t    mcause = csr_read_mcause();

    if( !(mcause & MCAUSE_INT_FLAG) )
    {
        // exception
        g_exception_cause = pFrame->mcause;

        uint32_t    excp_code = pFrame->mcause & 0xF;

        uart_puts("\n[TRAP] Exception!\n mcause=");
        uart_put_hex(pFrame->mcause & 0xF);
        uart_puts(" mepc=");
        uart_put_hex(pFrame->mepc);
        uart_puts(" mtval=");
        uart_put_hex(pFrame->mtval);
        uart_puts("\n");

        /**
         *  判斷導致異常的指令是 16-bit 還是 32-bit
         *  ps. instruction_32[1:0] = 0x3
         *  ps1. 若發生取指錯誤 (mcause == 1),不可直接讀取 *(uint16_t*)mepc
         */
        uint32_t    inst_len = 4;
        if( excp_code != EXCP_INST_ACCESS_FAULT && (pFrame->mepc & 0x1) == 0 )
        {
            uint16_t    inst_low = *(volatile uint16_t *)(pFrame->mepc);
            if( (inst_low & 0x3) != 0x3 )
            {
                inst_len = 2;
            }
        }

        switch( excp_code )
        {
            case EXCP_ILLEGAL_INSTRUCTION:
                uart_puts(" -> Illegal Instruction (or RV32I x16-x31 access)!\n");
                // 測試用途: 跳過此非法指令繼續執行 (正式產品建議在此記錄錯誤並重啟)
                pFrame->mepc += inst_len;
                break;

            case EXCP_LOAD_MISALIGNED:
            case EXCP_STORE_MISALIGNED:
                uart_puts(" -> Unaligned Memory Access at addr: ");
                uart_put_hex(pFrame->mtval);
                uart_puts("\n");
                // 測試用途: 跳過此非對齊存取指令繼續執行
                pFrame->mepc += inst_len;
                break;
            case EXCP_LOAD_ACCESS_FAULT:
                uart_puts(" -> Load Invalid Address\n");
                pFrame->mepc += inst_len;
                break;
            case EXCP_STORE_ACCESS_FAULT:
                uart_puts(" -> Store Invalid Address\n");
                pFrame->mepc += inst_len;
                break;
            case EXCP_INST_ACCESS_FAULT:
                uart_puts(" -> Instruction Fetch Invalid Address\n");
                pFrame->mepc = pFrame->ra;
                break;
            case EXCP_ECALL_FROM_M_MODE:
                uart_puts(" -> Environment Call (ECALL) from M-Mode\n");
                pFrame->mepc += inst_len;
                break;
            default:
                uart_puts(" -> Fatal Fault! System Halted. (excp_code= ");
                uart_put_hex(excp_code);
                uart_puts(")\n");
                while (1);
                break;
        }

        uart_puts("\n");
        return;
    }

    mcause &= MCAUSE_CODE_MASK;

    if( mcause == MCAUSE_MTI ) /* 1. 檢查是否為 Timer A 中斷 (Machine Timer Interrupt, Code = 7) */
    {
        if( TIMER_INTERRUPT->PENDINGS & TIMER_IRQ_A )
        {
            g_timer_a_ticks++;
            timer_a_clear_irq();
        }
    }
    else if( mcause == MCAUSE_MEI ) /* 2. 檢查是否為外部中斷 (Machine External Interrupt, Code = 11) */
    {
        uint32_t    status = 0;

        /**
         *  Software interrupt priority
         */

        /* 檢查 Timer B 中斷旗標 (TIMER_INTERRUPT->PENDINGS Bit 1) */
        if( TIMER_INTERRUPT->PENDINGS & TIMER_IRQ_B )
        {
            g_timer_b_ticks++;
            timer_b_clear_irq();
        }

        /* 檢查 SPI RX FIFO 非空中斷 (STATUS Bit 9 = RX Interrupt Pending) */
        if( SPI->STATUS & SPI_STATUS_RX_INT_PENDING )
        {
            uint32_t    rx_word;
            while ((rx_word = SPI->DATA) & SPI_DATA_RX_VALID)
            {
                if (g_spi_rx_count < 4)
                {
                    g_spi_rx_buf[g_spi_rx_count] = (uint8_t)(rx_word & SPI_DATA_MASK);
                }
                g_spi_rx_count++;
            }
        }

        /* 檢查 I2C 中斷旗標 */
        if (I2C->INT_ENABLE & I2C_INT_RX_DATA)
        {
            uint32_t rx_val = I2C->RX_DATA;
            if (rx_val & I2C_RX_VALID)
            {
                g_i2c_rx_data = (uint8_t)(rx_val & I2C_RX_DATA_MASK);
                g_i2c_rx_count++;
            }
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
