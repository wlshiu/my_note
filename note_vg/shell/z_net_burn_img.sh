#!/bin/bash

RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
BLUE='\e[0;34m'
MAGENTA='\e[0;35m'
CYAN='\e[0;36m'
WHITE='\e[0;37m'
NC='\e[0m' # No Color

set -e

if ps | grep -q 'socat'; then
    ps | grep 'socat' | awk -F' ' '{ print $1; }' | xargs kill
    # ps aux | grep 'socat' | grep -v 'grep' | awk '{print $2}' | xargs kill -9
fi


help()
{
    echo -e "${YELLOW}usage: $0 [elf-img-name] [tftp file root] [tftp server IP] [waiting seconds] ${NC}"
    echo -e "    e.g. $0 upgrade.elf $HOME/tftpboot/ 192.168.56.3 5"
    exit 1;
}

if [ $# != 4 ]; then
    help
fi

elf_file=$1
pkg_file=${elf_file}.pkg
tftp_root_dir=$2
tftp_ip=$3
monitor_sec=$4
packet_bin='__nbrn.pkt'
return_port=8888


speed_opt="--speed 115200"

input_argv="${input_argv} --log 0"
input_argv="${input_argv} --timeout 4"
input_argv="${input_argv} ${speed_opt}"

./out/bin/MemProber ${input_argv} burn -n ./$elf_file ./$pkg_file

echo -e "${GREEN}mv $pkg_file to $tftp_root_dir ${NC}"
mv -f ./$pkg_file $tftp_root_dir

resp_packet=rx.bin

pack_fmt_discovery="4sHH128s"
pack_fmt_burn_fw="4sHHI128sII"
pack_fmt_ack="4sIIBBBBBB"
remote_node_max_num=2048
out_list_tmp='__remote_list'
out_list='remote_node.lst'

cat > packet_generator.py << EOF
#!/usr/bin/env python
import sys
import struct
import socket
from array import *
import argparse
Crc32_table = [0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F, 0xE963A535, 0x9E6495A3,
               0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988, 0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91,
               0x1DB71064, 0x6AB020F2, 0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7,
               0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC, 0x14015C4F, 0x63066CD9, 0xFA0F3D63, 0x8D080DF5,
               0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172, 0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B,
               0x35B5A8FA, 0x42B2986C, 0xDBBBC9D6, 0xACBCF940, 0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59,
               0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116, 0x21B4F4B5, 0x56B3C423, 0xCFBA9599, 0xB8BDA50F,
               0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924, 0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D,
               0x76DC4190, 0x01DB7106, 0x98D220BC, 0xEFD5102A, 0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433,
               0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818, 0x7F6A0DBB, 0x086D3D2D, 0x91646C97, 0xE6635C01,
               0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E, 0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457,
               0x65B0D9C6, 0x12B7E950, 0x8BBEB8EA, 0xFCB9887C, 0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65,
               0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2, 0x4ADFA541, 0x3DD895D7, 0xA4D1C46D, 0xD3D6F4FB,
               0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0, 0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9,
               0x5005713C, 0x270241AA, 0xBE0B1010, 0xC90C2086, 0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F,
               0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4, 0x59B33D17, 0x2EB40D81, 0xB7BD5C3B, 0xC0BA6CAD,
               0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A, 0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683,
               0xE3630B12, 0x94643B84, 0x0D6D6A3E, 0x7A6A5AA8, 0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1,
               0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE, 0xF762575D, 0x806567CB, 0x196C3671, 0x6E6B06E7,
               0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC, 0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5,
               0xD6D6A3E8, 0xA1D1937E, 0x38D8C2C4, 0x4FDFF252, 0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
               0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60, 0xDF60EFC3, 0xA867DF55, 0x316E8EEF, 0x4669BE79,
               0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236, 0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F,
               0xC5BA3BBE, 0xB2BD0B28, 0x2BB45A92, 0x5CB36A04, 0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D,
               0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A, 0x9C0906A9, 0xEB0E363F, 0x72076785, 0x05005713,
               0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38, 0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21,
               0x86D3D2D4, 0xF1D4E242, 0x68DDB3F8, 0x1FDA836E, 0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777,
               0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C, 0x8F659EFF, 0xF862AE69, 0x616BFFD3, 0x166CCF45,
               0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2, 0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB,
               0xAED16A4A, 0xD9D65ADC, 0x40DF0B66, 0x37D83BF0, 0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9,
               0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6, 0xBAD03605, 0xCDD70693, 0x54DE5729, 0x23D967BF,
               0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94, 0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D]
arg_parser = argparse.ArgumentParser()
arg_parser.add_argument("packet_type", help="packet type: discovery, burn", type = str)
args = arg_parser.parse_args()
out_file = open('${packet_bin}', 'w+b')
if args.packet_type == 'discovery':
    uid = 'dvry'
    msg_len = struct.calcsize("${pack_fmt_discovery}")
    port = ${return_port}
    meta='HeyMan'
    a = struct.pack("${pack_fmt_discovery}", uid, msg_len, port, meta)
elif args.packet_type == 'burn':
    uid = 'nbrn'
    msg_len = struct.calcsize("${pack_fmt_burn_fw}")
    reboot_sec = 1
    fw_name = '$pkg_file'
    tftp_svr_ip = '$tftp_ip'
    port = ${return_port}
    tartget_dest = 0xFFFFFFFF
    a = struct.pack("${pack_fmt_burn_fw}", uid, msg_len, port, reboot_sec, fw_name, socket.htonl(int(socket.inet_aton(tftp_svr_ip).encode('hex'), 16)), tartget_dest)
out_file.write(a)
out_file.close()
crc32 = 0xFFFFFFFF
f = open('${packet_bin}', 'rb')
buf = f.read()
f.close()
for c in buf:
    crc32 = ((crc32 >> 8) & 0x00FFFFFF) ^ Crc32_table[(crc32 ^ ord(c)) & 0xFF]
# crc32 = hex(crc32 ^ 0xffffffff)
crc32 = crc32 ^ 0xffffffff
print '\ncrc32= 0x%x' % int(crc32)
a = struct.pack("I", int(crc32))
out_file = open('${packet_bin}', 'ab')
out_file.write(a)
out_file.close()
EOF

cat > resp_daemon.sh << EOF
#!/bin/bash
#PIDFILE=/var/run/socat-${return_port}.pid
PIDFILE=./socat-${return_port}.pid
if [ "\$1" = "start" -o -z "\$1" ]; then
    socat -u udp4-listen:${return_port} open:${resp_packet},create,append </dev/null &
    echo \$! >\$PIDFILE

elif [ "\$1" = "stop" ]; then
    kill \$(/bin/cat \$PIDFILE)
    # ps all | grep 'socat -u udp4-listen' | awk '{print $3}' | xargs kill
fi
EOF

cat > resp_parse.py << EOF
#!/usr/bin/env python
import sys
import struct
import socket
# from array import *
import argparse
class colors: # You may need to change color settings in iPython
    RED = '\033[31m'
    ENDC = '\033[m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'

arg_parser = argparse.ArgumentParser()
arg_parser.add_argument("packet_type", help="packet type: discovery, burn", type = str)
args = arg_parser.parse_args()
fin = open('${resp_packet}', 'rb')

output_node_list = '${out_list}'
pos = output_node_list.index('.')
has_filter = 1
if args.packet_type == 'discovery':
    print colors.YELLOW + '\n### discovery list' + colors.ENDC
    output_node_list = output_node_list[:pos] + '_dvry' + output_node_list[pos:]
    has_filter = 0
elif args.packet_type == 'burn':
    print colors.YELLOW + '\n@@@ remote report state (list fail nodes)' + colors.ENDC
    output_node_list = output_node_list[:pos] + '_nbrn' + output_node_list[pos:]

fout = open('${out_list_tmp}', 'w')
while True:
    pkt = fin.read(struct.calcsize("${pack_fmt_ack}"))
    if not pkt:
        break

    tag, id, result, mac0, mac1, mac2, mac3, mac4, mac5 = struct.unpack("${pack_fmt_ack}", pkt)

    if (args.packet_type == 'discovery') and (tag != 'dvry')  :
        break
    elif (args.packet_type == 'burn') and (tag != 'fnsh'):
        break

    out_str = '%s|%s|%s|%02x:%02x:%02x:%02x:%02x:%02x' % (tag, hex(id), hex(result), mac0, mac1, mac2, mac3, mac4, mac5)
    out_str += '\n'
    fout.write(out_str)

fout.close()
fin.close()

remote_device_list = [" "]*${remote_node_max_num}
index = 0

fout = open(output_node_list, 'w')

out_str = 'No. |     id     |   state    | MAC\n----+------------+------------+---------'
print out_str
out_str += '\n'
fout.write(out_str)

for line in open('${out_list_tmp}'):
    i = 0
    is_exist = 0
    uid = line.split("|")[1]
    rst = line.split("|")[2]
    mac = line.split("|")[3].split('\n')[0]

    for i in range(index):
        if uid in remote_device_list[i]:
            is_exist = 1
            break

    if (is_exist == 1):
        continue
    if (has_filter == 1) and (rst == '0x0'):
        continue

    remote_device_list[index] = '%10s | %10s | %s' % (uid, rst, mac)
    out_str = '%03d | %s' % (index + 1, remote_device_list[index])
    print out_str
    out_str += '\n'
    fout.write(out_str)
    index = index + 1

print '\n\n'
EOF

chmod +x packet_generator.py
chmod +x resp_daemon.sh
chmod +x resp_parse.py


if [ -f ${resp_packet} ]; then
    rm -f ${resp_packet}
fi

resp_daemon.sh start

## send discovery request
./packet_generator.py discovery
sudo socat -u open:${packet_bin} udp4-datagram:255.255.255.255:9999,broadcast

sleep 0.5

rm -f ${packet_bin}

## waiting to receive response of discovery
echo -e "${GREEN}wait discovery response ${NC}"
prev_income=
cnt=1
sec=1
while [ $sec != ${monitor_sec} ]
do
    if [ -f ${resp_packet} ]; then
        if [ -z "${prev_income}" ]; then
            prev_income=$(ls -l "${resp_packet}")
        fi

        cur_income=$(ls -l "${resp_packet}")
        if [ "${cur_income}" !=  "${prev_income}" ] || [ ${sec} == 1 ]; then
            prev_income="${cur_income}"
            printf "\n"
            resp_parse.py discovery
        fi

        sec=$(($sec+1))

        remain_sec=$(($monitor_sec - $sec))
        printf '\r wait %d sec...' ${remain_sec}

        sleep 1
    else
        _mos=$(($cnt % 4))

        if [ $_mos == 0 ]; then
            printf "\r/"
        elif [ $_mos == 1 ]; then
            printf "\r-"
        elif [ $_mos == 2 ]; then
            printf '\r\\'
        elif [ $_mos == 3 ]; then
            printf '\r|'
        fi

        sleep 0.1
    fi

    cnt=$(($cnt+1))
done

if [ -f ${resp_packet} ]; then
    rm -f ${resp_packet}
fi

resp_daemon.sh stop
resp_daemon.sh start

## send burning request
./packet_generator.py burn
sudo socat -u open:${packet_bin} udp4-datagram:255.255.255.255:9999,broadcast

rm -f packet_generator.py
rm -f ${packet_bin}

echo -e "\n${GREEN}burn image and wait remotes response ${NC}"
echo -e "${GREEN}it will take few minutes... ${NC}"

## waiting to receive response of burning
prev_income=

cnt=1
sec=1
monitor_sec=$(($monitor_sec * 4))
while [ $sec != ${monitor_sec} ]
do
    if [ -f ${resp_packet} ]; then
        if [ -z "${prev_income}" ]; then
            prev_income=$(ls -l "${resp_packet}")
        fi

        cur_income=$(ls -l "${resp_packet}")
        if [ "${cur_income}" !=  "${prev_income}" ] || [ ${sec} == 1 ]; then
            prev_income="${cur_income}"
            printf "\n"
            resp_parse.py burn
        fi

        sec=$(($sec+1))

        remain_sec=$(($monitor_sec - $sec))
        printf '\r wait %d sec...' ${remain_sec}
        sleep 1
    else
        _mos=$(($cnt % 4))

        if [ $_mos == 0 ]; then
            printf "\r/"
        elif [ $_mos == 1 ]; then
            printf "\r-"
        elif [ $_mos == 2 ]; then
            printf '\r\\'
        elif [ $_mos == 3 ]; then
            printf '\r|'
        fi

        sleep 0.1
    fi

    cnt=$(($cnt+1))
done

resp_daemon.sh stop

if [ -f ${out_list_tmp} ]; then
    rm -f ${out_list_tmp}
fi
rm -f resp_daemon.sh
rm -f resp_parse.py
rm -f ${resp_packet}
