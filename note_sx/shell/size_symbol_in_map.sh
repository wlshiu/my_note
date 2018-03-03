## _free_run.sh
#!/bin/bash
# set -e


#!/bin/sh

region_array=(
__ddr_region0_ro_start
__ddr_region0_ro_end
__ddr_region1_ro_start
__ddr_region1_ro_end
__ddr_region2_ro_start
__ddr_region2_ro_end
__ddr_region3_ro_start
__ddr_region3_ro_end
__ddr_region4_ro_start
__ddr_region4_ro_end
__ddr_region5_ro_start
__ddr_region5_ro_end
)

symbol_array=(

)

function help()
{
    echo "usage: $0 [input] [region0 ~ region5] '[start_symbol_name]' '[end_symbol_name]'"
    echo "       e.g. $0 reorder.map region0 '\*foo.o*(.text* )' '^\s*(.rodata*)'"
    exit 1
}

if [ $# == 0 ];then
    help
fi

# set -e

region_start_tag=__ddr_${2}_ro_start
region_end_tag=__ddr_${2}_ro_end


F=${1}
S=`grep -n ${region_start_tag} ${F} | awk -F ":" '{print $1}'`
E=`grep -n ${region_end_tag} ${F} | awk -F ":" '{print $1}'`

one_region_map=tmp.map

sed -n ${S},${E}p ${F} > ${one_region_map}

name_symbol_start=${3}
name_symbol_end=${4}
# echo -e "\n" ${name_symbol_start}
# echo -e "\n" "-"${name_symbol_end}"-"

symbol_start=`echo ${name_symbol_start} | sed 's/\*/\\\*/g' | sed 's/\./\\\./g' | sed 's/\ //g'`
symbol_end=`echo ${name_symbol_end} | sed 's/\*/\\\*/g' | sed 's/\./\\\./g' | sed 's/\ //g'`

# echo $symbol_start
# echo -e "-"$symbol_end"-\n"

tmp_file=dump.tmp

grep -A 10 $symbol_start ${one_region_map} | sed -e :x -e 'N; s/\n/,/; tx' > ${tmp_file}
grep -A 10 $symbol_end ${one_region_map} | sed -e :x -e 'N; s/\n/,/; tx' >> ${tmp_file}

start_addr=0
while read line
do
    # addr=$(echo $line | awk '{print $3}'| xargs printf '%d')
    addr=$(echo $line | awk '{ for(i=1;i<=NF;i++){ addr=match($i, /0x[a-fA-F0-9]+/); if(addr){print $i; exit} } }'| xargs printf '%d')
    if [ $? != 0 ]; then
        echo -e ${2}"\t" "N/A" "\t" ${name_symbol_start} "~" ${name_symbol_end}
        break
    fi

    # echo $addr
    if [ $start_addr -ne 0 ]; then
        echo -e ${2}"\t" $[$addr - $start_addr]"\t" ${name_symbol_start}"("$start_addr")" "~" ${name_symbol_end}"("$addr")"
    fi
    start_addr=`expr $addr`
done < ${tmp_file}

rm -f ${one_region_map}
rm -f ${tmp_file}


