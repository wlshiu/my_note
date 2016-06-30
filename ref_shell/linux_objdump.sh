#!/bin/bash

function help()
{
    echo "usage: linux_objdump [root_dir] [pattern] [out_path]"
    echo "       e.g. linux_objdump ./ \"memset\" ./result "
    exit 1
}

if [ $# != 3 ];then
    help
fi

work_dir=$1

${work_dir}/host/opt/ext-toolchain/bin/aarch64-linux-gnu-objdump -S ${work_dir}/build/linux-custom/vmlinux | grep -A 20 -e $2 > $3

## option
# -a
# --archive-headers
#     顯示檔案庫的成員信息,類似ls -l將lib*.a的信息列出。
# -b bfdname
# --target=bfdname
#     指定目標碼格式。這不是必須的，objdump能自動識別許多格式，
#     比如： objdump -b oasys -m vax -h fu.o 顯示fu.o的頭部摘要信息，明確指出該文件是Vax系統下用Oasys編譯器生成的目標文件。
#     objdump -i將給出這裡可以指定的目標碼格式列表。
# -C --demangle
#     將底層的符號名解碼成用戶級名字，除了去掉所開頭的下劃線之外，還使得C++函數名以可理解的方式顯示出來。
#
# -g
# --debugging  顯示調試信息。企圖解析保存在文件中的調試信息並以C語言的語法顯示出來。僅僅支持某些類型的調試信息。有些其他的格式被readelf -w支持。
#
# -e
# --debugging-tags
#     類似-g選項，但是生成的信息是和ctags工具相兼容的格式。
#
# -d
# --disassemble
#     從objfile中反彙編那些特定指令機器碼的section。
#
# -D
# --disassemble-all
#     與 -d 類似，但反彙編所有section.
#
# --prefix-addresses
#     反彙編的時候，顯示每一行的完整地址。這是一種比較老的反彙編格式。
#
# -EB/-EL
# --endian={big|little}
#     指定目標文件的小端。這個項將影響反彙編出來的指令。在反彙編的文件沒描述小端信息的時候用。
#     例如S-records. -f --file-headers 顯示objfile中每個文件的整體頭部摘要信息。
#
# -h
# --section-headers
# --headers
#     顯示目標文件各個section的頭部摘要信息。
#
# -H
# --help
#     簡短的幫助信息。
#
# -i
# --info
#     顯示對於 -b 或者 -m 選項可用的架構和目標格式列表。
#
# -j name
# --section=name
#     僅僅顯示指定名稱為name的section的信息
#
# -l
# --line-numbers
#     用文件名和行號標註相應的目標代碼，僅僅和-d、-D或者-r一起使用使用-ld和使用-d的區別不是很大，
#     在源碼級調試的時候有用，要求編譯時使用了-g之類的調試編譯選項。
#
# -m machine
# --architecture=machine
#     指定反彙編目標文件時使用的架構，當待反彙編文件本身沒描述架構信息的時候(比如S-records)，這個選項很有用。
#     可以用-i選項列出這裡能夠指定的架構.
#
# -r
# --reloc
#     顯示文件的重定位入口。如果和-d或者-D一起使用，重定位部分以反彙編後的格式顯示出來。
#
# -R
# --dynamic-reloc
#     顯示文件的動態重定位入口，僅僅對於動態目標文件意義，比如某些共享庫。
#
# -s
# --full-contents
#     顯示指定section的完整內容。默認所有的非空section都會被顯示。
#
# -S
# --source
#     儘可能反彙編出源代碼，尤其當編譯的時候指定了-g這種調試參數時，效果比較明顯。隱含了-d參數。
#
# --show-raw-insn
#     反彙編的時候，顯示每條彙編指令對應的機器碼，如不指定--prefix-addresses，這將是缺省選項。
#
# --no-show-raw-insn
#     反彙編時，不顯示彙編指令的機器碼，如不指定--prefix-addresses，這將是缺省選項。
#
# --start-address=address
#     從指定地址開始顯示數據，該選項影響-d、-r和-s選項的輸出。
#
# --stop-address=address
#     顯示數據直到指定地址為止，該項影響-d、-r和-s選項的輸出。
#
# -t
# --syms
#     顯示文件的符號表入口。類似於nm -s提供的信息
#
# -T
# --dynamic-syms
#     顯示文件的動態符號表入口，僅僅對動態目標文件意義，比如某些共享庫。它顯示的信息類似於 nm -D|--dynamic 顯示的信息。
#
# -V
# --version
#     版本信息
#
# -x
# --all-headers
#     顯示所可用的頭信息，包括符號表、重定位入口。-x 等價於-a -f -h -r -t 同時指定。
#
# -z
# --disassemble-zeroes
#     一般反彙編輸出將省略大塊的零，該選項使得這些零塊也被反彙編。

