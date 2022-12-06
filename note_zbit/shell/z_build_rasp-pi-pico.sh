#!/bin/bash

mkdir ~/raspberry-pi-pico
cd ~/raspberry-pi-pico
mkdir pico
cd pico
git clone -b master https://github.com/raspberrypi/pico-sdk.git
cd pico-sdk
git submodule update --init
cd ..
git clone -b master https://github.com/raspberrypi/pico-examples.git


export PICO_SDK_PATH=${HOME}/raspberry-pi-pico/pico/pico-sdk
export PICO_EXAMPLES_PATH=${HOME}/raspberry-pi-pico/pico/pico-examples

cd ~/raspberry-pi-pico/pico

mkdir build
cd build
cmake ../pico-examples
make

#######
# modify raspberry-pi-pico\pico\build\generated\pico_base\pico\config_autogen.h
#
# // based on PICO_CONFIG_HEADER_FILES:
# #include "../../../../pico-sdk/src/boards/include/boards/pico.h"
#
# // based on PICO_RP2040_CONFIG_HEADER_FILES:
#
# #include "../../../../pico-sdk/src/rp2_common/cmsis/include/cmsis/rename_exceptions.h"
#
