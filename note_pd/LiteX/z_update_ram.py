#!/usr/bin/env python3

import sys
import os
import argparse

'''
+ SpinalHDL 將一個 32-bit 寬的 RAM 拆成 4 個並聯的 8-bit 寬記憶體陣列:
    - ram_symbol0: 負責最低位元組 (Bit 7:0)
    - ram_symbol1: 負責次低位元組 (Bit 15:8)
    - ram_symbol2: 負責次高位元組 (Bit 23:16)
    - ram_symbol3: 負責最高位元組 (Bit 31:24)
'''

parser = argparse.ArgumentParser(description='Split bin file to 4 symbol X (X= 0 ~ 3) to fit SRAM controller access\n')
parser.add_argument("-i", "--Input", type=str, help="VexRISCV APP Bin file\n")

args = parser.parse_args()

if not args.Input:
    print('No input parameter ...')
    sys.exit(1)

# 預設的編譯產物路徑與 RAM 深度設定(4 kB = 1024 words)
DEFAULT_BIN_PATH = args.Input

'''
如果 Murax.scala 中把 onChipRamSize 調大(例如改成 8 kB 或 16 kB),
只需將 RAM_DEPTH_WORDS 改成 2048 (8kB / 4) 或 4096 (16kB / 4) 即可
'''
RAM_DEPTH_WORDS = 1024  # 對應 MuraxWithRamInit 的 4 kB (4096 bytes / 4)
MAX_BYTES = RAM_DEPTH_WORDS * 4

def main():
    # 支援從命令列傳入自訂的 .bin 路徑，若無則使用預設路徑
    bin_path = DEFAULT_BIN_PATH

    if not os.path.exists(bin_path):
        print(f"[Err] No input Bin file: {bin_path}")
        sys.exit(1)

    with open(bin_path, "rb") as f:
        raw_data = bytearray(f.read())

    orig_size = len(raw_data)
    if orig_size > MAX_BYTES:
        print(f"[警告] 檔案大小 ({orig_size} bytes) 超過 On-chip RAM 容量 ({MAX_BYTES} bytes)，超出的部分將被截斷！")
        raw_data = raw_data[:MAX_BYTES]
    else:
        # 自動補齊 0x00 直到填滿 4096 bytes (1024 words)
        raw_data.extend(b'\x00' * (MAX_BYTES - orig_size))

    # 寫入四個 byte-lane 初始化檔案
    files = [open(f"Murax.v_toplevel_system_ram_ram_symbol{i}.bin", "w") for i in range(4)]

    for word_idx in range(RAM_DEPTH_WORDS):
        base = word_idx * 4
        for byte_idx in range(4):
            files[byte_idx].write(f"{raw_data[base + byte_idx]:08b}\n")

    for f in files:
        f.close()

    print(f"[成功] 已將 {bin_path} ({orig_size} bytes) 轉換並補齊至 {RAM_DEPTH_WORDS} 行 (9216 bytes/檔)。")

if __name__ == "__main__":
    main()
