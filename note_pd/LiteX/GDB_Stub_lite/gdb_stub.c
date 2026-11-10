#include <stdint.h>
#include <stddef.h>
#include <irq.h>
#include <generated/csr.h>
#include "gdb_stub.h"

// PicoRV32 中斷暫存器儲存區（由 LiteX crt0.S 定義，存放 q0(PC), x1..x31）
extern uint32_t irq_regs[32];

// 第二組 UART (uart_gdb) 的底層字元收發函式
static void gdb_putc(char c) {
    while (uart_gdb_txfull_read());
    uart_gdb_rxtx_write(c);
}

static char gdb_getc(void) {
    while (uart_gdb_rxempty_read());
    char c = uart_gdb_rxtx_read();
    uart_gdb_ev_pending_write(UART_EV_RX);
    return c;
}

static const char hexchars[] = "0123456789abcdef";

static int hex2int(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

// 傳送 GDB RSP 封包 ($<data>#<checksum>)
static void gdb_send_packet(const char *data) {
    uint8_t csum = 0;
    gdb_putc('$');
    for (size_t i = 0; data[i] != '\0'; i++) {
        gdb_putc(data[i]);
        csum += (uint8_t)data[i];
    }
    gdb_putc('#');
    gdb_putc(hexchars[(csum >> 4) & 0xf]);
    gdb_putc(hexchars[csum & 0xf]);
}

// 接收 GDB RSP 封包並回傳 ACK '+'
static int gdb_recv_packet(char *buf, size_t max_len) {
    char c;
    while (1) {
        while ((c = gdb_getc()) != '$');
        size_t i = 0;
        uint8_t csum = 0;
        while (i < max_len - 1) {
            c = gdb_getc();
            if (c == '#') break;
            buf[i++] = c;
            csum += (uint8_t)c;
        }
        buf[i] = '\0';
        char h1 = gdb_getc();
        char h2 = gdb_getc();
        uint8_t recv_csum = (hex2int(h1) << 4) | hex2int(h2);
        if (csum == recv_csum) {
            gdb_putc('+');
            return i;
        } else {
            gdb_putc('-');
        }
    }
}

// 軟體斷點管理表（最多支援 16 個同時存在的斷點）
#define MAX_BREAKPOINTS 16
static struct {
    uint32_t addr;
    uint32_t orig_insn;
    int active;
} bp_table[MAX_BREAKPOINTS];

// 單步執行暫存斷點（針對下一條指令插入臨時 ebreak）
static uint32_t step_addr = 0;
static uint32_t step_orig_insn = 0;
static int step_active = 0;

static void set_ebreak(uint32_t addr, uint32_t *orig) {
    volatile uint32_t *ptr = (volatile uint32_t *)addr;
    *orig = *ptr;
    *ptr = 0x00100073; // RISC-V ebreak 指令
}

static void clear_ebreak(uint32_t addr, uint32_t orig) {
    volatile uint32_t *ptr = (volatile uint32_t *)addr;
    *ptr = orig;
}

// 覆寫 LiteX 預設的 isr() 中斷處理函式，接管 ebreak (IRQ 1)
void isr(void) {
    unsigned int irqs = irq_pending() & irq_getmask();

    // 處理單步暫存斷點還原
    if (step_active && irq_regs[0] == step_addr) {
        clear_ebreak(step_addr, step_orig_insn);
        step_active = 0;
    }

    // 檢查是否為 ebreak / 非法指令異常 (PicoRV32 IRQ Bit 1)
    if (irqs & (1 << 1)) {
        char pkt[1024];
        char resp[1024];

        // 若是主動寫在程式碼裡的 GDB_BREAKPOINT()，PC 需跳過這條 4-byte 的 ebreak
        // 若是 GDB 動態插入的斷點 (Z0)，PC 必須停在原位址以便還原原指令
        int is_sw_bp = 0;
        for (int i = 0; i < MAX_BREAKPOINTS; i++) {
            if (bp_table[i].active && bp_table[i].addr == irq_regs[0]) {
                is_sw_bp = 1;
                break;
            }
        }
        if (!is_sw_bp && *(uint32_t *)irq_regs[0] == 0x00100073) {
            irq_regs[0] += 4;
        }

        // 通知 GDB 目標機已觸發 SIGTRAP (05)
        gdb_send_packet("S05");

        while (1) {
            gdb_recv_packet(pkt, sizeof(pkt));

            if (pkt[0] == '?') {
                gdb_send_packet("S05");
            }
            // 讀取所有 32 個暫存器 (x0..x31) + PC (共 33 個 32-bit 暫存器，Little Endian)
            else if (pkt[0] == 'g') {
                char *p = resp;
                for (int r = 0; r < 33; r++) {
                    uint32_t val = (r == 0) ? 0 : (r == 32 ? irq_regs[0] : irq_regs[r]);
                    for (int b = 0; b < 4; b++) {
                        uint8_t byte = (val >> (b * 8)) & 0xff;
                        *p++ = hexchars[(byte >> 4) & 0xf];
                        *p++ = hexchars[byte & 0xf];
                    }
                }
                *p = '\0';
                gdb_send_packet(resp);
            }
            // 讀取記憶體: m<addr>,<len>
            else if (pkt[0] == 'm') {
                uint32_t addr = 0, len = 0;
                char *s = pkt + 1;
                while (*s != ',') addr = (addr << 4) | hex2int(*s++);
                s++;
                while (*s != '\0') len = (len << 4) | hex2int(*s++);

                char *p = resp;
                for (uint32_t i = 0; i < len; i++) {
                    uint8_t byte = *(volatile uint8_t *)(addr + i);
                    *p++ = hexchars[(byte >> 4) & 0xf];
                    *p++ = hexchars[byte & 0xf];
                }
                *p = '\0';
                gdb_send_packet(resp);
            }
            // 寫入記憶體: M<addr>,<len>:<data>
            else if (pkt[0] == 'M') {
                uint32_t addr = 0, len = 0;
                char *s = pkt + 1;
                while (*s != ',') addr = (addr << 4) | hex2int(*s++);
                s++;
                while (*s != ':') len = (len << 4) | hex2int(*s++);
                s++;
                for (uint32_t i = 0; i < len; i++) {
                    uint8_t byte = (hex2int(s[0]) << 4) | hex2int(s[1]);
                    *(volatile uint8_t *)(addr + i) = byte;
                    s += 2;
                }
                gdb_send_packet("OK");
            }
            // 設定軟體斷點: Z0,<addr>,<kind>
            else if (pkt[0] == 'Z' && pkt[1] == '0') {
                uint32_t addr = 0;
                char *s = pkt + 3;
                while (*s != ',') addr = (addr << 4) | hex2int(*s++);
                int slot = -1;
                for (int i = 0; i < MAX_BREAKPOINTS; i++) {
                    if (!bp_table[i].active) { slot = i; break; }
                }
                if (slot >= 0) {
                    bp_table[slot].addr = addr;
                    set_ebreak(addr, &bp_table[slot].orig_insn);
                    bp_table[slot].active = 1;
                    gdb_send_packet("OK");
                } else {
                    gdb_send_packet("E01");
                }
            }
            // 移除軟體斷點: z0,<addr>,<kind>
            else if (pkt[0] == 'z' && pkt[1] == '0') {
                uint32_t addr = 0;
                char *s = pkt + 3;
                while (*s != ',') addr = (addr << 4) | hex2int(*s++);
                for (int i = 0; i < MAX_BREAKPOINTS; i++) {
                    if (bp_table[i].active && bp_table[i].addr == addr) {
                        clear_ebreak(addr, bp_table[i].orig_insn);
                        bp_table[i].active = 0;
                        break;
                    }
                }
                gdb_send_packet("OK");
            }
            // 單步執行 (Step instruction): s
            else if (pkt[0] == 's') {
                // 簡化版單步：在 PC+4 插入臨時斷點（若遇分支跳轉則由下一個斷點接管）
                step_addr = irq_regs[0] + 4;
                set_ebreak(step_addr, &step_orig_insn);
                step_active = 1;
                break;
            }
            // 繼續執行 (Continue): c
            else if (pkt[0] == 'c') {
                break;
            }
            else {
                // 不支援的擴充指令回傳空字串，GDB 會自動降級使用基本指令
                gdb_send_packet("");
            }
        }
    }
}

void gdb_stub_init(void) {
    // 啟用 PicoRV32 的 ebreak/ecall/illegal 中斷 (IRQ 1)
    irq_setmask(irq_getmask() | (1 << 1));
    irq_setie(1);
}
