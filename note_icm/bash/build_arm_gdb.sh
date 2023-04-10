#!/usr/bin/env sh

export TARGET=arm-none-eabi
export PREFIX=$HOME/.local
export PATH=$PATH:$PREFIX/bin

export VERSION=7.8.1
export GDB=gdb-$VERSION

rm -rf $GDB

# Get archives
if [ ! -f ${GDB}.tar.gz ]; then
    wget http://ftp.gnu.org/gnu/gdb/$GDB.tar.gz
fi

# Extract archives
tar xzf $GDB.tar.gz

mkdir build-gdb
cd build-gdb
../$GDB/configure --target=$TARGET --prefix=$PREFIX --enable-interwork --enable-multilib --with-python
make
# make install
