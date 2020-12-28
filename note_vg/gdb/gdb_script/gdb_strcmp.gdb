set var  $_isEq=0

# Yes! GDB_STRCMP, below, is a gdb function.
# Function that provides strcmp-like functionality for gdb script;
# this function will be used to match the password string provided in command line argument
# with the string argument of strcmp in program
define GDB_STRCMP
    set var  $_i=0
    set var  $_c1= *(unsigned char *) ($arg0 + $_i)
    set var  $_c2= *(unsigned char *) ($arg1 + $_i)

    while (  ($_c1 != 0x0) && ($_c2 != 0x0) && ($_c1 == $_c2) )

        #printf "\n i=%d, addr1=%x(%d,%c), addr2=%x(%d,%c)", $_i, ($arg0 + $_i),$_c1, $_c1, ($arg1 + $_i), $_c2,$_c2
        set  $_i++
        set  $_c1= *(unsigned char *) ($arg0 + $_i)
        set  $_c2= *(unsigned char *) ($arg1 + $_i)

    #while end
    end

    if( $_c1 == $_c2)
        set $_isEq=1
    else
        set $_isEq=0
    end

#GDB_STRCMP end
end

