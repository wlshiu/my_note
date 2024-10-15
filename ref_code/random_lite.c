
#include <stdint.h>

uint32_t rand_fast(void)
{
    static uint32_t z1 = 12345, z2 = 12345, z3 = 12345, z4 = 12345;

    uint32_t    b;
    b  = ((z1 << 6) ^ z1) >> 13;
    z1 = ((z1 & 0xFFFFFFFEU) << 18) ^ b;
    b  = ((z2 << 2) ^ z2) >> 27;
    z2 = ((z2 & 0xFFFFFFF8U) << 2) ^ b;
    b  = ((z3 << 13) ^ z3) >> 21;
    z3 = ((z3 & 0xFFFFFFF0U) << 7) ^ b;
    b  = ((z4 << 3) ^ z4) >> 12;
    z4 = ((z4 & 0xFFFFFF80U) << 13) ^ b;
    return (z1 ^ z2 ^ z3 ^ z4);
}