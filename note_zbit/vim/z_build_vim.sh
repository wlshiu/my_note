#!/bin/bash

#
#   dependency:
#   + python-devel
#
#
#
#   --enable-gui=auto
#   --enable-gtk2-check
#
#   --enable-multibyte  (support unicode)
#
#   Ruby
#   --enable-rubyinterp=dynamic
#   --with-ruby-command=/usr/bin/ruby
#
#   python2
#   --enable-pythoninterp=dynamic \
#   --with-python-config-dir=/usr/lib/python2.7/config \
#
#   python3
#   --with-python3-config-dir=/usr/lib/python3.9/config-3.9-x86_64-msys
#


# ./configure --with-features=huge \
    # --enable-multibyte \
    # --disable-gtktest \
    # --disable-xsmp \
    # --enable-cscope \
    # --disable-netbeans \
    # --disable-channel \
    # --enable-terminal \
    # --disable-canberra \
    # --disable-libsodium \
    # --disable-nls \
    # --disable-arabic \
    # --disable-rightleft \
    # --disable-darwin \
    # --enable-python3interp=dynamic \
    # --with-python3-command=python \
    # --with-python3-config-dir=$(python3-config --configdir) \
    # --enable-fontset \
    # --enable-largefile \
    # --enable-fail-if-missing \
    # --prefix=$(echo -e $HOME)/.local/

# ${CHOST}

./configure \
    --build=${CHOST/-msys/-cygwin} \
    --with-features=huge \
    --enable-cscope \
    --enable-multibyte \
    --enable-luainterp=dynamic \
    --enable-perlinterp=dynamic \
    --enable-pythoninterp=no \
    --enable-python3interp=yes \
    --enable-rubyinterp=dynamic \
    --disable-netbeans \
    --disable-canberra \
    --disable-libsodium \
    --disable-nls \
    --disable-arabic \
    --disable-rightleft \
    --disable-darwin \
    --disable-tclinterp \
    --disable-gpm \
    --disable-sysmouse \
    --disable-gui \
    --without-x \
    --enable-fontset \
    --enable-terminal \
    --enable-largefile \
    --prefix=$(echo -e $HOME)/.local