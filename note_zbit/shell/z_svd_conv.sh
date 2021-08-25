#!/bin/bash

SVD_FILE=$1

KEIL_MDK="/C/Keil_v5/UV4"
env_setup_file=__env.sh
echo "export PATH=\"\$KEIL_MDK:\$PATH\"" >> $env_setup_file

source $env_setup_file

rm -f $env_setup_file


SVDConv.exe ${SVD_FILE} --generate=header --fields=struct --fields=macro # --fields=enum

SVDConv.exe ${SVD_FILE} --generate=sfr

# SfrCC2.exe ${SVD_FILE}