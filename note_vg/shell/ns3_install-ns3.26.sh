

Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
Cyan='\e[0;36m'
NC='\e[0m' # No Color


set -e

# sudo apt-get update
sudo apt-get -y install gcc g++
sudo apt-get -y install python python-dev
sudo apt-get -y install qt4-dev-tools libqt4-dev
sudo apt-get -y install mercurial
sudo apt-get -y install bzr
sudo apt-get -y install cmake libc6-dev libc6-dev-i386 g++-multilib
sudo apt-get -y install gdb valgrind
sudo apt-get -y install flex bison libfl-dev
sudo apt-get -y install tcpdump
sudo apt-get -y install sqlite sqlite3 libsqlite3-dev 
sudo apt-get -y install libxml2 libxml2-dev
sudo apt-get -y install libgtk2.0-0 libgtk2.0-dev
sudo apt-get -y install vtun lxc
sudo apt-get -y install uncrustify
sudo apt-get -y install python-sphinx dia
sudo apt-get -y install python-pygraphviz python-kiwi python-pygoocanvas libgoocanvas-dev
sudo apt-get -y install libboost-signals-dev libboost-filesystem-dev
sudo apt-get -y install openmpi-bin openmpi-common openmpi-doc libopenmpi-dev

echo -e "${Yellow}download... ${NC}"
wget https://www.nsnam.org/release/ns-allinone-3.26.tar.bz2

tar jxvf ns-allinone-3.26.tar.bz2

echo -e "${Yellow}build...${NC}"
cd ns-allinone-3.26
./build.py
cd ns-3.26

# sudo ./waf -d optimized configure
# sudo ./waf
