#!/bin/bash

set -e

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
NC='\e[0m'

help()
{
    echo -e "${Yellow}usage: $0 [ns3 sourece path] ${NC}"
    exit 0
}

if [ $# != 1 ]; then
    help
fi

echo -e "${Yellow} Use version ns-allinone-3.29 ${NC}"

cd $1

is_waf_build=1

if [ ${is_waf_build} == 1 ]; then
    my_build_profile=debug
    # my_build_profile=optimized

    cd ns-3.29

    ./waf clean
    ./waf configure --enable-sudo --build-profile=${my_build_profile} --enable-examples --enable-test --out=build/${my_build_profile}

    ## self test
    ./test.py -c core

    ## run app
    ./waf --run hello-simulator

else
    ./build.py --enable-examples --enable-tests
fi


