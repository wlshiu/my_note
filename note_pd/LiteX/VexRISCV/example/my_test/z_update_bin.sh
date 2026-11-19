#!/bin/bash

make clean && make

./z_update_ram.py -i ./build/my_test.bin -t flash

cp -f Murax.v_toplevel_system_eFlash_flash.bin $HOME/Working/vexriscv/VexRiscv/
