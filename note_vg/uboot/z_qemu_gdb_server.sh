#!/bin/bash -

set -e

## GDB server
qemu-system-arm -M vexpress-a9 -nographic -m 256M -kernel u-boot -s -S
