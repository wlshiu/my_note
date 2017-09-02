#!/bin/bash
#===============================================================================
# COPYRIGHT:Copyright (c) 2017, Wei-Lun Hsu
#
#          FILE: find_grep.sh
#
#         USAGE: ./find_grep.sh
#
#   DESCRIPTION:
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Wei-Lun Hsu (WL),
#       CREATED: 2017/09/ 2
#       LICENSE: GNU General Public License
#      REVISION:  ---
#===============================================================================

color_prefix='\e'
Red='\e[0;31m'
Yellow='\e[1;33m'
Green='\e[0;32m'
Cyan='\e[0;36m'
NC='\e[0m' # No Color


# set -o nounset                                  # Treat unset variables as an error
set -e

tag_file_ext='f'
tag_prune_dir='pd'
tag_grepword='gw'

sh_exec_file='_exec_find_grep.sh'

# replace the last ' ' => sed 's/\(.*\)\ /\1:/')

help ()
{
    echo -e "${Yellow} $0 [path_1 patch_2 ...] [-${tag_prune_dir} path_1 patch_2 ...] [-${tag_file_ext} iname_1 iname_2 ...] -${tag_grepword} [grep word]${NC}"
    echo -e "${Yellow}     -${tag_prune_dir}     -prune is find command ${NC}"
    echo -e "${Yellow}     -${tag_file_ext}      -iname is find command, only file extension ${NC}"
    echo -e "${Yellow}     -${tag_grepword}     the grep keyword ${NC}"
    echo -e "\n${Yellow}     e.g.    $0 ./ -${tag_prune_dir} ./a ./b -${tag_file_ext} sh cpp -${tag_grepword} word ${NC}"
    exit 1;
}	# ----------  end of function help  ----------


if [ $# -lt 1 ]; then
    help
fi

args_all=$*
args_dir=''
args_dir_ignore=''
grep_word=''
args_file_ext=''

case $# in
    1)
        find . -type f -exec grep --color -inH $1 {} \;
        ;;

    *)
        # replace ' -' to ':'
        args_all=$(echo -e $args_all | sed 's/\ \-/:/g')
        args_cnt=$(echo $args_all | awk -F ":" '{print NF}' | xargs printf "%d")

        i=0
        # while [ $i -lt $args_cnt ]
        for ((i=0; i < $args_cnt; i++)) ; do
                case $i in
                    0) args_tmp=$(echo -e $args_all | awk -F ":" '{print $1;}')
                        ;;
                    1) args_tmp=$(echo -e $args_all | awk -F ":" '{print $2;}')
                        ;;
                    2) args_tmp=$(echo -e $args_all | awk -F ":" '{print $3;}')
                        ;;
                    3) args_tmp=$(echo -e $args_all | awk -F ":" '{print $4;}')
                        ;;
                    # 4) args_tmp=$(echo -e $args_all | awk -F ":" '{print $5;}')
                    #     ;;
                    *)
                        help
                        exit 1;
                        break
                    ;;
                esac

            # echo $i">>"$args_tmp

            if echo $args_tmp | grep -q $tag_prune_dir; then
                if [ $args_dir_ignore ]; then
                    help
                fi

                args_dir_ignore=$(echo $args_tmp | awk '{for(i=2;i<=NF;i++){print "-ipath \""$i"\" -prune -o "; }}' | sed 's/\/\"/\"/g')
                # echo $args_dir_ignore

            elif echo $args_tmp | grep -q $tag_file_ext; then
                if [ $args_file_ext ]; then
                    help
                fi

                # args_file_ext=$(echo $args_tmp | awk '{for(i=2;i<=NF;i++){print "-iname \"*."$i"\""; if(i!=NF){print "-o"}}}')
                args_file_ext=$(echo $args_tmp | awk '{for(i=2;i<=NF;i++){printf("-iname \"*.%s\" ", $i); if(i!=NF){printf("-o ");}}}')
                # echo $args_file_ext

            elif echo $args_tmp | grep -q $tag_grepword; then
                if [ $grep_word ]; then
                    help
                fi

                grep_word=$(echo $args_tmp | sed 's/^.*\ //')
                # echo $grep_word

            else
                if [ $args_dir ]; then
                    help
                fi

                args_dir=$(echo $args_tmp)
            fi

        done


        # I have no idea why this cmd line can't work, so I just output a shell file to execute
        #===========================
        # find $args_dir $args_dir_ignore -type f $args_file_ext -exec grep --color -inH $grep_word {} \;
        #-----------------------
        (echo -e "#!/bin/bash") > _exec_find_grep.sh
        (echo -e "find " $args_dir $args_dir_ignore "-type f" $args_file_ext "| xargs grep --color -inH" $grep_word | tr -s '\r' ' ' | tr -s '\n' ' ') >> ${sh_exec_file}

        chmod +x ./${sh_exec_file}
        bash ./${sh_exec_file}

        rm -f ${sh_exec_file}
        #-----------------------
        ;;

esac    # --- end of case ---

