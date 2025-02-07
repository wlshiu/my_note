#!/bin/bash

help()
{
    echo "usage: $0 <-bx> <0/1>"
    echo "  <-bx>   bit[x], x = 11 ~ 0"
    echo "  e.g. $0 -b11 0 -b10 1 ... -b1 1 -b0 1"
    exit -1;
}

bit_00=0
bit_01=0
bit_02=0
bit_03=0
bit_04=0
bit_05=0
bit_06=0
bit_07=0
bit_08=0
bit_09=0
bit_10=0
bit_11=0

while [[ "$1" != "" ]]; do
    case $1 in
        -b0)
            echo "bit 0  = $2"
            bit_00=$(($2 << 0))
            shift
            ;;
        -b1)
            echo "bit 1  = $2"
            bit_01=$(($2 << 1))
            shift
            ;;
        -b2)
            echo "bit 2  = $2"
            bit_02=$(($2 << 2))
            shift
            ;;
        -b3)
            echo "bit 3  = $2"
            bit_03=$(($2 << 3))
            shift
            ;;
        -b4)
            echo "bit 4  = $2"
            bit_04=$(($2 << 4))
            shift
            ;;
        -b5)
            echo "bit 5  = $2"
            bit_05=$(($2 << 5))
            shift
            ;;
        -b6)
            echo "bit 6  = $2"
            bit_06=$(($2 << 6))
            shift
            ;;
        -b7)
            echo "bit 7  = $2"
            bit_07=$(($2 << 7))
            shift
            ;;
        -b8)
            echo "bit 8  = $2"
            bit_08=$(($2 << 8))
            shift
            ;;
        -b9)
            echo "bit 9  = $2"
            bit_09=$(($2 << 9))
            shift
            ;;
        -b10)
            echo "bit 10 = $2"
            bit_10=$(($2 << 10))
            shift
            ;;
        -b11)
            echo "bit 11 = $2"
            bit_11=$(($2 << 11))
            shift
            ;;

        *|--help|-h|\?)
            help
            exit -1;
            ;;

    esac
    shift
done

value=$((${bit_00} | ${bit_01} | ${bit_02} | ${bit_03} | \
         ${bit_04} | ${bit_05} | ${bit_06} | ${bit_07} | \
         ${bit_08} | ${bit_09} | ${bit_10} | ${bit_11}))

echo "${value}"