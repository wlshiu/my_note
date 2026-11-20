/*
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
*/
OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv")
OUTPUT_ARCH(riscv)

 __STACK_SIZE = 0x00000200;

ENTRY(_start)

MEMORY
{
  FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 32K
  RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 2K
}

SECTIONS
{
  /* 程式進入點與中斷向量表 (位於 0x00000000) */
  .text :
  {
    . = ALIGN(4);
    KEEP(*(.init))
    /* 確保中斷向量表對齊 0x00000020 (對應 CsrPlugin 的 mtvecInit) */
    . = ORIGIN(FLASH) + 0x20;
    KEEP(*(.trap))
    *(.text .text.*)
    *(.rodata .rodata.*)
    *(.srodata .srodata.*)
    . = ALIGN(4);
  } > FLASH

  /* 記錄 .data 在 Flash 中的起始位置 (Load Memory Address) */
  _data_lma = LOADADDR(.data);

  /* 已初始化的全域/靜態變數 (執行時位於 SRAM, 初始值存於 Flash) */
  .data :
  {
    . = ALIGN(4);
    _data_vma_start = .;
    PROVIDE( __global_pointer$ = . + 0x400 ); /* 訂在 SRAM size 的一半為最佳 */
    *(.data .data.*)
    *(.sdata .sdata.*)
    . = ALIGN(4);
    _data_vma_end = .;
  } > RAM AT > FLASH

  /* 未初始化變數區段 (位於 SRAM, 開機清零) */
  .bss (NOLOAD) :
  {
    . = ALIGN(4);
    _bss_start = .;
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
    . = ALIGN(4);
    _bss_end = .;
  } > RAM

  /* 檢查剩餘 SRAM 是否足以容納最小 Stack (例如 512 Bytes) */
  ._stack_check (NOLOAD) :
  {
    . = ALIGN(8);
    . = . + __STACK_SIZE;
    . = ALIGN(8);
  } > RAM

  /* 堆疊指標設在 2KB SRAM 的最頂端 (0x20000000 + 0x800) */
  PROVIDE(_stack_start = ORIGIN(RAM) + LENGTH(RAM));
}

