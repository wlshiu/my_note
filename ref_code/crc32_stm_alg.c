#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

/**
 *  IEEE 802.3 crc32
 *  x^32+x^26+x^23+x^22+x^16+x^12+x^11+x^10+x^8+x^7+x^5+x^4+x^2+x+1.
 */


uint32_t Crc32(uint32_t Crc, uint32_t Data )
{
  int i;

  Crc = Crc ^ Data;

  for ( i = 0; i < 32; i++ )
    if ( Crc & 0x80000000 )
      Crc = ( Crc << 1 ) ^ 0x04C11DB7; // Polynomial used in STM32
    else
      Crc = ( Crc << 1 );

  return ( Crc );
}

uint32_t crc32_STM32_algo(uint32_t crc_value, uint32_t *pData, int nbytes)
{
    if( nbytes & 0x3 )
        return 0xFFFFFFFF;

    nbytes = nbytes >> 2;

    for(int i = 0; i < nbytes; i++)
    {
        int     shift = 0;

        crc_value = crc_value ^ pData[i];

        do {
            if( crc_value & 0x80000000 )
                crc_value = (crc_value << 1) ^ 0x04C11DB7; // Polynomial used in STM32
            else
                crc_value = (crc_value << 1);

            shift++;
        } while(shift < 32);
    }

    return crc_value;
}

uint32_t crc32_stm32_agl_fast(uint32_t crc_value, uint32_t *pData, int nbytes)
{
    // Nibble lookup table for 0x04C11DB7 polynomial
    static const uint32_t   __Crc32Table[16] =
    {
        0x00000000, 0x04C11DB7, 0x09823B6E, 0x0D4326D9, 0x130476DC, 0x17C56B6B,
        0x1A864DB2, 0x1E475005, 0x2608EDB8, 0x22C9F00F, 0x2F8AD6D6, 0x2B4BCB61,
        0x350C9B64, 0x31CD86D3, 0x3C8EA00A, 0x384FBDBD
    };

    if( nbytes & 0x3 )
        return 0xFFFFFFFF;

    nbytes = nbytes >> 2;

    for(int i = 0; i < nbytes; i++)
    {
        crc_value = crc_value ^ pData[i]; // Apply all 32-bits

        /**
         *  Process 32-bits, 4 at a time, or 8 rounds
         *  Assumes 32-bit reg, masking index to 4-bits
         *  0x04C11DB7 Polynomial used in STM32
         */
        crc_value = ( crc_value << 4 ) ^ __Crc32Table[ crc_value >> 28 ];
        crc_value = ( crc_value << 4 ) ^ __Crc32Table[ crc_value >> 28 ];
        crc_value = ( crc_value << 4 ) ^ __Crc32Table[ crc_value >> 28 ];
        crc_value = ( crc_value << 4 ) ^ __Crc32Table[ crc_value >> 28 ];
        crc_value = ( crc_value << 4 ) ^ __Crc32Table[ crc_value >> 28 ];
        crc_value = ( crc_value << 4 ) ^ __Crc32Table[ crc_value >> 28 ];
        crc_value = ( crc_value << 4 ) ^ __Crc32Table[ crc_value >> 28 ];
        crc_value = ( crc_value << 4 ) ^ __Crc32Table[ crc_value >> 28 ];
    }

    return crc_value;
}

int main()
{
    uint32_t    crc_val = 0xFFFFFFFF;
    uint8_t     g_data[64] = {0};


    for(int i = 0; i < sizeof(g_data); i++)
        g_data[i] = (i + 0x5) & 0xFF;

    crc_val = 0xFFFFFFFF;
    for(int i = 0; i < sizeof(g_data); i += 4)
    {
        crc_val = Crc32(crc_val, *(uint32_t*)&g_data[i]);
    }

    printf("crc32= x%08X\n", crc_val);

    crc_val = 0xFFFFFFFF;
    printf("@ crc32= x%08X\n", crc32_STM32_algo(crc_val, (uint32_t*)&g_data, sizeof(g_data)));

    crc_val = 0xFFFFFFFF;
    printf("@ crc32= x%08X\n", crc32_stm32_agl_fast(crc_val, (uint32_t*)&g_data, sizeof(g_data)));


    system("pause");
    return 0;
}
