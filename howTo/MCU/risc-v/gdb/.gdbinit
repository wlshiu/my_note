

# __________________color functions_________________
# color codes
set $BLACK = 0
set $RED = 1
set $GREEN = 2
set $YELLOW = 3
set $BLUE = 4
set $MAGENTA = 5
set $CYAN = 6
set $WHITE = 7

set $COLOR_REGNAME = $GREEN
set $COLOR_REGVAL = $BLACK
set $COLOR_REGVAL_MODIFIED  = $RED

# __________________RV32-GPRs_________________
set $oldr_ra  = 0
set $oldr_sp  = 0
set $oldr_gp  = 0
set $oldr_tp  = 0

set $oldr_t0  = 0
set $oldr_t1  = 0
set $oldr_t2  = 0
set $oldr_t3  = 0
set $oldr_t4  = 0
set $oldr_t5  = 0
set $oldr_t6  = 0

set $oldr_a0  = 0
set $oldr_a1  = 0
set $oldr_a2  = 0
set $oldr_a3  = 0
set $oldr_a4  = 0
set $oldr_a5  = 0
set $oldr_a6  = 0
set $oldr_a7  = 0

set $oldr_s0  = 0
set $oldr_s1  = 0
set $oldr_s2  = 0
set $oldr_s3  = 0
set $oldr_s4  = 0
set $oldr_s5  = 0
set $oldr_s6  = 0
set $oldr_s7  = 0
set $oldr_s8  = 0
set $oldr_s9  = 0
set $oldr_s10 = 0
set $oldr_s11 = 0

# __________________cofigurations_________________

set confirm off
# set architecture riscv:rv32

set disassemble-next-line auto

set style address background white
set style address intensity bold

# set style sources on
# set style tui-current-position on

# show style sources
# show style tui-current-position


## configure some print formats
set print pretty on
set print array on


set prompt \033[0;33mgdb>>> \033[0m


# __________________macros_________________
define color
    # BLACK
    if $arg0 == 0
        echo \033[30m
    else
        # RED
        if $arg0 == 1
            echo \033[31m
        else
            # GREEN
            if $arg0 == 2
                echo \033[32m
            else
                # YELLOW
                if $arg0 == 3
                    echo \033[33m
                else
                    # BLUE
                    if $arg0 == 4
                        echo \033[34m
                    else
                        # MAGENTA
                        if $arg0 == 5
                            echo \033[35m
                        else
                            # CYAN
                            if $arg0 == 6
                                echo \033[36m
                            else
                                # WHITE
                                if $arg0 == 7
                                    echo \033[37m
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

define color_reset
    echo \033[0m
end

define color_bold
    echo \033[1m
   #echo \[\e[1m\]
end

define color_underline
    echo \033[4m
end


define reg_rv32
    printf "\n"
    # ra
    color $COLOR_REGNAME
    printf "ra (x1 ):"
    if ($ra != $oldr_ra)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $ra

    # sp
    color $COLOR_REGNAME
    printf "sp (x2 ):"
    if ($sp != $oldr_sp)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $sp

    # gp
    color $COLOR_REGNAME
    printf "gp (x3 ):"
    if ($gp != $oldr_gp)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $gp

    # tp
    color $COLOR_REGNAME
    printf "tp (x4 ):"
    if ($tp != $oldr_tp)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X\n", $tp

    #-------func_argv----------
    # a0 and return
    color $COLOR_REGNAME
    printf "a0 (x10):"
    if ($a0 != $oldr_a0)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $a0

    # a1 and return
    color $COLOR_REGNAME
    printf "a1 (x11):"
    if ($a1 != $oldr_a1)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $a1

    # a2
    color $COLOR_REGNAME
    printf "a2 (x12):"
    if ($a2 != $oldr_a2)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $a2

    # a3
    color $COLOR_REGNAME
    printf "a3 (x13):"
    if ($a3 != $oldr_a3)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X\n", $a3

    #----
    # a4
    color $COLOR_REGNAME
    printf "a4 (x14):"
    if ($a4 != $oldr_a4)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $a4

    # a5
    color $COLOR_REGNAME
    printf "a5 (x15):"
    if ($a5 != $oldr_a5)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $a5

    # s0
    color $COLOR_REGNAME
    printf "s0 (x8 ):"
    if ($s0 != $oldr_s0)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $s0

    # s1
    color $COLOR_REGNAME
    printf "s1 (x9 ):"
    if ($s1 != $oldr_s1)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X\n", $s1

    #----
    # t0
    color $COLOR_REGNAME
    printf "t0 (x5 ):"
    if ($t0 != $oldr_t0)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $t0

    # t1
    color $COLOR_REGNAME
    printf "t1 (x6 ):"
    if ($t1 != $oldr_t1)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $t1

    # t2
    color $COLOR_REGNAME
    printf "t2 (x7 ):"
    if ($t2 != $oldr_t2)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X\n", $t2

    #----
    printf "\n-----\n"


    #----
    # a6
    color $COLOR_REGNAME
    printf "a6 (x16):"
    if ($a6 != $oldr_a6)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $a6

    # a7
    color $COLOR_REGNAME
    printf "a7 (x17):"
    if ($a7 != $oldr_a7)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X\n", $a7

    #----
    # t3
    color $COLOR_REGNAME
    printf "t3 (x28):"
    if ($t3 != $oldr_t3)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $t3

    # t4
    color $COLOR_REGNAME
    printf "t4 (x29):"
    if ($t4 != $oldr_t4)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $t4

    # t5
    color $COLOR_REGNAME
    printf "t5 (x30):"
    if ($t5 != $oldr_t5)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $t5

    # t6
    color $COLOR_REGNAME
    printf "t6 (x31):"
    if ($t6 != $oldr_t6)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X\n", $t6

    #----
    # s2
    color $COLOR_REGNAME
    printf "s2 (x18):"
    if ($s2 != $oldr_s2)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $s2

    # s3
    color $COLOR_REGNAME
    printf "s3 (x19):"
    if ($s3 != $oldr_s3)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $s3

    # s4
    color $COLOR_REGNAME
    printf "s4 (x20):"
    if ($s4 != $oldr_s4)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $s4

    # s5
    color $COLOR_REGNAME
    printf "s5 (x21):"
    if ($s5 != $oldr_s5)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X\n", $s5

    #----
    # s6
    color $COLOR_REGNAME
    printf "s6 (x22):"
    if ($s6 != $oldr_s6)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $s6

    # s7
    color $COLOR_REGNAME
    printf "s7 (x23):"
    if ($s7 != $oldr_s7)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $s7

    # s8
    color $COLOR_REGNAME
    printf "s8 (x24):"
    if ($s8 != $oldr_s8)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $s8

    # s9
    color $COLOR_REGNAME
    printf "s9 (x25):"
    if ($s9 != $oldr_s9)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X\n", $s9

    #----
    # s10
    color $COLOR_REGNAME
    printf "s10(x26):"
    if ($s10 != $oldr_s10)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $s10

    # s11
    color $COLOR_REGNAME
    printf "s11(x27):"
    if ($s11 != $oldr_s11)
        color $COLOR_REGVAL_MODIFIED
    else
        color $COLOR_REGVAL
    end
    printf "  0x%08X  ", $s11

    #----
    # pc
    color $COLOR_REGNAME
    printf "\n-----\npc :"
    color $COLOR_REGVAL
    printf "  0x%08X\n", $pc
    color_reset
    printf "\n"
end
document reg_rv32
Syntax: reg_rv32
| Auxiliary function to display RISC-v 32-bits registers.
end

define reg_rv32gprs
    reg_rv32

    #------RV32E-----
    set $oldr_ra  = $x1
    set $oldr_sp  = $x2
    set $oldr_gp  = $x3
    set $oldr_tp  = $x4

    set $oldr_a0  = $a0
    set $oldr_a1  = $a1
    set $oldr_a2  = $a2
    set $oldr_a3  = $a3
    set $oldr_a4  = $a4
    set $oldr_a5  = $a5

    set $oldr_t0  = $t0
    set $oldr_t1  = $t1
    set $oldr_t2  = $t2

    set $oldr_s0  = 0
    set $oldr_s1  = 0

    #------
    set $oldr_a6  = $a6
    set $oldr_a7  = $a7

    set $oldr_t3  = $t3
    set $oldr_t4  = $t4
    set $oldr_t5  = $t5
    set $oldr_t6  = $t6

    set $oldr_s2  = $s2
    set $oldr_s3  = $s3
    set $oldr_s4  = $s4
    set $oldr_s5  = $s5
    set $oldr_s6  = $s6
    set $oldr_s7  = $s7
    set $oldr_s8  = $s8
    set $oldr_s9  = $s9
    set $oldr_s10 = $s10
    set $oldr_s11 = $s11

end
document reg_rv32gprs
Syntax: reg_rv32gprs
| Print CPU registers.
end


define reg_rv32csr

    printf "======= M-Mode ======\n"
    printf "info:\n"
    printf "mvendorid= 0x%08X, marchid= 0x%08X, mimpid= 0x%08X, mhartid= 0x%08X\n\n", \
            $mvendorid, $marchid, $mimpid, $mhartid

    printf "exception cfg:\n"
    printf "mstatus   = 0x%08X, misa      = 0x%08X\n", $mstatus, $misa
    # printf "mie       = 0x%08X, mcounteren= 0x%08X\n", $mie, $mcounteren
    printf "mie       = 0x%08X \n", $mie
    # printf "mtvec     = 0x%08X, mtvt      = 0x%08X\n\n", $mtvec, $mtvt
    printf "mtvec     = 0x%08X\n\n", $mtvec

    printf "mepc      = 0x%08X, mcause    = 0x%08X, mtval    = 0x%08X\n", $mepc, $mcause, $mtval
    # printf "mintstatus= 0x%08X\n", $mintstatus
    # printf "mip       = 0x%08X, mnxti     = 0x%08X, mclicbase= 0x%08X\n", $mip, $mnxti, $mclicbase
    printf "mip       = 0x%08X\n", $mip
    # printf "mscratch  = 0x%08X, mscratchcsw= 0x%08X, mscratchcswl= 0x%08X\n\n", $mscratch, $mscratchcsw, $mscratchcswl
    printf "mscratch  = 0x%08X\n\n", $mscratch

    printf "conter:\n"
    printf "mcycleh   = 0x%08X, mcycle    = 0x%08X\n", $mcycleh, $mcycle
    printf "minstreth = 0x%08X, minstret  = 0x%08X\n", $minstreth, $minstret

    if $argc == 1
        printf "mem protection:\n"
        printf "pmpcfg0  = 0x%08X, pmpcfg1  = 0x%08X, pmpcfg2  = 0x%08X, pmpcfg3  = 0x%08X\n", $pmpcfg0, $pmpcfg1, $pmpcfg2, $pmpcfg3
        printf "pmpaddr0 = 0x%08X, pmpaddr1 = 0x%08X, pmpaddr2 = 0x%08X, pmpaddr3 = 0x%08X\n", $pmpaddr0, $pmpaddr1, $pmpaddr2, $pmpaddr3
        printf "pmpaddr4 = 0x%08X, pmpaddr5 = 0x%08X, pmpaddr6 = 0x%08X, pmpaddr7 = 0x%08X\n", $pmpaddr4, $pmpaddr5, $pmpaddr6, $pmpaddr7
        printf "pmpaddr8 = 0x%08X, pmpaddr9 = 0x%08X, pmpaddr10= 0x%08X, pmpaddr11= 0x%08X\n", $pmpaddr8, $pmpaddr9, $pmpaddr10, $pmpaddr11
        printf "pmpaddr12= 0x%08X, pmpaddr13= 0x%08X, pmpaddr14= 0x%08X, pmpaddr15= 0x%08X\n", $pmpaddr12, $pmpaddr13, $pmpaddr14, $pmpaddr15
    end

end
document reg_rv32csr
Syntax: reg_rv32csr [all]
| Print CSR registers value.
| [all] Optional, Log mem protection registers
end



# __________hex/ascii dump an address_________
define ascii_char
    if $argc != 1
        help ascii_char
    else
        # thanks elaine :)
        set $_c = *(unsigned char *)($arg0)
        if ($_c < 0x20 || $_c > 0x7E)
            printf "."
        else
            printf "%c", $_c
        end
    end
end
document ascii_char
Syntax: ascii_char ADDR
| Print ASCII value of byte at address ADDR.
| Print "." if the value is unprintable.
end


define hex_quad
    if $argc != 1
        help hex_quad
    else
        printf "%02X %02X %02X %02X %02X %02X %02X %02X", \
               *(unsigned char*)($arg0), *(unsigned char*)($arg0 + 1),     \
               *(unsigned char*)($arg0 + 2), *(unsigned char*)($arg0 + 3), \
               *(unsigned char*)($arg0 + 4), *(unsigned char*)($arg0 + 5), \
               *(unsigned char*)($arg0 + 6), *(unsigned char*)($arg0 + 7)
    end
end
document hex_quad
Syntax: hex_quad ADDR
| Print eight hexadecimal bytes starting at address ADDR.
end

define hexdump_aux
    if $argc != 1
        help hexdump_aux
    else
        color_bold
        printf "0x%08X : ", $arg0
        color_reset

        hex_quad $arg0
        color_bold
        printf " - "
        color_reset
        hex_quad $arg0+8
        printf " "
        color_bold
        ascii_char $arg0+0x0
        ascii_char $arg0+0x1
        ascii_char $arg0+0x2
        ascii_char $arg0+0x3
        ascii_char $arg0+0x4
        ascii_char $arg0+0x5
        ascii_char $arg0+0x6
        ascii_char $arg0+0x7
        ascii_char $arg0+0x8
        ascii_char $arg0+0x9
        ascii_char $arg0+0xA
        ascii_char $arg0+0xB
        ascii_char $arg0+0xC
        ascii_char $arg0+0xD
        ascii_char $arg0+0xE
        ascii_char $arg0+0xF
        color_reset
        printf "\n"
    end
end
document hexdump_aux
Syntax: hexdump_aux ADDR
| Display a 16-byte hex/ASCII dump of memory at address ADDR.
end

define hexdump
    printf "\n"

    if $argc == 1
        hexdump_aux $arg0
    else
        if $argc == 2
            set $_count = 0
            while ($_count < $arg1)
                set $_i = ($_count * 0x10)
                hexdump_aux $arg0+$_i
                set $_count++
            end
        else
            if $argc == 3
                set $_count = 0
                while ($_count < $arg1)
                    set $_i = ($_count * 0x10)

                    color_bold
                    printf "0x%08X: ", $arg0+$_i
                    color_reset

                    printf "%08X %08X %08X %08X\n", \
                            *(unsigned int*)($arg0+$_i+0x0), \
                            *(unsigned int*)($arg0+$_i+0x4), \
                            *(unsigned int*)($arg0+$_i+0x8), \
                            *(unsigned int*)($arg0+$_i+0xC)
                    set $_count++
                end
            else
                help hexdump
            end
        end
    end

    printf "\n"
end
document hexdump
Syntax: hexdump ADDR <NR_LINES> <Is_Byte_Layout>
| Display a 16-byte hex/ASCII dump of memory starting at address ADDR.
| Optional parameter is the number of lines to display if you want more than one.
end

define memdump
    if $argc == 1
        hexdump $arg0
    else
        if $argc == 2
            hexdump $arg0 $arg1
        else
            if $argc == 3
                hexdump $arg0 $arg1 $arg2
            else
                help memdump
            end
        end
    end
end
document memdump
Syntax: memdump ADDR <NR_LINES> <Is_Byte_Layout>
| Display a 16-byte hex/ASCII dump of memory starting at address ADDR.
| Optional parameter is the number of lines to display if you want more than one.
end