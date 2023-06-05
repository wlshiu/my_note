#!/bin/bash

# issue: Python requires a OpenSSL 1.1.1 or newer
#   use libressl to replace openssl
#   $ wget https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-3.0.2.tar.gz
#   $ tar -zxvf libressl-3.0.2.tar.gz
#   $ mkdir /usr/local/libressl
#   $ cd libressl-3.0.2
#   $ ./configure --prefix=$HOME/.local
#   $ make
#
#   Symbolic link to replace openssl
#   $ mv /usr/bin/openssl /usr/bin/openssl.bak
#   $ mv /usr/include/openssl /usr/include/openssl.bak
#   $ ln -s $HOME/.local/bin/openssl /usr/bin/openssl
#   $ ln -s $HOME/.local/include/openssl /usr/include/openssl
#   $ echo $HOME/.local/libressl/lib >> /etc/ld.so.conf.d/libressl-3.0.2.conf
#   $ ldconfig -v
#
#   Verfiy
#   $ openssl version
#   $ export LDFLAGS="-L$HOME/.local/lib"
#   $ export CPPFLAGS="-I$HOME/.local/include"
#   $ export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig"
#


# dependancy:
#   $ sudo apt install libffi-dev


wget https://www.python.org/ftp/python/3.10.11/Python-3.10.11.tgz
tar xzf Python-3.10.11.tgz
cd Python-3.10.11

./configure --prefix=$HOME/.local/ --enable-optimizations --with-lto --with-computed-gotos --with-system-ffi
make -j "$(nproc)"
