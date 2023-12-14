/*
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Copyright (c) 2019 Western Digital Corporation or its affiliates.
 *
 * Authors:
 *   Anup Patel <anup.patel@wdc.com>
 */

#include <sbi/riscv_asm.h>
#include <sbi/riscv_encoding.h>
#include <sbi/riscv_elf.h>
#include <sbi/sbi_platform.h>
#include <sbi/sbi_scratch.h>
#include <sbi/sbi_trap.h>

#define BOOT_STATUS_RELOCATE_DONE   1
#define BOOT_STATUS_BOOT_HART_DONE  2

/**
 * move 3 registers, 也可以用 mv d, s 偽指令
 */
.macro  MOV_3R __d0, __s0, __d1, __s1, __d2, __s2
    add \__d0, \__s0, zero
    add \__d1, \__s1, zero
    add \__d2, \__s2, zero
.endm

/**
 * move 5 registers, 也可以用 mv d, s 偽指令
 */
.macro  MOV_5R __d0, __s0, __d1, __s1, __d2, __s2, __d3, __s3, __d4, __s4
    add \__d0, \__s0, zero
    add \__d1, \__s1, zero
    add \__d2, \__s2, zero
    add \__d3, \__s3, zero
    add \__d4, \__s4, zero
.endm

/*
 * If __start_reg <= __check_reg and __check_reg < __end_reg then
 *   jump to __pass
 */
.macro BRANGE __start_reg, __end_reg, __check_reg, __jump_lable
    blt \__check_reg, \__start_reg, 999f
    bge \__check_reg, \__end_reg, 999f
    j   \__jump_lable
999:
.endm

    .section .entry, "ax", %progbits
    .align 3
    .globl _start
    .globl _start_warm
_start:
    /**
     *  Find preferred boot HART id
     *  fw_boot_hart 會用到 a0 ~ a2, 所以在這把 a0 ~ a2 的值, 暫保到 s0 ~ s2
     */
    MOV_3R  s0, a0, s1, a1, s2, a2

    /**
     *  呼叫 fw_boot_hart() 獲取 boot HART id,
     *  對於 fw_dynamic, fw_jump, fw_payload 三種類型的 bios, boot HART id 是不一樣的.
     *  fw_jump 和 fw_payload 這裡直接 return -1 .
     *  fw_dynamic 則在啟動 fw_dynamic 的上一級程序, 會把參數
     *  放到 struct fw_dynamic_info 裡, 用 a2 傳給 opensbi,
     *  ps. HART = hardware thread 大部分情況下, hart 的概念等同於 core
     *
     *  根據具體程式碼可以看到, 依 fw_dynamic_info version 不同, boot HART id 是不一樣的:
     *      + version1 是固定的 boot HART id,
     *      + version2 返回 -1, 沒有定義 boot HART id
     *
     *  return 值會放在 a0, a1
     */
    call    fw_boot_hart

    /* boot HART id 放到 a6 */
    add a6, a0, zero

    /* 恢復 a0 ~a2 的值 */
    MOV_3R  a0, s0, a1, s1, a2, s2
    li  a7, -1

    /* 如果 boot HART id 是 -1, 使用 lottery (彩票演算法) 的方式選擇 boot hart */
    beq a6, a7, _try_lottery

    /**
     *  如果是固定的 boot HART, a6 是上一級定義的 boot HART id, a0 是當前 HART id,
     *  這裡可以參考 qemu 的程式碼:
     *      hw/riscv/boot.c, reset_vec 定義的地方, 第三條指令獲取當前 hart 的 HART id 值.
     *  兩者不相等，說明不是指定 boot HART, 跳到 relocate 結束的位置
     */
    /* Jump to relocation wait loop if we are not boot hart */
    bne a0, a6, _wait_relocate_copy_done

_try_lottery:
    /**
     *  Multi-Cores 執行到了這裡, 只要 main core 去做 binary 的 relocate 就好.
     *  其他 cores 到 relocate done 的位置, 等待做完 relocate
     *
     *  + lla (載入本地地址), 可擴展為 auipc and addi
     *  + la (載入地址), 在 PIC mode 下, 可展為 auipc and l[wd], 否則與 lla 相同
     */
    /* Jump to relocation wait loop if we don't get relocation lottery */
    lla a6, _relocate_lottery
    li  a7, 1

    /**
     *  通過原子 add 指令, 設定 _relocate_lottery address 的值(全域變數), 決定哪一個 core 做 relocate 和初始化
     *  pTmp = &_relocate_lottery;
     *  a6 = *pTmp;
     *  *pTmp = *pTmp + a7
     */
    amoadd.w a6, a7, (a6)

    /**
     *  if(*addr[_relocate_lottery] != 0), 就跳到 _wait_relocate_copy_done 的地方.
     *  如果 multi-cores 一起啟動執行, 只有第一個執行 原子加指令的 core 的 (*addr[_relocate_lottery])值是 0.
     *  後續執行到這裡的 Cores 都是 slave core, 直接跳到 _wait_relocate_copy_done 等待做完
     */
    bnez    a6, _wait_relocate_copy_done

    /* t0 是 _load_start 的地址, 這個 address 存的是 _fw_start 的值 */
    /* Save load address */
    lla t0, _load_start

    /**
     *  紀錄 _fw_start address 到 t1, _fw_start 是 img bin 存放的位址
     */
    lla t1, _fw_start

    /**
     *  REG_S 就是 instruction 'sw' or 'sd', 把 t1 中的資料(即 _fw_start Addr), 存入到 addr[t0 + 0] 中(也就是 _load_start)
     *
     *  LMA 是 _load_start, qemu virt 上的 LMA 和 VMA 都是 0x80000000.
     *  如果 '-bios' 是載入到其他地方(比如 flash), LMA 和 VMA 就會不一樣,
     *  此時候就需要做 relocate, 把 LMA 的 data 複製 VMA
     */
    REG_S   t1, 0(t0)

    /**
     *  編譯參數 '-fPIC' 是告訴編譯器, 產生與 address 無關代碼(PIC, Position-Independent Code);
     *  則產生的程序中, 沒有絕對位址, 全部使用相對位址,
     *  故而程序可以被載入到 memory 的任意位置, 都可以正確的執行
     */
#ifdef FW_PIC
    /**
     *  opensbi 編譯最終生成 bios 的 bin 以及 sbi 相關的 lib.
     *  sbi 的 bin 及 lib 是可以動態連結的, 這就需要對動態連結的符號, 做 relocate
     *
     *  這部分的內容相對獨立, 可以先跳過
     */
    /* relocate the global table content */
    lla t0, _link_start
    REG_L   t0, 0(t0)
    /* t1 shall has the address of _fw_start */
    sub t2, t1, t0
    lla t3, _runtime_offset
    REG_S   t2, (t3)
    lla t0, __rel_dyn_start
    lla t1, __rel_dyn_end
    beq t0, t1, _relocate_done
2:
    REG_L   t5, REGBYTES(t0)    /* t5 <-- relocation info:type */
    li  t3, R_RISCV_RELATIVE    /* reloc type R_RISCV_RELATIVE */
    bne t5, t3, 3f
    REG_L   t3, 0(t0)
    REG_L   t5, (REGBYTES * 2)(t0)  /* t5 <-- addend */
    add t5, t5, t2
    add t3, t3, t2
    REG_S   t5, 0(t3)       /* store runtime address to the GOT entry */
    j   5f

3:
    lla t4, __dyn_sym_start

4:
    srli    t6, t5, SYM_INDEX   /* t6 <--- sym table index */
    andi    t5, t5, 0xFF        /* t5 <--- relocation type */
    li  t3, RELOC_TYPE
    bne t5, t3, 5f

    /* address R_RISCV_64 or R_RISCV_32 cases*/
    REG_L   t3, 0(t0)
    li  t5, SYM_SIZE
    mul t6, t6, t5
    add s5, t4, t6
    REG_L   t6, (REGBYTES * 2)(t0)  /* t0 <-- addend */
    REG_L   t5, REGBYTES(s5)
    add t5, t5, t6
    add t5, t5, t2      /* t5 <-- location to fix up in RAM */
    add t3, t3, t2      /* t3 <-- location to fix up in RAM */
    REG_S   t5, 0(t3)       /* store runtime address to the variable */

5:
    addi    t0, t0, (REGBYTES * 3)
    blt t0, t1, 2b
    j   _relocate_done
_wait_relocate_copy_done:
    j   _wait_for_boot_hart
#else   /* FW_PIC */

    /* Relocate if load address != link address */
_relocate:
    /**
     *  分別把 addr[_link_start], addr[_link_end], addr[_load_start] 的值,
     *  load 到 t0, t1, t2
     */
    lla t0, _link_start
    REG_L   t0, 0(t0)
    lla t1, _link_end
    REG_L   t1, 0(t1)
    lla t2, _load_start
    REG_L   t2, 0(t2)

    /**
     *  如果 _link_start 和 _load_start 相同, 不需要 relocate, 直接跳到 _relocate_done
     */
    beq t0, t2, _relocate_done

    sub t3, t1, t0
    add t3, t3, t2
    /**
     * 到此
     *  t0 = _link_start (VMA start)
     *  t1 = _link_end (VMA end)
     *  t2 = _load_start (LMA start)
     *  t3=  _load_end (LMA end)
     **********/

    lla t4, _relocate_done

    /**
     *  計算 _relocate_done 在 loader 下的 offset
     *  t4 = _relocate_done - _load_start
     */
    sub t4, t4, t2

    /**
     *  計算 _relocate_done 在 linker 下的位址
     *  t4 = _relocate_done (in link space)
     */
    add t4, t4, t0

    /**
     *  if _load_start < _link_start, 則跳到 _relocate_copy_to_upper
     */
    blt t2, t0, _relocate_copy_to_upper


_relocate_copy_to_lower:
    /**
     *  _load_start > _link_start case, 往 low address copy data,
     *  從 start 開始搬
     *
     *  0x0 +------------
     *      |
     *      | _link_start <--- t0
     *      |
     *      | _link_end   <--- t1
     *      |
     *      | _load_start <--- t2
     *      |
     *      | _load_end   <--- t3
     *      |
     */
    ble t1, t2, _relocate_copy_to_lower_loop

    /* 異常處理, 檢查位址間的關係是否預期 */
    lla t3, _relocate_lottery

    BRANGE  t2, t1, t3, _start_hang  /* if _load_start <= _relocate_lottery < _link_end, jump to _start_hang */
    lla t3, _boot_status
    BRANGE  t2, t1, t3, _start_hang  /* if _load_start <= _boot_status < _link_end, jump to _start_hang */
    lla t3, _relocate
    lla t5, _relocate_done
    BRANGE  t2, t1, t3, _start_hang /* if _load_start <= _relocate < _link_end,      jump to _start_hang */
    BRANGE  t2, t1, t5, _start_hang /* if _load_start <= _relocate_done < _link_end, jump to _start_hang */
    BRANGE  t3, t5, t2, _start_hang /* if _relocate <= _load_start < _relocate_done, jump to _start_hang */

    /**
     *  // pseudo c code of _relocate_copy_to_lower_loop section
     *  t0 = &_link_start;
     *  t1 = &_link_end;
     *  t2 = &_load_start;
     *  while( t0 < t1 )
     *  {
     *      *t0 = *t2;
     *      t0 += __SIZEOF_POINTER__;
     *      t2 += __SIZEOF_POINTER__;
     *  }
     */
_relocate_copy_to_lower_loop:
    /**
     *  t2 address 的資料放到 t3, 再從 t3 放到 t0 address.
     *  也就是從 _load_start 複製 _link_start
     */
    REG_L   t3, 0(t2)
    REG_S   t3, 0(t0)

    /* t0 and t2 各加上 offset __SIZEOF_POINTER__ */
    add t0, t0, __SIZEOF_POINTER__
    add t2, t2, __SIZEOF_POINTER__

    /**
     *  if t0 < t1 (pCur < _link_end), jump to _relocate_copy_to_lower_loop
     */
    blt t0, t1, _relocate_copy_to_lower_loop
    jr  t4 /* 前面計算 t4 為 _relocate_done (in linker space) */

_relocate_copy_to_upper:
    /**
     *  _load_start < _link_start case, 往 high address copy data,
     *  從 end 開始搬
     *
     *  0x0 +------------
     *      |
     *      | _load_start <--- t2
     *      |
     *      | _load_end   <--- t3
     *      |
     *      | _link_start <--- t0
     *      |
     *      | _link_end   <--- t1
     *      |
     */
    ble t3, t0, _relocate_copy_to_upper_loop

    /* 異常處理, 檢查位址間的關係是否預期  */
    lla t2, _relocate_lottery

    BRANGE  t0, t3, t2, _start_hang /* if _link_start <= _relocate_lottery < _load_end, jump to _start_hang */
    lla t2, _boot_status
    BRANGE  t0, t3, t2, _start_hang /* if _link_start <= _boot_status < _load_end, jump to _start_hang */
    lla t2, _relocate
    lla t5, _relocate_done
    BRANGE  t0, t3, t2, _start_hang /* if _link_start <= _relocate < _load_end,      jump to _start_hang */
    BRANGE  t0, t3, t5, _start_hang /* if _link_start <= _relocate_done < _load_end, jump to _start_hang */
    BRANGE  t2, t5, t0, _start_hang /* if _relocate <= _link_start < _relocate_done, jump to _start_hang */

    /**
     *  // pseudo c code of _relocate_copy_to_upper_loop section
     *  t0 = &_link_start;
     *  t1 = &_link_end;
     *  t3 = &_load_end;
     *
     *  do {
     *      t3 -= __SIZEOF_POINTER__;
     *      t1 -= __SIZEOF_POINTER__;
     *
     *      *t1 = *t3;
     *  } while( t0 < t1 );
    */
_relocate_copy_to_upper_loop:
    add t3, t3, -__SIZEOF_POINTER__
    add t1, t1, -__SIZEOF_POINTER__
    REG_L   t2, 0(t3)
    REG_S   t2, 0(t1)
    blt t0, t1, _relocate_copy_to_upper_loop
    jr  t4  /* 前面計算 t4 為 _relocate_done (in linker space) */


_wait_relocate_copy_done:
    lla t0, _fw_start
    lla t1, _link_start
    REG_L   t1, 0(t1)

    /**
     *  slave cores 看到 addr[_link_start] and addr[_fw_start] 資料 一樣時,
     *  表示 relocate 已經完成, 可跳到 _wait_for_boot_hart.
     */
    beq t0, t1, _wait_for_boot_hart

    /**
     *  對於沒有 relocate 完成的情況,
     *  先計算出 relocate 完成後 _wait_for_boot_hart (in linker space) 的位址.
     *  在尚未 relocate 完成前, 還不能跳過去, 先把計算出的位址存到 t3,
     *  然後在一個循環裡檢測 _boot_status 的值
     */
    lla t2, _boot_status
    lla t3, _wait_for_boot_hart

    /**
     *  計算 offset
     *  t3 = _wait_for_boot_hart - _fw_start
     */
    sub t3, t3, t0

    /**
     *  將 offset 加上 base _link_start
     *  t3 = _wait_for_boot_hart - _fw_start + _link_start,
     *  t3 = _wait_for_boot_hart (in linker space)
     */
    add t3, t3, t1


/**
 *  // pseudo c code
 *  #define BOOT_STATUS_RELOCATE_DONE   1
 *
 *  t4 = BOOT_STATUS_RELOCATE_DONE;
 *  t2 = &_boot_status; // main-core 在完成 relocate 後, 會把 _boot_statue 設 1
 *  whie( *t2 != t4 ) {}
 *
 */
1:
    /* waitting for relocate copy done (_boot_status == 1) */
    li  t4, BOOT_STATUS_RELOCATE_DONE
    REG_L   t5, 0(t2)

    /* Reduce the bus traffic so that boot hart may proceed faster */
    nop
    nop
    nop
    bgt t4, t5, 1b

    /**
     *  get relocate done state and jump to _wait_for_boot_hart (in linker space)
     */
    jr  t3
#endif /* FW_PIC */


_relocate_done:

    /*
     * Mark relocate copy done
     * Use _boot_status copy relative to the load address
     */
    lla t0, _boot_status    /* t0 = &_boot_status; */
#ifndef FW_PIC
    lla t1, _link_start     /* t1 = &_link_start; */
    REG_L   t1, 0(t1)       /* t1 = *(t1 + 0); t1 = 0x80000000 */
    lla t2, _load_start     /* t2 = &_load_start; */
    REG_L   t2, 0(t2)       /* t2 = *(t2 + 0); t2 = 0x80000000 */
    sub t0, t0, t1  /* t0 = t0 - t1; 計算 _boot_status (in loader space) 的 offset */
    add t0, t0, t2  /* t0 = t0 + t2; 計算 _boot_status (in linker space) 位址 */
#endif
    /**
     *  要從 multi-cores 的角度去看這段程式碼, main-core 做完 relocate 後會跳到這裡,
     *  同時 main-core 會設定 _boot_status 為 BOOT_STATUS_RELOCATE_DONE.
     *
     *  slave-cores 則會在上面 _wait_relocate_copy_done 循環等待, 直到 main-core 完成 relocate
     */
    li  t1, BOOT_STATUS_RELOCATE_DONE
    REG_S   t1, 0(t0)

    /* fence 指令確保前面 RW memory 的操作都完成後, 才往下執行 */
    fence   rw, rw

    /**
     *  At this point we are running from link address
     *  在此已運行在 linker space
     */

	/**
	 *  以下是 main-core 的流程, 而 slave-cores 會跳到 _wait_for_boot_hart,
     *  等待 main-core 執行到 BOOT_STATUS_BOOT_HART_DONE state
	 */
    /* Reset all registers for boot HART, 為了啟動 Hart 重設所有暫存器 */
    li  ra, 0

    /**
     *  ra, a0, a1, a2 不清, 其他都清 0
     */
    call    _reset_regs

    /**
     *  BSS section 清 0
     */
    /* Zero-out BSS */
    lla s4, _bss_start
    lla s5, _bss_end
_bss_zero:
    REG_S   zero, (s4)
    add s4, s4, __SIZEOF_POINTER__
    blt s4, s5, _bss_zero

    /* Setup temporary trap handler */
    lla s4, _start_hang

    /**
     *  設定臨時的 trap handler
     *  寫 csr 的 CSR_MTVEC, 保存發生異常時, core 需要跳轉到的 handler 地址
     */
    csrw    CSR_MTVEC, s4

    /* Setup temporary stack */
    lla s4, _fw_end

    /**
     *  s5 設定成 SBI_SCRATCH_SIZE = 8KB
     */
    li  s5, (SBI_SCRATCH_SIZE * 2)

    /**
     *  從 OpenSBI img bin 載入結束位置, 開始的 8KB 設定為 stack,
     *  stack 由 high address 往 Low address
     *  ps. 設定臨時 stack 是為了後面 call c function 的流程
     */
    add sp, s4, s5

    /* Allow main firmware to save info */

    /* 保存 a0 ~ a4, 在後續 fw_save_info 需要用到 */
    MOV_5R  s0, a0, s1, a1, s2, a2, s3, a3, s4, a4

    /**
     *  呼叫上一階段的啟動資訊, 放到此階段與下一階段通訊的資料結構 fw_dynamic_info 中
     *  (目前只有 fw_dynamic 啟動方式, 會通過該資料結構, 向核心傳遞啟動參數)
     */
    call    fw_save_info
    MOV_5R  a0, s0, a1, s1, a2, s2, a3, s3, a4, s4

    /**
     *  OpenSBI 支援 Device Tree Binary */
#ifdef FW_FDT_PATH
    /* Override previous arg1 */
    lla a1, fw_fdt_bin
#endif

    /*
     * Initialize platform
     * Note: The a0 to a4 registers passed to the
     * firmware are parameters to this function.
     */
    MOV_5R  s0, a0, s1, a1, s2, a2, s3, a3, s4, a4
    call    fw_platform_init
    add t0, a0, zero
    MOV_5R  a0, s0, a1, s1, a2, s2, a3, s3, a4, s4
    add a1, t0, zero

	/**
	 *  platform 是平台相關的資料結構, qemu virt 的定義在:
	 *      platform/generic/platform.c,
     *  這個是 OpenSBI 裡針對 qemu virt 平台定義的組態.
	 *  最大的 Core conunter 是 128, stack 大小是 8KB
	 */
    /* Preload HART details
     * s7 -> HART Count
     * s8 -> HART Stack Size
     * s9 -> Heap Size
     * s10 -> Heap Offset
     */
    lla a4, platform
#if __riscv_xlen > 32
    lwu s7, SBI_PLATFORM_HART_COUNT_OFFSET(a4)
    lwu s8, SBI_PLATFORM_HART_STACK_SIZE_OFFSET(a4)
    lwu s9, SBI_PLATFORM_HEAP_SIZE_OFFSET(a4)
#else
    lw  s7, SBI_PLATFORM_HART_COUNT_OFFSET(a4)
    lw  s8, SBI_PLATFORM_HART_STACK_SIZE_OFFSET(a4)
    lw  s9, SBI_PLATFORM_HEAP_SIZE_OFFSET(a4)
#endif

    /* Setup scratch space for all the HARTs */
    lla tp, _fw_end

    /**
     *  算出全部 cores 需要的 stack size
     */
    mul a5, s7, s8

    /**
     *  tp, t3 都指向全部 stack 的起始基地址
     *  tp 為該段記憶體的 stack pointer
     */
    add tp, tp, a5

    /* Setup heap base address */
    lla s10, _fw_start
    sub s10, tp, s10
    add tp, tp, s9
    /* Keep a copy of tp */
    add t3, tp, zero
    /* Counter */
    li  t2, 1
    /* hartid 0 is mandated by ISA */
    li  t1, 0

_scratch_init:
    /*
     * The following registers hold values that are computed before
     * entering this block, and should remain unchanged.
     *
     * t3 -> the firmware end address
     * s7 -> HART count
     * s8 -> HART stack size
     * s9 -> Heap Size
     * s10 -> Heap Offset
     */
    add tp, t3, zero
    sub tp, tp, s9
    mul a5, s8, t1
    sub tp, tp, a5
    li  a5, SBI_SCRATCH_SIZE
    sub tp, tp, a5

    /* Initialize scratch space */
    /* Store fw_start and fw_size in scratch space */
    lla a4, _fw_start
    sub a5, t3, a4
    REG_S   a4, SBI_SCRATCH_FW_START_OFFSET(tp)
    REG_S   a5, SBI_SCRATCH_FW_SIZE_OFFSET(tp)

    /* Store R/W section's offset in scratch space */
    lla a4, __fw_rw_offset
    REG_L   a5, 0(a4)
    REG_S   a5, SBI_SCRATCH_FW_RW_OFFSET(tp)

    /* Store fw_heap_offset and fw_heap_size in scratch space */
    REG_S   s10, SBI_SCRATCH_FW_HEAP_OFFSET(tp)
    REG_S   s9, SBI_SCRATCH_FW_HEAP_SIZE_OFFSET(tp)

    /* Store next arg1 in scratch space */
    MOV_3R  s0, a0, s1, a1, s2, a2
    call    fw_next_arg1
    REG_S   a0, SBI_SCRATCH_NEXT_ARG1_OFFSET(tp)
    MOV_3R  a0, s0, a1, s1, a2, s2
    /* Store next address in scratch space */
    MOV_3R  s0, a0, s1, a1, s2, a2
    call    fw_next_addr
    REG_S   a0, SBI_SCRATCH_NEXT_ADDR_OFFSET(tp)
    MOV_3R  a0, s0, a1, s1, a2, s2
    /* Store next mode in scratch space */
    MOV_3R  s0, a0, s1, a1, s2, a2
    call    fw_next_mode
    REG_S   a0, SBI_SCRATCH_NEXT_MODE_OFFSET(tp)
    MOV_3R  a0, s0, a1, s1, a2, s2
    /* Store warm_boot address in scratch space */
    lla a4, _start_warm
    REG_S   a4, SBI_SCRATCH_WARMBOOT_ADDR_OFFSET(tp)
    /* Store platform address in scratch space */
    lla a4, platform
    REG_S   a4, SBI_SCRATCH_PLATFORM_ADDR_OFFSET(tp)
    /* Store hartid-to-scratch function address in scratch space */
    lla a4, _hartid_to_scratch
    REG_S   a4, SBI_SCRATCH_HARTID_TO_SCRATCH_OFFSET(tp)
    /* Store trap-exit function address in scratch space */
    lla a4, _trap_exit
    REG_S   a4, SBI_SCRATCH_TRAP_EXIT_OFFSET(tp)
    /* Clear tmp0 in scratch space */
    REG_S   zero, SBI_SCRATCH_TMP0_OFFSET(tp)
    /* Store firmware options in scratch space */
    MOV_3R  s0, a0, s1, a1, s2, a2
#ifdef FW_OPTIONS
    li  a0, FW_OPTIONS
#else
    call    fw_options
#endif
    REG_S   a0, SBI_SCRATCH_OPTIONS_OFFSET(tp)
    MOV_3R  a0, s0, a1, s1, a2, s2
    /* Move to next scratch space */
    add t1, t1, t2
    blt t1, s7, _scratch_init

    /*
     * Relocate Flatened Device Tree (FDT)
     * source FDT address = previous arg1
     * destination FDT address = next arg1
     *
     * Note: We will preserve a0 and a1 passed by
     * previous booting stage.
     */
    beqz    a1, _fdt_reloc_done
    /* Mask values in a4 */
    li  a4, 0xff
    /* t1 = destination FDT start address */
    MOV_3R  s0, a0, s1, a1, s2, a2
    call    fw_next_arg1
    add t1, a0, zero
    MOV_3R  a0, s0, a1, s1, a2, s2
    beqz    t1, _fdt_reloc_done
    beq t1, a1, _fdt_reloc_done
    /* t0 = source FDT start address */
    add t0, a1, zero
    /* t2 = source FDT size in big-endian */
#if __riscv_xlen == 64
    lwu t2, 4(t0)
#else
    lw  t2, 4(t0)
#endif
    /* t3 = bit[15:8] of FDT size */
    add t3, t2, zero
    srli    t3, t3, 16
    and t3, t3, a4
    slli    t3, t3, 8
    /* t4 = bit[23:16] of FDT size */
    add t4, t2, zero
    srli    t4, t4, 8
    and t4, t4, a4
    slli    t4, t4, 16
    /* t5 = bit[31:24] of FDT size */
    add t5, t2, zero
    and t5, t5, a4
    slli    t5, t5, 24
    /* t2 = bit[7:0] of FDT size */
    srli    t2, t2, 24
    and t2, t2, a4
    /* t2 = FDT size in little-endian */
    or  t2, t2, t3
    or  t2, t2, t4
    or  t2, t2, t5
    /* t2 = destination FDT end address */
    add t2, t1, t2
    /* FDT copy loop */
    ble t2, t1, _fdt_reloc_done
_fdt_reloc_again:
    REG_L   t3, 0(t0)
    REG_S   t3, 0(t1)
    add t0, t0, __SIZEOF_POINTER__
    add t1, t1, __SIZEOF_POINTER__
    blt t1, t2, _fdt_reloc_again
_fdt_reloc_done:

    /* mark boot hart done */
    li  t0, BOOT_STATUS_BOOT_HART_DONE
    lla t1, _boot_status
    REG_S   t0, 0(t1)
    fence   rw, rw
    j   _start_warm

    /* waiting for boot hart to be done (_boot_status == 2) */
_wait_for_boot_hart:
    li  t0, BOOT_STATUS_BOOT_HART_DONE
    lla t1, _boot_status
    REG_L   t1, 0(t1)
    /* Reduce the bus traffic so that boot hart may proceed faster */
    nop
    nop
    nop
    bne t0, t1, _wait_for_boot_hart

_start_warm:
    /* Reset all registers for non-boot HARTs */
    li  ra, 0
    call    _reset_regs

    /* Disable all interrupts */
    csrw    CSR_MIE, zero

    /* Find HART count and HART stack size */
    lla a4, platform
#if __riscv_xlen == 64
    lwu s7, SBI_PLATFORM_HART_COUNT_OFFSET(a4)
    lwu s8, SBI_PLATFORM_HART_STACK_SIZE_OFFSET(a4)
#else
    lw  s7, SBI_PLATFORM_HART_COUNT_OFFSET(a4)
    lw  s8, SBI_PLATFORM_HART_STACK_SIZE_OFFSET(a4)
#endif
    REG_L   s9, SBI_PLATFORM_HART_INDEX2ID_OFFSET(a4)

    /* Find HART id */
    csrr    s6, CSR_MHARTID

    /* Find HART index */
    beqz    s9, 3f
    li  a4, 0
1:
#if __riscv_xlen == 64
    lwu a5, (s9)
#else
    lw  a5, (s9)
#endif
    beq a5, s6, 2f
    add s9, s9, 4
    add a4, a4, 1
    blt a4, s7, 1b
2:  add s6, a4, zero
3:  bge s6, s7, _start_hang

    /* Find the scratch space based on HART index */
    lla tp, _fw_end
    mul a5, s7, s8
    add tp, tp, a5
    mul a5, s8, s6
    sub tp, tp, a5
    li  a5, SBI_SCRATCH_SIZE
    sub tp, tp, a5

    /* update the mscratch */
    csrw    CSR_MSCRATCH, tp

    /* Setup stack */
    add sp, tp, zero

    /* Setup trap handler */
    lla a4, _trap_handler
#if __riscv_xlen == 32
    csrr    a5, CSR_MISA
    srli    a5, a5, ('H' - 'A')
    andi    a5, a5, 0x1
    beq a5, zero, _skip_trap_handler_rv32_hyp
    lla a4, _trap_handler_rv32_hyp
_skip_trap_handler_rv32_hyp:
#endif
    csrw    CSR_MTVEC, a4

#if __riscv_xlen == 32
    /* Override trap exit for H-extension */
    csrr    a5, CSR_MISA
    srli    a5, a5, ('H' - 'A')
    andi    a5, a5, 0x1
    beq a5, zero, _skip_trap_exit_rv32_hyp
    lla a4, _trap_exit_rv32_hyp
    csrr    a5, CSR_MSCRATCH
    REG_S   a4, SBI_SCRATCH_TRAP_EXIT_OFFSET(a5)
_skip_trap_exit_rv32_hyp:
#endif

    /* Initialize SBI runtime */
    csrr    a0, CSR_MSCRATCH
    call    sbi_init

    /* We don't expect to reach here hence just hang */
    j   _start_hang

    .data
    .align 3
#ifdef FW_PIC
_runtime_offset:
    RISCV_PTR   0
#endif
_relocate_lottery:
    RISCV_PTR   0
_boot_status:
    RISCV_PTR   0
_load_start:
    RISCV_PTR   _fw_start
_link_start:
    RISCV_PTR   FW_TEXT_START
_link_end:
    RISCV_PTR   _fw_reloc_end
__fw_rw_offset:
    RISCV_PTR   _fw_rw_start - _fw_start

    .section .entry, "ax", %progbits
    .align 3
    .globl _hartid_to_scratch
_hartid_to_scratch:
    /*
     * a0 -> HART ID (passed by caller)
     * a1 -> HART Index (passed by caller)
     * t0 -> HART Stack Size
     * t1 -> HART Stack End
     * t2 -> Temporary
     */
    lla t2, platform
#if __riscv_xlen == 64
    lwu t0, SBI_PLATFORM_HART_STACK_SIZE_OFFSET(t2)
    lwu t2, SBI_PLATFORM_HART_COUNT_OFFSET(t2)
#else
    lw  t0, SBI_PLATFORM_HART_STACK_SIZE_OFFSET(t2)
    lw  t2, SBI_PLATFORM_HART_COUNT_OFFSET(t2)
#endif
    sub t2, t2, a1
    mul t2, t2, t0
    lla t1, _fw_end
    add t1, t1, t2
    li  t2, SBI_SCRATCH_SIZE
    sub a0, t1, t2
    ret

    .section .entry, "ax", %progbits
    .align 3
    .globl _start_hang
_start_hang:
    wfi
    j   _start_hang

    .section .entry, "ax", %progbits
    .align 3
    .weak fw_platform_init
fw_platform_init:
    add a0, a1, zero
    ret

    /* Map implicit memcpy() added by compiler to sbi_memcpy() */
    .section .text
    .align 3
    .globl memcpy
memcpy:
    tail    sbi_memcpy

    /* Map implicit memset() added by compiler to sbi_memset() */
    .section .text
    .align 3
    .globl memset
memset:
    tail    sbi_memset

    /* Map implicit memmove() added by compiler to sbi_memmove() */
    .section .text
    .align 3
    .globl memmove
memmove:
    tail    sbi_memmove

    /* Map implicit memcmp() added by compiler to sbi_memcmp() */
    .section .text
    .align 3
    .globl memcmp
memcmp:
    tail    sbi_memcmp

.macro  TRAP_SAVE_AND_SETUP_SP_T0
    /* Swap TP and MSCRATCH */
    csrrw   tp, CSR_MSCRATCH, tp

    /* Save T0 in scratch space */
    REG_S   t0, SBI_SCRATCH_TMP0_OFFSET(tp)

    /*
     * Set T0 to appropriate exception stack
     *
     * Came_From_M_Mode = ((MSTATUS.MPP < PRV_M) ? 1 : 0) - 1;
     * Exception_Stack = TP ^ (Came_From_M_Mode & (SP ^ TP))
     *
     * Came_From_M_Mode = 0    ==>    Exception_Stack = TP
     * Came_From_M_Mode = -1   ==>    Exception_Stack = SP
     */
    csrr    t0, CSR_MSTATUS
    srl t0, t0, MSTATUS_MPP_SHIFT
    and t0, t0, PRV_M
    slti    t0, t0, PRV_M
    add t0, t0, -1
    xor sp, sp, tp
    and t0, t0, sp
    xor sp, sp, tp
    xor t0, tp, t0

    /* Save original SP on exception stack */
    REG_S   sp, (SBI_TRAP_REGS_OFFSET(sp) - SBI_TRAP_REGS_SIZE)(t0)

    /* Set SP to exception stack and make room for trap registers */
    add sp, t0, -(SBI_TRAP_REGS_SIZE)

    /* Restore T0 from scratch space */
    REG_L   t0, SBI_SCRATCH_TMP0_OFFSET(tp)

    /* Save T0 on stack */
    REG_S   t0, SBI_TRAP_REGS_OFFSET(t0)(sp)

    /* Swap TP and MSCRATCH */
    csrrw   tp, CSR_MSCRATCH, tp
.endm

.macro  TRAP_SAVE_MEPC_MSTATUS have_mstatush
    /* Save MEPC and MSTATUS CSRs */
    csrr    t0, CSR_MEPC
    REG_S   t0, SBI_TRAP_REGS_OFFSET(mepc)(sp)
    csrr    t0, CSR_MSTATUS
    REG_S   t0, SBI_TRAP_REGS_OFFSET(mstatus)(sp)
    .if \have_mstatush
    csrr    t0, CSR_MSTATUSH
    REG_S   t0, SBI_TRAP_REGS_OFFSET(mstatusH)(sp)
    .else
    REG_S   zero, SBI_TRAP_REGS_OFFSET(mstatusH)(sp)
    .endif
.endm

.macro  TRAP_SAVE_GENERAL_REGS_EXCEPT_SP_T0
    /* Save all general regisers except SP and T0 */
    REG_S   zero, SBI_TRAP_REGS_OFFSET(zero)(sp)
    REG_S   ra, SBI_TRAP_REGS_OFFSET(ra)(sp)
    REG_S   gp, SBI_TRAP_REGS_OFFSET(gp)(sp)
    REG_S   tp, SBI_TRAP_REGS_OFFSET(tp)(sp)
    REG_S   t1, SBI_TRAP_REGS_OFFSET(t1)(sp)
    REG_S   t2, SBI_TRAP_REGS_OFFSET(t2)(sp)
    REG_S   s0, SBI_TRAP_REGS_OFFSET(s0)(sp)
    REG_S   s1, SBI_TRAP_REGS_OFFSET(s1)(sp)
    REG_S   a0, SBI_TRAP_REGS_OFFSET(a0)(sp)
    REG_S   a1, SBI_TRAP_REGS_OFFSET(a1)(sp)
    REG_S   a2, SBI_TRAP_REGS_OFFSET(a2)(sp)
    REG_S   a3, SBI_TRAP_REGS_OFFSET(a3)(sp)
    REG_S   a4, SBI_TRAP_REGS_OFFSET(a4)(sp)
    REG_S   a5, SBI_TRAP_REGS_OFFSET(a5)(sp)
    REG_S   a6, SBI_TRAP_REGS_OFFSET(a6)(sp)
    REG_S   a7, SBI_TRAP_REGS_OFFSET(a7)(sp)
    REG_S   s2, SBI_TRAP_REGS_OFFSET(s2)(sp)
    REG_S   s3, SBI_TRAP_REGS_OFFSET(s3)(sp)
    REG_S   s4, SBI_TRAP_REGS_OFFSET(s4)(sp)
    REG_S   s5, SBI_TRAP_REGS_OFFSET(s5)(sp)
    REG_S   s6, SBI_TRAP_REGS_OFFSET(s6)(sp)
    REG_S   s7, SBI_TRAP_REGS_OFFSET(s7)(sp)
    REG_S   s8, SBI_TRAP_REGS_OFFSET(s8)(sp)
    REG_S   s9, SBI_TRAP_REGS_OFFSET(s9)(sp)
    REG_S   s10, SBI_TRAP_REGS_OFFSET(s10)(sp)
    REG_S   s11, SBI_TRAP_REGS_OFFSET(s11)(sp)
    REG_S   t3, SBI_TRAP_REGS_OFFSET(t3)(sp)
    REG_S   t4, SBI_TRAP_REGS_OFFSET(t4)(sp)
    REG_S   t5, SBI_TRAP_REGS_OFFSET(t5)(sp)
    REG_S   t6, SBI_TRAP_REGS_OFFSET(t6)(sp)
.endm

.macro  TRAP_CALL_C_ROUTINE
    /* Call C routine */
    add a0, sp, zero
    call    sbi_trap_handler
.endm

.macro  TRAP_RESTORE_GENERAL_REGS_EXCEPT_A0_T0
    /* Restore all general regisers except A0 and T0 */
    REG_L   ra, SBI_TRAP_REGS_OFFSET(ra)(a0)
    REG_L   sp, SBI_TRAP_REGS_OFFSET(sp)(a0)
    REG_L   gp, SBI_TRAP_REGS_OFFSET(gp)(a0)
    REG_L   tp, SBI_TRAP_REGS_OFFSET(tp)(a0)
    REG_L   t1, SBI_TRAP_REGS_OFFSET(t1)(a0)
    REG_L   t2, SBI_TRAP_REGS_OFFSET(t2)(a0)
    REG_L   s0, SBI_TRAP_REGS_OFFSET(s0)(a0)
    REG_L   s1, SBI_TRAP_REGS_OFFSET(s1)(a0)
    REG_L   a1, SBI_TRAP_REGS_OFFSET(a1)(a0)
    REG_L   a2, SBI_TRAP_REGS_OFFSET(a2)(a0)
    REG_L   a3, SBI_TRAP_REGS_OFFSET(a3)(a0)
    REG_L   a4, SBI_TRAP_REGS_OFFSET(a4)(a0)
    REG_L   a5, SBI_TRAP_REGS_OFFSET(a5)(a0)
    REG_L   a6, SBI_TRAP_REGS_OFFSET(a6)(a0)
    REG_L   a7, SBI_TRAP_REGS_OFFSET(a7)(a0)
    REG_L   s2, SBI_TRAP_REGS_OFFSET(s2)(a0)
    REG_L   s3, SBI_TRAP_REGS_OFFSET(s3)(a0)
    REG_L   s4, SBI_TRAP_REGS_OFFSET(s4)(a0)
    REG_L   s5, SBI_TRAP_REGS_OFFSET(s5)(a0)
    REG_L   s6, SBI_TRAP_REGS_OFFSET(s6)(a0)
    REG_L   s7, SBI_TRAP_REGS_OFFSET(s7)(a0)
    REG_L   s8, SBI_TRAP_REGS_OFFSET(s8)(a0)
    REG_L   s9, SBI_TRAP_REGS_OFFSET(s9)(a0)
    REG_L   s10, SBI_TRAP_REGS_OFFSET(s10)(a0)
    REG_L   s11, SBI_TRAP_REGS_OFFSET(s11)(a0)
    REG_L   t3, SBI_TRAP_REGS_OFFSET(t3)(a0)
    REG_L   t4, SBI_TRAP_REGS_OFFSET(t4)(a0)
    REG_L   t5, SBI_TRAP_REGS_OFFSET(t5)(a0)
    REG_L   t6, SBI_TRAP_REGS_OFFSET(t6)(a0)
.endm

.macro  TRAP_RESTORE_MEPC_MSTATUS have_mstatush
    /* Restore MEPC and MSTATUS CSRs */
    REG_L   t0, SBI_TRAP_REGS_OFFSET(mepc)(a0)
    csrw    CSR_MEPC, t0
    REG_L   t0, SBI_TRAP_REGS_OFFSET(mstatus)(a0)
    csrw    CSR_MSTATUS, t0
    .if \have_mstatush
    REG_L   t0, SBI_TRAP_REGS_OFFSET(mstatusH)(a0)
    csrw    CSR_MSTATUSH, t0
    .endif
.endm

.macro TRAP_RESTORE_A0_T0
    /* Restore T0 */
    REG_L   t0, SBI_TRAP_REGS_OFFSET(t0)(a0)

    /* Restore A0 */
    REG_L   a0, SBI_TRAP_REGS_OFFSET(a0)(a0)
.endm

    .section .entry, "ax", %progbits
    .align 3
    .globl _trap_handler
    .globl _trap_exit
_trap_handler:
    TRAP_SAVE_AND_SETUP_SP_T0

    TRAP_SAVE_MEPC_MSTATUS 0

    TRAP_SAVE_GENERAL_REGS_EXCEPT_SP_T0

    TRAP_CALL_C_ROUTINE

_trap_exit:
    TRAP_RESTORE_GENERAL_REGS_EXCEPT_A0_T0

    TRAP_RESTORE_MEPC_MSTATUS 0

    TRAP_RESTORE_A0_T0

    mret

#if __riscv_xlen == 32
    .section .entry, "ax", %progbits
    .align 3
    .globl _trap_handler_rv32_hyp
    .globl _trap_exit_rv32_hyp
_trap_handler_rv32_hyp:
    TRAP_SAVE_AND_SETUP_SP_T0

    TRAP_SAVE_MEPC_MSTATUS 1

    TRAP_SAVE_GENERAL_REGS_EXCEPT_SP_T0

    TRAP_CALL_C_ROUTINE

_trap_exit_rv32_hyp:
    TRAP_RESTORE_GENERAL_REGS_EXCEPT_A0_T0

    TRAP_RESTORE_MEPC_MSTATUS 1

    TRAP_RESTORE_A0_T0

    mret
#endif

    .section .entry, "ax", %progbits
    .align 3
    .globl _reset_regs
_reset_regs:

    /* flush the instruction cache */
    fence.i
    /* Reset all registers except ra, a0, a1 and a2 */
    li sp, 0
    li gp, 0
    li tp, 0
    li t0, 0
    li t1, 0
    li t2, 0
    li s0, 0
    li s1, 0
    li a3, 0
    li a4, 0
    li a5, 0
    li a6, 0
    li a7, 0
    li s2, 0
    li s3, 0
    li s4, 0
    li s5, 0
    li s6, 0
    li s7, 0
    li s8, 0
    li s9, 0
    li s10, 0
    li s11, 0
    li t3, 0
    li t4, 0
    li t5, 0
    li t6, 0
    csrw CSR_MSCRATCH, 0

    ret

#ifdef FW_FDT_PATH
    .section .rodata
    .align 4
    .globl fw_fdt_bin
fw_fdt_bin:
    .incbin FW_FDT_PATH
#ifdef FW_FDT_PADDING
    .fill FW_FDT_PADDING, 1, 0
#endif
#endif
