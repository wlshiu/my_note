#include <stdint.h>

int clz(uint32_t x)
{
    static const char debruijn32[32] = {
        0, 31, 9, 30, 3, 8, 13, 29, 2, 5, 7, 21, 12, 24, 28, 19,
        1, 10, 4, 14, 6, 22, 25, 20, 11, 15, 23, 26, 16, 27, 17, 18
    };
    x |= x>>1;
    x |= x>>2;
    x |= x>>4;
    x |= x>>8;
    x |= x>>16;
    x++;
    return debruijn32[x*0x076be629>>27];
}

uint8_t _clz(uint32_t x)
{
    uint8_t     n = 0;

    if( x == 0 )    return 32;

    if( x <= 0x0000FFFFul ) { n += 16; x <<= 16; }
    if( x <= 0x00FFFFFFul ) { n += 8; x <<= 8; }
    if( x <= 0x0FFFFFFFul ) { n += 4; x <<= 4; }
    if( x <= 0x3FFFFFFFul ) { n += 2; x <<= 2; }
    if( x <= 0x7FFFFFFFul ) { n += 1; x <<= 1; }
    return n;
}