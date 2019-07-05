#!/bin/bash

set -e

CROSS_COMPILE=arm-none-eabi-

## convert raw binary to object file
# ${CROSS_COMPILE}objcopy --readonly-text -I binary -O elf32-little -B arm Rio.jpg Rio.o

## convert object file to raw binary
# ${CROSS_COMPILE}objcopy -I elf32-little -O binary Rio.o Rio.bin

## list the symbol
# ${CROSS_COMPILE}objdump -x Rio.o


## insert
# ${CROSS_COMPILE}objcopy --add-section .img_dsp=sunflower.jpg phoenix_rom.elf phoenix_rom.add.elf
${CROSS_COMPILE}objcopy --add-section .img_1=minion.jpg --add-section .img_2=sunflower.jpg ./out/phoenix_rom.elf phoenix_rom.add.elf


## list section 
# ${CROSS_COMPILE}readelf -S ./phoenix_rom.add.elf

## dump
# ${CROSS_COMPILE}objcopy --dump-section .mydata=mydate.dump ./phoenix_rom.add.elf
