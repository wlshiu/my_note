#include <stdio.h>
#include <stdlib.h>

///////////////////////////////////////////////////
//----------------------------
/**
 * bit field pull high/low
 * It should be set DEFINE_BIT_OP(bit_size) first.
 */
#define DEFINE_BIT_OP(bit_size)\
    typedef struct ZONE_SET_T{\
        unsigned short bits_field[((bit_size)+0xF)>>4];\
    }ZONE_SET;

#define BOP_SET(pZone_set_member, bit_order)     ((pZone_set_member)->bits_field[(bit_order)>>4] |=  (1<<((bit_order)&0xF)))
#define BOP_CLR(pZone_set_member, bit_order)     ((pZone_set_member)->bits_field[(bit_order)>>4] &= ~(1<<((bit_order)&0xF)))
#define BOP_IS_SET(pZone_set_member, bit_order)  ((pZone_set_member)->bits_field[(bit_order)>>4] &   (1<<((bit_order)&0xF)))
#define BOP_ZERO(pZone_set_member)               memset((void*)(pZone_set_member),0,sizeof(ZONE_SET))

#define BIT_OP_T    ZONE_SET
///////////////////////////////////////////////////
static void
_swap(unsigned long *pX, unsigned long *pY)
{
    unsigned long   x = *pX, y = *pY;

    #if 1
    x ^= y ^= x ^= y;
    #else
    x = x ^ y;
    y = x ^ y;
    x = x ^ y;
    #endif

    *pX = x, *pY = y;
    return;
}

static long
_abs(long  x)
{
    // x < 0 ? -x : x;
    int     shift = (sizeof(long) << 3) - 1;
    printf("shift = %d\n", shift);
    return (x ^ (x >> shift)) - (x >> shift);
}

static int _IsPow2(long  n)
{
    return (n && !(n & (n - 1)));
}

static long
_round_up_pow2(long x, int pow_element_of_2)
{
    return (x + ((1<<(pow_element_of_2)) - 1)) & ~((1<<(pow_element_of_2)) - 1);
}

static long
_round_down_pow2(long x, int pow_element_of_2)
{
    return (x & ~((1<<(pow_element_of_2)) - 1));
}

static unsigned long
_get_lsb_value(unsigned long  x)
{
    unsigned long    mask = (x) & (-x);
    return (x & mask);
}

static unsigned long
_get_mask_from_lsb_to_msb(long  x)
{
    unsigned long   mask = x | (-(x));
    char            buf[65] = {0};
    itoa(mask, buf, 2);
    printf("mask= %s\n", buf);
    return mask;
}

static unsigned long
_get_msb_value(unsigned long  x)
{
    int  i, cnt = sizeof(long);

    for(i = 0; i <= cnt; ++i)
        x |= (x >> (0x1L << i));

    return (x & ~(x >> 1));
}

// 只有MSB的值
static unsigned int
_msb_value(unsigned int x)
{
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);
    return(x & ~(x >> 1));
}

static int
_get_lsb_pos(unsigned int value)
{
    union {
        int i[2];
        double d;
    } u = { .d = value ^ (value - !!value) };
    return (u.i[1] >> 20) - 1023;
}


static int
_get_32bit_msb_order(unsigned int word)
{
    unsigned int   u[2];
    double         *pDouble;
    int r = 0;
    if (word < 1)   return 0;

    // Little Endian case, big endian => change u[0], u[1] order
    u[1] = 0x43300000;
    u[0] = word;
    pDouble = (double*)&u[0];
    (*pDouble) = (*pDouble) - 4503599627370496.0;
    r = (u[1] >> 20) - 0x3FF;
    return r;
}

static inline void
_printf_binary(unsigned long long x, int size)
{
    unsigned long long   mask = 0x1ull << size;
    while (mask)
    {
        printf("%u", (x & mask) != 0);
        mask >>= 1;
    }
    puts("\n");
    return;
}

static void _reverse_bits(unsigned int *pX)
{
    unsigned int    v = *pX;
    // swap odd and even bits
    v = ((v >> 1) & 0x55555555) | ((v & 0x55555555) << 1);
    // swap consecutive pairs
    v = ((v >> 2) & 0x33333333) | ((v & 0x33333333) << 2);
    // swap nibbles ...
    v = ((v >> 4) & 0x0F0F0F0F) | ((v & 0x0F0F0F0F) << 4);
    // swap bytes
    v = ((v >> 8) & 0x00FF00FF) | ((v & 0x00FF00FF) << 8);
    // swap 2-byte long pairs
    v = ( v >> 16             ) | ( v               << 16);

    *pX = v;
    return;
}

static unsigned int
_count_bits(unsigned int x)
{
    x = (x & 0x55555555) + ((x & 0xaaaaaaaa) >> 1);
    x = (x & 0x33333333) + ((x & 0xcccccccc) >> 2);
    x = (x & 0x0f0f0f0f) + ((x & 0xf0f0f0f0) >> 4);
    x = (x & 0x00ff00ff) + ((x & 0xff00ff00) >> 8);
    x = (x & 0x0000ffff) + ((x & 0xffff0000) >> 16);
    return x;
}

// 1.0 / sqrt(x)
static float InvSqrt(float x)
{
    float xhalf = 0.5f*x;
    int i = *(int*)&x;
    i = 0x5f3759df - (i>>1);
    x = *(float*)&i;
    x = x*(1.5f-xhalf*x*x);
    return x;
}
///////////////////////////////////////////////////

int main()
{
    {
        unsigned int  x = 29, y;

        y = x;
        _reverse_bits(&y);
        printf("%u -> %u, act bit= %d\n", x, y, _count_bits(x));
    }
    {
        long    x = -1;
        printf("%ld get msb= %lu, %d\n", x, _get_msb_value(x), _get_32bit_msb_order(x));
    }
    {
        long    x = 28;
        char    buf[65] = {0};

        itoa(x, buf, 2);
        printf("%s, %ld, %lu\n", buf, _get_lsb_value(x), _get_mask_from_lsb_to_msb(x));
    }

    {
        long    x = 25;
        int     elem = 3;

        printf("%ld align to: %ld~%ld (align %d)\n",
               x, _round_down_pow2(x, elem), _round_up_pow2(x, elem), 1 << elem);
    }
    {
        long    x = 125, y = 256;
        printf("is pow2, %ld(%d), %ld(%d)\n",
               x, _IsPow2(x), y, _IsPow2(y));
    }
    {
        unsigned long   a = 123, b = 456;
        _swap(&a, &b);
        printf("a= %ld, b= %ld\n", a, b);
    }

    {
        long    x = -5;
        printf("asb= %ld\n", _abs(x));
    }
    return 0;
}
