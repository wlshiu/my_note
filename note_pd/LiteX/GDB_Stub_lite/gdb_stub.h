#ifndef GDB_STUB_H
#define GDB_STUB_H

void gdb_stub_init(void);
// 主動觸發斷點，讓程式停下來等待 GDB 連線
#define GDB_BREAKPOINT() __asm__ volatile("ebreak")

#endif
