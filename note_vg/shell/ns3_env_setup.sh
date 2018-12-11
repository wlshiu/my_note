#!/bin/bash

################
# ubuntu 14.04 environment
# setup NS-3 (Network Simulation) environment

set -e

## minimal requirements for Python (release):
## This is the minimal set of packages needed to work with Python bindings from a released tarball.
sudo apt-get -y install gcc g++ python python-dev

################
## Note: Ubuntu 14.04 LTS release requires upgrade to gcc-4.9 from default gcc-4.8.
## More recent Ubuntu versions are OK.
## install add-apt-repository
sudo apt-get -y install software-properties-common

sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt-get update

## install gcc versions
sudo apt-get -y install gcc-4.9 g++-4.9
# sudo apt-get -y install gcc-5 g++-5

## set default version link
## usage:
##  update-alternatives --install <link> <name> <path> <priority>
##                         [--slave <link> <name> <path>]
##
##

# sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 48 \
#     --slave /usr/bin/g++ g++ /usr/bin/g++-4.8 \
#     --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-4.8 \
#     --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-4.8 \
#     --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-4.8

sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 49 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-4.9 \
    --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-4.9 \
    --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-4.9 \
    --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-4.9

# sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 53 \
#     --slave /usr/bin/g++ g++ /usr/bin/g++-5 \
#     --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-5 \
#     --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-5 \
#     --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-5

################
## minimal requirements for Python (development): For use of ns-3-allinone repository (cloned from Mercurial),
## additional packages are needed to fetch and successfully install pybindgen:
sudo apt-get -y install mercurial python-setuptools git

################
## Netanim animator: qt5 development tools are needed for Netanim animator;
## qt4 will also work but we have migrated to qt5
sudo apt-get -y install qt5-default

################
## Support for ns-3-pyviz visualizer
## For ns-3.28 and earlier, PyViz is based on GTK+ 2, GooCanvas, and GraphViz:
sudo apt-get -y install python-pygraphviz python-kiwi python-pygoocanvas libgoocanvas-dev ipython

################
## For Ubuntu 18.04, python-pygoocanvas is no longer provided.
## The ns-3.29 release and later upgrades the support to GTK+ version 3, and requires these packages:
sudo apt-get -y install gir1.2-goocanvas-2.0 python-gi python-gi-cairo python-pygraphviz gir1.2-gtk-3.0 ipython
sudo apt-get -y install python3-gi python3-gi-cairo ipython3
## python3-pygraphviz
sudo apt-get -y install python3-pip
sudo pip3 install graphviz

################
## Support for MPI-based distributed emulation
sudo apt-get -y install openmpi-bin openmpi-common openmpi-doc libopenmpi-dev

################
## Support for bake build tool:
sudo apt-get -y install autoconf cvs bzr unrar

################
## Debugging:
sudo apt-get -y install gdb valgrind

################
## Support for utils/check-style.py code style check program
sudo apt-get -y install uncrustify

################
## Doxygen and related inline documentation:
sudo apt-get -y install doxygen graphviz imagemagick
sudo apt-get -y install texlive texlive-extra-utils texlive-latex-extra texlive-font-utils texlive-lang-portuguese dvipng latexmk

################
## The ns-3 manual and tutorial are written in reStructuredText for Sphinx (doc/tutorial, doc/manual, doc/models),
## and figures typically in dia (also needs the texlive packages above):
sudo apt-get -y install python-sphinx dia
## Note: Sphinx version >= 1.12 required for ns-3.15. To check your version, type "sphinx-build".
## To fetch this package alone, outside of the Ubuntu package system, try "sudo easy_install -U Sphinx".

################
## GNU Scientific Library (GSL) support for more accurate WiFi error models
sudo apt-get -y install gsl-bin
# sudo apt-get -y install libgsl2 libgsl-dev

################
## The Network Simulation Cradle (nsc) requires the flex lexical analyzer and bison parser generator:
sudo apt-get -y install flex bison libfl-dev

################
## To read pcap packet traces
sudo apt-get -y install tcpdump

################
## Database support for statistics framework
sudo apt-get -y install sqlite sqlite3 libsqlite3-dev

################
## Xml-based version of the config store (requires libxml2 >= version 2.7)
sudo apt-get -y install libxml2 libxml2-dev

################
## Support for generating modified python bindings
sudo apt-get -y install cmake libc6-dev libc6-dev-i386 libclang-dev llvm-dev automake
sudo apt-get -y install python-pip build-essential
sudo pip install --upgrade pip
sudo pip install --upgrade virtualenv
sudo pip install cxxfilt

## and you will want to install castxml and pygccxml as per the instructions for python bindings
## (or through the bake build tool as described in the tutorial).
## The 'castxml' package provided by Ubuntu 18.04 and earlier is not recommended;
## a source build (coordinated via bake) is recommended.

## Note: Ubuntu 16.04 and systems based on it (e.g. Linux Mint 18) default to an old version of llvm (3.8).
## Users of Ubuntu 16.04 will want to explicitly install a newer version by specifying 'libclang-6.0-dev' and 'llvm-6.0-dev'.

################
## A GTK-based configuration system
sudo apt-get -y install libgtk2.0-0 libgtk2.0-dev

################
## To experiment with virtual machines and ns-3
sudo apt-get -y install vtun lxc

################
## Support for openflow module (requires some boost libraries)
sudo apt-get -y install libboost-signals-dev libboost-filesystem-dev








# sudo apt-get install gcc g++ Python
# sudo apt-get install mercurial
# sudo apt-get install bzr
# sudo apt-get install gdb valgrind
# sudo apt-get install gsl-bin libgsl0-dev libgsl0ldbl
# sudo apt-get install flex bison
# sudo apt-get install g++-3.4 gcc-3.4
# sudo apt-get install tcpdump
# sudo apt-get install sqlite sqlite3 libsqlite3-dev
# sudo apt-get install libxml2 libxml2-dev
# sudo apt-get install libgtk2.0-0 libgtk2.0-dev
# sudo apt-get install vtun lxc
# sudo apt-get install uncrustify
# sudo apt-get install doxygen graphviz imagemagick
# sudo apt-get install texlive texlive-pdf texlive-latex-extra texlive-generic-extra texlive-generic-recommended
# sudo apt-get install texinfo dia texlive texlive-pdf texlive-latex-extra texlive-extra-utils texlive-generic-recommended
# sudo apt-get install python-pygraphviz python-kiwi python-pygoocanvas libgoocanvas-dev
# sudo apt-get install libboost-signal-dev libboost-filesystem-dev

