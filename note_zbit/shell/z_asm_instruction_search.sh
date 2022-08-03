#!/bin/bash

asm_file=$1

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
NC='\e[0m'

help()
{
    echo -e "usage: $0 [disassembly.asm]"
    exit -1;
}

m0p_instruction_set=(
ADCS
ADD
ADR
ANDS
ASRS
B
BICS
BKPT
BL
BLX
BX
CMN
CMP
CPSID
CPSIE
DMB
DSB
EORS
ISB
LDM
LDR
LDR
LDRB
LDRH
LDRSB
LDRSH
LSLS
LSRS
MOV
MRS
MSR
MULS
MVNS
NOP
ORRS
POP
PUSH
REV
REV16
REVSH
RORS
RSBS
SBCS
SEV
STM
STR
STRB
STRH
SUB
SVC
SXTB
SXTH
TST
UXTB
UXTH
WFE
WFI
)

if [ $# != 1 ]; then
    help
fi

echo -e "${Green}Search Cortex-M0+ instruction set...${NC}"
grep '^[ \t]*0x[a-fA-F0-9]*' $asm_file > $asm_file.tmp

for instruction in "${m0p_instruction_set[@]}"; do

    if ! grep -i -q "${instruction} " $asm_file.tmp; then
        echo -e "${Yellow} No ${instruction} ${NC}"
    fi

done

rm -f $asm_file.tmp
