#include <stdio.h>
#include <stdlib.h>
#include <irq.h>
#include <uart.h>
#include <console.h>
#include <generated/csr.h>
#include "gdb_stub.h"

int main(void) {
    uart_init();
    gdb_stub_init();

    printf("\r\nWaiting for GDB connection on uart_gdb...\r\n");
    
    // 觸發第一個斷點，停在這裡等 GDB 連上並設定其他斷點
    GDB_BREAKPOINT();

    printf("PicoRV32 Bare-metal UART Test Ready!\r\n");

    int counter = 0;
    while (1) {
        counter++;
        if (uart_read_nonblock()) {
            char c = uart_read();
            printf("[%d] Received: %c (0x%02x)\r\n", counter, c, c);
        }
    }
    return 0;
}
