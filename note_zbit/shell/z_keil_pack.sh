#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
BLUE='\e[0;34m'
MAGENTA='\e[0;35m'
CYAN='\e[0;36m'
WHITE='\e[0;37m'
NC='\e[0m' # No Color

SUCCESS=0

help()
{
    echo -e "usage: $0 <sdk path>"
    exit -1
}

mkcp()
{
    test -d "$2" || mkdir -p "$2"
    cp -fr "$1" "$2"
}

if [ $# != 1 ]; then
    help
fi

cur_path=$(pwd)

cd $1

git clean -fxd

if [[ -d "./pack" ]]; then
    rm -fr ./pack
fi

mkdir pack


cp -fr ./Common             ./pack/
cp -fr ./Docs               ./pack/
cp -fr ./Drivers            ./pack/
cp -fr ./Examples           ./pack/
cp -fr ./Flash/             ./pack
cp -fr ./SVD                ./pack/
cp -fr ./Tools/             ./pack/
cp -fr ./README.md              ./pack/
cp -fr ./<vendor>.<name>.pdsc   ./pack/

cd pack

pdsc_file=$(find . -type f -maxdepth 1 -name '*.pdsc')
echo -e ${pdsc_file}

if [ -z ${pdsc_file} ]; then
    echo -e "$RED No pdsc file $NC"
    cd ${cur_path}
    exit -1
fi

out_pack_name=''

PackChk.exe ${pdsc_file} -n MyPackName.txt

if [ "$?" -ne $SUCCESS ]; then
    echo "PackChk fail !!"
    exit 1
fi

out_pack_name=$(cat MyPackName.txt)

rm -f MyPackName.txt
echo -e "$out_pack_name"

7z a ${out_pack_name} -tzip

mv ./*pack ../
rm -fr pack

cd ${cur_path}
echo -e "$GREEN Done~~ $NC"
