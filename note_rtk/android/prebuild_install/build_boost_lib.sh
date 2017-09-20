#!/bin/bash

set -e

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
Cyan='\e[0;36m'
NC='\e[0m'


boost_ver=boost_1_57_0


boost_dir=$1
boost_prefix=$2
toolchain_path=${TARGET_TOOLS_PREFIX}
root_path=`pwd`


# echo -e "${Yellow}toolchain_path=${toolchain_path}\n${NC}"
# echo -e "${Green}boost_prefix=${boost_prefix}\n${NC}"
# echo -e "${Green}root_path=${root_path}\n${NC}"
# echo -e "Extract ${boost_ver}...\n"
# echo -e " \n"

if [ -e ${root_path}/${boost_dir}/bin/lib/libboost_atomic.so ]; then
    echo -e "${Green} libs exist and skip ...\n${NC} "
    exit 0;
fi

if [ -d ${root_path}/${boost_dir}/${boost_ver} ]; then
    rm -fr ${root_path}/${boost_dir}/${boost_ver}
fi

tar -xJ -f ${root_path}/${boost_dir}/${boost_ver}.tar.xz -C ${root_path}/${boost_dir}


# echo -e "${Yellow}cd ${boost_dir}/${boost_ver}\n${NC}"
cd ${root_path}/${boost_dir}/${boost_ver}

echo -e "using gcc : arm : ccache ${root_path}/${toolchain_path}g++ ;" > ~/user-config.jam

if [ ! -d ${root_path}/${boost_dir}/bin ]; then
    mkdir ${root_path}/${boost_dir}/bin
fi

./bootstrap.sh --without-libraries=python,context,coroutine --prefix=${root_path}/${boost_dir}/bin > boost_build.log 2>&1

./bjam clean && ./bjam toolset=gcc-arm link=shared runtime-link=shared -sNO_BZIP2=1 -j8 install >> boost_build.log 2>&1
# ./bjam clean && ./bjam toolset=gcc-arm cxxflags="-std=c++11 -frtti" link=shared runtime-link=shared -sNO_BZIP2=1 -j8 install >> boost_build.log 2>&1

