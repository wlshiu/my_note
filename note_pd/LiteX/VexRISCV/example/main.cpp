#include "VMurax.h"
#include "VMurax_Murax.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include "../common/framework.h"
#include "../common/jtag.h"
#include "../common/uart.h"

/* =========================================================================
 * SPI Loopback & 虛擬 I2C Slave 模擬元件 (相容 VexRiscv Workspace 框架)
 * ========================================================================= */
class SpiI2cSimProcess : public TimeProcess {
public:
    VMurax *top;
    uint8_t dev_addr = 0x50;   // 虛擬 I2C Slave 7-bit 位址
    uint8_t reg_data = 0x5A;   // 預設暫存器內容
    uint8_t prev_scl = 1;
    uint8_t prev_sda = 1;
    int bit_cnt = 0;
    uint8_t shift_reg = 0;
    bool active = false;
    bool is_read = false;
    bool addr_phase = true;
    bool master_nacked = false; // 新增：記錄 Master 是否已送出 NACK
    uint8_t slave_sda_out = 1;

    SpiI2cSimProcess(VMurax *top) : top(top) {
        // 初始化外部上拉與 MISO 預設狀態
        top->io_spi_miso = 0;
        top->io_i2c_scl_read = 1;
        top->io_i2c_sda_read = 1;
        schedule(0);
    }

    virtual void tick() {
        // 1. SPI Loopback：直接將 MOSI 接回 MISO
        top->io_spi_miso = top->io_spi_mosi;

        // 2. I2C Open-Drain 線與邏輯 (Master 輸出與 Slave 輸出做 AND，模擬外部上拉電阻)
        uint8_t bus_scl = top->io_i2c_scl_write & 1;
        uint8_t bus_sda = (top->io_i2c_sda_write & slave_sda_out) & 1;

        top->io_i2c_scl_read = bus_scl;
        top->io_i2c_sda_read = bus_sda;

        // 3. 虛擬 I2C Slave 狀態機
        if (bus_scl == 1 && prev_scl == 1 && prev_sda == 1 && bus_sda == 0) {
            // 偵測 START
            active = true;
            addr_phase = true;
            master_nacked = false;
            bit_cnt = 0;
            shift_reg = 0;
            slave_sda_out = 1;
        } else if (bus_scl == 1 && prev_scl == 1 && prev_sda == 0 && bus_sda == 1) {
            // 偵測 STOP
            active = false;
            master_nacked = false;
            slave_sda_out = 1;
        } else if (active && prev_scl == 1 && bus_scl == 0) {
            // SCL 負緣更新 SDA 輸出
            if (master_nacked) {
                slave_sda_out = 1; // Master 已回 NACK，Slave 釋放匯流排等待 STOP
            } else if (bit_cnt < 8) {
                slave_sda_out = (is_read && !addr_phase) ? ((reg_data >> (7 - bit_cnt)) & 0x01) : 1;
            } else if (bit_cnt == 8) {
                if (is_read && !addr_phase) {
                    slave_sda_out = 1; // 釋放 SDA 讓 Master 送 ACK/NACK
                } else {
                    if (!addr_phase || ((shift_reg >> 1) == dev_addr)) {
                        slave_sda_out = 0; // 回應 ACK
                        if (addr_phase) is_read = (shift_reg & 0x01);
                        else reg_data = shift_reg;
                    } else {
                        slave_sda_out = 1; // 位址不符回 NACK
                    }
                }
            } else {
                bit_cnt = 0;
                addr_phase = false;
                slave_sda_out = is_read ? ((reg_data >> 7) & 0x01) : 1;
            }
        } else if (active && prev_scl == 0 && bus_scl == 1) {
            // SCL 正緣取樣資料
            if (bit_cnt < 8) {
                shift_reg = (shift_reg << 1) | (bus_sda & 0x01);
            } else if (bit_cnt == 8 && is_read && !addr_phase) {
                // 取樣 Master 在讀取階段回應的 ACK(0) 或 NACK(1)
                if (bus_sda == 1) {
                    master_nacked = true;
                }
            }
            bit_cnt++;
        }

        prev_scl = bus_scl;
        prev_sda = bus_sda;

        // 每半個 mainClk 週期 (41666 ps) 更新一次取樣
        schedule(41666);
    }
};

class MuraxWorkspace : public Workspace<VMurax>{
public:
    MuraxWorkspace() : Workspace("Murax"){
        ClockDomain *mainClk = new ClockDomain(&top->io_mainClk,NULL,83333,300000);
        AsyncReset *asyncReset = new AsyncReset(&top->io_asyncReset,50000);
        UartRx *uartRx = new UartRx(&top->io_uart_txd,1.0e12/115200);
        UartTx *uartTx = new UartTx(&top->io_uart_rxd,1.0e12/115200);
        SpiI2cSimProcess *spiI2cSim = new SpiI2cSimProcess(top);

        timeProcesses.push_back(mainClk);
        timeProcesses.push_back(asyncReset);
        timeProcesses.push_back(uartRx);
        timeProcesses.push_back(uartTx);
        timeProcesses.push_back(spiI2cSim);

        Jtag *jtag = new Jtag(&top->io_jtag_tms,&top->io_jtag_tdi,&top->io_jtag_tdo,&top->io_jtag_tck,83333*4);
        timeProcesses.push_back(jtag);

        #ifdef TRACE
        //speedFactor = 10e-3;
        //cout << "Simulation caped to " << speedFactor << " of real time"<< endl;
        #endif
    }
};


struct timespec timer_start(){
    struct timespec start_time;
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &start_time);
    return start_time;
}

long timer_end(struct timespec start_time){
    struct timespec end_time;
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &end_time);
    uint64_t diffInNanos = end_time.tv_sec*1e9 + end_time.tv_nsec -  start_time.tv_sec*1e9 - start_time.tv_nsec;
    return diffInNanos;
}



int main(int argc, char **argv, char **env) {

    Verilated::randReset(2);
    Verilated::commandArgs(argc, argv);

    printf("BOOT\n");
    timespec startedAt = timer_start();

    MuraxWorkspace().run(1e9);

    uint64_t duration = timer_end(startedAt);
    cout << endl << "****************************************************************" << endl;


    exit(0);
}
