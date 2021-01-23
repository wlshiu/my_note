
# sh build_gdbserver.sh --help
Command: build_gdbserver.sh --help

==== must argument ====
--use-toolchain-dir=      specify a path to dir of toolchains. (EX: /home/coder/nds32le-linux)
--src-dir=                specify a path to dir of source code. (EX: /home/coder/src/gdb)
--src-file=               specify a path to file of source code. (EX: PWD/gdbserver-src.tar.gz)
--tmp-dir=                specify a path to temporary directory. (Default: PWD/tmp)

==== choose argument ====
--date=                   if you want to rebuild by date. (EX: 2008-11-11)
--build-dir=              specify a path to dir of build location. (Default: PWD/build-gdbserver)
--clean-all               clean all (remove build folder)


build_example.sh:
#!/bin/sh
sh -x ./build_gdbserver.sh \
--src-file=`pwd`/gdbserver.tgz \
--use-toolchain-dir=/home/coder/BSPv320/toolchains/nds32le-linux-glibc-v3

ls install/
gdbserver-nds32le-linux-glibc-v3-2013-08-31
static-gdbserver-nds32le-linux-glibc-v3-2013-08-31


#!/bin/sh
sh -x ./build_gdbserver.sh \
--src-dir=`pwd`/gdb-7.3 \
--use-toolchain-dir=/home/coder/BSPv320/toolchains/nds32le-linux-glibc-v3

