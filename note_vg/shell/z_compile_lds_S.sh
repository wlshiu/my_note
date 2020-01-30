#!/bin/bash

set -e

arm-none-eabi-gcc -E -P gcc_arm.lds.S -include autoconfig.h > target.lds
