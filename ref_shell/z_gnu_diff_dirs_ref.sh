#!/bin/bash

##
## https://blog.csdn.net/rush3/article/details/82844830
##


if [ $# -ne 2 ];then
    echo "Usage:$0 dir1 dir2"
    exit 1
fi

if [ ! -d "$1" -o ! -d "$2" ];then
    echo "$1 or $2 is not derectory!"
    exit 1
fi

##
## Note: Mac的readlink程序和GNU readlink功能不同, Mac需要下載greadlink
##
arg1=`readlink -f "$1"`
arg2=`readlink -f "$2"`

tmp_dir=$PREFIX/tmp/tmp.$$
rm -rf $tmp_dir
mkdir -p $tmp_dir || exit 0
#echo $tmp_dir

trap "rm -rf $tmp_dir; exit 0" SIGINT SIGTERM

##
## Note: Mac和Linux的MD5程序不同, 請根據需求使用, 這裡是Mac版的用法
##
function get_file_md5
{
    if [ $# -ne 1 ];then
        echo "get_file_md5 arg num error!"
        return 1
    fi
    local file=$1
    md5sum $file | awk -F" " '{print $1}'
}

function myexit
{
    rm -rf $tmp_dir
    exit 0
}

function show_diff
{
    if [ $# -ne 1 ];then
        return 1
    fi

    local diff_file=$1
    echo "diff file:"
    printf " %-55s %-52s\n" "$arg1" "$arg2"

    if [ -f $tmp_dir/A_only_file ];then
        awk '{printf(" [%2d] %-50s\n", NR, $0)}' $tmp_dir/A_only_file
        python -c 'print("-"*100)'
    fi

    if [ -f $tmp_dir/B_only_file ];then
        awk '{for(i=0;i<60;i++)printf(" "); printf(" [%2d] %-50s\n",NR, $0)}' $tmp_dir/B_only_file
        python -c 'print("-"*100)'
    fi

    if [ -f $diff_file ];then
        awk '{printf(" [%2d] %-50s %-50s\n", NR, $0, $0)}' $diff_file
        echo "(s):show diff files (a):open all diff files (q):exit"
        echo
    fi
}

function check_value
{
    local diff_file=$1
    local value=$2
    tmp_file=$tmp_dir/tmp_file
    >$tmp_file

    for numbers in `echo "$value" | tr ',' ' '`
    do
        nf=`echo "$numbers" | awk -F"-" '{print NF}'`
        if [ $nf -ne 1 -a $nf -ne 2 ];then
            return 1
        fi

        begin=`echo "$numbers" | awk -F"-" '{print $1}'`
        end=`echo "$numbers" | awk -F"-" '{print $2}'`

        if [ -z "$end" ];then
            sed -n $begin'p' $diff_file >> $tmp_file
        else
            if [ "$end" -lt $begin ];then
                return 1
            fi

            sed -n $begin','$end'p' $diff_file >> $tmp_file
        fi

        if [ $? -ne 0 ];then
            return 1
        fi
    done

    awk -v dir1="$arg1" -v dir2="$arg2" '{
        if (NR==1)
        {
            printf("edit %s/%s\nvertical diffsplit %s/%s\n", dir1, $0, dir2, $0)
        }
        else
        {
            printf("tabnew %s/%s\nvertical diffsplit %s/%s\n", dir1, $0, dir2, $0)
        }
    }' $tmp_file
}

#############################################################
# get different info
#############################################################
temp_path1=$1
temp_path2=$2

## 如果路徑最後面沒有帶"/", 都加上"/"

if [ ${1:0-1} != "/" ]; then
    temp_path1=`echo $1/`
fi

if [ ${2:0-1} != "/" ]; then
    temp_path2=`echo $2/`
fi

## 呼叫diff命令, 結果輸出到diff_out
diff -rq "$temp_path1" "$temp_path2" > $tmp_dir/diff_out

## 處理兩個檔案有不同的檔案情況
grep "^Files" $tmp_dir/diff_out | sed "s%$temp_path2%#&%" | cut -d"#" -f2 | sed "s%$temp_path2/*%%" > $tmp_dir/diff_file
grep "Binary files" $tmp_dir/diff_out | sed "s%.*$1\/*\(.*\) and .*%\1%" >> $tmp_dir/diff_file
sed -i 's/ differ$//' $tmp_dir/diff_file

## 判斷檔案是否為空
# if [ ! -s $tmp_dir/diff_file ];then
#     rm -rf $tmp_dir/diff_file
# fi


##
## handle left folder only files
##
grep "Only in $temp_path1" $tmp_dir/diff_out |cut -d" " -f3- | sed 's%: %/%' > $tmp_dir/A_only_file
sed -i "s#.*$temp_path1/*##" $tmp_dir/A_only_file
grep -w "File ${temp_path1%/*}" $tmp_dir/diff_out | sed "s%\(File ${temp_path1%/*}.*\)while.*%\1%" >> > $tmp_dir/A_only_file

##
## handle right folder only files
##
grep "Only in $temp_path2" $tmp_dir/diff_out |cut -d" " -f3- | sed 's%: %/%' > $tmp_dir/B_only_file
sed -i "s#.*$temp_path2/*##" $tmp_dir/B_only_file
grep -w "File ${temp_path1%/*}" $tmp_dir/diff_out |sed "s%.*while \(.*${temp_path2%/*}.*\)%\1%" >> $tmp_dir/B_only_file


#############################################################
# use vim to open different file
#############################################################
if [[ ! -s $tmp_dir/diff_file && ! -s $tmp_dir/A_only_file && ! -s $tmp_dir/B_only_file ]]; then
    echo folders are the same!
    myexit
fi

show_diff $tmp_dir/diff_file
while true
do
    if [ -s $tmp_dir/diff_file ];then
        echo -n "Please choose file number list (like this:1,3-4,5):"
    else
        echo "No diff files,enter 'q' to exit!"
        echo -n ":"
    fi

    read value
    if [[ "$value" = "s" ]] || [[ "$value" = "S" ]];then
        show_diff $tmp_dir/diff_file
        continue
    elif [[ "$value" = "q" ]] || [[ "$value" = "Q" ]];then
        myexit
    elif [[ "$value" = "a" ]] || [ "$value" = "A" ];then
        value="1-$"
    fi

    vim_script=`check_value $tmp_dir/diff_file "$value" 2>/dev/null`
    if [ $? -ne 0 ];then
        echo "invalid parameter[$value]!"
    else
        vim -c "$vim_script"
    fi
done

