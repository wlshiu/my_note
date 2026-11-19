#!/usr/bin/env python3

import sys
import os
import struct
import argparse

'''
記憶體初始化檔轉換腳本:
1. flash 模式 (預設, 對應 MuraxEmbeddedFlash 32KB XIP 架構):
    - 輸出單一 32-bit 寬度初始化檔: Murax.v_toplevel_system_eFlash_flash.bin (8192 行, 每行 32-bit 二進位)
2. ram 模式 (對應舊版 MuraxPipelinedMemoryBusRam 架構):
    - 拆分為 4 個並聯的 8-bit 記憶體陣列: Murax.v_toplevel_system_ram_ram_symbol0~3.bin
    - SpinalHDL 將一個 32-bit 寬的 RAM 拆成 4 個並聯的 8-bit 寬記憶體陣列:
        1. ram_symbol0: 負責最低位元組 (Bit 7:0)
        1. ram_symbol1: 負責次低位元組 (Bit 15:8)
        1. ram_symbol2: 負責次高位元組 (Bit 23:16)
        1. ram_symbol3: 負責最高位元組 (Bit 31:24)
'''

parser = argparse.ArgumentParser(description='Convert VexRiscv APP Bin file to SpinalHDL memory init files\n')
parser.add_argument("-i", "--Input", type=str, required=True, help="VexRISCV APP Bin file (e.g., build/my_hello.bin)\n")
parser.add_argument("-t", "--Target", type=str, choices=["flash", "ram"], default="flash",
                    help="Target memory type: 'flash' (32KB single file, default) or 'ram' (2KB 4-symbol files)\n")
parser.add_argument("-s", "--Size", type=int, default=None,
                    help="Override memory size in KB (default: 32 for flash, 2 for ram)\n")

args = parser.parse_args()

def main():
    bin_path = args.Input

    if not os.path.exists(bin_path):
        print(f"[Err] No input Bin file: {bin_path}")
        sys.exit(1)

    # 決定目標記憶體容量 (Bytes)
    if args.Size is not None:
        max_bytes = args.Size * 1024
    else:
        max_bytes = (32 * 1024) if args.Target == "flash" else (2 * 1024)

    depth_words = max_bytes // 4

    with open(bin_path, "rb") as f:
        raw_data = bytearray(f.read())

    orig_size = len(raw_data)
    if orig_size > max_bytes:
        print(f"[警告] 檔案大小 ({orig_size} bytes) 超過目標 {args.Target.upper()} 容量 ({max_bytes} bytes)，超出的部分將被截斷！")
        raw_data = raw_data[:max_bytes]
    else:
        # 自動補齊 0x00 直到填滿目標容量
        raw_data.extend(b'\x00' * (max_bytes - orig_size))

    if args.Target == "flash":
        # 輸出單一 32-bit 寬度檔案給 MuraxEmbeddedFlash (Little-Endian 轉 32-bit Word)
        out_name = "Murax.v_toplevel_system_eFlash_flash.bin"
        with open(out_name, "w") as out_f:
            for word_idx in range(depth_words):
                base = word_idx * 4
                word = int.from_bytes(raw_data[base:base + 4], "little")
                out_f.write(f"{word:032b}\n")
        print(f"[成功] [Flash 模式] 已將 {bin_path} ({orig_size} bytes) 轉換至 {out_name} ({depth_words} words / {max_bytes // 1024} KB)。")

    else:
        # 寫入四個 byte-lane 初始化檔案給 On-chip RAM
        files = [open(f"Murax.v_toplevel_system_ram_ram_symbol{i}.bin", "w") for i in range(4)]
        for word_idx in range(depth_words):
            base = word_idx * 4
            for byte_idx in range(4):
                files[byte_idx].write(f"{raw_data[base + byte_idx]:08b}\n")
        for f in files:
            f.close()
        print(f"[成功] [RAM 模式] 已將 {bin_path} ({orig_size} bytes) 轉換並補齊至 {depth_words} 行 (4 個 symbol 檔)。")

if __name__ == "__main__":
    main()
