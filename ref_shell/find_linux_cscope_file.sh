#!bin/sh

# LNX=~/linux-3.18.14
MINGW=F:/_portable/MinGW
LNX=$MINGW/msys/1.0/home/redegg/linux-3.18.14

cd /
find -L $LNX                            \
-path "$LNX/arch/arm*" -o             \
-path "$LNX/include/asm-*" -o         \
-path "$LNX/tmp*" -prune -o           \
-path "$LNX/Documentation*" -prune -o \
-path "$LNX/scripts*" -prune -o       \
-path "$LNX/drivers*" -prune -o       \
-path "$LNX/tool*" -prune -o          \
-path "$LNX/sound*" -prune -o         \
-path "$LNX/lib*" -prune -o           \
-name "*.[ch]" > $LNX/cscope.files
