
/**
 *  Comparing strings (http://mgronhol.github.io/fast-strcmp/)
 *  A set of test runs against the strncmp was done using a C program that generated a set of random strings
 *  and the compare functions were timed when an all-to-all compare loop was executed.
 *  Results reported here are averages over 512 runs.
 *  All programs were complied using gcc version 4.4.6 and with -O3 flag.
 *
 *  Results from 32bit EC2 instance:
 *
 *  Test 1: Comparing 20000 strings (20 chars each) against each other
 *  fast_compare: 1.19 s
 *  strncmp:      3.58 s
 *
 *  fastcmp vs strncmp: 3.0x
 *
 *
 *  Test 2: Comparing 20000 strings (2000 chars each) against each other
 *  fast_compare: 18.15 s
 *  strncmp:      187.74 s
 *
 *  fastcmp vs strncmp: 10.3x
 *
 *  Result from 64bit Intel Pentium 4 @ 3.4Ghz
 *
 *  Test 1: Comparing 20000 strings (20 chars each) against each other
 *  fast_compare: 2.44 s
 *  strncmp:      7.47 s
 *
 *  fastcmp vs strncmp: 3.1x
 *
 *
 *  Test 2: Comparing 20000 strings (2000 chars each) against each other
 *  fast_compare: 29.20 s
 *  strncmp:      45.31 s
 *
 *  fastcmp vs strncmp: 1.6x
 *
 */

int fast_strncmp( const char *ptr0, const char *ptr1, int len )
{
    int     fast = len / sizeof(size_t) + 1;
    int     offset = (fast - 1) * sizeof(size_t);
    int     current_block = 0;
    size_t  *lptr0 = (size_t*)ptr0;
    size_t  *lptr1 = (size_t*)ptr1;

    fast = (len > sizeof(size_t)) ? fast : 0;

    while( current_block < fast )
    {
        if( (lptr0[current_block] ^ lptr1[current_block]) )
        {
            for(int pos = current_block * sizeof(size_t); pos < len ; ++pos )
            {
                if( (ptr0[pos] ^ ptr1[pos]) || (ptr0[pos] == 0) || (ptr1[pos] == 0) )
                {
                    return (int)((unsigned char)ptr0[pos] - (unsigned char)ptr1[pos]);
                }
            }
        }

        ++current_block;
    }

    while( len > offset )
    {
        if( (ptr0[offset] ^ ptr1[offset]) )
        {
            return (int)((unsigned char)ptr0[offset] - (unsigned char)ptr1[offset]);
        }
        ++offset;
    }


    return 0;
}
