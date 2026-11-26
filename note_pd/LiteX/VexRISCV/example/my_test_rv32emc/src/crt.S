
.global main
.global irqCallback

.section .init, "ax"
.global _start
_start:
  /* 關閉全域中斷 (MIE = 0) */
  csrci mstatus, 8

  /* 跳過 0x20 的中斷向量區段，前往初始化流程 */
  j _init_system

/* 中斷向量入口 (對齊於 0x00000020) */
.org 0x20
.section .trap, "ax"
.global trap_entry
trap_entry:
#if !defined(USE_RV32E)
  addi sp, sp, -80 /*-64*/ /* 76 bytes 內容 + 4 bytes padding = 80 (16-byte 對齊) */
#else
  addi sp, sp, -64 /* 52 bytes 內容 + 12 bytes padding = 64 (16-byte 對齊) */
#endif

  sw ra,   0(sp)
  sw t0,   4(sp)
  sw t1,   8(sp)
  sw t2,  12(sp)
  sw a0,  16(sp)
  sw a1,  20(sp)
  sw a2,  24(sp)
  sw a3,  28(sp)
  sw a4,  32(sp)
  sw a5,  36(sp)

  /* 讀取關鍵 CSR 並存入堆疊結構體 (TrapFrame) */
  csrr t0, mcause
  csrr t1, mepc

#if !defined(USE_RV32E)
  sw a6,  40(sp)
  sw a7,  44(sp)
  sw t3,  48(sp)
  sw t4,  52(sp)
  sw t5,  56(sp)
  sw t6,  60(sp)   /*-64*/

  sw t0,  64(sp)   /* frame->mcause   */
  sw t1,  68(sp)   /* frame->mepc     */
  sw zero, 72(sp)  /* frame->mtval (smallest profile 無 mtval,填 0) */
#else
  sw t0,  40(sp)   /* frame->mcause   */
  sw t1,  44(sp)   /* frame->mepc     */
  sw zero, 48(sp)  /* frame->mtval (smallest profile 無 mtval,填 0) */
#endif

  /* 呼叫 C 語言處理函式: void trap_handler(TrapFrame *frame) */
  mv a0, sp
  call trap_handler

  /* 寫回可能被 C 語言修改過的 mepc (例如跳過非法指令) */
#if !defined(USE_RV32E)
  lw t1, 68(sp)
#else
  lw t1, 44(sp)
#endif
  csrw mepc, t1

  lw ra,   0(sp)
  lw t0,   4(sp)
  lw t1,   8(sp)
  lw t2,  12(sp)
  lw a0,  16(sp)
  lw a1,  20(sp)
  lw a2,  24(sp)
  lw a3,  28(sp)
  lw a4,  32(sp)
  lw a5,  36(sp)

#if !defined(USE_RV32E)
  lw a6,  40(sp)
  lw a7,  44(sp)
  lw t3,  48(sp)
  lw t4,  52(sp)
  lw t5,  56(sp)
  lw t6,  60(sp)
  addi sp, sp, 80
#else
  addi sp, sp, 64
#endif

  mret

.section .text
_init_system:
  /* 設定堆疊指標 (Stack Pointer = 0x20000800) */
  la sp, _stack_start

  .option push
  .option norelax
  la gp, __global_pointer$
  .option pop

  /* 1. 將 .data 從 Flash (_data_lma) 搬移至 SRAM (_data_vma_start ~ _data_vma_end) */
  la a0, _data_lma
  la a1, _data_vma_start
  la a2, _data_vma_end
  bgeu a1, a2, _copy_data_done

_copy_data_loop:
  lw t0, 0(a0)
  sw t0, 0(a1)
  addi a0, a0, 4
  addi a1, a1, 4
  bltu a1, a2, _copy_data_loop

_copy_data_done:
  /* 2. 將 SRAM 中的 .bss 區段清零 (_bss_start ~ _bss_end) */
  la a0, _bss_start
  la a1, _bss_end
  bgeu a0, a1, _clear_bss_done

_clear_bss_loop:
  sw zero, 0(a0)
  addi a0, a0, 4
  bltu a0, a1, _clear_bss_loop

_clear_bss_done:

  /**
   * Murax 預設將 Debug 讀取通道關閉, GDB 讀不到 CSRs 資料, 必須從程式中讀取
   */

  /* mtvec 固定在 0x00000020 (hard code) */
  /* la t0, trap_entry */
  /* csrw mtvec, t0 */

  /* 0x880 enable timer(mie.MTIE) + external interrupts(mie.MEIE) */
  li t0, 0x880
  csrw mie, t0

  /* 0x1808 enable interrupts, mstatus.MPP and mstatus.MIE */
  li t0, 0x1808
  csrw mstatus, t0

  nop

  /* 呼叫 C 語言主程式 */
  call main

/* 若 main() 返回，進入無窮迴圈 */
_exit_loop:
  j _exit_loop

/* 提供預設的弱符號 irqCallback，避免未定義中斷函式時連結錯誤 */
.weak irqCallback
irqCallback:
  ret


