#!/bin/bash
#
# https://www.build-python-from-source.com/
#


wget https://www.python.org/ftp/python/3.9.18/Python-3.9.18.tgz
tar xzf Python-3.9.18.tgz
cd Python-3.9.18

# ./configure --prefix=/opt/python/3.9.18/ --enable-optimizations --with-lto --with-computed-gotos --with-system-ffi
./configure --enable-optimizations --with-lto --with-computed-gotos --with-system-ffi
make

# sudo make -j "$(nproc)"
# sudo make altinstall
# sudo rm /tmp/Python-3.9.18.tgz
