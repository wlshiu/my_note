#!/bin/bash

help()
{
    echo -e "usage: $0 [options]\n"
    echo -e "Options:"
    echo -e "  -t |--target, Target devic kernel/uboot"
    echo -e "  -i |--img, elf file"
    echo -e "  -s |--srctree, source directory"
    echo -e "  -c |--cgdb, Use cgdb frontend"
    exit -1;
}

if [ -z "$1" ]; then
    help
fi


target=''
img_elf=''
src_tree=''
gdb_frontend=''
extra_opt=""

while [ ! -z "$1" ]; do
    case "$1" in
        --target|-t)
            shift
            target=$1
            ;;
        --img|-i)
            shift
            img_elf=$1
            ;;
        --srctree|-s)
            shift
            src_tree=$1
            ;;
        --cgdb|-c)
            gdb_frontend='cgdb'
            ;;
        *)
            help
            ;;
    esac

    shift
done

echo "" > .bp

if [ "$target" = "kernel" ]; then
    echo -e "$Yellow GDB kernel ... $NC"

    ### break at ASM code enter
    # echo "b stext" >> .bp

    ### break at C code enter
    echo "b start_kernel" >> .bp

    ### jump to enter pointer of kernel
    # echo "jump stext" >> .bp

elif [ "$target" = "uboot" ]; then
    echo -e "$Yellow GDB U-boot ... $NC"

    ### break at C code enter
    echo "b _start" >> .bp
fi

if [ "$gdb_frontend" = "cgdb" ]; then
    cgdb -d arm-none-eabi-gdb --directory=$src_tree -ex 'target remote:1234' -ex 'source ./.bp' $img_elf
else
    arm-none-eabi-gdb --directory=$src_tree -ex 'target remote:1234' -ex 'source ./.bp' $img_elf -tui

    ### gdb with python
    # arm-none-eabi-gdb-py --directory=$src_tree ${extra_opt} $img_elf # -tui
fi

rm -f ./.bp
